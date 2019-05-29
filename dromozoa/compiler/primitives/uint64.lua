-- Copyright (C) 2019 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-compiler.
--
-- dromozoa-compiler is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-compiler is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-compiler.  If not, see <http://www.gnu.org/licenses/>.

local K16 = 0x10000
local K24 = 0x1000000
local K28 = 0x10000000
local K48 = 0x1000000000000
local KD = 10000000

local function add(x1, x2, y1, y2)
  local u2 = x2 + y2
  local u1 = x1 + y1

  local v2 = u2 % K48
  local v1 = u1 + (u2 - v2) / K48

  return v1 % K16, v2
end

local function sub(x1, x2, y1, y2)
  local u2 = x2 - y2
  local u1 = x1 - y1

  if u2 < 0 then
    u2 = u2 + K48
    u1 = u1 - 1
  end
  if u1 < 0 then
    u1 = u1 + K16
  end

  return u1, u2
end

local function mul(x1, x2, y1, y2)
  local x3 = x2 % K24
  local x2 = (x2 - x3) / K24
  local y3 = y2 % K24
  local y2 = (y2 - y3) / K24

  local u1 = x3 * y1 + x2 * y2 + x1 * y3
  local u2 = x3 * y2 + x2 * y3
  local u3 = x3 * y3

  local v3 = u3 % K24
  u2 = u2 + (u3 - v3) / K24
  local v2 = u2 % K24
  u1 = u1 + (u2 - v2) / K24
  local v1 = u1 % K16

  return v1, v2 * K24 + v3
end

local function div(X1, X2, y1, y2)
  if y1 == 0 then
    local x2 = X2 % K24
    local x1 = X1 * K24 + (X2 - x2) / K24

    local r1 = x1 % y2
    if r1 < K28 then
      local q1 = (x1 - r1) / y2

      local u2 = x2 + r1 * K24

      local r2 = u2 % y2
      local q2 = (u2 - r2) / y2

      local z2 = q1 % K24
      local z1 = (q1 - z2) / K24
      z2 = z2 * K24 + q2

      return z1, z2, 0, r2
    end
  end

  local x1 = X1
  local x2 = X2
  local Y1 = {}
  local Y2 = {}
  local Z = {}

  local z = 1
  for i = 1, 36 do
    Y1[i] = y1
    Y2[i] = y2
    Z[i] = z
    y1 = y1 * 2
    y2 = y2 * 2
    z = z * 2
    local r = y2 % K48
    y1 = y1 + (y2 - r) / K48
    if y1 >= K16 then
      break
    end
    y2 = r
  end

  local q = 0
  for i = #Y1, 1, -1 do
    local y1 = Y1[i]
    local y2 = Y2[i]
    local z = Z[i]
    if x1 == y1 then
      if x2 >= y2 then
        x1, x2 = sub(x1, x2, y1, y2)
        q = q + z
      end
    else
      if x1 >= y1 then
        x1, x2 = sub(x1, x2, y1, y2)
        q = q + z
      end
    end
  end

  return 0, q, x1, x2
end

local function eq(x1, x2, y1, y2)
  return x1 == y1 and x2 == y2
end

local function lt(x1, x2, y1, y2)
  if x1 == y1 then
    return x2 < y2
  else
    return x1 < y1
  end
end

local function encode_dec(x1, X2)
  local x2 = X2 % K24
  local x1 = x1 * K24 + (X2 - x2) / K24

  local r1 = x1 % KD
  local q1 = (x1 - r1) / KD

  local u2 = x2 + r1 * K24

  local r2 = u2 % KD
  local q2 = (u2 - r2) / KD

  local u1 = q1 * K24 + q2

  if u1 == 0 then
    return ("%d"):format(r2)
  else
    return ("%d%07d"):format(u1, r2)
  end
end

local function encode_hex(x1, x2)
  return ("0x%04X%012X"):format(x1, x2)
end

local class = {
  add = add;
  sub = sub;
  mul = mul;
  div = div;
  eq = eq;
  lt = lt;
  encode_dec = encode_dec;
  encode_hex = encode_hex;
}
local metatable = { __index = class }

local function normalize(x1, X2)
  if X2 then
    local x2 = X2 % K48
    local x1 = (x1 + (X2 - x2) / K48) % K16
    return x1, x2
  elseif x1 then
    local x2 = x1 % K48
    local x1 = (x1 - x2) / K48 % K16
    return x1, x2
  else
    return 0, 0
  end
end

local function construct(x1, x2)
  return setmetatable({ x1, x2 }, metatable)
end

function metatable.__add(x, y)
  return construct(add(x[1], x[2], y[1], y[2]))
end

function metatable.__sub(x, y)
  return construct(sub(x[1], x[2], y[1], y[2]))
end

function metatable.__mul(x, y)
  return construct(mul(x[1], x[2], y[1], y[2]))
end

function metatable.__div(x, y)
  local q1, q2 = div(x[1], x[2], y[1], y[2])
  return construct(q1, q2)
end

function metatable.__mod(x, y)
  local _, _, r1, r2 = div(x[1], x[2], y[1], y[2])
  return construct(r1, r2)
end

function metatable.__eq(x, y)
  return eq(x[1], x[2], y[1], y[2])
end

function metatable.__lt(x, y)
  return lt(x[1], x[2], y[1], y[2])
end

function metatable.__tostring(x)
  return encode_dec(x[1], x[2])
end

return setmetatable(class, {
  __call = function (_, ...)
    return construct(normalize(...))
  end;
})

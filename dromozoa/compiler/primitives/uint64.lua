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
local K48 = 0x1000000000000
local KD = 10000000

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

local class = {}
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

function class.encode_dec(x)
  return encode_dec(x[1], x[2])
end

function class.encode_hex(x)
  return encode_hex(x[1], x[2])
end

function metatable.__mul(x, y)
  return construct(mul(x[1], x[2], y[1], y[2]))
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

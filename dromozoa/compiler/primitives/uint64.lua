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

local function mul(X1, X2, Y1, Y2)
end







local SHIFT16 = 0x10000
local SHIFT24 = 0x1000000
local SHIFT48 = 0x1000000000000
local MASK24 = 0xFFFFFF
local MASK48 = 0xFFFFFFFFFFFF
local POW10_7 = 10000000

-- TODO impl n
local function construct(x1, x2, n)
  if not x1 then
    x1 = 0
  end
  assert(x1 % 1 == 0)
  assert(x1 >= 0)

  if not x2 then
    x2 = 0
  end
  assert(x2 % 1 == 0)
  assert(x2 >= 0)

  if x1 >= SHIFT48 then
    local y1 = x1 % SHIFT48
    x2 = x2 + (x1 - y1) / SHIFT48
    x1 = y1
  end

  if x2 >= SHIFT16 then
    x2 = x2 % SHIFT16
  end

  return { x1, x2 }
end

local function eq(x, y)
  return x[1] == y[1] and x[2] == y[2]
end

local function lt(x, y)
  local x2 = x[2]
  local y2 = y[2]
  if x2 == y2 then
    return x[1] < y[1]
  else
    return x2 < y2
  end
end

local function mul(x, y, z)
  local v1 = x[1]
  local x1 = v1 % SHIFT24
  local x2 = (v1 - x1) / SHIFT24
  local v2 = y[1]
  local y1 = v2 % SHIFT24
  local y2 = (v2 - y1) / SHIFT24
  local z1 = x1 * y1
  local z2 = x1 * y2 + x2 * y1
  local z3 = x1 * y[2] + x2 * y2 + x[2] * y1
  local r1 = z1 % SHIFT24
  local v3 = z2 + (z1 - r1) / SHIFT24
  local r2 = v3 % SHIFT24
  local q2 = (v3 - r2) / SHIFT24
  z[1] = r2 * SHIFT24 + r1
  z[2] = (z3 + q2) % SHIFT16
  return z
end

local function tostring_dec(x)
  local v1 = x[1]
  local x1 = v1 % SHIFT24
  local x2 = x[2] * SHIFT24 + (v1 - x1) / SHIFT24
  local r1 = x2 % POW10_7
  local q1 = (x2 - r1) / POW10_7
  local v2 = r1 * SHIFT24 + x1
  local r2 = v2 % POW10_7
  local q2 = (v2 - r2) / POW10_7
  local v3 = q1 * SHIFT24 + q2
  if v3 == 0 then
    return ("%d"):format(v3)
  else
    return ("%d%07d"):format(v3, r2)
  end
end

local function tostring_hex(x)
  return ("0x%04X%012X"):format(x[2], x[1])
end

local class = {
  eq = eq;
  tostring_dec = tostring_dec;
  tostring_hex = tostring_hex;
}

local metatable = {
  __index = class;
  __eq = eq;
  __tostring = tostring_dec;
}

local function new()
  return setmetatable({}, metatable)
end

function metatable.__mul(x, y)
  if type(x) ~= "table" then
    x = construct(x)
  end
  if type(y) ~= "table" then
    y = construct(y)
  end
  return mul(x, y, new())
end

return setmetatable(class, {
  __call = function (_, lower, upper)
    return setmetatable(construct(lower, upper), metatable)
  end;
})

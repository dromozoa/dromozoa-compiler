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

local function tostring_dec(x)
  local x1 = x[1]
  local x2 = x[2]

  local y1 = x1 % SHIFT24
  local y2 = x2 * SHIFT24 + (x1 - y1) / SHIFT24

  local r1 = y2 % POW10_7
  local q1 = (y2 - r1) / POW10_7

  local u1 = r1 * SHIFT24 + y1
  local r2 = u1 % POW10_7
  local q2 = (u1 - r2) / POW10_7

  local z2 = q1 * SHIFT24 + q2
  local z1 = r2

  if z2 == 0 then
    return ("%d"):format(z1)
  else
    return ("%d%07d"):format(z2, z1)
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
  __tostring = tostring_impl;
}

function class:mul(x, y)
  if type(x) ~= "table" then
    x = construct(x)
  end
  if type(y) ~= "table" then
    y = construct(y)
  end

  local u = x[1]
  local x1 = u % SHIFT24
  local x2 = (u - x1) / SHIFT24
  local x3 = x[2]

  local u = y[1]
  local y1 = u % SHIFT24
  local y2 = (u - y1) / SHIFT24
  local y3 = y[2]

  local z1 = x1 * y1
  local z2 = x1 * y2 + x2 * y1
  local z3 = x1 * y3 + x2 * y2 + x3 * y1

  local r1 = z1 % SHIFT24
  local q1 = (z1 - r1) / SHIFT24

  z1 = r1
  z2 = z2 + q1

  local r2 = z2 % SHIFT24
  local q2 = (z2 - r2) / SHIFT24

  z2 = r2
  z3 = z3 + q2

  self[1] = z2 * SHIFT24 + z1
  self[2] = z3 % SHIFT16
  return self
end

return setmetatable(class, {
  __call = function (_, lower, upper)
    return setmetatable(construct(lower, upper), metatable)
  end;
})

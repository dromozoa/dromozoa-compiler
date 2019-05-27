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

local function construct(x1, x2)
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

  -- y1 = x1 & 0xFFFFFF
  -- y2 = x2 << 24 | x1 >> 24
  local y1 = x1 % SHIFT24
  local y2 = x2 * SHIFT24 + (x1 - y1) / SHIFT24

  -- b = y2 % 10000000
  -- a = y2 / 10000000
  local b = y2 % POW10_7
  local a = (y2 - b) / POW10_7

  -- c = b << 24 | y1
  -- d = c % 10000000
  -- e = c / 10000000
  local c = b * SHIFT24 + y1
  local d = c % POW10_7
  local e = (c - d) / POW10_7

  local f = a * SHIFT24 + e
  if f == 0 then
    return ("%d"):format(d)
  else
    return ("%d%07d"):format(f, d)
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

return setmetatable(class, {
  __call = function (_, lower, upper)
    return setmetatable(construct(lower, upper), metatable)
  end;
})

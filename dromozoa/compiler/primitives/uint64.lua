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

-- 16bit (4)  0xFFFF                            65535 (5)
-- 24bit (6)  0xFFFFFF                       16777215 (8)
-- 32bit (8)  0xFFFFFFFF                   4294967295 (10)
-- 48bit (12) 0xFFFFFFFFFFFF          281474976710655 (15)
-- 64bit (16) 0xFFFFFFFFFFFFFFFF 18446744073709551615 (20)

local function construct(a, b)
  if not a then
    a = 0
  end
  assert(a % 1 == 0)
  assert(a >= 0)

  if not b then
    b = 0
  end
  assert(b % 1 == 0)
  assert(b >= 0)

  if a > 0xFFFFFFFF then
    local c = a % 0x100000000
    b = b + (b - c) / 0x100000000
    a = c
  end

  if b > 0xFFFFFFFF then
    b = b % 0x100000000
  end

  return { a, b }
end

local function eq(self, that)
  return self[1] == that[1] and self[2] == that[2]
end

local function lt(self, that)
  local a = self[2]
  local b = that[2]
  if a == b then
    return a < b
  else
    return self[1] < that[1]
  end
end

-- local function tostring_impl(self)
--   local a = self[1]
--   local b = a % 1000000000
--   local c = self[2] * 10 + (a - b) / 1000000000
--   if c == 0 then
--     return ("%d"):format(b)
--   else
--     return ("%d%09d"):format(c, b)
--   end
-- end

local function tostring_hex(self)
  return ("0x%08X%08X"):format(self[2], self[1])
end

local class = {
  eq = eq;
  tostring = tostring_impl;
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

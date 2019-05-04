-- Copyright (C) 2018,2019 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local print = print

print(42 + 17)
print(42 - 17)
print(42 * 17)
print(42 / 8)
print(42 // 8)
print(42 ^ 3 == 74088)
print(0xDEAD & 0xFACE)
print(0xDEAD | 0xFACE)
print(0xDEAD >> 3)
print(0xDEAD << 3)
print(1 .. 2 .. 3 .. 4)
print(42 < 17, 42 < 42)
print(42 <= 17, 42 <= 42)
print(42 > 17, 42 > 42)
print(42 >= 17, 42 >= 42)
print(42 == 17, 42 == 42, 42 == "42")
print(42 ~= 17, 42 ~= 42, 42 ~= "42")

local t1 = {}
local t2 = t1
local t3 = {}

print(t1 == t1, t1 == t2, t1 == t3)
print(t1 ~= t1, t1 ~= t2, t1 ~= t3)

local p1 = function () return 1 end
local p2 = p1
local p3 = function () return 2 end

print(p1 == p1, p1 == p2, p1 == p3)
print(p1 ~= p1, p1 ~= p2, p1 ~= p3)

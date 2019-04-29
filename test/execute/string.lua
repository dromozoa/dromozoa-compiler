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

local s1 = "abc"
local s2 = "あいうえお"
print(#s1)
print(#s2)

print(string.byte(s1))
print(s1:byte())
for i = -4, 4 do
  print(s1:byte(i))
  for j = -4, 4 do
    print(s1:byte(i, j))
  end
end
print(s2:byte(1, -1))

print(string.char())
print(string.char(0x41, 0xE2, 0x89, 0xA2, 0xCE, 0x91, 0x2E))
print(string.char(0xED, 0x95, 0x9C, 0xEA, 0xB5, 0xAD, 0xEC, 0x96, 0xB4))
print(string.char(0xE6, 0x97, 0xA5, 0xE6, 0x9C, 0xAC, 0xE8, 0xAA, 0x9E))
print(string.char(0xEF, 0xBB, 0xBF, 0xF0, 0xA3, 0x8E, 0xB4))

print(s1:len())
print(s1:len())
print(s1:len())
print(s1:len())
print(s2:len())

print(_VERSION:len());
print(_VERSION:len());
print(_VERSION:len());
print(_VERSION:len());

for i = -4, 4 do
  print(s1:sub(i))
  for j = -4, 4 do
    print(s1:sub(i, j))
  end
end

print(getmetatable("foo").__index == string)

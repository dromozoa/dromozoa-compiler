-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local d = {}

local i = 1
while i <= 10 do
  d[i] = i * i
  i = i + 1
end

local function f(x)
  return x, x, x
end

while f(f(i) <= 10) do
  d[i] = i * i
  i = i + 1
end

local i = 1
repeat
  d[i] = i * i
  i = i + 1
until i > 10

for i = 1, 10 do
  d[i] = i * i
end

for i = 10, 1, -1 do
  d[i] = i * i
end

for i, v in ipairs(d) do
  d[i] = i * i
end

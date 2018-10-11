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

b1 = false
b2 = true
d1 = 42
d2 = 17
s1 = "foo"
s2 = "bar"

v = d1 + d2
v = d1 - d2
v = d1 * d2
v = d1 / d2
v = d1 // d2
v = d1 ^ d2
v = d1 % d2
v = d1 & d2
v = d1 ~ d2
v = d1 | d2
v = d1 >> d2
v = d1 << d2
v = s1 .. s2
v = d1 < d2
v = d1 <= d2
v = d1 > d2
v = d1 >= d2
v = d1 == d2
v = d1 ~= d2
v = b1 and b2
v = b1 or b2

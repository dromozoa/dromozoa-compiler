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

print(nil)
print(false)
print(true)
print(3)
print(345)
print(0xff)
print(0xBEBADA)
print(3.0 == 3)
print(3.1416)
print(314.16e-2)
print(0.31416E1)
print(34e1 == 340)
print(0x0.1E)
print(0xA23p-4)
local hex = 0X1.921FB54442D18P+1
print(3.1415926535897 < hex and hex < 3.1415926535898)
print ""
print ''
print [[]]
print "test\n"
print "\x41\x42\x43"
print "abc\z
def"
print "\xE3\x81\x82\227\129\132\u{3046}"
print "\u{2027}" -- HYPHENATION POINT
print "\u{2028}" -- LINE SEPARATOR
print "\u{2029}" -- PARAGAPH SEPARATOR

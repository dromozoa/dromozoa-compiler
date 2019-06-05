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

local function check(x, y)
  print "============================================================"
  print("x", type(x), math.type(x), x)
  print("y", type(y), math.type(y), y)

  print "------------------------------------------------------------"

  print("+", math.type(x + y), x + y)
  print("-", math.type(x - y), x - y)
  print("*", math.type(x * y), x * y)
  print("%", math.type(x % y), x % y)
  print("//", math.type(x // y), x // y)

  print "------------------------------------------------------------"

  print("/", math.type(x / y), x / y)
  print("^", math.type(x ^ y), x ^ y)

  print "------------------------------------------------------------"

  print("unm", math.type(-x), -x)

  print "------------------------------------------------------------"

  print("&", math.type(x & y), x & y)
  print("|", math.type(x | y), x | y)
  print("~", math.type(x ~ y), x ~ y)

  print "------------------------------------------------------------"

  print("bnot", math.type(~x), ~x)
end

-- check(42, 7)
-- check(42, 7.0)
-- check(42.0, 7)
check(42.0, 7.0)



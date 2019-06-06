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

local x = 0x7FFFFFFFFFFFFFFF -- 2^63 - 1
local y = 1.0
local z = x * y
local w = 0x1.0p63 -- 2^63
print(("%A"):format(z))
print(("%A"):format(z - w))
print(z == x)
print(z == w)

local function check_float_to_integer(x)
  local result, message = pcall(function (x, y)
    local z = x | y
    print(("0x%016X %d"):format(z, z))
  end, x, 0)
  if not result then
    print("error", message)
  end
end

check_float_to_integer( 0x1.0p63)
check_float_to_integer( 0x1.FFFFFFFFFFFFp62)
check_float_to_integer( 0x1.0p62)
check_float_to_integer(-0x1.0p64)
check_float_to_integer(-0x1.0p63)
check_float_to_integer(-0x1.0p62)
check_float_to_integer( 42.5)
check_float_to_integer( 42.0)

-- 2's complement
-- int64_t + 0x10000000000000000 = uint64_t

-- -9223372036854775807 = 0x8000000000000001
-- -9223372036854775808 = 0x8000000000000000
-- -9223372036854775809 = 0x7FFFFFFFFFFFFFFF
--
--  9223372036854775807 = 0x7FFFFFFFFFFFFFFF
--  9223372036854775808 = 0x8000000000000000
--  9223372036854775809 = 0x8000000000000001

print "===="

local x = -9223372036854775807
print(math.type(x))
print(("0x%08X %d"):format(x, x))
print(("0x%08X %d"):format(x - 1, x - 1))
print(("0x%08X %d"):format(x - 2, x - 2))
print(("0x%08X %d"):format(x - 3, x - 3))

print "===="

local x = -9223372036854775808
print(math.type(x))

local x = tonumber "-9223372036854775808"
print(math.type(x))

local x = tonumber "-9223372036854775808"
print(math.type(x))

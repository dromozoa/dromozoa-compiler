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

local uint64 = require "dromozoa.compiler.primitives.uint64"

assert(uint64(0, 0):tostring_dec() == "0")
assert(uint64(0xDEAD, 0xBEEFFEEDFACE):tostring_dec() == "16045690985374415566")
assert(uint64(0xDEAD, 0xBEEFFEEDFACE):tostring_hex() == "0xDEADBEEFFEEDFACE")

local uint64_max = uint64(0xFFFF, 0xFFFFFFFFFFFF)
assert(uint64_max * uint64_max == uint64(0, 1))
assert(uint64_max * uint64(0, 2) == uint64(0xFFFF, 0xFFFFFFFFFFFE))

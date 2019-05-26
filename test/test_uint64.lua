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

-- assert(tostring(uint64()) == "0")
-- assert(tostring(uint64(0)) == "0")
-- assert(tostring(uint64(0, 0)) == "0")
-- assert(tostring(uint64(0x100000000, 0xFFFFFFFF)) == "0")
-- assert(tostring(uint64(0xFEEDFACE, 0xDEADBEEF)) == "16045690985374415566")

local zero = uint64()
assert(uint64(0) == zero)
assert(uint64(0, 0) == zero)
assert(uint64(0x100000000, 0xFFFFFFFF) == zero)
assert(uint64(0x100000000, 0xFFFFFFFE) == uint64(0x00000000, 0xFFFFFFFF))

assert(uint64(0xFEEDFACE, 0xDEADBEEF):tostring_hex() == "0xDEADBEEFFEEDFACE")

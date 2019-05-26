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

-- 1 << 48
local x = 0x1000000000000
print(x)
local d = 281474976710656
print(d)

-- 1 << 56
local x = 0x100000000000000
print(x)

-- 1 << 64
local x = 0x10000000000000000
print(x)
local d = 18446744073709551615
print(d)
-- assert(0x10000000000000000 ~= 18446744073709551615)

-- 1 << 24
local x = 0x1000000
local y = x * x
print(y)

-- 1 << 28
local x = 0x10000000
local y = x * x
print(y)

-- 1 << 32
local x = 0x100000000
local y = x * x
print(y)

local x = 0x080000000 -- 1 << 31
local y = 0x100000000 -- 1 << 32
local z = x * y -- int64(1 << 63)
print(x, y)
print(z)


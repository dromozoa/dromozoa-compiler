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

local builtin = require "dromozoa.runtime.builtin"

local stdout = builtin.native_io.stdout

local b = builtin.native_byte_array.construct(3)
b:set(0, 0x66)
b:set(1, 0x6F)
b:set(2, 0x6F)
stdout:write_byte_array(b)

b:resize(2)
stdout:write_byte_array(b)

b:resize(4)
b:set(2, 0x6F)
b:set(3, 0x0A)
stdout:write_byte_array(b)

local o = builtin.native_object.construct()
o:set("foo", b)
stdout:write_byte_array(o:get "foo")

local s = builtin.native_string.construct "bar\n"
stdout:write_string(s)

s:destruct()
o:destruct()
b:destruct()

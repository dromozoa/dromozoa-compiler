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
-- Under Section 7 of GPL version 3, you are granted additional
-- permissions described in the GCC Runtime Library Exception, version
-- 3.1, as published by the Free Software Foundation.
--
-- You should have received a copy of the GNU General Public License
-- and a copy of the GCC Runtime Library Exception along with
-- dromozoa-compiler.  If not, see <http://www.gnu.org/licenses/>.

local array = require "dromozoa.runtime.builtin.array"
local byte_array = require "dromozoa.runtime.builtin.byte_array"

local class = {}

function class.construct(n)
  local self = array.construct(2)
  array.set(self, 0, 4) -- LUA_TSTRING
  array.set(self, 1, byte_array.construct(n))
  return self
end

function class:destruct()
  local data = array.get(self, 1)
  byte_array.destruct(data)

end

function class:set(i, v)
  local data = array.get(self, 1)
  byte_array.set(data, i, v)
end

return class

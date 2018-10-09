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

local native_byte_array = require "dromozoa.runtime.builtin.native_byte_array"
local native_object = require "dromozoa.runtime.builtin.native_object"

local class = {}
local metatable = { __index = class }

function class.construct(n)
  local this = native_object.construct()
  this:set("type", 4)
  this:set("data", native_byte_array(n))
  return setmetatable({ this = this }, metatable)
end

function class:destruct()
  local this = self.this
  this:get("data"):destruct()
  this:set("data", nil)
  this:set("type", nil)




  self.data:destruct()
  self.data = nil
  self.type = nil
end

function class:resize(m)
  self.data:resize(m)
end

function class:set(i, v)
  self.data:set(i, v)
end

function class:get(i)
  return self.data:get(i)
end

return class

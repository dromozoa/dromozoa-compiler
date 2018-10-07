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

local class = {}

local rawget = rawget
local rawset = rawset

function class.new(n)
  local self = { n = n }
  for i = 0, n - 1 do
    rawset(self, i, 0)
  end
  return self
end

function class:set(i, v)
  return rawset(self, i, v)
end

function class:get(i)
  return rawget(self, i)
end

function class:size()
  return rawget(self, "n")
end

return class

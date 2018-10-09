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

local setmetatable = setmetatable
local stdout = io.stdout
local stderr = io.stderr
local char = string.char

local class = {}
local metatable = { __index = class }

class.stdout = setmetatable({ handle = stdout }, metatable)
class.stderr = setmetatable({ handle = stderr }, metatable)

function class:write(data)
  local handle = self.handle
  for i = 0, data:size() - 1 do
    handle:write(char(data:get(i)))
  end
  handle:flush()
end

return class

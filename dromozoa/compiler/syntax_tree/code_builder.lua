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

local class = {}
local metatable = { __index = class }

function class:MOVE(...)
  local stack = self.stack
  local codes = stack[#stack]
  codes[#codes + 1] = { [0] = "MOVE", ... }
  return self
end

return setmetatable(class, {
  __call = function (_, stack, node)
    return setmetatable({
      node = node;
      stack = stack;
    }, metatable)
  end;
})

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

local function visit(self, node, parent_path)
  local id = self.id + 1
  self.id = id

  local path = {}
  local n = #parent_path
  for i = 1, n do
    path[i] = parent_path[i]
  end
  path[n + 1] = id

  node.id = id
  node.path = path

  for i = 1, #node do
    local that = node[i]
    that.parent = node
    visit(self, that, path)
  end
end

return function (self)
  local accepted_node = self.accepted_node
  visit(self, accepted_node, {})
  return self
end

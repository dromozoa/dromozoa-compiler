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

local function visit(node, preorder_nodes, postorder_nodes, parent_path)
  local id = #preorder_nodes + 1
  local path = {}
  local n = #parent_path
  for i = 1, n do
    path[i] = parent_path[i]
  end
  path[n + 1] = id

  node.id = id
  node.path = path

  preorder_nodes[id] = node
  for i = 1, #node do
    visit(node[i], preorder_nodes, postorder_nodes, path)
  end
  postorder_nodes[#postorder_nodes + 1] = node
end

return function (self)
  local accepted_node = self.accepted_node
  local preorder_nodes = {}
  local postorder_nodes = {}
  visit(accepted_node, preorder_nodes, postorder_nodes, {})
  self.preorder_nodes = preorder_nodes
  self.postorder_nodes = postorder_nodes

  local terminal_nodes = self.terminal_nodes
  local n = #terminal_nodes
  local next_path = {}
  for i = n, 1, -1 do
    local node = terminal_nodes[i]
    node.next_path = next_path
    local path = node.path
    if path then
      next_path = path
    end
  end
  local prev_path = {}
  for i = 1, n do
    local node = terminal_nodes[i]
    node.prev_path = prev_path
    local path = node.path
    if path then
      prev_path = path
    else
      local next_path = node.next_path
      local path = {}
      for i = 1, #prev_path do
        local id = prev_path[i]
        if id == next_path[i] then
          path[i] = id
        else
          break
        end
      end
      node.path = path
    end
  end

  return self
end

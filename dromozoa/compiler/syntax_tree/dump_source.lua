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

local element = require "dromozoa.dom.element"
local space_separated = require "dromozoa.dom.space_separated"

local _ = element

local function prepare_paths(node, parent_path)
  local path = {}
  local n = #parent_path
  for i = 1, n do
    path[i] = parent_path[i]
  end
  path[n + 1] = node.id

  node.path = path

  for i = 1, #node do
    prepare_paths(node[i], path)
  end
end

local function prepare(self)
  local terminal_nodes = self.terminal_nodes
  local accepted_node = self.accepted_node

  prepare_paths(accepted_node, {})

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
end

local function dump(self)
  local terminal_nodes = self.terminal_nodes
  local source = self.source

  local html = _"div" { class = "text" }
  for i = 1, #terminal_nodes do
    local node = terminal_nodes[i]
    local symbol = node[0]
    local p = node.p
    local i = node.i
    local j = node.j
    local path = node.path

    if p < i then
      local prev_path = node.prev_path
      local class = space_separated {}
      for i = 1, #prev_path do
        local id = prev_path[i]
        if id == path[i] then
          class[i] = "node" .. id
        else
          break
        end
      end
      if #class == 0 then
        class = nil
      end
      html[#html + 1] = _"span" {
        class = class;
        source:sub(p, i - 1);
      }
    end

    if symbol == 1 then -- eof
      break
    end

    local class = space_separated {}
    for i = 1, #path do
      class[i] = "node" .. path[i]
    end
    class[#class + 1] = "node"
    html[#html + 1] = _"span" {
      id = id;
      class = class;
      ["data-node-id"] = node.id;
      source:sub(i, j);
    }
  end

  return html
end

return function (self, out)
  prepare(self)
  return dump(self)
end

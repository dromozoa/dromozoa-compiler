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

local code_builder = require "dromozoa.compiler.syntax_tree.code_builder"

local function generate(stack, node, symbol_table)
  local proto = node.proto
  if proto then
    local codes = {}
    proto.codes = codes
    stack = { codes }
  end

  local symbol = node[0]
  local n = #node
  local _ = code_builder(stack, node)

  local inorder = node.inorder
  for i = 1, n do
    generate(stack, node[i], symbol_table)
  end

  if symbol == symbol_table["local"] then
    local vars = node[1].vars
    local that = node[2]
    for i = 1, #that do
      _:MOVE(that[i].var, vars[i])
    end
  end
end

return function (self)
  generate(nil, self.accepted_node, self.symbol_table)
  return self
end

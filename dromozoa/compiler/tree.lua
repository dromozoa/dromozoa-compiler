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

local dump_protos = require "dromozoa.compiler.tree.dump_protos"
local dump_tree = require "dromozoa.compiler.tree.dump_tree"
local resolve = require "dromozoa.compiler.tree.resolve"
local transpile_es = require "dromozoa.compiler.tree.transpile_es"

local function construct(self, node)
  local id = self.id + 1
  self.id = id
  node.id = id
  for i = 1, #node do
    local that = node[i]
    that.parent = node
    construct(self, that)
  end
end

local class = {}
local metatable = { __index = class }

function class:resolve()
  return resolve(self)
end

function class:dump_protos(out)
  if type(out) == "string" then
    return dump_protos(self, assert(io.open(out, "w"))):close()
  else
    return dump_protos(self, out)
  end
end

function class:dump_tree(out)
  if type(out) == "string" then
    return dump_tree(self, assert(io.open(out, "w"))):close()
  else
    return dump_tree(self, out)
  end
end

function class:transpile_es(out, name)
  if type(out) == "string" then
    return transpile_es(self, assert(io.open(out, "w")), name):close()
  else
    return transpile_es(self, out, name)
  end
end

return setmetatable(class, {
  __call = function (_, parser, source, terminal_nodes, accepted_node)
    local self = {
      id = 0;
      symbol_names = parser.symbol_names;
      symbol_table = parser.symbol_table;
      max_terminal_symbol = max_terminal_symbol;
      source = source;
      terminal_nodes = terminal_nodes;
      accepted_node = accepted_node;
    }
    construct(self, accepted_node)
    return setmetatable(self, metatable)
  end;
})

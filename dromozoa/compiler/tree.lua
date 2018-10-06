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

local construct = require "dromozoa.compiler.tree.construct"
local write_html = require "dromozoa.compiler.tree.write_html"

local class = {}
local metatable = { __index = class }

function class:write_html(out)
  if type(out) == "string" then
    return write_html(self, assert(io.open(out, "w"))):close()
  else
    return write_html(self, out)
  end
end

return setmetatable(class, {
  __call = function (_, parser, source, terminal_nodes, accepted_node)
    return setmetatable(construct {
      symbol_names = parser.symbol_names;
      symbol_table = parser.symbol_table;
      max_terminal_symbol = max_terminal_symbol;
      source = source;
      terminal_nodes = terminal_nodes;
      accepted_node = accepted_node;
    }, metatable)
  end;
})

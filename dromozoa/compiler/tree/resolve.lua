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

local function attr(node, key)
  while node do
    local value = node[key]
    if value then
      return value
    end
    node = node.parent
  end
end

local function prepare(self)
  local symbol_table = self.symbol_table
  local preorder_nodes = self.preorder_nodes

  local protos = {}
  for i = 1, #preorder_nodes do
    local node = preorder_nodes[i]
    local symbol = node[0]

    if symbol == symbol_table.chunk then
      local env_name = {
        value = "_ENV";
        defs = {};
        refs = {};
        v = "B1";
      }

      local external_proto = {
        constants = {};
        names = { env_name };
        labels = {};
        upvalues = {};
        vararg = false;
        A = 0;
        B = 1;
        L = 0;
      }

      local external_scope = {
        proto = external_proto;
        names = { env_name };
        labels = {};
      }

      local proto = {
        index = 1;
        parent = external_proto;
        constants = {};
        names = {};
        labels = {};
        upvalues = {
          {
            name = env_name;
            u = "B1";
            v = "U1";
          };
        };
        vararg = true;
      }

      node.proto = proto
      protos[1] = proto

      node.scope = {
        proto = proto;
        parent = external_scope;
        names = {};
        labels = {};
      }
    elseif symbol == symbol_table.funcbody then
      local index = #protos + 1
      local proto = {
        index = index;
        parent = attr(node.parent, "proto");
        constants = {};
        names = {};
        labels = {};
        upvalues = {};
        vararg = false;
        A = 0;
        B = 0;
        L = 0;
      }
      node.proto = proto
      protos[index] = proto
    end

    if node.scope then
      node.scope = {
        proto = attr(node, "proto");
        parent = attr(node.parent, "scope");
        names = {};
        labels = {};
      }
    end
  end
  self.protos = protos
end

return function (self)
  prepare(self)
end

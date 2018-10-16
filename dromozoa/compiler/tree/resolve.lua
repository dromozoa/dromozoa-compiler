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

local symbol_value = require "dromozoa.parser.symbol_value"

local function attr(node, key)
  while node do
    local value = node[key]
    if value then
      return value
    end
    node = node.parent
  end
end

local function def_label(node)
  local source = symbol_value(node)
  local scope = attr(node, "scope")
  local proto = scope.proto

  local scope_labels = scope.labels
  local n = #scope_labels
  for i = n, 1, -1 do
    local label = scope_labels[i]
    if label.source == source then
      return nil, ("label %q already defined"):format(source), node.i
    end
  end

  local proto_labels = proto.labels
  local index = #proto_labels + 1
  local label = {
    source = source;
    defs = { node.id };
    refs = {};
    "L" .. index;
  }

  scope_labels[n + 1] = label
  proto_labels[index] = label

  return label
end

local function ref_label(node)
  local source = symbol_value(node)
  local scope = attr(node, "scope")
  local proto = scope.proto

  repeat
    local scope_labels = scope.labels
    for i = #scope_labels, 1, -1 do
      local label = scope_labels[i]
      if label.source == source then
        local refs = label.refs
        refs[#refs + 1] = node.id
        return label
      end
    end
    scope = scope.parent
  until not scope or scope.proto ~= proto

  return nil, ("no visible label %q for <goto>"):format(source), node.i
end

local function prepare(self)
  local symbol_table = self.symbol_table
  local preorder_nodes = self.preorder_nodes

  local protos = {}
  for i = 1, #preorder_nodes do
    local node = preorder_nodes[i]
    local symbol = node[0]

    if symbol == symbol_table.chunk then
      local env = {
        source = "_ENV";
        defs = {};
        refs = {};
        "B1";
      }

      local external_proto = {
        constants = {};
        names = { env };
        labels = {};
        upvalues = {};
        A = 0;
        B = 1;
      }

      local external_scope = {
        proto = external_proto;
        names = { env };
        labels = {};
      }

      local proto = {
        parent = external_proto;
        constants = {};
        names = {};
        labels = {};
        upvalues = {
          {
            name = env;
            "U1";
            "B1";
          };
        };
        vararg = true;
        A = 0;
        B = 0;
        "P1";
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
        parent = attr(node.parent, "proto");
        constants = {};
        names = {};
        labels = {};
        upvalues = {};
        self = false;
        vararg = false;
        A = 0;
        B = 0;
        "P" .. index;
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
  return self
end

local function process_labels(self)
  local symbol_table = self.symbol_table
  local preorder_nodes = self.preorder_nodes
  local n = #preorder_nodes

  for i = 1, n do
    local node = preorder_nodes[i]
    if node[0] == symbol_table["::"] then
      local that = node[1]
      local result, message, i = def_label(that)
      if not result then
        return nil, message, i
      end
      that.v = result[1]
    end
  end

  for i = 1, n do
    local node = preorder_nodes[i]
    if node[0] == symbol_table["goto"] then
      local that = node[1]
      local result, message, i = ref_label(that)
      if not result then
        return nil, message, i
      end
      that.v = result[1]
    end
  end

  return self
end

local function process2(self)
  local symbol_table = self.symbol_table
  local preorder_nodes = self.preorder_nodes
  local n = #preorder_nodes







  return self
end

return function (self)
  prepare(self)
  local result, message, i = process_labels(self)
  if not result then
    return nil, message, i
  end
  local result, message, i = process2(self)
  if not result then
    return nil, message, i
  end
  return self
end

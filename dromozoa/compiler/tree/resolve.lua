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

local function ref_constant(node, type)
  local source = symbol_value(node)
  local proto = attr(node, "proto")

  local constants = proto.constants
  local n = #constants
  for i = n, 1, -1 do
    local constant = constants[i]
    if constant.type == type and constant.source == source then
      local refs = constant.refs
      refs[#refs + 1] = node.id
      return constant
    end
  end

  local index = n + 1
  local constant = {
    type = type;
    source = source;
    refs = { node.id };
    "K" .. index;
  }

  constants[index] = constant
  return constant
end

local function def_name(node, key, source)
  if not source then
    source = symbol_value(node)
  end
  local scope = attr(node, "scope")
  local proto = scope.proto

  local index = proto[key] + 1
  proto[key] = index

  local name = {
    source = source;
    defs = { node.id };
    refs = {};
    upvalue_defs = {};
    upvalue_refs = {};
    key .. index;
  }

  local scope_names = scope.names
  scope_names[#scope_names + 1] = name
  local proto_names = proto.names
  proto_names[#proto_names + 1] = name

  return name
end

local function resolve_name(node, source)
  if not source then
    source = symbol_value(node)
  end
  local scope = attr(node, "scope")
  local proto = scope.proto

  repeat
    local names = scope.names
    for i = #names, 1, -1 do
      local name = names[i]
      if name.source == source then


      end
    end
    scope = scope.parent
  until not scope
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
        source = "_ENV";
        defs = {};
        refs = {};
        updefs = {};
        uprefs = {};
        "B1";
      }

      local external_proto = {
        constants = {};
        names = { env_name };
        labels = {};
        upvalues = {};
        A = 0;
        B = 1;
      }

      local external_scope = {
        proto = external_proto;
        names = { env_name };
        labels = {};
      }

      local proto = {
        parent = external_proto;
        constants = {};
        names = {};
        labels = {};
        upvalues = {
          {
            name = env_name;
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

local function resolve_labels(self)
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

local function resolve(self)
  local symbol_table = self.symbol_table
  local preorder_nodes = self.preorder_nodes
  local n = #preorder_nodes

  for i = 1, n do
    local node = preorder_nodes[i]
    local symbol = node[0]
    if symbol == symbol_table.funcname and node.self then
      node.parent[2].proto.self = true
    elseif symbol == symbol_table.namelist and node.vararg then
      node.parent.proto.vararg = true
    end
  end

  for i = 1, n do
    local node = preorder_nodes[i]
    local symbol = node[0]
    if symbol == symbol_table.funcbody then
      local proto = node.proto
      if proto.self then
        def_name(node, "A", "self")
      end
      local namelist = node[1]
      for j = 1, #namelist do
        local name = namelist[j]
        name.v = def_name(name, "A")[1]
      end
    elseif symbol == symbol_table["nil"] then
      node.v = "NIL"
    elseif symbol == symbol_table["false"] then
      node.v = "FALSE"
    elseif symbol == symbol_table["true"] then
      node.v = "TRUE"
    elseif symbol == symbol_table.IntegerConstant then
      node.v = assert(ref_constant(node, "integer")[1])
    elseif symbol == symbol_table.FloatConstant then
      node.v = ref_constant(node, "float")[1]
    elseif symbol == symbol_table.LiteralString then
      node.v = ref_constant(node, "string")[1]
    elseif symbol == symbol_table["..."] then
      local proto = attr(node, "proto")
      if not proto.vararg then
        return nil, "cannot use '...' outside a vararg function", node.i
      end
      node.v = "V"
    end
  end

  return self
end

return function (self)
  prepare(self)
  local result, message, i = resolve_labels(self)
  if not result then
    return nil, message, i
  end
  local result, message, i = resolve(self)
  if not result then
    return nil, message, i
  end
  return self
end

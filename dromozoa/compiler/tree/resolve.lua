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

local function declare_name(node, key, source)
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
    updefs = {};
    uprefs = {};
    key .. index;
  }

  local scope_names = scope.names
  scope_names[#scope_names + 1] = name
  local proto_names = proto.names
  proto_names[#proto_names + 1] = name

  return name
end

-- TODO recursive function
local function resolve_upvalue(proto, name, parent_upvalue)
  local upvalues = proto.upvalues
  local n = #upvalues
  for i = n, 1, -1 do
    local upvalue = upvalues[i]
    if upvalue.name == name then
      return upvalue
    end
  end

  local index = n + 1
  local upvalue = {
    name = name;
    "U" .. index;
  }
  if parent_upvalue then
    upvalue[2] = parent_upvalue[1]
  else
    upvalue[2] = name[1]
  end

  upvalues[index] = upvalue
  return upvalue
end

local function resolve_name(node, key, upkey, source)
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
        local resolved_proto = scope.proto
        if resolved_proto == proto then
          local refs = name[key]
          refs[#refs + 1] = node.id
          return name
        else
          local uprefs = name[upkey]
          uprefs[#uprefs + 1] = node.id

          local protos = {}
          local n = 0
          repeat
            n = n + 1
            protos[n] = proto
            proto = proto.parent
          until resolved_proto == proto

          local upvalue
          for j = n, 1, -1 do
            upvalue = resolve_upvalue(protos[j], name, upvalue)
          end
          return upvalue
        end
      end
    end
    scope = scope.parent
  until not scope
end

local function ref_name(node)
  return resolve_name(node, "refs", "uprefs")
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
    else
      if symbol == symbol_table.funcbody then
        local index = #protos + 1
        local proto = {
          parent = attr(node.parent, "proto");
          constants = {};
          names = {};
          labels = {};
          upvalues = {};
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
    if symbol == symbol_table.funcname then
      if node.self then
        node.parent[2].proto.self = true
      end
      if #node == 1 then
        if node.def then
          node[1].def = true
        else
          node[1].ref = true
        end
      end
    elseif symbol == symbol_table.var then
      if #node == 1 then
        if node.def then
          node[1].def = true
        else
          node[1].ref = true
        end
      end
    elseif symbol == symbol_table.namelist then
      if node.vararg then
        node.parent.proto.vararg = true
      end
      if node.parlist then
        for j = 1, #node do
          node[j].param = true
        end
      else
        for j = 1, #node do
          node[j].declare = true
        end
      end
    elseif symbol == symbol_table.funcbody then
      node[1].parlist = true
    end
  end

  for i = 1, n do
    local node = preorder_nodes[i]
    local symbol = node[0]
    if symbol == symbol_table.namelist then
      if node.parlist then
        if attr(node, "proto").self then
          declare_name(node, "A", "self")
        end
      end
    elseif symbol == symbol_table["nil"] then
      node.v = "NIL"
    elseif symbol == symbol_table["false"] then
      node.v = "FALSE"
    elseif symbol == symbol_table["true"] then
      node.v = "TRUE"
    elseif symbol == symbol_table.IntegerConstant then
      node.v = ref_constant(node, "integer")[1]
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
    elseif symbol == symbol_table.Name then
      if node.param then
        node.v = declare_name(node, "A")[1]
      elseif node.declare then
        node.v = declare_name(node, "B")[1]
      elseif node.key then
        node.v = ref_constant(node, "string")[1]
      elseif node.def then
        -- TODO
      elseif node.ref then
        local name = ref_name(node)
        if name then
          node.v = name[1]
        else
          print("_ENV." .. symbol_value(node))
        end
        -- TODO
      else
        -- DEBUG
        assert(node.v :find "^L%d+$")
      end
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

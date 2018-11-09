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
local decode_var = require "dromozoa.compiler.syntax_tree.decode_var"
local encode_var = require "dromozoa.compiler.syntax_tree.encode_var"

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
  local m = #scope_labels
  for i = m, 1, -1 do
    local label = scope_labels[i]
    if label.source == source then
      return nil, ("label %q already defined"):format(source), node.i
    end
  end

  local proto_labels = proto.labels
  local n = #proto_labels
  local label = {
    source = source;
    def = { node.id };
    use = {};
    encode_var("L", n);
  }

  scope_labels[m + 1] = label
  proto_labels[n + 1] = label
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
        local use = label.use
        use[#use + 1] = node.id
        return label
      end
    end
    scope = scope.parent
  until not scope or scope.proto ~= proto

  return nil, ("no visible label %q for <goto>"):format(source), node.i
end

local function ref_constant(node, type, source)
  if not source then
    source = symbol_value(node)
  end
  local proto = attr(node, "proto")

  local constants = proto.constants
  local n = #constants
  for i = n, 1, -1 do
    local constant = constants[i]
    if constant.type == type and constant.source == source then
      local use = constant.use
      use[#use + 1] = node.id
      return constant
    end
  end

  local constant = {
    type = type;
    source = source;
    use = { node.id };
    encode_var("K", n);
  }

  constants[n + 1] = constant
  return constant
end

local function declare_name(node, key, source)
  if not source then
    source = symbol_value(node)
  end
  local scope = attr(node, "scope")
  local proto = scope.proto

  local n = proto[key]
  proto[key] = n + 1

  local name = {
    source = source;
    def = { node.id };
    use = {};
    updef = {};
    upuse = {};
    encode_var(key, n);
  }

  local scope_names = scope.names
  scope_names[#scope_names + 1] = name
  local proto_names = proto.names
  proto_names[#proto_names + 1] = name
  return name
end

local function resolve_upvalue(proto, name, parent_upvalue)
  local upvalues = proto.upvalues
  local n = #upvalues
  for i = n, 1, -1 do
    local upvalue = upvalues[i]
    if upvalue.name == name then
      return upvalue
    end
  end

  local upvalue = {
    name = name;
    encode_var("U", n);
  }
  if parent_upvalue then
    upvalue[2] = parent_upvalue[1]
  else
    upvalue[2] = name[1]
  end

  upvalues[n + 1] = upvalue
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
          local use = name[key]
          use[#use + 1] = node.id
          return name
        else
          local upuse = name[upkey]
          upuse[#upuse + 1] = node.id

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

local function def_name(node)
  return resolve_name(node, "def", "updef")
end

local function ref_name(node)
  return resolve_name(node, "use", "upuse")
end

local function normalize_self(self, node, symbol_table)
  local id = self.id + 1
  self.id = id

  local var_node = node[1]
  local key_node = node[2]

  local that = {
    [0] = symbol_table.var;
    parent = node;
    id = id;
    var_node;
    key_node;
  }

  var_node.parent = that
  key_node.parent = that

  node[1] = that
  node[2] = node[3]
  node[3] = nil
end

local function normalize_env(self, node, symbol_table)
  local that = node.parent

  local var_id = self.id + 1
  local env_id = var_id + 1
  self.id = env_id

  local env_node = {
    [0] = symbol_table.Name;
    rs = "_ENV";
    ri = 1;
    rj = 4;
    id = env_id;
    use = true;
  }

  local var_node = {
    [0] = symbol_table.var;
    parent = that;
    id = var_id;
    env_node;
  }

  env_node.parent = var_node

  node.def = nil
  node.use = nil
  node.key = true

  that[1] = var_node;
  that[2] = node;

  env_node.var = ref_name(env_node)[1]
  node.var = ref_constant(node, "string")[1]
end

local function assign_var(node, key)
  if not key then
    key = "C"
  end
  local proto = attr(node, "proto")
  local n = proto[key]
  proto[key] = n + 1
  return encode_var(key, n)
end

local function prepare_protos(node, symbol_table, protos)
  local symbol = node[0]
  if symbol == symbol_table.chunk then
    local env_name = {
      source = "_ENV";
      def = {};
      use = {};
      updef = {};
      upuse = {};
      encode_var("B", 0);
    }

    local external_proto = {
      labels = {};
      constants = {};
      upvalues = {};
      names = { env_name };
      A = 0;
      B = 1;
      C = 0;
    }

    local external_scope = {
      proto = external_proto;
      labels = {};
      names = { env_name };
    }

    local proto = {
      parent = external_proto;
      labels = {};
      constants = {};
      upvalues = {
        {
          name = env_name;
          encode_var("U", 0);
          encode_var("B", 0);
        };
      };
      names = {};
      A = 0;
      B = 0;
      C = 0;
      vararg = true;
      encode_var("P", 0);
    }
    node.proto = proto
    protos[1] = proto

    node.scope = {
      proto = proto;
      parent = external_scope;
      labels = {};
      names = {};
    }
  else
    if symbol == symbol_table.funcbody then
      local n = #protos
      local proto = {
        parent = attr(node.parent, "proto");
        labels = {};
        constants = {};
        upvalues = {};
        names = {};
        A = 0;
        B = 0;
        C = 0;
        encode_var("P", n);
      }
      node.proto = proto
      protos[n + 1] = proto
    end

    if node.scope then
      node.scope = {
        proto = attr(node, "proto");
        parent = attr(node.parent, "scope");
        labels = {};
        names = {};
      }
    end
  end

  for i = 1, #node do
    prepare_protos(node[i], symbol_table, protos)
  end
end

local function prepare_attrs(node, symbol_table)
  local symbol = node[0]
  local n = #node

  if symbol == symbol_table["="] then
    node[1].adjust = #node[2]
  elseif symbol == symbol_table["local"] then
    node[1].adjust = #node[2]
  elseif symbol == symbol_table.funcname then
    if node.self then
      node.parent[1].proto.self = true
    end
    if n == 1 then
      if node.def then
        node[1].def = true
      else
        node[1].use = true
      end
    end
  elseif symbol == symbol_table.var then
    if n == 1 then
      if node.def then
        node[1].def = true
      else
        node[1].use = true
      end
    end
  elseif symbol == symbol_table.namelist then
    if node.vararg then
      node.parent.proto.vararg = true
    end
    if node.parlist then
      for j = 1, n do
        node[j].param = true
      end
    else
      for j = 1, n do
        node[j].declare = true
      end
    end
  elseif symbol == symbol_table.explist then
    if n > 0 then
      local adjust = node.adjust
      if adjust then
        if n > adjust then
          for i = adjust + 1, n do
            node[i].adjust = 0
          end
        elseif n < adjust then
          node[n].adjust = adjust - n + 1
        end
      else
        node[n].adjust = -1
      end
    end
  elseif symbol == symbol_table.funcbody then
    node[1].parlist = true
  elseif symbol == symbol_table.fieldlist then
    if n > 0 then
      local that = node[n]
      if #that == 1 then
        that[1].adjust = -1
      end
    end
  end

  for i = 1, n do
    prepare_attrs(node[i], symbol_table)
  end
end

local function def_labels(node, symbol_table)
  if node[0] == symbol_table["::"] then
    local that = node[1]
    local result, message, i = def_label(that)
    if not result then
      return nil, message, i
    end
    that.label = result[1]
  end

  for i = 1, #node do
    local result, message, i = def_labels(node[i], symbol_table)
    if not result then
      return nil, message, i
    end
  end

  return node
end

local function ref_labels(node, symbol_table)
  if node[0] == symbol_table["goto"] then
    local that = node[1]
    local result, message, i = ref_label(that)
    if not result then
      return nil, message, i
    end
    attr(node, "proto")["goto"] = true
    that.label = result[1]
  end

  for i = 1, #node do
    local result, message, i = ref_labels(node[i], symbol_table)
    if not result then
      return nil, message, i
    end
  end

  return node
end

local function resolve_names(self, node, symbol_table)
  local symbol = node[0]

  if symbol == symbol_table.namelist then
    if node.parlist then
      if attr(node, "proto").self then
        declare_name(node, "A", "self")
      end
    end
  elseif symbol == symbol_table["nil"] then
    node.var = encode_var "NIL"
  elseif symbol == symbol_table["false"] then
    node.var = encode_var "FALSE"
  elseif symbol == symbol_table["true"] then
    node.var = encode_var "TRUE"
  elseif symbol == symbol_table.IntegerConstant then
    node.var = ref_constant(node, "integer")[1]
  elseif symbol == symbol_table.FloatConstant then
    node.var = ref_constant(node, "float")[1]
  elseif symbol == symbol_table.LiteralString then
    node.var = ref_constant(node, "string")[1]
  elseif symbol == symbol_table["..."] then
    local proto = attr(node, "proto")
    if not proto.vararg then
      return nil, "cannot use '...' outside a vararg function", node.i
    end
    proto.V = true
    local adjust = node.adjust
    if adjust then
      if adjust ~= 0 then
        node.var = encode_var "V"
      end
    else
      node.adjust = 1
      node.var = encode_var("V", 0)
    end
  elseif symbol == symbol_table.functioncall then
    if node.self then
      normalize_self(self, node, symbol_table)
    end
  elseif symbol == symbol_table.Name then
    if node.param then
      node.var = declare_name(node, "A")[1]
    elseif node.declare then
      node.var = declare_name(node, "B")[1]
    elseif node.key then
      node.var = ref_constant(node, "string")[1]
    elseif node.def then
      local name = def_name(node)
      if name then
        node.var = name[1]
      else
        normalize_env(self, node, symbol_table)
      end
    elseif node.use then
      local name = ref_name(node)
      if name then
        node.var = name[1]
      else
        normalize_env(self, node, symbol_table)
      end
    end
  end

  for i = 1, #node do
    local result, message, i = resolve_names(self, node[i], symbol_table)
    if not result then
      return nil, message, i
    end
  end

  return node
end

local function resolve_vars(self, node, symbol_table)
  local symbol = node[0]
  local n = #node

  for i = 1, n do
    resolve_vars(self, node[i], symbol_table)
  end

  if symbol == symbol_table["="] then
    local lvars = {}
    local rvars = node[1].vars
    local that = node[2]
    for i = 1, #rvars do
      local var = rvars[i]
      if i == 1 then
        local key, i = decode_var(var)
        if key == "T" then
          var = assign_var(node)
        end
      else
        local key, i = decode_var(var)
        if key == "U" or key == "A" or key == "B" or key == "T" then
          var = assign_var(node)
        end
      end
      lvars[i] = var
      that[i].def = var
    end
    node.vars = lvars
  elseif symbol == symbol_table["function"] then
    node[2].def = node[1].var
  elseif symbol == symbol_table["for"] then
    if n == 4 then -- numerical for without step
      node.vars = {
        assign_var(node, "B"); -- var
        assign_var(node, "B"); -- limit
        ref_constant(node, "integer", "1")[1]; -- step
        assign_var(node);
      }
    elseif n == 5 then -- numerical for with step
      node.vars = {
        assign_var(node, "B"); -- var
        assign_var(node, "B"); -- limit
        assign_var(node, "B"); -- step
        ref_constant(node, "integer", "0")[1];
        assign_var(node);
        assign_var(node);
        assign_var(node);
        assign_var(node);
      }
    else -- generic for
      node.vars = {
        assign_var(node, "B"); -- var
        assign_var(node, "B"); -- limit
        assign_var(node, "B"); -- step
        assign_var(node);
      }
      if n == 3 then -- generic for
        attr(node, "proto").T = true
      end
    end
  elseif symbol == symbol_table.funcname or symbol == symbol_table.var then
    if n == 1 then
      node.var = node[1].var
    elseif not node.def then
      node.var = assign_var(node)
    end
  elseif symbol == symbol_table.explist then
    local adjust = node.adjust
    if adjust then
      local vars = {}
      for i = 1, n do
        local that = node[i]
        local var = that.var
        if var then
          local key, j = decode_var(var)
          if key == "V" or key == "T" then
            for j = 0, that.adjust - 1 do
              vars[i + j] = encode_var(key, j)
            end
          else
            vars[i] = var
          end
        end
      end
      for i = #vars + 1, adjust do
        vars[i] = encode_var "NIL"
      end
      node.vars = vars
    end
  elseif symbol == symbol_table["("] then
    node.var = node[1].var
  elseif symbol == symbol_table.functioncall then
    local adjust = node.adjust
    if adjust then
      if adjust ~= 0 then
        attr(node, "proto").T = true
        node.var = "T"
      end
    else
      node.adjust = 1
      node.var = assign_var(node)
    end
    if node.self then
      node.self = node[1][1].var
    end
  elseif symbol == symbol_table.funcbody then
    node.var = assign_var(node.parent)
  elseif symbol == symbol_table.fieldlist or node.binop or node.unop then
    node.var = assign_var(node)
  end
end

return function (self)
  local symbol_table = self.symbol_table
  local accepted_node = self.accepted_node

  local protos = {}
  prepare_protos(accepted_node, symbol_table, protos)
  self.protos = protos

  prepare_attrs(accepted_node, symbol_table)

  local result, message, i = def_labels(accepted_node, symbol_table)
  if not result then
    return nil, message, i
  end

  local result, message, i = ref_labels(accepted_node, symbol_table)
  if not result then
    return nil, message, i
  end

  local result, message, i = resolve_names(self, accepted_node, symbol_table)
  if not result then
    return nil, message, i
  end

  resolve_vars(self, accepted_node, symbol_table)

  return self
end

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

local graph = require "dromozoa.graph"
local code_builder = require "dromozoa.compiler.syntax_tree.code_builder"

local unpack = table.unpack or unpack

local function generate_tree_code(stack, node, symbol_table)
  local proto = node.proto
  if proto then
    code_builder(stack, node):CLOSURE(node.var, proto[1])
    local code = { block = true }
    proto.tree_code = code
    stack = { code }
  end

  local symbol = node[0]
  local n = #node
  local inorder = node.inorder
  local binop = node.binop
  local unop = node.unop
  local _ = code_builder(stack, node)

  if symbol == symbol_table["while"] or symbol == symbol_table["repeat"] then
    _:LOOP()
  end

  for i = 1, n do
    generate_tree_code(stack, node[i], symbol_table)
    if i == inorder then
      if symbol == symbol_table["while"] then
        _:COND_IF(node[1].var, "FALSE")
         :  BREAK()
         :COND_END()
      elseif symbol == symbol_table["for"] then
        if n == 4 then -- numerical for without step
          local vars = node.vars
          _:TONUMBER(vars[1], node[1].var)
           :TONUMBER(vars[2], node[2].var)
           :SUB(vars[1], vars[1], vars[3])
           :LOOP()
           :  ADD(vars[1], vars[1], vars[3])
           :  LT(vars[4], vars[2], vars[1])
           :  COND_IF(vars[4], "TRUE")
           :    BREAK()
           :  COND_END()
           :  MOVE(node[3].var, vars[1])
        elseif n == 5 then -- numerical for with step
          local vars = node.vars
          _:TONUMBER(vars[1], node[1].var)
           :TONUMBER(vars[2], node[2].var)
           :TONUMBER(vars[3], node[3].var)
           :SUB(vars[1], vars[1], vars[3])
           :LOOP()
           :  ADD(vars[1], vars[1], vars[3])
           :  LE(vars[4], vars[5], vars[3])
           :  COND_IF(vars[4], "TRUE")
           :    LT(vars[4], vars[2], vars[1])
           :    COND_IF(vars[4], "TRUE")
           :      BREAK()
           :    COND_END()
           :  COND_END()
           :  LT(vars[4], vars[3], vars[5])
           :  COND_IF(vars[4], "TRUE")
           :    LT(vars[4], vars[1], vars[2])
           :    COND_IF(vars[4], "TRUE")
           :      BREAK()
           :    COND_END()
           :  COND_END()
           :  MOVE(node[4].var, vars[1])
        else -- generic for
          local rvars = node[1].vars
          local lvars = node.vars
          _:MOVE(lvars[1], rvars[1])
           :MOVE(lvars[2], rvars[2])
           :MOVE(lvars[3], rvars[3])
           :LOOP()
           :  CALL("T", lvars[1], lvars[2], lvars[3])
          local that = node[2]
          for i = 1, #that do
            _:MOVE(that[i].var, "T" .. i - 1)
          end
          _:EQ(lvars[4], that[1].var, "NIL")
           :COND_IF(lvars[4], "TRUE")
           :  BREAK()
           :COND_END()
           :MOVE(lvars[3], that[1].var)
        end
      elseif symbol == symbol_table.conditional then
        _:COND_ELSE()
      elseif symbol == symbol_table["if"] then
        _:COND_IF(node[1].var, "TRUE")
      elseif binop == "AND" then
        _:MOVE(node.var, node[1].var)
         :COND_IF(node.var, "TRUE")
      elseif binop == "OR" then
        _:MOVE(node.var, node[1].var)
         :COND_IF(node.var, "FALSE")
      end
    end
  end

  if symbol == symbol_table["local"] then
    local vars = node[1].vars
    local that = node[2]
    for i = 1, #that do
      _:MOVE(that[i].var, vars[i])
    end
  elseif symbol == symbol_table["::"] then
    _:LABEL(node[1].label)
  elseif symbol == symbol_table["break"] then
    _:BREAK()
  elseif symbol == symbol_table["goto"] then
    _:GOTO(node[1].label)
  elseif symbol == symbol_table["function"] then
    local that = node[1]
    if that.declare then
      _:MOVE(that.var, node[2].var)
    end
  elseif symbol == symbol_table["while"] then
    _:LOOP_END()
  elseif symbol == symbol_table["repeat"] then
    _:COND_IF(node[2].var, "TRUE")
     :  BREAK()
     :COND_END()
     :LOOP_END()
  elseif symbol == symbol_table["for"] then
    _:LOOP_END()
  elseif symbol == symbol_table["return"] then
    local that = node[1]
    local args = {}
    for i = 1, #that do
      args[i] = that[i].var
    end
    _:RETURN(unpack(args))
  elseif symbol == symbol_table.conditional then
    _:COND_END()
  elseif symbol == symbol_table.funcname or symbol == symbol_table.var then
    if node.def then
      if n == 2 then
        _:SETTABLE(node[1].var, node[2].var, node.def)
      else
        _:MOVE(node[1].var, node.def)
      end
    else
      if n == 2 then
        _:GETTABLE(node.var, node[1].var, node[2].var)
      end
    end
  elseif symbol == symbol_table.explist then
    local that = node.parent
    if that[0] == symbol_table["="] then
      local lvars = that.vars
      local rvars = node.vars
      for i = 1, #lvars do
        local lvar = lvars[i]
        local rvar = rvars[i]
        if lvar ~= rvar then
          _:MOVE(lvar, rvar)
        end
      end
    end
  elseif binop == "GT" then
    _:LT(node.var, node[2].var, node[1].var)
  elseif binop == "GE" then
    _:LE(node.var, node[2].var, node[1].var)
  elseif binop == "AND" or binop == "OR" then
    _:MOVE(node.var, node[2].var)
     :COND_END()
  elseif binop then
    _[binop](_, node.var, node[1].var, node[2].var)
  elseif unop then
    _[unop](_, node.var, node[1].var)
  elseif symbol == symbol_table.functioncall then
    local that = node[2]
    local args = {}
    for i = 1, #that do
      args[i] = that[i].var
    end
    if node.self then
      _:CALL(node.var or "NIL", node[1].var, node.self, unpack(args))
    else
      _:CALL(node.var or "NIL", node[1].var, unpack(args))
    end
  elseif symbol == symbol_table.fieldlist then
    _:NEWTABLE(node.var)
    for i = 1, n do
      local that = node[i]
      if #that == 2 then
        _:SETTABLE(node.var, that[2].var, that[1].var)
      end
    end
    local index = 0
    for i = 1, n do
      local that = node[i]
      if #that == 1 then
        index = index + 1
        _:SETLIST(node.var, index, that[1].var)
      end
    end
  end
end

local function generate_flat_code(proto, flat_code, code, break_label)
  local name = code[0]

  if code.block then
    if name == "LOOP" then
      local n = proto.M
      local x = "M" .. n
      local y = "M" .. n + 1
      proto.M = n + 2
      flat_code[#flat_code + 1] = { [0] = "LABEL", x }
      for i = 1, #code do
        generate_flat_code(proto, flat_code, code[i], y)
      end
      flat_code[#flat_code + 1] = { [0] = "GOTO", x }
      flat_code[#flat_code + 1] = { [0] = "LABEL", y }
    elseif name == "COND" then
      local cond = code[1]
      if #code == 2 then
        local n = proto.M
        local x = "M" .. n
        local y = "M" .. n + 1
        proto.M = n + 2
        flat_code[#flat_code + 1] = { [0] = "COND", cond[1], cond[2], x, y }
        flat_code[#flat_code + 1] = { [0] = "LABEL", x }
        generate_flat_code(proto, flat_code, code[2], break_label)
        flat_code[#flat_code + 1] = { [0] = "LABEL", y }
      else
        local n = proto.M
        local x = "M" .. n
        local y = "M" .. n + 1
        local z = "M" .. n + 2
        proto.M = n + 3
        flat_code[#flat_code + 1] = { [0] = "COND", cond[1], cond[2], x, y }
        flat_code[#flat_code + 1] = { [0] = "LABEL", x }
        generate_flat_code(proto, flat_code, code[2], break_label)
        flat_code[#flat_code + 1] = { [0] = "GOTO", z }
        flat_code[#flat_code + 1] = { [0] = "LABEL", y }
        generate_flat_code(proto, flat_code, code[3], break_label)
        flat_code[#flat_code + 1] = { [0] = "LABEL", z }
      end
    else
      for i = 1, #code do
        generate_flat_code(proto, flat_code, code[i], break_label)
      end
    end
  else
    if name == "BREAK" then
      flat_code[#flat_code + 1] = { [0] = "GOTO", break_label }
    else
      flat_code[#flat_code + 1] = code
    end
  end
end

local function generate_basic_blocks(proto)
  local flat_code = proto.flat_code
  local n = #flat_code
  local g = graph()

  local entry_uid = g:add_vertex()
  local uid
  local uids = { entry_uid }
  local block
  local blocks = { [entry_uid] = {} }
  local labels = {}

  for i = 1, n do
    local code = flat_code[i]
    local name = code[0]
    if name == "LABEL" then
      uid = g:add_vertex()
      uids[#uids + 1] = uid
      local label = code[1]
      block = { label = label }
      blocks[uid] = block
      labels[label] = uid
    else
      if not uid then
        uid = g:add_vertex()
        uids[#uids + 1] = uid
        block = {}
        blocks[uid] = block
      end
      block[#block + 1] = code
      if name == "CALL" or name == "RETURN" or name == "GOTO" or name == "COND" then
        uid = nil
      end
    end
  end

  local exit_uid = g:add_vertex()
  uids[#uids + 1] = exit_uid
  blocks[exit_uid] = {}
  local jumps = {}

  local this_uid = uids[1]
  for i = 2, #uids do
    local next_uid = uids[i]
    local block = blocks[this_uid]
    local code = block[#block]
    local name
    if code then
      name = code[0]
    end
    if name == "GOTO" then
      block[#block] = nil
      local label = code[1]
      block["goto"] = label
      g:add_edge(this_uid, labels[label])
    elseif name == "RETURN" then
      g:add_edge(this_uid, exit_uid)
    elseif name == "COND" then
      local then_eid = g:add_edge(this_uid, labels[code[3]])
      local else_eid = g:add_edge(this_uid, labels[code[4]])
      jumps[then_eid] = "THEN"
      jumps[else_eid] = "ELSE"
    else
      g:add_edge(this_uid, next_uid)
    end
    this_uid = next_uid
  end

  proto.basic_blocks = {
    g = g;
    entry_uid = entry_uid;
    exit_uid = exit_uid;
    blocks = blocks;
    jumps = jumps;
  }
end

return function (self)
  generate_tree_code({ { block = true } }, self.accepted_node, self.symbol_table)

  local protos = self.protos
  local n = #protos
  for i = 1, n do
    local proto = protos[i]
    local flat_code = { block = true }
    proto.M = 0
    proto.flat_code = flat_code
    generate_flat_code(proto, flat_code, proto.tree_code)
  end

  for i = 1, n do
    generate_basic_blocks(protos[i])
  end

  return self
end

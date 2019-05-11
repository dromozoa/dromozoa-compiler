-- Copyright (C) 2018,2019 Tomoyuki Fujimori <moyu@dromozoa.com>
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
local variable = require "dromozoa.compiler.variable"

local unpack = table.unpack or unpack

local function opname_to_convert(opname)
  if opname == "arithmetic" then
    return "TONUMBER"
  elseif opname == "bitwise" then
    return "TOINTEGER"
  else
    return "TOSTRING"
  end
end

local function generate(stack, node, symbol_table)
  local proto = node.proto
  if proto then
    local var = node.var
    if var then
      local upvalues = proto.upvalues
      local args = {}
      for i = 1, #upvalues do
        args[i] = upvalues[i][2]
      end
      code_builder(stack, node):CLOSURE(var, proto[1], unpack(args))
    end
    local code_list = {}
    proto.code_list = code_list
    stack = { proto = proto, code_list }
  end

  local symbol = node[0]
  local n = #node
  local inorder = node.inorder
  local binop = node.binop
  local unop = node.unop
  local opname = node.opname
  local _ = code_builder(stack, node)

  if symbol == symbol_table["function"] then
    local that = node[1]
    if that.declare then
      _:MOVE(that.var, variable.NIL)
    end
  elseif symbol == symbol_table["while"] or symbol == symbol_table["repeat"] then
    _:LOOP()
  end

  for i = 1, n do
    generate(stack, node[i], symbol_table)
    if i == inorder then
      if symbol == symbol_table["while"] then
        _:NOT(node.var, node[1].var)
         :COND_IF(node.var)
         :  BREAK()
         :COND_END()
      elseif symbol == symbol_table["for"] then
        if n == 4 then -- numerical for without step
          local vars = node.vars
          _:TONUMBER(vars[1], node[1].var)
           :TONUMBER(vars[2], node[2].var)
           :COND_IF(vars[2])
           :COND_ELSE()
           :  ERROR(vars[5], variable(0))
           :COND_END()
           :COND_IF(vars[1])
           :COND_ELSE()
           :  ERROR(vars[4], variable(0))
           :COND_END()
           :SUB(vars[1], vars[1], variable(1))
           :LOOP()
           :  ADD(vars[1], vars[1], variable(1))
           :  LT(vars[3], vars[2], vars[1])
           :  COND_IF(vars[3])
           :    BREAK()
           :  COND_END()
           :  MOVE(node[3].var, vars[1])
        elseif n == 5 then -- numerical for with step
          local vars = node.vars
          _:TONUMBER(vars[1], node[1].var)
           :TONUMBER(vars[2], node[2].var)
           :TONUMBER(vars[3], node[3].var)
           :COND_IF(vars[3])
           :COND_ELSE()
           :  ERROR(vars[10], variable(0))
           :COND_END()
           :COND_IF(vars[2])
           :COND_ELSE()
           :  ERROR(vars[9], variable(0))
           :COND_END()
           :COND_IF(vars[1])
           :COND_ELSE()
           :  ERROR(vars[8], variable(0))
           :COND_END()
           :SUB(vars[1], vars[1], vars[3])
           :LOOP()
           :  ADD(vars[1], vars[1], vars[3])
           :  LE(vars[4], variable(0), vars[3])
           :  COND_IF(vars[4])
           :    LT(vars[5], vars[2], vars[1])
           :    COND_IF(vars[5])
           :      BREAK()
           :    COND_END()
           :  COND_END()
           :  LT(vars[6], vars[3], variable(0))
           :  COND_IF(vars[6])
           :    LT(vars[7], vars[1], vars[2])
           :    COND_IF(vars[7])
           :      BREAK()
           :    COND_END()
           :  COND_END()
           :  MOVE(node[4].var, vars[1])
        else -- generic for
          local rvars = node[1].vars
          local lvars = node.vars
          local that = node[2]
          local args = {}
          for i = 1, #that do
            args[i] = that[i].var
          end
          _:MOVE(lvars[1], rvars[1])
           :MOVE(lvars[2], rvars[2])
           :MOVE(lvars[3], rvars[3])
           :LOOP()
           :  CALL(lvars[1], lvars[2], lvars[3])
           :  RESULT(unpack(args))
           :  EQ(lvars[4], that[1].var, variable.NIL)
           :  COND_IF(lvars[4])
           :    BREAK()
           :  COND_END()
           :  MOVE(lvars[3], that[1].var)
        end
      elseif symbol == symbol_table.conditional then
        _:COND_ELSE()
      elseif symbol == symbol_table["if"] then
        _:COND_IF(node[1].var)
      elseif binop == "AND" then
        _:MOVE(node.var, node[1].var)
         :COND_IF(node.var)
      elseif binop == "OR" then
        _:NOT(node.var, node[1].var)
         :COND_IF(node.var)
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
    _:LABEL(node[1].var)
  elseif symbol == symbol_table["break"] then
    _:BREAK()
  elseif symbol == symbol_table["goto"] then
    _:GOTO(node[1].var)
  elseif symbol == symbol_table["function"] then
    local that = node[1]
    if that.declare then
      _:MOVE(that.var, node[2].var)
    end
  elseif symbol == symbol_table["while"] then
    _:LOOP_END()
  elseif symbol == symbol_table["repeat"] then
    _:COND_IF(node[2].var)
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
  elseif binop == "AND" or binop == "OR" then
    _:MOVE(node.var, node[2].var)
     :COND_END()
  elseif binop then
    if opname then
      local vars = node.vars
      local convert = opname_to_convert(opname)
      _[convert](_, vars[5], node[1].var)
      _[convert](_, vars[6], node[2].var)
      _:COND_IF(vars[5])
       :  MOVE(vars[1], vars[6])
       :COND_ELSE()
       :  MOVE(vars[1], vars[5])
       :COND_END()
       :COND_IF(vars[1])
      _[binop](_, vars[2], vars[5], vars[6])
      _:COND_ELSE()
       :  GETMETAFIELD(vars[3], node[1].var, vars[9])
       :  COND_IF(vars[3])
       :  COND_ELSE()
       :    GETMETAFIELD(vars[3], node[2].var, vars[9])
       :  COND_END()
       :  COND_IF(vars[3])
       :    CALL(vars[3], node[1].var, node[2].var)
       :    RESULT(vars[2])
       :  COND_ELSE()
       :    COND_IF(vars[5])
       :      TYPENAME(vars[4], node[2].var)
       :    COND_ELSE()
       :      TYPENAME(vars[4], node[1].var)
       :    COND_END()
       :    CONCAT(vars[7], vars[10], vars[4])
       :    CONCAT(vars[8], vars[7], vars[11])
       :    ERROR(vars[8], variable(0))
       :  COND_END()
       :COND_END()
       :MOVE(node.var, vars[2])
    elseif binop == "EQ" or binop == "NE" then
      local vars = node.vars
      _:EQ(vars[1], node[1].var, node[2].var)
       :COND_IF(vars[1])
       :COND_ELSE()
       :  TYPE(vars[3], node[1].var)
       :  EQ(vars[4], vars[3], variable.LUA_TTABLE)
       :  COND_IF(vars[4])
       :    TYPE(vars[5], node[2].var)
       :    EQ(vars[6], vars[5], variable.LUA_TTABLE)
       :    COND_IF(vars[6])
       :      GETMETAFIELD(vars[2], node[1].var, vars[8])
       :      COND_IF(vars[2])
       :      COND_ELSE()
       :        GETMETAFIELD(vars[2], node[2].var, vars[8])
       :      COND_END()
       :      COND_IF(vars[2])
       :        CALL(vars[2], node[1].var, node[2].var)
       :        RESULT(vars[7])
       :        COND_IF(vars[7])
       :          MOVE(vars[1], variable.TRUE)
       :        COND_END()
       :      COND_END()
       :    COND_END()
       :  COND_END()
       :COND_END()
      if binop == "EQ" then
        _:MOVE(node.var, vars[1])
      else
        _:NOT(node.var, vars[1])
      end
    elseif binop == "LT" or binop == "GT" then
      local vars = node.vars
      local var1
      local var2
      if binop == "LT" then
        var1 = node[1].var
        var2 = node[2].var
      else
        var1 = node[2].var
        var2 = node[1].var
      end
      _:TYPE(vars[4], var1)
       :EQ(vars[1], vars[4], variable.LUA_TNUMBER)
       :COND_IF(vars[1])
       :COND_ELSE()
       :  EQ(vars[1], vars[4], variable.LUA_TSTRING)
       :COND_END()
       :COND_IF(vars[1])
       :  TYPE(vars[5], var2)
       :  EQ(vars[1], vars[4], vars[5])
       :COND_END()
       :COND_IF(vars[1])
       :  LT(vars[2], var1, var2)
       :COND_ELSE()
       :  GETMETAFIELD(vars[3], var1, vars[12])
       :  COND_IF(vars[3])
       :  COND_ELSE()
       :    GETMETAFIELD(vars[3], var2, vars[12])
       :  COND_END()
       :  COND_IF(vars[3])
       :    CALL(vars[3], var1, var2)
       :    RESULT(vars[6])
       :    COND_IF(vars[6])
       :      MOVE(vars[2], variable.TRUE)
       :    COND_ELSE()
       :      MOVE(vars[2], variable.FALSE)
       :    COND_END()
       :  COND_ELSE()
       :    TYPENAME(vars[7], var1)
       :    TYPENAME(vars[8], var2)
       :    CONCAT(vars[9], vars[13], vars[7])
       :    CONCAT(vars[10], vars[9], vars[14])
       :    CONCAT(vars[11], vars[10], vars[8])
       :    ERROR(vars[11], variable(0))
       :  COND_END()
       :COND_END()
       :MOVE(node.var, vars[2])
    elseif binop == "LE" or binop == "GE" then
      local vars = node.vars
      local var1
      local var2
      if binop == "LE" then
        var1 = node[1].var
        var2 = node[2].var
      else
        var1 = node[2].var
        var2 = node[1].var
      end
      _:TYPE(vars[5], var1)
       :EQ(vars[1], vars[5], variable.LUA_TNUMBER)
       :COND_IF(vars[1])
       :COND_ELSE()
       :  EQ(vars[1], vars[5], variable.LUA_TSTRING)
       :COND_END()
       :COND_IF(vars[1])
       :  TYPE(vars[6], var2)
       :  EQ(vars[1], vars[5], vars[6])
       :COND_END()
       :COND_IF(vars[1])
       :  LE(vars[2], var1, var2)
       :COND_ELSE()
       :  GETMETAFIELD(vars[3], var1, vars[14])
       :  COND_IF(vars[3])
       :  COND_ELSE()
       :    GETMETAFIELD(vars[3], var2, vars[14])
       :  COND_END()
       :  COND_IF(vars[3])
       :    CALL(vars[3], var1, var2)
       :    RESULT(vars[7])
       :    COND_IF(vars[7])
       :      MOVE(vars[2], variable.TRUE)
       :    COND_ELSE()
       :      MOVE(vars[2], variable.FALSE)
       :    COND_END()
       :  COND_ELSE()
       :    GETMETAFIELD(vars[4], var2, vars[15])
       :    COND_IF(vars[4])
       :    COND_ELSE()
       :      GETMETAFIELD(vars[4], var1, vars[15])
       :    COND_END()
       :    COND_IF(vars[4])
       :      CALL(vars[4], var2, var1)
       :      RESULT(vars[8])
       :      NOT(vars[2], vars[8])
       :    COND_ELSE()
       :      TYPENAME(vars[9], var1)
       :      TYPENAME(vars[10], var2)
       :      CONCAT(vars[11], vars[16], vars[9])
       :      CONCAT(vars[12], vars[11], vars[17])
       :      CONCAT(vars[13], vars[12], vars[10])
       :      ERROR(vars[13], variable(0))
       :    COND_END()
       :  COND_END()
       :COND_END()
       :MOVE(node.var, vars[2])
    else
      _[binop](_, node.var, node[1].var, node[2].var)
    end
  elseif unop then
    if opname then
      local vars = node.vars
      local convert = opname_to_convert(opname)
      _[convert](_, vars[2], node[1].var)
      _:COND_IF(vars[2])
      _[unop](_, vars[1], vars[2])
      _:COND_ELSE()
       :  GETMETAFIELD(vars[3], node[1].var, vars[7])
       :  COND_IF(vars[3])
       :    CALL(vars[3], node[1].var)
       :    RESULT(vars[1])
       :  COND_ELSE()
       :    TYPENAME(vars[4], node[1].var)
       :    CONCAT(vars[5], vars[8], vars[4])
       :    CONCAT(vars[6], vars[5], vars[9])
       :    ERROR(vars[6], variable(0))
       :  COND_END()
       :COND_END()
       :MOVE(node.var, vars[1])
    elseif unop == "LEN" then
      local vars = node.vars
      _:TYPE(vars[2], node[1].var)
       :EQ(vars[3], vars[2], variable.LUA_TSTRING)
       :COND_IF(vars[3])
       :  LEN(vars[1], node[1].var)
       :COND_ELSE()
       :  GETMETAFIELD(vars[4], node[1].var, vars[9])
       :  COND_IF(vars[4])
       :    CALL(vars[4], node[1].var)
       :    RESULT(vars[1])
       :  COND_ELSE()
       :    EQ(vars[5], vars[2], variable.LUA_TTABLE)
       :    COND_IF(vars[5])
       :      LEN(vars[1], node[1].var)
       :    COND_ELSE()
       :      TYPENAME(vars[6], node[1].var)
       :      CONCAT(vars[7], vars[10], vars[6])
       :      CONCAT(vars[8], vars[7], vars[11])
       :      ERROR(vars[8], variable(0))
       :    COND_END()
       :  COND_END()
       :COND_END()
       :MOVE(node.var, vars[1])
    else
      _[unop](_, node.var, node[1].var)
    end
  elseif symbol == symbol_table.functioncall then
    local that = node[2]
    local args = {}
    for i = 1, #that do
      args[i] = that[i].var
    end
    local self = node.self
    if self then
      _:CALL(node[1].var, self, unpack(args))
    else
      _:CALL(node[1].var, unpack(args))
    end
    local var = node.var
    if var then
      _:RESULT(var)
    else
      local vars = assert(node.vars)
      _:RESULT(unpack(vars))
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
        _:SETTABLE(node.var, variable(index), that[1].var)
      end
    end
  end
end

return function (self)
  generate(nil, self.accepted_node, self.symbol_table)
  return self
end

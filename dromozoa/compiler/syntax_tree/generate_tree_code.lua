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
local variable = require "dromozoa.compiler.variable"

local unpack = table.unpack or unpack

local function generate(stack, node, symbol_table)
  local proto = node.proto
  if proto then
    code_builder(stack, node):CLOSURE(node.var or variable.NIL, proto[1])
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
    generate(stack, node[i], symbol_table)
    if i == inorder then
      if symbol == symbol_table["while"] then
        _:COND_IF(node[1].var, variable.FALSE)
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
           :  COND_IF(vars[4], variable.TRUE)
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
           :  LE(vars[5], vars[4], vars[3])
           :  COND_IF(vars[5], variable.TRUE)
           :    LT(vars[6], vars[2], vars[1])
           :    COND_IF(vars[6], variable.TRUE)
           :      BREAK()
           :    COND_END()
           :  COND_END()
           :  LT(vars[7], vars[3], vars[4])
           :  COND_IF(vars[7], variable.TRUE)
           :    LT(vars[8], vars[1], vars[2])
           :    COND_IF(vars[8], variable.TRUE)
           :      BREAK()
           :    COND_END()
           :  COND_END()
           :  MOVE(node[4].var, vars[1])
        else -- generic for
          local rvars = node[1].vars
          local lvars = node.vars
          local var = lvars[5]
          _:MOVE(lvars[1], rvars[1])
           :MOVE(lvars[2], rvars[2])
           :MOVE(lvars[3], rvars[3])
           :LOOP()
           :  CALL(var, lvars[1], lvars[2], lvars[3])
          local that = node[2]
          for i = 1, #that do
            _:MOVE(that[i].var, var[i - 1])
          end
          _:EQ(lvars[4], that[1].var, variable.NIL)
           :COND_IF(lvars[4], variable.TRUE)
           :  BREAK()
           :COND_END()
           :MOVE(lvars[3], that[1].var)
        end
      elseif symbol == symbol_table.conditional then
        _:COND_ELSE()
      elseif symbol == symbol_table["if"] then
        _:COND_IF(node[1].var, variable.TRUE)
      elseif binop == "AND" then
        _:MOVE(node.var, node[1].var)
         :COND_IF(node.var, variable.TRUE)
      elseif binop == "OR" then
        _:MOVE(node.var, node[1].var)
         :COND_IF(node.var, variable.FALSE)
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
    _:COND_IF(node[2].var, variable.TRUE)
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
      _:CALL(node.var or variable.NIL, node[1].var, node.self, unpack(args))
    else
      _:CALL(node.var or variable.NIL, node[1].var, unpack(args))
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
        _:SETLIST(node.var, variable(index), that[1].var)
      end
    end
  end
end

return function (self)
  generate({ { block = true } }, self.accepted_node, self.symbol_table)
  return self
end

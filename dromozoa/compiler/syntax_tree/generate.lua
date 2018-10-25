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

local unpack = table.unpack or unpack

local function generate(stack, node, symbol_table)
  local proto = node.proto
  if proto then
    code_builder(stack, node):CLOSURE(proto[1])
    local block = { [0] = "BLOCK" }
    proto.block = block
    stack = { block }
  end

  local symbol = node[0]
  local n = #node
  local _ = code_builder(stack, node)

  if symbol == symbol_table["while"] then
    _:LOOP()
  elseif symbol == symbol_table["repeat"] then
    _:LOOP()
  end

  local inorder = node.inorder
  for i = 1, n do
    generate(stack, node[i], symbol_table)
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
        _:COND_IF(node[1].var)
      end
    end
  end

  if symbol == symbol_table["local"] then
    local vars = node[1].vars
    local that = node[2]
    for i = 1, #that do
      _:MOVE(that[i].var, vars[i])
    end
  elseif symbol == symbol_table["break"] then
    _:BREAK()
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
    local vars = {}
    for i = 1, #that do
      vars[i] = that[i].var
    end
    _:RETURN(unpack(vars))
  elseif symbol == symbol_table.conditional then
    _:COND_END()
  elseif symbol == symbol_table.funcname or symbol == symbol_table.var then
    local def = node.def
    if def then
      if n == 2 then
        _:SETTABLE(node[1].var, node[2].var, def)
      else
        _:MOVE(node[1].var, def)
      end
    else
      if n == 2 then
        _:GETTABLE(node.var, node[1].var, node[2].var)
      end
    end
  end
end

return function (self)
  generate({ { [0] = "BLOCK" } }, self.accepted_node, self.symbol_table)
  return self
end

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

local variable = require "dromozoa.compiler.variable"

local function _(name)
  return function (self, ...)
    local stack = self.stack
    local block = stack[#stack]
    block[#block + 1] = { node_id = self.node_id, [0] = name, ... }
    return self
  end
end

local class = {
  MOVE     = _"MOVE";
  GETTABLE = _"GETTABLE";
  SETTABLE = _"SETTABLE";
  NEWTABLE = _"NEWTABLE";
  ADD      = _"ADD";
  SUB      = _"SUB";
  MUL      = _"MUL";
  MOD      = _"MOD";
  POW      = _"POW";
  DIV      = _"DIV";
  IDIV     = _"IDIV";
  BAND     = _"BAND";
  BOR      = _"BOR";
  BXOR     = _"BXOR";
  SHL      = _"SHL";
  SHR      = _"SHR";
  UNM      = _"UNM";
  BNOT     = _"BNOT";
  NOT      = _"NOT";
  LEN      = _"LEN";
  CONCAT   = _"CONCAT";
  EQ       = _"EQ";
  NE       = _"NE";
  LT       = _"LT";
  LE       = _"LE";
  CALL     = _"CALL";
  RETURN   = _"RETURN";
  SETLIST  = _"SETLIST";
  CLOSURE  = _"CLOSURE";
  LABEL    = _"LABEL";
  BREAK    = _"BREAK";
  GOTO     = _"GOTO";
  TONUMBER = _"TONUMBER";
}
local metatable = { __index = class }

function class:LOOP()
  local stack = self.stack
  stack[#stack + 1] = { loop_node_id = self.node_id }
  return self
end

function class:LOOP_END()
  local stack = self.stack
  local node_id = self.node_id
  local n = #stack
  local loop_block = stack[n]
  local this_block = stack[n - 1]
  stack[n] = nil

  local proto = stack.proto
  local m = proto.M
  local loop_label = variable.M(m)
  local join_label = variable.M(m + 1)
  proto.M = m + 2

  this_block[#this_block + 1] = { node_id = loop_block.loop_node_id, [0] = "LABEL", loop_label }
  for i = 1, #loop_block do
    local code = loop_block[i]
    if code[0] == "BREAK" then
      this_block[#this_block + 1] = { node_id = code.node_id, [0] = "GOTO", join_label }
    else
      this_block[#this_block + 1] = code
    end
  end
  this_block[#this_block + 1] = { node_id = node_id, [0] = "GOTO", loop_label }
  this_block[#this_block + 1] = { node_id = node_id, [0] = "LABEL", join_label }

  return self
end

function class:COND_IF(...)
  local stack = self.stack
  local n = #stack
  stack[n + 1] = { then_node_id = self.node_id, ... }
  stack[n + 2] = {}
  return self
end

function class:COND_ELSE()
  local stack = self.stack
  local n = #stack
  local cond_block = stack[n - 1]
  cond_block.then_block = stack[n]
  cond_block.else_node_id = self.node_id
  stack[n] = {}
  return self
end

function class:COND_END()
  local stack = self.stack
  local node_id = self.node_id
  local n = #stack
  local m = n - 1
  local that_block = stack[n]
  local cond_block = stack[m]
  local this_block = stack[m - 1]
  stack[n] = nil
  stack[m] = nil

  local then_block = cond_block.then_block
  local then_node_id = cond_block.then_node_id
  if then_block then
    local else_node_id = cond_block.else_node_id
    local proto = stack.proto
    local m = proto.M
    local then_label = variable.M(m)
    local else_label = variable.M(m + 1)
    local join_label = variable.M(m + 2)
    proto.M = m + 3

    this_block[#this_block + 1] = { node_id = then_node_id; [0] = "COND", cond_block[1], cond_block[2], then_label, else_label }
    this_block[#this_block + 1] = { node_id = then_node_id; [0] = "LABEL", then_label }
    for i = 1, #then_block do
      this_block[#this_block + 1] = then_block[i]
    end
    this_block[#this_block + 1] = { node_id = else_node_id; [0] = "GOTO", join_label }
    this_block[#this_block + 1] = { node_id = else_node_id; [0] = "LABEL", else_label }
    for i = 1, #that_block do
      this_block[#this_block + 1] = that_block[i]
    end
    this_block[#this_block + 1] = { node_id = node_id; [0] = "LABEL", join_label }
  else
    local proto = stack.proto
    local m = proto.M
    local then_label = variable.M(m)
    local join_label = variable.M(m + 1)
    proto.M = m + 2

    this_block[#this_block + 1] = { node_id = then_node_id; [0] = "COND", cond_block[1], cond_block[2], then_label, join_label }
    this_block[#this_block + 1] = { node_id = then_node_id; [0] = "LABEL", then_label }
    for i = 1, #that_block do
      this_block[#this_block + 1] = that_block[i]
    end
    this_block[#this_block + 1] = { node_id = node_id; [0] = "LABEL", join_label }
  end

  return self
end

return setmetatable(class, {
  __call = function (_, stack, node)
    return setmetatable({
      stack = stack;
      node_id = node.id;
    }, metatable)
  end;
})

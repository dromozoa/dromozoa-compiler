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

local function _(name)
  return function (self, ...)
    local s = self.stack
    local b = s[#s]
    b[#b + 1] = { name, ... }
    return self
  end
end

local function pop(self, name)
  local s = self.stack
  local n = #s
  local b1 = s[n]
  local b2 = s[n - 1]
  s[n] = nil
  b2[#b2 + 1] = b1
  assert(b1[0] == name)
end

local class = {
  -- binop
  ADD    = _"ADD";
  SUB    = _"SUB";
  MUL    = _"MUL";
  DIV    = _"DIV";
  IDIV   = _"IDIV";
  POW    = _"POW";
  MOD    = _"MOD";
  BAND   = _"BAND";
  BXOR   = _"BXOR";
  BOR    = _"BOR";
  SHR    = _"SHR";
  SHL    = _"SHL";
  CONCAT = _"CONCAT";
  LT     = _"LT";
  LE     = _"LE";
  EQ     = _"EQ";
  NE     = _"NE";

  -- unop
  UNM  = _"UNM";
  NOT  = _"NOT";
  LEN  = _"LEN";
  BNOT = _"BNOT";

  MOVE = _"MOVE";
  GETTABLE = _"GETTABLE";
  SETTABLE = _"SETTABLE";
  CALL = _"CALL";
  CLOSURE = _"CLOSURE";
  BREAK = _"BREAK";
  RETURN = _"RETURN";
  TONUMBER = _"TONUMBER";
}
local metatable = { __index = class }

function class:LOOP()
  local s = self.stack
  s[#s + 1] = { [0] = "LOOP" }
  return self
end

function class:LOOP_END()
  pop(self, "LOOP")
  return self
end

function class:COND_IF(...)
  local s = self.stack
  local n = #s
  s[n + 1] = { [0] = "COND", { "IF", ... } }
  s[n + 2] = { [0] = "BLOCK" }
  return self
end

function class:COND_ELSE()
  pop(self, "BLOCK")
  local s = self.stack
  s[#s + 1] = { [0] = "BLOCK" }
  return self
end

function class:COND_END()
  pop(self, "BLOCK")
  pop(self, "COND")
  return self
end

return setmetatable(class, {
  __call = function (_, stack, node)
    return setmetatable({
      node = node;
      stack = stack;
    }, metatable)
  end;
})

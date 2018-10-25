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
    b[#b + 1] = { [0] = name, ... }
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
  assert(b1.block)
  assert(b1[0] == name)
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
  LT       = _"LT";
  LE       = _"LE";
  CALL     = _"CALL";
  RETURN   = _"RETURN";
  SETLIST  = _"SETLIST";
  CLOSURE  = _"CLOSURE";
  BREAK    = _"BREAK";
  TONUMBER = _"TONUMBER";
}
local metatable = { __index = class }

function class:LOOP()
  local s = self.stack
  s[#s + 1] = { block = true, [0] = "LOOP" }
  return self
end

function class:LOOP_END()
  pop(self, "LOOP")
  return self
end

function class:COND_IF(...)
  local s = self.stack
  local n = #s
  s[n + 1] = { block = true, [0] = "COND", { [0] = "IF", ... } }
  s[n + 2] = { block = true }
  return self
end

function class:COND_ELSE()
  pop(self)
  local s = self.stack
  s[#s + 1] = { block = true }
  return self
end

function class:COND_END()
  pop(self)
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

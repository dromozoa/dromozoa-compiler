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

local function is_unsigned_integer(number)
  return type(number) == "number" and number >= 0 and number % 1 == 0
end

local class = {}
local metatable = { ["dromozoa.dom.is_serializable"] = true }

local order = {
  VOID  =  0;
  NIL   =  1;
  FALSE =  2;
  TRUE  =  3;
  I     =  4;
  P     =  5;
  L     =  6;
  M     =  7;
  K     =  8;
  U     =  9;
  A     = 10;
  B     = 11;
  C     = 12;
  V     = 13;
  T     = 14;
}

class.VOID  = setmetatable({ type = "immediate", key = "VOID"  }, metatable)
class.NIL   = setmetatable({ type = "immediate", key = "NIL"   }, metatable)
class.FALSE = setmetatable({ type = "immediate", key = "FALSE" }, metatable)
class.TRUE  = setmetatable({ type = "immediate", key = "TRUE"  }, metatable)

local function _(type, key)
  class[key] = function (number)
    assert(is_unsigned_integer(number))
    return setmetatable({ type = type, key = key, number = number }, metatable)
  end
end

_("immediate", "I")
_("proto",     "P")
_("label",     "L")
_("label",     "M")
_("constant",  "K")
_("value",     "U")
_("value",     "A")
_("value",     "B")
_("value",     "C")
_("array",     "V")
_("array",     "T")

function class.decode(s)
  if s:find "^%d+$" then
    return class.I(tonumber(s))
  else
    local key, number, index = s:match "^[VT](%d+)%[(%d+)%]"
    if number then
      return class[key](tonumber(number))[tonumber(index)]
    end
    local key, number = s:match "^([PLMKUABCVT])(%d+)$"
    if key then
      return class[key](tonumber(number))
    end
    assert(s == "VOID" or s == "NIL" or s == "FALSE" or s == "TRUE")
    return class[s]
  end
end

function class:encode()
  local key = self.key
  if key == "I" then
    return ("%d"):format(self.number)
  elseif key == "V" or key == "T" then
    local index = self.index
    if index then
      return ("%s%d[%d]"):format(key, self.number, index)
    else
      return ("%s%d"):format(key, self.number)
    end
  else
    local number = self.number
    if number then
      return ("%s%d"):format(key, number)
    else
      return ("%s"):format(key)
    end
  end
end

function class:encode_without_index()
  local key = self.key
  if key == "I" then
    return ("%d"):format(self.number)
  else
    local number = self.number
    if number then
      return ("%s%d"):format(key, number)
    else
      return ("%s"):format(key)
    end
  end
end

function metatable:__tostring()
  return class.encode(self)
end

function metatable:__lt(that)
  local self_order = order[self.key]
  local that_order = order[that.key]
  if self_order == that_order then
    local self_number = self.number or -1
    local that_number = that.number or -1
    if self_number == that.number then
      return (self.index or -1) < (that.index or -1)
    else
      return self_number < that_number
    end
  else
    return self_order < that_order
  end
end

function metatable:__index(index)
  if type(index) == "number" then
    local key = self.key
    assert(is_unsigned_integer(index))
    assert(key == "V" or key == "T")
    assert(not self.index)
    return setmetatable({ type = self.type, key = key, number = self.number, index = index }, metatable)
  else
    return class[index]
  end
end

return setmetatable(class, {
  __call = function (_, number)
    return class.I(number)
  end;
})

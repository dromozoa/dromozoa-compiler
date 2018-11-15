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

local metatable = { ["dromozoa.dom.is_serializable"] = true }

local class = {
  VOID  = setmetatable({ type = "immediate", key = "VOID"  }, metatable);
  NIL   = setmetatable({ type = "immediate", key = "NIL"   }, metatable);
  FALSE = setmetatable({ type = "immediate", key = "FALSE" }, metatable);
  TRUE  = setmetatable({ type = "immediate", key = "TRUE"  }, metatable);
}

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

function class:encode()
  local key = self.key
  if key == "I" then
    return ("%d"):format(self.number)
  elseif key == "A" or key == "B" then
    local index = self.index
    if index then
      return ("%s%d_%d"):format(key, self.number, index)
    end
  elseif key == "V" or key == "T" then
    local index = self.index
    if index then
      return ("%s%d[%d]"):format(key, self.number, index)
    end
  end
  local number = self.number
  if number then
    return ("%s%d"):format(key, number)
  else
    return ("%s"):format(key)
  end
end

function metatable:__tostring()
  return class.encode(self)
end

function metatable:__index(index)
  if type(index) == "number" then
    local key = self.key
    assert(is_unsigned_integer(index))
    assert(key == "A" or key == "B" or key == "V" or key == "T")
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

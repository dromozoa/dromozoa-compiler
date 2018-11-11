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

local map = {
  P     = { "proto",     true  };
  L     = { "label",     true  };
  M     = { "label",     true  };
  NIL   = { "constant",  false };
  FALSE = { "constant",  false };
  TRUE  = { "constant",  false };
  K     = { "constant",  true  };
  U     = { "upvalue",   true  };
  A     = { "value",     true  };
  B     = { "value",     true  };
  C     = { "value",     true  };
  V     = { "array",     false };
  T     = { "array",     true  };
}

local class = {}
local metatable = { ["dromozoa.dom.is_serializable"] = true }

function class:encode()
  local t = self.type
  if t == "immediate" then
    return ("%d"):format(self.value)
  else
    local key = self.key
    if key == "V" then
      local index = self.index
      if index then
        return ("V[%d]"):format(index)
      else
        return "V"
      end
    elseif key == "T" then
      local index = self.index
      if index then
        return ("T%d[%d]"):format(self.number, index)
      else
        return ("T%d"):format(self.number)
      end
    else
      if map[key][2] then
        return ("%s%d"):format(self.key, self.number)
      else
        return ("%s"):format(self.key)
      end
    end
  end
end

function metatable:__tostring()
  return class.encode(self)
end

function metatable:__index(index)
  if type(index) == "number" then
    assert(self.type == "array")
    assert(not self.index)
    return setmetatable({ key = self.key, number = self.number, index = index }, metatable)
  elseif index == "type" then
    local def = map[self.key]
    if def then
      return def[1]
    else
      assert(self.value)
      return "immediate"
    end
  else
    return class[index]
  end
end

for key, def in pairs(map) do
  if def[2] then
    class[key] = function (number)
      return setmetatable({ key = key, number = number }, metatable)
    end
  else
    class[key] = setmetatable({ key = key }, metatable)
  end
end

return setmetatable(class, {
  __call = function (_, value)
    assert(type(value) == "number")
    assert(value % 1 == 0)
    return setmetatable({ value = value }, metatable)
  end;
})

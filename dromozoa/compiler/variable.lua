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

local function is_unsigned_integer(value)
  return type(value) == "number" and value >= 0 and value % 1 == 0
end

local class = {}
local metatable = { ["dromozoa.dom.is_serializable"] = true }

function class.decode(s)
  if s:find "^%d+$" then
    return class(tonumber(s))
  else
    local index = s:match "^V%[(%d+)%]$"
    if index then
      return class.V[tonumber(index)]
    end
    local number, index = s:match "^T(%d+)%[(%d+)%]"
    if number then
      return class.T(tonumber(number))[tonumber(index)]
    end
    local key, number = s:match "^([PLMKUABCT])(%d+)$"
    if key then
      return class[key](tonumber(number))
    end
    assert(s == "VOID" or s == "NIL" or s == "FALSE" or s == "TRUE")
    return class[s]
  end
end

function class:encode()
  if self.type == "immediate" then
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
      local number = self.number
      if number then
        return ("%s%d"):format(key, number)
      else
        return ("%s"):format(key)
      end
    end
  end
end

function class:encode_without_index()
  if self.type == "immediate" then
    return ("%d"):format(self.value)
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

function metatable:__index(index)
  if type(index) == "number" then
    assert(is_unsigned_integer(index))
    assert(self.type == "array")
    assert(not self.index)
    return setmetatable({ type = self.type, key = self.key, number = self.number, index = index }, metatable)
  else
    return class[index]
  end
end

local function _(type, key, number)
  if number then
    class[key] = function (number)
      assert(is_unsigned_integer(number))
      return setmetatable({ type = type, key = key, number = number }, metatable)
    end
  else
    class[key] = setmetatable({ type = type, key = key }, metatable)
  end
end

_("proto",    "P",     true)
_("label",    "L",     true)
_("label",    "M",     true)
_("constant", "VOID",  false)
_("constant", "NIL",   false)
_("constant", "FALSE", false)
_("constant", "TRUE",  false)
_("constant", "K",     true)
_("upvalue",  "U",     true)
_("value",    "A",     true)
_("value",    "B",     true)
_("value",    "C",     true)
_("array",    "V",     false)
_("array",    "T",     true)

return setmetatable(class, {
  __call = function (_, value)
    assert(is_unsigned_integer(value))
    return setmetatable({ type = "immediate", value = value }, metatable)
  end;
})

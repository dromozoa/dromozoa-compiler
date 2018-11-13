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

function class.I(number)
  assert(is_unsigned_integer(number))
  return setmetatable({ type = "immediate", key = "I", number = number }, metatable)
end

local order = { I = 0 }
local count = 0

local function _(type, key, number)
  if number then
    class[key] = function (number)
      assert(is_unsigned_integer(number))
      return setmetatable({ type = type, key = key, number = number }, metatable)
    end
  else
    class[key] = setmetatable({ type = type, key = key }, metatable)
  end
  count = count + 1
  order[key] = count
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
    assert(s == "VOID" or s == "NIL" or s == "FALSE" or s == "TRUE" or s == "V")
    return class[s]
  end
end

function class:encode()
  local key = self.key
  if key == "I" then
    return ("%d"):format(self.number)
  elseif key == "V" then
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
    assert(is_unsigned_integer(index))
    assert(self.type == "array")
    assert(not self.index)
    return setmetatable({ type = self.type, key = self.key, number = self.number, index = index }, metatable)
  else
    return class[index]
  end
end

return setmetatable(class, {
  __call = function (_, number)
    assert(is_unsigned_integer(number))
    return setmetatable({ type = "immediate", key = "I", number = number }, metatable)
  end;
})

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

local serialize = require "dromozoa.compiler.serializer.serialize"
local template = require "dromozoa.compiler.serializer.template"

local unpack = table.unpack or unpack

local class = {}
local metatable = {
  __index = class;
  ["dromozoa.compiler.is_serializable"] = true;
}

local function construct(self, ...)
  return setmetatable({
    separator = self.separator;
    before = self.before;
    after = self.after;
    ...
  }, metatable)
end

function class:separated(separator)
  self.separator = separator
  return self
end

function class:if_not_empty(before, after)
  self.before = before
  self.after = after
  return self
end

function class:filter(f)
  local that = construct(self)
  for i = 1, #self do
    local item = self[i]
    if item.tuple then
      if f(unpack(item)) then
        that[#that + 1] = item
      end
    else
      if f(item) then
        that[#that + 1] = item
      end
    end
  end
  return that
end

function class:map(f)
  if type(f) == "string" then
    f = template(f)
  end
  local that = construct(self)
  for i = 1, #self do
    local item = self[i]
    if item.tuple then
      item = f(unpack(item))
    else
      item = f(item)
    end
    if item then
      that[#that + 1] = item
    end
  end
  return that
end

function class:unshift(...)
  local that = construct(self, ...)
  for i = 1, #self do
    that[#that + 1] = self[i]
  end
  return that
end

function class:sort(compare)
  local that = construct(self, unpack(self))
  table.sort(that, compare)
  return that
end

function class:encode()
  local that = {}
  for i = 1, #self do
    that[i] = serialize(self[i])
  end
  if that[1] then
    return (self.before or "") .. table.concat(that, self.separator) .. (self.after or "")
  else
    return ""
  end
end

function class:write(out)
  out:write(self:encode())
  return out
end

function metatable:__tostring()
  return self:encode()
end

return setmetatable(class, {
  __call = function (_, that, first)
    if not first then
      first = 1
    end
    local self = {}
    for i = first, #that do
      self[#self + 1] = that[i]
    end
    return setmetatable(self, metatable)
  end;
})

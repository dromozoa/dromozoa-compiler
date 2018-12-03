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

local class = {}
local metatable = { __index = class }

local function construct(self)
  return setmetatable({
    separator = self.separator;
    before = self.before;
  }, metatable)
end

function class:separated(separator)
  self.separator = separator
  return self
end

function class:if_not_empty(before)
  self.before = before
  return self
end

function class:filter(f)
  local that = construct(self)
  for i = 1, #self do
    if f(self[i]) then
      that[#that + 1] = self[i]
    end
  end
  return that
end

function class:map(f)
  local that = construct(self)
  for i = 1, #self do
    that[i] = f(self[i])
  end
  return that
end

function class:encode()
  local that = {}
  for i = 1, #self do
    that[i] = serialize(self[i])
  end
  if that[1] then
    local before = self.before
    if before then
      return before .. table.concat(that, self.separator)
    end
  end
  return table.concat(that, self.separator)
end

function metatable:__tostring()
  return self:encode()
end

return setmetatable(class, {
  __call = function (_, that)
    local self = {}
    for i = 1, #that do
      self[i] = that[i]
    end
    return setmetatable(self, metatable)
  end;
})

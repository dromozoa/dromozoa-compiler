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

local metatable = { ["dromozoa.compiler.is_serializable"] = true }

function metatable:__call(source)
  for i = 1, #source do
    self[i] = source[i]
  end
  return self
end

function metatable:__tostring()
  local buffer = {}
  for i = 1, #self do
    buffer[#buffer + 1] = serialize(self[i])
  end
  return table.concat(buffer, self[0])
end

return setmetatable({}, {
  __call = function (_, separator)
    return setmetatable({ [0] = separator }, metatable)
  end;
})

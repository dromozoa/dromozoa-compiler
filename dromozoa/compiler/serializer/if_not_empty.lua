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
  self[1] = source
  return self
end

function metatable:__tostring()
  local source = self[1]
  if #source == 0 then
    return ""
  end
  return serialize(self[0]) .. serialize(source)
end

return setmetatable({}, {
  __call = function (_, before)
    return setmetatable({ [0] = before }, metatable)
  end;
})

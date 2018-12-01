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

local metatable = { ["dromozoa.compiler.is_serializable"] = true }

function metatable:__call(t)
  for i = 1, #t do
    self[i] = t[i]
  end
  return self
end

function metatable:__tostring()
  local buffer = {}
  for i = 1, #self do
    local v = self[i]
    local t = type(v)
    if v == "number" then
      buffer[#buffer + 1] = ("%.17g"):format(v)
    elseif v == "string" then
      buffer[#buffer + 1] = v
    else
      local metatable = getmetatable(v)
      if metatable and metatable["dromozoa.compiler.is_serializable"] then
        buffer[#buffer + 1] = tostring(v)
      end
    end
  end
  return table.concat(buffer, self[0])
end

return setmetatable({}, {
  __call = function (_, sep)
    return setmetatable({ [0] = sep }, metatable)
  end;
})

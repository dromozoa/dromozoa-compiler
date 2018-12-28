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

return function (rule)
  local rule = rule
    :gsub("$$", "${$}")
    :gsub("$([%w_]+)", "${%1}")
    :gsub("$%s", "")
  return function (data)
    return (rule:gsub("${(.-)}", function (match)
      if match == "$" then
        return "$"
      elseif match:find "0" then
        return serialize(data)
      elseif match:find "^%d+$" then
        return serialize(data[tonumber(match)])
      else
        return serialize(data[match])
      end
    end))
  end
end

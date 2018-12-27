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

local sequence = require "dromozoa.compiler.serializer.sequence";
local serialize = require "dromozoa.compiler.serializer.serialize"

local function tuple(...)
  return { tuple = true, ... }
end

local class = {
  sequence = sequence;
  tuple = tuple;
}

function class.entries(that)
  local self = sequence {}
  for k, v in pairs(that) do
    self[#self + 1] = tuple(k, v)
  end
  return self
end

function class.range(a, b, c)
  local self = sequence {}
  for i = a, b, c do
    self[#self + 1] = i
  end
  return self
end

function class.template(rule)
  local rule = rule:gsub("%%([%%%d%s])", "%%{%1}")
  return function (...)
    local args = { ... }
    return (rule:gsub("%%{(.-)}", function (match)
      if match == "%" then
        return "%"
      elseif match:find "^%d+$" then
        return serialize(args[tonumber(match)])
      elseif match:find "^%s+$" then
        return ""
      end
    end))
  end
end

return class

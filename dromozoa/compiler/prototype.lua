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

local dump = require "dromozoa.compiler.prototype.dump"
local dump_code = require "dromozoa.compiler.prototype.dump_code"
local generate = require "dromozoa.compiler.prototype.generate"

local class = {}
local metatable = { __index = class }

function class:generate()
  return generate(self)
end

function class:dump_code(out)
  local buffer = dump_code({}, self, "")
  if type(out) == "string" then
    local out = assert(io.open(out, "w"))
    for i = 1, #buffer do
      out:write(buffer[i])
    end
    return out:close()
  else
    for i = 1, #buffer do
      out:write(buffer[i])
    end
    return out
  end
end

function class:dump(out)
  if type(out) == "string" then
    return dump(self, assert(io.open(out, "w"))):close()
  else
    return dump(self, out)
  end
end

return setmetatable(class, {
  __call = function (_, self)
    return setmetatable(self, metatable)
  end;
})

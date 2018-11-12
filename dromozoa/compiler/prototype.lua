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

local dump_code = require "dromozoa.compiler.prototype.dump_code"
local dump_basic_blocks = require "dromozoa.compiler.prototype.dump_basic_blocks"
local generate_basic_blocks = require "dromozoa.compiler.prototype.generate_basic_blocks"

local class = {}
local metatable = { __index = class }

function class:generate_basic_blocks()
  return generate_basic_blocks(self)
end

function class:dump_code(out)
  if type(out) == "string" then
    return dump_code(self, assert(io.open(out, "w"))):close()
  else
    return dump_code(self, out)
  end
end

function class:dump_basic_blocks(out)
  if type(out) == "string" then
    return dump_basic_blocks(self, assert(io.open(out, "w"))):close()
  else
    return dump_basic_blocks(self, out)
  end
end

return setmetatable(class, {
  __call = function (_, self)
    return setmetatable(self, metatable)
  end;
})

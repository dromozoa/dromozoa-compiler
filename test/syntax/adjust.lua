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

local function f()
  return 1, 2, 3, 4, 5
end

local a                = f(), f(), f(), f()
local a, b             = f(), f(), f(), f()
local a, b, c          = f(), f(), f(), f()
local a, b, c, d       = f(), f(), f(), f()
local a, b, c, d, e    = f(), f(), f(), f()
local a, b, c, d, e, f = f(), f(), f(), f()

local function g(...)
  local a                = ..., ..., ..., ...
  local a, b             = ..., ..., ..., ...
  local a, b, c          = ..., ..., ..., ...
  local a, b, c, d       = ..., ..., ..., ...
  local a, b, c, d, e    = ..., ..., ..., ...
  local a, b, c, d, e, f = ..., ..., ..., ...
end

g(1, 2, 3, 4, 5)

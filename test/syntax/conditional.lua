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

local c1 = nil
local c2 = false
local c3 = true

if c1 then
  v = 1
end

if c1 then
  v = 1
else
  v = 0
end

if c1 then
  v = 1
elseif c2 then
  v = 2
end

if c1 then
  v = 1
elseif c2 then
  v = 2
else
  v = 0
end

if c1 then
  v = 1
elseif c2 then
  v = 2
elseif c3 then
  v = 3
end

if c1 then
  v = 1
elseif c2 then
  v = 2
elseif c3 then
  v = 3
else
  v = 0
end

if c1 then
  v = 1
  if c2 then
    v = 2
    if c3 then
      v = 3
    else
      v = 0
    end
  else
    v = 0
  end
else
  v = 0
end

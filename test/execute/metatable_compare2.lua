-- Copyright (C) 2019 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local t1 = setmetatable({}, {
  __lt = function ()
    print "t1"
    return true
  end;
})

local t2 = setmetatable({}, {
  __lt = function ()
    print "t2"
    return false
  end;
})

local lt = t1 < t2
local le = t1 <= t2
print(lt, le)

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

local metatable = {
  name = "metatable";

  __call = function (self, ...)
    print(self, ...)
    -- return ...
  end;

  __tostring = function (self)
    return "self is " .. type(self)
  end;

  __len = function ()
    print "__len"
    return 42
  end;
}

local t = setmetatable({}, metatable)
t(1, 2, 3, 4)
print(#t)
print(getmetatable(t).name)

local metatable2 = {
  name = "metatable2";

  __metatable = metatable;

  __len = function ()
    print "__len2"
    return 666
  end;
}

local t2 = setmetatable({}, metatable2)
print(#t2)
print(getmetatable(t2).name)

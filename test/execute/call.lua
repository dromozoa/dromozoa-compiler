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

local t = {
  f = function (self, ...)
    print(type(self), ...)
  end;
}
t.t = t

t.f(1, 2, 3, 4)
t.t.f(1, 2, 3, 4)
t.t.t.f(1, 2, 3, 4)
t:f(1, 2, 3, 4)
t.t:f(1, 2, 3, 4)
t.t.t:f(1, 2, 3, 4)
t.t.t.t:f(1, 2, 3, 4)

local f1 = function (...)
  return 1, ...
end

local f2 = function (...)
  return 2, ...
end

local f3 = function (...)
  return 3, ...
end

print(f1(f2(f3(4, 5, 6))))

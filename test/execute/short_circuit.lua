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

local function t()
  print "t"
  return true
end

local function f()
  print "f"
  return false
end

local function n()
  print "n"
  return nil
end

local function z()
  print "z"
  return 0
end

local function o()
  print "o"
  return 1
end

print(t() and t())
print(t() and f())
print(f() and t())
print(f() and f())

print(t() or t())
print(t() or f())
print(f() or t())
print(f() or f())

print(t() and t() or t())
print(t() and t() or f())
print(t() and f() or t())
print(t() and f() or f())
print(f() and t() or t())
print(f() and t() or f())
print(f() and f() or t())
print(f() and f() or f())

print(t() and z() and o() and f())
print(f() or n() or t())

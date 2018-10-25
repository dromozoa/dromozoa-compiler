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

local function f(a, b, c)
  local print = print

  if a then
    print "1"
  end

  if a then
    print "2"
  else
    print "3"
  end

  if a then
    print "4"
  elseif b then
    print "5"
  end

  if a then
    print "6"
  elseif b then
    print "7"
  else
    print "8"
  end

  if a then
    print "9"
  elseif b then
    print "10"
  elseif c then
    print "11"
  end

  if a then
    print "12"
  elseif b then
    print "13"
  elseif c then
    print "14"
  else
    print "15"
  end
end

f(true, false, false)
f(false, true, false)
f(false, false, true)

local function f(a, b, c)
  local print = print

  if a then
    print "1"
  end

  if a then
    print "2"
  else
    print "3"
  end

  if a then
    print "4"
  else
    if b then
      print "5"
    end
  end

  if a then
    print "6"
  else
    if b then
      print "7"
    else
      print "8"
    end
  end

  if a then
    print "9"
  else
    if b then
      print "10"
    else
      if c then
        print "11"
      end
    end
  end

  if a then
    print "12"
  else
    if b then
      print "13"
    else
      if c then
        print "14"
      else
        print "15"
      end
    end
  end
end

f(true, false, false)
f(false, true, false)
f(false, false, true)

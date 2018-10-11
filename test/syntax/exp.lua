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

function f(...)
  local v = {
    nil;
    false;
    true;
    ...;
  }

  local v = {
    3;
    345;
    0xff;
    0xBEBADA;
  }

  local v = {
    3.0;
    3.1416;
    314.16e-2;
    0.31416E1;
    34e1;
    0x0.1E;
    0xA23p-4;
    0X1.921FB54442D18P+1;
  }

  local v = {
    "";
    '';
    [[]];
    "test\n";
    "\x41\x42\x43";
    "abc\z
     def";
    "\xE3\x81\x82\227\129\132\u{3046}";
  }
end

#! /bin/sh -e

# Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
#
# This file is part of dromozoa-compiler.
#
# dromozoa-compiler is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# dromozoa-compiler is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with dromozoa-compiler.  If not, see <http://www.gnu.org/licenses/>.

LUA_PATH="?.lua;;"
export LUA_PATH

mkdir -p result/syntax
cp docs/dromozoa-compiler.* result/syntax

echo "<!DOCTYPE html><title>dromozoa-compiler</title><ul>" >result/syntax/index.html
for i in test/syntax/*.lua
do
  j=`expr "X$i" : 'X.*/\([^/]*\)\.lua'`
  case X$# in
    X0)
      lua "$i"
      lua test/write_html.lua "$i" "result/syntax/$j.html";;
    *)
      "$@" "$i"
      "$@" test/write_html.lua "$i" "result/syntax/$j.html";;
  esac
  printf '<li><a href="%s.html">%s</a></li>\n' "$j" "$j" >>result/syntax/index.html
done
echo "</ul>" >>result/syntax/index.html

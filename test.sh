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

mkdir -p result/compile result/execute
cp docs/dromozoa-compiler.* result/compile
cp docs/dromozoa-compiler.* result/execute

echo "<!DOCTYPE html><title>dromozoa-compiler</title>" >result/index.html

echo "<h1>compile</h1><ul>" >>result/index.html
for i in test/compile/*.lua
do
  echo "compiling $i..."
  j=`expr "X$i" : 'X.*/\([^/]*\)\.lua'`
  n=compile/$j
  lua test/compile.lua "$i" "result/$n"
  cat <<EOH >>result/index.html
<li>$j:
  <a href="$n.js">es</a>
  <a href="$n.html">tree</a>
  <a href="$n.txt">protos</a>
</li>
EOH
done
echo "</ul>" >>result/index.html

echo "<h1>execute</h1><ul>" >>result/index.html
for i in test/execute/*.lua
do
  echo "compiling $i..."
  j=`expr "X$i" : 'X.*/\([^/]*\)\.lua'`
  n=execute/$j
  lua test/compile.lua "$i" "result/$n"

  printf 'executing %s... ' "$i"
  lua "$i" >"result/$n-lua.txt"
  node "result/$n.js" >"result/$n-es.txt"
  if diff "result/$n-lua.txt" "result/$n-es.txt" >/dev/null 2>&1
  then
    if test -t 2
    then
      printf '\33[96m[OK]\33[0m\n'
    else
      echo "[OK]"
    fi
    result=OK
  else
    if test -t 2
    then
      printf '\33[91m[NG]\33[0m\n'
    else
      echo "[NG]"
    fi
    result=NG
  fi
  cat <<EOH >>result/index.html
<li>[$result] $j:
  <a href="$n.js">es</a>
  <a href="$n.html">tree</a>
  <a href="$n.txt">protos</a>
  <a href="$n-lua.txt">lua</a>
  <a href="$n-es.txt">es</a>
</li>
EOH
done
echo "</ul>" >>result/index.html

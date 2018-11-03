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

for i in result/*.cpp
do
  result=OK

  echo "compiling $i..."
  j=`expr "X$i" : 'X.*/\([^/]*\)\.lua'`
  n=execute/$j
  lua test/compile.lua "$i" "result/$n"

  echo "executing $i..."
  lua "$i" >"result/$n-expected.txt"

  printf 'executing %s (es)... ' "$i"
  node "result/$n.js" >"result/$n-es.txt" 2>&1
  if diff "result/$n-expected.txt" "result/$n-es.txt" >/dev/null 2>&1
  then
    ok
  else
    ng
    result=NG
  fi

  if test "X$NO_CXX_TEST" = "X"
  then
    printf 'compiling %s (cxx)... ' "$i"
    if clang++ -std=c++11 -Wall -W "result/$n.cpp" -g -O3 -o "result/$n.exe" >"result/$n-compile.txt" 2>&1
    then
      ok
    else
      ng
      result=NG
    fi

    printf 'executing %s (cxx)... ' "$i"
    "result/$n.exe" >"result/$n-cxx.txt" 2>&1
    if diff "result/$n-expected.txt" "result/$n-cxx.txt" >/dev/null 2>&1
    then
      ok
    else
      ng
      result=NG
    fi
  fi

  cat <<EOH >>result/index.html
<li>[$result] $j:
  <a href="$n.js">es</a>,
  <a href="$n.cpp">cxx</a>,
  <a href="$n.html">tree</a>,
  <a href="$n.txt">protos</a>,
  result:
  <a href="$n-expected.txt">lua</a>,
  <a href="$n-es.txt">es</a>,
  <a href="$n-cxx.txt">cxx</a>
</li>
EOH
done
echo "</ul>" >>result/index.html

echo "</div></body></html>" >>result/index.html

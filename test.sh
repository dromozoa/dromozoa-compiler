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

mkdir -p result/execute
cp docs/dromozoa-compiler.* result/execute

cat <<EOH >result/index.html
<!DOCTYPE html>
<head>
<title>dromozoa-compiler test</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/2.10.0/github-markdown.min.css">
<style>
.markdown-body {
  box-sizing: border-box;
  min-width: 200px;
  max-width: 980px;
  margin: 0 auto;
  padding: 45px;
}
@media (max-width: 767px) {
  .markdown-body {
    padding: 15px;
  }
}
</style>
</head>
<body>
<div class="markdown-body">
<h1>dromozoa-compiler test</h1>
EOH

echo "<h2>execute</h2><ul>" >>result/index.html
for i in test/execute/*.lua
do
  echo "compiling $i..."
  j=`expr "X$i" : 'X.*/\([^/]*\)\.lua'`
  n=execute/$j
  lua test/compile.lua "$i" "result/$n"

  printf 'executing %s... ' "$i"
  lua "$i" >"result/$n-expected.txt"
  node "result/$n.js" >"result/$n-es.txt"
  if diff "result/$n-expected.txt" "result/$n-es.txt" >/dev/null 2>&1
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
  <a href="$n.js">es</a>,
  <a href="$n.html">tree</a>,
  <a href="$n.txt">protos</a>,
  result:
  <a href="$n-expected.txt">lua</a>,
  <a href="$n-es.txt">es</a>
</li>
EOH
done
echo "</ul>" >>result/index.html

echo "</div></body></html>" >>result/index.html


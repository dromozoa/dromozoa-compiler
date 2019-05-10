#! /usr/bin/env lua

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

local buffer = {}

local out = io.stdout

local state
for line in io.lines() do
  if state then
    if line == "</pre>" then
      state = nil
    else
      buffer[#buffer + 1] = line
    end
  else
    if line == [[<pre class="code">]] then
      state = 1
    end
  end
end

local kmap = {}
local vmap = {}
for i = 1, #buffer do
  local line = buffer[i]
  local k, v = line:match [[^(k%d+) = (".*")$]]
  if k then
    assert(not kmap[k])
    kmap[k] = v
  elseif line:find "^%s*[A-Z]" then
    for token in line:gmatch "%S+" do
      if token:find "^[bck]%d+$" then
        vmap[token] = true
      end
    end
  end
end

local vars = {}
for var in pairs(vmap) do
  vars[#vars + 1] = var
end
table.sort(vars)

local tmap = {}
for i = 1, #vars do
  local var = vars[i]
  local t = ("v%d"):format(i)
  tmap[var] = t
end

out:write "<pre>\n"
for i = 1, #vars do
  local var = vars[i]
  local t = assert(var:match "^([bck])"):upper()

  out:write(("%s v%d %s"):format(t, i, var))
  if t == "K" then
    out:write(" ", assert(kmap[var]))
  end
  out:write "\n"
end
out:write "</pre>\n\n<pre>\n"

local state
for i = 1, #buffer do
  local line = buffer[i]
  out:write((line:gsub("(%s)([bck]%d+)", function (u, v)
    local t = tmap[v]
    if t then
      return " " .. t
    end
  end)), "\n")
end
out:write "</pre>\n"

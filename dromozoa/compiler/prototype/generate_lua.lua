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

local serializer = require "dromozoa.compiler.serializer"

local char_table = {
  ["\""] = [[\"]]; -- 34
  ["\\"] = [[\\]]; -- 92
  ["\a"] = [[\a]];
  ["\b"] = [[\b]];
  ["\f"] = [[\f]];
  ["\n"] = [[\n]];
  ["\r"] = [[\r]];
  ["\t"] = [[\t]];
  ["\v"] = [[\v]];
}

for byte = 0x00, 0x7F do
  local char = string.char(byte)
  if not char_table[char] then
    char_table[char] = ([[\03d]]):format(byte)
  end
end

local function encode_string(s)
  local s = s:gsub("[%z\1-\31\34\92\127]", char_table)
  return "\"" .. s .. "\""
end

local function encode_number(source)
  return ("%.17g"):format(assert(tonumber(source)))
end

local function generate_proto(out, self)
  out:write(serializer.template [[
local ${1}_t = {
  K = {
$2$
  };
}
]] {
    self[1],
    serializer.sequence(self.constants)
      :map(function (item)
        if item.type == "string" then
          return { item[1], encode_string(item.source) }
        else
          return { item[1], encode_number(item.source) }
        end
      end)
      :map(serializer.template "    $1 = $2;\n")
  })
end

local function generate_closure(out, self)
end

return function (self, out)
  generate_proto(out, self)
  generate_closure(out, self)
  return out
end

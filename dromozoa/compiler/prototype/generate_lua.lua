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

local _ = serializer.template

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

local function encode_assign_var(var)
  if var.declare then
    if var.reference then
      return ("local %s = {}; %s[1]"):format(var, var)
    else
      return ("local %s"):format(var)
    end
  else
    if var.reference then
      return ("%s[1]"):format(var)
    else
      return ("%s"):format(var)
    end
  end
end

local function encode_var(var)
  -- assert(not var.declare)
  if var.reference then
    return ("%s[1]"):format(var)
  elseif var.key == "K" then
    return ("self.%s"):format(var)
  else
    return ("%s"):format(var)
  end
end

local templates = {
  MOVE         = _"$1 = $2";
  GETTABLE     = _"$1 = $2[$3]";
  NEWTABLE     = _"$1 = {}";
  ADD          = _"$1 = $2 + $3";
  CONCAT       = _"$1 = $2 .. $3";
  EQ           = _"$1 = $2 == $3";
  TYPE         = _"$1 = type($2)";
  TYPENAME     = _"$1 = TYPENAME($2)";
  TONUMBER     = _"$1 = tonumber($2)";
  GETMETAFIELD = _"$1 = GETMETAFIELD($2, $3)";
}

local function generate_proto(out, self)
  out:write(serializer.template [[
local $1 = {
$2$
}
]] {
    self[1];
    serializer.sequence(self.constants)
      :map(function (item)
        if item.type == "string" then
          return { item[1], encode_string(item.source) }
        else
          return { item[1], encode_number(item.source) }
        end
      end)
      :map(serializer.template "  $1 = $2;\n");
  })
end

local function generate_block(out, self, uid)
  local blocks = self.blocks
  local block = assert(blocks[uid])

  out:write(serializer.template [[
function $1:b$2($3)
]] {
    self[1];
    uid;
    serializer.entries(block.params)
      :map(function (_, param)
        return param[0]
      end)
      :sort()
      :unshift("cont", "catch", "coro")
      :separated ", "
  })

  for i = 1, #block do
    local code = block[i]
    local name = code[0]

    if name == "SETTABLE" then
      out:write(serializer.template "  $1[$2] = $3\n" {
        encode_var(code[1]);
        encode_var(code[2]);
        encode_var(code[3]);
      })
    elseif name == "CALL" then
      -- noop
    elseif name == "RESULT" then
    elseif name == "RETURN" then
    elseif name == "COND" then
    elseif name == "ERROR" then
    else
      local tmpl = templates[name]
      local data = { encode_assign_var(code[1]) }
      for j = 2, #code do
        -- print(name, j, code[j])
        data[j] = encode_var(code[j])
      end
      if tmpl then
        out:write("  ", tmpl(data), "\n")
      else
        out:write("--", name, "\n")
      end
    end
  end

  out:write "end\n"
end

local function generate_blocks(out, self)
  local blocks = self.blocks
  local g = blocks.g
  local u = g.u
  local u_after = u.after

  local uid = u.first
  while uid do
    generate_block(out, self, uid)
    uid = u_after[uid]
  end
end

return function (self, out)
  generate_proto(out, self)
  generate_blocks(out, self)
  return out
end

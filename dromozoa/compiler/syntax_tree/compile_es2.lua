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

local runtime_es = require "dromozoa.compiler.runtime.runtime_es"

local char_table = {
  ["\n"] = [[\n]];
  ["\r"] = [[\r]];
  ["\\"] = [[\\]];
  ["\""] = [[\"]];
  [string.char(0xE2, 0x80, 0xA8)] = [[\u2028]]; -- LINE SEPARATOR
  [string.char(0xE2, 0x80, 0xA9)] = [[\u2029]]; -- PARAGRAPH SEPARATOR
}

for byte = 0x00, 0xFF do
  local char = string.char(byte)
  if not char_table[char] then
    char_table[char] = ([[\u04X]]):format(byte)
  end
end

local function encode_string(s)
  return "\"" .. s:gsub("[%z\1-\31\127]", char_table):gsub("\226\128[\168\169]", char_table) .. "\""
end

local function encode_var(var)
  if var == "V" then
    return "...V"
  elseif var == "T" then
    return "...T"
  elseif var == "NIL" then
    return "undefined"
  elseif var == "FALSE" then
    return "false"
  elseif var == "TRUE" then
    return "true"
  else
    local k = var:sub(1, 1)
    if k == "P" then
      return var
    elseif k == "U" then
      local i = var:sub(2)
      return "U[" .. i .. "][0][U[" .. i .. "][1]]"
    else
      return k .. "[" .. var:sub(2) .. "]"
    end
  end
end

local function _(var, not_spread)
  if var == "V" then
    return "...V"
  elseif var == "T" then
    return "...T"
  elseif var == "NIL" then
    return "undefined"
  elseif var == "FALSE" then
    return "false"
  elseif var == "TRUE" then
    return "true"
  else
    local k = var:sub(1, 1)
    if k == "P" then
      return var
    elseif k == "U" then
      local i = var:sub(2)
      return "U[" .. i .. "][0][U[" .. i .. "][1]]"
    else
      return k .. "[" .. var:sub(2) .. "]"
    end
  end
end

local compile_proto

function compile_code(self, out, code)
end

function compile_proto(self, out, proto)
  local A = proto.A
  local B = proto.B
  local C = proto.C

  local pars = {}
  for i = 0, A - 1 do
    pars[#pars + 1] = "A" .. i
  end
  if proto.arg then
    pars[#pars + 1] = "...V"
  end
  out:write(("const %s = (%s) => {\n"):format(_(proto[1]), table.concat(pars, ", ")))

  local constants = proto.constants
  local n = #constants
  if n > 0 then
    out:write "const K = [\n"
    for i = 1, n do
      local constant = constants[i]
      if constant.type == "string" then
        out:write(("/* %s */ %s,\n"):format(constant[1], encode_string(constant.source)))
      else
        out:write(("/* %s */ %.17g,\n"):format(constant[1], tonumber(constant.source)))
      end
    end
    out:write "];\n"
  end

  local upvalues = proto.upvalues
  local n = #upvalues
  for i = 1, n do
    local upvalue = upvalues[i]
    if upvalue[2]:find "^U" then
      out:write "const S = U;\n"
      break
    end
  end

  out:write "{\n"

  if n > 0 then
    out:write "const U = [\n"
    for i = 1, n do
      local upvalue = upvalues[i]
      local var = upvalue[2]
      assert(var:find "^[ABU]%d+$")
      local key = var:sub(1, 1)
      if key == "U" then
        local index = var:sub(2)
        out:write(("/* %s */ [ S[%d][0], S[%d][1] ],\n"):format(upvalue[1], index, index))
      else
        out:write(("/* %s */ [ %s, %d ],\n"):format(upvalue[1], key, var:sub(2)))
      end
    end
    out:write "];\n"
  end

  out:write "{\n"

  if A > 0 then
    out:write "const A = [\n"
    for i = 0, A - 1 do
      out:write("A", i, ",\n")
    end
    out:write "];\n"
  end
  if B > 0 then
    out:write(("const B = []; /* %d */\n"):format(B))
  end
  if C > 0 then
    out:write(("const C = []; /* %d */\n"):format(C))
  end
  if proto.T then
    out:write "let T;\n"
  end

  compile_code(proto.block)

  out:write "}}}\n"
end

return function (self, out, name)
  if name then
    out:write(name, " = ")
  else
    out:write "("
  end

  out:write "env => {\n"
  out:write(runtime_es);
  out:write [[
if (env === undefined) {
  env = open_env();
}
const B = [ env ];
]]

  compile_proto(self, out, self.protos[1])
  out:write "P0();\n"

  if name then
    out:write "};\n"
  else
    out:write "})();\n"
  end

  return out
end

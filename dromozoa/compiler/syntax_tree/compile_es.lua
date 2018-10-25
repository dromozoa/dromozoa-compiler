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

local var_table = {
  V = "...V";
  T = "...T";
  NIL = "undefined";
  FALSE = "false";
  TRUE = "true";
}

local function encode_string(s)
  return "\"" .. s:gsub("[%z\1-\31\127]", char_table):gsub("\226\128[\168\169]", char_table) .. "\""
end

local function encode_var(var)
  local result = var_table[var]
  if result then
    return result
  else
    local key = var:sub(1, 1)
    if key == "P" then
      return var
    elseif key == "U" then
      local index = var:sub(2)
      return "U[" .. index .. "][0][U[" .. index .. "][1]]"
    else
      return key .. "[" .. var:sub(2) .. "]"
    end
  end
end

local function encode_var_not_spread(var)
  if var == "V" or var == "T" then
    return var
  else
    return encode_var(var)
  end
end

local function encode_vars(source, i, j)
  if not i then
    i = 1
  end
  if not j then
    j = #source
  end
  local result = {}
  for i = i, j do
    result[#result + 1] = encode_var(source[i])
  end
  return table.concat(result, ", ")
end

local function _1(template)
  return function (out, code)
    out:write(template:format(encode_var(code[1])), ";\n")
  end
end

local function _12(template)
  return function (out, code)
    out:write(template:format(encode_var(code[1]), encode_var(code[2])), ";\n")
  end
end

local function _122(template)
  return function (out, code)
    local a = encode_var(code[1])
    local b = encode_var(code[2])
    out:write(template:format(a, b, b), ";\n")
  end
end

local function _123(template)
  return function (out, code)
    out:write(template:format(encode_var(code[1]), encode_var(code[2]), encode_var(code[3])), ";\n")
  end
end

local templates = {
  MOVE     = _12  "%s = %s";
  GETTABLE = _123 "%s = GETTABLE(%s, %s)";
  SETTABLE = _123 "SETTABLE(%s, %s, %s)";
  NEWTABLE = _1   "%s = new Map()";
  ADD      = _123 "%s = %s + %s";
  SUB      = _123 "%s = %s - %s";
  MUL      = _123 "%s = %s * %s";
  MOD      = _123 "%s = %s %% %s";
  POW      = _123 "%s = %s ** %s";
  DIV      = _123 "%s = %s / %s";
  IDIV     = _123 "%s = Math.floor(%s / %s)";
  BAND     = _123 "%s = %s & %s";
  BOR      = _123 "%s = %s | %s";
  BXOR     = _123 "%s = %s ^ %s";
  SHL      = _123 "%s = %s << %s";
  SHR      = _123 "%s = %s >>> %s";
  UNM      = _12  "%s = -%s";
  BNOT     = _12  "%s = ~%s";
  NOT      = _122 "%s = %s === undefined || %s === false";
  LEN      = _12  "%s = LEN(%s)";
  CONCAT   = _123 "%s = tostring(%s) + tostring(%s)";
  EQ       = _123 "%s = %s === %s";
  NE       = _123 "%s = %s !== %s";
  LT       = _123 "%s = %s < %s";
  LE       = _123 "%s = %s <= %s";
  TONUMBER = _12  "%s = tonumber(%s)";
}

local compile_proto
local compile_code

local function write_block(self, out, code)
  for i = 1, #code do
    compile_code(self, out, code[i])
  end
end

function compile_code(self, out, code)
  local name = code[0]
  if code.block then
    if name == "LOOP" then
      out:write "while (true) {\n"
      write_block(self, out, code)
      out:write "}\n"
    elseif name == "COND" then
      local cond = code[1]
      local a = encode_var(cond[1])
      if cond[2] == "TRUE" then
        out:write(("if (%s !== undefined && %s !== false) {\n"):format(a, a))
      else
        out:write(("if (%s === undefined || %s === false) {\n"):format(a, a))
      end
      compile_code(self, out, code[2])
      if #code == 2 then
        out:write "}\n"
      else
        out:write "} else {\n"
        compile_code(self, out, code[3])
        out:write "}\n"
      end
    else
      write_block(self, out, code)
    end
  else
    if name == "CALL" then
      local args = encode_vars(code, 2)
      local var = code[1]
      if var == "NIL" then
        out:write(("CALL0(%s);\n"):format(args))
      elseif var == "T" then
        out:write(("T = CALL(%s);\n"):format(args))
      else
        out:write(("%s = CALL1(%s);\n"):format(encode_var(var), args))
      end
    elseif name == "RETURN" then
      local n = #code
      if n == 0 then
        out:write "return;\n"
      elseif n == 1 then
        out:write(("return %s;\n"):format(encode_var_not_spread(code[1])))
      else
        out:write(("return [%s];\n"):format(encode_vars(code)))
      end
    elseif name == "SETLIST" then
      out:write(("SETLIST(%s, %d, %s);\n"):format(encode_var(code[1]), code[2], encode_var(code[3])))
    elseif name == "CLOSURE" then
      compile_proto(self, out, code[1])
    elseif name == "LABEL" then
      out:write(("%s:\n"):format(code[1]))
    elseif name == "BREAK" then
      out:write "break;\n"
    elseif name == "GOTO" then
      out:write(("// GOTO %s\n"):format(code[1]))
    else
      templates[name](out, code)
    end
  end
end

function compile_proto(self, out, name)
  local protos = self.protos
  local proto
  for i = 1, #protos do
    proto = protos[i]
    if proto[1] == name then
      break
    end
    proto = nil
  end

  local A = proto.A
  local B = proto.B
  local C = proto.C

  local pars = {}
  for i = 0, A - 1 do
    pars[#pars + 1] = "A" .. i
  end
  if proto.vararg then
    pars[#pars + 1] = "...V"
  end
  out:write(("const %s = (%s) => {\n"):format(proto[1], table.concat(pars, ", ")))

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
        out:write(("/* %s */ [S[%d][0], S[%d][1]],\n"):format(upvalue[1], index, index))
      else
        out:write(("/* %s */ [%s, %d],\n"):format(upvalue[1], key, var:sub(2)))
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

  compile_code(self, out, proto.code)

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
const B = [env];
]]

  compile_proto(self, out, "P0")
  out:write "P0();\n"

  if name then
    out:write "};\n"
  else
    out:write "})();\n"
  end

  return out
end

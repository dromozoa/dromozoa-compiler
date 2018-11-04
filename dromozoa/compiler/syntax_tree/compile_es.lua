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
local template = require "dromozoa.compiler.syntax_tree.template"

local char_table = {
  ["\n"] = [[\n]];
  ["\r"] = [[\r]];
  ["\\"] = [[\\]];
  ["\""] = [[\"]];
  [string.char(0xE2, 0x80, 0xA8)] = [[\u2028]]; -- LINE SEPARATOR
  [string.char(0xE2, 0x80, 0xA9)] = [[\u2029]]; -- PARAGRAPH SEPARATOR
}

for byte = 0x00, 0x7F do
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
    if key == "P" or key == "L" then
      return var
    elseif key == "U" then
      local index = var:sub(2)
      return "U[" .. index .. "][0][U[" .. index .. "][1]]"
    else
      return key .. "[" .. var:sub(2) .. "]"
    end
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

local tmpl = template(encode_var, {
  MOVE     = "%1 = %2";
  GETTABLE = "%1 = gettable(%2, %3)";
  SETTABLE = "settable(%1, %2, %3)";
  NEWTABLE = "%1 = new Map()";
  ADD      = "%1 = checknumber(%2) + checknumber(%3)";
  SUB      = "%1 = checknumber(%2) - checknumber(%3)";
  MUL      = "%1 = checknumber(%2) * checknumber(%3)";
  MOD      = "%1 = checknumber(%2) % checknumber(%3)";
  POW      = "%1 = checknumber(%2) ** checknumber(%3)";
  DIV      = "%1 = checknumber(%2) / checknumber(%3)";
  IDIV     = "%1 = Math.floor(checknumber(%2) / checknumber(%3))";
  BAND     = "%1 = checkinteger(%2) & checkinteger(%3)";
  BOR      = "%1 = checkinteger(%2) | checkinteger(%3)";
  BXOR     = "%1 = checkinteger(%2) ^ checkinteger(%3)";
  SHL      = "%1 = checkinteger(%2) << checkinteger(%3)";
  SHR      = "%1 = checkinteger(%2) >>> checkinteger(%3)";
  UNM      = "%1 = -checknumber(%2)";
  BNOT     = "%1 = ~checkinteger(%2)";
  NOT      = "%1 = !toboolean(%2)";
  LEN      = "%1 = len(%2)";
  CONCAT   = "%1 = checkstring(%2) + checkstring(%3)";
  EQ       = "%1 = %2 === %3";
  NE       = "%1 = %2 !== %3";
  LT       = "%1 = %2 < %3";
  LE       = "%1 = %2 <= %3";
  BREAK    = "break";
  GOTO     = "L = %1; continue";
  TONUMBER = "%1 = checknumber(%2)";
})

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
      out:write "for (;;) {\n"
      write_block(self, out, code)
      out:write "}\n"
    elseif name == "COND" then
      local cond = code[1]
      local var = encode_var(cond[1])
      if cond[2] == "TRUE" then
        out:write(("if (%s !== undefined && %s !== false) {\n"):format(var, var))
      else
        out:write(("if (%s === undefined || %s === false) {\n"):format(var, var))
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
      local var = code[1]
      if var == "NIL" then
        out:write(("call0(%s);\n"):format(encode_vars(code, 2)))
      elseif var == "T" then
        out:write(("T = call(%s);\n"):format(encode_vars(code, 2)))
      else
        out:write(("%s = call1(%s);\n"):format(encode_var(var), encode_vars(code, 2)))
      end
    elseif name == "RETURN" then
      local n = #code
      if n == 0 then
        out:write "return;\n"
      elseif n == 1 then
        local var = code[1]
        if var == "V" or var == "T" then
          out:write(("return %s;\n"):format(var))
        else
          out:write(("return %s;\n"):format(encode_var(var)))
        end
      else
        out:write(("return [%s];\n"):format(encode_vars(code)))
      end
    elseif name == "SETLIST" then
      out:write(("setlist(%s, %d, %s);\n"):format(encode_var(code[1]), code[2], encode_var(code[3])))
    elseif name == "CLOSURE" then
      compile_proto(self, out, code[1])
    elseif name == "LABEL" then
      out:write(("case %s:\n"):format(encode_var(code[1])))
    else
      out:write(tmpl:eval(name, code), ";\n")
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
  if proto.V then
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
      local key = var:sub(1, 1)
      if key == "U" then
        local index = var:sub(2)
        out:write(("/* %s */ S[%d],\n"):format(upvalue[1], index))
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
    out:write "let T = undefined;\n"
  end

  local emulate_goto = proto["goto"]
  if emulate_goto then
    local labels = proto.labels
    for i = 1, #labels do
      out:write(("const %s = %d;\n"):format(labels[i][1], i))
    end
    out:write "let L = 0;\n"
    out:write "for (;;) {\n"
    out:write "switch (L) {\n"
    out:write "case 0:\n"
  end

  compile_code(self, out, proto.code)

  if emulate_goto then
    out:write "}\n"
    out:write "return;\n"
    out:write "}\n"
  end

  out:write "}}};\n"
end

return function (self, out, name)
  if name then
    out:write(("%s = "):format(name))
  else
    out:write "("
  end
  out:write "() => {\n"
  out:write(runtime_es);
  out:write "const B = [env];\n"
  compile_proto(self, out, "P0")
  out:write "P0();\n"
  if name then
    out:write "};\n"
  else
    out:write "})();\n"
  end
  return out
end

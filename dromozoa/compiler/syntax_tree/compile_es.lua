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

local function _(var, not_spread)
  if var == "V" then
    if not_spread then
      return var
    else
      return "...V"
    end
  elseif var == "T" then
    if not_spread then
      return var
    else
      return "...T"
    end
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
  local name = code[0]
  if code.block then
    if name == "LOOP" then
      out:write "while (true) {\n"
      for i = 1, #code do
        compile_code(self, out, code[i])
      end
      out:write "}\n"
    elseif name == "COND" then
      local cond = code[1]
      if cond[2] == "TRUE" then
        out:write(("if (%s !== undefined && %s !== false) {\n"):format(_(cond[1]), _(cond[1])))
      else
        out:write(("if (%s === undefined || %s === false) {\n"):format(_(cond[1]), _(cond[1])))
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
      for i = 1, #code do
        compile_code(self, out, code[i])
      end
    end
  else
    if name == "MOVE" then
      out:write(("%s = %s;\n"):format(_(code[1]), _(code[2])))
    elseif name == "GETTABLE" then
      out:write(("%s = GETTABLE(%s, %s);\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "SETTABLE" then
      out:write(("SETTABLE(%s, %s, %s);\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "NEWTABLE" then
      out:write(("%s = new Map();\n"):format(_(code[1])))
    elseif name == "ADD" then
      out:write(("%s = %s + %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "SUB" then
      out:write(("%s = %s - %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "MUL" then
      out:write(("%s = %s * %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "MOD" then
      out:write(("%s = %s %% %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "POW" then
      out:write(("%s = %s ** %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "DIV" then
      out:write(("%s = %s / %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "IDIV" then
      out:write(("%s = Math.floor(%s / %s);\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "BAND" then
      out:write(("%s = %s & %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "BOR" then
      out:write(("%s = %s | %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "BXOR" then
      out:write(("%s = %s ^ %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "SHL" then
      out:write(("%s = %s << %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "SHR" then
      out:write(("%s = %s >>> %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "UNM" then
      out:write(("%s = -%s;\n"):format(_(code[1]), _(code[2])))
    elseif name == "BNOT" then
      out:write(("%s = ~%s;\n"):format(_(code[1]), _(code[2])))
    elseif name == "NOT" then
      out:write(("%s = %s === undefined || %s === false;\n"):format(_(code[1]), _(code[2]), _(code[2])))
    elseif name == "LEN" then
      out:write(("%s = LEN(%s);\n"):format(_(code[1]), _(code[2])))
    elseif name == "CONCAT" then
      out:write(("%s = tostring(%s) + tostring(%s);\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "EQ" then
      if code[4] == "TRUE" then
        out:write(("%s = %s === %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
      else
        out:write(("%s = %s !== %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
      end
    elseif name == "LT" then
      out:write(("%s = %s < %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "LE" then
      out:write(("%s = %s <= %s;\n"):format(_(code[1]), _(code[2]), _(code[3])))
    elseif name == "CALL" then
      local args = {}
      for i = 2, #code do
        args[i - 1] = _(code[i])
      end
      local var = code[1]
      if var == "NIL" then
        out:write(("CALL0(%s);\n"):format(table.concat(args, ", ")))
      elseif var == "T" then
        out:write(("T = CALL(%s);\n"):format(table.concat(args, ", ")))
      else
        out:write(("%s = CALL1(%s);\n"):format(_(var), table.concat(args, ", ")))
      end
    elseif name == "RETURN" then
      local n = #code
      if n == 0 then
        out:write "return;\n"
      elseif n == 1 then
        out:write(("return %s;\n"):format(_(code[1], true)))
      else
        local rets = {}
        for i = 1, #code do
          rets[i] = _(code[i])
        end
        out:write(("return [%s];\n"):format(table.concat(rets, ", ")))
      end
    elseif name == "SETLIST" then
      out:write(("SETLIST(%s, %d, %s);\n"):format(_(code[1]), code[2], _(code[3])))
    elseif name == "CLOSURE" then
      compile_proto(self, out, code[1])
    elseif name == "LABEL" then
      -- TODO warn
    elseif name == "BREAK" then
      out:write "break;\n"
    elseif name == "GOTO" then
      -- TODO warn
    elseif name == "TONUMBER" then
      out:write(("%s = tonumber(%s);\n"):format(_(code[1]), _(code[2])))
    else
      -- DEBUG
      error("invalid name " .. name)
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

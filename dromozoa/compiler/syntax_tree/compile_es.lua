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

local symbol_value = require "dromozoa.parser.symbol_value"
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

local function write(self, out, node, symbol_table)
  local proto = node.proto
  if proto then
    local A = proto.A
    local B = proto.B
    local C = proto.C

    out:write(("const %s = function ("):format(proto[1]))
    if A > 0 then
      out:write "A0"
      for i = 1, A - 1 do
        out:write(", A", i)
      end
      if proto.vararg then
        out:write(", ...V")
      end
    elseif proto.vararg then
      out:write "...V"
    end
    out:write ") {\n"

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
          out:write(("/* %s */ [S[%d][0],S[%d][1]],\n"):format(upvalue[1], index, index))
        else
          out:write(("/* %s */ [%s,%d],\n"):format(upvalue[1], key, var:sub(2)))
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
  end

  local symbol = node[0]
  if symbol == symbol_table["while"] then
    out:write "while (true) {\n"
  elseif symbol == symbol_table["repeat"] then
    out:write "while (true) {\n"
  elseif symbol == symbol_table["for"] then
    out:write "{\n"
  end

  local n = #node
  local inorder = node.inorder
  for i = 1, n do
    write(self, out, node[i], symbol_table)
    if i == inorder then
      if symbol == symbol_table["while"] then
        local var = node[1].var
        out:write("if (", encode_var(var), "===undefined||", encode_var(var), "===false) break;\n")
      elseif symbol == symbol_table["for"] then
        if n == 4 then
          local vars = node.vars
          out:write(encode_var(vars[1]), " = ", encode_var(node[1].var), ";\n")
          out:write(encode_var(vars[2]), " = ", encode_var(node[2].var), ";\n")
          out:write("--", encode_var(vars[1]), ";\n")
          out:write "while (true) {\n"
          out:write("++", encode_var(vars[1]), ";\n")
          out:write("if (", encode_var(vars[1]), " > ", encode_var(vars[2]), ") break;\n")
          out:write(encode_var(node[3].var), "=", encode_var(vars[1]), ";\n")
        elseif n == 5 then
          local vars = node.vars
          out:write(encode_var(vars[1]), " = ", encode_var(node[1].var), ";\n")
          out:write(encode_var(vars[2]), " = ", encode_var(node[2].var), ";\n")
          out:write(encode_var(vars[3]), " = ", encode_var(node[3].var), ";\n")
          out:write(encode_var(vars[1]), "-=", encode_var(vars[3]), ";\n")
          out:write "while (true) {\n"
          out:write(encode_var(vars[1]), "+=", encode_var(vars[3]), ";\n")
          out:write("if ((", encode_var(vars[3]), " >= 0 && ", encode_var(vars[1]), " > ", encode_var(vars[2]), ") || (", encode_var(vars[3]), " < 0 && ", encode_var(vars[1]), " < ", encode_var(vars[2]), ")) break;\n")
          out:write(encode_var(node[4].var), "=", encode_var(vars[1]), ";\n")
        else
          local rvars = node[1].vars
          local lvars = node.vars
          out:write(encode_var(lvars[1]), " = ", encode_var(rvars[1]), ";\n")
          out:write(encode_var(lvars[2]), " = ", encode_var(rvars[2]), ";\n")
          out:write(encode_var(lvars[3]), " = ", encode_var(rvars[3]), ";\n")
          out:write "while (true) {\n"
          out:write("T = CALL(", encode_var(lvars[1]), ",", encode_var(lvars[2]), ",", encode_var(lvars[3]), ");\n")
          local that = node[2]
          for i = 1, #that do
            out:write(encode_var(that[i].var), "=T[", i - 1, "];\n")
          end
          local var = that[1].var
          out:write("if (", encode_var(var), "==undefined) break;\n")
          out:write(encode_var(lvars[3]), "=", encode_var(var), "\n")
        end
      elseif symbol == symbol_table.conditional then
        out:write "} else {\n"
      elseif symbol == symbol_table["if"] then
        local var = node[1].var
        out:write("if (!(", encode_var(var), "==undefined||", encode_var(var), "===false)) {\n")
      elseif symbol == symbol_table["and"] then
        local var = node.var
        out:write(encode_var(node.var), "=", encode_var(node[1].var), ";\n")
        out:write("if (!(", encode_var(var), "==undefined||", encode_var(var), "===false)) {\n")
      elseif symbol == symbol_table["or"] then
        local var = node.var
        out:write(encode_var(node.var), "=", encode_var(node[1].var), ";\n")
        out:write("if (", encode_var(var), "==undefined||", encode_var(var), "===false) {\n")
      end
    end
  end

  if symbol == symbol_table["local"] then
    local vars = node[1].vars
    local that = node[2]
    for i = 1, #that do
      out:write(encode_var(that[i].var), "=", encode_var(vars[i]), ";\n")
    end
  elseif symbol == symbol_table["break"] then
    out:write "break;\n"
  elseif symbol == symbol_table["function"] then
    local that = node[1]
    if that.declare then
      out:write(encode_var(that.var), "=", encode_var(node[2].var), ";\n")
    end
  elseif symbol == symbol_table["while"] then
    out:write "/* while */ }\n"
  elseif symbol == symbol_table["repeat"] then
    local var = node[2].var
    out:write("if (!(", encode_var(var), "===undefined||", encode_var(var), "===false)) break;\n")
    out:write "/* while */ }\n"
  elseif symbol == symbol_table["for"] then
    out:write "/* while */ }\n"
    out:write "}\n"
  elseif symbol == symbol_table["return"] then
    local that = node[1]
    local n = #that
    if n == 0 then
      out:write "return;\n"
    elseif n == 1 then
      local var = that[1].var
      if var == "V" or var == "T" then
        out:write("return ", var, ";\n")
      else
        out:write("return ", encode_var(that[1].var), ";\n")
      end
    else
      out:write "return ["
      for i = 1, n do
        if i > 1 then
          out:write ","
        end
        out:write(encode_var(that[i].var))
      end
      out:write "];\n"
    end
  elseif symbol == symbol_table.conditional then
    out:write "/* if */ }\n"
  elseif symbol == symbol_table.funcname then
    if node.def then
      if #node == 2 then
        out:write("SETTABLE(", encode_var(node[1].var), ",", encode_var(node[2].var), ",", encode_var(node.def), ");\n")
      else
        out:write(encode_var(node[1].var), "=", encode_var(node.def), ";\n")
      end
    else
      if #node == 2 then
        out:write(encode_var(node.var), "=GETTABLE(", encode_var(node[1].var), ",", encode_var(node[2].var), ");\n")
      end
    end
  elseif symbol == symbol_table.var then
    if node.def then
      if #node == 2 then
        out:write("SETTABLE(", encode_var(node[1].var), ",", encode_var(node[2].var), ",", encode_var(node.def), ");\n")
      else
        out:write(encode_var(node[1].var), "=", encode_var(node.def), ";\n")
      end
    else
      if #node == 2 then
        out:write(encode_var(node.var), "=GETTABLE(", encode_var(node[1].var), ",", encode_var(node[2].var), ");\n")
      end
    end
  elseif symbol == symbol_table.explist then
    local that = node.parent
    if that[0] == symbol_table["="] then
      local lvars = that.vars
      local rvars = node.vars
      for i = 1, #lvars do
        local lvar = lvars[i]
        local rvar = rvars[i]
        if lvar ~= rvar then
          out:write(encode_var(lvar), "=", encode_var(rvar), ";\n")
        end
      end
    end
  elseif symbol == symbol_table["+"] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), "+", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table["-"] then
    if #node == 2 then
      out:write(encode_var(node.var), "=", encode_var(node[1].var), "-", encode_var(node[2].var), ";\n")
    else
      out:write(encode_var(node.var), "=-", encode_var(node[1].var), ";\n")
    end
  elseif symbol == symbol_table["*"] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), "*", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table["/"] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), "/", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table["//"] then
    out:write(encode_var(node.var), "=Math.floor(", encode_var(node[1].var), "/", encode_var(node[2].var), ");\n")
  elseif symbol == symbol_table["^"] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), "**", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table["%"] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), "%", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table["&"] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), "&", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table["~"] then
    if #node == 2 then
      out:write(encode_var(node.var), "=", encode_var(node[1].var), "^", encode_var(node[2].var), ";\n")
    else
      out:write(encode_var(node.var), "=~", encode_var(node[1].var), ";\n")
    end
  elseif symbol == symbol_table["|"] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), "|", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table[">>"] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), ">>>", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table["<<"] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), "<<", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table[".."] then
    out:write(encode_var(node.var), "=tostring(", encode_var(node[1].var), ")+tostring(", encode_var(node[2].var), ");\n")
  elseif symbol == symbol_table["<"] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), "<", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table["<="] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), "<=", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table[">"] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), ">", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table[">="] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), ">=", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table["=="] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), "===", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table["~="] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), "!==", encode_var(node[2].var), ";\n")
  elseif symbol == symbol_table["and"] then
    out:write(encode_var(node.var), "=", encode_var(node[2].var), ";\n")
    out:write "/* if */ }\n"
  elseif symbol == symbol_table["or"] then
    out:write(encode_var(node.var), "=", encode_var(node[2].var), ";\n")
    out:write "/* if */ }\n"
  elseif symbol == symbol_table["not"] then
    local var = node[1].var
    out:write(encode_var(node.var), "=", encode_var(var), "==undefined||", encode_var(var), "===false;\n")
  elseif symbol == symbol_table["#"] then
    out:write(encode_var(node.var), "=LEN(", encode_var(node[1].var), ");\n")
  elseif symbol == symbol_table.functioncall then
    local adjust = node.adjust
    if adjust == 0 then
      out:write "CALL0"
    elseif adjust == 1 then
      out:write(encode_var(node.var), "=CALL1")
    else
      out:write("T=CALL")
    end
    out:write("(", encode_var(node[1].var))
    local self = node.self
    if self then
      out:write(",", encode_var(self))
    end
    local that = node[2]
    for i = 1, #that do
      out:write(",", encode_var(that[i].var))
    end
    out:write ");\n"
  elseif symbol == symbol_table.fieldlist then
    local var = node.var
    out:write(encode_var(var), "=new Map();\n")
    for i = 1, #node do
      local that = node[i]
      if #that == 2 then
        out:write("SETTABLE(", encode_var(var), ",", encode_var(that[2].var), ",", encode_var(that[1].var), ");\n")
      end
    end
    local index = 0
    for i = 1, #node do
      local that = node[i]
      if #that == 1 then
        index = index + 1
        out:write("SETLIST(", encode_var(var), ",", index, ",", encode_var(that[1].var), ");\n")
      end
    end
  end

  if proto then
    out:write "}\n"
    out:write "}\n"
    out:write(("/* %s */ };\n"):format(proto[1]))
  end
end

return function (self, out, name)
  if name then
    out:write(name, " = ")
  else
    out:write "("
  end

  out:write "function (env) {\n"
  out:write(runtime_es);
  out:write [[
if (env === undefined) {
  env = open_env();
}
const B = [env];
]]
  write(self, out, self.accepted_node, self.symbol_table)
  out:write "P0();\n"

  if name then
    out:write "};\n"
  else
    out:write "})();\n"
  end

  return out
end

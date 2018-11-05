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

local template = require "dromozoa.compiler.syntax_tree.template"

local char_table = {
  ["\""] = [[\"]];
  ["\\"] = [[\\]];
  ["\n"] = [[\n]];
}

for byte = 0x00, 0x7F do
  local char = string.char(byte)
  if not char_table[char] then
    char_table[char] = ([[\x02X]]):format(byte)
  end
end

local var_table = {
  V = "V";
  T = "T";
  NIL = "NIL";
  FALSE = "FALSE";
  TRUE = "TRUE";
}

local function encode_string(s)
  return "\"" .. s:gsub("[%z\1-\31\127]", char_table) .. "\""
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
      return "(*U[" .. var:sub(2) .. "])"
    elseif key == "K" then
      return "K->" .. var
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
  local var = result[#result]
  if var == "V" or var == "T" then
    result[#result] = nil
    if #result == 0 then
      return var
    else
      return "array_t({ " .. table.concat(result, ", ") .. " }, " .. var .. ")"
    end
  else
    if #result == 0 then
      return "{}"
    else
      return "{ " .. table.concat(result, ", ") .. " }"
    end
  end
end

local tmpl = template(encode_var, {
  MOVE     = "%1 = %2";
  GETTABLE = "%1 = gettable(%2, %3)";
  SETTABLE = "settable(%1, %2, %3)";
  NEWTABLE = "%1 = type_t::table";
  ADD      = "%1 = %2.checknumber() + %3.checknumber()";
  SUB      = "%1 = %2.checknumber() - %3.checknumber()";
  MUL      = "%1 = %2.checknumber() * %3.checknumber()";
  MOD      = "%1 = std::fmod(%2.checknumber(), %3.checknumber())";
  POW      = "%1 = std::pow(%2.checknumber(), %3.checknumber())";
  DIV      = "%1 = %2.checknumber() / %3.checknumber()";
  IDIV     = "%1 = std::floor(%2.checknumber() / %3.checknumber())";
  BAND     = "%1 = %2.checkinteger() & %3.checkinteger()";
  BOR      = "%1 = %2.checkinteger() | %3.checkinteger()";
  BXOR     = "%1 = %2.checkinteger() ^ %3.checkinteger()";
  SHL      = "%1 = %2.checkinteger() << %3.checkinteger()";
  SHR      = "%1 = %2.checkinteger() >> %3.checkinteger()";
  UNM      = "%1 = -%2.checknumber()";
  BNOT     = "%1 = ~%2.checkinteger()";
  NOT      = "%1 = !%2.toboolean()";
  LEN      = "%1 = len(%2)";
  CONCAT   = "%1 = %2.checkstring() + %3.checkstring()";
  EQ       = "%1 = eq(%2, %3)";
  NE       = "%1 = !eq(%2, %3)";
  LT       = "%1 = lt(%2, %3)";
  LE       = "%1 = le(%2, %3)";
  BREAK    = "break";
  GOTO     = "goto %1";
  TONUMBER = "%1 = %2.checknumber()";
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
      if cond[2] == "TRUE" then
        out:write(("if (%s.toboolean()) {\n"):format(encode_var(cond[1])))
      else
        out:write(("if (!%s.toboolean()) {\n"):format(encode_var(cond[1])))
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
        out:write(("call0(%s, %s);\n"):format(encode_var(code[2]), encode_vars(code, 3)))
      elseif var == "T" then
        out:write(("T = call(%s, %s);\n"):format(encode_var(code[2]), encode_vars(code, 3)))
      else
        out:write(("%s = call1(%s, %s);\n"):format(encode_var(var), encode_var(code[2]), encode_vars(code, 3)))
      end
    elseif name == "RETURN" then
      local n = #code
      if n == 0 then
        out:write "return {};\n"
      else
        out:write(("return %s;\n"):format(encode_vars(code)))
      end
    elseif name == "SETLIST" then
      out:write(("setlist(%s, %d, %s);\n"):format(encode_var(code[1]), code[2], encode_var(code[3])))
    elseif name == "CLOSURE" then
      out:write(("value_t %s = std::make_shared<%s_T>(U, A, B);\n"):format(code[1], code[1]))
    elseif name == "LABEL" then
      out:write(("%s:\n"):format(code[1]))
    else
      out:write(tmpl:eval(name, code), ";\n")
    end
  end
end

function compile_proto(self, out, proto)
  local name = proto[1]

  local constants = proto.constants
  local upvalues = proto.upvalues

  local kn = #constants
  local un = #upvalues

  out:write(("struct %s_K {\n"):format(name))
  if kn > 0 then
    for i = 1, kn do
      out:write(("const value_t %s;\n"):format(constants[i][1]))
    end
    out:write(("%s_K()\n"):format(name))
    for i = 1, kn do
      if i == 1 then
        out:write ": "
      else
        out:write ",\n  "
      end

      local constant = constants[i]
      if constant.type == "string" then
        local source = constant.source
        out:write(("%s(%s, %d)"):format(constant[1], encode_string(source), #source))
      else
        out:write(("%s(%.17g)"):format(constant[1], tonumber(constant.source)))
      end
    end
    out:write " {}\n"
  end
  out:write(([[
static const %s_K* get() {
  static const %s_K instance;
  return &instance;
}
]]):format(name, name))
  out:write "};\n"

  out:write(([[
struct %s_Q {
const %s_K* K;
uparray_t U;
array_t A;
array_t V;
array_t B;
array_t C;
%s_Q(uparray_t U, array_t A, array_t V)
  : K(%s_K::get()),
    U(U),
    A(A),
    V(V),
    B(%d),
    C(%d) {}
array_t Q0() const {
]]):format(name, name, name, name, proto.B, proto.C))
  if proto.T then
    out:write "array_t T;\n"
  end
  compile_code(self, out, proto.code)
  out:write [[
return {};
}
};
]]

  out:write(([[
struct %s_T : proto_t<%d> {
uparray_t U;
%s_T(uparray_t S, array_t A, array_t B)
]]):format(name, proto.A, name))
  if un == 0 then
    out:write " {}\n"
  else
    out:write [[
: U {
]]
    for i = 1, #upvalues do
      local var = upvalues[i][2]
      local key = var:sub(1, 1)
      if key == "U" then
        out:write(("    S[%d],\n"):format(var:sub(2)))
      else
        out:write(("    { %s, %d },\n"):format(key, var:sub(2)))
      end
    end
    out:write [[
  } {}
]]
  end

  out:write(([[
array_t operator()(array_t A, array_t V) const {
  return std::make_shared<%s_Q>(U, A, V)->Q0();
}
]]):format(name))



  out:write "};\n"
end


return function (self, out, name)
  out:write [[
#include <cmath>
#include <iostream>
#include "runtime.hpp"
]]

  out:write "namespace"
  if name then
    out:write(" ", name)
  end
  out:write " {\n"
  out:write "using namespace dromozoa::runtime;\n"

  local protos = self.protos
  for i = #protos, 1, -1 do
    compile_proto(self, out, protos[i])
  end

  out:write [[
value_t chunk() {
  uparray_t S;
  array_t A;
  array_t B = { env };
  return std::make_shared<P0_T>(S, A, B);
}
}
]]

  if name then
    return out
  end

  out:write [[
int main(int, char*[]) {
  using namespace dromozoa::runtime;
  try {
    call0(chunk(), {});
    return 0;
  } catch (const value_t& e) {
    std::cerr << tostring(e) << std::endl;
  } catch (const std::exception& e) {
    std::cerr << e.what() << std::endl;
  }
  return 1;
}
]]

  return out
end

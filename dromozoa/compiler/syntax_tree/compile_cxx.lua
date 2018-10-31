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
  NIL = "nil()";
  FALSE = "false_()";
  TRUE = "true_()";
}

local function encode_string(s)
  return "\"" .. s:gsub("[%z\1-\31\127]", char_table) .. "\""
end

local function proto_name(var)
  return "proto" .. var:sub(2)
end

local function encode_var(var)
  local result = var_table[var]
  if result then
    return result
  else
    local key = var:sub(1, 1)
    if key == "P" or key == "L" then
      return var
    elseif key == "V" or key == "T" then
      return "get(" .. key .. ", " .. var:sub(2) .. ")"
    elseif key == "U" then
      local index = var:sub(2)
      return "(*std::get<0>((*U)[" .. index .. "]))[std::get<1>((*U)[" .. index .. "])]"
    elseif key == "K" then
      return "K->" .. var
    else
      return "(*" .. key .. ")[" .. var:sub(2) .. "]"
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
    return "{" .. table.concat(result, ", ") .. "}, " ..var
  else
    return "{" .. table.concat(result, ", ") .. "}"
  end
end

local tmpl = template(encode_var, {
  MOVE     = "%1 = %2";
  GETTABLE = "%1 = %2.gettable(%3)";
  SETTABLE = "%1.settable(%2, %3)";
  NEWTABLE = "%1 = table()";
  ADD      = "%1 = number(%2.tonumber() + %3.tonumber())";
  SUB      = "%1 = number(%2.tonumber() - %3.tonumber())";
  MUL      = "%1 = number(%2.tonumber() * %3.tonumber())";
  MOD      = "%1 = number(%2.tointeger() % %3.tointeger())";
  POW      = "%1 = number(std::pow(%2.tonumber(), %3.tonumber()))";
  DIV      = "%1 = number(%2.tonumber() / %3.tonumber())";
  IDIV     = "%1 = number(std::floor(%2.tonumber() / %3.tonumber()))";
  BAND     = "%1 = number(%2.tointeger() & %3.tointeger())";
  BOR      = "%1 = number(%2.tointeger() | %3.tointeger())";
  BXOR     = "%1 = number(%2.tointeger() ^ %3.tointeger())";
  SHL      = "%1 = number(%2.tointeger() << %3.tointeger())";
  SHR      = "%1 = number(%2.tointeger() >> %3.tointeger())";
  UNM      = "%1 = number(-%2.tonumber())";
  BNOT     = "%1 = number(~%2.tointeger())";
  NOT      = "%1 = boolean(%2 == nil() || %2 == false_())";
  LEN      = "%1 = %2.len()";
  CONCAT   = "%1 = string(%2.tostring() + %3.tostring())";
  EQ       = "%1 = boolean(%2 == %3)";
  NE       = "%1 = boolean(%2 != %3)";
  LT       = "%1 = boolean(%2.lt(%3))";
  LE       = "%1 = boolean(%2.le(%3))";
  BREAK    = "break";
  GOTO     = "goto %1";
  TONUMBER = "%1 = number(%2.tonumber())";
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
      local a = encode_var(cond[1])
      if cond[2] == "TRUE" then
        out:write(("if (%s != nil() && %s != false_()) {\n"):format(a, a))
      else
        out:write(("if (%s == nil() || %s == false_()) {\n"):format(a, a))
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
        out:write(("%s.call0(newarray(%s));\n"):format(encode_var(code[2]), encode_vars(code, 3)))
      elseif var == "T" then
        out:write(("T = %s.call(newarray(%s));\n"):format(encode_var(code[2]), encode_vars(code, 3)))
      else
        out:write(("%s = %s.call1(newarray(%s));\n"):format(encode_var(var), encode_var(code[2]), encode_vars(code, 3)))
      end
    elseif name == "RETURN" then
      local n = #code
      if n == 0 then
        out:write "return nullptr;\n"
      else
        out:write(("return newarray(%s);\n"):format(encode_vars(code)))
      end
    elseif name == "SETLIST" then
      out:write(("%s.setlist(%d, %s);\n"):format(encode_var(code[1]), code[2], encode_var(code[3])))
    elseif name == "CLOSURE" then
      out:write(("auto %s = function(std::make_shared<%s>(U, A, B));\n"):format(code[1], proto_name(code[1])))
    elseif name == "LABEL" then
      out:write(("%s:\n"):format(code[1]))
    else
      out:write(tmpl:eval(name, code), ";\n")
    end
  end
end

function compile_proto(self, out, proto)
  local constants = proto.constants
  local upvalues = proto.upvalues

  local kn = #constants
  local un = #upvalues

  if kn > 0 then
    out:write(("struct %s_constants {\n"):format(proto_name(proto[1])))
    for i = 1, kn do
      local constant = constants[i]
      out:write(("value_t %s;\n"):format(constant[1]))
    end
    out:write(("%s_constants() {\n"):format(proto_name(proto[1])))
    for i = 1, kn do
      local constant = constants[i]
      if constant.type == "string" then
        local source = constant.source
        out:write(("%s = string(%s, %d);\n"):format(constant[1], encode_string(source), #source))
      else
        out:write(("%s = number(%.17g);\n"):format(constant[1], tonumber(constant.source)))
      end
    end
    out:write "}\n"
    out:write(("static %s_constants* get() {\n"):format(proto_name(proto[1])))
    out:write(("static %s_constants instance;\n"):format(proto_name(proto[1])))
    out:write "return &instance;\n"
    out:write "}\n"
    out:write "};\n"
  end

  out:write(("struct %s : function_t {\n"):format(proto_name(proto[1])))

  if kn > 0 then
    out:write(("%s_constants* K;\n"):format(proto_name(proto[1])))
  end
  out:write "upvalues_ptr U;\n"

  out:write(("%s(upvalues_ptr S, array_ptr A, array_ptr B)\n"):format(proto_name(proto[1])))
  out:write((": function_t(%d, %s)\n"):format(proto.A, proto.V and "true" or "false"))
  if kn > 0 then
    out:write((",K(%s_constants::get())\n"):format(proto_name(proto[1])))
  end
  out:write "{\n"

  if #upvalues > 0 then
    out:write(("U = std::make_shared<upvalues_t>(%d);\n"):format(#upvalues))
    for i = 1, #upvalues do
      local upvalue = upvalues[i]
      local var = upvalue[2]
      local key = var:sub(1, 1)
      if key == "U" then
        local index = var:sub(2)
        out:write(("(*U)[%d] = (*S)[%d];\n"):format(i - 1, index))
      else
        out:write(("(*U)[%d] = std::make_tuple(%s, %d);\n"):format(i - 1, key, var:sub(2)))
      end
    end
  end
  out:write "}\n"

  local A = proto.A
  local B = proto.B
  local C = proto.C

  out:write "array_ptr operator()(array_ptr A, array_ptr V) const {\n"
  out:write(("array_ptr B = std::make_shared<array_t>(%d);\n"):format(B))
  out:write(("array_ptr C = std::make_shared<array_t>(%d);\n"):format(C))
  if proto.T then
    out:write "array_ptr T;\n"
  end

  compile_code(self, out, proto.code)

  out:write "return nullptr;\n"
  out:write "}\n"

  out:write "};\n"
end


return function (self, out, name)
  out:write "#include \"runtime_cxx.hpp\"\n"

  out:write "namespace"
  if name then
    out:write(" ", name)
  end
  out:write "{\n"
  out:write "using namespace dromozoa::runtime;\n"

  local protos = self.protos
  for i = #protos, 1, -1 do
    compile_proto(self, out, protos[i])
  end

  out:write "}\n"

  if name then
    return out
  end

  out:write [[
int main(int, char*[]) {
  using namespace dromozoa::runtime;

  array_ptr B = std::make_shared<array_t>(1);
  (*B)[0] = env();
  try {
    auto P0 = proto0(nullptr, nullptr, B);
    P0(nullptr, nullptr);
    return 0;
  } catch (const error_t& e) {
    std::cerr << e.what() << std::endl;
  }
  return 1;
}
]]

  return out
end

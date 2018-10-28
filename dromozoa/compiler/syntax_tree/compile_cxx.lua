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

local runtime_cxx = require "dromozoa.compiler.runtime.runtime_cxx"

local compile_proto
local compile_code

local function write_block(self, out, code)
  for i = 1, #code do
    compile_code(self, out, code[i])
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

  local param_A = "array_ptr"
  local param_V = "array_ptr"
  if A > 0 then
    param_A = "array_ptr A"
  end
  if proto.vararg then
    param_V = "array_ptr V"
  end
  out:write(("value_t %s = value_t::function(%d, %s, (%s, %s) => {\n"):format(proto[1], A, proto.vararg, param_A, param_V))

--[====[
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
]====]
  out:write "});\n"
end


return function (self, out, name)
  out:write(runtime_cxx);

  if name then
    out:write(("%s = "):format(name))
  else
    out:write "int main(int, char*[]) { ("
  end

  out:write [[
[=](dromozoa::runtime::value_t env) -> dromozoa::runtime::tuple_t {
using namespace dromozoa::runtime;
if (env == NIL) {
  env = open_env();
}
array_ptr B = std::make_shared<array_t>(1);
(*B)[0] = env;
]]

  compile_proto(self, out, "P0")
  out:write "return P0.call();\n"

  if name then
    out:write "};\n"
  else
    out:write "})(dromozoa::runtime::NIL);}\n"
  end

  return out
end

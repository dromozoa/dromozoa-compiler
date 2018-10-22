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

local runtime = [[
let runtime_env = function () {
  let tostring = function (v) {
    const t = typeof v;
    if (t === "undefined") {
      return "nil";
    } else if (t === "number") {
      return v.toString();
    } else if (t === "string") {
      return v;
    } else if (t === "boolean") {
      if (v) {
        return "true";
      } else {
        return "false";
      }
    } else if (t === "object") {
      if (Map.prototype.isPrototypeOf(v)) {
        return "table";
      }
    } else if (t === "function") {
      return "function";
    }
    return "userdata";
  };
  let env = new Map();
  env.set("print", function (...vararg) {
    for (let i = 0; i < vararg.length; ++i) {
      if (i > 0) {
        process.stdout.write("\t");
      }
      process.stdout.write(tostring(vararg[i]));
    }
    process.stdout.write("\n");
    return [];
  });
  env.set("assert", function (...vararg) {
    let v = vararg[0];
    if (v === undefined || v === false) {
      if (vararg.length > 1) {
        throw vararg[1];
      } else {
        throw "assertion failed"
      }
    }
    return vararg;
  });
  return env;
};
if (env === undefined) {
  env = runtime_env();
}
]]

-- https://tc39.github.io/ecma262/#prod-DoubleStringCharacter
local char_table = {
  ["\n"] = [[\n]];
  ["\r"] = [[\r]];
  ["\\"] = [[\\]];
  ["\""] = [[\"]];
  [string.char(0xE2, 0x80, 0xA8)] = [[\u2028]]; -- LS / LINE SEPARATOR
  [string.char(0xE2, 0x80, 0xA9)] = [[\u2029]]; -- PS / PARAGRAPH SEPARATOR
}

for byte = 0x00, 0x7F do
  local char = string.char(byte)
  if not char_table[char] then
    char_table[char] = ([[\u04X]]):format(byte)
  end
end

local function encode_string(s)
  return "\"" .. s:gsub("[%z\1-\31\127]", char_table):gsub("\226\128[\168\169]", char_table) .. "\""
end

local function encode_var(var)
  if not var then
    return "?"
  end

  if var == "V" then
    return "V"
  elseif var == "T" then
    return "T"
  elseif var == "NIL" then
    return "undefined"
  else
    local k = var:sub(1, 1)
    if k == "U" then
      local i = var:sub(2)
      return "U[" .. i .. "][0][U[" .. i .. "][1]]"
    elseif k == "P" then
      return var
    else
      return k .. "[" .. var:sub(2) .. "]"
    end
  end
end

local function write_constants(self, out, proto)
  local constants = proto.constants
  local n = #constants
  out:write(("let %s_K = [\n"):format(proto[1]))
  for j = 1, #constants do
    local constant = constants[j]
    if constant.type == "string" then
      out:write(("/* %s */ %s,\n"):format(constant[1], encode_string(constant.source)))
    else
      out:write(("/* %s */ %.17g,\n"):format(constant[1], tonumber(constant.source)))
    end
  end
  out:write "];\n"
end

local function write_proto(self, out, node, proto)
  local proto_name = proto[1]
  out:write(("let %s = function () {\n"):format(proto_name))

  local constants = proto.constants
  out:write "let K = [\n"
  for j = 1, #constants do
    local constant = constants[j]
    if constant.type == "string" then
      out:write(("/* %s */ %s,\n"):format(constant[1], encode_string(constant.source)))
    else
      out:write(("/* %s */ %.17g,\n"):format(constant[1], tonumber(constant.source)))
    end
  end
  out:write "];\n"

  out:write "};\n";
end

local function write(self, out, node, symbol_table)
  local proto = node.proto
  if proto then
    local A = proto.A
    out:write(("let %s = function ("):format(proto[1]))
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
    out:write "let K = [\n"
    for i = 1, #constants do
      local constant = constants[i]
      if constant.type == "string" then
        out:write(("/* %s */ %s,\n"):format(constant[1], encode_string(constant.source)))
      else
        out:write(("/* %s */ %.17g,\n"):format(constant[1], tonumber(constant.source)))
      end
    end
    out:write "];\n"

    local upvalues = proto.upvalues
    out:write "let U = [\n"
    for i = 1, #upvalues do
      local upvalue = upvalues[i]
      local var = upvalue[2]
      assert(var:find "^[ABCU]%d+$")
      out:write(("/* %s */ [%s,%d],\n"):format(upvalue[1], var:sub(1, 1), var:sub(2)))
    end
    out:write "];\n"

    out:write "{\n"
    out:write "let A = [\n"
    for i = 0, A - 1 do
      out:write("A", i, ",\n")
    end
    out:write "];\n"

    out:write "let B = [];\n"
    out:write "let C = [];\n"
    out:write "let T;\n"
  end

  for i = 1, #node do
    write(self, out, node[i], symbol_table)
  end

  local symbol = node[0]
  if symbol == symbol_table.var then
    if #node == 2 then
      out:write(encode_var(node.var), "=", encode_var(node[1].var), ".get(", encode_var(node[2].var), ");\n")
    end
  elseif symbol == symbol_table["local"] then
    local vars = node[1].vars
    local that = node[2]
    for i = 1, #that do
      out:write(encode_var(that[i].var), "=", encode_var(vars[i]), ";\n")
    end
  elseif symbol == symbol_table["return"] then
    local that = node[1]
    out:write "return ["
    for i = 1, #that do
      if i > 1 then
        out:write ", "
      end
      out:write(encode_var(that[i].var))
    end
    out:write "];\n"
  elseif symbol == symbol_table.functioncall then
    local adjust = node.adjust
    if adjust > 0 then
      out:write(encode_var(node.var), "=")
    end
    out:write(encode_var(node[1].var), "(")
    local that = node[2]
    for i = 1, #that do
      if i > 1 then
        out:write ", "
      end
      out:write(encode_var(that[i].var))
    end
    out:write ")"
    if adjust == 1 then
      out:write "[0]"
    end
    out:write ";\n"
  elseif symbol == symbol_table["+"] then
    out:write(encode_var(node.var), "=", encode_var(node[1].var), "+", encode_var(node[2].var), ";\n")
  end

  if proto then
    out:write "}\n"
    out:write(("/* %s */ };\n"):format(proto[1]))
  end
end

return function (self, out, name)
  out:write(name, " = function (env) {\n")
  out:write(runtime);
  out:write "let B = [env];\n"
  write(self, out, self.accepted_node, self.symbol_table)
  out:write "P0();\n"
  out:write "};\n"
  out:write(name, "();\n");
  return out
end

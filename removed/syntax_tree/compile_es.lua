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

local runtime_es = require "dromozoa.compiler.runtime.runtime_es"
local template = require "dromozoa.compiler.syntax_tree.template"
local decode_var = require "dromozoa.compiler.syntax_tree.decode_var"

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
  V = "...this.V";
  T = "...this.T";
  NIL = "undefined";
  FALSE = "false";
  TRUE = "true";
}

local function encode_string(s)
  local s = s:gsub("[%z\1-\31\127]", char_table)
  local s = s:gsub("\226\128[\168\169]", char_table)
  return "\"" .. s .. "\""
end

local function encode_var(var)
  local key, i = decode_var(var)
  local result = var_table[key]
  if result and not i then
    return result
  else
    if key == "L" or key == "M" then
      return key .. i
    elseif key == "U" then
      return "this.U[" .. i .. "].value"
    else
      return "this." .. key .. "[" .. i .. "]"
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
  NEWTABLE = "%1 = new table_t()";
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
  CONCAT   = "%1 = concat(checkstring(%2), checkstring(%3))";
  EQ       = "%1 = eq(%2, %3)";
  NE       = "%1 = !eq(%2, %3)";
  LT       = "%1 = lt(%2, %3)";
  LE       = "%1 = le(%2, %3)";
  BREAK    = "break";
  GOTO     = "L = %1; continue";
  TONUMBER = "%1 = checknumber(%2)";
})

local compile_code

local function write_block(self, out, code, indent, opts)
  for i = 1, #code do
    compile_code(self, out, code[i], indent, opts)
  end
end

function compile_code(self, out, code, indent, opts)
  local name = code[0]
  if code.block then
    if name == "LOOP" then
      out:write(indent, "for (;;) {\n")
      write_block(self, out, code, indent .. "  ", opts)
      out:write(indent, "}\n")
    elseif name == "COND" then
      local cond = code[1]
      out:write(indent, ("if (%stoboolean(%s)) {\n"):format(
          decode_var(cond[2]) == "TRUE" and "" or "!",
          encode_var(cond[1])))
      write_block(self, out, code[2], indent .. "  ", opts)
      if #code == 2 then
        out:write(indent, "}\n")
      else
        out:write(indent, "} else {\n")
        write_block(self, out, code[3], indent .. "  ", opts)
        out:write(indent, "}\n")
      end
    else
      write_block(self, out, code, indent, opts)
    end
  else
    if name == "CALL" then
      local var = code[1]
      local key, i = decode_var(var)
      if key == "NIL" then
        out:write(indent, ("call0(%s);\n"):format(encode_vars(code, 2)))
      elseif key == "T" then
        out:write(indent, ("this.T = call(%s);\n"):format(encode_vars(code, 2)))
      else
        out:write(indent, ("%s = call1(%s);\n"):format(encode_var(var), encode_vars(code, 2)))
      end
    elseif name == "RETURN" then
      local n = #code
      if n == 0 then
        out:write(indent, "return;\n")
      elseif n == 1 then
        local var = code[1]
        local key, i = decode_var(var)
        if (key == "V" or key == "T") and not i then
          out:write(indent, ("return this.%s;\n"):format(key))
        else
          out:write(indent, ("return %s;\n"):format(encode_var(var)))
        end
      else
        out:write(indent, ("return [ %s ];\n"):format(encode_vars(code)))
      end
    elseif name == "SETLIST" then
      out:write(indent, ("setlist(%s, %d, %s);\n"):format(encode_var(code[1]), code[2], encode_var(code[3])))
    elseif name == "CLOSURE" then
      out:write(indent, ("%s = new %s(this.U, this.A, this.B);\n"):format(encode_var(code[1]), code[2]))
    elseif name == "LABEL" then
      out:write(("      case %s:\n"):format(encode_var(code[1])))
    elseif name == "COND" then
      out:write(indent, ("if (%stoboolean(%s)) L = %s; else L = %s; continue;\n"):format(
          decode_var(code[2]) == "TRUE" and "" or "!",
          encode_var(code[1]),
          code[3],
          code[4]))
    else
      out:write(indent, tmpl:eval(name, code), ";\n")
    end
  end
end

local function compile_constants(self, out, proto, opts)
  local name = proto[1]
  local constants = proto.constants

  local inits = {}
  for i = 1, #constants do
    local constant = constants[i]
    if constant.type == "string" then
      inits[i] = ("wrap(%s)"):format(encode_string(constant.source))
    else
      inits[i] = ("%.17g"):format(tonumber(constant.source))
    end
  end

  out:write(([[

const %s_constants = [%s];
]]):format(name, template.concat(inits, ",\n  ", "\n  ", ",\n")))
end

local function compile_codes(self, out, proto, opts)
  out:write [[

  entry() {
]]

  if opts.mode == "flat_code" then
    compile_code(self, out, proto.flat_code, "    ", opts)
  else
    compile_code(self, out, proto.tree_code, "    ", opts)
  end

  out:write [[
  }
]]
end

local function compile_emulated_goto(self, out, proto, opts)
  local labels = proto.labels

  local decls = {}
  for i = 1, #labels do
    decls[i] = ("const %s = %d"):format(labels[i][1], i)
  end
  if opts.mode == "flat_code" then
    for i = 0, proto.M - 1 do
      local n = #decls + 1
      decls[n] = ("const M%d = %d"):format(i, n)
    end
  end

  out:write(([[

  entry() {
    %s;
    let L = 0;
    for (;;) {
      switch (L) {
      case 0:
]]):format(template.concat(decls, ";\n    ")))

  if opts.mode == "flat_code" then
    compile_code(self, out, proto.flat_code, "        ", opts)
  else
    compile_code(self, out, proto.tree_code, "        ", opts)
  end

  out:write [[
      }
      return;
    }
  }
]]
end

local function compile_basic_block(self, out, basic_blocks, uid, block, indent, opts)
  out:write(([[

  BB%d() {
]]):format(uid))

  local code
  local name
  for i = 1, #block do
    code = block[i]
    name = code[0]
    if name == "RETURN" or name == "COND" then
      break
    else
      compile_code(self, out, code, indent, opts)
    end
  end

  if name == "RETURN" then
    out:write(indent, ("return this.BB%d(%s);\n"):format(basic_blocks.exit_uid, encode_vars(code)))
  else
    local g = basic_blocks.g
    local uv = g.uv
    local uv_target = uv.target
    local eid = uv.first[uid]
    if name == "COND" then
      local then_uid = uv_target[eid]
      eid = uv.after[eid]
      out:write(indent, ("if (%stoboolean(%s)) return this.BB%d(); else return this.BB%d();\n"):format(
          decode_var(code[2]) == "TRUE" and "" or "!",
          encode_var(code[1]),
          then_uid,
          uv_target[eid]))
    else
      out:write(indent, ("return this.BB%d();\n"):format(uv_target[eid]))
    end
  end

  out:write(([[
  }
]]):format(uid))
end

local function compile_basic_blocks(self, out, proto, opts)
  local basic_blocks = proto.basic_blocks
  local g = basic_blocks.g
  local u = g.u
  local u_after = u.after
  local exit_uid = basic_blocks.exit_uid
  local blocks = basic_blocks.blocks

  out:write(([[

  entry() {
    return this.BB%d();
  }
]]):format(basic_blocks.entry_uid))

  local uid = u.first
  while uid do
    if uid ~= exit_uid then
      compile_basic_block(self, out, basic_blocks, uid, blocks[uid], "    ", opts)
    end
    uid = u_after[uid]
  end

  out:write(([[

  BB%d(...result) {
    return result;
  }
]]):format(exit_uid))
end

local function compile_program(self, out, proto, opts)
  local name = proto[1]

  out:write(([[

class %s_program {
  constructor(U, A, V) {
    this.K = %s_constants;
    this.U = U;
    this.A = A;
    this.V = V;
    this.B = [];
    this.C = [];
  }
]]):format(name, name))

  if opts.mode == "basic_blocks" then
    compile_basic_blocks(self, out, proto, opts)
  elseif opts.mode == "flat_code" then
    if proto["goto"] or proto.M > 0 then
      compile_emulated_goto(self, out, proto, opts)
    else
      compile_codes(self, out, proto, opts)
    end
  else
    if proto["goto"] then
      compile_emulated_goto(self, out, proto, opts)
    else
      compile_codes(self, out, proto, opts)
    end
  end

  out:write [[
}
]]
end

local function compile_proto(self, out, proto, opts)
  local name = proto[1]
  local upvalues = proto.upvalues

  local uinits = {}
  for i = 1, #upvalues do
    local var = upvalues[i][2]
    local key = var:sub(1, 1)
    if key == "U" then
      uinits[i] = ("S[%d]"):format(var:sub(2))
    else
      uinits[i] = ("new upvalue_t(%s, %d)"):format(key, var:sub(2))
    end
  end

  local params = {}
  local ainits = {}
  for i = 1, proto.A do
    local name = "A" .. i - 1
    params[i] = name
    ainits[i] = name
  end
  params[#params + 1] = "...V"

  compile_constants(self, out, proto, opts)
  compile_program(self, out, proto, opts)

  out:write(([[

class %s extends proto_t {
  constructor(S, A, B) {
    super();
    this.U = [%s];
  }

  entry(%s) {
    const A = [%s];
    return new %s_program(this.U, A, V).entry();
  }
}
]]):format(
    name,
    template.concat(uinits, ",\n      ", "\n      ", ",\n    "),
    template.concat(params, ", "),
    template.concat(ainits, ", ", " ", " "),
    name))
end

return function (self, out, opts)
  if not opts then
    opts = {}
  end
  local name = opts.name

  if name then
    out:write(([[
%s = () => {
]]):format(name))
  else
    out:write [[
(() => {
]]
  end
  out:write(runtime_es);

  local protos = self.protos
  for i = #protos, 1, -1 do
    compile_proto(self, out, protos[i], opts)
  end

  out:write [[

return new P0([], [], [ env ]);
]]

  if name then
    out:write [[
};
]]
  else
    out:write [[
})().entry();
]]
  end

  return out
end

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

local function write_use(out, item, key)
  local use = item[key]
  if use[1] then
    out:write(("      %s %s\n"):format(key, table.concat(use, " ")))
  end
end

local function dump_code(out, code, indent)
  if code.block then
    local block_indent = indent .. "  "
    out:write(indent)
    local name = code[0]
    if name then
      out:write(name, " ")
    end
    out:write "{\n"
    for i = 1, #code do
      dump_code(out, code[i], block_indent)
    end
    out:write(indent, "}\n")
  else
    out:write(indent, code[0])
    for i = 1, #code do
      out:write(" ", var:encode())
    end
    out:write "\n"
  end
end

local function dump_proto(out, proto, opts)
  out:write(proto[1]:encode(), "\n")

  local parent = proto.parent[1]
  if parent then
    out:write("  parent ", parent:encode(), "\n")
  end
  if proto.self then
    out:write "  self\n"
  end
  if proto.vararg then
    out:write "  vararg\n"
  end
  if proto["goto"] then
    out:write "  goto\n"
  end
  out:write(("  A %d\n"):format(proto.A))
  out:write(("  B %d\n"):format(proto.B))
  out:write(("  C %d\n"):format(proto.C))
  if proto.V then
    out:write "  V\n"
  end
  if proto.T then
    out:write "  T\n"
  end

  local labels = proto.labels
  if labels[1] then
    out:write "  labels\n"
    for j = 1, #labels do
      local label = labels[j]
      out:write(("    %s %q\n"):format(label[1], label.source))
      write_use(out, label, "def")
      write_use(out, label, "use")
    end
  end

  local constants = proto.constants
  if constants[1] then
    out:write "  constants\n"
    for j = 1, #constants do
      local constant = constants[j]
      out:write(("    %s %q %s\n"):format(constant[1], constant.source, constant.type))
      write_use(out, constant, "use")
    end
  end

  local upvalues = proto.upvalues
  if upvalues[1] then
    out:write "  upvalues\n"
    for j = 1, #upvalues do
      local upvalue = upvalues[j]
      out:write(("    %s %s (%s %q)\n"):format(upvalue[1], upvalue[2], upvalue.name[1], upvalue.name.source))
    end
  end

  local names = proto.names
  if names[1] then
    out:write "  names\n"
    for j = 1, #names do
      local name = names[j]
      out:write(("    %s %q\n"):format(name[1], name.source))
      write_use(out, name, "def")
      write_use(out, name, "use")
      write_use(out, name, "updef")
      write_use(out, name, "upuse")
    end
  end

  if opts.mode == "flat_code" then
    dump_code(out, proto.flat_code, "  ")
  else
    dump_code(out, proto.tree_code, "  ")
  end

  out:write "\n"
end

return function (self, out, opts)
  local protos = self.protos
  for i = 1, #protos do
    dump_proto(out, protos[i], opts)
  end
  return out
end

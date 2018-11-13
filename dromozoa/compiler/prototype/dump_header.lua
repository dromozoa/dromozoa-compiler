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

local function dump_use(buffer, item, key, indent)
  local use = item[key]
  if use[1] then
    buffer[#buffer + 1] = indent .. ("%s %s\n"):format(key, table.concat(use, " "))
  end
end

local function dump_items(buffer, self, key, indent, f)
  local items = self[key]
  if items[1] then
    buffer[#buffer + 1] = indent .. ("%s {\n"):format(key)
    local block_indent = indent .. "  "
    for i = 1, #items do
      f(buffer, items[i], block_indent)
    end
    buffer[#buffer + 1] = indent .. "}\n"
  end
end

return function (buffer, self, indent)
  local parent = self.parent[1]
  if parent then
    buffer[#buffer + 1] = indent .. ("parent %s\n"):format(parent:encode())
  end

  if self.self then
    buffer[#buffer + 1] = indent .. "self\n"
  end

  if self.vararg then
    buffer[#buffer + 1] = indent .. "vararg\n"
  end

  local keys = { "M", "A", "B", "C", "V", "T" }
  for i = 1, #keys do
    local key = keys[i]
    buffer[#buffer + 1] = indent .. ("%s %d\n"):format(key, self[key])
  end

  dump_items(buffer, self, "labels", indent, function (buffer, item, indent)
    buffer[#buffer + 1] = indent .. ("%s %q\n"):format(item[1]:encode(), item.source)
    local block_indent = indent .. "  "
    dump_use(buffer, item, "def", block_indent)
    dump_use(buffer, item, "use", block_indent)
  end)

  dump_items(buffer, self, "constants", indent, function (buffer, item, indent)
    buffer[#buffer + 1] = indent .. ("%s %q %s\n"):format(item[1]:encode(), item.source, item.type)
    local block_indent = indent .. "  "
    dump_use(buffer, item, "use", block_indent)
  end)

  dump_items(buffer, self, "upvalues", indent, function (buffer, item, indent)
    buffer[#buffer + 1] = indent .. ("%s %s (%s %q)\n"):format(item[1]:encode(), item[2]:encode(), item.name[1], item.name.source)
  end)

  dump_items(buffer, self, "names", indent, function (buffer, item, indent)
    buffer[#buffer + 1] = indent .. ("%s %q\n"):format(item[1]:encode(), item.source)
    local block_indent = indent .. "  "
    dump_use(buffer, item, "def", block_indent)
    dump_use(buffer, item, "use", block_indent)
    dump_use(buffer, item, "updef", block_indent)
    dump_use(buffer, item, "upuse", block_indent)
  end)

  return buffer
end

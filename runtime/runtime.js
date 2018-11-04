// Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
//
// This file is part of dromozoa-compiler.
//
// dromozoa-compiler is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// dromozoa-compiler is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// Under Section 7 of GPL version 3, you are granted additional
// permissions described in the GCC Runtime Library Exception, version
// 3.1, as published by the Free Software Foundation.
//
// You should have received a copy of the GNU General Public License
// and a copy of the GCC Runtime Library Exception along with
// dromozoa-compiler.  If not, see <http://www.gnu.org/licenses/>.

const METATABLE = Symbol("metatabale");

const decint_pattern = /^\s*([+-]?\d+)\s*$/;
const hexint_pattern = /^\s*([+-]?0[xX][0-9A-Fa-f]+)\s*$/;
const decflt_pattern = /^\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)\s*$/;

const string_buffers = new Map();
const string_metatable = new Map();

class logic_error {
  constructor(message) {
    this.message = message;
  }
}

class runtime_error {
  constructor(message) {
    this.message = message;
  }
}

const string_buffer = s => {
  let buffer = string_buffers.get(s);
  if (buffer !== undefined) {
    string_buffers.delete(s);
  } else {
    if (typeof TextEncoder !== "undefined") {
      buffer = new TextEncoder().encode(s);
    } else if (typeof Buffer !== "undefined") {
      buffer = Buffer.from(s);
    } else {
      throw new runtime_error("no UTF-8 encoder");
    }
  }
  string_buffers.set(s, buffer);
  if (string_buffers.size > 16) {
    for (const entry of string_buffers) {
      string_buffers.delete(entry[0]);
      break;
    }
  }
  return buffer;
};

const is_nil = (value) => {
  return value === undefined;
};

const is_boolean = (value) => {
  return typeof value === "boolean";
};

const is_number = (value) => {
  return typeof value === "number";
};

const is_string = (value) => {
  return typeof value === "string" || String.prototype.isPrototypeOf(value);
};

const is_table = (value) => {
  return Map.prototype.isPrototypeOf(value);
};

const is_function = (value) => {
  return typeof value === "function";
};

const type = value => {
  if (is_nil(value)) {
    return "nil";
  } else if (is_boolean(value)) {
    return "boolean";
  } else if (is_number(value)) {
    return "number";
  } else if (is_string(value)) {
    return "string";
  } else if (is_table(value)) {
    return "table";
  } else if (is_function(value)) {
    return "function";
  }
  throw new logic_error("unreachable code");
};

const toboolean = (v) => {
  if (is_nil(v)) {
    return false;
  } else if (is_boolean(v)) {
    return v;
  }
  return true;
};

const tonumber = v => {
  if (is_number(v)) {
    return v;
  } else if (is_string(v)) {
    let match;
    if ((match = decint_pattern.exec(v))) {
      return parseInt(match[0], 10);
    }
    if ((match = hexint_pattern.exec(v))) {
      return parseInt(match[0], 16);
    }
    if ((match = decflt_pattern.exec(v))) {
      return parseFloat(match[0]);
    }
  }
};


const checknumber = (v) => {
  const result = tonumber(v);
  if (is_number(result)) {
    return result;
  }
  throw new runtime_error("number expected, got " + type(v));
};

const checkinteger = (v) => {
  const result = checknumber(v);
  if (Number.isInteger(result)) {
    return result;
  }
  throw new runtime_error("number has no integer representation");
};

const checkstring = (v) => {
  if (is_string(v)) {
    return v;
  } else if (is_number(v)) {
    return v.toString();
  }
  throw new runtime_error("string expected, got " + type(v));
};

const checktable = (v) => {
  if (is_table(v)) {
    return v;
  }
  throw new runtime_error("table expected, got " + type(v));
};

const optinteger = (v, d) => {
  if (is_nil(v)) {
    return d;
  } else {
    return checkinteger(v);
  }
};

const rawget = (table, index) => {
  return checktable(table).get(index);
};

const rawset = (table, index, value) => {
  if (is_nil(index)) {
    throw new runtime_error("table index is nil");
  }
  if (is_nil(value)) {
    checktable(table).delete(index);
  } else {
    checktable(table).set(index, value);
  }
};

const getmetafield = (object, event) => {
  let metatable;
  if (is_string(object)) {
    metatable = string_metatable;
  } else if (is_table(object)) {
    metatable = object[METATABLE];
  }
  if (is_table(metatable)) {
    return rawget(metatable, event);
  }
};

const call0 = (f, ...args) => {
  if (is_function(f)) {
    f(...args);
  } else {
    const field = getmetafield(f, "__call");
    if (is_function(field)) {
      field(f, ...args);
    } else {
      throw new runtime_error("attempt to call a " + type(f) + " value");
    }
  }
};

const call1 = (f, ...args) => {
  let result;
  if (is_function(f)) {
    result = f(...args);
  } else {
    const field = getmetafield(f, "__call");
    if (is_function(field)) {
      result = field(f, ...args);
    } else {
      throw new runtime_error("attempt to call a " + type(f) + " value");
    }
  }
  if (Array.prototype.isPrototypeOf(result)) {
    return result[0];
  } else {
    return result;
  }
};

const call = (f, ...args) => {
  let result;
  if (is_function(f)) {
    result = f(...args);
  } else {
    const field = getmetafield(f, "__call");
    if (is_function(field)) {
      result = field(f, ...args);
    } else {
      throw new runtime_error("attempt to call a " + type(f) + " value");
    }
  }
  if (Array.prototype.isPrototypeOf(result)) {
    return result;
  } else {
    return [ result ];
  }
};

const getmetatable = object => {
  if (is_string(object)) {
    return string_metatable;
  } else if (is_table(object)) {
    const metatable = object[METATABLE];
    if (is_table(metatable)) {
      const protected_metatable = rawget(metatable, "__metatable");
      if (!is_nil(protected_metatable)) {
        return protected_metatable;
      }
    }
    return metatable;
  }
};

const setmetatable = (table, metatable) => {
  if (!is_nil(metatable) && !is_table(metatable)) {
    throw new runtime_error("nil or table expected");
  }
  if (!is_nil(getmetafield(table, "__metatable"))) {
    throw new runtime_error("cannot change a protected metatable");
  }
  checktable(table)[METATABLE] = metatable;
  return table;
};

const gettable = (table, index) => {
  if (is_string(table)) {
    const field = getmetafield(table, "__index");
    if (!is_nil(field)) {
      if (is_function(field)) {
        return call1(field, table, index);
      } else {
        return gettable(field, index);
      }
    }
  }
  const result = rawget(table, index);
  if (is_nil(result)) {
    const field = getmetafield(table, "__index");
    if (!is_nil(field)) {
      if (is_function(field)) {
        return call1(field, table, index);
      } else {
        return gettable(field, index);
      }
    }
  }
  return result;
};

const settable = (table, index, value) => {
  const result = rawget(table, index);
  if (is_nil(result)) {
    const field = getmetafield(table, "__newindex");
    if (!is_nil(field)) {
      if (is_function(field)) {
        return call0(field, table, index, value);
      } else {
        return settable(field, index, value);
      }
    }
  }
  rawset(table, index, value);
};

const setlist = (table, index, ...args) => {
  for (let i = 0; i < args.length; ++i) {
    rawset(table, index++, args[i]);
  }
};

const tostring = v => {
  if (is_nil(v)) {
    return "nil";
  } else if (is_boolean(v)) {
    if (v) {
      return "true";
    } else {
      return "false";
    }
  } else if (is_number(v)) {
    return v.toString();
  } else if (is_string(v)) {
    return v;
  } else if (is_table(v)) {
    const field = getmetafield(v, "__tostring");
    if (!is_nil(field)) {
      return call1(field, v);
    } else {
      return "table";
    }
  } else if (is_function(v)) {
    return "function";
  }
  throw logic_error("unreachable code");
};

const len = v => {
  if (is_string(v)) {
    return string_buffer(v).byteLength;
  } else if (is_table(v)) {
    const field = getmetafield(v, "__len");
    if (!is_nil(field)) {
      return call1(field, v);
    }
    for (let i = 1; ; ++i) {
      if (is_nil(gettable(v, i))) {
        return i - 1;
      }
    }
  }
  throw new runtime_error("attempt to get length of a " + type(v) + " value");
};

const eq = (self, that) => {
  if (self === that) {
    return true;
  }
  if (is_table(self) && is_table(that)) {
    let field = getmetafield(self, "__eq");
    if (is_nil(field)) {
      field = getmetafield(that, "__eq");
    }
    if (!is_nil(field)) {
      return toboolean(call1(field, self, that));
    }
  }
  return false;
};

const lt = (self, that) => {
  if (is_number(self) && is_number(that)) {
    return self < that;
  } else if (is_string(self) && is_string(that)) {
    return self < that;
  } else {
    let field = getmetafield(self, "__lt");
    if (is_nil(field)) {
      field = getmetafield(self, "__lt");
    }
    if (!is_nil(field)) {
      return toboolean(call1(field, self, that));
    }
  }
  throw new runtime_error("attempt to compare " + type(self) + " with " + type(that));
};

const le = (self, that) => {
  if (is_number(self) && is_number(that)) {
    return self <= that;
  } else if (is_string(self) && is_string(that)) {
    return self <= that;
  } else {
    let field = getmetafield(self, "__le");
    if (is_nil(field)) {
      field = getmetafield(self, "__le");
    }
    if (!is_nil(field)) {
      return toboolean(call1(field, self, that));
    }
    field = getmetafield(that, "__lt");
    if (is_nil(field)) {
      field = getmetafield(self, "__lt");
    }
    if (!is_nil(field)) {
      return !toboolean(call1(field, that, self));
    }
  }
  throw new runtime_error("attempt to compare " + type(self) + " with " + type(that));
};

const range_i = (i, size) => {
  if (i < 0) {
    i += size;
    if (i < 0) {
      return 0;
    } else {
      return i;
    }
  } else if (i > 0) {
    return i - 1;
  } else {
    return 0;
  }
};

const range_j = (j, size) => {
  if (j < 0) {
    j += size + 1;
    if (j < 0) {
      return 0;
    } else {
      return j;
    }
  } else if (j > size) {
    return size;
  } else {
    return j;
  }
};

const suppress_no_unsed = () => {};
suppress_no_unsed(len);
suppress_no_unsed(setlist);
suppress_no_unsed(lt);
suppress_no_unsed(le);

const open_base = env => {
  const ipairs_iterator = (table, index) => {
    index = checkinteger(index) + 1;
    const value = gettable(table, index);
    if (!is_nil(value)) {
      return [ index, value ];
    }
  };

  settable(env, "_G", env);

  settable(env, "_VERSION", "Lua 5.3");

  settable(env, "assert", (...args) => {
    const value = args[0];
    if (toboolean(value)) {
      return args;
    } else {
      if (args.length > 1) {
        throw new runtime_error(args[1]);
      } else {
        throw new runtime_error("assertion failed!");
      }
    }
  });

  settable(env, "error", message => {
    throw new runtime_error(message);
  });

  settable(env, "getmetatable", getmetatable);

  settable(env, "ipairs", table => {
    return [ ipairs_iterator, table, 0 ];
  });

  settable(env, "pcall", (f, ...args) => {
    try {
      const result = call(f, ...args);
      return [ true, ...result ];
    } catch (e) {
      if (runtime_error.prototype.isPrototypeOf(e)) {
        return [ false, e.message ];
      } else {
        throw e;
      }
    }
  });

  settable(env, "print", (...args) => {
    if (typeof process !== "undefined") {
      for (let i = 0; i < args.length; ++i) {
        if (i > 0) {
          process.stdout.write("\t");
        }
        process.stdout.write(tostring(args[i]));
      }
      process.stdout.write("\n");
    } else {
      console.log(...args);
    }
  });

  settable(env, "select", (index, ...args) => {
    if (eq(index, "#")) {
      return args.length;
    }
    const min = range_i(checkinteger(index), args.length);
    const result = [];
    for (let i = min; i < args.length; ++i) {
      result.push(args[i]);
    }
    return result;
  });

  settable(env, "setmetatable", setmetatable);

  settable(env, "tonumber", tonumber);

  settable(env, "tostring", tostring);

  settable(env, "type", type);
};

const open_string = env => {
  const module = new Map();

  settable(module, "byte", (s, i, j) => {
    const buffer = string_buffer(s);
    const index = optinteger(i, 1);
    const min = range_i(index, buffer.byteLength);
    const max = range_j(optinteger(j, index), buffer.byteLength);
    const result = [];
    for (let i = min; i < max; ++i) {
      result.push(buffer[i]);
    }
    return result;
  });

  settable(module, "char", (...args) => {
    if (typeof TextDecoder !== "undefined") {
      return new TextDecoder().decode(new Uint8Array(args));
    } else if (typeof Buffer !== "undefined") {
      return Buffer.from(args).toString();
    } else {
      throw new runtime_error("no UTF-8 decoder");
    }
  });

  settable(module, "len", s => {
    return string_buffer(s).byteLength;
  });

  settable(module, "sub", (s, i, j) => {
    const buffer = string_buffer(checkstring(s));
    const min = range_i(optinteger(i, 1), buffer.byteLength);
    const max = range_j(optinteger(j, buffer.byteLength), buffer.byteLength);
    if (min < max) {
      if (typeof TextDecoder !== "undefined") {
        return new TextDecoder().decode(buffer.slice(min, max));
      } else if (typeof Buffer !== "undefined") {
        return buffer.slice(min, max).toString();
      } else {
        throw new runtime_error("no UTF-8 decoder");
      }
    } else {
      return "";
    }
  });

  settable(env, "string", module);
  string_metatable.set("__index", module);
};

const env = new Map();
open_base(env);
open_string(env);

return [[
const METATABLE = Symbol("metatabale");
const TEST = true;

const string_buffers = new Map();
const string_metatable = new Map();

class logic_error {
  constructor(message) {
    this.message = message;
  }
};

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

const is_nil = (self) => {
  return self === undefined;
};

const is_boolean = (self) => {
  return typeof self === "boolean";
};

const is_number = (self) => {
  return typeof self === "number";
};

const is_string = (self) => {
  return typeof self === "string" || String.prototype.isPrototypeOf(self);
};

const is_table = (self) => {
  return Map.prototype.isPrototypeOf(self);
};

const is_function = (self) => {
  return typeof self === "function";
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
  } else {
    throw new logic_error("unreachable code");
  }
};

const checktable = (self) => {
  if (is_table(self)) {
    return self;
  }
  throw new runtime_error("table expected, got " + type(self));
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

const call0 = (self, ...args) => {
  if (is_function(self)) {
    self(...args);
  } else {
    const field = getmetafield(self, "__call");
    if (is_function(field)) {
      field(self, ...args);
    } else {
      throw new runtime_error("attempt to call a " + type(f) + " value");
    }
  }
};

const call1 = (self, ...args) => {
  let result;
  if (is_function(self)) {
    result = self(...args);
  } else {
    const field = getmetafield(self, "__call");
    if (is_function(field)) {
      result = field(self, ...args);
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

const call = (self, ...args) => {
  let result;
  if (is_function(self)) {
    result = self(...args);
  } else {
    const field = getmetafield(self, "__call");
    if (is_function(field)) {
      result = field(self, ...args);
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

const len = value => {
  if (is_string(value)) {
    return string_buffer(value).byteLength;
  } else if (is_table(value)) {
    const field = getmetafield(value, "__len");
    if (!is_nil(field)) {
      return call1(field, value);
    }
    for (let i = 1; ; ++i) {
      if (is_nil(gettable(value, i))) {
        return i - 1;
      }
    }
  }
  throw new runtime_error("attempt to get length of a " + type(value) + " value");
};

const setlist = (table, index, ...args) => {
  for (let i = 0; i < args.length; ++i) {
    rawset(table, index++, args[i]);
  }
};

const decint_pattern = /^\s*([+-]?\d+)\s*$/;
const hexint_pattern = /^\s*([+-]?0[xX][0-9A-Fa-f]+)\s*$/;
const decflt_pattern = /^\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)\s*$/;

const tonumber = value => {
  const t = typeof value;
  if (t == "number") {
    return value;
  } else if (t == "string" || String.prototype.isPrototypeOf(value)) {
    let match = decint_pattern.exec(value);
    if (match) {
      return parseInt(match[0], 10);
    }
    match = hexint_pattern.exec(value);
    if (match) {
      return parseInt(match[0], 16);
    }
    match = decflt_pattern.exec(value);
    if (match) {
      return parseFloat(match[0]);
    }
  }
};

const tointeger = value => {
  const result = tonumber(value);
  if (Number.isInteger(result)) {
    return result;
  }
};

const tostring = value => {
  const t = typeof value;
  if (t === "undefined") {
    return "nil";
  } else if (t === "number") {
    return value.toString();
  } else if (t === "string" || String.prototype.isPrototypeOf(value)) {
    return value;
  } else if (t === "boolean") {
    if (value) {
      return "true";
    } else {
      return "false";
    }
  } else if (t === "function") {
    return "function";
  } else if (Map.prototype.isPrototypeOf(value)) {
    const field = getmetafield(value, "__tostring");
    if (field !== undefined) {
      return call1(field, value);
    } else {
      return "table";
    }
  } else {
    return "userdata";
  }
};

const suppress_no_unsed = () => {};
suppress_no_unsed(len);
suppress_no_unsed(setlist);

const open_base = env => {
  const ipairs_iterator = (table, index) => {
    ++index;
    const value = gettable(table, index);
    if (value !== undefined) {
      return [index, value];
    }
  };

  env.set("_G", env);

  env.set("_VERSION", "Lua 5.3");

  env.set("assert", (...args) => {
    const value = args[0];
    if (value === undefined || value === false) {
      if (args.length > 1) {
        throw new runtime_error(args[1]);
      } else {
        throw new runtime_error("assertion failed!");
      }
    }
    return args;
  });

  env.set("error", message => {
    throw new runtime_error(message);
  });

  env.set("getmetatable", object => {
    if (typeof object === "string" || String.prototype.isPrototypeOf(object)) {
      return string_metatable;
    }
    const metatable = object[METATABLE];
    if (metatable !== undefined) {
      if (metatable.has("__metatable")) {
        return metatable.get("__metatable");
      }
    }
    return metatable;
  });

  env.set("ipairs", table => {
    return [ipairs_iterator, table, 0];
  });

  env.set("pcall", (f, ...args) => {
    try {
      const result = call(f, ...args);
      return [true, ...result];
    } catch (e) {
      if (runtime_error.prototype.isPrototypeOf(e)) {
        return [false, e.message];
      } else {
        throw e;
      }
    }
  });

  env.set("print", (...args) => {
    if (typeof process !== "undefined") {
      for (let i = 0; i < args.length; ++i) {
        if (i > 0) {
          process.stdout.write("\t");
        }
        // convert String object to string
        process.stdout.write(tostring(args[i]).toString());
      }
      process.stdout.write("\n");
    } else {
      console.log(...args);
    }
  });

  env.set("select", (index, ...args) => {
    if (index === "#") {
      return args.length;
    }
    index = tointeger(index);
    if (index === undefined) {
      throw new runtime_error("bad argument #1");
    }
    if (index < 0) {
      index += args.length;
    } else {
      --index;
    }
    const result = [];
    for (let i = index; i < args.length; ++i) {
      result.push(args[i]);
    }
    return result;
  });

  env.set("setmetatable", (table, metatable) => {
    if (!Map.prototype.isPrototypeOf(table)) {
      throw new runtime_error("bad argument #1");
    }
    if (metatable !== undefined && !Map.prototype.isPrototypeOf(metatable)) {
      throw new runtime_error("nil or table expected");
    }
    if (getmetafield(table, "__metatable") !== undefined) {
      throw new runtime_error("cannot change a protected metatable");
    }
    table[METATABLE] = metatable;
    return table;
  });

  env.set("tonumber", tonumber);

  env.set("tostring", tostring);

  env.set("type", type);
};

const open_string = env => {
  const module = new Map();

  const range_i = (buffer, arg, i) => {
    if (i === undefined) {
      return 0;
    } else {
      i = tointeger(i);
      if (i === undefined) {
        throw new runtime_error("bad argument #" + arg);
      }
    }
    if (i === 0) {
      return 0;
    } else if (i < 0) {
      i += buffer.byteLength;
      if (i < 0) {
        return 0;
      } else {
        return i;
      }
    } else {
      return i - 1;
    }
  };

  const range_j = (buffer, arg, j, d) => {
    if (j === undefined) {
      if (d === undefined) {
        return buffer.byteLength - 1;
      } else {
        j = d;
      }
    } else {
      j = tointeger(j);
      if (j === undefined) {
        throw new runtime_error("bad argument #" + arg);
      }
    }
    if (j < 0) {
      return j + buffer.byteLength;
    } else {
      if (j >= buffer.byteLength) {
        return buffer.byteLength - 1;
      } else {
        return j - 1;
      }
    }
  };

  module.set("byte", (s, i, j) => {
    const buffer = string_buffer(s);
    if (i === undefined) {
      i = 1;
    }
    const min = range_i(buffer, 2, i);
    const max = range_j(buffer, 3, j, i);
    const result = [];
    for (let i = min; i <= max; ++i) {
      result.push(buffer[i]);
    }
    return result;
  });

  module.set("char", (...args) => {
    if (typeof TextDecoder !== "undefined") {
      return new TextDecoder().decode(new Uint8Array(args));
    } else if (typeof Buffer !== "undefined") {
      return Buffer.from(args).toString();
    } else {
      throw new runtime_error("no UTF-8 decoder");
    }
  });

  module.set("len", s => {
    return string_buffer(s).byteLength;
  });

  module.set("sub", (s, i, j) => {
    const buffer = string_buffer(s);
    if (i === undefined) {
      i = 1;
    }
    const min = range_i(buffer, 2, i);
    const max = range_j(buffer, 3, j);
    if (min > max) {
      return "";
    }
    if (typeof TextDecoder !== "undefined") {
      return new TextDecoder().decode(buffer.slice(min, max + 1));
    } else if (typeof Buffer !== "undefined") {
      return buffer.slice(min, max + 1).toString();
    } else {
      throw new runtime_error("no UTF-8 decoder");
    }
  });

  env.set("string", module);
  string_metatable.set("__index", module);
};

const env = new Map();
open_base(env);
open_string(env);
]]

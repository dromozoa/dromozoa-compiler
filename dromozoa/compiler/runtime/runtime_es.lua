return [[
class logic_error {
  constructor(message) {
    this.message = message;
  }
}

class runtime_error {
  constructor(message) {
    this.message = wrap(message);
  }
}

let make_buffer;
let string_to_buffer;
let buffer_to_string;

if (typeof Buffer !== "undefined") {
  make_buffer = size => {
    return Buffer.alloc(size);
  };

  string_to_buffer = string => {
    return Buffer.from(string);
  };

  buffer_to_string = buffer => {
    return buffer.toString();
  };
} else {
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();

  make_buffer = size => {
    return new Uint8Array(size);
  };

  string_to_buffer = string => {
    return encoder.encode(string);
  };

  buffer_to_string = buffer => {
    return decoder.decode(buffer);
  };
}

class string_t {
  constructor(string, buffer) {
    this.string_ = string;
    this.buffer_ = buffer;
  }

  get string() {
    return this.string_;
  }

  get buffer() {
    if (this.buffer_ === undefined) {
      this.buffer_ = string_to_buffer(this.string_);
    }
    return this.buffer_;
  }
}

class table_t {
  constructor() {
    this.map = new Map();
    this.index = new Map();
    this.metatable = undefined;
  }

  get(index) {
    if (is_string(index)) {
      return this.map.get(this.index.get(unwrap(index)));
    } else {
      return this.map.get(index);
    }
  }

  set(index, value) {
    if (is_nil(index)) {
      throw new runtime_error("table index is nil");
    } else if (is_string(index)) {
      if (is_nil(value)) {
        const string = unwrap(index);
        if (this.index.has(string)) {
          this.map.delete(this.index.get(string));
          this.index.delete(string);
        }
      } else {
        const string = unwrap(index);
        if (this.index.has(string)) {
          index = this.index.get(string);
        } else {
          index = wrap(index);
          this.index.set(string, index);
        }
        this.map.set(index, wrap(value));
      }
    } else {
      if (is_nil(value)) {
        this.map.delete(index);
      } else {
        this.map.set(index, wrap(value));
      }
    }
  }
}

const wrap = object => {
  if (typeof object === "string") {
    return new string_t(object);
  } else {
    return object;
  }
};

const unwrap = object => {
  if (string_t.prototype.isPrototypeOf(object)) {
    return object.string;
  } else {
    return object;
  }
};

const concat = (...args) => {
  const result = [];
  for (let i = 0; i < args.length; ++i) {
    result.push(unwrap(checkstring(args[i])));
  }
  return wrap(result.join(""));
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
  return typeof value === "string" || string_t.prototype.isPrototypeOf(value);
};

const is_table = (value) => {
  return table_t.prototype.isPrototypeOf(value);
};

const is_function = (value) => {
  return typeof value === "function";
};

const toboolean = (v) => {
  if (is_nil(v)) {
    return false;
  } else if (is_boolean(v)) {
    return v;
  }
  return true;
};

const decint_pattern = /^\s*([+-]?\d+)\s*$/;
const hexint_pattern = /^\s*([+-]?0[xX][0-9A-Fa-f]+)\s*$/;
const decflt_pattern = /^\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)\s*$/;

const tonumber = v => {
  if (is_number(v)) {
    return v;
  } else if (is_string(v)) {
    let match;
    if ((match = decint_pattern.exec(unwrap(v)))) {
      return parseInt(match[0], 10);
    }
    if ((match = hexint_pattern.exec(unwrap(v)))) {
      return parseInt(match[0], 16);
    }
    if ((match = decflt_pattern.exec(unwrap(v)))) {
      return parseFloat(match[0]);
    }
  }
};

const checknumber = (v) => {
  const result = tonumber(v);
  if (is_number(result)) {
    return result;
  }
  throw new runtime_error(concat("number expected, got ", type(v)));
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
    return wrap(v);
  } else if (is_number(v)) {
    return wrap(v.toString());
  }
  throw new runtime_error(concat("string expected, got ", type(v)));
};

const checktable = (v) => {
  if (is_table(v)) {
    return v;
  }
  throw new runtime_error(concat("table expected, got ", type(v)));
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
  checktable(table).set(index, value);
  return table;
};

const getmetafield = (object, event) => {
  let metatable;
  if (is_string(object)) {
    metatable = string_metatable;
  } else if (is_table(object)) {
    metatable = object.metatable;
  }
  if (is_table(metatable)) {
    return rawget(metatable, event);
  }
};

const getmetatable = object => {
  if (is_string(object)) {
    return string_metatable;
  } else if (is_table(object)) {
    const metatable = object.metatable;
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
  checktable(table).metatable = metatable;
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

const call = (f, ...args) => {
  let result;
  if (is_function(f)) {
    result = f(...args);
  } else {
    const field = getmetafield(f, "__call");
    if (is_function(field)) {
      result = field(f, ...args);
    } else {
      throw new runtime_error(concat("attempt to call a ", type(f), " value"));
    }
  }
  if (Array.prototype.isPrototypeOf(result)) {
    return result;
  } else {
    return [ result ];
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
      throw new runtime_error(concat("attempt to call a ", type(f), " value"));
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
      throw new runtime_error(concat("attempt to call a ", type(f), " value"));
    }
  }
  if (Array.prototype.isPrototypeOf(result)) {
    return result[0];
  } else {
    return result;
  }
};

const type = value => {
  if (is_nil(value)) {
    return wrap("nil");
  } else if (is_boolean(value)) {
    return wrap("boolean");
  } else if (is_number(value)) {
    return wrap("number");
  } else if (is_string(value)) {
    return wrap("string");
  } else if (is_table(value)) {
    return wrap("table");
  } else if (is_function(value)) {
    return wrap("function");
  } else {
    throw new logic_error("unreachable code");
  }
};

const tostring = v => {
  if (is_nil(v)) {
    return wrap("nil");
  } else if (is_boolean(v)) {
    if (v) {
      return wrap("true");
    } else {
      return wrap("false");
    }
  } else if (is_number(v)) {
    return wrap(v.toString());
  } else if (is_string(v)) {
    return wrap(v);
  } else if (is_table(v)) {
    const field = getmetafield(v, "__tostring");
    if (!is_nil(field)) {
      return checkstring(call1(field, v));
    } else {
      return wrap("table");
    }
  } else if (is_function(v)) {
    return wrap("function");
  } else {
    throw logic_error("unreachable code");
  }
};

const len = v => {
  if (is_string(v)) {
    return wrap(v).buffer.byteLength;
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
  throw new runtime_error(concat("attempt to get length of a ", type(v), " value"));
};

const eq = (self, that) => {
  if (self === that) {
    return true;
  }
  if (is_string(self) && is_string(that)) {
    return unwrap(self) === unwrap(that);
  } else if (is_table(self) && is_table(that)) {
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
    return unwrap(self) < unwrap(that);
  } else {
    let field = getmetafield(self, "__lt");
    if (is_nil(field)) {
      field = getmetafield(self, "__lt");
    }
    if (!is_nil(field)) {
      return toboolean(call1(field, self, that));
    }
  }
  throw new runtime_error(concat("attempt to compare ", type(self), " with ", type(that)));
};

const le = (self, that) => {
  if (is_number(self) && is_number(that)) {
    return self <= that;
  } else if (is_string(self) && is_string(that)) {
    return unwrap(self) <= unwrap(that);
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
  throw new runtime_error(concat("attempt to compare ", type(self), " with ", type(that)));
};

let print;
if (typeof process !== "undefined") {
  print = (...args) => {
    const result = [];
    for (let i = 0; i < args.length; ++i) {
      result.push(unwrap(tostring(args[i])));
    }
    process.stdout.write(result.join("\t"));
    process.stdout.write("\n");
  };
} else {
  print = (...args) => {
    const result = [];
    for (let i = 0; i < args.length; ++i) {
      result.push(unwrap(tostring(args[i])));
    }
    console.log(result.join("\t"));
  };
}

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
suppress_no_unsed(setlist);
suppress_no_unsed(len);
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

  settable(env, "print", print);

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

const open_string = (env, string_metatable) => {
  const module = new table_t();

  settable(module, "byte", (s, i, j) => {
    const buffer = checkstring(s).buffer;
    const index = optinteger(i, 1);
    const min = range_i(index, buffer.byteLength);
    const max = range_j(optinteger(j, index), buffer.byteLength);
    if (min < max) {
      const result = [];
      for (let i = min; i < max; ++i) {
        result.push(buffer[i]);
      }
      return result;
    } else {
      return [];
    }
  });

  settable(module, "char", (...args) => {
    const buffer = make_buffer(args.length);
    for (let i = 0; i < buffer.byteLength; ++i) {
      buffer[i] = args[i];
    }
    return new string_t(buffer_to_string(buffer), buffer);
  });

  settable(module, "len", s => {
    return checkstring(s).buffer.byteLength;
  });

  settable(module, "sub", (s, i, j) => {
    let buffer = checkstring(s).buffer;
    const min = range_i(optinteger(i, 1), buffer.byteLength);
    const max = range_j(optinteger(j, buffer.byteLength), buffer.byteLength);
    if (min < max) {
      buffer = buffer.slice(min, max);
      return new string_t(buffer_to_string(buffer), buffer);
    } else {
      return wrap("");
    }
  });

  settable(env, "string", module);
  settable(string_metatable, "__index", module);
};

const string_metatable = new table_t();
const env = new table_t();
open_base(env);
open_string(env, string_metatable);
]]

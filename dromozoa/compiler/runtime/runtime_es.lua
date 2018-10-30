return [[
const METATABLE = Symbol("metatabale");

class Error {
  constructor(message) {
    this.message = message;
  }
}

const type = value => {
  const t = typeof value;
  if (t === "undefined") {
    return "nil";
  } else if (t === "number") {
    return "number";
  } else if (t === "string") {
    return "string";
  } else if (t === "boolean") {
    return "boolean";
  } else if (t === "function") {
    return "function";
  } else if (Map.prototype.isPrototypeOf(value)) {
    return "table";
  } else {
    return "userdata";
  }
};

const getmetafield = (object, event) => {
  const metatable = object[METATABLE];
  if (metatable !== undefined) {
    return metatable.get(event);
  }
};

const call0 = (f, ...args) => {
  if (typeof f === "function") {
    f(...args);
  } else {
    const field = getmetafield(f, "__call");
    if (typeof field == "function") {
      field(f, ...args);
    } else {
      throw new Error("attempt to call a " + type(f) + " value");
    }
  }
};

const call1 = (f, ...args) => {
  let result;
  if (typeof f === "function") {
    result = f(...args);
  } else {
    const field = getmetafield(f, "__call");
    if (typeof field == "function") {
      result = field(f, ...args);
    } else {
      throw new Error("attempt to call a " + type(f) + " value");
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
  if (typeof f === "function") {
    result = f(...args);
  } else {
    const field = getmetafield(f, "__call");
    if (typeof field == "function") {
      result = field(f, ...args);
    } else {
      throw new Error("attempt to call a " + type(f) + " value");
    }
  }
  if (Array.prototype.isPrototypeOf(result)) {
    return result;
  } else {
    return [result];
  }
};

const gettable = (table, index) => {
  if (!Map.prototype.isPrototypeOf(table)) {
    throw new Error("attempt to index a " + type(table) + " value");
  }
  const result = table.get(index);
  if (result === undefined) {
    const field = getmetafield(table, "__index");
    if (field !== undefined) {
      if (typeof field === "function") {
        return call1(field, table, index);
      } else {
        return gettable(field, index);
      }
    }
  }
  return result;
};

const settable = (table, index, value) => {
  if (!Map.prototype.isPrototypeOf(table)) {
    throw new Error("attempt to index a " + type(table) + " value");
  }
  if (index === undefined) {
    throw new Error("table index is nil");
  }
  const result = table.get(index);
  if (result === undefined) {
    const field = getmetafield(table, "__newindex");
    if (field !== undefined) {
      if (typeof field === "function") {
        return call0(field, table, index, value);
      } else {
        return settable(field, index, value);
      }
    }
  }
  if (value === undefined) {
    table.delete(index);
  } else {
    table.set(index, value);
  }
};

const len = value => {
  if (typeof value === "string") {
    throw new Error("not implemented");
  } else if (Map.prototype.isPrototypeOf(value)) {
    const field = getmetafield(value, "__len");
    if (field !== undefined) {
      return call1(field, value);
    }
    for (let i = 1; ; ++i) {
      if (value.get(i) === undefined) {
        return i - 1;
      }
    }
  } else {
    throw new Error("attempt to get index of a " + type(value) + " value");
  }
};

const setlist = (table, index, ...args) => {
  for (let i = 0; i < args.length; ++i) {
    const value = args[i];
    if (value !== undefined) {
      table.set(index + i, args[i]);
    }
  }
};

const decint_pattern = /^\s*([+-]?\d+)\s*$/;
const hexint_pattern = /^\s*([+-]?0[xX][0-9A-Fa-f]+)\s*$/;
const decflt_pattern = /^\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)\s*$/;

const tonumber = value => {
  const t = typeof value;
  if (t == "number") {
    return value;
  } else if (t == "string") {
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
  } else if (t === "string") {
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

const open_env = () => {
  const ipairs_iterator = (table, index) => {
    ++index;
    const value = gettable(table, index);
    if (value !== undefined) {
      return [index, value];
    }
  };

  const env = new Map();

  env.set("_G", env);
  env.set("_VERSION", "Lua 5.3");

  env.set("assert", (...args) => {
    const value = args[0];
    if (value === undefined || value === false) {
      if (args.length > 1) {
        throw new Error(args[1]);
      } else {
        throw new Error("assertion failed!");
      }
    }
    return args;
  });

  env.set("error", message => {
    throw new Error(message);
  });

  env.set("getmetatable", object => {
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
      if (Error.prototype.isPrototypeOf(e)) {
        return [false, e.message];
      } else {
        throw e;
      }
    }
  });

  env.set("print", (...args) => {
    for (let i = 0; i < args.length; ++i) {
      if (i > 0) {
        process.stdout.write("\t");
      }
      process.stdout.write(tostring(args[i]));
    }
    process.stdout.write("\n");
  });

  env.set("select", (index, ...args) => {
    if (index === "#") {
      return args.length;
    }
    index = tointeger(index);
    if (index === undefined) {
      throw new Error("bad argument #1");
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
      throw new Error("bad argument #1");
    }
    if (metatable !== undefined && !Map.prototype.isPrototypeOf(metatable)) {
      throw new Error("nil or table expected");
    }
    if (getmetafield(table, "__metatable") !== undefined) {
      throw new Error("cannot change a protected metatable");
    }
    table[METATABLE] = metatable;
    return table;
  });

  env.set("tonumber", tonumber);

  env.set("tostring", tostring);

  env.set("type", type);

  return env;
};
]]

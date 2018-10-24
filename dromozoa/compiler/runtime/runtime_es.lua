return [[
const metatable_key = Symbol("metatabale");

const getmetafield = (object, event) => {
  const metatable = object[metatable_key];
  if (metatable !== undefined) {
    return metatable.get(event);
  }
};

const CALL0 = (f, ...args) => {
  if (typeof f === "function") {
    f(...args);
  } else {
    getmetafield(f, "__call")(f, ...args);
  }
};

const CALL1 = (f, ...args) => {
  let result;
  if (typeof f === "function") {
    result = f(...args);
  } else {
    result = getmetafield(f, "__call")(f, ...args);
  }
  if (Array.prototype.isPrototypeOf(result)) {
    return result[0];
  } else {
    return result;
  }
};

const CALL = (f, ...args) => {
  let result;
  if (typeof f === "function") {
    result = f(...args);
  } else {
    result = getmetafield(f, "__call")(f, ...args);
  }
  if (Array.prototype.isPrototypeOf(result)) {
    return result;
  } else {
    return [result];
  }
};

const GETTABLE = (table, index) => {
  const result = table.get(index);
  if (result === undefined) {
    const field = getmetafield(table, "__index");
    if (field !== undefined) {
      if (typeof field === "function") {
        return CALL1(field, table, index);
      } else {
        return GETTABLE(field, index);
      }
    }
  }
  return result;
};

const SETTABLE = (table, index, value) => {
  const result = table.get(index);
  if (result === undefined) {
    const field = getmetafield(table, "__newindex");
    if (field !== undefined) {
      if (typeof field === "function") {
        return CALL0(field, table, index, value);
      } else {
        return SETTABLE(field, index, value);
      }
    }
  }
  if (value === undefined) {
    table.delete(index);
  } else {
    table.set(index, value);
  }
};

const LEN = value => {
  if (Map.prototype.isPrototypeOf(value)) {
    const field = getmetafield(value, "__len");
    if (field !== undefined) {
      return CALL1(field, value);
    }
    for (let i = 1; ; ++i) {
      if (value.get(i) === undefined) {
        return i - 1;
      }
    }
  }
};

const SETLIST = (table, index, ...args) => {
  for (let i = 0; i < args.length; ++i) {
    table.set(index + i, args[i]);
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
      return CALL1(field, value);
    } else {
      return "table";
    }
  }
  return "userdata";
};

const open_env = () => {
  class Error {
    constructor(message) {
      this.message = message;
    }
  }

  const env = new Map();

  env.set("_G", env);
  env.set("_VERSION", "Lua 5.3");
  env.set("tostring", tostring);

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
    const metatable = object[metatable_key];
    if (metatable !== undefined) {
      if (metatable.has("__metatable")) {
        return metatable.get("__metatable");
      }
    }
    return metatable;
  });

  // ipairs
  // next
  // pairs

  env.set("pcall", (f, ...args) => {
    try {
      const result = CALL(f, ...args);
      return [true, ...result];
    } catch (e) {
      if (Error.prototype.isPrototypeOf(e)) {
        return [false, e.message];
      }
      throw e;
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

  // select

  env.set("setmetatable", function (table, metatable) {
    if (getmetafield(table, "__metatable") !== undefined) {
      throw new Error("cannot change a protected metatable");
    }
    table[metatable_key] = metatable;
    return table;
  });

  // tonumber

  env.set("type", value => {
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
    }
    return "userdata";
  });

  return env;
};
]]

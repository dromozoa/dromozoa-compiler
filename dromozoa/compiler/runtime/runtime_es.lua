return [[
class Error {
  constructor(message) {
    this.message = message;
  }
};

const metatable_key = Symbol("metatabale");

const getmetatable = function (table) {
  const metatable = table[metatable_key];
  if (metatable !== undefined) {
    if (metatable.has("__metatable")) {
      return metatable.get("__metatable");
    }
  }
  return metatable;
};

const getmetafield = function (table, index) {
  const metatable = table[metatable_key];
  if (metatable !== undefined) {
    return metatable.get(index);
  }
}

const setmetatable = function (table, metatable) {
  if (getmetafield(table, "__metatable") !== undefined) {
    throw new Error("cannot change a protected metatable");
  }
  table[metatable_key] = metatable;
};

const CALL0 = function (f, ...args) {
  if (typeof f !== "function") {
    f = getmetafield(f, "__call");
  }
  f(...args);
};

const CALL1 = function (f, ...args) {
  if (typeof f !== "function") {
    f = getmetafield(f, "__call");
  }
  const result = f(...args);
  if (typeof result === "object" && Array.prototype.isPrototypeOf(result)) {
    return result[0];
  } else {
    return result;
  }
};

const CALL = function (f, ...args) {
  if (typeof f !== "function") {
    f = getmetafield(f, "__call");
  }
  const result = f(...args);
  if (typeof result === "object" && Array.prototype.isPrototypeOf(result)) {
    return result;
  } else {
    return [result];
  }
};

const tostring = function (v) {
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
      const field = getmetafield(v);
      if (field !== undefined) {
        return CALL1(field, v);
      } else {
        return "table";
      }
    }
  } else if (t === "function") {
    return "function";
  }
  return "userdata";
};

const GETTABLE = function (table, index) {
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

const SETTABLE = function (table, index, value) {
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

const LEN = function (v) {
  const t = typeof v;
  if (t === "object") {
    if (Map.prototype.isPrototypeOf(v)) {
      const field = getmetafield(v, "__len");
      if (field !== undefined) {
        return CALL1(field, v);
      }
      for (let i = 1; ; ++i) {
        if (v.get(i) === undefined) {
          return i - 1;
        }
      }
    }
  }
};

const SETLIST = function (table, index, ...args) {
  for (let i = 0; i < args.length; ++i) {
    table.set(index + i, args[i]);
  }
}

const open_env = function () {
  const env = new Map();

  env.set("tostring", tostring);
  env.set("getmetatable", getmetatable);
  env.set("setmetatable", setmetatable);

  env.set("type", function (v) {
    const t = typeof v;
    if (t === "undefined") {
      return "nil";
    } else if (t === "number") {
      return "number"
    } else if (t === "string") {
      return "string"
    } else if (t === "boolean") {
      return "boolean"
    } else if (t === "object") {
      if (Map.prototype.isPrototypeOf(v)) {
        return "table";
      }
    } else if (t === "function") {
      return "function";
    }
    return "userdata";
  });

  env.set("print", function (...args) {
    for (let i = 0; i < args.length; ++i) {
      if (i > 0) {
        process.stdout.write("\t");
      }
      process.stdout.write(tostring(args[i]));
    }
    process.stdout.write("\n");
  });

  env.set("assert", function (...args) {
    const v = args[0];
    if (v === undefined || v === false) {
      if (args.length > 1) {
        throw new Error(args[1]);
      } else {
        throw new Error("assertion failed");
      }
    }
    return args;
  });

  return env;
};
]]

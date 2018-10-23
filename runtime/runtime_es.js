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

const CALL0 = function (f, ...args) {
  f(...args);
};

const CALL1 = function (f, ...args) {
  const result = f(...args);
  if (typeof result === "object" && Array.prototype.isPrototypeOf(result)) {
    return result[0];
  } else {
    return result;
  }
};

const CALL = function (f, ...args) {
  const result = f(...args);
  if (typeof result === "object" && Array.prototype.isPrototypeOf(result)) {
    return result;
  } else {
    return [result];
  }
};

const GETTABLE = function (table, index) {
  return table.get(index);
};

const SETTABLE = function (table, index, value) {
  if (value === undefined) {
    table.delete(index);
  } else {
    table.set(index, value);
  }
};

const LEN = function (v) {
  if (typeof v === "object" && Map.prototype.isPrototypeOf(v)) {
    for (let i = 1; ; ++i) {
      if (v.get(i) === undefined) {
        return i - 1;
      }
    }
  }
};

const SETLIST = function (table, index, ...args) {
  for (let i = 0; i < args.length; ++i) {
    table.set(index + i, args[i]);
  }
}

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
      return "table";
    }
  } else if (t === "function") {
    return "function";
  }
  return "userdata";
};

const type = function (v) {
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
}

const open_env = function () {
  const env = new Map();

  env.set("tostring", tostring);
  env.set("type", type);

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
        throw args[1];
      } else {
        throw "assertion failed"
      }
    }
    return args;
  });

  return env;
};

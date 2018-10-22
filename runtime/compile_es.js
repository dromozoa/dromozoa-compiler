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

let runtime_env = function () {
  let tostring = function (v) {
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

  let env = new Map();

  env.set("print", function (...vararg) {
    for (let i = 0; i < vararg.length; ++i) {
      if (i > 0) {
        process.stdout.write("\t");
      }
      process.stdout.write(tostring(vararg[i]));
    }
    process.stdout.write("\n");
    return [];
  });

  env.set("assert", function (...vararg) {
    let v = vararg[0];
    if (v === undefined || v === false) {
      if (vararg.length > 1) {
        throw vararg[1];
      } else {
        throw "assertion failed"
      }
    }
    return vararg;
  });

  return env;
};

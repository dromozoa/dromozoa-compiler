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

local builder = require "dromozoa.parser.builder"

local RE = builder.regexp
local _ = builder()

local function string_lexer(lexer)
  return lexer
    :_ [[\a]] "\a" :push()
    :_ [[\b]] "\b" :push()
    :_ [[\f]] "\f" :push()
    :_ [[\n]] "\n" :push()
    :_ [[\r]] "\r" :push()
    :_ [[\t]] "\t" :push()
    :_ [[\v]] "\v" :push()
    :_ [[\\]] "\\" :push()
    :_ [[\"]] "\"" :push()
    :_ [[\']] "\'" :push()
    :_ (RE[[\\z\s*]]) :skip()
    :_ (RE[[\\(\r|\n|\r\n|\n\r)]]) "\n" :push()
    :_ (RE[[\\x[0-9A-Fa-f]{2}]]) :sub(3) :int(16) :char() :push()
    :_ (RE[[\\\d{1,3}]]) :sub(2) :int(10) :char() :push()
    :_ (RE[[\\u\{[0-9A-Fa-f]+\}]]) :utf8(4, -2) :push()
end

_:lexer()
  :_ (RE[[\s+]]) :skip()
  :_ "and"
  :_ "break"
  :_ "do"
  :_ "else"
  :_ "elseif"
  :_ "end"
  :_ "false"
  :_ "for"
  :_ "function"
  :_ "goto"
  :_ "if"
  :_ "in"
  :_ "local"
  :_ "nil"
  :_ "not"
  :_ "or"
  :_ "repeat"
  :_ "return"
  :_ "then"
  :_ "true"
  :_ "until"
  :_ "while"
  :_ "+"
  :_ "-"
  :_ "*"
  :_ "/"
  :_ "%"
  :_ "^"
  :_ "#"
  :_ "&"
  :_ "~"
  :_ "|"
  :_ "<<"
  :_ ">>"
  :_ "//"
  :_ "=="
  :_ "~="
  :_ "<="
  :_ ">="
  :_ "<"
  :_ ">"
  :_ "="
  :_ "("
  :_ ")"
  :_ "{"
  :_ "}"
  :_ "["
  :_ "]"
  :_ "::"
  :_ ";"
  :_ ":"
  :_ ","
  :_ "."
  :_ ".."
  :_ "..."
  :_ (RE[[[A-Za-z_]\w*]]) :as "Name"
  :_ [["]] :skip() :call "double_quoted_string" :mark()
  :_ [[']] :skip() :call "single_quoted_string" :mark()
  :_ (RE[[\[=*\[]]) :sub(2, -2) :join("]", "]") :hold() :skip() :call "long_string" :mark()
  :_ (RE[[\d+]]) :as "IntegerConstant"
  :_ (RE[[0[xX][0-9A-Fa-f]+]]) :as "IntegerConstant"
  :_ (RE[[(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?]]) :as "FloatConstant"
  :_ (RE[[0[xX]([0-9A-Fa-f]+(\.[0-9A-Fa-f]*)?|\.[0-9A-Fa-f]+)([pP][+-]?\d+)?]]) :as "FloatConstant"
  :_ ("--" * (RE[[[^\n\r]*]] - RE[[\[=*\[.*]]) * RE[[[\n\r]?]]) :skip()
  :_ (RE[[--\[=*\[]]) :sub(4, -2) :join("]", "]") :hold() :skip() :call "long_comment"

string_lexer(_:lexer "double_quoted_string")
  :_ (RE[[[^\\"]+]]) :push()
  :_ [["]] :as "LiteralString" :concat() :ret()

string_lexer(_:lexer "single_quoted_string")
  :_ (RE[[[^\\']+]]) :push()
  :_ [[']] :as "LiteralString" :concat() :ret()

_:search_lexer "long_string"
  :when() :as "LiteralString" :concat() :normalize_eol() :ret()
  :otherwise() :push()

_:search_lexer "long_comment"
  :when() :skip() :ret()
  :otherwise() :skip()

_ :left "or"
  :left "and"
  :left "<" ">" "<=" ">=" "~=" "=="
  :left "|"
  :left "~"
  :left "&"
  :left "<<" ">>"
  :right ".."
  :left "+" "-"
  :left "*" "/" "//" "%"
  :right "not" "#" "UNM" "BNOT"
  :right "^"

_"chunk"
  :_ "block"

_"block"
  :_ () {"statlist"}
  :_ "retstat" {"statlist",1}
  :_ "statlist"
  :_ "statlist" "retstat"

_"statlist"
  :_ "stat"
  :_ "statlist" "stat" {[1]={2}}

_"stat"
  :_ ";" {[1]={}}
  :_ "varlist" "=" "explist" {[2]={3,1}}
  :_ "functioncall" {[1]={}}
  :_ "label" {[1]={}}
  :_ "break"
  :_ "goto" "Name" {[1]={2}}
  :_ "do" "block" "end" {[1]={2}} :attr "scope"
  :_ "while" "exp" "do" "block" "end" {[1]={2,4}} :attr "scope"
  :_ "repeat" "block" "until" "exp" {[1]={2,4}} :attr "scope"
  :_ "conditional" "end" {[1]={}}
  :_ "for" "Name" "=" "exp" "," "exp" "do" "block" "end" {[1]={4,6,2,8}} :attr "scope" :attr(2, "declare")
  :_ "for" "Name" "=" "exp" "," "exp" "," "exp" "do" "block" "end" {[1]={4,6,8,2,10}} :attr "scope" :attr(2, "declare")
  :_ "for" "namelist" "in" "explist" "do" "block" "end" {[1]={4,2,6}} :attr "scope"
  :_ "function" "funcname_" "funcbody" {[1]={2,3}}
  :_ "local" "function" "Name" "funcbody" {[2]={3,4}} :attr(3, "declare")
  :_ "local" "namelist" {[1]={2}}
  :_ "local" "namelist" "=" "explist" {[1]={4,2}}

_"retstat"
  :_ "return" {[1]={}}
  :_ "return" ";" {[1]={}}
  :_ "return" "explist" {[1]={2}}
  :_ "return" "explist" ";" {[1]={2}}

_"label"
  :_ "::" "Name" "::" {[1]={2}}

_"conditional"
  :_"if_"
  :_"if_" "else_"
  :_"if_" "conditional_"

_"conditional_"
  :_ "elseif_" {["conditional"]={1}}
  :_ "elseif_" "else_" {["conditional"]={1,2}}
  :_ "elseif_" "conditional_" {["conditional"]={1,2}}

_"if_"
  :_ "if" "exp" "then" "block" {[1]={2,4}} :attr "scope"

_"elseif_"
  :_ "elseif" "exp" "then" "block" {["if"]={2,4}} :attr "scope"

_"else_"
  :_ "else" "block" {[1]={2}} :attr "scope"

_"funcname_"
  :_ "funcname" {[1]={}} :attr(1, "def")
  :_ "funcname" ":" "Name" {["funcname"]={1,3}} :attr "self" :attr(3, "key")

_"funcname"
  :_ "Name"
  :_ "funcname" "." "Name" {1,3} :attr(3, "key")

_"varlist"
  :_ "var" :attr(1, "def")
  :_ "varlist" "," "var" {[1]={3}} :attr(3, "def")

_"var"
  :_ "Name"
  :_ "prefixexp" "[" "exp" "]" {1,3}
  :_ "prefixexp" "." "Name" {1,3} :attr(3, "key")
  :_ "functioncall" "[" "exp" "]" {1,3}
  :_ "functioncall" "." "Name" {1,3} :attr(3, "key")

_"namelist"
  :_ "Name"
  :_ "namelist" "," "Name" {[1]={3}}

_"explist"
  :_ "exp"
  :_ "explist" "," "exp" {[1]={3}}

_"exp"
  :_ "nil"   {[1]={}}
  :_ "false" {[1]={}}
  :_ "true"  {[1]={}}
-- Numeral
  :_ "IntegerConstant"  {[1]={}}
  :_ "FloatConstant"    {[1]={}}
  :_ "LiteralString"    {[1]={}}
  :_ "..."              {[1]={}}
  :_ "functiondef"      {[1]={}}
  :_ "prefixexp"        {[1]={}}
  :_ "functioncall"     {[1]={}}
  :_ "tableconstructor" {[1]={}}
-- binop
  :_ "exp" "+"   "exp" {[2]={1,3}}
  :_ "exp" "-"   "exp" {[2]={1,3}}
  :_ "exp" "*"   "exp" {[2]={1,3}}
  :_ "exp" "/"   "exp" {[2]={1,3}}
  :_ "exp" "//"  "exp" {[2]={1,3}}
  :_ "exp" "^"   "exp" {[2]={1,3}}
  :_ "exp" "%"   "exp" {[2]={1,3}}
  :_ "exp" "&"   "exp" {[2]={1,3}}
  :_ "exp" "~"   "exp" {[2]={1,3}}
  :_ "exp" "|"   "exp" {[2]={1,3}}
  :_ "exp" ">>"  "exp" {[2]={1,3}}
  :_ "exp" "<<"  "exp" {[2]={1,3}}
  :_ "exp" ".."  "exp" {[2]={1,3}}
  :_ "exp" "<"   "exp" {[2]={1,3}}
  :_ "exp" "<="  "exp" {[2]={1,3}}
  :_ "exp" ">"   "exp" {[2]={1,3}}
  :_ "exp" ">="  "exp" {[2]={1,3}}
  :_ "exp" "=="  "exp" {[2]={1,3}}
  :_ "exp" "~="  "exp" {[2]={1,3}}
  :_ "exp" "and" "exp" {[2]={1,3}}
  :_ "exp" "or"  "exp" {[2]={1,3}}
-- unop
  :_ "-"   "exp" :prec "UNM"  {[1]={2}}
  :_ "not" "exp"              {[1]={2}}
  :_ "#"   "exp"              {[1]={2}}
  :_ "~"   "exp" :prec "BNOT" {[1]={2}}

-- prefixexp without functioncall
_"prefixexp"
  :_ "var" {[1]={}}
  :_ "(" "exp" ")" {[1]={2}}

_"functioncall"
  :_ "prefixexp" "args"
  :_ "prefixexp" ":" "Name" "args" {1,3,4} :attr(3, "key")
  :_ "functioncall" "args"
  :_ "functioncall" ":" "Name" "args" {1,3,4} :attr(3, "key")

_"args"
  :_ "(" ")" {"explist"}
  :_ "(" "explist" ")" {2}
  :_ "tableconstructor"
  :_ "LiteralString"

_"functiondef"
  :_ "function" "funcbody" {2}

_"funcbody"
  :_ "(" ")" "block" "end" {"namelist",3} :attr "scope"
  :_ "(" "parlist" ")" "block" "end" {2,4} :attr "scope"

_"parlist"
  :_ "namelist" {[1]={}}
  :_ "namelist" "," "..." {[1]={}} :attr "vararg"
  :_ "..." {["namelist"]={}} :attr "vararg"

_"tableconstructor"
  :_ "{" "}" {["fieldlist"]={}}
  :_ "{" "fieldlist" "}" {[2]={}}
  :_ "{" "fieldlist" "fieldsep" "}" {[2]={}}

_"fieldlist"
  :_ "field"
  :_ "fieldlist" "fieldsep" "field" {[1]={3}}

_"field"
  :_ "[" "exp" "]" "=" "exp" {5,2}
  :_ "Name" "=" "exp" {3,1} :attr(1, "key")
  :_ "exp"

_"fieldsep"
  :_ ","
  :_ ";"

local lexer, grammar = _:build()
local parser, conflicts = grammar:lr1_construct_table(grammar:lalr1_items())
grammar:write_conflicts(io.stderr, conflicts)
lexer:compile "dromozoa/compiler/lua53_lexer.lua"
parser:compile "dromozoa/compiler/lua53_parser.lua"

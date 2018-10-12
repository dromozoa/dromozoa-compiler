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
  :_ ";"
  :_ "varlist" "=" "explist"
  :_ "functioncall"
  :_ "label"
  :_ "break"
  :_ "goto" "Name"
  :_ "do" "block" "end"
  :_ "while" "exp" "do" "block" "end"
  :_ "repeat" "block" "until" "exp"
  :_ "if_clauses" "end"
  :_ "for" "Name" "=" "exp" "," "exp" "do" "block" "end"
  :_ "for" "Name" "=" "exp" "," "exp" "," "exp" "do" "block" "end"
  :_ "for" "namelist" "in" "explist" "do" "block" "end"
  :_ "function" "funcname_impl" "funcbody"
  :_ "local" "function" "Name" "funcbody"
  :_ "local" "namelist"
  :_ "local" "namelist" "=" "explist"

_"retstat"
  :_ "return"
  :_ "return" ";" {1}
  :_ "return" "explist" {1,2}
  :_ "return" "explist" ";" {1,2}

_"label"
  :_ "::" "Name" "::"

_"if_clauses"
  :_"if_clause"
  :_"if_clause" "else_clause"
  :_"if_clause" "elseif_clauses"

_"elseif_clauses"
  :_ "elseif_clause"
  :_ "elseif_clause" "else_clause"
  :_ "elseif_clause" "elseif_clauses"

_"if_clause"
  :_ "if" "exp" "then" "block"

_"elseif_clause"
  :_ "elseif" "exp" "then" "block"

_"else_clause"
  :_ "else" "block"

_"funcname_impl"
  :_ "funcname" {[1]={}}
  :_ "funcname" ":" "Name" :attr "self" {["funcname"]={1,3}}

_"funcname"
  :_ "Name"
  :_ "funcname" "." "Name" {1,3}

_"varlist"
  :_ "var"
  :_ "varlist" "," "var" {[1]={3}}

-- TODO ???
_"var"
  :_ "Name"
  :_ "prefixexp" "[" "exp" "]"
  :_ "prefixexp" "." "Name"
  :_ "functioncall" "[" "exp" "]"
  :_ "functioncall" "." "Name"

_"namelist"
  :_ "Name"
  :_ "namelist" "," "Name" {[1]={3}}

_"explist"
  :_ "exp"
  :_ "explist" "," "exp" {[1]={3}}

_"exp"
  :_ "nil"
  :_ "false"
  :_ "true"
-- Numeral
  :_ "IntegerConstant"
  :_ "FloatConstant"
  :_ "LiteralString"
  :_ "..."
  :_ "functiondef"
  :_ "prefixexp"
  :_ "functioncall"
  :_ "tableconstructor"
-- binop
  :_ "exp" "+"   "exp" :attr("binop", "ADD")    {1,3}
  :_ "exp" "-"   "exp" :attr("binop", "SUB")    {1,3}
  :_ "exp" "*"   "exp" :attr("binop", "MUL")    {1,3}
  :_ "exp" "/"   "exp" :attr("binop", "DIV")    {1,3}
  :_ "exp" "//"  "exp" :attr("binop", "IDIV")   {1,3}
  :_ "exp" "^"   "exp" :attr("binop", "POW")    {1,3}
  :_ "exp" "%"   "exp" :attr("binop", "MOD")    {1,3}
  :_ "exp" "&"   "exp" :attr("binop", "BAND")   {1,3}
  :_ "exp" "~"   "exp" :attr("binop", "BXOR")   {1,3}
  :_ "exp" "|"   "exp" :attr("binop", "BOR")    {1,3}
  :_ "exp" ">>"  "exp" :attr("binop", "SHR")    {1,3}
  :_ "exp" "<<"  "exp" :attr("binop", "SHL")    {1,3}
  :_ "exp" ".."  "exp" :attr("binop", "CONCAT") {1,3}
  :_ "exp" "<"   "exp" :attr("binop", "LT")     {1,3}
  :_ "exp" "<="  "exp" :attr("binop", "LE")     {1,3}
  :_ "exp" ">"   "exp" :attr("binop", "GT")     {1,3}
  :_ "exp" ">="  "exp" :attr("binop", "GE")     {1,3}
  :_ "exp" "=="  "exp" :attr("binop", "EQ")     {1,3}
  :_ "exp" "~="  "exp" :attr("binop", "NE")     {1,3}
  :_ "exp" "and" "exp" :attr("binop", "AND")    {1,3}
  :_ "exp" "or"  "exp" :attr("binop", "OR")     {1,3}
-- unop
  :_ "-"   "exp" :prec "UNM"  :attr("unop", "UNM")  {2}
  :_ "not" "exp"              :attr("unop", "NOT")  {2}
  :_ "#"   "exp"              :attr("unop", "LEN")  {2}
  :_ "~"   "exp" :prec "BNOT" :attr("unop", "BNOT") {2}

-- prefixexp without functioncall
_"prefixexp"
  :_ "var"
  :_ "(" "exp" ")" {2}

-- TODO ???
_"functioncall"
  :_ "prefixexp" "args"
  :_ "prefixexp" ":" "Name" "args"
  :_ "functioncall" "args"
  :_ "functioncall" ":" "Name" "args"

_"args"
  :_ "(" ")" {"explist"}
  :_ "(" "explist" ")" {2}
  :_ "tableconstructor"
  :_ "LiteralString"

_"functiondef"
  :_ "function" "funcbody" {2}

_"funcbody"
  :_ "(" ")" "block" "end" {"parlist",3}
  :_ "(" "parlist" ")" "block" "end" {2,4}

_"parlist"
  :_ "namelist"
  :_ "namelist" "," "..." :attr "vararg" {1}
  :_ "..." :attr "vararg" {}

_"tableconstructor"
  :_ "{" "}" {"fieldlist"}
  :_ "{" "fieldlist" "}" {2}
  :_ "{" "fieldlist" "fieldsep" "}" {2}

_"fieldlist"
  :_ "field"
  :_ "fieldlist" "fieldsep" "field" {[1]={3}}

_"field"
  :_ "[" "exp" "]" "=" "exp" {2,5}
  :_ "Name" "=" "exp" {1,3}
  :_ "exp"

_"fieldsep"
  :_ ","
  :_ ";"

local lexer, grammar = _:build()
local parser, conflicts = grammar:lr1_construct_table(grammar:lalr1_items())
grammar:write_conflicts(io.stderr, conflicts)
lexer:compile "dromozoa/compiler/lua53_lexer.lua"
parser:compile "dromozoa/compiler/lua53_parser.lua"

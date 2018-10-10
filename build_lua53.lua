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
    :_ (RE[[\\\d{1,3}]]) :sub(2) :int(10) :char() :push()
    :_ (RE[[\\x[0-9A-Fa-f]{2}]]) :sub(3) :int(16) :char() :push()
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
  :_ ("[[" * (RE[[.*]] - RE[[.*\]\].*]]) * "]]") :as "LiteralString" :sub(3, -3) :normalize_eol()

  :_ [["]] :skip() :call "dq_string" :mark()
  :_ [[']] :skip() :call "sq_string" :mark()

  :_ (RE[[\[=*\[]]) :sub(2, -2) :join("]", "]") :hold() :skip() :call "long_string" :mark()

  :_ (RE[[\d+]]) :as "IntegerConstant"
  :_ (RE[[0[xX][0-9A-Fa-f]+]]) :as "IntegerConstant"

  :_ (RE[[(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?]]) :as "FloatConstant"
  :_ (RE[[0[xX]([0-9A-Fa-f]+(\.[0-9A-Fa-f]*)?|\.[0-9A-Fa-f]+)([pP][+-]?\d+)?]]) :as "FloatConstant"

  :_ ("--[[" * (RE[[.*]] - RE[[.*\]\].*]]) * "]]") :skip()
  :_ (RE[[--\[=+\[]]) :sub(4, -2) :join("]", "]") :hold() :skip() :call "long_comment"

  :_ ("--" * (RE[[[^\n]*]] - RE[[\[=*\[.*]]) * "\n") : skip()

string_lexer(_:lexer "dq_string")
  :_ (RE[[[^\\"]+]]) :push()
  :_ [["]] :as "LiteralString" :concat() :ret()

string_lexer(_:lexer "sq_string")
  :_ (RE[[[^\\']+]]) :push()
  :_ [[']] :as "LiteralString" :concat() :ret()

_:search_lexer "long_string"
  :when() :as "LiteralString" :concat() :ret()
  :otherwise() :normalize_eol() :push()

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
  :_ () {"stats"}
  :_ "retstat" {"stats",1}
  :_ "stats"
  :_ "stats" "retstat" {1,2}

-- [TODO] statlist?
_"stats"
  :_ "stat"
  :_ "stats" "stat" {[1]={2}}

_"stat"
  :_ ";"
  :_ "varlist" "=" "explist" {2,3,1}
  :_ "functioncall"
  :_ "label"
  :_ "break"
  :_ "goto" "Name" :attr(2, "label")
  :_ "do" "block" "end" :attr "scope" {1,2}
  :_ "while" "exp" "do" "block" "end" :attr "scope" :attr "loop" {1,2,4}
  :_ "repeat" "block" "until" "exp" :attr "scope" :attr "loop" {1,2,4}
  :_ "if_clauses" "end" {1}
  :_ "for" "Name" "=" "exp" "," "exp" "do" "block" "end" :attr "scope" :attr "loop" :attr(2, "decl") {1,4,6,"exp",2,8}
  :_ "for" "Name" "=" "exp" "," "exp" "," "exp" "do" "block" "end" :attr "scope" :attr "loop" :attr(2, "decl") {1,4,6,8,2,10}
  :_ "for" "namelist" "in" "explist" "do" "block" "end" :attr "scope" :attr "loop" {1,4,2,6}
  :_ "function" "funcname" "funcbody" {2,3}
  :_ "local" "function" "Name" "funcbody" :attr(3, "decl") {1,3,4}
  :_ "local" "namelist"  {1,"explist",2}
  :_ "local" "namelist" "=" "explist" {1,4,2}

_"retstat"
  :_ "return" {}
  :_ "return" ";" {}
  :_ "return" "explist" {2}
  :_ "return" "explist" ";" {2}

_"label"
  :_ "::" "Name" "::" :attr(2, "label") {2}

_"if_clauses"
  :_"if_clause"
  :_"if_clause" "else_clause"
  :_"if_clause" "elseif_clauses"

_"elseif_clauses"
  :_ "elseif_clause"
  :_ "elseif_clause" "else_clause"
  :_ "elseif_clause" "elseif_clauses"

_"if_clause"
  :_ "if" "exp" "then" "block" :attr "scope" {2,4}

_"elseif_clause"
  :_ "elseif" "exp" "then" "block" :attr "scope" {2,4}

_"else_clause"
  :_ "else" "block" :attr "scope" {2}

_"funcname"
  :_ "funcnames"
  :_ "funcnames" ":" "Name" :attr "self" {1,3}

_"funcnames"
  :_ "Name"
  :_ "funcnames" "." "Name" {[1]={3}}

_"varlist"
  :_ "var" :attr(1, "def")
  :_ "varlist" "," "var" :attr(3, "def") {[1]={3}}

_"var"
  :_ "Name"
  :_ "prefixexp" "[" "exp" "]" {1,3}
  :_ "prefixexp" "." "Name" {1,3}
  :_ "functioncall" "[" "exp" "]" {1,3}
  :_ "functioncall" "." "Name" {1,3}

_"namelist"
  :_ "Name" :attr(1, "decl")
  :_ "namelist" "," "Name" :attr(3, "decl") {[1]={3}}

_"explist"
  :_ "exp"
  :_ "explist" "," "exp" {[1]={3}}

_"exp"
  :_ "nil"
  :_ "false"
  :_ "true"
  :_ "Numeral" -- IntegerConstant, FloatConstant
  :_ "LiteralString"
  :_ "..."
  :_ "functiondef"
  :_ "prefixexp"
  :_ "functioncall"
  :_ "tableconstructor" -- fieldlist
  -- binop
  :_ "exp" "+" "exp" {2,1,3} :attr("binop", "ADD")
  :_ "exp" "-" "exp" {2,1,3} :attr("binop", "SUB")
  :_ "exp" "*" "exp" {2,1,3} :attr("binop", "MUL")
  :_ "exp" "/" "exp" {2,1,3} :attr("binop", "DIV")
  :_ "exp" "//" "exp" {2,1,3} :attr("binop", "IDIV")
  :_ "exp" "^" "exp" {2,1,3} :attr("binop", "POW")
  :_ "exp" "%" "exp" {2,1,3} :attr("binop", "MOD")
  :_ "exp" "&" "exp" {2,1,3} :attr("binop", "BAND")
  :_ "exp" "~" "exp" {2,1,3} :attr("binop", "BXOR")
  :_ "exp" "|" "exp" {2,1,3} :attr("binop", "BOR")
  :_ "exp" ">>" "exp" {2,1,3} :attr("binop", "SHR")
  :_ "exp" "<<" "exp" {2,1,3} :attr("binop", "SHL")
  :_ "exp" ".." "exp" {2,1,3} :attr("binop", "CONCAT")
  :_ "exp" "<" "exp" {2,1,3} :attr("binop", "LT")
  :_ "exp" "<=" "exp" {2,1,3} :attr("binop", "LE")
  :_ "exp" ">" "exp" {2,3,1} :attr("binop", "LT")
  :_ "exp" ">=" "exp" {2,3,1} :attr("binop", "LE")
  :_ "exp" "==" "exp" {2,1,3} :attr("binop", "EQ")
  :_ "exp" "~=" "exp" {2,1,3} :attr("binop", "NE")
  :_ "exp" "and" "exp" {2,1,3}
  :_ "exp" "or" "exp" {2,1,3}
  -- unop
  :_ "-" "exp" :prec "UNM" :attr("unop", "UNM")
  :_ "not" "exp" :attr("unop", "NOT")
  :_ "#" "exp" :attr("unop", "LEN")
  :_ "~" "exp" :prec "BNOT" :attr("unop", "BNOT")

-- prefixexp without functioncall
_"prefixexp"
  :_ "var"
  :_ "(" "exp" ")" {2}

_"functioncall"
  :_ "prefixexp" "args"
  :_ "prefixexp" ":" "Name" "args" {1,3,4}
  :_ "functioncall" "args"
  :_ "functioncall" ":" "Name" "args" {1,3,4}

_"args"
  :_ "(" ")" {"explist"}
  :_ "(" "explist" ")" {2}
  :_ "tableconstructor"
  :_ "LiteralString"

_"functiondef"
  :_ "function" "funcbody" {2}

_"funcbody"
  :_ "(" "parlist" ")" "block" "end" :attr "proto" :attr "scope" :attr(5, "funcbody_end") {2,4}

_"parlist"
  :_ () {"namelist"}
  :_ "namelist"
  :_ "namelist" "," "..." {1,3}
  :_ "..." {"namelist",1}

_"tableconstructor"
  :_ "{" "}" {["fieldlist"]={}}
  :_ "{" "fieldlist" "}" {[2]={}}
  :_ "{" "fieldlist" "fieldsep" "}" {[2]={}}

_"fieldlist"
  :_ "field"
  :_ "fieldlist" "fieldsep" "field" {[1]={3}}

_"field"
  :_ "[" "exp" "]" "=" "exp" {5,2}
  :_ "Name" "=" "exp" {3,1}
  :_ "exp"

_"fieldsep"
  :_ ","
  :_ ";"

_"Numeral"
  :_ "IntegerConstant" {[1]={}}
  :_ "FloatConstant" {[1]={}}

local lexer, grammar = _:build()
local parser, conflicts = grammar:lr1_construct_table(grammar:lalr1_items())
grammar:write_conflicts(io.stderr, conflicts)
lexer:compile "dromozoa/compiler/lua53_lexer.lua"
parser:compile "dromozoa/compiler/lua53_parser.lua"

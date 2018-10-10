local execute = (function ()
local tonumber = tonumber
local concat = table.concat

local string_byte = string.byte
local string_char = string.char
local string_find = string.find
local string_gsub = string.gsub
local string_sub = string.sub

local encode_utf8
local decode_surrogate_pair

local utf8 = utf8
if utf8 then
  encode_utf8 = utf8.char
else
  local result, module = pcall(require, "dromozoa.utf8.encode")
  if result then
    encode_utf8 = module
  end
end
if not encode_utf8 then
  encode_utf8 = function (a)
    if a <= 0x7F then
      return string_char(a)
    elseif a <= 0x07FF then
      local b = a % 0x40
      local a = (a - b) / 0x40
      return string_char(a + 0xC0, b + 0x80)
    elseif a <= 0xFFFF then
      local c = a % 0x40
      local a = (a - c) / 0x40
      local b = a % 0x40
      local a = (a - b) / 0x40
      return string_char(a + 0xE0, b + 0x80, c + 0x80)
    else
      local d = a % 0x40
      local a = (a - d) / 0x40
      local c = a % 0x40
      local a = (a - c) / 0x40
      local b = a % 0x40
      local a = (a - b) / 0x40
      return string_char(a + 0xF0, b + 0x80, c + 0x80, d + 0x80)
    end
  end
end

local result, module = pcall(require, "dromozoa.utf16.decode_surrogate_pair")
if result then
  decode_surrogate_pair = module
else
  decode_surrogate_pair = function (a, b)
    return (a - 0xD800) * 0x0400 + (b - 0xDC00) + 0x010000
  end
end

local function range(ri, rj, i, j)
  if i > 0 then
    i = i + ri - 1
  else
    i = i + rj + 1
  end
  if j > 0 then
    j = j + ri - 1
  else
    j = j + rj + 1
  end
  return i, j
end

local eol_table = {
  ["\r"] = "\n";
  ["\r\n"] = "\n";
  ["\n\r"] = "\n";
  ["\r\r"] = "\n\n";
}

return function (self, s)
  local init = 1
  local n = #s
  local terminal_nodes = {}

  local stack = { 1 } -- start lexer
  local position_start = init
  local position_mark
  local buffer = {}

  while init <= n do
    local lexer = self[stack[#stack]]
    local automaton = lexer.automaton
    local position
    local accept

    if automaton then -- regexp_lexer
      local transitions = automaton.transitions
      local state = automaton.start_state

      for i = init + 3, n, 4 do
        local a, b, c, d = string_byte(s, i - 3, i)
        local state1 = transitions[a][state]
        if not state1 then
          position = i - 3
          break
        else
          local state2 = transitions[b][state1]
          if not state2 then
            state = state1
            position = i - 2
            break
          else
            local state3 = transitions[c][state2]
            if not state3 then
              state = state2
              position = i - 1
              break
            else
              local state4 = transitions[d][state3]
              if not state4 then
                state = state3
                position = i
                break
              else
                state = state4
              end
            end
          end
        end
      end

      if not position then
        position = n + 1
        local m = position - (position - init) % 4
        if m < position then
          local a, b, c = string_byte(s, m, n)
          if c then
            local state1 = transitions[a][state]
            if not state1 then
              position = m
            else
              local state2 = transitions[b][state1]
              if not state2 then
                state = state1
                position = m + 1
              else
                local state3 = transitions[c][state2]
                if not state3 then
                  state = state2
                  position = n
                else
                  state = state3
                end
              end
            end
          elseif b then
            local state1 = transitions[a][state]
            if not state1 then
              position = m
            else
              local state2 = transitions[b][state1]
              if not state2 then
                state = state1
                position = m + 1
              else
                state = state2
              end
            end
          else
            local state1 = transitions[a][state]
            if not state1 then
              position = m
            else
              state = state1
            end
          end
        end
      end

      accept = automaton.accept_states[state]
      if not accept then
        return nil, "lexer error", init
      end
    else -- search lexer
      local i, j = string_find(s, self.hold, init, true)
      if not i then
        return nil, "lexer error", init
      end
      if init == i then
        position = j + 1
        accept = 1
      else
        position = i
        accept = 2
      end
    end

    local skip
    local rs = s
    local ri = init
    local rj = position - 1
    local rv

    local actions = lexer.accept_to_actions[accept]
    for i = 1, #actions do
      local action = actions[i]
      local code = action[1]
      if code == 1 then -- skip
        skip = true
      elseif code == 2 then -- push
        buffer[#buffer + 1] = string_sub(rs, ri, rj)
        skip = true
      elseif code == 3 then -- concat
        rs = concat(buffer)
        ri = 1
        rj = #rs
        for j = 1, #buffer do
          buffer[j] = nil
        end
      elseif code == 4 then -- call
        stack[#stack + 1] = action[2]
      elseif code == 5 then -- return
        stack[#stack] = nil
      elseif code == 6 then -- substitute
        rs = action[2]
        ri = 1
        rj = #rs
      elseif code == 7 then -- hold
        self.hold = string_sub(rs, ri, rj)
      elseif code == 8 then -- mark
        position_mark = init
      elseif code == 9 then -- substring
        ri, rj = range(ri, rj, action[2], action[3])
      elseif code == 10 then -- convert to integer
        rv = tonumber(string_sub(rs, ri, rj), action[2])
      elseif code == 11 then -- convert to char
        rs = string_char(rv)
        ri = 1
        rj = #rs
      elseif code == 12 then -- join
        rs = action[2] .. string_sub(rs, ri, rj) .. action[3]
        ri = 1
        rj = #rs
      elseif code == 13 then -- encode utf8
        rs = encode_utf8(tonumber(string_sub(rs, range(ri, rj, action[2], action[3])), 16))
        ri = 1
        rj = #rs
      elseif code == 14 then -- encode utf8 (surrogate pair)
        local code1 = tonumber(string_sub(rs, range(ri, rj, action[2], action[3])), 16)
        local code2 = tonumber(string_sub(rs, range(ri, rj, action[4], action[5])), 16)
        rs = encode_utf8(decode_surrogate_pair(code1, code2))
        ri = 1
        rj = #rs
      elseif code == 15 then -- add integer
        rv = rv + action[2]
      elseif code == 16 then -- normalize end-of-line
        rs = string_gsub(string_gsub(string_sub(rs, ri, rj), "[\n\r][\n\r]?", eol_table), "^\n", "")
        ri = 1
        rj = #rs
      end
    end

    if not skip then
      if not position_mark then
        position_mark = init
      end
      terminal_nodes[#terminal_nodes + 1] = {
        [0] = lexer.accept_to_symbol[accept];
        p = position_start;
        i = position_mark;
        j = position - 1;
        rs = rs;
        ri = ri;
        rj = rj;
      }
      position_start = position
      position_mark = nil
    end
    init = position
  end

  if #stack == 1 then
    if not position_mark then
      position_mark = init
    end
    terminal_nodes[#terminal_nodes + 1] = {
      [0] = 1; -- marker end
      p = position_start;
      i = position_mark;
      j = n;
      rs = s;
      ri = init;
      rj = n;
    }
    return terminal_nodes
  else
    return nil, "lexer error", init
  end
end
end)()
local metatable = { __call = execute }
local _ = {}
_[1] = {1}
_[2] = {_[1]}
_[3] = {}
_[4] = {4,2}
_[5] = {8}
_[6] = {_[1],_[4],_[5]}
_[7] = {4,3}
_[8] = {_[1],_[7],_[5]}
_[9] = {9,2,-2}
_[10] = {12,"]","]"}
_[11] = {7}
_[12] = {4,4}
_[13] = {_[9],_[10],_[11],_[1],_[12],_[5]}
_[14] = {9,4,-2}
_[15] = {4,5}
_[16] = {_[14],_[10],_[11],_[1],_[15]}
_[17] = {_[2],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[3],_[6],_[8],_[13],_[3],_[3],_[3],_[3],_[2],_[16]}
_[18] = {nil,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,nil,nil,nil,58,58,59,59}
_[19] = {1,64,64,65,65,65,65,66,2,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,61,62,63,63}
_[20] = {[4]=5,[5]=5,[7]=5}
_[21] = {[1]=1,[4]=5,[5]=5,[7]=5,[51]=1}
_[22] = {[1]=1,[4]=6,[5]=6,[7]=6,[51]=1}
_[23] = {[4]=5,[5]=5,[7]=5,[51]=43}
_[24] = {[4]=5,[5]=5,[7]=5,[51]=16}
_[25] = {[4]=5,[5]=5,[7]=5,[51]=14}
_[26] = {[4]=5,[5]=5,[7]=5,[51]=17}
_[27] = {[4]=5,[5]=5,[7]=5,[51]=44}
_[28] = {[4]=5,[5]=5,[7]=5,[51]=30}
_[29] = {[4]=5,[5]=5,[7]=5,[51]=31}
_[30] = {[4]=5,[5]=5,[7]=5,[51]=12}
_[31] = {[4]=5,[5]=5,[7]=5,[51]=10,[52]=53,[56]=57}
_[32] = {[4]=5,[5]=5,[7]=5,[51]=39}
_[33] = {[4]=5,[5]=5,[7]=5,[11]=4,[51]=11,[52]=53,[56]=57}
_[34] = {[4]=5,[5]=5,[7]=5,[40]=41,[41]=42,[46]=49,[47]=49,[48]=2,[51]=40,[54]=55}
_[35] = {[4]=5,[5]=5,[7]=5,[13]=22,[51]=13}
_[36] = {[2]=2,[3]=3,[4]=5,[5]=5,[7]=5,[9]=9,[40]=49,[46]=47,[47]=47,[48]=48,[49]=49,[50]=50,[51]=46,[52]=50,[53]=50,[54]=48,[55]=2,[56]=3,[57]=3}
_[37] = {[2]=2,[3]=3,[4]=5,[5]=5,[7]=5,[9]=9,[40]=49,[46]=47,[47]=47,[48]=48,[49]=49,[50]=50,[51]=47,[52]=50,[53]=50,[54]=48,[55]=2,[56]=3,[57]=3}
_[38] = {[4]=5,[5]=5,[7]=5,[38]=36,[51]=38}
_[39] = {[4]=5,[5]=5,[7]=5,[51]=37}
_[40] = {[4]=5,[5]=5,[7]=5,[27]=20,[51]=27}
_[41] = {[4]=5,[5]=5,[7]=7,[18]=24,[27]=25,[28]=26,[29]=23,[34]=58,[51]=29,[58]=58}
_[42] = {[4]=5,[5]=5,[7]=5,[28]=21,[51]=28}
_[43] = {[2]=2,[4]=5,[5]=5,[7]=5,[9]=9,[48]=48,[51]=9,[54]=48,[55]=2}
_[44] = {[2]=2,[4]=5,[5]=5,[7]=5,[9]=9,[46]=52,[47]=52,[48]=48,[49]=52,[51]=9,[54]=48,[55]=2}
_[45] = {[4]=5,[5]=5,[7]=5,[9]=9,[51]=9}
_[46] = {[2]=56,[4]=5,[5]=5,[7]=5,[9]=9,[48]=56,[51]=9}
_[47] = {[4]=5,[5]=5,[7]=5,[9]=9,[46]=54,[51]=9}
_[48] = {[4]=7,[5]=5,[7]=8,[34]=45,[51]=34,[58]=45}
_[49] = {[4]=5,[5]=5,[7]=5,[51]=35}
_[50] = {[4]=5,[5]=5,[7]=5,[51]=15}
_[51] = {[4]=5,[5]=5,[7]=5,[51]=32}
_[52] = {[4]=5,[5]=5,[7]=5,[51]=19}
_[53] = {[4]=5,[5]=5,[7]=5,[51]=33}
_[54] = {[4]=5,[5]=5,[7]=5,[51]=18}
_[55] = {_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[21],_[22],_[21],_[21],_[22],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[21],_[20],_[23],_[24],_[20],_[25],_[26],_[27],_[28],_[29],_[30],_[31],_[32],_[33],_[34],_[35],_[36],_[37],_[37],_[37],_[37],_[37],_[37],_[37],_[37],_[37],_[38],_[39],_[40],_[41],_[42],_[20],_[20],_[43],_[43],_[43],_[43],_[44],_[43],_[45],_[45],_[45],_[45],_[45],_[45],_[45],_[45],_[45],_[46],_[45],_[45],_[45],_[45],_[45],_[45],_[45],_[47],_[45],_[45],_[48],_[20],_[49],_[50],_[45],_[20],_[43],_[43],_[43],_[43],_[44],_[43],_[45],_[45],_[45],_[45],_[45],_[45],_[45],_[45],_[45],_[46],_[45],_[45],_[45],_[45],_[45],_[45],_[45],_[47],_[45],_[45],_[51],_[52],_[53],_[54],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],_[20],[0]=_[20]}
_[56] = {accept_states=_[19],max_state=58,start_state=51,transitions=_[55]}
_[57] = {accept_to_actions=_[17],accept_to_symbol=_[18],automaton=_[56]}
_[58] = {6,"\a"}
_[59] = {2}
_[60] = {_[58],_[59]}
_[61] = {6,"\b"}
_[62] = {_[61],_[59]}
_[63] = {6,"\f"}
_[64] = {_[63],_[59]}
_[65] = {6,"\n"}
_[66] = {_[65],_[59]}
_[67] = {6,"\r"}
_[68] = {_[67],_[59]}
_[69] = {6,"\t"}
_[70] = {_[69],_[59]}
_[71] = {6,"\v"}
_[72] = {_[71],_[59]}
_[73] = {6,"\\"}
_[74] = {_[73],_[59]}
_[75] = {6,"\""}
_[76] = {_[75],_[59]}
_[77] = {6,"'"}
_[78] = {_[77],_[59]}
_[79] = {9,3,-1}
_[80] = {10,16}
_[81] = {11}
_[82] = {_[79],_[80],_[81],_[59]}
_[83] = {9,2,-1}
_[84] = {10,10}
_[85] = {_[83],_[84],_[81],_[59]}
_[86] = {13,4,-2}
_[87] = {_[86],_[59]}
_[88] = {_[59]}
_[89] = {3}
_[90] = {5}
_[91] = {_[89],_[90]}
_[92] = {_[60],_[62],_[64],_[66],_[68],_[70],_[72],_[74],_[76],_[78],_[2],_[66],_[82],_[85],_[87],_[88],_[91]}
_[93] = {[17]=60}
_[94] = {1,2,3,4,5,6,7,8,9,10,11,12,12,12,13,14,14,14,15,16,17}
_[95] = {[20]=20,[22]=20}
_[96] = {[11]=11,[20]=20,[22]=20}
_[97] = {[11]=11,[14]=13,[20]=20,[22]=20,[23]=12}
_[98] = {[11]=11,[12]=13,[20]=20,[22]=20,[23]=14}
_[99] = {[22]=21,[23]=9}
_[100] = {[20]=20,[22]=20,[23]=10}
_[101] = {[16]=17,[17]=18,[20]=20,[22]=20,[23]=16,[25]=27,[26]=28,[27]=27,[28]=15}
_[102] = {[20]=20,[22]=20,[25]=27,[26]=28,[27]=27,[28]=15}
_[103] = {[22]=23,[23]=8}
_[104] = {[20]=20,[22]=20,[23]=1,[25]=27,[26]=28,[27]=27,[28]=15}
_[105] = {[20]=20,[22]=20,[23]=2,[25]=27,[26]=28,[27]=27,[28]=15}
_[106] = {[20]=20,[22]=20,[23]=3,[25]=27,[26]=28,[27]=27,[28]=15}
_[107] = {[20]=20,[22]=20,[23]=4}
_[108] = {[20]=20,[22]=20,[23]=5}
_[109] = {[20]=20,[22]=20,[23]=6}
_[110] = {[20]=20,[22]=20,[23]=24}
_[111] = {[20]=20,[22]=20,[23]=7}
_[112] = {[20]=20,[22]=20,[23]=26}
_[113] = {[20]=20,[22]=20,[23]=11}
_[114] = {[20]=20,[22]=20,[24]=25}
_[115] = {[20]=20,[22]=20,[27]=19}
_[116] = {_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[96],_[97],_[96],_[96],_[98],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[96],_[95],_[99],_[95],_[95],_[95],_[95],_[100],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[101],_[101],_[101],_[101],_[101],_[101],_[101],_[101],_[101],_[101],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[102],_[102],_[102],_[102],_[102],_[102],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[103],_[95],_[95],_[95],_[95],_[104],_[105],_[102],_[102],_[102],_[106],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[107],_[95],_[95],_[95],_[108],_[95],_[109],_[110],_[111],_[95],_[112],_[95],_[113],_[114],_[95],_[115],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],[0]=_[95]}
_[117] = {accept_states=_[94],max_state=28,start_state=22,transitions=_[116]}
_[118] = {accept_to_actions=_[92],accept_to_symbol=_[93],automaton=_[117]}
_[119] = {[20]=20,[22]=20,[23]=9}
_[120] = {[22]=21,[23]=10}
_[121] = {_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[96],_[97],_[96],_[96],_[98],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[96],_[95],_[119],_[95],_[95],_[95],_[95],_[120],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[101],_[101],_[101],_[101],_[101],_[101],_[101],_[101],_[101],_[101],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[102],_[102],_[102],_[102],_[102],_[102],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[103],_[95],_[95],_[95],_[95],_[104],_[105],_[102],_[102],_[102],_[106],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[107],_[95],_[95],_[95],_[108],_[95],_[109],_[110],_[111],_[95],_[112],_[95],_[113],_[114],_[95],_[115],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],_[95],[0]=_[95]}
_[122] = {accept_states=_[94],max_state=28,start_state=22,transitions=_[121]}
_[123] = {accept_to_actions=_[92],accept_to_symbol=_[93],automaton=_[122]}
_[124] = {16}
_[125] = {_[89],_[124],_[90]}
_[126] = {_[125],_[88]}
_[127] = {60}
_[128] = {accept_to_actions=_[126],accept_to_symbol=_[127]}
_[129] = {_[1],_[90]}
_[130] = {_[129],_[2]}
_[131] = {accept_to_actions=_[130],accept_to_symbol=_[3]}
_[132] = {_[57],_[118],_[123],_[128],_[131]}
local root = setmetatable(_[132], metatable)
return function() return root end

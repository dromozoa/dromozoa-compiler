// Copyright (C) 2019 Tomoyuki Fujimori <moyu@dromozoa.com>
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
// You should have received a copy of the GNU General Public License
// along with dromozoa-compiler.  If not, see <http://www.gnu.org/licenses/>.

#include <cstddef>
#include <cstdint>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <vector>

std::string to_string(std::uint64_t v, std::size_t width) {
  std::ostringstream out;
  out << "0x"
      << std::hex << std::uppercase << std::setfill('0') << std::setw(width)
      << v;
  return out.str();
}

std::ostream& write_value(std::ostream& out, std::uint64_t x) {
  std::uint64_t x1 = x >> 48;
  std::uint64_t x2 = x & 0xFFFFFFFFFFFF;
  return out << to_string(x1, 4) << "\t" << to_string(x2, 12);
}

void write_binop(const std::string& op, const std::vector<std::uint64_t>& data) {
  std::ofstream out("uint64_data_" + op + ".txt");
  for (std::size_t i = 0; i < data.size(); ++i) {
    std::uint64_t x = data[i];
    for (std::size_t j = 0; j < data.size(); ++j) {
      std::uint64_t y = data[j];
      if (op == "add") {
        write_value(out, x + y) << "\n";
      } else if (op == "sub") {
        write_value(out, x - y) << "\n";
      } else if (op == "mul") {
        write_value(out, x * y) << "\n";
      } else if (op == "div") {
        if (y == 0) {
          out << "\n";
        } else {
          write_value(out, x / y) << "\t";
          write_value(out, x % y) << "\n";
        }
      }
    }
  }
}

void write_shift(const std::string& op, const std::vector<std::uint64_t>& data) {
  std::ofstream out("uint64_data_" + op + ".txt");
  for (std::size_t i = 0; i < data.size(); ++i) {
    std::uint64_t x = data[i];
    for (std::uint64_t j = 0; j < 64; ++j) {
      if (op == "shl") {
        write_value(out, x << j) << "\n";
      } else if (op == "shr") {
        write_value(out, x >> j) << "\n";
      }
    }
  }
}

std::string encode_hex(std::uint64_t v) {
  std::ostringstream out;
  out << "0x"
      << std::hex << std::uppercase << std::setfill('0') << std::setw(16)
      << v;
  return out.str();
}

void write_unop(const std::string& op, const std::vector<std::uint64_t>& data) {
  std::ofstream out("uint64_data_" + op + ".txt");
  for (std::size_t i = 0; i < data.size(); ++i) {
    std::uint64_t x = data[i];
    if (op == "bnot") {
      write_value(out, ~x) << "\n";
    } else if (op == "encode_dec") {
      out << x << "\n";
    } else if (op == "encode_hex") {
      out << encode_hex(x) << "\n";
    }
  }
}

int main(int, char*[]) {
  std::uint64_t K16[] = {
    0x0000,
    0x0001,
    0x0008,
    0x000F,
    0x1000,
    0x8000,
    0xF000,
    0xFFFF,
  };

  std::size_t N16 = sizeof(K16) / sizeof(K16[0]);

  std::uint64_t K24[] = {
    0x000000,
    0x000001,
    0x000008,
    0x00000F,
    0x100000,
    0x800000,
    0xF00000,
    0xFFFFFF,
  };

  std::size_t N24 = sizeof(K24) / sizeof(K24[0]);

  std::vector<std::uint64_t> data;
  std::ofstream out("uint64_data_source.txt");
  for (std::size_t i = 0; i < N16; ++i) {
    for (std::size_t j = 0; j < N24; ++j) {
      for (std::size_t k = 0; k < N24; ++k) {
        std::uint64_t v = K16[i] << 48 | K24[j] << 24 | K24[k];
        data.push_back(v);
        write_value(out, v) << "\n";
      }
    }
  }

  write_binop("add", data);
  write_binop("mul", data);
  write_binop("sub", data);
  write_binop("div", data);

  write_shift("shl", data);
  write_shift("shr", data);

  write_unop("bnot", data);

  write_unop("encode_dec", data);
  write_unop("encode_hex", data);

  return 0;
}

# Copyright (C) 2019 Tomoyuki Fujimori <moyu@dromozoa.com>
#
# This file is part of dromozoa-prl.
#
# dromozoa-prl is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# dromozoa-prl is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with dromozoa-prl.  If not, see <http://www.gnu.org/licenses/>.

CFLAGS = -g -O2
CPPFLAGS =
CXXFLAGS = -Wall -W $(CFLAGS)
LDFLAGS =
LDLIBS =

TARGET = uint64_data.lua

all: $(TARGET)

clean:
	rm -f *.o uint64_data $(TARGET)

uint64_data.lua: uint64_data
	./uint64_data >$@

uint64_data: uint64_data.o
	$(CXX) $(LDFLAGS) $^ $(LDLIBS) -o $@

uint64_data.o: uint64_data.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $<

#!/bin/bash
export LANG=
set -e
CC="${CC:-cc}"
CXX="${CXX:-c++}"
testname=$(basename -s .sh "$0")
echo -n "Testing $testname ... "
cd "$(dirname "$0")"/../..
mold="$(pwd)/mold"
t=out/test/elf/$testname
mkdir -p $t

cat <<EOF | $CC -c -o $t/a.o -fPIC -xc -
int foo = 4;

int get_foo() {
  return foo;
}

void *bar() {
  return bar;
}
EOF

$CC -B. -shared -o $t/b.so $t/a.o -Wl,-Bsymbolic-functions

cat <<EOF | $CC -c -o $t/c.o -xc - -fno-PIE
#include <stdio.h>

extern int foo;
int get_foo();
void *bar();

int main() {
  foo = 3;
  printf("%d %d %d\n", foo, get_foo(), bar == bar());
}
EOF

$CC -B. -no-pie -o $t/exe $t/c.o $t/b.so
$t/exe | grep -q '3 3 0'

echo OK

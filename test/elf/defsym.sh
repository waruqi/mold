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

cat <<EOF | $CC -fPIC -o $t/a.o -c -xc -
#include <stdio.h>
extern char foo;
extern char bar;
void baz();

void print() {
  printf("Hello %p %p\n", &foo, &bar);
}

int main() {
  baz();
}
EOF

$CC -B. -o $t/exe $t/a.o -pie -Wl,-defsym=foo=16 \
  -Wl,-defsym=bar=0x2000 -Wl,-defsym=baz=print

$t/exe | grep -q '^Hello 0x10 0x2000$'

echo OK

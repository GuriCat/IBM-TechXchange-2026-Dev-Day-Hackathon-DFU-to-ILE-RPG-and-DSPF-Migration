#!/bin/sh
system "CPYSPLF FILE(QPLPRPG) TOFILE(*TOSTMF) TOSTMF('/tmp/cmplist.txt') SPLNBR(*LAST) STMFOPT(*REPLACE)"
echo "exit: $?"

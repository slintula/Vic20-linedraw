#!/bin/bash
/usr/local/bin/acme -f cbm -l build/labels -o build/$1.prg ./$1.asm 
/usr/local/bin/xvic -moncommands build/labels build/$1.prg 2> /dev/null
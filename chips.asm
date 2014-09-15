INCBIN  "chips.exe", 0, 0x4800
INCBIN  "data.o" ; 4800
ALIGN   512, db 0
TIMES   512 db 0
INCBIN  "logic.o" ; 6200
INCBIN  "chips.exe", $

; vim: syntax=nasm

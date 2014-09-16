INCBIN  "base.exe", 0, 0x4800
INCBIN  "data.bin" ; 4800
ALIGN   512, db 0
TIMES   512 db 0
INCBIN  "logic.bin" ; 6200
INCBIN  "base.exe", $

; vim: syntax=nasm

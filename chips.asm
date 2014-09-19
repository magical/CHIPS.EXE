INCBIN "base.exe", 0, 0xa00

INCBIN "base.exe", 0xa00, 0xc00 ; Segment 1
INCBIN "base.exe", 0x1600, 0x2dca+0x2ba ; Segment 2
ALIGN 512, db 0

INCBIN "data.bin" ; 4800 Segment 10
ALIGN 512, db 0
TIMES 512  db 0

INCBIN "logic.bin" ; 6200 Segment 3
INCBIN "base.exe", 0x8c70, 0x52
ALIGN 512, db 0

INCBIN "base.exe", 0x8e00, 0x1400 ; Segment 4

INCBIN "seg5.bin" ; a200 Segment 5
INCBIN "base.exe", 0xa3bc, 0x5a
ALIGN 512, db 0

INCBIN "base.exe", 0xa600, 0x800 ; Segment 6
INCBIN "base.exe", 0xae00, 0x1e00 ; Segment 7
INCBIN "base.exe", 0xcc00, 0x800 ; Segment 8

INCBIN "digits.bin" ; d400
INCBIN "base.exe", 0xd550, 0x3a
ALIGN 512, db 0

; Resources
INCBIN  "base.exe", $

; vim: syntax=nasm

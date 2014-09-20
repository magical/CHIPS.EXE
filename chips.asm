; NASM is our linker for now...

; DOS header

    db 'MZ'         ; 00 Signature
    dw 0x1a6        ; 02 Size of last sector, in bytes
    dw 0x3          ; 04 Size of file, in 0x200-byte pages
    dw 0            ; 06 Number of relocation table entries
    dw 0x20         ; 08 Size of header, in units of 0x10 bytes
    dw 0            ; 0a Minimum allocation, ditto
    dw 0xffff       ; 0c Maximum allocation, ditto
    dw 0x7          ; 0e Stack segment
    dw 0x100        ; 10 Stack pointer
    dw 0x4065       ; 12 Checksum
    dw 0            ; 14 Entry point
    dw 0            ; 16 Code segment
    dw MZRelocTable ; 18 Relocation table address
    dw 0            ; 1a Overlay

; NE extension
    dd 1            ; 1c
    times 14 dw 0   ; 20 Reserved
    dd NEHeader     ; 3c Offset to NE header
MZRelocTable:

ALIGN 512, db 0

MZEntry:
    call word MZStub

    db "This program requires Microsoft Windows.", 13, 10, "$"
    times 0x28 db " "

MZStub:
    pop dx
    push cs
    pop ds
    mov ah,0x9      ; Print ds:dx
    int 0x21
    mov ax,0x4c01   ; Exit with status code 1
    int 0x21

ALIGN 0x200, db 0

; NE header
NEHeader:
    ; TODO

INCBIN "base.exe", 0x400, 0x600


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

; d600
; Resources
INCBIN  "base.exe", $, 0x3fc00-0xd600

; 3fc00
; RT_MENU
%define MF_POPUP  0x10
%define MF_END    0x80
%define MF_CHECKED  0x08

dw 0, 0
dw MF_POPUP
db "&Game", 0
dw 0, 0x72
db "&New Game", 9, "F2", 0
dw 0, 0x74
db "&Pause", 9, "F3", 0
dw 0, 0x73
db "Best &Times...", 0
dw 0, 0
db 0
dw MF_END, 0x6A
db "E&xit", 0

dw MF_POPUP
db "&Options", 0
dw MF_CHECKED, 0x75
db "&Background Music", 0
dw MF_CHECKED, 0x76
db "&Sound Effects", 0
dw MF_CHECKED|MF_END, 0x7A
db "&Color", 0

dw MF_POPUP
db "&Level", 0
dw 0, 0x71
db "&Restart", 9, "Ctrl+R", 0
dw 0, 0x6E
db "&Next", 9, "Ctrl+N", 0
dw 0, 0x6F
db "&Previous", 9, "Ctrl+P", 0
dw MF_END, 0x77
db "&Go To...", 0

dw MF_POPUP|MF_END
db "&Help", 0
dw 0, 0x6B
db "&Contents", 9, "F1", 0
dw 0, 0x78
db "&How to Play", 0
dw 0, 0x79
db "C&ommands", 0
dw 0, 0x6D
db "How to &Use Help", 0
dw 0, 0
db 0
dw MF_END, 0x64
db "&About Chip's Challenge...", 0

ALIGN 512, db 0

; 3fe00

INCBIN "base.exe", 0x3fe00, 0x40800-0x3fe00

; 40800
; RT_ACCELERATOR
%define VIRTKEY 0x1
%define VK_F1   0x70
%define VK_F2   0x71
%define VK_F3   0x72

db 0
dw 'R'-64   ; Ctrl-R
dw 0x71     ; Restart

db 0
dw 'N'-64   ; Ctrl-N
dw 0x6E     ; Next level

db 0
dw 'P'-64   ; Ctrl-P
dw 0x6F     ; Previous level

db VIRTKEY
dw VK_F1
dw 0x6B     ; Help

db VIRTKEY
dw VK_F2
dw 0x72     ; New Game

db VIRTKEY|0x80
dw VK_F3
dw 0x74     ; Pause

ALIGN 512, db 0

; 40a00
; RT_RCDATA
; DLGINCLUDE

; These sections tell the resource compiler
; the name of the include file
; associated with a dialog box.
; They aren't really supposed
; to end up in the executable.

; https://support.microsoft.com/kb/91697

db "GOTO.H", 0
ALIGN 512, db 0

; 40c00
db "PASSWORD.H", 0
ALIGN 512, db 0

; 40e00
db "BESTTIME.H", 0
ALIGN 512, db 0

; 41000
db "COMPLETE.H", 0
ALIGN 512, db 0

; 41200

INCBIN "base.exe", $

; vim: syntax=nasm

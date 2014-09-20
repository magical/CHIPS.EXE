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

; NE header and tables
; See ftp://ftp.microsoft.com/Softlib/MSLFILES/EXEFMT.EXE


; 400
; NE header
NEHeader:
    db "NE"                 ; 00 Signature
    db 5, 30                ; 02 Linker version
    dw NEEntryTab-NEHeader  ; 04 Entry table offset, relative to NE header
    dw NEEntryTabSize       ; 06 Size of entry table, in bytes
    dd 0                    ; 08 CRC
    dw 0x30a                ; 0c Flags
    dw 0xa                  ; 0e Data segment number
    dw 0x800                ; 10 Heap size
    dw 0x2000               ; 12 Stack size
    dw 0x1a, 1              ; 14 Entry point
    dw 0, 0xa               ; 18 Stack pointer
    dw 0xa                  ; 1c Number of entries in segment table
    dw 0x4                  ; 1e Number of entries in module reference table
    dw 0xba                 ; 20 Number of bytes in non-resident name table
    ; Offsets to tables, relative to header
    dw NESegmentTab-NEHeader        ; 22 Segment table
    dw NEResourceTab-NEHeader       ; 24 Resource table
    dw NEResidentNameTab-NEHeader   ; 26 Resident name table
    dw NEModuleRefTab-NEHeader      ; 28 Module Refeference table
    dw NEImportedNameTab-NEHeader   ; 2a Imported names table
    dd NENonResidentNameTab ; 2c Non-resident name table, absolute address
    dw 0                    ; 30 Number of movable entries in entry table
    dw 9                    ; 32 Sector alignment shift
    dw 0                    ; 34 Number of resource entries
    db 0x2                  ; 36 Executable type. 2 = Windows
    db 0x8                  ; 37-3F Reserved
    dw 0x4                  ; 38
    dw 0x2d                 ; 3a
    dw 0                    ; 3c
    dw 0x300                ; 3e

; 440
NESegmentTab:
    dw 0x5, 0x952, 0x1d50, 0x952 ; Segment 1
    dw 0xb, 0x2dca, 0x1d50, 0x2dca ; Segment 2
    dw 0x31, 0x2a70, 0x1d10, 0x2a70 ; Segment 3
    dw 0x47, 0x1208, 0x1d10, 0x1208 ; Segment 4
    dw 0x51, 0x1bc, 0x1d10, 0x1bc ; Segment 5
    dw 0x53, 0x75b, 0x1d10, 0x75c ; Segment 6
    dw 0x57, 0x1cd4, 0x1d10, 0x1cd4 ; Segment 7
    dw 0x66, 0x620, 0x1d10, 0x620 ; Segment 8
    dw 0x6a, 0x150, 0x1d10, 0x150 ; Segment 9
    dw 0x24, 0x1738, 0x0c51, 0x1738 ; Segment 10

; 490
NEResourceTab:
    %define RT_BITMAP 0x8002
    %define RT_ICON 0x8003
    %define RT_MENU 0x8004
    %define RT_DIALOG 0x8005
    %define RT_STRING 0x8006
    %define RT_ACCELERATOR 0x8009
    %define RT_RCDATA 0x800a
    %define RT_VERSIONINFO 0x800e

    dw 9    ; Sector shift

    dw RT_VERSIONINFO, 1, 0, 0
        ; Offset, Length, Flags, ID, Reserved
        dw 0x6b, 1, 0x1c30, 0x8100, 0, 0

    dw RT_BITMAP, 7, 0, 0
        dw 0x6c, 0x90, 0xc30, .OBJ32_4-NEResourceTab, 0, 0
        dw 0xfc, 0x84, 0xc30, .OBJ32_4E-NEResourceTab, 0, 0
        dw 0x180, 0x35, 0xc30, .OBJ32_1-NEResourceTab, 0, 0
        dw 0x1b5, 0xd, 0xc30, .BACKGROUND-NEResourceTab, 0, 0
        dw 0x1c2, 0xe, 0xc30, 0x80c8, 0, 0
        dw 0x1d0, 0xc, 0xc30, .INFOWND-NEResourceTab, 0, 0
        dw 0x1dc, 0x22, 0xc30, .CHIPEND-NEResourceTab, 0, 0

    dw RT_MENU, 1, 0, 0
        dw 0x1fe, 0x1, 0x1c30, .CHIPSMENU-NEResourceTab, 0, 0

    dw RT_DIALOG, 4, 0, 0
        dw 0x1ff, 0x1, 0x1c30, .DLG_GOTO-NEResourceTab, 0, 0
        dw 0x200, 0x1, 0x1c30, .DLG_PASSWORD-NEResourceTab, 0, 0
        dw 0x201, 0x1, 0x1c30, .DLG_BESTTIMES-NEResourceTab, 0, 0
        dw 0x202, 0x1, 0x1c30, .DLG_COMPLETE-NEResourceTab, 0, 0

    dw RT_STRING, 1, 0, 0
        dw 0x203, 0x1, 0x1c30, 0x8011, 0, 0

    dw RT_ACCELERATOR, 1, 0, 0
        dw 0x204, 1, 0xc30, .CHIPSMENU2-NEResourceTab, 0, 0

    dw RT_RCDATA, 4, 0, 0
        dw 0x205, 1, 0x1c30, .DLGINCLUDE1-NEResourceTab, 0, 0
        dw 0x206, 1, 0x1c30, .DLGINCLUDE2-NEResourceTab, 0, 0
        dw 0x207, 1, 0x1c30, .DLGINCLUDE3-NEResourceTab, 0, 0
        dw 0x208, 1, 0x1c30, .DLGINCLUDE4-NEResourceTab, 0, 0

    dw RT_ICON, 1, 0, 0
        dw 0x209, 2, 0x1c10, 0x8001, 0, 0

    dw 0

.OBJ32_4: db 7, "OBJ32_4"
.OBJ32_4E: db 8, "OBJ32_4E"
.OBJ32_1: db 7, "OBJ32_1"
.BACKGROUND: db 10, "BACKGROUND"
.INFOWND: db 7, "INFOWND"
.CHIPEND: db 7, "CHIPEND"
.CHIPSMENU: db 9, "CHIPSMENU"
.DLG_GOTO: db 8, "DLG_GOTO"
.DLG_PASSWORD: db 12, "DLG_PASSWORD"
.DLG_BESTTIMES: db 13, "DLG_BESTTIMES"
.DLG_COMPLETE: db 12, "DLG_COMPLETE"
.CHIPSMENU2: db 9, "CHIPSMENU"
.DLGINCLUDE1: db 10, "DLGINCLUDE"
.DLGINCLUDE2: db 10, "DLGINCLUDE"
.DLGINCLUDE3: db 10, "DLGINCLUDE"
.DLGINCLUDE4: db 10, "DLGINCLUDE"

; 669
NEResidentNameTab:
    db 5, "CHIPS"
    dw 0

    db 0

; 672
NEModuleRefTab:
    dw NEImportedNameTab.KERNEL-NEImportedNameTab
    dw NEImportedNameTab.GDI-NEImportedNameTab
    dw NEImportedNameTab.USER-NEImportedNameTab
    dw NEImportedNameTab.WEP4UTIL-NEImportedNameTab

; 67b
NEImportedNameTab:
    db 0
    .KERNEL: db 6, "KERNEL"
    .GDI: db 3, "GDI"
    .USER: db 4, "USER"
    .WEP4UTIL: db 8, "WEP4UTIL"

; 694
NEEntryTabSize          equ 0x31
NEEntryTab:

INCBIN "base.exe", 0x694, 0x31

; 6C5
NENonResidentNameTab:
    %macro name 2
        %push
        %strlen %$len %1
        db %$len, %1    ; name
        dw %2           ; ordinal
        %pop
    %endmacro

    name "Chips Challenge",    0
    name "BOARDWNDPROC",       9
    name "MAINWNDPROC",        1
    name "INFOWNDPROC",       16
    name "PASSWORDMSGPROC",   11
    name "GOTOLEVELMSGPROC",   4
    name "HINTWNDPROC",       15
    name "INVENTORYWNDPROC",  14
    name "COMPLETEMSGPROC",   13
    name "BESTTIMESMSGPROC",  12
    name "COUNTERWNDPROC",     2

; 77e

ALIGN 512, db 0
TIMES 512  db 0

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

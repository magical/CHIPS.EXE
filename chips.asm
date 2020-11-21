; NASM is our linker for now...

%include "constants.asm"

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

; 200
MZEntry:
    call MZStub

    db "This program requires Microsoft Windows.", 13, 10, "$"
    times 0x28 db " "

MZStub:
    pop dx  ; dx = return address
    push cs
    pop ds  ; ds = cs
    mov ah,0x9      ; Print string in ds:dx
    int 0x21
    mov ax,0x4c01   ; Exit with status code 1
    int 0x21

ALIGN 512, db 0

; NE header and tables
; See ftp://ftp.microsoft.com/Softlib/MSLFILES/EXEFMT.EXE

%define SectorShift 9
%define SectorSize (1<<SectorShift)

; 400
; NE header
NEHeader:
    db "NE"                 ; 00 Signature
    db 5, 30                ; 02 Linker version
    dw NEEntryTab-NEHeader  ; 04 Entry table offset, relative to NE header
    dw NEEntryTabSize       ; 06 Size of entry table, in bytes
    dd 0                    ; 08 CRC
    dw 0x30a                ; 0c Flags
    dw 10                   ; 0e Data segment
    dw 0x800                ; 10 Heap size
    dw 0x2000               ; 12 Stack size
    dw 0x1a, 1              ; 14 Entry point
    dw 0x0, 10              ; 18 Stack pointer
    dw NESegmentLen         ; 1c Number of entries in segment table
    dw NEModuleRefLen       ; 1e Number of entries in module reference table
    dw NENonResidentNameSize; 20 Number of bytes in non-resident name table
    ; Offsets to tables, relative to header
    dw NESegmentTab-NEHeader        ; 22 Segment table
    dw NEResourceTab-NEHeader       ; 24 Resource table
    dw NEResidentNameTab-NEHeader   ; 26 Resident name table
    dw NEModuleRefTab-NEHeader      ; 28 Module Refeference table
    dw NEImportedNameTab-NEHeader   ; 2a Imported names table
    dd NENonResidentNameTab ; 2c Non-resident name table, absolute address
    dw 0                    ; 30 Number of movable entries in entry table
    dw SectorShift          ; 32 Sector alignment shift
    dw 0                    ; 34 Number of resource entries
    db 0x2                  ; 36 Executable type. 2 = Windows
    db 0x8                  ; 37-3F Reserved
    dw 0x4                  ; 38
    dw 0x2d                 ; 3a
    dw 0                    ; 3c
    dw 0x300                ; 3e


; 440
NESegmentLen equ 10
NESegmentTab:
    ; sector, length, flags, alloc
    dw (Segment1-$$)>>SectorShift, _segment_1_size, 0x1d50, _segment_1_size ; Segment 1
    dw (Segment2-$$)>>SectorShift, _segment_2_size, 0x1d50, _segment_2_size ; Segment 2
    dw (Logic-$$)>>SectorShift,    _segment_3_size, 0x1d10, _segment_3_size ; Segment 3
    dw (Segment4-$$)>>SectorShift, _segment_4_size, 0x1d10, _segment_4_size ; Segment 4
    dw (Segment5-$$)>>SectorShift, _segment_5_size, 0x1d10, _segment_5_size ; Segment 5
    dw (Segment6-$$)>>SectorShift, _segment_6_size, 0x1d10, _segment_6_size+1 ; Segment 6
    dw (Segment7-$$)>>SectorShift, _segment_7_size, 0x1d10, _segment_7_size ; Segment 7
    dw (Segment8-$$)>>SectorShift, _segment_8_size, 0x1d10, _segment_8_size ; Segment 8
    dw (Digits-$$)>>SectorShift,   _segment_9_size, 0x1d10, _segment_9_size ; Segment 9
    dw (Data-$$)>>SectorShift,     _data_size,      0x0c51, _data_size ; Segment 10

    _segment_1_size equ 0x952
    %include "segment_sizes.inc"

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

    dw SectorShift    ; Shift amount

    %define RESOFF(s) ((s-$$)>>SectorShift)
    %define RESLEN(n) (n>>SectorShift)

    dw RT_VERSIONINFO, 1, 0, 0
        ; Offset, Length, Flags, ID, Reserved
        dw RESOFF(VERSION), 1, 0x1c30, 0x8100, 0, 0

    dw RT_BITMAP, 7, 0, 0
        dw RESOFF(OBJ32_4), RESLEN(OBJ32_4E-OBJ32_4),   0xc30, .OBJ32_4-NEResourceTab, 0, 0
        dw RESOFF(OBJ32_4E), RESLEN(OBJ32_1-OBJ32_4E),  0xc30, .OBJ32_4E-NEResourceTab, 0, 0
        dw RESOFF(OBJ32_1), RESLEN(BACKGROUND-OBJ32_1), 0xc30, .OBJ32_1-NEResourceTab, 0, 0
        dw RESOFF(BACKGROUND), RESLEN(DigitsBitmap-BACKGROUND), 0xc30, .BACKGROUND-NEResourceTab, 0, 0
        dw RESOFF(DigitsBitmap), RESLEN(INFOWND-DigitsBitmap),  0xc30, 0x8000+200, 0, 0
        dw RESOFF(INFOWND), RESLEN(CHIPEND-INFOWND),    0xc30, .INFOWND-NEResourceTab, 0, 0
        dw RESOFF(CHIPEND), RESLEN(CHIPSMENU-CHIPEND),  0xc30, .CHIPEND-NEResourceTab, 0, 0

    dw RT_MENU, 1, 0, 0
        dw RESOFF(CHIPSMENU), 0x1, 0x1c30, .CHIPSMENU-NEResourceTab, 0, 0

    dw RT_DIALOG, 4, 0, 0
        dw RESOFF(DLGGOTO), 0x1, 0x1c30, .DLG_GOTO-NEResourceTab, 0, 0
        dw RESOFF(DLGPASSWORD), 0x1, 0x1c30, .DLG_PASSWORD-NEResourceTab, 0, 0
        dw RESOFF(DLGBESTTIME), 0x1, 0x1c30, .DLG_BESTTIMES-NEResourceTab, 0, 0
        dw RESOFF(DLGCOMPLETE), 0x1, 0x1c30, .DLG_COMPLETE-NEResourceTab, 0, 0

    dw RT_STRING, 1, 0, 0
        dw RESOFF(StringResource), 0x1, 0x1c30, 0x8011, 0, 0

    dw RT_ACCELERATOR, 1, 0, 0
        dw RESOFF(CHIPSMENUACCEL), 1, 0xc30, .CHIPSMENU2-NEResourceTab, 0, 0

    dw RT_RCDATA, 4, 0, 0
        dw RESOFF(DlgIncludeGoto), 1, 0x1c30, .DLGINCLUDE1-NEResourceTab, 0, 0
        dw RESOFF(DlgIncludePassword), 1, 0x1c30, .DLGINCLUDE2-NEResourceTab, 0, 0
        dw RESOFF(DlgIncludeBesttime), 1, 0x1c30, .DLGINCLUDE3-NEResourceTab, 0, 0
        dw RESOFF(DlgIncludeComplete), 1, 0x1c30, .DLGINCLUDE4-NEResourceTab, 0, 0

    dw RT_ICON, 1, 0, 0
        dw RESOFF(ICON), 2, 0x1c10, 0x8001, 0, 0

    dw 0

    %undef RESOFF
    %undef RESLEN

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
    db 5, "CHIPS" ; name of this module
    dw 0 ; ordinal (ignored for module name)

    ; exported procedure names
    db 0

; 672
NEModuleRefLen equ 4
NEModuleRefTab:
    dw NEImportedNameTab.KERNEL-NEImportedNameTab
    dw NEImportedNameTab.GDI-NEImportedNameTab
    dw NEImportedNameTab.USER-NEImportedNameTab
    dw NEImportedNameTab.WEP4UTIL-NEImportedNameTab

; 67b
NEImportedNameTab:
    db 0
    .KERNEL     db 6, "KERNEL"
    .GDI        db 3, "GDI"
    .USER       db 4, "USER"
    .WEP4UTIL   db 8, "WEP4UTIL"

; 694
NEEntryTab:
    %macro BUNDLE 2
        db %1 ; number of entries
        db %2 ; segment number
    %endmacro
    %macro ENTRY 1
        db 1  ; EXPORTED flag
        dw %1 ; offset
    %endmacro
    BUNDLE 2, 2
        ENTRY MAINWNDPROC       ; 1
        ENTRY COUNTERWNDPROC    ; 2
    BUNDLE 1, 0                 ; 3 (unused)
    BUNDLE 1, 6
        ENTRY GOTOLEVELMSGPROC  ; 4
    BUNDLE 4, 0                 ; 5-8 (unused)
    BUNDLE 1, 2
        ENTRY BOARDWNDPROC      ; 9
    BUNDLE 1, 0                 ; 10 (unused)
    BUNDLE 1, 4
        ENTRY PASSWORDMSGPROC   ; 11
    BUNDLE 2, 6
        ENTRY BESTTIMESMSGPROC  ; 12
        ENTRY COMPLETEMSGPROC   ; 13
    BUNDLE 3, 2
        ENTRY INVENTORYWNDPROC  ; 14
        ENTRY HINTWNDPROC       ; 15
        ENTRY INFOWNDPROC       ; 16
    db 0

    ; Exported symbol addresses
    ; TODO: get these from the linker
    %include "exports.inc"

NEEntryTabSize          equ $-NEEntryTab

; 6c5
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
    db 0

NENonResidentNameSize equ $-NENonResidentNameTab

; 77f

ALIGN 512, db 0
TIMES 512  db 0

; a00
Segment1:
    INCBIN "base.exe", 0xa00, 0x952
    INCBIN "base.exe", 0xa00+0x952, 162
    ALIGN SectorSize, db 0
    TIMES SectorSize  db 0

; 1600
Segment2:
    INCBIN "seg2.bin"
    ALIGN SectorSize, db 0

; 4800
; Segment 10
Data:
    INCBIN "data.bin"
    _data_size equ $-Data
    ALIGN SectorSize, db 0
    TIMES SectorSize  db 0

; 6200
; Segment 3
Logic:
    INCBIN "logic.bin"
    ALIGN SectorSize, db 0

; 8e00
Segment4:
    INCBIN "seg4.bin"
    ALIGN SectorSize, db 0

; a200
Segment5:
    INCBIN "seg5.bin"
    ALIGN SectorSize, db 0

; a600
Segment6:
    INCBIN "seg6.bin"
    ALIGN SectorSize, db 0

; ae00
Segment7:
    INCBIN "movement.bin"
    ALIGN SectorSize, db 0

; cc00
Segment8:
    INCBIN "sound.bin"
    ALIGN SectorSize, db 0

; d400
; Segment 9
Digits:
    INCBIN "digits.bin"
    ALIGN SectorSize, db 0

; d600
; Resources

; d600
; RT_VERSION
; Mysterious resource is mysterious
VERSION:
    dw 0, 1, 1, 0x2020, 0x10, 1, 0x4, 0x2e8, 0, 1
    ALIGN SectorSize, db 0

; d800
; Bitmaps
; RT_BITMAP

; d800
OBJ32_4:
    INCBIN "res/OBJ32_4.bmp", 14
    TIMES 0x22 db 0xFF ; ???
    ALIGN SectorSize, db 0


; 1f800
OBJ32_4E:
    INCBIN "res/OBJ32_4E.bmp", 14
    TIMES 0x1c db 0xFF
    ALIGN SectorSize, db 0

; 30000
OBJ32_1:
    INCBIN "res/OBJ32_1.bmp", 14
    db 0x04, 0x04, 0x88, 0x10, 0x0F, 0xFF, 0xF0, 0x00,
    db 0x0C, 0x00, 0x00, 0x00, 0x0C, 0x8D, 0xBF, 0xD2
    ALIGN SectorSize, db 0

; 36a00
BACKGROUND:
    INCBIN "res/BACKGROUND.bmp", 14
    ALIGN SectorSize, db 0

; 38400
DigitsBitmap:
    INCBIN "res/200.bmp", 14
    ALIGN SectorSize, db 0

; 3a000
INFOWND:
    INCBIN "res/INFOWND.bmp", 14
    ALIGN SectorSize, db 0

; 3b800
CHIPEND:
    INCBIN "res/CHIPEND.bmp", 14
    ALIGN SectorSize, db 0

; 3fc00
; RT_MENU
%define MF_CHECKED  0x08
%define MF_POPUP    0x10
%define MF_END      0x80

%macro POPUP 1-2 0
    dw MF_POPUP|%2
    db %1, 0
%endmacro
%macro MENUITEM 2-3 0
    dw %3 ; flags
    dw %2 ; action
    db %1, 0 ; text
%endmacro

CHIPSMENU:
    dd 0
    POPUP "&Game"
        MENUITEM `&New Game\tF2`, ID_NEWGAME
        MENUITEM `&Pause\tF3`, ID_PAUSE
        MENUITEM "Best &Times...", ID_BESTTIMES
        MENUITEM "", 0
        MENUITEM "E&xit", ID_QUIT, MF_END

    POPUP "&Options"
        MENUITEM "&Background Music", ID_BGM, MF_CHECKED
        MENUITEM "&Sound Effects", ID_SOUND, MF_CHECKED
        MENUITEM "&Color", ID_COLOR, MF_CHECKED|MF_END

    POPUP "&Level"
        MENUITEM `&Restart\tCtrl+R`, ID_RESTART
        MENUITEM `&Next\tCtrl+N`, ID_NEXT
        MENUITEM `&Previous\tCtrl+P`, ID_PREVIOUS
        MENUITEM "&Go To...", ID_GOTO, MF_END

    POPUP "&Help", MF_END
        MENUITEM `&Contents\tF1`, ID_HELP
        MENUITEM "&How to Play", ID_HOWTOPLAY
        MENUITEM "C&ommands", ID_COMMANDS
        MENUITEM "How to &Use Help", ID_METAHELP
        MENUITEM "", 0
        MENUITEM "&About Chip's Challenge...", ID_ABOUT, MF_END

ALIGN SectorSize, db 0

; 3fe00
; RT_DIALOGs

; 3fe00
DLGGOTO:
    dd 0x90c800c0 ; window style
    db 7    ; number of items
    dw 6, 18, 151, 94 ; position and size
    db 0x0   ; menu
    db 0x0   ; window class
    db "Go To Level", 0 ; caption
    dw 8 ; font size
    db "MS Sans Serif", 0 ; font
    ; Items
    db 0x09, 0x00, 0x07, 0x00, 0x84, 0x00, 0x13, 0x00, 0xff, 0xff, 0x00, 0x00, 0x02, 0x50, 0x82, "Enter a level number and password, or just a password.", 0, 0
    db 0x45, 0x00, 0x1e, 0x00, 0x20, 0x00, 0x0c, 0x00, 0x64, 0x00, 0x80, 0x00, 0x81, 0x50, 0x81, 0, 0
    db 0x45, 0x00, 0x2e, 0x00, 0x20, 0x00, 0x0c, 0x00, 0x65, 0x00, 0x88, 0x00, 0x81, 0x50, 0x81, 0, 0
    db 0x10, 0x00, 0x20, 0x00, 0x33, 0x00, 0x08, 0x00, 0xff, 0xff, 0x02, 0x00, 0x02, 0x50, 0x82, "Level number:", 0, 0
    db 0x10, 0x00, 0x2f, 0x00, 0x33, 0x00, 0x08, 0x00, 0xff, 0xff, 0x02, 0x00, 0x02, 0x50, 0x82, "Password:", 0, 0
    db 0x1b, 0x00, 0x4a, 0x00, 0x28, 0x00, 0x0e, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x50, 0x80, "OK", 0, 0
    db 0x53, 0x00, 0x4a, 0x00, 0x28, 0x00, 0x0e, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x50, 0x80, "Cancel", 0, 0
ALIGN SectorSize, db 0

; 40000
DLGPASSWORD:
    dd 0x90c800c0 ; window style
    db 4    ; number of items
    dw 6, 18, 181, 56 ; position and size
    db 0x0   ; menu
    db 0x0   ; window class
    db "Password Entry", 0 ; caption
    dw 8 ; font size
    db "MS Sans Serif", 0 ; font
    ; Items
    db 0x8e, 0x00, 0x09, 0x00, 0x1b, 0x00, 0x0c, 0x00, 0x65, 0x00, 0x88, 0x00, 0x81, 0x50, 0x81, 0, 0
    db 0x09, 0x00, 0x0b, 0x00, 0x84, 0x00, 0x08, 0x00, 0x64, 0x00, 0x00, 0x00, 0x02, 0x50, 0x82, 0, 0
    db 0x2a, 0x00, 0x24, 0x00, 0x28, 0x00, 0x0e, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x50, 0x80, "OK", 0, 0
    db 0x62, 0x00, 0x24, 0x00, 0x28, 0x00, 0x0e, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x50, 0x80, "Cancel", 0, 0
ALIGN SectorSize, db 0

; 40200
DLGBESTTIME:
    dd 0x90c800c0 ; window style
    db 6    ; number of items
    dw 6, 18, 159, 159 ; position and size
    db 0x0   ; menu
    db 0x0   ; window class
    db "Best Times", 0 ; caption
    dw 8 ; font size
    db "MS Sans Serif", 0 ; font
    ; Items
    db 0x07, 0x00, 0x31, 0x00, 0x90, 0x00, 0x51, 0x00, 0x64, 0x00, 0x81, 0x00, 0xa1, 0x50, 0x83, 0, 0
    db 0x07, 0x00, 0x24, 0x00, 0x90, 0x00, 0x08, 0x00, 0xff, 0xff, 0x00, 0x00, 0x02, 0x50, 0x82, "Level number, seconds left, level score:", 0, 0
    db 0x1f, 0x00, 0x8a, 0x00, 0x28, 0x00, 0x0e, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x50, 0x80, "OK", 0, 0
    db 0x57, 0x00, 0x8a, 0x00, 0x28, 0x00, 0x0e, 0x00, 0x65, 0x00, 0x00, 0x00, 0x01, 0x58, 0x80, "Go To", 0, 0
    db 0x07, 0x00, 0x0a, 0x00, 0x8e, 0x00, 0x08, 0x00, 0x66, 0x00, 0x00, 0x00, 0x02, 0x50, 0x82, 0, 0
    db 0x07, 0x00, 0x17, 0x00, 0x8e, 0x00, 0x08, 0x00, 0x67, 0x00, 0x00, 0x00, 0x02, 0x50, 0x82, 0, 0
ALIGN SectorSize, db 0

; 40400
DLGCOMPLETE:
    dd 0x90c800c0 ; window style
    db 7    ; number of items
    dw 6, 18, 136, 119 ; position and size
    db 0x0   ; menu
    db 0x0   ; window class
    db "Level Complete!", 0 ; caption
    dw 8 ; font size
    db "MS Sans Serif", 0 ; font
    ; Items
    db 0x09, 0x00, 0x07, 0x00, 0x75, 0x00, 0x08, 0x00, 0x65, 0x00, 0x01, 0x00, 0x02, 0x50, 0x82, 0, 0
    db 0x09, 0x00, 0x15, 0x00, 0x75, 0x00, 0x08, 0x00, 0x66, 0x00, 0x01, 0x00, 0x02, 0x50, 0x82, 0, 0
    db 0x09, 0x00, 0x23, 0x00, 0x75, 0x00, 0x08, 0x00, 0x67, 0x00, 0x01, 0x00, 0x02, 0x50, 0x82, 0, 0
    db 0x09, 0x00, 0x31, 0x00, 0x75, 0x00, 0x08, 0x00, 0x6c, 0x00, 0x01, 0x00, 0x02, 0x50, 0x82, 0, 0
    db 0x09, 0x00, 0x3f, 0x00, 0x75, 0x00, 0x08, 0x00, 0x68, 0x00, 0x01, 0x00, 0x02, 0x50, 0x82, 0, 0
    db 0x09, 0x00, 0x4d, 0x00, 0x75, 0x00, 0x13, 0x00, 0x69, 0x00, 0x01, 0x00, 0x02, 0x50, 0x82, 0, 0
    db 0x30, 0x00, 0x63, 0x00, 0x28, 0x00, 0x0e, 0x00, 0x6a, 0x00, 0x01, 0x00, 0x01, 0x50, 0x80, "Onward!", 0, 0
ALIGN SectorSize, db 0

; 40600
; RT_STRING
StringResource:
    db 0x5, "Chips"
    db 0x10, "Chip's Challenge"
    db 0x24, "By Tony Krueger", 10
    db       "Artwork by Ed Halley"

ALIGN SectorSize, db 0

; 40800
; RT_ACCELERATOR
%define VIRTKEY 0x1
%define LAST    0x80
%define CTRL(k) ((k)-64)
%define VK_F1   0x70
%define VK_F2   0x71
%define VK_F3   0x72

%macro ACCEL 2-3 0
    db %3
    dw %1
    dw %2
%endmacro

CHIPSMENUACCEL:
    ACCEL CTRL('R'), ID_RESTART
    ACCEL CTRL('N'), ID_NEXT
    ACCEL CTRL('P'), ID_PREVIOUS
    ACCEL VK_F1, ID_HELP, VIRTKEY
    ACCEL VK_F2, ID_NEWGAME, VIRTKEY
    ACCEL VK_F3, ID_PAUSE, VIRTKEY|LAST

ALIGN SectorSize, db 0

; 40a00
; RT_RCDATA
; DLGINCLUDE

; These sections tell the resource compiler
; the name of the include file
; associated with a dialog box.
; They aren't really supposed
; to end up in the executable.

; https://support.microsoft.com/kb/91697

DlgIncludeGoto:
db "GOTO.H", 0
ALIGN SectorSize, db 0

; 40c00
DlgIncludePassword:
db "PASSWORD.H", 0
ALIGN SectorSize, db 0

; 40e00
DlgIncludeBesttime:
db "BESTTIME.H", 0
ALIGN SectorSize, db 0

; 41000
DlgIncludeComplete:
db "COMPLETE.H", 0
ALIGN SectorSize, db 0

; 41200
; RT_ICON
ICON:
INCBIN "chips.ico", 0x16
ALIGN SectorSize, db 0

; vim: syntax=nasm

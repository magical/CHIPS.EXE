; structs.asm - header file for struct definitions
; Game state offsets

Upper               equ 0x0
Lower               equ 0x400

LevelNumber         equ 0x800
ChipX               equ 0x808
ChipY               equ 0x80a
IsSliding           equ 0x80c
IsBuffered          equ 0x80e ; buffered move waiting
BufferedX           equ 0x812
BufferedY           equ 0x814
Autopsy             equ 0x816
SlideX              equ 0x818
SlideY              equ 0x81a

InitialMonsterListLen   equ 0x81c
InitialMonsterList  equ 0x81e
;   ... monsters ...
;   x, y

; Probably
; See Monster struct
SlipListLen         equ 0x91e
SlipListCap         equ 0x920
SlipListHandle      equ 0x922
SlipListPtr         equ 0x924
SlipListSeg         equ 0x926

; Monsters
; See Monster struct
MonsterListLen      equ 0x928
MonsterListCap      equ 0x92a
MonsterListHandle   equ 0x92c
MonsterListPtr      equ 0x92e
MonsterListSeg      equ 0x930

; Toggle walls and floors
; x, y
ToggleListLen       equ 0x932
ToggleListCap       equ 0x934
ToggleListHandle    equ 0x936
ToggleListPtr       equ 0x938
ToggleListSeg       equ 0x93a

; Trap connections
; See Connection
TrapListLen         equ 0x93c
TrapListCap         equ 0x940
TrapListPtr         equ 0x942
TrapListSeg         equ 0x944
; no handle?
; probably no cap, actually

; 946
; 948
; 94a
; 94c
; 94e

; Teleports
; x, y
TeleportListLen       equ 0x950
TeleportListCap       equ 0x952
TeleportListHandle    equ 0x954
TeleportListPtr       equ 0x956
TeleportListSeg       equ 0x958

HaveMouseTarget     equ 0xa38
MouseTargetX        equ 0xa3a
MouseTargetY        equ 0xa3c
;HaveMouseTarget     equ 0xa40

STRUC Connection
    .fromX resw 1
    .fromY resw 1
    .toX   resw 1
    .toY   resw 1
    .flag resw 1
ENDSTRUC

STRUC Monster
    .tile resb 1
    .x resw 1
    .y resw 1
    .xdir resw 1
    .ydir resw 1
    .slipping resw 1
ENDSTRUC

; vim: syntax=nasm

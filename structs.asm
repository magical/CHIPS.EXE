; structs.asm - header file for struct definitions
; Game state offsets

Upper               equ 0x0
Lower               equ 0x400

LevelNumber         equ 0x800
NumLevelsInSet      equ 0x802
InitialTimeLimit    equ 0x804
InitialChipsRemainingCount equ 0x806
ChipX               equ 0x808
ChipY               equ 0x80a
IsSliding           equ 0x80c
IsBuffered          equ 0x80e ; buffered move waiting
; Whether the "Level Title / Password: ZORK"
; box should be shown
IsLevelPlacardVisible equ 0x810
BufferedX           equ 0x812
BufferedY           equ 0x814
Autopsy             equ 0x816
SlideX              equ 0x818
SlideY              equ 0x81a

InitialMonsterListLen   equ 0x81c
InitialMonsterList  equ 0x81e
;   ... monsters ...
;   x, y

; Slip list
; Array of Monster structs
; Monster.slipping records whether the moving object is a block (yes, i should probably rename it).
SlipListLen         equ 0x91e
SlipListCap         equ 0x920
SlipListHandle      equ 0x922
SlipListPtr         equ 0x924
SlipListSeg         equ 0x926

; Monsters
; Array of Monster structs
MonsterListLen      equ 0x928
MonsterListCap      equ 0x92a
MonsterListHandle   equ 0x92c
MonsterListPtr      equ 0x92e
MonsterListSeg      equ 0x930

; Toggle walls and floors
; Array of x, y points
ToggleListLen       equ 0x932
ToggleListCap       equ 0x934
ToggleListHandle    equ 0x936
ToggleListPtr       equ 0x938
ToggleListSeg       equ 0x93a

; Trap connections
; Array of Connection structs
; Connection.flag records whether the trap is closed
TrapListLen         equ 0x93c
TrapListCap         equ 0x93e
TrapListHandle      equ 0x940
TrapListPtr         equ 0x942
TrapListSeg         equ 0x944

; Clone machine connections
; Array of Connection structs
CloneListLen        equ 0x946
CloneListCap        equ 0x948
CloneListHandle     equ 0x94a
CloneListPtr        equ 0x94c
CloneListSeg        equ 0x94e

; Teleports
; Array of x, y points
TeleportListLen     equ 0x950
TeleportListCap     equ 0x952
TeleportListHandle  equ 0x954
TeleportListPtr     equ 0x956
TeleportListSeg     equ 0x958

LevelTitle          equ 0x95a ; size: 64
LevelHint           equ 0x99a ; size: 128
LevelPassword       equ 0xa1a ; size: 10

; top left corner of the viewport
ViewportX           equ 0xa24
ViewportY           equ 0xa26
; size of the viewport. always 9,9
ViewportWidth       equ 0xa28
ViewportHeight      equ 0xa2a

; when the level starts and after each move,
; the viewport position is set to
;     viewportx = chipx - viewportwidth/2
;     viewporty = chipy - viewportheight/2
; and clamped to the range [0, 32-viewportsize]

; a24 viewport x
; a26 viewport y
; a28 viewport width
; a2a viewport height
; a2c ___ x?
; a2e ___ y?

; a34 incremented every time chip moves

; Counts the number of times the level has been retried,
; and progress towards the "You seem to be having trouble"
; dialog box appearing.
RestartCount        equ 0xa30
MelindaCount        equ 0xa32

StepCount           equ 0xa34 ; Incremented every time chip moves
EndingTick          equ 0xa36 ; Controls the ending animation
HaveMouseTarget     equ 0xa38
MouseTargetX        equ 0xa3a
MouseTargetY        equ 0xa3c
IdleTickCount       equ 0xa3e
ChipHasMoved        equ 0xa40

GameStateSize       equ 0xa42

STRUC Point
    .x  resw 1
    .y  resw 1
ENDSTRUC

STRUC Connection
    .fromX resw 1       ; 0x0
    .fromY resw 1       ; 0x2
    .toX   resw 1       ; 0x4
    .toY   resw 1       ; 0x6
    .flag resw 1        ; 0x8
ENDSTRUC

STRUC Monster
    .tile resb 1        ; 0x0
    .x resw 1           ; 0x1
    .y resw 1           ; 0x3
    .xdir resw 1        ; 0x5
    .ydir resw 1        ; 0x7
    .slipping resw 1    ; 0x9
ENDSTRUC

; vim: syntax=nasm

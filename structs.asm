; structs.asm - header file for struct definitions
; Game state offsets

STRUC FarPtr
    .Off                resw 1      ; 0x0
    .Seg                resw 1      ; 0x2
ENDSTRUC

STRUC GameState
    Upper               resb 0x400  ; 0x0
    Lower               resb 0x400  ; 0x400

    LevelNumber         resw 1      ; 0x800
    NumLevelsInSet      resw 1      ; 0x802
    InitialTimeLimit    resw 1      ; 0x804
    InitialChipsRemainingCount resw 1 ; 0x806
    ChipX               resw 1      ; 0x808
    ChipY               resw 1      ; 0x80a
    IsSliding           resw 1      ; 0x80c
    IsBuffered          resw 1      ; 0x80e ; buffered move waiting
    ; Whether the "Level Title / Password: ZORK"
    ; box should be shown
    IsLevelPlacardVisible resw 1    ; 0x810
    BufferedX           resw 1      ; 0x812
    BufferedY           resw 1      ; 0x814
    Autopsy             resw 1      ; 0x816
    SlideX              resw 1      ; 0x818
    SlideY              resw 1      ; 0x81a

    InitialMonsterListLen resw 1    ; 0x81c
    InitialMonsterList  resw 64*2   ; 0x81e
    ;   ... monsters ...
    ;   x, y

    ; Slip list
    ; Array of Slipper structs
    ; See Slipper definition below
    SlipListLen         resw 1      ; 0x91e
    SlipListCap         resw 1      ; 0x920
    SlipListHandle      resw 1      ; 0x922
    SlipListPtr         resd 1      ; 0x924

    ; Monsters
    ; Array of Monster structs
    ; See Monster definition below
    MonsterListLen      resw 1      ; 0x928
    MonsterListCap      resw 1      ; 0x92a
    MonsterListHandle   resw 1      ; 0x92c
    MonsterListPtr      resd 1      ; 0x92e

    ; Toggle walls and floors
    ; Array of x, y points
    ToggleListLen       resw 1      ; 0x932
    ToggleListCap       resw 1      ; 0x934
    ToggleListHandle    resw 1      ; 0x936
    ToggleListPtr       resd 1      ; 0x938

    ; Trap connections
    ; Array of Connection structs
    ; Connection.flag records whether the trap is closed
    TrapListLen         resw 1      ; 0x93c
    TrapListCap         resw 1      ; 0x93e
    TrapListHandle      resw 1      ; 0x940
    TrapListPtr         resd 1      ; 0x942

    ; Clone machine connections
    ; Array of Connection structs
    CloneListLen        resw 1      ; 0x946
    CloneListCap        resw 1      ; 0x948
    CloneListHandle     resw 1      ; 0x94a
    CloneListPtr        resd 1      ; 0x94c

    ; Teleports
    ; Array of x, y points
    TeleportListLen     resw 1      ; 0x950
    TeleportListCap     resw 1      ; 0x952
    TeleportListHandle  resw 1      ; 0x954
    TeleportListPtr     resd 1      ; 0x956

    LevelTitle          resb MaxTitleLength    ; 0x95a
    LevelHint           resb MaxHintLength     ; 0x99a
    LevelPassword       resb MaxPasswordLength ; 0xa1a

    ; top left corner of the viewport
    ViewportX           resw 1      ; 0xa24
    ViewportY           resw 1      ; 0xa26
    ; size of the viewport. always 9,9
    ViewportWidth       resw 1      ; 0xa28
    ViewportHeight      resw 1      ; 0xa2a

    ; when the level starts and after each move,
    ; the viewport position is set to
    ;     viewportx = chipx - viewportwidth/2
    ;     viewporty = chipy - viewportheight/2
    ; and clamped to the range [0, 32-viewportsize]

    ; These fields are some sort of unused additional offset
    ; to the viewport offset. They are always set to zero.
    UnusedOffsetX       resw 1      ; 0xa2c
    UnusedOffsetY       resw 1      ; 0xa2e

    ; Counts the number of times the level has been retried,
    ; and progress towards the "You seem to be having trouble"
    ; dialog box appearing.
    RestartCount        resw 1      ; 0xa30
    MelindaCount        resw 1      ; 0xa32

    StepCount           resw 1      ; 0xa34 ; Incremented every time chip moves
    EndingTick          resw 1      ; 0xa36 ; Controls the ending animation
    HaveMouseTarget     resw 1      ; 0xa38
    MouseTargetX        resw 1      ; 0xa3a
    MouseTargetY        resw 1      ; 0xa3c
    IdleTickCount       resw 1      ; 0xa3e
    ChipHasMoved        resw 1      ; 0xa40
ENDSTRUC

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

; An entry on the monster list
; slipping records whether the monster is also on the slip list
STRUC Monster
    .tile resb 1        ; 0x0
    .x resw 1           ; 0x1
    .y resw 1           ; 0x3
    .xdir resw 1        ; 0x5
    .ydir resw 1        ; 0x7
    .slipping resw 1    ; 0x9
ENDSTRUC

; An entry on the slip list
; isblock records whether the moving object is a block (not a monster)
STRUC Slipper
    .tile resb 1        ; 0x0
    .x resw 1           ; 0x1
    .y resw 1           ; 0x3
    .xdir resw 1        ; 0x5
    .ydir resw 1        ; 0x7
    .isblock resw 1     ; 0x9
ENDSTRUC

; vim: syntax=nasm

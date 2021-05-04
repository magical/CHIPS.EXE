SEGMENT CODE ; 4

; Functions for loading levels

%include "base.inc"
%include "constants.asm"
%include "structs.asm"
%include "variables.asm"
%include "func.mac"

%include "extern.inc"
%include "windows.inc"

EXTERN WEP4UTIL.CENTERHWND
EXTERN WEP4UTIL.GRAYDLGPROC

EXPORT PASSWORDMSGPROC PASSWORDMSGPROC 11

; 0

; Returns the onscreen rect containing the tile at x,y
func GetTileRect
    %arg x:word, y:word
    sub sp,byte +0xa
    push di
    push si
    mov ax,[x]
    mov bx,[GameStatePtr]
    sub ax,[bx+ViewportX]
    sub ax,[bx+UnusedOffsetX]
    shl ax,byte TileShift
    mov [bp-0xa],ax
    mov ax,[y]
    sub ax,[bx+ViewportY]
    sub ax,[bx+UnusedOffsetY]
    shl ax,byte TileShift
    mov [bp-0x8],ax
    mov ax,[bp-0xa]
    add ax,TileWidth
    mov [bp-0x6],ax
    mov ax,[bp-0x8]
    add ax,TileHeight
    mov [bp-0x4],ax
    ; return rect by value, via global temp space
    mov ax,TempRect
    mov di,ax
    lea si,[bp-0xa]
    push ds
    pop es
    movsw
    movsw
    movsw
    movsw
    pop si
    pop di
endfunc

; 5e

; ResetLevelData
;
; Sets all the tiles to Floor
; and clears the slip, monster, toggle, trap,
; clone, teleport, and initial monster lists
; (doesn't free them, just sets the length to 0).
func ResetLevelData
    sub sp,byte +0x2
    push si
    xor si,si
.label0: ; 6e
    mov bx,[GameStatePtr]
    mov byte [bx+si+Lower],0x0
    mov bx,[GameStatePtr]
    add bx,si
    mov al,[bx+Lower]
    mov [bx+Upper],al
    inc si
    cmp si,0x400 ; BoardWidth * BoardHeight?
    jl .label0 ; ↑
    mov bx,[GameStatePtr]
    mov word [bx+SlipListLen],0x0
    mov bx,[GameStatePtr]
    mov word [bx+MonsterListLen],0x0
    mov bx,[GameStatePtr]
    mov word [bx+ToggleListLen],0x0
    mov bx,[GameStatePtr]
    mov word [bx+TrapListLen],0x0
    mov bx,[GameStatePtr]
    mov word [bx+CloneListLen],0x0
    mov bx,[GameStatePtr]
    mov word [bx+TeleportListLen],0x0
    mov bx,[GameStatePtr]
    mov word [bx+InitialMonsterListLen],0x0
    pop si
endfunc

; d8

; ReadLevelDataOrDie
; Tries to read a level. Sets LevelNumber on success.
; If it fails, pops up an error message and exits the game.
func ReadLevelDataOrDie
    %arg levelNum:word
    sub sp,byte +0x2
    push si
    mov si,[levelNum]
    push ds
    push word DataFileName ; "CHIPS.DAT"
    push si
    call far ReadLevelData ; ee 4:a56
    add sp,byte +0x6
    or ax,ax
    jnz .success ; ↓
    ; load failed... show and error message and quit the game
    call far ResetLevelData ; fa 4:5e
    push byte +0x10
    push ds
    push word CorruptDataMessage
    push word [hwndMain]
    call far ShowMessageBox ; 109 2:0
    add sp,byte +0x8
    push word [hwndMain]
    push word 0x111
    push byte ID_QUIT
    push byte +0x0
    push byte +0x0
    call far USER.PostMessage ; 11e
.success: ; 123
    mov bx,[GameStatePtr]
    mov [bx+LevelNumber],si
    pop si
endfunc

; 134

; Sets the window title to "Chip's Challenge: level title"
; or just "Chip's Challenge" if the level title is blank.
func UpdateWindowTitle
    %arg hWnd:word
    sub sp,0x8c
    mov bx,[GameStatePtr]
    add bx,LevelTitle
    mov [bp-0x8c],bx
    cmp byte [bx],0x0
    jz .label0 ; ↓
    mov ax,bx
    jmp short .label1 ; ↓
    nop
.label0: ; 158
    mov ax,s_98e ; ""
.label1: ; 15b
    mov cx,ax
    mov [bp-0x8],ds
    push ds
    push cx
    cmp byte [bx],0x0
    jz .label2 ; ↓
    mov ax,sColon ; ": "
    jmp short .label3 ; ↓
.label2: ; 16c
    mov ax,sNoColon ; ""
.label3: ; 16f
    mov [bp-0x4],ds
    push ds
    push ax
    push ds
    push word MessageBoxCaption
    push ds
    push word s_sss ; "%s%s%s"
    lea ax,[bp-0x8a]
    push ss
    push ax
    call far USER._wsprintf ; 182
    add sp,byte +0x14
    push word [hWnd]
    lea ax,[bp-0x8a]
    push ss
    push ax
    call far USER.SetWindowText ; 193
endfunc

; 1a0

; Enable or disable the previous/next menu items
; as appropriate for the given level number.
func UpdateNextPrevMenuItems
    %arg levelNum:word
    %local levelNumTmp:word
    sub sp,byte +0x4
    push si
    mov si,[levelNum]
    push word [hMenu]
    push byte ID_PREVIOUS
    mov [levelNumTmp],si
    cmp si,byte +0x1
    jng .label0 ; ↓
    xor ax,ax
    jmp short .label1 ; ↓
    nop
.label0: ; 1c4
    mov ax,0x1
.label1: ; 1c7
    push ax
    call far USER.EnableMenuItem ; 1c8
    mov ax,[levelNumTmp]
    mov bx,[GameStatePtr]
    cmp [bx+NumLevelsInSet],ax
    jg .label2 ; ↓
    cmp word [DebugModeEnabled],byte +0x0
    jnz .label2 ; ↓
    mov cx,0x1
    jmp short .label3 ; ↓
.label2: ; 1e6
    xor cx,cx
.label3: ; 1e8
    push word [hMenu]
    push byte ID_NEXT
    push cx
    call far USER.EnableMenuItem ; 1ef
    pop si
endfunc

; 1fc

; Sets the timer and chip counter to the
; level's time limit and chip count.
func ResetTimerAndChipCount
    sub sp,byte +0x2
    mov bx,[GameStatePtr]
    mov ax,[bx+InitialTimeLimit]
    mov [TimeRemaining],ax
    mov ax,[bx+InitialChipsRemainingCount]
    mov [ChipsRemainingCount],ax
    push word [hwndCounter2]
    push byte +0x2
    cmp word [TimeRemaining],byte +0x1
    sbb ax,ax
    and ax,0x2
    push ax
    call far USER.SetWindowWord ; 22c
    push byte +0x1
    call far FUN_2_16fa ; 233 2:16fa
endfunc

; 240

; frees the monster list and other lists
func FreeGameLists
    sub sp,byte +0xe
    mov bx,[GameStatePtr]
    mov ax,[bx+SlipListHandle]
    mov [bp-0x4],ax
    or ax,ax
    jz .label0 ; ↓
    push ax
    call far KERNEL.GlobalUnlock ; 25d
    mov bx,[GameStatePtr]
    push word [bx+SlipListHandle]
    call far KERNEL.GlobalFree ; 26a
.label0: ; 26f
    mov bx,[GameStatePtr]
    mov ax,[bx+MonsterListHandle]
    mov [bp-0x6],ax
    or ax,ax
    jz .label1 ; ↓
    push ax
    call far KERNEL.GlobalUnlock ; 27f
    mov bx,[GameStatePtr]
    push word [bx+MonsterListHandle]
    call far KERNEL.GlobalFree ; 28c
.label1: ; 291
    mov bx,[GameStatePtr]
    mov ax,[bx+ToggleListHandle]
    mov [bp-0x8],ax
    or ax,ax
    jz .label2 ; ↓
    push ax
    call far KERNEL.GlobalUnlock ; 2a1
    mov bx,[GameStatePtr]
    push word [bx+ToggleListHandle]
    call far KERNEL.GlobalFree ; 2ae
.label2: ; 2b3
    mov bx,[GameStatePtr]
    mov ax,[bx+TrapListHandle]
    mov [bp-0xa],ax
    or ax,ax
    jz .label3 ; ↓
    push ax
    call far KERNEL.GlobalUnlock ; 2c3
    mov bx,[GameStatePtr]
    push word [bx+TrapListHandle]
    call far KERNEL.GlobalFree ; 2d0
.label3: ; 2d5
    mov bx,[GameStatePtr]
    mov ax,[bx+CloneListHandle]
    mov [bp-0xc],ax
    or ax,ax
    jz .label4 ; ↓
    push ax
    call far KERNEL.GlobalUnlock ; 2e5
    mov bx,[GameStatePtr]
    push word [bx+CloneListHandle]
    call far KERNEL.GlobalFree ; 2f2
.label4: ; 2f7
    mov bx,[GameStatePtr]
    mov ax,[bx+TeleportListHandle]
    mov [bp-0xe],ax
    or ax,ax
    jz .end ; ↓
    push ax
    call far KERNEL.GlobalUnlock ; 307
    mov bx,[GameStatePtr]
    push word [bx+TeleportListHandle]
    call far KERNEL.GlobalFree ; 314
.end: ; 319
endfunc

; 320

; ClearGameState(bool flag)
;
; Zeroes the game state
; and maybe frees lists first.
func ClearGameState
    %arg flag:word
    sub sp,byte +0x4
    cmp word [flag],byte +0x0
    jnz .dontFree ; ↓
    call far FreeGameLists ; 333 4:240
.dontFree: ; 338
    ; memset(gamestateptr, 0, sizeof *gamestateptr)
    mov bx,[GameStatePtr]
    lea dx,[bx+GameStateSize]
    cmp dx,bx
    jna .end ; ↓
.zeroLoop: ; 344
    mov word [bx],0x0
    add bx,byte +0x2
    cmp bx,dx
    jb .zeroLoop ; ↑
.end: ; 34f
endfunc

; 356

; StartLevel(levelNum, restarting)
func FUN_4_0356
    %arg levelNum:word
    %arg restarting:word
    %local oldMelinda:word
    %local wasPaused:word
    %local oldCursor:word
    sub sp,byte +0xa
    push di
    push si
    mov si,[restarting]
    mov bx,[GameStatePtr]
    mov ax,[bx+IsLevelPlacardVisible]
    mov [wasPaused],ax
    push byte +0x0
    push byte +0x0
    push word IDC_WAIT ; i don't care ...wait
    call far USER.LoadCursor ; 37a
    mov di,ax
    push word [hwndBoard]
    call far USER.SetCapture ; 385
    push di
    call far USER.SetCursor ; 38b
    mov [oldCursor],ax
    push byte +0x1
    call far FUN_2_176e ; 395 2:176e
    add sp,byte +0x2
    push byte +0x0
    call far ResetInventory ; 39f 3:1734
    add sp,byte +0x2
    or si,si
    jz .label1 ; ↓
    mov bx,[GameStatePtr]
    cmp word [bx+StepCount],byte MelindaStepRequirement
    jng .label1 ; ↓
    cmp word [levelNum],FakeLastLevel
    jz .label1 ; ↓
    cmp word [levelNum],LastLevel
    jz .label1 ; ↓
    inc word [bx+MelindaCount]
    mov bx,[GameStatePtr]
    cmp word [bx+MelindaCount],byte MelindaThreshold
    jl .label1 ; ↓
    push byte +0x24
    push ds
    push word MelindaMessage
    push word [hwndMain]
    call far ShowMessageBox ; 3dd 2:0
    add sp,byte +0x8
    cmp ax,ID_YES
    jnz .resetMelindaCount ; ↓
    inc word [levelNum]
    xor si,si
    jmp short .label1 ; ↓
    nop
.resetMelindaCount: ; 3f2
    mov bx,[GameStatePtr]
    mov word [bx+MelindaCount],0x0
.label1: ; 3fc
    mov di,[bp-0xa] ; uninitialized
    or si,si
    jz .clearGameState ; ↓
    mov bx,[GameStatePtr]
    mov di,[bx+RestartCount]
    mov ax,[bx+MelindaCount]
    mov [oldMelinda],ax
.clearGameState: ; 412
    push byte +0x0 ; don't free lists
    call far ClearGameState ; 414 4:320
    add sp,byte +0x2
    or si,si
    jz .label3 ; ↓
    lea ax,[di+0x1] ; increment restart count
    ; preserve RestartCount and MelindaCount across restart
    mov bx,[GameStatePtr]
    mov [bx+RestartCount],ax
    mov ax,[oldMelinda]
    mov bx,[GameStatePtr]
    mov [bx+MelindaCount],ax
.label3: ; 436
    push word [levelNum]
    call far ReadLevelDataOrDie ; 439 4:d8
    add sp,byte +0x2
    cmp word [GamePaused],byte +0x0
    jnz .label4 ; ↓
    or si,si
    jnz .label4 ; ↓
    ; start the music
    ; but not if we're paused or restarting the same level
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    call far FUN_8_0308 ; 454 8:308
    add sp,byte +0x2
.label4: ; 45c
    call far InitBoard ; 45c 3:54c
    cmp word [DebugModeEnabled],byte +0x0
    jz .label5 ; ↓
    ; if debug mode is enabled, show the whole game board
    mov bx,[GameStatePtr]
    mov word [bx+ViewportY],0x0
    mov bx,[GameStatePtr]
    mov ax,[bx+ViewportY]
    mov [bx+ViewportX],ax
    mov bx,[GameStatePtr]
    mov word [bx+UnusedOffsetY],0x0
    mov bx,[GameStatePtr]
    mov ax,[bx+UnusedOffsetY]
    mov [bx+UnusedOffsetX],ax
    mov bx,[GameStatePtr]
    mov word [bx+ViewportWidth],0x20
    mov bx,[GameStatePtr]
    mov word [bx+ViewportHeight],0x20
    jmp .label10 ; ↓
    nop
.label5: ; 4ac
    ; normal mode: 9x9 viewport
    mov bx,[GameStatePtr]
    mov word [bx+ViewportHeight],0x9
    mov bx,[GameStatePtr]
    mov ax,[bx+ViewportHeight]
    mov [bx+ViewportWidth],ax
    mov bx,[GameStatePtr]
    mov word [bx+UnusedOffsetY],0x10
    mov bx,[GameStatePtr]
    mov ax,[bx+UnusedOffsetY]
    mov [bx+UnusedOffsetX],ax
    mov bx,[GameStatePtr]
    ; set the viewport position
    ; based on chip's position
    ; ViewportX = ChipX - (32-ViewportWidth)/2 clamped to [0, 32-ViewportWidth]
    mov ax,[bx+ViewportWidth]
    mov cx,ax
    sub ax,0x20
    neg ax
    mov dx,ax
    mov ax,cx
    mov di,dx
    cwd
    sub ax,dx
    sar ax,1
    sub ax,[bx+ChipX]
    neg ax
    ; clamp
    or ax,ax
    jnl .label6 ; ↓
    xor ax,ax
.label6: ; 4fe
    cmp ax,di
    jng .label7 ; ↓
    mov ax,di
.label7: ; 504
    mov [bx+ViewportX],ax
    ; ViewportY = ChipX - (32-ViewportHeight)/2 clamped to [0, 32-ViewportHeight]
    mov bx,[GameStatePtr]
    mov ax,[bx+ViewportHeight]
    mov cx,ax
    sub ax,0x20
    neg ax
    mov dx,ax
    mov ax,cx
    mov di,dx
    cwd
    sub ax,dx
    sar ax,1
    sub ax,[bx+ChipY]
    neg ax
    ; clamp
    or ax,ax
    jnl .label8 ; ↓
    xor ax,ax
.label8: ; 52e
    cmp ax,di
    jng .label9 ; ↓
    mov ax,di
.label9: ; 534
    mov [bx+ViewportY],ax
.label10: ; 538
    call far ResetTimerAndChipCount ; 538 4:1fc
    mov bx,[GameStatePtr]
    mov word [bx+IsLevelPlacardVisible],0x1
    cmp word [wasPaused],byte +0x0
    jnz .label11 ; ↓
    call far PauseTimer ; 54d 2:17a2
.label11: ; 552
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    push word [hwndMain]
    call far UpdateWindowTitle ; 55e 4:134
    add sp,byte +0x4
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    call far UpdateNextPrevMenuItems ; 56e 4:1a0
    add sp,byte +0x2
    mov bx,[GameStatePtr]
    mov word [bx+UnusedOffsetX],0x0
    mov bx,[GameStatePtr]
    mov word [bx+UnusedOffsetY],0x0
    push word [hwndBoard]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far USER.InvalidateRect ; 594
    ; refresh time, chips, and inventory windows
    push byte 0x3f
    call far FUN_2_0cbe ; 59b 2:cbe
    add sp,byte +0x2
    or si,si
    jnz .label12 ; ↓
    push si
    push si
    push si
    push word [levelNum]
    call far GetLevelProgressFromIni ; 5ad 2:1adc
    add sp,byte +0x8
    or ax,ax
    jnz .label12 ; ↓
    push ax
    push ax
    push byte -1
    push word [levelNum]
    call far SaveLevelProgressToIni ; 5c0 2:1c1c
    add sp,byte +0x8
    push word ID_HighestLevel
    call far GetIniInt ; 5cb 2:198e
    add sp,byte +0x2
    cmp ax,[levelNum]
    jnl .label12 ; ↓
    push word [levelNum]
    push word ID_HighestLevel
    call far StoreIniInt ; 5de 2:19ca
    add sp,byte +0x4
.label12: ; 5e6
    push word [oldCursor]
    call far USER.SetCursor ; 5e9
    call far USER.ReleaseCapture ; 5ee
    pop si
    pop di
endfunc

; 5fc

; Expand rle
func ExpandTilesRLE
    %arg src:word, _:dword
    %arg dest:word, _:dword
    sub sp,byte +0x14
    push di
    push si
    mov si,[bp+0x10]
    mov ax,0x20
    sub ax,[bp+0xe]
    cwd
    sub ax,dx
    sar ax,1
    mov [bp-0xa],ax
    mov ax,0x20
    sub ax,si
    cwd
    sub ax,dx
    sar ax,1
    mov di,ax
    mov byte [bp-0x4],0x0
    mov ax,[src]
    mov [bp-0xc],ax
    mov ax,di
    add ax,si
    cmp ax,di
    jng .label5 ; ↓
    mov cx,di
    shl cx,byte 0x5
    mov ax,[bp-0xa]
    add ax,[bp+0xe]
    mov [bp-0x14],ax
    sub ax,ax
    add ax,si
    mov [bp-0xe],ax
    mov si,[dest]
.label0: ; 652
    mov di,[bp-0xa]
    cmp [bp-0x14],di
    jng .label4 ; ↓
    mov si,[bp-0xc]
    mov dx,[dest]
.label1: ; 660
    cmp byte [bp-0x4],0x0
    jz .label2 ; ↓
    mov al,[bp-0x5]
    mov [bp-0x3],al
    dec byte [bp-0x4]
    jmp short .label3 ; ↓
    nop
.label2: ; 672
    lodsb
    mov [bp-0x3],al
    cmp al,0xff
    jnz .label3 ; ↓
    lodsb
    mov [bp-0x4],al
    dec byte [bp-0x4]
    lodsb
    mov [bp-0x5],al
    mov [bp-0x3],al
.label3: ; 688
    mov al,[bp-0x3]
    mov bx,cx
    add bx,di
    add bx,dx
    mov [bx],al
    inc di
    cmp [bp-0x14],di
    jg .label1 ; ↑
    mov [bp-0xc],si
    mov si,[dest]
.label4: ; 69f
    add cx,byte +0x20
    dec word [bp-0xe]
    jnz .label0 ; ↑
.label5: ; 6a7
    pop si
    pop di
endfunc

; 6b0

func DecodePassword
    %arg password:word
    sub sp,byte +0x2
    push si
    mov si,[password]
    cmp byte [si],0x0
    jz .label1 ; ↓
.label0: ; 6c6
    xor byte [si],0x99
    inc si
    cmp byte [si],0x0
    jnz .label0 ; ↑
.label1: ; 6cf
    pop si
endfunc

; 6d8

; Parse the optional fields for a level
; and load them into the GameState
func DecodeLevelFields
    %arg data:word, size:word
    sub sp,byte +0xc
    push di
    push si
    mov si,[data]
    mov ax,[size]
    add ax,si
    mov [bp-0xc],ax
    cmp ax,si
    ja .label0 ; ↓
    jmp .label26 ; ↓
.label0: ; 6f9
    mov al,[si]
    mov [bp-0x3],al
    inc si
    mov al,[si]
    mov [bp-0x9],al
    inc si
    mov al,[bp-0x3]
    sub ah,ah
    dec ax
    cmp ax,0x9
    jna .label1 ; ↓
    jmp .nextField ; ↓
.label1: ; 713
    shl ax,1
    xchg ax,bx
    jmp [cs:bx+.jumpTable]
    nop
.jumpTable:
    dw .field.timelimit ; 1
    dw .field.chips ; 2
    dw .field.title ; 3
    dw .field.traps ; 4
    dw .field.clones ; 5
    dw .field.password ; 6
    dw .field.hint ; 7
    dw .field.plaintextPassword ; 8
    dw .nextField ; 9
    dw .field.monsters ; 10
.field.timelimit: ; 730
    mov ax,[si]
    mov bx,[GameStatePtr]
    mov [bx+InitialTimeLimit],ax
    jmp .nextField
    nop
.field.chips: ; 73e
    mov ax,[si]
    mov bx,[GameStatePtr]
    mov [bx+InitialChipsRemainingCount],ax
    jmp .nextField ; ↓
    nop
.field.title: ; 74c
    cmp byte [bp-0x9],MaxTitleLength
    jna .label4 ; ↓
    mov byte [si+MaxTitleLength-1],0x0
.label4: ; 756
    mov ax,[GameStatePtr]
    add ax,LevelTitle
.label5: ; 75c
    push ds
    push ax
    push ds
    push si
    call far KERNEL.lstrcpy ; 760
    jmp .nextField ; ↓
.field.traps: ; 768
    mov [bp-0x6],si
    mov al,[bp-0x9]
    mov cl,0xa
    sub ah,ah
    div cl
    sub ah,ah
    mov bx,[GameStatePtr]
    mov [bx+TrapListLen],ax
    mov bx,[GameStatePtr]
    mov ax,[bx+TrapListCap]
    cmp [bx+TrapListLen],ax
    jg .label7 ; ↓
    jmp .nextField ; ↓
.label7: ; 78f
    push byte +0xa
    push word [bx+TrapListLen]
    lea ax,[bx+TrapListCap]
    push ax
    lea ax,[bx+TrapListPtr]
    push ax
    lea ax,[bx+TrapListHandle]
    push ax
    call far GrowArray ; 7a4 3:1a4
    add sp,byte +0xa
    or ax,ax
    jz .label11 ; ↓
    mov word [bp-0x8],0x0
    mov bx,[GameStatePtr]
    cmp word [bx+TrapListLen],byte +0x0
    jg .label8 ; ↓
    jmp .nextField ; ↓
.label8: ; 7c3
    mov [data],si
    mov word [bp-0x4],0x0
.label9: ; 7cb
    les bx,[bx+TrapListPtr]
    mov si,[bp-0x4]
    mov ax,[bp-0x6]
    lea di,[bx+si]
    mov si,ax
    mov cx,0x5
    rep movsw
    add word [bp-0x4],byte +0xa
    add word [bp-0x6],byte +0xa
    inc word [bp-0x8]
    mov ax,[bp-0x8]
    mov bx,[GameStatePtr]
    cmp [bx+TrapListLen],ax
    jg .label9 ; ↑
.label10: ; 7f6
    mov si,[data]
    jmp .nextField ; ↓
.label11: ; 7fc
    mov bx,[GameStatePtr]
    mov word [bx+TrapListLen],0x0
    jmp .nextField ; ↓
    nop
.field.clones: ; 80a
    mov [bp-0x6],si
    mov al,[bp-0x9]
    shr al,byte 0x3
    sub ah,ah
    mov bx,[GameStatePtr]
    mov [bx+CloneListLen],ax
    mov bx,[GameStatePtr]
    mov ax,[bx+CloneListCap]
    cmp [bx+CloneListLen],ax
    jg .label13 ; ↓
    jmp .nextField ; ↓
.label13: ; 82e
    push byte +0x8
    push word [bx+CloneListLen]
    lea ax,[bx+CloneListCap]
    push ax
    lea ax,[bx+CloneListPtr]
    push ax
    lea ax,[bx+CloneListHandle]
    push ax
    call far GrowArray ; 843 3:1a4
    add sp,byte +0xa
    or ax,ax
    jz .label16 ; ↓
    mov word [bp-0x8],0x0
    mov bx,[GameStatePtr]
    cmp word [bx+CloneListLen],byte +0x0
    jg .label14 ; ↓
    jmp .nextField ; ↓
.label14: ; 862
    mov [data],si
    mov word [bp-0x4],0x0
.label15: ; 86a
    les bx,[bx+CloneListPtr]
    mov si,[bp-0x4]
    mov ax,[bp-0x6]
    lea di,[bx+si]
    mov si,ax
    movsw
    movsw
    movsw
    movsw
    add word [bp-0x4],byte +0x8
    add word [bp-0x6],byte +0x8
    inc word [bp-0x8]
    mov ax,[bp-0x8]
    mov bx,[GameStatePtr]
    cmp [bx+CloneListLen],ax
    jg .label15 ; ↑
    jmp .label10 ; ↑
    nop
.label16: ; 898
    mov bx,[GameStatePtr]
    mov word [bx+CloneListLen],0x0
    jmp .nextField ; ↓
    nop
.field.password: ; 8a6
    cmp byte [bp-0x9],MaxPasswordLength
    jna .label18 ; ↓
    mov byte [si+MaxPasswordLength-1],0x0
.label18: ; 8b0
    mov ax,[GameStatePtr]
    add ax,LevelPassword
    push ds
    push ax
    push ds
    push si
    call far KERNEL.lstrcpy ; 8ba
    mov ax,[GameStatePtr]
    add ax,LevelPassword
    push ax
    call far DecodePassword ; 8c6 4:6b0
    add sp,byte +0x2
    jmp short .nextField ; ↓
.field.hint: ; 8d0
    cmp byte [bp-0x9],MaxHintLength
    jna .label20 ; ↓
    mov byte [si+MaxHintLength-1],0x0
.label20: ; 8da
    mov ax,[GameStatePtr]
    add ax,LevelHint
    jmp .label5 ; ↑
    nop
.field.plaintextPassword: ; 8e4
    cmp byte [bp-0x9],MaxPasswordLength
    jna .label22 ; ↓
    mov byte [si+MaxPasswordLength-1],0x0
.label22: ; 8ee
    mov ax,[GameStatePtr]
    add ax,LevelPassword
    jmp .label5 ; ↑
    nop
.field.monsters: ; 8f8
    mov di,si
    mov al,[bp-0x9]
    shr al,1
    sub ah,ah
    mov bx,[GameStatePtr]
    mov [bx+InitialMonsterListLen],ax
    xor dx,dx
    mov bx,[GameStatePtr]
    cmp [bx+InitialMonsterListLen],dx
    jng .nextField ; ↓
    mov [data],si
    xor bx,bx
.label24: ; 91a
    mov ax,[di]
    mov si,[GameStatePtr]
    mov [bx+si+InitialMonsterList],ax
    add bx,byte +0x2
    add di,byte +0x2
    inc dx
    mov si,[GameStatePtr]
    cmp [si+InitialMonsterListLen],dx
    jg .label24 ; ↑
    jmp .label10 ; ↑
.nextField: ; 938
    mov al,[bp-0x9]
    sub ah,ah
    add si,ax
    cmp si,[bp-0xc]
    jnb .label26 ; ↓
    jmp .label0 ; ↑
.label26: ; 947
    pop si
    pop di
endfunc

; 950

; checks the signature of a file
; and returns the next word (number of levels)
func FUN_4_0950
    %arg hFile:word
    sub sp,byte +0x4
    push si
    mov si,[hFile]
    push si
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; 969
    cmp ax,0x2
    jnb .label1 ; ↓
.label0: ; 973
    xor ax,ax
    jmp short .label2 ; ↓
    nop
.label1: ; 978
    cmp word [bp-0x4],0xaaac
    jnz .label0 ; ↑
    push si
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; 987
    cmp ax,0x2
    jb .label0 ; ↑
    cmp word [bp-0x4],byte +0x2
    jnz .label0 ; ↑
    push si
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; 99f
    cmp ax,0x2
    jb .label0 ; ↑
    mov ax,[bp-0x4]
.label2: ; 9ac
    pop si
endfunc

; 9b4

; Skips some number of length-prefixed chunks in a file.
; This is essentially FindLevelN
func SkipNFields
    %arg hFile:word, num:word
    %local size:word
    sub sp,byte +0x4
    push di
    push si
    mov di,0x1
    cmp [num],di
    jng .return1 ; ↓
    mov si,[hFile]
.loop: ; 9ce
    push si
    lea ax,[size]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; 9d6
    cmp ax,0x2
    jb .return0 ; ↓
    push si
    push byte +0x0
    push word [size]
    push byte +0x1 ; SEEK_CUR
    call far KERNEL._llseek ; 9e8
    cmp ax,-1
    jnz .label1 ; ↓
    cmp dx,ax
    jz .return0 ; ↓
.label1: ; 9f6
    inc di
    cmp di,[num]
    jl .loop ; ↑
    jmp short .return1 ; ↓
.return0: ; 9fe
    xor ax,ax
    jmp short .end ; ↓
.return1: ; a02
    mov ax,0x1
.end: ; a05
    pop si
    pop di
endfunc

; a0e

; opens chips.dat and checks the signature
; and returns the number of levels
func FUN_4_0a0e
    sub sp,0x8a
    push di
    push si
    push ds
    push word DataFileName ; "CHIPS.DAT"
    lea ax,[bp-0x8a]
    push ss
    push ax
    push byte +0x0
    call far KERNEL.OpenFile ; a2a
    mov di,ax
    cmp di,byte -0x1
    jnz .label0 ; ↓
    xor ax,ax
    jmp short .label1 ; ↓
.label0: ; a3a
    push di
    call far FUN_4_0950 ; a3b 4:950
    add sp,byte +0x2
    mov si,ax
    push di
    call far KERNEL._lclose ; a46
    mov ax,si
.label1: ; a4d
    pop si
    pop di
endfunc

; a56

func ReadLevelData
    %arg levelNum:word, farFileName:dword
    sub sp,0x490
    push di
    push si
    push word [farFileName+FarPtr.Seg]
    push word [farFileName+FarPtr.Off]
    lea ax,[bp-0x90]
    push ss
    push ax
    push byte +0x20
    call far KERNEL.OpenFile ; a74
    mov [bp-0x4],ax
    inc ax
    jnz .label0 ; ↓
    jmp .label14 ; ↓
.label0: ; a82
    push word [bp-0x4]
    call far FUN_4_0950 ; a85 4:950
    add sp,byte +0x2
    mov si,ax
    mov bx,[GameStatePtr]
    mov [bx+NumLevelsInSet],si
    or si,si
    jnz .label1 ; ↓
    jmp .label13 ; ↓
.label1: ; a9e
    mov di,[levelNum]
    cmp si,di
    jnb .label2 ; ↓
    jmp .label13 ; ↓
.label2: ; aa8
    push di
    push word [bp-0x4]
    call far SkipNFields ; aac 4:9b4
    add sp,byte +0x4
    or ax,ax
    jnz .label3 ; ↓
    jmp .label13 ; ↓
.label3: ; abb
    push word [bp-0x4]
    lea ax,[bp-0x6]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; ac5
    cmp ax,0x2
    jnb .label4 ; ↓
    jmp .label13 ; ↓
.label4: ; ad2
    push word [bp-0x4]
    lea ax,[bp-0x6]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; adc
    cmp ax,0x2
    jnb .label5 ; ↓
    jmp .label13 ; ↓
.label5: ; ae9
    cmp di,[bp-0x6]
    jz .label6 ; ↓
    jmp .label13 ; ↓
.label6: ; af1
    push word [bp-0x4]
    mov ax,[GameStatePtr]
    add ax,InitialTimeLimit
    push ds
    push ax
    push byte +0x2
    call far KERNEL._lread ; afe
    cmp ax,0x2
    jnb .label7 ; ↓
    jmp .label13 ; ↓
.label7: ; b0b
    push word [bp-0x4]
    mov ax,[GameStatePtr]
    add ax,InitialChipsRemainingCount
    push ds
    push ax
    push byte +0x2
    call far KERNEL._lread ; b18
    cmp ax,0x2
    jnb .label8 ; ↓
    jmp .label13 ; ↓
.label8: ; b25
    push word [bp-0x4]
    lea ax,[bp-0x8]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; b2f
    cmp ax,0x2
    jnb .label9 ; ↓
    jmp .label13 ; ↓
.label9: ; b3c
    cmp word [bp-0x8],byte +0x0
    jz .label10 ; ↓
    cmp word [bp-0x8],byte +0x1
    jz .label10 ; ↓
    jmp .label13 ; ↓
.label10: ; b4b
    push word [bp-0x4]
    lea ax,[bp-0x6]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; b55
    cmp ax,0x2
    jnb .label11 ; ↓
    jmp .label13 ; ↓
.label11: ; b62
    push word [bp-0x4]
    lea ax,[bp-0x490]
    push ss
    push ax
    push word [bp-0x6]
    call far KERNEL._lread ; b6e
    cmp ax,[bp-0x6]
    jnb .label12 ; ↓
    jmp .label13 ; ↓
.label12: ; b7b
    push byte +0x20
    push byte +0x20
    push word [GameStatePtr]
    push word [bp-0x8]
    push word [bp-0x6]
    lea ax,[bp-0x490]
    push ax
    call far ExpandTilesRLE ; b8e 4:5fc
    add sp,byte +0xc
    push word [bp-0x4]
    lea ax,[bp-0x6]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; ba0
    cmp ax,0x2
    jb .label13 ; ↓
    push word [bp-0x4]
    lea ax,[bp-0x490]
    push ss
    push ax
    push word [bp-0x6]
    call far KERNEL._lread ; bb6
    cmp ax,[bp-0x6]
    jb .label13 ; ↓
    push byte +0x20
    push byte +0x20
    mov ax,[GameStatePtr]
    add ah,Lower>>8
    push ax
    push word [bp-0x8]
    push word [bp-0x6]
    lea ax,[bp-0x490]
    push ax
    call far ExpandTilesRLE ; bd6 4:5fc
    add sp,byte +0xc
    push word [bp-0x4]
    lea ax,[bp-0x6]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; be8
    cmp ax,0x2
    jb .label13 ; ↓
    push word [bp-0x4]
    lea ax,[bp-0x490]
    push ss
    push ax
    push word [bp-0x6]
    call far KERNEL._lread ; bfe
    cmp ax,[bp-0x6]
    jb .label13 ; ↓
    push word [bp-0x6]
    lea ax,[bp-0x490]
    push ax
    call far DecodeLevelFields ; c10 4:6d8
    add sp,byte +0x4
    push word [bp-0x4]
    call far KERNEL._lclose ; c1b
    mov ax,0x1
    jmp short .label15 ; ↓
    nop
.label13: ; c26
    push word [bp-0x4]
    call far KERNEL._lclose ; c29
.label14: ; c2e
    xor ax,ax
.label15: ; c30
    pop si
    pop di
endfunc

; c3a

; Read a level's optional fields
; Precondition: file is positioned at the start of a level
func ReadLevelFields
    %arg hFile:word, levelNum:word, fieldData:word, fieldSizePtr:word
    %local local_4:word
    sub sp,byte +0x4
    ; read a word - the level size
    push word [hFile]
    lea ax,[local_4]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; c51
    cmp ax,0x2
    jnb .label0 ; ↓
    jmp .error ; ↓
.label0: ; c5e
    ; read the next word - the level number
    push word [hFile]
    lea ax,[local_4]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; c68
    cmp ax,0x2
    jnb .label1 ; ↓
    jmp .error ; ↓
.label1: ; c75
    ; check that the level number is what we expected
    mov ax,[levelNum]
    cmp [local_4],ax
    jz .label2 ; ↓
    jmp .error ; ↓
.label2: ; c80
    ; read & discard 2 words - the time limit & chip count
    push word [hFile]
    lea ax,[local_4]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; c8a
    cmp ax,0x2
    jnb .label3 ; ↓
    jmp .error ; ↓
.label3: ; c97
    push word [hFile]
    lea ax,[local_4]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; ca1
    cmp ax,0x2
    jnb .label4 ; ↓
    jmp .error ; ↓
.label4: ; cae
    ; read the map word
    push word [hFile]
    lea ax,[local_4]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; cb8
    cmp ax,0x2
    jnb .label5 ; ↓
    jmp .error ; ↓
.label5: ; cc5
    ; check that it equals 0 or 1
    cmp word [local_4],byte +0x0
    jz .label6 ; ↓
    cmp word [local_4],byte +0x1
    jnz .error ; ↓
.label6: ; cd1
    ; skip the map layers
    ; read a word and skip that many bytes
    push word [hFile]
    lea ax,[local_4]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; cdb
    cmp ax,0x2
    jb .error ; ↓
    push word [hFile]
    push byte +0x0
    push word [local_4]
    push byte +0x1
    call far KERNEL._llseek ; cef
    ; read a word and skip that many bytes (again)
    push word [hFile]
    lea ax,[local_4]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; cfe
    cmp ax,0x2
    jb .error ; ↓
    push word [hFile]
    push byte +0x0
    push word [local_4]
    push byte +0x1
    call far KERNEL._llseek ; d12
    ; finally! the optional fields
    ; (read a word and then read that many bytes into fieldData)
    push word [hFile]
    lea ax,[local_4]
    push ss
    push ax
    push byte +0x2
    call far KERNEL._lread ; d21
    cmp ax,0x2
    jb .error ; ↓
    push word [hFile]
    push ds
    push word [fieldData]
    push word [local_4]
    call far KERNEL._lread ; d35
    cmp ax,[local_4]
    jb .error ; ↓
    ; store number of bytes in *fieldSizePtr
    mov ax,[local_4]
    mov bx,[fieldSizePtr]
    mov [bx],ax
    ; success! return 1
    mov ax,0x1
    jmp short .end ; ↓
    nop
    nop
.error: ; d4e
    xor ax,ax
.end: ; d50
endfunc

; d58

; Get a password from CHIPS.DAT
func GetLevelPassword
    %arg levelNum:word, passwordDest:word
    sub sp,0x222
    push di
    push si
    ; open CHIPS.DAT
    push ds
    push word DataFileName ; "CHIPS.DAT"
    lea ax,[bp-0x92]
    push ss
    push ax
    push byte +0x20
    call far KERNEL.OpenFile ; d74
    mov di,ax
    cmp di,byte -0x1
    jnz .label0 ; ↓
    jmp .error ; ↓
.label0: ; d83
    ; read signature & level count
    push di
    call far FUN_4_0950 ; d84 4:950
    add sp,byte +0x2
    mov si,ax
    or si,si
    jnz .label1 ; ↓
    jmp .cleanup ; ↓
.label1: ; d95
    ; check that our level number isn't too large
    cmp si,[levelNum]
    jnb .label2 ; ↓
    jmp .cleanup ; ↓
.label2: ; d9d
    ; find level
    push word [levelNum]
    push di
    call far SkipNFields ; da1 4:9b4
    add sp,byte +0x4
    or ax,ax
    jnz .label3 ; ↓
    jmp .cleanup ; ↓
.label3: ; db0
    ; read its fields
    mov word [bp-0xa],0x190
    lea ax,[bp-0xa]
    push ax
    lea ax,[bp-0x222]
    push ax
    push word [levelNum]
    push di
    call far ReadLevelFields ; dc2 4:c3a
    add sp,byte +0x8
    or ax,ax
    jz .cleanup ; ↓
    ; search for password field
    mov si,[bp-0xa]
    lea dx,[bp-0x222+si]
    lea si,[bp-0x222]
    cmp dx,si
    jna .cleanup ; ↓
    mov [bp-0x6],dx
    mov [bp-0x8],di
.loop: ; de3
    lodsb
    mov [bp-0x3],al
    lodsb
    mov [bp-0x4],al
    cmp byte [bp-0x3],0x6
    jz .label5 ; ↓
    cmp byte [bp-0x3],0x8
    jz .label5 ; ↓
    sub ah,ah
    add si,ax
    cmp si,dx
    jb .loop ; ↑
    jmp short .cleanup ; ↓
    nop
.label5: ; e02
    cmp byte [bp-0x4],0xa
    jna .label6 ; ↓
    mov byte [si+0x9],0x0
.label6: ; e0c
    push ds
    push word [passwordDest]
    push ds
    push si
    call far KERNEL.lstrcpy ; e12
    cmp byte [bp-0x3],0x8
    jz .label7 ; ↓
    push word [passwordDest]
    call far DecodePassword ; e20 4:6b0
    add sp,byte +0x2
.label7: ; e28
    push word [bp-0x8]
    call far KERNEL._lclose ; e2b
    mov ax,0x1
    jmp short .label10 ; ↓
    nop
.cleanup: ; e36
    push di
    call far KERNEL._lclose ; e37
.error: ; e3c
    xor ax,ax
.label10: ; e3e
    pop si
    pop di
endfunc

; e48

; Check password in INI file
; returns 1 if the password is okay,
; or 0 if there was a problem
func TryIniPassword
    %arg levelNum:word
    sub sp,0x82
    push si
    mov si,[levelNum]
    cmp si,byte +0x1
    jng .return1 ; ↓
    push byte +0x0
    push byte +0x0
    lea ax,[bp-0x42]
    push ax
    push si
    call far GetLevelProgressFromIni ; e68 2:1adc
    add sp,byte +0x8
    or ax,ax
    jz .return0 ; ↓
    lea ax,[bp-0x82]
    push ax
    push si
    call far GetLevelPassword ; e7a 4:d58
    add sp,byte +0x4
    or ax,ax
    jz .return0 ; ↓
    lea ax,[bp-0x42]
    push ss
    push ax
    lea ax,[bp-0x82]
    push ss
    push ax
    call far USER.lstrcmpi ; e91
    or ax,ax
    jz .return1 ; ↓
.return0: ; e9a
    xor ax,ax
    jmp short .label2 ; ↓
.return1: ; e9e
    mov ax,0x1
.label2: ; ea1
    pop si
endfunc

; eaa

; check password for a level
; level number may be 0 in which case we search
; for a level with a matching password
; Called by GOTOLEVELMSGPROC
func FUN_4_0eaa
    %arg levelNumPtr:word, password:word
    sub sp,0x23e
    push di
    push si
    mov di,[levelNumPtr]
    ; get number of levels
    call far FUN_4_0a0e ; ebd 4:a0e
    mov [bp-0xe],ax
    cmp word [di],byte +0x0
    jz .label3 ; ↓
    cmp word [di],byte +0x1
    jnz .label1 ; ↓
.label0: ; ecf
    mov ax,0x1
    jmp .label18 ; ↓
    nop
.label1: ; ed6
    push byte +0x0
    push byte +0x0
    lea ax,[bp-0x1a]
    push ax
    push word [di]
    call far GetLevelProgressFromIni ; ee0 2:1adc
    add sp,byte +0x8
    or ax,ax
    jnz .label0 ; ↑
    ; get level password
    lea ax,[bp-0x26]
    push ax
    push word [di]
    call far GetLevelPassword ; ef2 4:d58
    add sp,byte +0x4
    or ax,ax
    jnz .label2 ; ↓
    jmp .label17 ; ↓
.label2: ; f01
    ; check password
    push ds
    push word [password]
    lea ax,[bp-0x26]
    push ss
    push ax
    call far USER.lstrcmpi ; f0a
    or ax,ax
    jz .label0 ; ↑
    jmp .label17 ; ↓
.label3: ; f16
    ; same, but this time we don't know the level number
    push ds
    push word DataFileName ; "CHIPS.DAT"
    lea ax,[bp-0xae]
    push ss
    push ax
    push byte +0x20
    call far KERNEL.OpenFile ; f22
    mov [bp-0xa],ax
    inc ax
    jnz .label4 ; ↓
    jmp .label17 ; ↓
.label4: ; f30
    push word [bp-0xa]
    call far FUN_4_0950 ; f33 4:950
    add sp,byte +0x2
    or ax,ax
    jnz .label5 ; ↓
    jmp .label16 ; ↓
.label5: ; f42
    mov word [bp-0x8],0x1
    cmp word [bp-0xe],byte +0x1
    jnl .label6 ; ↓
    jmp .label16 ; ↓
.label6: ; f50
    mov word [bp-0xc],0x190
    lea ax,[bp-0xc]
    push ax
    lea ax,[bp-0x23e]
    push ax
    push word [bp-0x8]
    push word [bp-0xa]
    call far ReadLevelFields ; f64 4:c3a
    add sp,byte +0x8
    or ax,ax
    jnz .label7 ; ↓
    jmp .label16 ; ↓
.label7: ; f73
    mov si,[bp-0xc]
    lea di,[bp-0x23e+si]
    lea si,[bp-0x23e]
    cmp di,si
    jna .label13 ; ↓
    mov [bp-0x6],di
.label8: ; f85
    lodsb
    mov [bp-0x3],al
    lodsb
    mov [bp-0x4],al
    cmp byte [bp-0x3],0x6 ; password field
    jz .label9 ; ↓
    cmp byte [bp-0x3],0x8 ; plaintext password field
    jnz .label12 ; ↓
.label9: ; f99
    cmp byte [bp-0x4],MaxPasswordLength ; length
    jna .label10 ; ↓
    mov byte [si+MaxPasswordLength-1],0x0
.label10: ; fa3
    lea ax,[bp-0x26]
    push ss
    push ax
    push ds
    push si
    call far KERNEL.lstrcpy ; faa
    cmp byte [bp-0x3],0x8
    jz .label11 ; ↓
    lea ax,[bp-0x26]
    push ax
    call far DecodePassword ; fb9 4:6b0
    add sp,byte +0x2
.label11: ; fc1
    push ds
    push word [password]
    lea ax,[bp-0x26]
    push ss
    push ax
    call far USER.lstrcmpi ; fca
    or ax,ax
    jz .label15 ; ↓
.label12: ; fd3
    mov al,[bp-0x4]
    sub ah,ah
    add si,ax
    cmp si,di
    jb .label8 ; ↑
.label13: ; fde
    mov ax,[bp-0xe]
    inc word [bp-0x8]
    cmp [bp-0x8],ax
    jg .label14 ; ↓
    jmp .label6 ; ↑
.label14: ; fec
    jmp short .label16 ; ↓
.label15: ; fee
    push word [bp-0xa]
    call far KERNEL._lclose ; ff1
    mov ax,[bp-0x8]
    mov bx,[levelNumPtr]
    mov [bx],ax
    jmp .label0 ; ↑
    nop
.label16: ; 1002
    push word [bp-0xa]
    call far KERNEL._lclose ; 1005
.label17: ; 100a
    xor ax,ax
.label18: ; 100c
    pop si
    pop di
endfunc

; 1016

func PASSWORDMSGPROC
    %assign %$argsize 0xa
    sub sp,byte +0x4c
    push si
    mov ax,[bp+0xc]
    sub ax,0xf
    jz .label0 ; ↓
    dec ax
    jz .label1 ; ↓
    sub ax,0x9
    jz .label0 ; ↓
    sub ax,0xf7
    jz .label2 ; ↓
    dec ax
    jz .label3 ; ↓
    xor ax,ax
    jmp .label12 ; ↓
    nop
.label0: ; 1042
    push word [bp+0xe]
    push word [bp+0xc]
    push word [bp+0xa]
    push word [bp+0x8]
    push word [bp+0x6]
    call far WEP4UTIL.GRAYDLGPROC ; 1051
    jmp .label12 ; ↓
    nop
.label1: ; 105a
    push word [bp+0xe]
    push word 0x111
    push byte +0x2
    push byte +0x0
    push byte +0x0
    call far USER.PostMessage ; 1066
    jmp .label11 ; ↓
.label2: ; 106e
    mov si,[bp+0xe]
    push si
    call far WEP4UTIL.CENTERHWND ; 1072
    push word [PasswordPromptLevel]
    push ds
    push word PasswordPromptMessage
    lea ax,[bp-0x4c]
    push ss
    push ax
    call far USER._wsprintf ; 1084
    add sp,byte +0xa
    push si
    push byte +0x64
    lea ax,[bp-0x4c]
    push ss
    push ax
    call far USER.SetDlgItemText ; 1094
    jmp .label11 ; ↓
.label3: ; 109c
    mov ax,[bp+0xa]
    dec ax
    jz .label5 ; ↓
    dec ax
    jnz .label4 ; ↓
    jmp .label9 ; ↓
.label4: ; 10a8
    jmp .label11 ; ↓
    nop
.label5: ; 10ac
    mov si,[bp+0xe]
    push si
    push byte +0x65
    lea ax,[bp-0xc]
    push ss
    push ax
    push byte +0xa
    call far USER.GetDlgItemText ; 10b9
    lea ax,[bp-0xc]
    push ss
    push ax
    push ds
    push word [PasswordPromptPassword]
    call far USER.lstrcmpi ; 10c8
    or ax,ax
    jz .label8 ; ↓
    cmp byte [bp-0xc],0x0
    jz .label6 ; ↓
    lea ax,[bp-0xc]
    push ss
    push ax
    push ds
    push word WrongPasswordMessage
    lea ax,[bp-0x4c]
    push ss
    push ax
    call far USER._wsprintf ; 10e5
    add sp,byte +0xc
    jmp short .label7 ; ↓
    nop
.label6: ; 10f0
    push ds
    push word EmptyPasswordMessage
    lea ax,[bp-0x4c]
    push ss
    push ax
    call far USER._wsprintf ; 10f9
    add sp,byte +0x8
.label7: ; 1101
    push byte +0x10
    lea ax,[bp-0x4c]
    push ss
    push ax
    push si
    call far ShowMessageBox ; 1109 2:0
    add sp,byte +0x8
    push si
    push byte +0x65
    call far USER.GetDlgItem ; 1114
    push ax
    call far USER.SetFocus ; 111a
    push si
    push byte +0x65
    push word 0x401
    push byte +0x0
    push byte -0x1
    push byte +0x0
    call far USER.SendDlgItemMessage ; 112b
    jmp short .label11 ; ↓
.label8: ; 1132
    mov word [PasswordPromptLevel],0x1
    push si
    push byte +0x1
    jmp short .label10 ; ↓
    nop
.label9: ; 113e
    mov word [PasswordPromptLevel],0x0
    push word [bp+0xe]
    push byte +0x0
.label10: ; 1149
    call far USER.EndDialog ; 1149
.label11: ; 114e
    mov ax,0x1
.label12: ; 1151
    pop si
endfunc

; 115c

; Go to next level, possibly asking for a password
; Called by GOTOLEVELMSGPROC
func FUN_4_115c
    %arg hWnd:word, levelNum:word
    sub sp,byte +0x12
    push di
    push si
    mov si,[levelNum]
    mov bx,[GameStatePtr]
    mov ax,[bx+LevelNumber]
    mov [bp-0x12],ax
    cmp ax,si
    jz .label2 ; ↓
    cmp word [IgnorePasswords],byte +0x0
    jz .label0 ; ↓
    cmp ax,FakeLastLevel+1 ; Thanks to...
    jnz .label2 ; ↓
.label0: ; 1189
    push si
    call far TryIniPassword ; 118a 4:e48
    add sp,byte +0x2
    or ax,ax
    jnz .label2 ; ↓
    call far PauseGame ; 1196 2:17da
    lea ax,[bp-0x10]
    push ax
    push word [bp+0x8]
    call far GetLevelPassword ; 11a2 4:d58
    add sp,byte +0x4
    or ax,ax
    jz .label1 ; ↓
    mov ax,[bp+0x8]
    mov [PasswordPromptLevel],ax
    lea ax,[bp-0x10]
    mov [PasswordPromptPassword],ax
    push word SEG PASSWORDMSGPROC
    push word PASSWORDMSGPROC
    push word [OurHInstance]
    call far KERNEL.MakeProcInstance ; 11c4
    mov di,ax
    mov [bp-0x4],dx
    push word [OurHInstance]
    push ds
    push word s_DLG_PASSWORD
    push word [hWnd]
    mov ax,dx
    push ax
    push di
    mov si,dx
    call far USER.DialogBox ; 11df
    push si
    push di
    call far KERNEL.FreeProcInstance ; 11e6
    call far UnpauseGame ; 11eb 2:1834
    mov ax,[PasswordPromptLevel]
    jmp short .label3 ; ↓
    nop
.label1: ; 11f6
    call far UnpauseGame ; 11f6 2:1834
.label2: ; 11fb
    mov ax,0x1
.label3: ; 11fe
    pop si
    pop di
endfunc

; 1208

GLOBAL _segment_4_size
_segment_4_size equ $ - $$

; vim: syntax=nasm

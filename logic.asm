SEGMENT CODE ; 3

; Game logic
; (Mostly monsters so far)

%include "constants.asm"

GameStatePtr    equ 0x1680

; Game state offsets

Upper               equ 0x0
Lower               equ 0x400

ChipX               equ 0x808
ChipY               equ 0x80a

Autopsy             equ 0x816

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

%macro  func 1
    global %1
%1:
    %push func
    %stacksize small
    ; Standard function prologue
    ; See http://blogs.msdn.com/b/oldnewthing/archive/2011/03/16/10141735.aspx
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
%endmacro

%macro endfunc 0
    pop ds
    pop bp
    dec bp
    retf
    align 2
    %pop func
%endmacro

; 0

; FindMonster returns the index of the monster at (x, y),
; or -1.
func FindMonster
    sub sp,byte +0x2
    push di
    push si

    %arg x:word, y:word

    xor cx,cx
    mov bx,[GameStatePtr]
    cmp [bx+MonsterListLen],cx
    jng .notfound

    ; Initialize es:bx to point to the first monster
    ; on the monster list
    mov si,bx
    mov ax,[si+MonsterListPtr]
    mov dx,[si+MonsterListSeg]
    inc ax
    mov bx,ax
    mov es,dx
    mov di,[x]
.loop:
    ; if monster.x == x and monster.y == y
    ;   goto found
    cmp [es:bx+Monster.x-1],di
    jnz .next
    mov ax,[y]
    cmp [es:bx+Monster.y-1],ax
    jz .found
.next:
    add bx,byte +0xB
    inc cx
    cmp [si+MonsterListLen],cx
    jg .loop
    jmp short .notfound
    nop
.found:
    mov ax,cx
    jmp short .end
.notfound:
    mov ax,-1
.end:
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 58

; Same as above, but searches a different array.
func FindSomething
    sub sp,byte +0x2
    push di
    push si

    %arg x:word, y:word

    xor cx,cx
    mov bx,[GameStatePtr]
    cmp [bx+SlipListLen],cx
    jng .notfound
    mov si,bx
    mov ax,[si+SlipListPtr]
    mov dx,[si+SlipListSeg]
    inc ax
    mov bx,ax
    mov es,dx
    mov di,[x]
.loop:
    cmp [es:bx+Monster.x-1],di
    jnz .next
    mov ax,[y]
    cmp [es:bx+Monster.y-1],ax
    jz .found
.next:
    add bx,byte +0xb
    inc cx
    cmp [si+SlipListLen],cx
    jg .loop
    jmp short .notfound
    nop
.found:
    mov ax,cx
    jmp short .end
.notfound:
    mov ax,-1
.end:
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; b0
func TurnLeft
    sub sp,byte +0x2

    ;    x  y  ->  x  y
    ; W -1  0  ->  0  1  S
    ; N  0 -1  -> -1  0  W
    ; S  0  1  ->  1  0  E
    ; E  1  0  ->  0 -1  N

    %arg x:word, y:word, xOut:word, yOut:word

    ; ax = x<<1 + y
    mov ax,[x]
    shl ax,1
    add ax,[y]

    inc ax
    inc ax
    jz .west ; -2
    dec ax
    jz .north ; -1
    dec ax
    dec ax
    jz .south ; +1
    dec ax
    jz .east ; +2
    jmp short .end
    nop
.west:
    mov bx,[xOut]
    mov word [bx],0
    mov bx,[yOut]
    mov word [bx],1
    jmp short .end
.north:
    mov bx,[xOut]
    mov word [bx],-1
.setYOutToZero:
    mov bx,[yOut]
    mov word [bx],0
    jmp short .end
.south:
    mov bx,[xOut]
    mov word [bx],1
    jmp short .setYOutToZero
    nop
.east:
    mov bx,[xOut]
    mov word [bx],0
    mov bx,[yOut]
    mov word [bx],-1
.end:
    lea sp,[bp-0x2]
endfunc

; 116
func TurnRight
    sub sp,byte +0x2

    ;    x  y  ->  x  y
    ; W -1  0  ->  0 -1  N
    ; N  0 -1  ->  1  0  E
    ; S  0  1  -> -1  0  W
    ; E  1  0  ->  0  1  S

    %arg x:word, y:word, xOut:word, yOut:word

    mov ax,[x]
    shl ax,1
    add ax,[y]
    inc ax
    inc ax
    jz .west
    dec ax
    jz .north
    dec ax
    dec ax
    jz .south
    dec ax
    jz .east
    jmp short .end
    nop
.west:
    mov bx,[xOut]
    mov word [bx],0
    mov bx,[yOut]
    mov word [bx],-1
    jmp short .end
.north:
    mov bx,[xOut]
    mov word [bx],1
.setYOutToZero:
    mov bx,[yOut]
    mov word [bx],0
    jmp short .end
.south:
    mov bx,[xOut]
    mov word [bx],-1
    jmp short .setYOutToZero
    nop
.east:
    mov bx,[xOut]
    mov word [bx],0
    mov bx,[yOut]
    mov word [bx],1
.end:
    lea sp,[bp-0x2]
endfunc

; 17c
func TurnAround
    sub sp,byte +0x2

    ;    x  y  ->  x  y
    ; W -1  0  ->  1  0  E
    ; N  0 -1  ->  0  1  S
    ; S  0  1  ->  0 -1  N
    ; E  1  0  -> -1  0  W

    %arg x:word, y:word, xOut:word, yOut:word

    ; *xOut = -x
    mov ax,[x]
    neg ax
    mov bx,[xOut]
    mov [bx],ax

    ; *yOut = -y
    mov ax,[y]
    neg ax
    mov bx,[yOut]
    mov [bx],ax

    lea sp,[bp-0x2]
endfunc

; 1a4
func GrowArray
    sub sp,byte +0x2
    push si

    %arg hMem:word, ptr:word, lenPtr:word, numToAlloc:word, size:word
    ; ptr is a NEAR*FAR*

    mov bx,[hMem]
    cmp word [bx],byte +0x0
    jz .globalAlloc
    push word [bx]
    call word 0x0:0xffff ; 1bc KERNEL.GlobalUnlock
    mov bx,[hMem]
    push word [bx]
    ; Compute (*len + numToAlloc) * size
    mov bx,[lenPtr]
    mov ax,[bx]
    add ax,[numToAlloc]
    imul word [size]
    cwd
    push dx         ; dwBytes
    push ax
    push byte +0x2  ; GMEM_MOVABLE
    call word 0x0:0xffff ; 1d6 KERNEL.GlobalReAlloc
    jmp short .lock
    nop
.globalAlloc: ; 1de
    push byte +0x42 ; GHND
    ; size * numToAlloc
    mov ax,[size]
    imul word [numToAlloc]
    cwd
    push dx         ; dwBytes
    push ax
    call word 0x0:0xffff ; 1e9 KERNEL.GlobalAlloc

.lock: ; 1ee
    ; update hMem
    ; and call GlobalLock to get a pointer
    ; to the allocated memory
    mov si,ax
    or si,si
    jz .noupdate
    mov bx,[hMem]
    mov [bx],si
.noupdate: ; 1f9
    mov bx,[hMem]
    push word [bx]
    call word 0x0:0xffff ; 1fe KERNEL.GlobalLock
    mov bx,[ptr]
    mov [bx],ax
    mov [bx+0x2],dx

    or si,si
    jnz .success
    ; GlobalAlloc/ReAlloc failed, return 0
    xor ax,ax
    jmp short .end
    nop

.success: ; 214
    ; lenPtr += numToAlloc
    ; return 1
    mov ax,[numToAlloc]
    mov bx,[lenPtr]
    add [bx],ax
    mov ax,1

.end: ; 21f
    pop si
    lea sp,[bp-0x2]
endfunc

; 228
func NewMonster
    %arg tile:byte, x:word, y:word, xdir:word, ydir:word, cloning:word
    %define pos (bp-6)
    %define lowerTile (bp-3)

    sub sp,byte +0x6
    push si

    ; Grow monster list if necessary.
    mov bx,[GameStatePtr]
    mov ax,[bx+MonsterListCap]
    cmp [bx+MonsterListLen],ax
    jl .longEnough
    push byte +0xb
    push byte +0x10
    mov ax,bx
    add ax,MonsterListCap
    push ax
    mov ax,bx
    add ax,MonsterListPtr
    push ax
    mov ax,bx
    add ax,MonsterListHandle
    push ax
    call word 0x383:0x1a4 ; 25a GrowArray
    add sp,byte +0xa
    or ax,ax
    jnz .growSucceeded
    jmp word .end

.longEnough: ; 269
.growSucceeded:
    ; pos = y*32 + x
    mov si,[y]
    shl si,byte 0x5
    add si,[x]
    mov [pos],si

    ; Get tile under the monster
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [lowerTile],al

    ; Return if not cloning and the lower tile is a clone machine
    ;
    ; In other words: during initialization,
    ; don't add monsters on clone machines
    ; to the monster list.
    cmp word [cloning],byte +0x0
    jnz .notOnACloneMachine
    cmp al,CloneMachine
    jnz .notOnACloneMachine
    jmp word .end

.notOnACloneMachine: ; 28d
    ; monster.tile = lowerTile
    mov al,[tile]
    les si,[bx+MonsterListPtr]
    mov bx,[bx+MonsterListLen]
    mov cx,bx
    shl bx,byte 0x2
    add bx,cx
    shl bx,1
    add bx,cx
    mov [es:bx+si+Monster.tile],al

    ; monster.x = x
    mov cx,[x]
    mov bx,[GameStatePtr]
    mov si,[bx+MonsterListLen]
    mov dx,si
    shl si,byte 0x2
    add si,dx
    shl si,1
    add si,dx
    les bx,[bx+MonsterListPtr]
    mov [es:bx+si+Monster.x],cx

    ; monster.y = y
    mov cx,[y]
    mov bx,[GameStatePtr]
    mov si,[bx+MonsterListLen]
    mov dx,si
    shl si,byte 0x2
    add si,dx
    shl si,1
    add si,dx
    les bx,[bx+MonsterListPtr]
    mov [es:bx+si+Monster.y],cx

    ; monster.xdir = xdir
    mov cx,[xdir]
    mov bx,[GameStatePtr]
    mov si,[bx+MonsterListLen]
    mov dx,si
    shl si,byte 0x2
    add si,dx
    shl si,1
    add si,dx
    les bx,[bx+MonsterListPtr]
    mov [es:bx+si+Monster.xdir],cx
    ; monster.ydir = ydir
    mov cx,[ydir]
    mov bx,[GameStatePtr]
    mov si,[bx+MonsterListLen]
    mov dx,si
    shl si,byte 0x2
    add si,dx
    shl si,1
    add si,dx
    les bx,[bx+MonsterListPtr]
    mov [es:bx+si+Monster.ydir],cx
    ; monster.slipping = 0
    mov bx,[GameStatePtr]
    mov si,[bx+MonsterListLen]
    mov cx,si
    shl si,byte 0x2
    add si,cx
    shl si,1
    add si,cx
    les bx,[bx+MonsterListPtr]
    mov word [es:bx+si+Monster.slipping],0x0

    ; If tile is not the upper tile at pos...
    mov bx,[pos]
    mov si,[GameStatePtr]
    cmp [bx+si+Upper],al
    jz .sameTile
    ; ...push the upper tile down
    mov al,[bx+si+Upper]
    add bx,si
    mov [bx+Lower],al
    mov bx,[pos]
    add bx,[GameStatePtr]
    mov al,[bx+Lower]
    mov [lowerTile],al
.sameTile: ; 35c
    ; Set the top tile to tile
    mov al,[tile]
    mov bx,[pos]
    mov si,[GameStatePtr]
    mov [bx+si+Upper],al

    ; If the monster is on a trap...
    mov bx,[GameStatePtr]
    inc word [bx+MonsterListLen]
    cmp byte [lowerTile],Trap
    jnz .notOnATrap
    ; ... call a function and return
    push byte -0x1
    push byte -0x1
    push word [y]
    push word [x]
    call word 0xffff:0x21aa ; 380
    add sp,byte +0x8
    jmp short .end

.notOnATrap: ; 38a
    cmp byte [lowerTile],ChipN
    jc .notChip
    cmp byte [lowerTile],ChipE
    jna .deathByMonster
.notChip: ; 396
    cmp byte [lowerTile],SwimN
    jc .end
    cmp byte [lowerTile],SwimE
    ja .end
.deathByMonster: ; 3a2
    ; Monster landed on Chip (or Swimming Chip)
    ; Set cause of death
    mov bx,[GameStatePtr]
    mov word [bx+Autopsy],Eaten
.end: ; 3ac
    pop si
    lea sp,[bp-0x2]
endfunc

; 3b4
func DeleteMonster
    sub sp,byte +0x8
    push di
    push si

    %arg    idx:word
    %define offset (bp-4)

    ; Get a pointer to the requested monster
    mov si,[idx]
    mov ax,si
    shl ax,byte 0x2
    add ax,si
    shl ax,1
    add ax,si
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,ax
    mov [bp-0x8],bx ; unused
    mov [bp-0x6],es ; unused
    ; If monster is slipping, delete from slip list
    cmp word [es:bx+Monster.slipping],byte +0x0
    jz .notSlipping
    push byte +0x2          ; unused
    push word [es:bx+Monster.y]
    push word [es:bx+Monster.x]
    mov al,[es:bx+Monster.tile]
    push ax                 ; unused
    call word 0x474:0x12be  ; 3f6 DeleteSlipperAt
    add sp,byte +0x8
.notSlipping: ; 3fe
    ; If we're already at the end of the list, skip the loop.
    lea ax,[si+0x1]
    mov bx,[GameStatePtr]
    cmp [bx+MonsterListLen],ax
    jng .end
    ; offset = idx*11
    mov ax,si
    shl ax,byte 0x2
    add ax,si
    shl ax,1
    add ax,si
    mov [offset],ax
.loop: ; 419
    ; Move next monster to current index.
    mov ax,[bx+MonsterListPtr]
    mov dx,[bx+MonsterListSeg]
    add ax,[offset]
    mov cx,ax
    mov bx,dx
    add ax,0xb
    push ds
    mov di,cx
    mov si,ax
    mov es,bx
    mov ds,dx
    mov cx,0x5
    rep movsw
    movsb
    pop ds
    ; Rinse and repeat.
    add word [offset],byte +0xb
    mov ax,[idx]
    inc ax
    mov [idx],ax
    inc ax
    mov bx,[GameStatePtr]
    cmp ax,[bx+MonsterListLen]
    jl .loop
.end: ; 451
    ; Decrement MonsterListLen
    dec word [bx+MonsterListLen]
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 45e
func DeleteMonsterAt
    sub sp,byte +0x2
    %arg dunno:word x:word, y:word
    push word [y]
    push word [x]
    call word 0x47d:0x0 ; 471 FindMonster
    add sp,byte +0x4
    push ax
    call word 0x5c9:0x3b4 ; 47a DeleteMonster
    lea sp,[bp-0x2]
endfunc

; 486
func SetTileDir
    sub sp,byte +0x4
    %arg origTile:byte, xdir:word, ydir:word
    %define tile (bp-3)
    mov al,[origTile]
    and al,0xfc
    mov [tile],al
    mov ax,[xdir]
    shl ax,1
    add ax,[ydir]
    inc ax
    inc ax
    jz .west
    dec ax
    jz .north
    dec ax
    dec ax
    jz .south
    dec ax
    jz .east
    mov al,[origTile]
    jmp short .end
.west: ; 4b6
    mov al,[tile]
    inc al
    jmp short .end
    nop
.north: ; 4be
    mov al,[tile]
    jmp short .end
    nop
.south: ; 4c4
    mov al,[tile]
    add al,0x2
    jmp short .end
    nop
.east: ; 4cc
    mov al,[tile]
    add al,0x3
.end: ; 4d1
    lea sp,[bp-0x2]
endfunc

; 4d8
func GetMonsterDir
    sub sp,byte +0x2
    %arg tile:byte, xOut:word, yOut:word
    cmp byte [tile],FirstMonster
    jc .notAMonster
    cmp byte [tile],LastMonster
    ja .notAMonster
    mov al,[tile]
    and ax,0x3
    jz .north
    dec ax
    jz .west
    dec ax
    jz .south
    dec ax
    jz .east
    jmp short .ok
.north: ; 504
    mov bx,[xOut]
    mov word [bx],0
    mov bx,[yOut]
    mov word [bx],-1
    jmp short .ok
.west: ; 514
    mov bx,[xOut]
    mov word [bx],-1
    jmp short .setYToZero
    nop
.south: ; 51e
    mov bx,[xOut]
    mov word [bx],0
    mov bx,[yOut]
    mov word [bx],1
    jmp short .ok
.east: ; 52e
    mov bx,[xOut]
    mov word [bx],1
.setYToZero: ; 535
    mov bx,[yOut]
    mov word [bx],0
.ok: ; 53c
    ; Return 1
    mov ax,0x1
    jmp short .end
    nop
.notAMonster: ; 542
    ; Return 0
    xor ax,ax
.end: ; 544
    lea sp,[bp-0x2]
endfunc

; 54c

; Initialize monster list, toggle walls, teleports, and chip's position.
func InitBoard
    sub sp,byte +0xc
    push di
    push si

    %define coords (bp-6)
    %define tile (bp-3)
    %define y (bp-0xa)

    ; Loop over initial monster list
    ; and add entries to actual monster list
    xor di,di
    mov bx,[GameStatePtr]
    cmp [bx+InitialMonsterListLen],di
    jng .noMonsters
    xor si,si
.loop: ; 569
    ; Get x, y coords of i'th monster.
    mov ax,[bx+si+InitialMonsterList]
    mov [coords],ax
    mov al,[coords+1] ; y
    sub ah,ah
    mov [y],ax
    shl ax,byte 0x5
    mov cl,[coords] ; x
    sub ch,ch
    add ax,cx
    add bx,ax
    ; Get upper tile
    mov al,[bx+Upper]
    mov [tile],al
    ; If not a monster, continue
    cmp al,FirstMonster
    jc .next
    cmp al,LastMonster
    ja .next
    ; Switch on monster direction
    and ax,0x3
    jz .north
    dec ax
    jz .west
    dec ax
    jz .south
    dec ax
    jz .east
    jmp short .next
    nop
    ; Call NewMonster with appropriate arguments
.north: ; 5a2
    push byte 0
    push byte -1
    jmp short .pushZero
.west: ; 5a8
    push byte 0
    push byte 0
    push byte -1
    jmp short .callNewMonster
.south: ; 5b0
    push byte 0
    push byte 1
.pushZero: ; 5b4
    push byte 0
    jmp short .callNewMonster
.east: ; 5b8
    push byte 0
    push byte 0
    push byte 1
.callNewMonster: ; 5be
    push word [y]
    push cx  ; x
    mov al,[tile]
    push ax
    call word 0x661:0x228 ; 5c6 NewMonster
    add sp,byte +0xc
.next: ; 5ce
    add si,byte +0x2
    inc di
    mov bx,[GameStatePtr]
    cmp [bx+InitialMonsterListLen],di
    jg .loop

.noMonsters: ; 5dc

    ; Loop over the game board
    %define yoff (bp-8)
    xor di,di
    mov [yoff],di
.loopY: ; 5e1
    xor si,si
    mov [bp-0x6],di ; unused
.loopX: ; 5e6
    ; Get tile at x,y
    mov bx,[GameStatePtr]
    add bx,[yoff]
    mov al,[bx+si+Upper]
    mov [tile],al

    ; If tile is a monster, get lower tile
    cmp al,FirstMonster
    jc .notAMonster
    cmp al,LastMonster
    ja .notAMonster
    mov bx,[GameStatePtr]
    add bx,[yoff]
    add bx,si ; x
    mov al,[bx+Lower]
    mov [tile],al

    ; Check if the tile is a toggle wall or floor, a teleport,
    ; or the protagonist.
.notAMonster: ; 60a
    mov al,[tile]
    sub ah,ah
    sub ax,0x25
    jnl .label10
    jmp word .nextX
.label10: ; 617
    ; Bail if the subtraction overflowed,
    ; which is impossible.
    jno .noOverflow
    jmp word .nextX
.noOverflow: ; 61c
    dec ax
    jng .toggleWallOrFloor
    sub ax,0x3
    jnz .notATeleport
    jmp word .teleport
.notATeleport: ; 627
    sub ax,0x43
    jnl .maybeChip
    jmp word .nextX
.maybeChip: ; 62f
    sub ax,0x3
    jg .notChip
    jmp word .chip
.notChip: ; 637
    jmp word .nextX

.toggleWallOrFloor: ; 63a
    ; Add toggle wall or floor to toggle list.
    ; No idea why this isn't its own function like all the other lists.
    mov bx,[GameStatePtr]
    mov ax,[bx+ToggleListCap]
    cmp [bx+ToggleListLen],ax
    jl .longenough
    push byte +0x4
    push byte +0x20
    mov ax,bx
    add ax,ToggleListCap
    push ax
    mov ax,bx
    add ax,ToggleListPtr
    push ax
    mov ax,bx
    add ax,ToggleListHandle
    push ax
    call word 0x6bf:0x1a4 ; 65e GrowArray
    add sp,byte +0xa
    or ax,ax
    jz .nextX
.longenough: ; 66a
    mov bx,[GameStatePtr]
    mov bx,[bx+ToggleListLen]
    mov ax,bx
    mov bx,[GameStatePtr]
    mov cx,[bx+ToggleListPtr]
    mov dx,[bx+ToggleListSeg]
    mov bx,ax
    shl bx,byte 0x2
    mov es,dx
    add bx,cx
    mov [es:bx],si ; = x
    mov bx,[GameStatePtr]
    mov bx,[bx+ToggleListLen]
    mov ax,bx
    mov bx,[GameStatePtr]
    mov cx,[bx+ToggleListPtr]
    mov dx,[bx+ToggleListSeg]
    mov bx,ax
    shl bx,byte 0x2
    mov es,dx
    add bx,cx
    mov [es:bx+0x2],di ; = y
    mov bx,[GameStatePtr]
    inc word [bx+ToggleListLen]
    jmp short .nextX
    nop

.teleport: ; 6ba
    ; Add teleport to teleport list.
    push di ; y
    push si ; x
    call word 0x25d:0x295e ; 6bc 3:0x295e AddTeleport
    add sp,byte +0x4
    jmp short .nextX

.chip: ; 6c6
    ; Set chip's position
    mov bx,[GameStatePtr]
    mov [bx+ChipX],si
    mov bx,[GameStatePtr]
    mov [bx+ChipY],di

.nextX: ; 6d6
    inc si
    cmp si,byte +0x20
    jnl .nextY
    jmp word .loopX
.nextY: ; 6df
    inc di
    add word [yoff],byte +0x20
    cmp word [yoff],Lower
    jnl .label22
    jmp word .loopY

.label22: ; 6ee
    ; If either of chip's coordinates is -1,
    ; put chip on the map at (1,1).
    ; Can't ever happen because chip starts at (0,0).
    mov bx,[GameStatePtr]
    cmp word [bx+ChipX],byte -0x1
    jz .addChip
    cmp word [bx+ChipY],byte -0x1
    jnz .end
.addChip: ; 700
    mov word [bx+ChipX],0x1
    mov bx,[GameStatePtr]
    mov word [bx+ChipY],0x1
    mov bx,[GameStatePtr]
    mov al,[bx+Lower+(1*32)+1]
    mov [bx+Upper+(1*32)+1],al
    mov bx,[GameStatePtr]
    mov byte [bx+Lower+(1*32)+1],0x0
.end: ; 724
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 72e
; Returns a random integer between 0 and n-1.
func RandInt
    sub sp,byte +0x2
    call word 0xffff:0xdc ; 73b 1:0xdc
    sub dx,dx
    div word [bp+0x6]
    mov ax,dx
    lea sp,[bp-0x2]
endfunc

; 74e
; Big freaking monster loop
; Loop through the monster list and move each monster.
func MonsterLoop
    ; Look at all these locals!
    %define tile (bp-3)
    %define xdir (bp-6)
    %define ydir (bp-8)
    %define deadflag (bp-0xa)
    %define i (bp-0xc)
    %define ynewdir (bp-0xe)
    %define xnewdir (bp-0x10)
    %define x (bp-0x12)
    %define y (bp-0x14)
    %define len (bp-0x16)
    %define xdistance (bp-0x18)
    %define ydistance (bp-0x1a)
    %define p (bp-0x1e)
    %define offset (bp-0x20)

    sub sp,byte +0x20
    push di
    push si
    mov bx,[GameStatePtr]
    mov ax,[bx+MonsterListLen]
    mov [len],ax
    mov word [i],0x0
    or ax,ax
    jg .loop
    jmp word .end

    ; Top of loop
.loop: ; 774
    ; Compute offset of monster[i]
    mov ax,[i]
    mov cx,ax
    shl ax,byte 0x2
    add ax,cx
    shl ax,1
    add ax,cx
    mov [offset],ax
    ; Pointer to monster[i]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,ax
    mov [p],bx
    mov [p+2],es

    ; If monster is slipping, skip it.
    cmp word [es:bx+Monster.slipping],byte +0x0
    jz .notSlipping
    jmp word .next
.notSlipping: ; 79f

    ; Get attributes
    mov ax,[es:bx+Monster.x]
    mov [x],ax
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov ax,[es:bx+si+Monster.y]
    mov [y],ax
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,si
    mov [p],bx
    mov [p+2],es
    mov ax,[es:bx+Monster.xdir]
    mov [xdir],ax
    mov ax,[es:bx+Monster.ydir]
    mov [ydir],ax
    mov al,[es:bx+Monster.tile]
    sub ah,ah
    sub ax,FirstMonster
    cmp ax,LastMonster-0x40
    jna .isAMonster
    jmp word .next ; not a monster
.isAMonster: ; 7e6
    shl ax,1
    xchg ax,bx
    jmp word near [cs:bx+.jmpTable]

.jmpTable:
    ; Jump table
    times 4 dw .BugMovement
    times 4 dw .FireballMovement
    times 4 dw .BallMovement
    times 4 dw .TankMovement
    times 4 dw .GliderMovement
    times 4 dw .TeethMovement
    times 4 dw .WalkerMovement
    times 4 dw .BlobMovement
    times 4 dw .ParameciumMovement

        ;;; BUG ;;;
.BugMovement:
    mov si,[y]
    shl si,byte 0x5
    add si,[x]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [tile],al

    ; Turn left, unless on a trap or clone machine.
    cmp al,Trap
    jz .bug.dontTurn
    cmp al,CloneMachine
    jz .bug.dontTurn
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    push word [ydir]
    push word [xdir]
    call word 0x880:0xb0 ; 860 TurnLeft
    add sp,byte +0x8
.bug.dontTurn: ; 868

    ; Set direction and move.
    ; Note: xnewdir and ynewdir may be used uninitialized.
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call word 0x8ed:0x486 ; 87d SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0x909:0x18da ; 899 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .bug.alive
    jmp word .label7
.bug.alive: ; 8ab
    cmp byte [tile],Trap
    jnz .bug.notATrap
    jmp word .next
.bug.notATrap: ; 8b4
    cmp byte [tile],CloneMachine
    jnz .bug.notACloneMachine
    jmp word .next
.bug.notACloneMachine: ; 8bd
    mov ax,[xdir]
    mov [xnewdir],ax
    mov ax,[ydir]
    mov [ynewdir],ax
    push ax
    ; Jump to second half of function call,
    ; shared with glider.
    jmp word .label10
    nop

        ;;; FIREBALL ;;;
.FireballMovement:
    ; Go straight
    mov ax,[xdir]
    mov [xnewdir],ax
    mov ax,[ydir]
    mov [ynewdir],ax
    push ax
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call word 0x94b:0x486 ; 8ea SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0x991:0x18da ; 906 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .label11
    jmp word .label7
.label11: ; 918

    ; Ran into something.
    ; Try turning left,
    ; unless we're on a trap or clone machine.
    mov si,[y]
    shl si,byte 0x5
    add si,[x]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [tile],al
    cmp al,Trap
    jnz .label12
    jmp word .next
.label12: ; 933
    cmp al,CloneMachine
    jnz .label13
    jmp word .next
.label13: ; 93a
    lea ax,[ynewdir]
    push ax
    lea cx,[xnewdir]
    push cx
    push word [ydir]
    push word [xdir]
    call word 0x975:0x116 ; 948 TurnLeft
    add sp,byte +0x8
    push word [ynewdir]
    ; The rest of the logic is shared with the paramecium.
    jmp word .label14

        ;;; BALL ;;;
.BallMovement:
    ; Go straight.
    mov ax,[xdir]
    mov [xnewdir],ax
    mov ax,[ydir]
    mov [ynewdir],ax
    push ax
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call word 0x9e5:0x486 ; 972 SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0xa01:0x18da ; 98e 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .label15
    jmp word .label7
.label15: ; 9a0
    mov si,[y]
    shl si,byte 0x5
    add si,[x]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [tile],al
    cmp al,Trap
    jnz .label16
    jmp word .next
.label16: ; 9bb
    cmp al,CloneMachine
    jnz .label17
    jmp word .next
.label17: ; 9c2
    ; rest of logic shared with gliders
    jmp word .label18
    nop

        ;;; TANK ;;;
.TankMovement:
    ; Go straight
    mov ax,[xdir]
    mov [xnewdir],ax
    mov ax,[ydir]
    mov [ynewdir],ax
    push ax
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call word 0xa50:0x486 ; 9e2 SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0xadb:0x18da ; 9fe 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .tank.blocked
    jmp word .label7

.tank.blocked: ; a10
    push word [y]
    push word [x]
    push word [bp+0x6]
    call word 0xffff:0x1ca ; a19 2:0x1ca
    add sp,byte +0x6
    mov bx,[GameStatePtr]
    les si,[bx+MonsterListPtr]
    add si,[offset]
    mov di,[es:si+Monster.y]
    shl di,byte 0x5
    add di,[es:si+Monster.x]
    cmp byte [bx+di+Lower],Trap
    jnz .tank.notTrapped
    mov bx,[bx+MonsterListPtr]
    add bx,[offset]
    push word [es:bx+Monster.y]
    push word [es:bx+Monster.x]
    call word 0xabf:0x22be ; a4d 3:22be FindTrap
    add sp,byte +0x4
    mov si,ax
    or si,si
    jnl .tank.found
    jmp word .next
.tank.found: ; a5e
    mov bx,ax
    shl bx,byte 0x2
    add bx,ax
    shl bx,1
    mov si,[GameStatePtr]
    les si,[si+TrapListPtr]
    cmp word [es:bx+si+Connection.flag],byte +0x1
    jnz .tank.notTrapped
    jmp word .next

.tank.notTrapped:
    ; Blocked or on a closed trap.
    ; Cease movement.
    ; monster.xdir = monster.ydir = 0
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov word [es:bx+si+Monster.ydir],0x0
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,si
    mov ax,[es:bx+Monster.ydir]
    mov [es:bx+Monster.xdir],ax
    jmp word .next
    nop

        ;;; GLIDER ;;;
.GliderMovement:
    ; Go straight.
    mov ax,[xdir]
    mov [xnewdir],ax
    mov ax,[ydir]
    mov [ynewdir],ax
    push ax
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call word 0x3f9:0x486 ; abc SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0xffff:0x18da ; ad8 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .label22
    jmp word .label7

.label22: ; aea
    ; Couldn't go - turn left!
    ; (Unless we're on a trap or clone machine of course)
    mov si,[y]
    shl si,byte 0x5
    add si,[x]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [tile],al
    cmp al,Trap
    jnz .label23
    jmp word .next
.label23: ; b05
    cmp al,CloneMachine
    jnz .label24
    jmp word .next

.label24: ; b0c
    lea ax,[ynewdir]
    push ax
    lea cx,[xnewdir]
    push cx
    push word [ydir]
    push word [xdir]
    call word 0xb3a:0xb0 ; b1a TurnLeft
    add sp,byte +0x8
    push word [ynewdir]
.label10: ; b25
    ; shared with bugs
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call word 0xb76:0x486 ; b37 SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0xc3e:0x18da ; b53 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .label25
    jmp word .label7
.label25: ; b65
    ; If that didn't work, turn right.
    lea ax,[ynewdir]
    push ax
    lea cx,[xnewdir]
    push cx
    push word [ydir]
    push word [xdir]
    call word 0xc22:0x116 ; b73 TurnRight
    ; The rest of this logic is shared with parameciums.
    jmp word .label26
    nop

        ; TEETH
.TeethMovement:
    ; Teeth move only on even ticks.
    cmp word [bp+0x8],byte +0x0
    jnz .label27
    jmp word .next
.label27: ; b85

    ; If on a trap or clone machine,
    ; don't change direction.
    mov si,[y]
    shl si,byte 0x5
    add si,[x]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [tile],al
    cmp al,Trap
    jz .label28
    cmp al,CloneMachine
    jz .label28

    ; xdistance = chip's x pos - monster's x pos
    ; ydistance = chip's y pos - monster's y pos
    mov ax,[bx+ChipX]
    mov si,[p]
    sub ax,[es:si+Monster.x]
    mov [xdistance],ax
    mov cx,[bx+ChipY]
    sub cx,[es:si+Monster.y]
    mov [ydistance],cx
    ; ydistance = abs(ydistance)
    mov dx,ax
    mov ax,cx
    mov cx,dx
    cwd
    xor ax,dx
    sub ax,dx
    ; xdistance = abs(xdistance)
    mov dx,ax
    mov ax,cx
    mov cx,dx
    cwd
    xor ax,dx
    sub ax,dx
    ; if xdistance <= ydistance
    cmp ax,cx
    jg .label29
    cmp word [ydistance],byte +0x0
    jng .label30
    mov word [xnewdir],0
    mov word [ynewdir],+1
    jmp short .label28
.label30: ; be6
    mov word [xnewdir],0
    mov word [ynewdir],-1
    jmp short .label28
.label29: ; bf2
    cmp word [xdistance],byte +0x0
    jng .label31
    mov word [xnewdir],+1
    jmp short .teeth.setYdiroutToZero
    nop
.label31: ; c00
    mov word [xnewdir],-1
.teeth.setYdiroutToZero: ; c05
    mov word [ynewdir],0

.label28: ; c0a
    ; Set tile direction and move tile.
    ; Note: xnewdir and ynewdir may be used uninitialized.
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call word 0xcd0:0x486 ; c1f SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0xcec:0x18da ; c3b 7:0x18da
    add sp,byte +0xc
    ; Check if we succeeded
    mov [deadflag],ax
    or ax,ax
    jz .label33
    jmp word .label7

    ; Our preferred direction is blocked.
    ; Try the other direction.
.label33: ; c4d
    cmp byte [tile],Trap
    jnz .label34
    jmp word .next
.label34: ; c56
    cmp byte [tile],CloneMachine
    jnz .label35
    jmp word .next
.label35: ; c5f
    mov ax,[xdistance]
    cwd
    xor ax,dx
    sub ax,dx
    mov cx,ax
    mov ax,[ydistance]
    cwd
    xor ax,dx
    sub ax,dx
    ; if xdistance <= ydistance
    cmp ax,cx
    jl .label36
    cmp word [xdistance],byte +0x0
    jng .label37
    mov word [xnewdir],0x1
.label40: ; c80
    mov word [ynewdir],0x0
    jmp short .label38
    nop
.label37: ; c88
    cmp word [xdistance],byte +0x0
    jnl .label39
    mov word [xnewdir],-1
    jmp short .label40
    nop
.label36: ; c96
    cmp word [ydistance],byte +0x0
    jng .label41
    mov word [xnewdir],0
    mov word [ynewdir],1
    jmp short .label38
.label41: ; ca8
    cmp word [ydistance],byte +0x0
    jnl .label39
    mov word [xnewdir],0
    mov word [ynewdir],-1
.label38: ; cb8
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call word 0xd60:0x486 ; ccd SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0xdd9:0x18da ; ce9 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .label39
    jmp word .label7

    ; Both directions were blocked.
    ; At least /face/ the right way.
.label39: ; cfb
    mov ax,[xdistance]
    cwd
    xor ax,dx
    sub ax,dx
    mov cx,ax
    mov ax,[ydistance]
    cwd
    xor ax,dx
    sub ax,dx
    cmp ax,cx
    jl .label42
    cmp word [ydistance],byte +0x0
    jng .label43
    mov word [xnewdir],0
    mov word [ynewdir],1
    jmp short .label44
    nop
.label43: ; d24
    mov word [xnewdir],0
    mov word [ynewdir],-1
    jmp short .label44
.label42: ; d30
    cmp word [xdistance],byte +0x0
    jng .label45
    mov word [xnewdir],1
    jmp short .label46
    nop
.label45: ; d3e
    mov word [xnewdir],-1
.label46: ; d43
    mov word [ynewdir],0
.label44: ; d48
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call word 0xdbd:0x486 ; d5d SetTileDir
    add sp,byte +0x6
    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    mov di,[GameStatePtr]
    mov [bx+di+Upper],al
    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    mov di,[GameStatePtr]
    mov al,[bx+di+Upper]
    les bx,[di+MonsterListPtr]
    mov [es:bx+si+Monster.tile],al
    push word [y]
    push word [x]
    push word [bp+0x6]
    call word 0xa1c:0x1ca ; d93 2:0x1ca
    add sp,byte +0x6
    jmp word .next

        ; WALKER
.WalkerMovement:
    ; Go straight.
    mov ax,[xdir]
    mov [xnewdir],ax
    mov ax,[ydir]
    mov [ynewdir],ax
    push ax
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call word 0xe25:0x486 ; dba SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0xebf:0x18da ; dd6 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .label47
    jmp word .label7
.label47: ; de8

    ; Straight was blocked.
    ; If we are on a trap or clone machine,
    ; that's it, we're done.
    mov si,[y]
    shl si,byte 0x5
    add si,[x]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [tile],al
    cmp al,Trap
    jnz .label48
    jmp word .next
.label48: ; e03
    cmp al,CloneMachine
    jnz .label49
    jmp word .next
.label49: ; e0a

    ; Otherwise pick a random direction to go.
    ; Keep trying until we find an open direction
    ; or until every direction has been tried.
    ; Don't try a direction more than once.
    xor si,si ; attempted directions
    mov di,[xnewdir]
    mov ax,[ynewdir]
    mov [bp-0x4],ax
    mov [xdir],di
.walker.loop: ; e18
    cmp si,byte +0x7
    jnz .label50
    jmp word .next
.label50: ; e20
    ; Random choice of 0, 1, or 2.
    push byte +0x3
    call word 0xe4e:0x72e ; e22 RandInt
    add sp,byte +0x2
    or ax,ax
    jz .walker.turnLeft
    dec ax
    jz .walker.turnRight
    dec ax
    jz .walker.turnAround
    jmp short .label54

.walker.turnLeft: ; e36
    ; Randomly turn left
    test si,0x1
    jnz .walker.loop
    or si,byte +0x1
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    push word [bp-0x4]
    push di
    call word 0xe6a:0xb0 ; e4b TurnLeft
    jmp short .label56

.walker.turnRight: ; e52
    ; Randomly turn right
    test si,0x2
    jnz .walker.loop
    or si,byte +0x2
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    push word [bp-0x4]
    push di
    call word 0xe86:0x116 ; e67 TurnRight
    jmp short .label56

.walker.turnAround: ; e6e
    ; Randomly turn around
    test si,0x4
    jnz .walker.loop
    or si,byte +0x4
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    push word [bp-0x4]
    push di
    call word 0xea3:0x17c ; e83 TurnAround
.label56: ; e88
    add sp,byte +0x8

    ; Try moving.
.label54: ; e8b
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,[offset]
    mov al,[es:bx+Monster.tile]
    push ax
    call word 0x863:0x486 ; ea0 SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0x89c:0x18da ; ebc 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jnz .label57
    jmp word .walker.loop
.label57: ; ece
    jmp word .label7
    nop

        ;;; BLOB ;;;
.BlobMovement:
    cmp word [bp+0x8],byte +0x0
    jnz .label58
    jmp word .next
.label58: ; edb
    push byte +0x3
    call word 0xeee:0x72e ; edd
    add sp,byte +0x2
    dec ax
    mov [xnewdir],ax
    push byte +0x3
    call word 0xf20:0x72e ; eeb
    add sp,byte +0x2
    dec ax
    mov [ynewdir],ax
    cmp word [xnewdir],byte +0x0
    jnz .label59
    or ax,ax
    jnz .label60
.label59: ; f01
    or ax,ax
    jnz .label58
    cmp [xnewdir],ax
    jz .label58
.label60: ; f0a
    push ax
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si]
    push ax
    call word 0xf66:0x486 ; f1d SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0x1001:0x18da ; f39 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .label61
    jmp word .label7
.label61: ; f4b
    xor si,si
    mov di,[xnewdir]
    mov ax,[ynewdir]
    mov [bp-0x4],ax
    mov [xdir],di
.label67: ; f59
    cmp si,byte +0x7
    jnz .label62
    jmp word .next
.label62: ; f61
    push byte +0x3
    call word 0xf90:0x72e ; f63
    add sp,byte +0x2
    or ax,ax
    jz .label63
    dec ax
    jz .label64
    dec ax
    jz .label65
    jmp short .label66
    nop
.label63: ; f78
    test si,0x1
    jnz .label67
    or si,byte +0x1
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    push word [bp-0x4]
    push di
    call word 0xfac:0xb0 ; f8d
    jmp short .label68
.label64: ; f94
    test si,0x2
    jnz .label67
    or si,byte +0x2
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    push word [bp-0x4]
    push di
    call word 0xfc8:0x116 ; fa9
    jmp short .label68
.label65: ; fb0
    test si,0x4
    jnz .label67
    or si,byte +0x4
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    push word [bp-0x4]
    push di
    call word 0xfe5:0x17c ; fc5
.label68: ; fca
    add sp,byte +0x8
.label66: ; fcd
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,[offset]
    mov al,[es:bx]
    push ax
    call word 0x1041:0x486 ; fe2 SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0x107a:0x18da ; ffe 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jnz .label69
    jmp word .label67
.label69: ; 1010
    jmp word .label7
    nop

        ;;; PARAMECIUM ;;;
.ParameciumMovement:
    mov si,[y]
    shl si,byte 0x5
    add si,[x]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [tile],al
    cmp al,Trap
    jz .label70
    cmp al,CloneMachine
    jz .label70
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    push word [ydir]
    push word [xdir]
    call word 0x105e:0x116 ; 103e TurnRight
    add sp,byte +0x8
.label70: ; 1046
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si]
    push ax
    call word 0x10bd:0x486 ; 105b SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0x10d9:0x18da ; 1077 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .label71
    jmp word .label7
.label71: ; 1089
    cmp byte [tile],Trap
    jnz .label72
    jmp word .next
.label72: ; 1092
    cmp byte [tile],CloneMachine
    jnz .label73
    jmp word .next
.label73: ; 109b
    mov ax,[xdir]
    mov [xnewdir],ax
    mov ax,[ydir]
    mov [ynewdir],ax
    push ax
.label14: ; 10a8
    ; shared with fireball
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si]
    push ax
    call word 0x10f9:0x486 ; 10ba SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0x1132:0x18da ; 10d6 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .label74
    jmp word .label7
.label74: ; 10e8
    lea ax,[ynewdir]
    push ax
    lea cx,[xnewdir]
    push cx
    push word [ydir]
    push word [xdir]
    call word 0x1116:0xb0 ; 10f6 TurnLeft

.label26: ; 10fb
    ; shared with gliders
    add sp,byte +0x8
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si]
    push ax
    call word 0x114f:0x486 ; 1113 SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0x1188:0x18da ; 112f 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jnz .label7
.label18: ; 113e
    ; shared with balls
    lea ax,[ynewdir]
    push ax
    lea cx,[xnewdir]
    push cx
    push word [ydir]
    push word [xdir]
    call word 0x116c:0x17c ; 114c TurnAround
    add sp,byte +0x8
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si]
    push ax
    call word 0x11f6:0x486 ; 1169 SetTileDir
    add sp,byte +0x6
    push ax
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push word [bp+0x6]
    call word 0xb56:0x18da ; 1185 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .next

.label7: ; 1194
    ; Check dead flag.
    cmp ax,0x1
    jnz .dead
    ; The monster is still alive.
    ; Update the monster list.
    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    mov si,[GameStatePtr]
    mov al,[bx+si]
    les bx,[si+MonsterListPtr]
    mov si,[offset]
    mov [es:bx+si+Monster.tile],al
    mov ax,[x]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov [es:bx+si+Monster.x],ax
    mov ax,[y]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov [es:bx+si+Monster.y],ax
    mov ax,[xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov [es:bx+si+Monster.xdir],ax
    mov ax,[ynewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov [es:bx+si+Monster.ydir],ax
    jmp short .next

.dead: ; 11f0
    ; The monster died.
    ; Remove it from the monster list.
    push word [i]
    call word 0xb1d:0x3b4 ; 11f3 DeleteMonster
    add sp,byte +0x2
    dec word [i]
    dec word [len]

.next: ; 1201
    mov ax,[len]
    inc word [i]
    cmp [i],ax
    jnl .end
    jmp word .loop

.end: ; 120f
    ; If chip died, do a bunch of mysterious things.
    mov bx,[GameStatePtr]
    cmp word [bx+Autopsy],byte +0x0
    jz .notDeadYet
    push byte +0x1
    call word 0x1233:0xcbe ; 121c 2:0xcbe
    add sp,byte +0x2
    push byte +0x1
    push byte +0x2
    call word 0xffff:0x56c ; 1228 8:0x56c
    add sp,byte +0x4
    call word 0xd96:0xb9a ; 1230 2:0xb9a
    push byte +0x1
    mov bx,[GameStatePtr]
    push word [bx+0x800]
    call word 0xffff:0x356 ; 123f 4:0x356
    add sp,byte +0x4
.notDeadYet: ; 1247

    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 1250

func NewSlipper
    sub sp,byte +0x2
    mov bx,[GameStatePtr]
    mov ax,[bx+SlipListCap]
    cmp [bx+SlipListLen],ax
    jl .label0
    push byte +0xb
    push byte +0x8
    mov ax,bx
    add ax,SlipListCap
    push ax
    mov ax,bx
    add ax,SlipListPtr
    push ax
    mov ax,bx
    add ax,SlipListHandle
    push ax
    call word 0x12e7:0x1a4 ; 1281 3:0x1a4 GrowArray
    add sp,byte +0xa
    or ax,ax
    jnz .label0
    cwd
    jmp short .end
.label0: ; 1290
    mov bx,[GameStatePtr]
    inc word [bx+SlipListLen]
    mov bx,[GameStatePtr]
    mov ax,[bx+SlipListLen]
    mov cx,ax
    shl ax,byte 0x2
    add ax,cx
    shl ax,1
    add ax,cx
    add ax,[bx+SlipListPtr]
    mov dx,[bx+SlipListSeg]
    sub ax,0xb
.end: ; 12b6
    lea sp,[bp-0x2]
endfunc

; 12be

func DeleteSlipperAt
    sub sp,byte +0x6
    push di
    push si
    mov bx,[GameStatePtr]
    cmp word [bx+SlipListLen],byte +0x0
    jnz .nonzero
.returnZero: ; 12d8
    xor ax,ax
    jmp word .end
    nop
.nonzero: ; 12de
    push word [bp+0xa]
    push word [bp+0x8]
    call word 0x1316:0x58 ; 12e4 3:58 FindSlipper
    add sp,byte +0x4
    mov di,ax
    cmp di,byte -1
    jz .returnZero
    mov bx,ax
    shl bx,byte 0x2
    add bx,ax
    shl bx,1
    add bx,ax
    mov si,[GameStatePtr]
    les si,[si+SlipListPtr]
    cmp word [es:bx+si+Monster.slipping],byte +0x0
    jz .notslipping
    push word [bp+0xa]
    push word [bp+0x8]
    call word 0x13ac:0x0 ; 1313 3:0 FindMonster
    add sp,byte +0x4
    mov bx,ax
    shl bx,byte 0x2
    add bx,ax
    shl bx,1
    add bx,ax
    mov si,[GameStatePtr]
    les si,[si+MonsterListPtr]
    mov word [es:bx+si+Monster.slipping],0x0
.notslipping: ; 1334
    lea bx,[di+0x1]
    mov si,[GameStatePtr]
    cmp bx,[si+SlipListLen]
    jnl .noloop
    mov ax,bx
    shl ax,byte 0x2
    add ax,bx
    shl ax,1
    add ax,bx
    mov [bp-0x4],ax
    mov [bp-0x6],bx
.loop: ; 1352
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    add bx,[bp-0x4]
    mov ax,es
    push ds
    lea di,[bx-0xb]
    mov si,bx
    mov ds,ax
    mov cx,0x5
    rep movsw
    movsb
    pop ds
    add word [bp-0x4],byte +0xb
    inc word [bp-0x6]
    mov ax,[bp-0x6]
    mov bx,[GameStatePtr]
    cmp [bx+SlipListLen],ax
    jg .loop
.noloop: ; 1382
    mov bx,[GameStatePtr]
    mov ax,0x1
    dec word [bx+SlipListLen]
.end: ; 138d
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 1396

func FindSlipperAt
    sub sp,byte +0x4
    push word [bp+0xa]
    push word [bp+0x8]
    call word 0x1431:0x58 ; 13a9 FindSlipper
    add sp,byte +0x4
    mov [bp-0x4],ax
    inc ax
    jz .returnZero
    mov ax,[bp-0x4]
    mov cx,ax
    shl ax,byte 0x2
    add ax,cx
    shl ax,1
    add ax,cx
    mov bx,[GameStatePtr]
    add ax,[bx+SlipListPtr]
    mov dx,[bx+SlipListSeg]
    jmp short .end
    nop
.returnZero: ; 13d4
    xor ax,ax
    cwd
.end: ; 13d7
    lea sp,[bp-0x2]
endfunc

; 13de

INCBIN "base.exe", 0x6200+$, 0x22be - 0x13de

; 22be

; Search trap list for trap at x,y
func FindTrap
    %arg x:word, y:word
    sub sp,byte +0x2
    push di
    push si
    xor cx,cx
    mov bx,[GameStatePtr]
    cmp [bx+TrapListLen],cx
    jng .notFound
    mov si,bx
    mov ax,[si+TrapListPtr]
    mov dx,[si+TrapListSeg]
    add ax,0x4
    mov bx,ax
    mov es,dx
    mov di,[x]
.loop: ; 22ed
    cmp [es:bx+Connection.toX-4],di
    jnz .next
    mov ax,[y]
    cmp [es:bx+Connection.toY-4],ax
    jz .found
.next: ; 22fb
    add bx,byte +0xa
    inc cx
    cmp [si+TrapListLen],cx
    jg .loop
    jmp short .notFound
    nop
.found: ; 2308
    mov ax,cx
    jmp short .end
.notFound: ; 230c
    mov ax,-1
.end: ; 230f
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 2318

INCBIN "base.exe", 0x6200+0x2318, 0x295e-0x2318

; 295e
func AddTeleport
    %arg x:word, y:word
    sub sp,byte +0x2
    push si

    ; Grow teleport list if out of space.
    mov bx,[GameStatePtr]
    mov ax,[bx+TeleportListCap]
    cmp [bx+TeleportListLen],ax
    jl .allswell
    push byte +0x4
    push byte +0x8
    mov ax,bx
    add ax,TeleportListCap
    push ax
    mov ax,bx
    add ax,TeleportListPtr
    push ax
    mov ax,bx
    add ax,TeleportListHandle
    push ax
    call word 0x2501:0x1a4 ; 2990 GrowArray
    add sp,byte +0xa
    or ax,ax
    jnz .allswell
    mov ax,-1
    jmp short .end
    nop
.allswell: ; 29a2
    mov si,[GameStatePtr]
    mov bx,[si+TeleportListLen]
    inc word [si+TeleportListLen]
    mov ax,[x]
    mov si,bx
    mov cx,bx
    shl si,byte 0x2
    mov bx,[GameStatePtr]
    les bx,[bx+TeleportListPtr]
    mov [es:bx+si],ax
    mov ax,[y]
    mov bx,[GameStatePtr]
    les bx,[bx+TeleportListPtr]
    mov [es:bx+si+0x2],ax
    mov ax,cx
.end: ; 29d4
    pop si
    lea sp,[bp-0x2]
endfunc

; 29dc
func DeleteTeleport
    sub sp,byte +0x2
    push si

    %arg idx:word

    ; If idx is negative, return
    mov cx,[idx]
    or cx,cx
    jl .end

    ; If idx is >= len, return
    mov bx,[GameStatePtr]
    cmp [bx+TeleportListLen],cx
    jng .end

    ; Decrement len
    dec word [bx+TeleportListLen]

    mov bx,[GameStatePtr]
    cmp [bx+TeleportListLen],cx
    jng .end
    mov bx,cx
    shl bx,byte 0x2
.loop: ; 2a0e
    ; Move next entry down
    mov si,[GameStatePtr]
    les si,[si+TeleportListPtr]
    add si,bx
    mov ax,[es:si+4+0]
    mov dx,[es:si+4+2]
    mov [es:si+0],ax
    mov [es:si+2],dx
    add bx,byte +0x4
    inc cx
    mov si,[GameStatePtr]
    cmp [si+TeleportListLen],cx
    jg .loop
.end: ; 2a35
    pop si
    lea sp,[bp-0x2]
endfunc

; 2a3e

; Return the bitmap coordinates of the specified tile.
func GetTileImagePos
    sub sp,byte +0x6

    ; ax = a/16 * 32
    ; dx = a%16 * 32

    mov al,[bp+0x6]
    and ax,0xf0
    shl ax,1
    mov [bp-0x6],ax
    mov al,[bp+0x6]
    and ax,0xf
    shl ax,byte 0x5
    mov [bp-0x4],ax
    mov ax,[bp-0x6]
    mov dx,[bp-0x4]
    lea sp,[bp-0x2]
endfunc

; 2a70

; vim: syntax=nasm

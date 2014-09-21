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

; Probably
SlipListLen         equ 0x91e
SlipListCap         equ 0x920
SlipListHandle      equ 0x922
SlipListPtr         equ 0x924
SlipListSeg         equ 0x926

MonsterListLen      equ 0x928
MonsterListCap      equ 0x92a
MonsterListHandle   equ 0x92c
MonsterListPtr      equ 0x92e
MonsterListSeg      equ 0x930

ToggleListLen       equ 0x932
ToggleListCap       equ 0x934
ToggleListHandle    equ 0x936
ToggleListPtr       equ 0x938
ToggleListSeg       equ 0x93a

TeleportListLen       equ 0x950
TeleportListCap       equ 0x952
TeleportListHandle    equ 0x954
TeleportListPtr       equ 0x956
TeleportListSeg       equ 0x958

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
    %arg tile:byte, x:word, y:word, xdir:word, ydir:word, dunno:word
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

    ; Return if dunno == 0 and the lower tile is a clone machine
    cmp word [dunno],byte +0x0
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

INCBIN "base.exe", 0x6200+$, 0x295e - 0x72e

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

SEGMENT CODE ; 3

; Game logic
; (Mostly monsters so far)

%include "constants.asm"
%include "structs.asm"
%include "variables.asm"
%include "func.mac"

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

; Same as above, but searches the slip list
func FindSlipper
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
    add bx,byte Monster_size
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
    call 0x0:0xffff ; 1bc KERNEL.GlobalUnlock
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
    call 0x0:0xffff ; 1d6 KERNEL.GlobalReAlloc
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
    call 0x0:0xffff ; 1e9 KERNEL.GlobalAlloc

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
    call 0x0:0xffff ; 1fe KERNEL.GlobalLock
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
    call 0x383:GrowArray ; 25a 3:0x1a4
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
    call 0xffff:EnterTrap ; 380 3:0x21aa
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
    call 0x474:DeleteSlipperAt  ; 3f6 3:12be
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
    call 0x47d:FindMonster ; 471 3:471
    add sp,byte +0x4
    push ax
    call 0x5c9:DeleteMonster ; 47a 3:47a
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
    call 0x661:NewMonster ; 5c6 3:228
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
    sub ax,ToggleWall
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
    call 0x6bf:GrowArray ; 65e 3:1a4
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
    mov [es:bx+Point.x],si ; = x
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
    mov [es:bx+Point.y],di ; = y
    mov bx,[GameStatePtr]
    inc word [bx+ToggleListLen]
    jmp short .nextX
    nop

.teleport: ; 6ba
    ; Add teleport to teleport list.
    push di ; y
    push si ; x
    call 0x25d:AddTeleport ; 6bc 3:295e
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
    call 0xffff:0xdc ; 73b 1:0xdc
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
    call 0x880:TurnLeft ; 860 3:b0
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
    call 0x8ed:SetTileDir ; 87d 3:486
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
    call 0x909:0x18da ; 899 7:0x18da
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
    call 0x94b:SetTileDir ; 8ea 3:486
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
    call 0x991:0x18da ; 906 7:0x18da
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
    call 0x975:TurnRight ; 948 3:116
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
    call 0x9e5:SetTileDir ; 972 3:486
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
    call 0xa01:0x18da ; 98e 7:0x18da
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
    call 0xa50:SetTileDir ; 9e2 3:486
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
    call 0xadb:0x18da ; 9fe 7:0x18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .tank.blocked
    jmp word .label7

.tank.blocked: ; a10
    push word [y]
    push word [x]
    push word [bp+0x6]
    call 0xffff:0x1ca ; a19 2:0x1ca
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
    call 0xabf:FindTrap ; a4d 3:22be
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
    call 0x3f9:SetTileDir ; abc 3:486
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
    call 0xffff:0x18da ; ad8 7:0x18da
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
    call 0xb3a:TurnLeft ; b1a 3:b0
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
    call 0xb76:SetTileDir ; b37 3:486
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
    call 0xc3e:0x18da ; b53 7:0x18da
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
    call 0xc22:TurnRight ; b73 3:116
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
    call 0xcd0:SetTileDir ; c1f 3:486
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
    call 0xcec:0x18da ; c3b 7:0x18da
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
    call 0xd60:SetTileDir ; ccd 3:486
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
    call 0xdd9:0x18da ; ce9 7:0x18da
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
    call 0xdbd:SetTileDir ; d5d 3:486
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
    call 0xa1c:0x1ca ; d93 2:0x1ca
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
    call 0xe25:SetTileDir ; dba 3:486
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
    call 0xebf:0x18da ; dd6 7:0x18da
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
    call 0xe4e:RandInt ; e22 3:0x72e
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
    call 0xe6a:TurnLeft ; e4b 3:b0
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
    call 0xe86:TurnRight ; e67 3:116
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
    call 0xea3:TurnAround ; e83 3:17c
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
    call 0x863:SetTileDir ; ea0 3:486
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
    call 0x89c:0x18da ; ebc 7:0x18da
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
    call 0xeee:RandInt ; edd 3:0x72e
    add sp,byte +0x2
    dec ax
    mov [xnewdir],ax
    push byte +0x3
    call 0xf20:RandInt ; eeb 3:0x72e
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
    call 0xf66:SetTileDir ; f1d 3:486
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
    call 0x1001:0x18da ; f39 7:0x18da
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
    call 0xf90:RandInt ; f63 3:0x72e
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
    call 0xfac:TurnLeft ; f8d 3:0xb0
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
    call 0xfc8:TurnRight ; fa9 3:0x116
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
    call 0xfe5:TurnAround ; fc5 3:0x17c
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
    call 0x1041:SetTileDir ; fe2 3:486
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
    call 0x107a:0x18da ; ffe 7:0x18da
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
    call 0x105e:TurnRight ; 103e 3:116
    add sp,byte +0x8
.label70: ; 1046
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si]
    push ax
    call 0x10bd:SetTileDir ; 105b 3:486
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
    call 0x10d9:0x18da ; 1077 7:0x18da
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
    call 0x10f9:SetTileDir ; 10ba 3:486
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
    call 0x1132:0x18da ; 10d6 7:0x18da
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
    call 0x1116:TurnLeft ; 10f6 3:b0

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
    call 0x114f:SetTileDir ; 1113 3:486
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
    call 0x1188:0x18da ; 112f 7:0x18da
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
    call 0x116c:TurnAround ; 114c 3:17c
    add sp,byte +0x8
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si]
    push ax
    call 0x11f6:SetTileDir ; 1169 3:486
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
    call 0xb56:0x18da ; 1185 7:0x18da
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
    call 0xb1d:DeleteMonster ; 11f3 3:0x3b4
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
    call 0x1233:0xcbe ; 121c 2:0xcbe
    add sp,byte +0x2
    push byte +0x1
    push byte ChipDeathSound
    call 0xffff:0x56c ; 1228 8:0x56c
    add sp,byte +0x4
    call 0xd96:0xb9a ; 1230 2:0xb9a
    push byte +0x1
    mov bx,[GameStatePtr]
    push word [bx+0x800]
    call 0xffff:0x356 ; 123f 4:0x356
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
    call 0x12e7:GrowArray ; 1281 3:0x1a4
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
    call 0x1316:FindSlipper ; 12e4 3:58
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
    ; if the slipper has a monster list entry (i.e. it isn't a block),
    ; then find it and turn off its slipping flag
    cmp word [es:bx+si+Monster.slipping],byte +0x0
    jz .notAMonster
    push word [bp+0xa]
    push word [bp+0x8]
    call 0x13ac:FindMonster ; 1313 3:0
    add sp,byte +0x4
    mov bx,ax
    shl bx,byte 0x2
    add bx,ax
    shl bx,1
    add bx,ax
    mov si,[GameStatePtr]
    les si,[si+MonsterListPtr]
    mov word [es:bx+si+Monster.slipping],0x0
.notAMonster: ; 1334
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
    add word [bp-0x4],byte Monster_size
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
    call 0x1431:FindSlipper ; 13a9 3:0x58
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

func SlipLoop
    %define previousSlipListLen (bp-0x8)
    %define i (bp-0xa)
    %define x (bp-0xc)
    %define y (bp-0xe)
    %define xdir (bp-0x10)
    %define ydir (bp-0x12)

    sub sp,byte +0x16
    push di
    push si
    mov word [i],0x0
    mov bx,[GameStatePtr]
    cmp word [bx+SlipListLen],byte +0x0
    jg .start
    jmp word .break
.start: ; 1400
    xor si,si
    mov di,[bp+0x6]
.loop: ; 1405
    mov ax,[bx+SlipListLen]
    mov [previousSlipListLen],ax
    les bx,[bx+SlipListPtr]
    add bx,si
    cmp word [es:bx+Monster.slipping],byte +0x0
    jnz .isAMonster
    jmp word .isABlock
.isAMonster: ; 141c
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    add bx,si
    push word [es:bx+Monster.y]
    push word [es:bx+Monster.x]
    call 0x148d:FindMonster ; 142e 3:0x0
    add sp,byte +0x4
    mov [bp-0x4],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Monster.xdir]
    mov [xdir],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Monster.ydir]
    mov [ydir],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Monster.x]
    mov [x],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Monster.y]
    mov [y],ax
    push word [ydir]
    push word [xdir]
    mov bx,ax ; y
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    mov al,[bx+Upper]
    push ax ; tile
    call 0x151c:SetTileDir ; 148a 3:486
    add sp,byte +0x6
    push ax         ; tile
    lea ax,[ydir]
    push ax
    lea ax,[xdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push di  ; wnd
    call 0x14fe:0x18da ; 14a4 MoveMonster
    add sp,byte +0xc
    mov [bp-0x6],ax
    or ax,ax
    jz .label4
    jmp word .success
    ; if the move was blocked,
    ; check if we're on ice
.label4: ; 14b6
    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    mov al,[bx+Lower]
    mov [bp-0x14],al
    cmp al,Ice
    jz .label6
    cmp al,IceWallNW
    jnc .label7
    jmp word .label8
.label7: ; 14d5
    cmp al,IceWallSW
    jna .label6
    jmp word .label8
.label6: ; 14dc
    ; reverse the move direction and try again
    neg word [xdir]
    neg word [ydir]
    push word 0xc6c
    push byte +0x2
    lea ax,[ydir]
    push ax
    lea cx,[xdir]
    push cx
    push word [y]
    push word [x]
    push word [y]
    push word [x]
    call 0x1536:0x636 ; 14fb 7:636 SlideMovement
    add sp,byte +0x10
    push word [ydir]
    push word [xdir]
    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    mov al,[bx+Upper]
    push ax
    call 0x15bb:SetTileDir ; 1519 3:486
    add sp,byte +0x6
    push ax
    lea ax,[ydir]
    push ax
    lea ax,[xdir]
    push ax
    lea ax,[y]
    push ax
    lea ax,[x]
    push ax
    push di ; hDC
    call 0xf3c:0x18da ; 1533 7:18da MoveMonster
    add sp,byte +0xc
    mov [bp-0x6],ax
    or ax,ax
    jnz .success
    jmp word .label9

.success: ; 1545
    cmp ax,0x1
    jz .label10
    jmp word .label11
.label10: ; 154d
    mov ax,[x]
    mov cx,[bp-0x4]
    mov dx,cx
    shl cx,byte 0x2
    add cx,dx
    shl cx,1
    add cx,dx
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,cx
    mov [es:bx+Monster.x],ax
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,cx
    mov ax,[y]
    mov [es:bx+Monster.y],ax
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,cx
    mov ax,[xdir]
    mov [es:bx+Monster.xdir],ax
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,cx
    mov ax,[ydir]
    mov [es:bx+Monster.ydir],ax
    push word [ydir]
    push word [xdir]
    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    mov al,[bx+Upper]
    push ax
    mov [bp-0x16],cx
    call 0x15d8:SetTileDir ; 15b8 3:486
    add sp,byte +0x6
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,[bp-0x16]
    mov [es:bx+Monster.tile],al
    jmp word .next
    nop
.label11: ; 15d2
    push word [bp-0x4]
    call 0xee0:0x3b4 ; 15d5
    add sp,byte +0x2
    jmp word .next
.label9: ; 15e0
    neg word [xdir]
    neg word [ydir]

.label8: ; 15e6
    push word 0xc6c
    push byte +0x2
    jmp word .label13

.isABlock: ; 15ee
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    add bx,si
    mov ax,[es:bx+Monster.xdir]
    mov [xdir],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Monster.ydir]
    mov [ydir],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Monster.x]
    mov [x],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Monster.y]
    mov [y],ax
    push byte +0x0
    push word 0xff
    push word [ydir]
    push word [xdir]
    push ax
    push word [x]
    push di
    call 0x168d:0xdae ; 163c
    add sp,byte +0xe
    or ax,ax
    jz .label14
    jmp word .next
.label14: ; 164b
    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    mov al,[bx+Lower]
    mov [bp-0x14],al
    cmp al,Ice
    jz .label15
    cmp al,IceWallNW
    jb .label16
    cmp al,IceWallSW
    ja .label16
.label15: ; 166b
    neg word [xdir]
    neg word [ydir]
    push word 0xc6c
    push byte +0x1
    lea ax,[ydir]
    push ax
    lea cx,[xdir]
    push cx
    push word [y]
    push word [x]
    push word [y]
    push word [x]
    call 0x16a7:0x636 ; 168a slide movement
    add sp,byte +0x10
    push byte +0x0
    push word 0xff
    push word [ydir]
    push word [xdir]
    push word [y]
    push word [x]
    push di
    call 0x16d2:0xdae ; 16a4 MoveBlock
    add sp,byte +0xe
    or ax,ax
    jnz .next
    neg word [xdir]
    neg word [ydir]
.label16: ; 16b6
    push word 0xc6c
    push byte +0x1
.label13: ; 16bb
    lea ax,[ydir]
    push ax
    lea ax,[xdir]
    push ax
    push word [y]
    push word [x]
    push word [y]
    push word [x]
    call 0x14a7:0x636 ; 16cf
    add sp,byte +0x10

.next: ; 16d7
    mov ax,[previousSlipListLen]
    mov bx,[GameStatePtr]
    cmp [bx+SlipListLen],ax
    jnz .label17
    add si,byte Monster_size
    inc word [bp-0xa]
.label17: ; 16ea
    mov ax,[bp-0xa]
    cmp [bx+SlipListLen],ax
    jng .break
    jmp word .loop

.break: ; 16f6
    cmp word [bx+Autopsy],byte +0x0
    jz .label19
    push byte +0x1
    call 0x1716:0xcbe ; 16ff
    add sp,byte +0x2
    push byte +0x1
    push byte ChipDeathSound
    call 0x17fb:0x56c ; 170b
    add sp,byte +0x4
    call 0x121f:0xb9a ; 1713
    push byte +0x1
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    call 0x1242:0x356 ; 1722
    add sp,byte +0x4
.label19: ; 172a
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 1734

func ResetInventory
    sub sp,byte +0x2
    ; if arg is nonzero, only reset boots, not keys
    cmp word [bp+0x6],byte +0x0
    jnz .resetBoots ; ↓
    xor ax,ax
    mov [BlueKeyCount],ax
    mov [RedKeyCount],ax
    mov [GreenKeyCount],ax
    mov [YellowKeyCount],ax
.resetBoots: ; 1755
    xor ax,ax
    mov [FlipperCount],ax
    mov [FireBootCount],ax
    mov [IceSkateCount],ax
    mov [SuctionBootCount],ax
    mov word [0x20],0x1 ; ???
    lea sp,[bp-0x2]
endfunc

; 1770

func PickUpKeyOrBoot
    sub sp,byte +0x2
    mov al,[bp+0x6]
    sub ah,ah
    cmp ax,SuctionBoots
    jz .suctionBoots ; ↓
    ja .playToolSound ; ↓
    cmp al,GreenKey
    jz .greenKey ; ↓
    jg .label0 ; ↓
    sub al,ICChip
    jz .chip ; ↓
    sub al,BlueKey-ICChip
    jz .blueKey ; ↓
    dec al
    jz .redKey ; ↓
    jmp short .playToolSound ; ↓
    nop
.label0: ; 179e
    sub al,YellowKey
    jz .yellowKey ; ↓
    dec al
    jz .flipper ; ↓
    dec al
    jz .fireBoots ; ↓
    dec al
    jz .iceSkates ; ↓
    jmp short .playToolSound ; ↓
.chip: ; 17b0
    cmp word [ChipsRemainingCount],byte +0x0
    jng .noChipsLeft ; ↓
    dec word [ChipsRemainingCount]
.noChipsLeft: ; 17bb
    mov cx,PickUpChipSound
    jmp short .playSound ; ↓
.blueKey: ; 17c0
    inc word [BlueKeyCount]
    jmp short .playToolSound ; ↓
.redKey: ; 17c6
    inc word [RedKeyCount]
    jmp short .playToolSound ; ↓
.greenKey: ; 17cc
    inc word [GreenKeyCount]
    jmp short .playToolSound ; ↓
.yellowKey: ; 17d2
    inc word [YellowKeyCount]
    jmp short .playToolSound ; ↓
.flipper: ; 17d8
    inc word [FlipperCount]
    jmp short .playToolSound ; ↓
.fireBoots: ; 17de
    inc word [FireBootCount]
    jmp short .playToolSound ; ↓
.iceSkates: ; 17e4
    inc word [IceSkateCount]
    jmp short .playToolSound ; ↓
.suctionBoots: ; 17ea
    inc word [SuctionBootCount]

    ; play a sound effect?
.playToolSound: ; 17ee
    xor cx,cx ; PickUpToolSound
.playSound: ; 17f0
    mov ax,0x1
    mov [0x20],ax
    push ax
    push cx
    call 0x122b:0x56c ; 17f8 8:56c
    lea sp,[bp-0x2]
endfunc

; 1804

; Check whether chip has the key necessary to open a door,
; and possibly decrement the inventory count.
func CanOpenDoor
    sub sp,byte +0x2
    %arg tile:byte, consume:word
    mov al,[bp+0x6]
    sub ah,ah
    sub ax,BlueDoor
    jz .blueDoor ; ↓
    dec ax
    jz .redDoor ; ↓
    dec ax
    jz .greenDoor ; ↓
    dec ax
    jz .yellowDoor ; ↓
    jmp short .no ; ↓

.blueDoor: ; 1826
    cmp word [BlueKeyCount],byte +0x0
    jz .no ; ↓
    cmp word [bp+0x8],byte +0x0
    jz .yes ; ↓
    dec word [BlueKeyCount]
.yes: ; 1837
    mov ax,0x1
    mov [0x20],ax
    jmp short .label6 ; ↓
    nop

.redDoor: ; 1840
    cmp word [RedKeyCount],byte +0x0
    jz .no ; ↓
    cmp word [bp+0x8],byte +0x0
    jz .yes ; ↑
    dec word [RedKeyCount]
    jmp short .yes ; ↑
    nop

.greenDoor: ; 1854
    cmp word [GreenKeyCount],byte +0x0
    jz .no ; ↓
    ; green keys aren't expended
    jmp short .yes ; ↑
    nop

.yellowDoor: ; 185e
    cmp word [YellowKeyCount],byte +0x0
    jz .no ; ↓
    cmp word [bp+0x8],byte +0x0
    jz .yes ; ↑
    dec word [YellowKeyCount]
    jmp short .yes ; ↑
    nop

.no: ; 1872
    xor ax,ax
.label6: ; 1874
    lea sp,[bp-0x2]
endfunc

; 187c

; force floors, ice, fire, water
func HaveBootsForTile
    sub sp,byte +0x2
    mov al,[bp+0x6]
    sub ah,ah
    sub ax,Water
    cmp ax,ForceRandom-Water
    jna .label0 ; ↓
    jmp word .none ; ↓
.label0: ; 1899
    shl ax,1
    xchg ax,bx
    jmp word [cs:bx+0x18a2]
    nop
    dw .water ; ↓
    dw .fire ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .ice ; ↓
    dw .forceFloor ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .forceFloor ; ↓
    dw .forceFloor ; ↓
    dw .forceFloor ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .iceWall ; ↓
    dw .iceWall ; ↓
    dw .iceWall ; ↓
    dw .ice ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .none ; ↓
    dw .forceFloor ; ↓

.water: ; 1902
; 0x1902
    cmp word [FlipperCount],byte +0x0
.compare: ; 1907
    jz .returnZero ; ↓
    ; return True and set something mysterious
    mov ax,0x1
    mov [0x20],ax
    jmp short .end ; ↓
    nop

.fire: ; 1912
    cmp word [FireBootCount],byte +0x0
    jmp short .compare ; ↑
    nop

.ice: ; 191a
.iceWall:
    cmp word [IceSkateCount],byte +0x0
    jmp short .compare ; ↑
    nop

.forceFloor: ; 1922
    cmp word [SuctionBootCount],byte +0x0
    jmp short .compare ; ↑
    nop

.none: ; 192a
.returnZero:
    xor ax,ax
.end: ; 192c
    lea sp,[bp-0x2]
endfunc

; 1934

; can exit/enter tile?
; Returns whether something can enter (or exit) a panel or ice wall in a given direction.
func CheckPanelWalls
    sub sp,byte +0x2

    %arg tile:byte, xdir:word, ydir:word, flag:byte

    mov al,[tile]
    sub ah,ah
    cmp ax,PanelSE
    jnz .notPanelSE ; ↓
    jmp word .southEast ; ↓
.notPanelSE: ; 194e
    jna .label1 ; ↓
    jmp word .returnTrue ; ↓
.label1: ; 1953
    cmp al,IceWallNW
    jz .northWest ; ↓
    jg .label2 ; ↓
    sub al,PanelN
    jz .north ; ↓
    dec al ; PanelW
    jz .west ; ↓
    dec al ; PanelS
    jz .south ; ↓
    dec al ; PanelE
    jz .east ; ↓
    jmp word .returnTrue ; ↓
    nop
    nop
.label2: ; 196e
    sub al,IceWallNE
    jz .northEast ; ↓
    dec al ; IceWallSE
    jnz .label3 ; ↓
    jmp word .southEast ; ↓
.label3: ; 1979
    dec al ; IceWallSW
    jnz .label4 ; ↓
    jmp word .southWest ; ↓
.label4: ; 1980
    jmp word .returnTrue ; ↓
    nop

.north: ; 1984
    cmp word [flag],byte +0x0
    jz .label13 ; ↓
.label6: ; 198a
    cmp word [xdir],byte +0x0
    jz .label7 ; ↓
    jmp word .returnTrue ; ↓
.label7: ; 1993
    cmp word [ydir],byte +0x1
.label8: ; 1997
    jz .returnFalse ; ↓
    jmp word .returnTrue ; ↓
.returnFalse: ; 199c
    xor ax,ax
    jmp word .return ; ↓
    nop

.west: ; 19a2
    cmp word [flag],byte +0x0
    jz .label16 ; ↓
.label11: ; 19a8
    cmp word [xdir],byte +0x1
    jmp short .label28 ; ↓
    nop
    nop

.south: ; 19b0
    cmp word [flag],byte +0x0
    jz .label6 ; ↑
.label13: ; 19b6
    cmp word [xdir],byte +0x0
    jz .label14 ; ↓
    jmp word .returnTrue ; ↓
.label14: ; 19bf
    cmp word [ydir],byte -0x1
    jmp short .label8 ; ↑
    nop

.east: ; 19c6
    cmp word [flag],byte +0x0
    jz .label11 ; ↑
.label16: ; 19cc
    cmp word [xdir],byte -0x1
    jmp short .label28 ; ↓

.northWest: ; 19d2
    cmp word [flag],byte +0x0
    jz .label21 ; ↓
.label18: ; 19d8
    mov bx,[xdir]
    or bx,bx
    jnz .label27 ; ↓
    cmp word [ydir],byte +0x1
    jmp short .label26 ; ↓
    nop

.northEast: ; 19e6
    cmp word [flag],byte +0x0
    jz .label25 ; ↓
    mov bx,[xdir]
    or bx,bx
    jnz .label23 ; ↓
    cmp word [ydir],byte +0x1
    jmp short .label22 ; ↓
    nop

.southEast: ; 19fa
    cmp word [flag],byte +0x0
    jz .label18 ; ↑
.label21: ; 1a00
    mov bx,[xdir]
    or bx,bx
    jnz .label23 ; ↓
    cmp word [ydir],byte -0x1
.label22: ; 1a0b
    jz .returnFalse ; ↑
.label23: ; 1a0d
    inc bx
    jmp short .label28 ; ↓

.southWest: ; 1a10
    cmp word [flag],byte +0x0
    jz .label29 ; ↓
.label25: ; 1a16
    mov bx,[xdir]
    or bx,bx
    jnz .label27 ; ↓
    cmp word [ydir],byte -0x1
.label26: ; 1a21
    jnz .label27 ; ↓
    jmp word .returnFalse ; ↑
.label27: ; 1a26
    dec bx
.label28: ; 1a27
    jnz .returnTrue ; ↓
    cmp word [ydir],byte +0x0
    jmp word .label8 ; ↑
.label29: ; 1a30
    mov bx,[xdir]
    or bx,bx
    jnz .label30 ; ↓
    cmp word [ydir],byte +0x1
    jnz .label30 ; ↓
    jmp word .returnFalse ; ↑
.label30: ; 1a40
    inc bx
    jnz .returnTrue ; ↓
    cmp word [ydir],byte +0x0
    jnz .returnTrue ; ↓
    jmp word .returnFalse ; ↑
.returnTrue: ; 1a4c
    mov ax,0x1
.return: ; 1a4f
    lea sp,[bp-0x2]
endfunc

; 1a56

func ChipCanEnterTile
    sub sp,byte +0xe
    push di
    push si

    %define x (bp+0x6)
    %define y (bp+0x8)
    %define xdir (bp+0xa)
    %define ydir (bp+0xc)
    %define ptr (bp+0xe)
    %define flag1 (bp+0x10)
    %define upperOrLower (bp+0x12) ; 1=upper 0=lower

    %define tile (bp-0x3)
    %define tileTableRow (bp-0xa)
    %define tileIndex (bp-0xe)

    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    mov [tileIndex],bx
    add bx,[GameStatePtr]
    mov [bp-0xc],bx

    ; Can't enter clone machines
    cmp byte [bx+Lower],CloneMachine
    jnz .notACloneMachine ; ↓
    jmp word .nope ; ↓
.notACloneMachine: ; 1a82

    cmp word [upperOrLower],byte +0x0
    jz .readLowerTile ; ↓
    mov al,[bx+Upper]
    jmp short .label2 ; ↓
.readLowerTile: ; 1a8c
    mov al,[bx+Lower]
.label2: ; 1a90
    mov [tile],al

    ; fetch the appropriate row from the tile table
    mov bl,al
    sub bh,bh
    mov ax,bx
    shl bx,1
    add bx,ax
    shl bx,1
    lea di,[tileTableRow]
    lea si,[TileTable+bx]
    mov ax,ss
    mov es,ax
    movsw
    movsw
    movsw

    ; set *ptr to action from the table
    mov al,[tileTableRow+1]
    sub ah,ah
    mov bx,[ptr]
    mov [bx],ax

    ; if table says we can enter (1), return 1
    cmp byte [tileTableRow+0],0x1
    jnz .tableIsnt1 ; ↓
.return1: ; 1abd
    mov ax,0x1
    jmp word .end ; ↓
    nop
.tableIsnt1: ; 1ac4
    ; if table says it's more complicated (2), keep going
    cmp byte [tileTableRow+0],0x2
    jz .tableIs2 ; ↓
    ; otherwise return 0
    jmp word .nope ; ↓

.tableIs2: ; 1acd
    ; if tile is transparent, check the lower tile instead
    cmp byte [tile],FirstTransparent
    jb .notTransparent ; ↓
    cmp byte [tile],LastTransparent
    ja .notTransparent ; ↓
    jmp word .checkLowerTile ; ↓
.notTransparent: ; 1adc
    ; if the tile is a block, check the lower tile insteadk
    cmp byte [tile],Block
    jnz .doJumpTable ; ↓
    jmp word .checkLowerTile ; ↓

.doJumpTable: ; 1ae5
    mov di,[x]
    mov si,[y]
    mov al,[tile]
    sub ah,ah
    sub ax,Water
    cmp ax,ForceRandom - Water
    jna .label8 ; ↓
    jmp word .nope ; ↓
.label8: ; 1afb
    shl ax,1
    xchg ax,bx
    jmp word [cs:bx+.jumpTable]
    nop
.jumpTable:
    dw .label9          ; Water
    dw .label9          ; Fire
    dw .nope            ; InvisibleWall
    dw .panelWalls      ; PanelN
    dw .panelWalls      ; PanelW
    dw .panelWalls      ; PanelS
    dw .panelWalls      ; PanelE
    dw .nope            ; Block
    dw .nope            ; Dirt
    dw .label9          ; Ice
    dw .label9          ; ForceS
    dw .nope            ; BlockN
    dw .nope            ; BlockW
    dw .nope            ; BlockS
    dw .nope            ; BlockE
    dw .label9          ; ForceN
    dw .label9          ; ForceE
    dw .label9          ; ForceW
    dw .nope            ; Exit
    dw .doors           ; BlueDoor
    dw .doors           ; RedDoor
    dw .doors           ; GreenDoor
    dw .doors           ; YellowDoor
    dw .iceCorners      ; IceWallNW
    dw .iceCorners      ; IceWallNE
    dw .iceCorners      ; IceWallSE
    dw .iceCorners      ; IceWallSW
    dw .fakeFloor       ; FakeFloor
    dw .hiddenWall      ; FakeWall
    dw .nope            ; Unused20
    dw .thief           ; Thief
    dw .socket          ; Socket
    dw .nope            ; ToggleButton
    dw .nope            ; CloneButton
    dw .nope            ; ToggleWall
    dw .nope            ; ToggleFloor
    dw .nope            ; TrapButton
    dw .nope            ; TankButton
    dw .nope            ; Teleport
    dw .nope            ; Bomb
    dw .nope            ; Trap
    dw .hiddenWall      ; HiddenWall
    dw .nope            ; Gravel
    dw .popupWall       ; PopupWall
    dw .nope            ; Hint
    dw .panelWalls      ; PanelSE
    dw .nope            ; CloneMachine
    dw .label9          ; ForceRandom

.label9: ; 1b64
    ; force floors, ice, water, fire
    ; if we have boots for this tile,
    ; override the returned action to be 4
    ; instead of whatever the table says
    mov al,[tile]
    push ax
    call 0x1b91:HaveBootsForTile ; 1b68 3:187c
    add sp,byte +0x2
    or ax,ax
    jnz .label10 ; ↓
    jmp word .return1 ; ↑
.label10: ; 1b77
    mov bx,[ptr]
    mov word [bx],0x4
    jmp word .return1 ; ↑
    nop


.panelWalls: ; 1b82
    push byte +0x1
    push word [ydir]
    push word [xdir]
    mov al,[tile]
    push ax
    call 0x1bab:CheckPanelWalls ; 1b8e 3:1934
    add sp,byte +0x8
.label12: ; 1b96
    or ax,ax
    jnz .label13 ; ↓
    jmp word .nope ; ↓
.label13: ; 1b9d
    jmp word .return1 ; ↑


.doors: ; 1ba0
    mov si,[flag1]
    push si
    mov al,[tile]
    push ax
    call 0x1bdd:CanOpenDoor ; 1ba8 3:1804
    add sp,byte +0x4
    or ax,ax
    jnz .label15 ; ↓
    jmp word .nope ; ↓
.label15: ; 1bb7
    or si,si
    jnz .label16 ; ↓
    jmp word .return1 ; ↑
.label16: ; 1bbe
    push byte +0x1
    push byte OpenDoorSound
.label17: ; 1bc2
    call 0x1c34:0x56c ; 1bc2 8:56c
    add sp,byte +0x4
    jmp word .return1 ; ↑
    nop


.iceCorners: ; 1bce
    push byte +0x1
    push word [ydir]
    push word [xdir]
    mov al,[tile]
    push ax
    call 0x1c3e:CheckPanelWalls ; 1bda 3:1934
    add sp,byte +0x8
    or ax,ax
    jnz .label19 ; ↓
    jmp word .nope ; ↓
.label19: ; 1be9
    jmp word .label9 ; ↑

.fakeFloor: ; 1bec
    cmp word [flag1],byte +0x0
    jnz .label21 ; ↓
    jmp word .return1 ; ↑
.label21: ; 1bf5
    mov bx,[tileIndex]
    mov si,[GameStatePtr]
    mov byte [bx+si+Upper],Floor
    jmp word .return1 ; ↑

.hiddenWall: ; 1c02
    cmp word [flag1],byte +0x0
    jnz .label23 ; ↓
    jmp word .nope ; ↓
.label23: ; 1c0b
    mov bx,[tileIndex]
    mov ax,si
    mov si,[GameStatePtr]
    mov byte [bx+si+Upper],Wall
    push ax
    push di
    call 0x1702:0x2b2 ; 1c19
    add sp,byte +0x4
    jmp short .nope ; ↓
    nop


.thief: ; 1c24
    cmp word [flag1],byte +0x0
    jnz .label25 ; ↓
    jmp word .return1 ; ↑
.label25: ; 1c2d
    push byte +0x1
    push byte ThiefSound
    call 0x170e:0x56c ; 1c31 8:56c
    add sp,byte +0x4
    push byte +0x1
    call 0x1c8b:ResetInventory ; 1c3b 3:1734
    add sp,byte +0x2
    jmp word .return1 ; ↑

.socket: ; 1c46
    cmp word [ChipsRemainingCount],byte +0x0
    jnz .nope ; ↓
    cmp word [flag1],byte +0x0
    jnz .label27 ; ↓
    jmp word .return1 ; ↑
.label27: ; 1c56
    push byte +0x1
    push byte +0x4
    jmp word .label17 ; ↑
    nop

.popupWall: ; 1c5e
    cmp word [flag1],byte +0x0
    jnz .label29 ; ↓
    jmp word .return1 ; ↑
.label29: ; 1c67
    mov bx,[tileIndex]
    mov si,[GameStatePtr]
    mov byte [bx+si],0x1
    jmp word .return1 ; ↑

.checkLowerTile: ; 1c74
    push byte +0x0
    push byte +0x0
    lea ax,[bp-0x4]
    push ax
    push word [ydir]
    push word [xdir]
    push word [y]
    push word [x]
    call 0x1d31:ChipCanEnterTile ; 1c88 3:1a56
    add sp,byte +0xe
    jmp word .label12 ; ↑
    nop
.nope: ; 1c94
    xor ax,ax
    mov bx,[ptr]
    mov [bx],ax
.end: ; 1c9b
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 1ca4

func BlockCanEnterTile
    sub sp,byte +0xc
    push di
    push si

    %arg tile:byte, x:word, y:word, xdir:word, ydir:word, outPtr:byte
    %define tileTableRow (bp-0xa)

    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    mov [bp-0xc],bx

    ; Can't enter clone machines
    cmp byte [bx+Lower],CloneMachine
    jz .nope ; ↓

    mov al,[bx+Upper]
    mov [bp-0x3],al

    mov bl,al
    sub bh,bh
    ; multiply by 6
    mov ax,bx
    shl bx,1
    add bx,ax
    shl bx,1
    ; load six bytes from the tile table
    ; onto the stack
    lea di,[tileTableRow]
    lea si,[TileTable+bx]
    mov ax,ss
    mov es,ax
    movsw
    movsw
    movsw

    mov al,[tileTableRow+3]
    sub ah,ah
    mov bx,[outPtr]
    mov [bx],ax

    cmp byte [tileTableRow+2],0x1
    jnz .label1 ; ↓
.label0: ; 1cf9
    mov ax,0x1
    jmp short .end ; ↓
    nop
    nop
.label1: ; 1d00
    cmp byte [tileTableRow+2],0x2
    jnz .nope ; ↓
    mov al,[bp-0x3]
    sub ah,ah
    cmp ax,PanelSE
    jz .checkPanelWallsOrIceWalls ; ↓
    ja .nope ; ↓
    sub al,PanelN
    jl .nope ; ↓
    sub al,PanelE-PanelN
    jng .checkPanelWallsOrIceWalls ; ↓
    sub al,IceWallNW-PanelE
    jl .nope ; ↓
    sub al,IceWallSW-IceWallNW
    jg .nope ; ↓
.checkPanelWallsOrIceWalls: ; 1d22
    push byte +0x1
    push word [ydir]
    push word [xdir]
    mov al,[bp-0x3]
    push ax
    call 0x1284:CheckPanelWalls ; 1d2e 3:1934
    add sp,byte +0x8
    or ax,ax
    jnz .label0 ; ↑
.nope: ; 1d3a
    xor ax,ax
    mov bx,[outPtr]
    mov [bx],ax
.end: ; 1d41
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 1d4a

func MonsterCanEnterTile
    sub sp,byte +0xc
    push di
    push si

    %arg tile:byte, x:word, y:word, xdir:word, ydir:word, outPtr:byte
    %define tileTableRow (bp-0xa)

    mov di,[y]
    mov si,[x]
    mov bx,di
    shl bx,byte 0x5
    add bx,[GameStatePtr]
    add bx,si
    mov [bp-0xc],bx

; if tile is on a clone machine, return
    cmp byte [bx+Lower],CloneMachine
    jnz .notACloneMachine ; ↓
    jmp word .clearOutAndReturnZero ; ↓

.notACloneMachine: ; 1d77
    mov al,[bx+Upper]
    mov [bp-0x3],al
    cmp al,ChipN
    jb .checkSwimmingChip ; ↓
    cmp al,ChipE
    jna .getBottomTile ; ↓
.checkSwimmingChip: ; 1d84
    cmp byte [bp-0x3],SwimN
    jb .label3 ; ↓
    cmp byte [bp-0x3],SwimE
    ja .label3 ; ↓

; creature is chip or swimming chip
.getBottomTile: ; 1d90
    mov al,[bx+Lower]
    mov [bp-0x3],al

.label3: ; 1d97
    mov bl,[bp-0x3]
    sub bh,bh
    ; multiply by 6
    mov ax,bx
    shl bx,1
    add bx,ax
    shl bx,1
    ; load six bytes from the tile table
    ; onto the stack
    lea di,[tileTableRow]
    lea si,[TileTable+bx]
    mov ax,ss
    mov es,ax
    movsw
    movsw
    movsw

    ; copy action to outPtr
    mov al,[tileTableRow + 5]
    sub ah,ah
    mov bx,[outPtr]
    mov [bx],ax

    ; if table entry == 1 return true
    cmp byte [tileTableRow + 4],0x1
    jnz .label5 ; ↓
.returnTrue: ; 1dc2
    mov ax,0x1
    jmp word .return

;if table entry == 2 do some other stuff
.label5: ; 1dc8
    cmp byte [tileTableRow + 4],0x2
    jz .label6 ; ↓

; otherwise return zero
    jmp word .clearOutAndReturnZero ; ↓

; other stuff ==>
.label6: ; 1dd1
    mov si,[outPtr]
    mov al,[bp-0x3]
    sub ah,ah
    cmp ax,PanelSE
    jz .thinWalls ; ↓
    ja .clearOutAndReturnZero ; ↓
    cmp al,Fire
    jz .fire ; ↓
    jg .checkPanelWallsOrIceWalls ; ↓
    sub al,Water
    jz .water ; ↓
    jmp short .clearOutAndReturnZero ; ↓
    nop
    nop

; check if the tile is a panel wall or ice wall
.checkPanelWallsOrIceWalls: ; 1dee
    sub al,PanelN
    jl .clearOutAndReturnZero ; ↓
    sub al,PanelE - PanelN
    jng .thinWalls ; ↓
    sub al,IceWallNW - PanelE
    jl .clearOutAndReturnZero ; ↓
    sub al,IceWallSW - IceWallNW
    jng .thinWalls ; ↓
    jmp short .clearOutAndReturnZero ; ↓

.water: ; 1e00
    mov al,[tile]
    sub ah,ah
    sub ax,GliderN
    jl .returnTrue ; ↑
    jo .returnTrue ; ↑
    sub ax,GliderE - GliderN
    jg .returnTrue ; ↑
.label9: ; 1e11
    mov word [si],0x1
    jmp short .returnTrue ; ↑
    nop

.fire: ; 1e18
    mov al,[tile]
    sub ah,ah
    sub ax,BugN
    jl .returnTrue ; ↑
    jo .returnTrue ; ↑
    sub ax,BugE - BugN
    jng .clearOutAndReturnZero ; ↓
    dec ax ; Tank
    jl .returnTrue ; ↑
    sub ax,TankE - TankN
    jng .label9 ; ↑
    sub ax,ParameciumN - TankE
    jl .returnTrue ; ↑
    sub ax,ParameciumE - ParameciumN
    jng .clearOutAndReturnZero ; ↓
    jmp short .returnTrue ; ↑
    nop

.thinWalls: ; 1e3e
    push byte +0x1
    push word [ydir]
    push word [xdir]
    mov al,[bp-0x3]
    push ax
    call 0x1edc:CheckPanelWalls ; 1e4a 3:0x1934
    add sp,byte +0x8
    or ax,ax
    jz .clearOutAndReturnZero ; ↓
    jmp word .returnTrue ; ↑
.clearOutAndReturnZero: ; 1e59
    xor ax,ax
    mov bx,[outPtr]
    mov [bx],ax
.return: ; 1e60
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 1e6a

func PressTankButton
    sub sp,byte +0xc
    push di
    push si
    %define x (bp-0x6)
    %define index (bp-0x8)
    %define xdir (bp-0xc)
    %define ydir (bp-0xa)
    %define tile (bp-0x3)
    push word [bp+0x8]
    push byte SwitchSound
    call 0x2130:0x56c ; 1e7e 8:0x56c PlaySoundEffect
    add sp,byte +0x4
    mov word [index],0x0
    mov bx,[GameStatePtr]
    cmp word [bx+MonsterListLen],byte +0x0
    jg .label0 ; ↓
    jmp word .end ; ↓
.label0: ; 1e99
    xor si,si
.loop: ; 1e9b
    les bx,[bx+MonsterListPtr]
    mov al,[es:bx+si+Monster.tile]
    mov [tile],al
    cmp al,TankN
    jz .isATank ; ↓
    cmp al,TankW
    jz .isATank ; ↓
    cmp al,TankS
    jz .isATank ; ↓
    cmp al,TankE
    jz .isATank ; ↓
    jmp word .loopCheck ; ↓
.isATank: ; 1eb8
    ; get position from monster list
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,si
    mov di,[es:bx+Monster.x]
    mov ax,[es:bx+Monster.y]
    mov [x],ax
    ; get direction from tile
    lea ax,[ydir]
    push ax
    lea cx,[xdir]
    push cx
    mov dl,[tile]
    push dx
    call 0x1ef2:GetMonsterDir ; 1ed9 3:0x4d8
    add sp,byte +0x6
    ; turn tile left and store in map
    lea ax,[ydir]
    push ax
    lea cx,[xdir]
    push cx
    push word [ydir]
    push word [xdir]
    call 0x1f04:TurnLeft ; 1eef 3:0xb0
    add sp,byte +0x8
    push word [ydir]
    push word [xdir]
    mov al,[tile]
    push ax
    call 0x1f3b:SetTileDir ; 1f01 3:0x486
    add sp,byte +0x6
    mov bx,[x]
    shl bx,byte 0x5
    add bx,di ; y
    mov cx,di
    mov di,[GameStatePtr]
    mov [di+bx+Upper],al ; store tile
    ; update display?
    push word [x]
    push cx ; y
    push word [bp+0x6]
    mov di,bx
    call 0x204d:0x1ca ; 1f22 2:0x1ca
    add sp,byte +0x6
    ; turn direction left again (180 degrees total)
    ; and store new direction in monster list
    lea ax,[ydir]
    push ax
    lea cx,[xdir]
    push cx
    push word [ydir]
    push word [xdir]
    call 0x1f6b:TurnLeft ; 1f38 3:0xb0
    add sp,byte +0x8
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov ax,[xdir]
    mov [es:bx+si+Monster.xdir],ax
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov ax,[ydir]
    mov [es:bx+si+Monster.ydir],ax
    ; update the tile stored in the monster list
    push word [ydir]
    push word [xdir]
    mov al,[tile]
    push ax
    call 0x1b6b:SetTileDir ; 1f68 3:0x486
    add sp,byte +0x6
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov [es:bx+si+Monster.tile],al
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov al,[es:bx+si+Monster.tile]
    mov bx,[GameStatePtr]
    mov [bx+di+Upper],al
.loopCheck: ; 1f8c
    add si,byte Monster_size
    inc word [index]
    mov ax,[index]
    mov bx,[GameStatePtr]
    cmp [bx+MonsterListLen],ax
    jng .end ; ↓
    jmp word .loop ; ↑
.end: ; 1fa2
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 1fac

func PressToggleButton
    sub sp,byte +0xa
    push di
    push si
    %define x (bp-0x4)
    %define y (bp-0x6)
    xor di,di
    mov bx,[GameStatePtr]
    cmp [bx+ToggleListLen],di
    jg .label0 ; ↓
    jmp word .end ; ↓
.label0: ; 1fca
    xor si,si
.loop: ; 1fcc
    ; get toggle wall coordinates
    les bx,[bx+ToggleListPtr]
    mov ax,[es:bx+si+Point.x]
    mov [x],ax
    add bx,si
    mov cx,[es:bx+Point.y]
    mov [y],cx

.toggleUpper:
    mov bx,cx
    shl bx,byte 0x5
    add bx,ax
    add bx,[GameStatePtr]
    mov al,[bx+Upper]
    mov [bp-0x7],al
    cmp al,ToggleWall
    jnz .upperIsNotAWall ; ↓
.setUpperFloor:
    mov bx,cx
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    mov byte [bx+Upper],ToggleFloor
    jmp short .toggleLower ; ↓
.upperIsNotAWall: ; 2004
    cmp byte [bp-0x7],ToggleFloor
    jnz .toggleLower ; ↓
    mov bx,cx
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    mov byte [bx+Upper],ToggleWall

.toggleLower: ; 2019
    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    add bh,(Lower>>8)
    mov al,[bx]
    mov [bp-0x7],al
    cmp al,ToggleWall
    jnz .lowerIsNotAWall ; ↓
    mov byte [bx],ToggleFloor
    jmp short .label5 ; ↓
    nop
.lowerIsNotAWall: ; 2038
    cmp byte [bp-0x7],ToggleFloor
    jnz .label5 ; ↓
    mov byte [bx],ToggleWall

.label5: ; 2041
    ; update display?
    push word [y]
    push word [x]
    push word [bp+0x6]
    call 0x1c1c:0x1ca ; 204a 2:0x1ca
    add sp,byte +0x6
    ; check loop condition
    add si,byte Point_size
    inc di
    mov bx,[GameStatePtr]
    cmp [bx+ToggleListLen],di
    jng .end ; ↓
    jmp word .loop ; ↑
.end: ; 2063
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 206c

; Finds multiple traps at x,y.
; Returns the first and last index in the trap index (inclusive).
func FindTrapSpan
    %arg x:word, y:word, firstIndexOut:word, lastIndexOut:word

    sub sp,byte +0x2
    push di
    push si
    ; look for a trap connected to the given x,y coordinates
    xor cx,cx
    mov bx,[GameStatePtr]
    cmp [bx+TrapListLen],cx
    jg .label0 ; ↓
    jmp word .returnZero ; ↓
.label0: ; 208a
    mov si,bx
    mov ax,[si+TrapListPtr]
    mov dx,[si+TrapListSeg]
    add ax,0x4
    mov bx,ax
    mov es,dx
    mov di,[x]
.loop1: ; 209e
    cmp [es:bx+Connection.toX-4],di
    jnz .label2 ; ↓
    mov ax,[y]
    cmp [es:bx+Connection.toY-4],ax
    jz .found ; ↓
.label2: ; 20ac
    add bx,byte Connection_size
    inc cx
    cmp [si+TrapListLen],cx
    jg .loop1 ; ↑
    jmp short .returnZero ; ↓

.found: ; 20b8
    ; index in cx
    ; store found index in *firstIndexOut
    mov bx,[firstIndexOut]
    mov [bx],cx

    ; there might be a run of traps with the same destination  coordinates
    ; look for where the run ends
    inc cx ; index++
    mov bx,[GameStatePtr]
    cmp [bx+TrapListLen],cx
    jng .break ; ↓
    mov si,bx
    mov ax,[si+TrapListPtr]
    mov dx,[si+TrapListSeg]
    ; si = cx*10
    mov si,cx
    shl si,byte 0x2
    add si,cx
    shl si,1
    ; si = &traplist[i] + 4
    add ax,si
    add ax,0x4
    mov bx,ax
    mov es,dx
    mov di,[y]
.loop2: ; 20e7
    mov ax,[x]
    cmp [es:bx+Connection.toX-4],ax
    jnz .break ; ↓
    cmp [es:bx+Connection.toY-4],di
    jnz .break ; ↓
    add bx,byte Connection_size
    inc cx
    mov si,[GameStatePtr]
    cmp [si+TrapListLen],cx
    jg .loop2 ; ↑
.break: ; 2103
    ; store i-1 in *lastIndexOut
    dec cx
    mov bx,[lastIndexOut]
    mov [bx],cx
    mov ax,0x1
    jmp short .end ; ↓
.returnZero: ; 210e
    xor ax,ax
.end: ; 2110
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 211a

func PressTrapButton
    %arg x:word, y:word, arg:word
    %define firstTrap (bp-0x6)
    %define lastTrap (bp-0x4)
    sub sp,byte +0x6
    push si
    push word [arg]
    push byte SwitchSound
    call 0x1bc5:0x56c ; 212d 8:0x56c PlaySoundEffect
    add sp,byte +0x4
    push word [y]
    push word [x]
    call 0x216f:FindTrapByButton ; 213b 3:0x2270
    add sp,byte +0x4
    mov si,ax
    or si,si
    jl .end ; ↓
    lea ax,[lastTrap]
    push ax
    lea ax,[firstTrap]
    push ax
    mov ax,si
    shl si,byte 0x2
    add si,ax
    shl si,1
    mov bx,[GameStatePtr]
    les bx,[bx+TrapListPtr]
    add bx,si
    push word [es:bx+Connection.toY]
    push word [es:bx+Connection.toX]
    call 0x21ca:FindTrapSpan ; 216c 3:0x206c
    add sp,byte +0x8
    or ax,ax
    jz .end ; ↓

    ; set flag = 0 for all traps between first and last
    mov cx,[firstTrap]
    cmp cx,[lastTrap]
    jg .end ; ↓
    mov bx,cx
    mov ax,cx
    shl bx,byte 0x2
    add bx,ax
    shl bx,1
.loop: ; 218b
    mov si,[GameStatePtr]
    les si,[si+TrapListPtr]
    mov word [es:bx+si+Connection.flag],0x0
    add bx,byte Connection_size
    inc cx
    cmp cx,[lastTrap]
    jng .loop ; ↑
.end: ; 21a2
    pop si
    lea sp,[bp-0x2]
endfunc

; 21aa

func EnterTrap
    sub sp,byte +0xa
    push di
    push si
    %arg xdest:word, ydest:word, xsrc:word, ysrc:word
    %define firstTrap (bp-0x6)
    %define lastTrap (bp-0x4)

    lea ax,[lastTrap]
    push ax
    lea ax,[firstTrap]
    push ax
    push word [ydest]
    push word [xdest]
    call 0x234d:FindTrapSpan ; 21c7 3:0x206c
    add sp,byte +0x8
    or ax,ax
    jnz .label0 ; ↓
    jmp word .end ; ↓
.label0: ; 21d6
    mov di,0x1
    mov cx,[firstTrap]
    cmp cx,[lastTrap]
    jg .label4 ; ↓
    mov [bp-0x8],di
    ;
    mov si,[GameStatePtr]
    mov ax,[si+TrapListPtr]
    mov dx,[si+TrapListSeg]
    ; si = cx*10
    mov si,cx
    shl si,byte 0x2
    add si,cx
    shl si,1
    add ax,si
    add ax,0x2
    mov bx,ax
    mov es,dx
    mov di,[xsrc]
.loop1: ; 2205
    lea si,[bx+Connection.fromX-0x2]
    mov ax,[es:si]
    mov [bp-0xa],ax
    mov si,[es:bx+Connection.fromY-0x2]
    ; look up connection src coords & check if there is a trap button in the
    ; upper layer
    shl si,byte 0x5
    add si,ax
    add si,[GameStatePtr]
    cmp byte [si],TrapButton
    jz .continue ; ↓
    ; do the provided src coords match the connection coords?
    cmp ax,di
    jnz .break1 ; ↓
    mov ax,[ysrc]
    cmp [es:bx],ax
    jnz .break1 ; ↓
.continue: ; 222b
    add bx,byte Connection_size
    inc cx
    cmp cx,[lastTrap]
    jng .loop1 ; ↑
    mov di,[bp-0x8]
    jmp short .label4 ; ↓
    nop
.break1: ; 223a
    xor di,di
.label4: ; 223c
    ; Update status of all connected traps
    mov ax,[firstTrap]
    mov cx,ax
    cmp [lastTrap],ax
    jl .end ; ↓
    mov bx,ax
    shl bx,byte 0x2
    add bx,ax
    shl bx,1
    mov [bp-0x8],di
.loop2: ; 2252
    mov si,[GameStatePtr]
    les si,[si+TrapListPtr]
    mov [es:bx+si+Connection.flag],di
    add bx,byte Connection_size
    inc cx
    cmp cx,[lastTrap]
    jng .loop2 ; ↑
.end: ; 2267
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 2270

; Finds the trap connection associated with a button at the given coordinates.
; Returns index into the trap list or -1.
func FindTrapByButton
    %arg x:word, y:word
    sub sp,byte +0x2
    push di
    push si
    xor cx,cx
    mov bx,[GameStatePtr]
    cmp [bx+TrapListLen],cx
    jng .label3 ; ↓
    mov si,bx
    les bx,[si+TrapListPtr]
    mov di,[bp+0x6]
.label0: ; 2294
    cmp [es:bx],di
    jnz .label1 ; ↓
    mov ax,[bp+0x8]
    cmp [es:bx+0x2],ax
    jz .label2 ; ↓
.label1: ; 22a2
    add bx,byte +0xa
    inc cx
    cmp [si+TrapListLen],cx
    jg .label0 ; ↑
    jmp short .label3 ; ↓
.label2: ; 22ae
    mov ax,cx
    jmp short .label4 ; ↓
.label3: ; 22b2
    mov ax,0xffff
.label4: ; 22b5
    pop si
    pop di
    lea sp,[bp-0x2]
endfunc

; 22be

; Search trap list for trap at x,y
; Returns an index.
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

func AddTrap_Unused
    sub sp,byte +0x2
    push si
    mov bx,[GameStatePtr]
    mov ax,[bx+0x93e]
    cmp [bx+0x93c],ax
    jl .label0 ; ↓
    push byte Connection_size
    push byte +0x8
    mov ax,bx
    add ax,TrapListCap
    push ax
    mov ax,bx
    add ax,TrapListPtr
    push ax
    mov ax,bx
    add ax,TrapListHandle
    push ax
    call 0x2467:GrowArray ; 234a 3:0x1a4
    add sp,byte +0xa
    or ax,ax
    jnz .label0 ; ↓
    mov ax,0xffff
    jmp short .label1 ; ↓
    nop
.label0: ; 235c
    mov si,[GameStatePtr]
    mov bx,[si+TrapListLen]
    inc word [si+TrapListLen]
    mov ax,[bp+0x6]
    mov si,bx
    mov dx,bx
    mov cx,bx
    shl si,byte 0x2
    add si,cx
    shl si,1
    mov bx,[GameStatePtr]
    les bx,[bx+TrapListPtr]
    mov [es:bx+si+Connection.fromX],ax
    mov bx,[GameStatePtr]
    les bx,[bx+TrapListPtr]
    mov ax,[bp+0x8]
    mov [es:bx+si+Connection.fromY],ax
    mov bx,[GameStatePtr]
    les bx,[bx+TrapListPtr]
    mov word [es:bx+si+Connection.toX],-1
    mov bx,[GameStatePtr]
    les bx,[bx+TrapListPtr]
    mov word [es:bx+si+Connection.toY],-1
    mov bx,[GameStatePtr]
    les bx,[bx+TrapListPtr]
    mov word [es:bx+si+Connection.flag],0x0
    mov ax,dx
.label1: ; 23be
    pop si
    lea sp,[bp-0x2]
endfunc

; 23c6
; DeleteTrap_Unused

; 2442 PressCloneButton
; 260e FindCloneMachine
; 265c AddCloneMachine (unused)
; 26f6 DeleteCloneMachine (unused)
; 276a EnterTeleport
; 2910 FindTeleport

INCBIN "base.exe", 0x6200+0x23c6, 0x295e-0x23c6

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
    call 0x2501:GrowArray ; 2990 3:0x1a4
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

func DeleteTeleport_Unused
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

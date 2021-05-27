SEGMENT CODE ; 3

; Game logic

%include "base.inc"
%include "constants.asm"
%include "structs.asm"
%include "variables.asm"
%include "func.mac"
%include "if.mac"

%include "extern.inc"
%include "windows.inc"

EXTERN atoi
EXTERN atol
EXTERN rand

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
    mov ax,[si+MonsterListPtr+FarPtr.Off]
    mov dx,[si+MonsterListPtr+FarPtr.Seg]
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
    add bx,byte Monster_size
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
    mov ax,[si+SlipListPtr+FarPtr.Off]
    mov dx,[si+SlipListPtr+FarPtr.Seg]
    inc ax
    mov bx,ax
    mov es,dx
    mov di,[x]
.loop:
    cmp [es:bx+Slipper.x-1],di
    jnz .next
    mov ax,[y]
    cmp [es:bx+Slipper.y-1],ax
    jz .found
.next:
    add bx,byte Slipper_size
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
    call far KERNEL.GlobalUnlock ; 1bc
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
    call far KERNEL.GlobalReAlloc ; 1d6
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
    call far KERNEL.GlobalAlloc ; 1e9

.lock: ; 1ee
    ; update hMem
    ; and call GlobalLock to get a pointer
    ; to the allocated memory
    mov si,ax
    or si,si
    if nz
        mov bx,[hMem]
        mov [bx],si
    endif ; 1f9
    mov bx,[hMem]
    push word [bx]
    call far KERNEL.GlobalLock ; 1fe
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
endfunc

; 228
func NewMonster
    %arg tile:byte
    %arg x:word, y:word
    %arg xdir:word, ydir:word
    %arg cloning:word
    %define pos (bp-6)
    %define lowerTile (bp-3)

    sub sp,byte +0x6
    push si

    ; Grow monster list if necessary.
    mov bx,[GameStatePtr]
    mov ax,[bx+MonsterListCap]
    cmp [bx+MonsterListLen],ax
    jl .addMonsterToList
    push byte Monster_size
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
    call far GrowArray ; 25a 3:1a4
    add sp,byte +0xa
    or ax,ax
    if z
        jmp word .end
    endif

.addMonsterToList: ; 269
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
    if ne
        ; ...push the upper tile down
        mov al,[bx+si+Upper]
        add bx,si
        mov [bx+Lower],al
        mov bx,[pos]
        add bx,[GameStatePtr]
        mov al,[bx+Lower]
        mov [lowerTile],al
    endif ; 35c
    ; Set the top tile to tile
    mov al,[tile]
    mov bx,[pos]
    mov si,[GameStatePtr]
    mov [bx+si+Upper],al

    ; If the monster is on a trap...
    mov bx,[GameStatePtr]
    inc word [bx+MonsterListLen]
    cmp byte [lowerTile],Trap
    if e
        ; ... call EnterTrap and return
        push byte -0x1
        push byte -0x1
        push word [y]
        push word [x]
        call far EnterTrap ; 380 3:21aa
        add sp,byte +0x8
        jmp short .end
    endif ; 38a

    cmp byte [lowerTile],ChipN
    jb .notChip
    cmp byte [lowerTile],ChipE
    jna .deathByMonster
.notChip: ; 396
    cmp byte [lowerTile],SwimN
    jb .end
    cmp byte [lowerTile],SwimE
    ja .end
.deathByMonster: ; 3a2
    ; Monster landed on Chip (or Swimming Chip)
    ; Set cause of death
    mov bx,[GameStatePtr]
    mov word [bx+Autopsy],Eaten
.end: ; 3ac
    pop si
endfunc

; 3b4
func DeleteMonster
    sub sp,byte +0x8
    push di
    push si

    %arg    idx:word
    %local  offset:word

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
    if nz
        push byte +0x2          ; unused
        push word [es:bx+Monster.y]
        push word [es:bx+Monster.x]
        mov al,[es:bx+Monster.tile]
        push ax                 ; unused
        call far DeleteSlipperAt ; 3f6 3:12be
        add sp,byte +0x8
    endif ; 3fe
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
    mov ax,[bx+MonsterListPtr+FarPtr.Off]
    mov dx,[bx+MonsterListPtr+FarPtr.Seg]
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
endfunc

; 45e
func DeleteMonsterAt
    sub sp,byte +0x2
    %arg dunno:word x:word, y:word
    push word [y]
    push word [x]
    call far FindMonster ; 471 3:471
    add sp,byte +0x4
    push ax
    call far DeleteMonster ; 47a 3:47a
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
endfunc

; 4d8
func GetMonsterDir
    sub sp,byte +0x2
    %arg tile:byte, xOut:word, yOut:word
    cmp byte [tile],FirstMonster
    jb .notAMonster
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
endfunc

; 54c

; Initialize monster list, toggle walls, teleports, and chip's position.
func InitBoard
    sub sp,byte +0xc
    push di
    push si

    %define tile (bp-3)
    %local local_4:byte ; -4
    %local coords:word ; -6
    %define xoff (bp-0x6)
    %local yoff:word ; -8
    %local y:word ; -a

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
    jb .next
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
    call far NewMonster ; 5c6 3:228
    add sp,byte +0xc
.next: ; 5ce
    add si,byte +0x2
    inc di
    mov bx,[GameStatePtr]
    cmp [bx+InitialMonsterListLen],di
    jg .loop

.noMonsters: ; 5dc

    ; Loop over the game board
    xor di,di
    mov [yoff],di
.loopY: ; 5e1
    xor si,si
    mov [xoff],di ; unused
.loopX: ; 5e6
    ; Get tile at x,y
    mov bx,[GameStatePtr]
    add bx,[yoff]
    mov al,[bx+si+Upper]
    mov [tile],al

    ; If tile is a monster, get lower tile
    cmp al,FirstMonster
    jb .notAMonster
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
    if l
        jmp word .nextX
    endif ; 617
    ; Bail if the subtraction overflowed,
    ; which is impossible.
    if o
        jmp word .nextX
    endif ; 61c
    dec ax
    jng .toggleWallOrFloor
    sub ax,0x3
    if z
        jmp word .teleport
    endif ; 627
    sub ax,0x43
    if l
        jmp word .nextX
    endif ; 62f
    sub ax,0x3
    if le
        jmp word .chip
    endif ; 637
    jmp word .nextX

.toggleWallOrFloor: ; 63a
    ; Add toggle wall or floor to toggle list.
    ; No idea why this isn't its own function like all the other lists.
    mov bx,[GameStatePtr]
    mov ax,[bx+ToggleListCap]
    cmp [bx+ToggleListLen],ax
    if nl
        push byte Point_size
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
        call far GrowArray ; 65e 3:1a4
        add sp,byte +0xa
        or ax,ax
        jz .nextX
    endif ; 66a
    mov bx,[GameStatePtr]
    mov bx,[bx+ToggleListLen]
    mov ax,bx
    mov bx,[GameStatePtr]
    mov cx,[bx+ToggleListPtr+FarPtr.Off]
    mov dx,[bx+ToggleListPtr+FarPtr.Seg]
    mov bx,ax
    shl bx,byte 0x2
    mov es,dx
    add bx,cx
    mov [es:bx+Point.x],si ; = x
    mov bx,[GameStatePtr]
    mov bx,[bx+ToggleListLen]
    mov ax,bx
    mov bx,[GameStatePtr]
    mov cx,[bx+ToggleListPtr+FarPtr.Off]
    mov dx,[bx+ToggleListPtr+FarPtr.Seg]
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
    call far AddTeleport ; 6bc 3:295e
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
    jnl .break
    jmp word .loopY
.break:

.checkChipCoords: ; 6ee
    ; If either of chip's coordinates is -1,
    ; put chip on the map at (1,1).
    ; Can't ever happen because chip starts at (0,0).
    mov bx,[GameStatePtr]
    cmp word [bx+ChipX],byte -0x1
    jz .addChipToMap
    cmp word [bx+ChipY],byte -0x1
    jnz .end
.addChipToMap: ; 700
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
endfunc

; 72e
; Returns a random integer between 0 and n-1.
func RandInt
    sub sp,byte +0x2
    call far rand ; 73b 1:dc
    sub dx,dx
    div word [bp+0x6]
    mov ax,dx
endfunc

; 74e
; Big freaking monster loop
; Loop through the monster list and move each monster.
func MonsterLoop
    sub sp,byte +0x20
    push di
    push si

    %arg hDC:word ; +6
    %arg isEvenTurn:word ; +8

    ; Look at all these locals!
    %define tile (bp-3)
    %local local_4:byte ; -4
    %local xdir:word ; -6
    %local ydir:word ; -8
    %local deadflag:word ; -a
    %local i:word ; -c
    %local ynewdir:word ; -e
    %local xnewdir:word ; -10
    %local x:word ; -12
    %local y:word ; -14
    %local len:word ; -16
    %local xdistance:word ; -18
    %local ydistance:word ; -1a
    %local p:dword ; -1e
    %local offset:word ; -20

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
    mov [p+FarPtr.Off],bx
    mov [p+FarPtr.Seg],es

    ; If monster is slipping, skip it.
    cmp word [es:bx+Monster.slipping],byte +0x0
    if nz
        jmp word .next ; slipping
    endif ; 79f

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
    mov [p+FarPtr.Off],bx
    mov [p+FarPtr.Seg],es
    mov ax,[es:bx+Monster.xdir]
    mov [xdir],ax
    mov ax,[es:bx+Monster.ydir]
    mov [ydir],ax
    mov al,[es:bx+Monster.tile]
    sub ah,ah
    sub ax,FirstMonster
    cmp ax,LastMonster-0x40
    if a
        jmp word .next ; not a monster
    endif ; 7e6
    shl ax,1
    xchg ax,bx
    jmp word near [cs:.jmpTable+bx]

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
    call far TurnLeft ; 860 3:b0
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
    call far SetTileDir ; 87d 3:486
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
    push word [hDC]
    call far MoveMonster ; 899 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    if nz
        jmp word .finishMovement
    endif ; 8ab
    cmp byte [tile],Trap
    if e
        jmp word .next ; trapped
    endif ; 8b4
    cmp byte [tile],CloneMachine
    if e
        jmp word .next ; clone
    endif ; 8bd
    mov ax,[xdir]
    mov [xnewdir],ax
    mov ax,[ydir]
    mov [ynewdir],ax
    push ax
    ; Jump to second half of function call,
    ; shared with glider.
    jmp word .glider.moveLeft
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
    call far SetTileDir ; 8ea 3:486
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
    push word [hDC]
    call far MoveMonster ; 906 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    if nz
        jmp word .finishMovement
    endif ; 918

    ; Ran into something.
    ; Try turning right,
    ; unless we're on a trap or clone machine.
    mov si,[y]
    shl si,byte 0x5
    add si,[x]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [tile],al
    cmp al,Trap
    if e
        jmp word .next ; trapped
    endif ; 933
    cmp al,CloneMachine
    if e
        jmp word .next ; clone
    endif ; 93a
    lea ax,[ynewdir]
    push ax
    lea cx,[xnewdir]
    push cx
    push word [ydir]
    push word [xdir]
    call far TurnRight ; 948 3:116
    add sp,byte +0x8
    push word [ynewdir]
    ; The rest of the logic is shared with the paramecium.
    jmp word .paramecium.trySecondMove

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
    call far SetTileDir ; 972 3:486
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
    push word [hDC]
    call far MoveMonster ; 98e 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    if nz
        jmp word .finishMovement ; dead
    endif ; 9a0
    mov si,[y]
    shl si,byte 0x5
    add si,[x]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [tile],al
    cmp al,Trap
    if e
        jmp word .next
    endif ; 9bb
    cmp al,CloneMachine
    if e
        jmp word .next
    endif ; 9c2
    ; rest of logic shared with paramecia
    jmp word .paramecium.moveBackwards
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
    call far SetTileDir ; 9e2 3:486
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
    push word [hDC]
    call far MoveMonster ; 9fe 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    if nz
        jmp word .finishMovement ; not blocked
    endif ; a10
    push word [y]
    push word [x]
    push word [hDC]
    call far UpdateTile ; a19 2:1ca
    add sp,byte +0x6
    mov bx,[GameStatePtr]
    les si,[bx+MonsterListPtr]
    add si,[offset]
    mov di,[es:si+Monster.y]
    shl di,byte 0x5
    add di,[es:si+Monster.x]
    cmp byte [bx+di+Lower],Trap
    if e
        mov bx,[bx+MonsterListPtr]
        add bx,[offset]
        push word [es:bx+Monster.y]
        push word [es:bx+Monster.x]
        call far FindTrap ; a4d 3:22be
        add sp,byte +0x4
        mov si,ax
        or si,si
        if l
            jmp word .next ; trap connection not found
        endif ; a5e
        mov bx,ax
        shl bx,byte 0x2
        add bx,ax
        shl bx,1
        mov si,[GameStatePtr]
        les si,[si+TrapListPtr]
        cmp word [es:bx+si+Connection.flag],byte +0x1
        if e
            jmp word .next ; trap is closed
        endif
    endif
.tank.stop:
    ; Blocked and not on a closed trap
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
    call far SetTileDir ; abc 3:486
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
    push word [hDC]
    call far MoveMonster ; ad8 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    if nz
        jmp word .finishMovement ; not blocked
    endif ; aea
.glider.tryLeftTurn:
    ; Couldn't go - turn left!
    ; (Unless we're on a trap or clone machine of course)
    mov si,[y]
    shl si,byte 0x5
    add si,[x]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [tile],al
    cmp al,Trap
    if e
        jmp word .next
    endif ; b05
    cmp al,CloneMachine
    if e
        jmp word .next
    endif ; b0c
    lea ax,[ynewdir]
    push ax
    lea cx,[xnewdir]
    push cx
    push word [ydir]
    push word [xdir]
    call far TurnLeft ; b1a 3:b0
    add sp,byte +0x8
    push word [ynewdir]
.glider.moveLeft: ; b25
    ; shared with bugs
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call far SetTileDir ; b37 3:486
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
    push word [hDC]
    call far MoveMonster ; b53 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    if nz
        jmp word .finishMovement
    endif
.glider.tryRightTurn: ; b65
    ; If that didn't work, turn right.
    lea ax,[ynewdir]
    push ax
    lea cx,[xnewdir]
    push cx
    push word [ydir]
    push word [xdir]
    call far TurnRight ; b73 3:116
    ; The rest of this logic is shared with parameciums.
    jmp word .paramecium.tryThirdMove
    nop

        ; TEETH
.TeethMovement:
    ; Teeth move only on even turns.
    cmp word [isEvenTurn],byte +0x0
    if z
        ; odd turn, skip
        jmp word .next
    endif ; b85
    ; If on a trap or clone machine,
    ; don't change direction.
    mov si,[y]
    shl si,byte 0x5
    add si,[x]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [tile],al
    cmp al,Trap
    jz .teeth.tryMove
    cmp al,CloneMachine
    jz .teeth.tryMove

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
    if le
        ; Y distance is greater
        cmp word [ydistance],byte +0x0
        if g
            mov word [xnewdir],0
            mov word [ynewdir],+1
            jmp short .teeth.tryMove
        endif ; be6
        mov word [xnewdir],0
        mov word [ynewdir],-1
    else ; bf2
        ; X distance is greater (or equal)
        cmp word [xdistance],byte +0x0
        if g
            mov word [xnewdir],+1
        else ; c00
            mov word [xnewdir],-1
        endif ; c05
        mov word [ynewdir],0
    endif
.teeth.tryMove: ; c0a
    ; Set tile direction and move tile.
    ; Note: xnewdir and ynewdir may be used uninitialized.
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call far SetTileDir ; c1f 3:486
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
    push word [hDC]
    call far MoveMonster ; c3b 7:18da
    add sp,byte +0xc
    ; Check if we succeeded
    mov [deadflag],ax
    or ax,ax
    if nz
        jmp word .finishMovement ; not blocked
    endif ; c4d

.teeth.tryOtherDirection:
    ; Our preferred direction is blocked.
    ; Try the other direction.
    cmp byte [tile],Trap
    if e
        jmp word .next
    endif ; c56
    cmp byte [tile],CloneMachine
    if e
        jmp word .next
    endif ; c5f
    mov ax,[xdistance]
    cwd
    xor ax,dx
    sub ax,dx
    mov cx,ax
    mov ax,[ydistance]
    cwd
    xor ax,dx
    sub ax,dx
    ; if xdistance >= ydistance
    cmp ax,cx
    if ge
         ; X distance is greater (or equal)
        cmp word [xdistance],byte +0x0
        if g
            mov word [xnewdir],0x1
        .teeth.set_ynewdir_to_0_and_move: ; c80
            mov word [ynewdir],0x0
            jmp short .teeth.tryOtherMove
            nop
        endif ; c88
        cmp word [xdistance],byte +0x0
        jnl .teeth.failedMove
        mov word [xnewdir],-1
        jmp short .teeth.set_ynewdir_to_0_and_move
        nop
    endif ; c96
    ; Y distance is greater
    cmp word [ydistance],byte +0x0
    if g
        mov word [xnewdir],0
        mov word [ynewdir],1
    else ; ca8
        cmp word [ydistance],byte +0x0
        jnl .teeth.failedMove
        mov word [xnewdir],0
        mov word [ynewdir],-1
    endif
.teeth.tryOtherMove: ; cb8
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call far SetTileDir ; ccd 3:486
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
    push word [hDC]
    call far MoveMonster ; ce9 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    if nz
        jmp word .finishMovement ; not blocked
    endif

.teeth.failedMove: ; cfb
    ; Both directions were blocked.
    ; At least /face/ the right way.
    mov ax,[xdistance]
    cwd
    xor ax,dx
    sub ax,dx
    mov cx,ax
    mov ax,[ydistance]
    cwd
    xor ax,dx
    sub ax,dx
    ; compare abs(ydistance) and abs(xdistance)
    cmp ax,cx
    if ge
        ; Y distance is greater or equal
        cmp word [ydistance],byte +0x0
        if g
            mov word [xnewdir],0
            mov word [ynewdir],1
            jmp short .teeth.faceDirection
            nop
        endif ; d24
        mov word [xnewdir],0
        mov word [ynewdir],-1
    else ; d30
        ; X distance is greater
        cmp word [xdistance],byte +0x0
        if g
            mov word [xnewdir],1
        else ; d3e
            mov word [xnewdir],-1
        endif ; d43
        mov word [ynewdir],0
    endif
.teeth.faceDirection: ; d48
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si+Monster.tile]
    push ax
    call far SetTileDir ; d5d 3:486
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
    push word [hDC]
    call far UpdateTile ; d93 2:1ca
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
    call far SetTileDir ; dba 3:486
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
    push word [hDC]
    call far MoveMonster ; dd6 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    if nz
        jmp word .finishMovement ; not blocked
    endif ; de8
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
    if e
        jmp word .next
    endif ; e03
    cmp al,CloneMachine
    if e
        jmp word .next
    endif ; e0a
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
    ; each direction tried sets a bit in the si register
    ; so that si equals 7 when all direction bits are set
    cmp si,byte +0x7
    if e
        jmp word .next
    endif ; e20
    ; Random choice of 0, 1, or 2.
    push byte +0x3
    call far RandInt ; e22 3:72e
    add sp,byte +0x2
    or ax,ax
    jz .walker.turnLeft
    dec ax
    jz .walker.turnRight
    dec ax
    jz .walker.turnAround
    jmp short .walker.tryMove

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
    call far TurnLeft ; e4b 3:b0
    jmp short .walker.cleanStack
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
    call far TurnRight ; e67 3:116
    jmp short .walker.cleanStack
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
    call far TurnAround ; e83 3:17c
.walker.cleanStack: ; e88
    add sp,byte +0x8
.walker.tryMove: ; e8b
    ; Try moving.
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,[offset]
    mov al,[es:bx+Monster.tile]
    push ax
    call far SetTileDir ; ea0 3:486
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
    push word [hDC]
    call far MoveMonster ; ebc 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    if z
        ; if we were blocked, try another direction
        jmp word .walker.loop
    endif ; ece
    ; found a successful (or fatal) direction
    jmp word .finishMovement
    nop

        ;;; BLOB ;;;
.BlobMovement:
    ; Blobs only move on even turns
    cmp word [isEvenTurn],byte +0x0
    if z
        ; odd turn, skip
        jmp word .next
    endif
.blob.loop: ; edb
    ; Random choice of -1,0,1
    push byte +0x3
    call far RandInt ; edd 3:72e
    add sp,byte +0x2
    dec ax
    mov [xnewdir],ax
    ; Random choice of -1,0,1
    push byte +0x3
    call far RandInt ; eeb 3:72e
    add sp,byte +0x2
    dec ax
    mov [ynewdir],ax
    ; if exactly one direction is nonzero, try moving
    ; otherwise loop back to the top to pick another direction
    cmp word [xnewdir],byte +0x0
    if z
        or ax,ax
        jnz .blob.tryMove
    endif ; f01
    or ax,ax
    jnz .blob.loop
    cmp [xnewdir],ax
    jz .blob.loop
.blob.tryMove: ; f0a
    push ax
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si]
    push ax
    call far SetTileDir ; f1d 3:486
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
    push word [hDC]
    call far MoveMonster ; f39 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    if nz
        jmp word .finishMovement ; not blocked
    endif
.blob.moveBlocked: ; f4b
    xor si,si
    mov di,[xnewdir]
    mov ax,[ynewdir]
    mov [bp-0x4],ax
    mov [xdir],di
.blob.moveBlocked.loop: ; f59
    ; if we've tried every direction, give up
    cmp si,byte +0x7
    if e
        jmp word .next
    endif ; f61
    ; random choice of left,right,backwards
    push byte +0x3
    call far RandInt ; f63 3:72e
    add sp,byte +0x2
    or ax,ax
    jz .blob.moveBlocked.turnLeft
    dec ax
    jz .blob.moveBlocked.turnRight
    dec ax
    jz .blob.moveBlocked.turnAround
    jmp short .blob.moveBlocked.tryMove
    nop
.blob.moveBlocked.turnLeft: ; f78
    test si,0x1
    jnz .blob.moveBlocked.loop
    or si,byte +0x1
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    push word [bp-0x4]
    push di
    call far TurnLeft ; f8d 3:b0
    jmp short .blob.moveBlocked.tryMoveJump
.blob.moveBlocked.turnRight: ; f94
    test si,0x2
    jnz .blob.moveBlocked.loop
    or si,byte +0x2
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    push word [bp-0x4]
    push di
    call far TurnRight ; fa9 3:116
    jmp short .blob.moveBlocked.tryMoveJump
.blob.moveBlocked.turnAround: ; fb0
    test si,0x4
    jnz .blob.moveBlocked.loop
    or si,byte +0x4
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    push word [bp-0x4]
    push di
    call far TurnAround ; fc5 3:17c
.blob.moveBlocked.tryMoveJump: ; fca
    add sp,byte +0x8
.blob.moveBlocked.tryMove: ; fcd
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,[offset]
    mov al,[es:bx]
    push ax
    call far SetTileDir ; fe2 3:486
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
    push word [hDC]
    call far MoveMonster ; ffe 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    if z
        ; if we were blocked, try another direction
        jmp word .blob.moveBlocked.loop
    endif ; 1010
    ; found a successful (or fatal) direction
    jmp word .finishMovement
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
    jz .paramecium.tryMove
    cmp al,CloneMachine
    jz .paramecium.tryMove
    lea ax,[ynewdir]
    push ax
    lea ax,[xnewdir]
    push ax
    push word [ydir]
    push word [xdir]
    call far TurnRight ; 103e 3:116
    add sp,byte +0x8
.paramecium.tryMove: ; 1046
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si]
    push ax
    call far SetTileDir ; 105b 3:486
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
    push word [hDC]
    call far MoveMonster ; 1077 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    if nz
        jmp word .finishMovement ; not blocked
    endif
.paramecium.moveBlocked: ; 1089
    cmp byte [tile],Trap
    if e
        jmp word .next
    endif ; 1092
    cmp byte [tile],CloneMachine
    if e
        jmp word .next
    endif ; 109b
    mov ax,[xdir] ; causes the paramecium to turn forwards
    mov [xnewdir],ax
    mov ax,[ydir]
    mov [ynewdir],ax
    push ax
.paramecium.trySecondMove: ; 10a8
    ; shared with fireball
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si]
    push ax
    call far SetTileDir ; 10ba 3:486
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
    push word [hDC]
    call far MoveMonster ; 10d6 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    if nz
        jmp word .finishMovement ; not blocked
    endif
.paramecium.turnLeft: ; 10e8
    lea ax,[ynewdir]
    push ax
    lea cx,[xnewdir]
    push cx
    push word [ydir]
    push word [xdir]
    call far TurnLeft ; 10f6 3:b0
.paramecium.tryThirdMove: ; 10fb
    ; shared with gliders
    add sp,byte +0x8
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si]
    push ax
    call far SetTileDir ; 1113 3:486
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
    push word [hDC]
    call far MoveMonster ; 112f 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jnz .finishMovement ; not blocked
.paramecium.moveBackwards: ; 113e
    ; shared with balls
    lea ax,[ynewdir]
    push ax
    lea cx,[xnewdir]
    push cx
    push word [ydir]
    push word [xdir]
    call far TurnAround ; 114c 3:17c
    add sp,byte +0x8
    push word [ynewdir]
    push word [xnewdir]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov si,[offset]
    mov al,[es:bx+si]
    push ax
    call far SetTileDir ; 1169 3:486
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
    push word [hDC]
    call far MoveMonster ; 1185 7:18da
    add sp,byte +0xc
    mov [deadflag],ax
    or ax,ax
    jz .next

.finishMovement: ; 1194
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
    call far DeleteMonster ; 11f3 3:3b4
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
    ; If chip died, then play "bummer" sfx, show death message, and restart the level
    mov bx,[GameStatePtr]
    cmp word [bx+Autopsy],byte +0x0
    if nz
        push byte +0x1
        call far FUN_2_0cbe ; 121c 2:cbe
        add sp,byte +0x2
        push byte +0x1
        push byte ChipDeathSound
        call far PlaySoundEffect ; 1228 8:56c
        add sp,byte +0x4
        call far ShowDeathMessage ; 1230 2:b9a
        push byte +0x1
        mov bx,[GameStatePtr]
        push word [bx+LevelNumber]
        call far FUN_4_0356 ; 123f 4:356
        add sp,byte +0x4
    endif ; 1247
    pop si
    pop di
endfunc

; 1250

func NewSlipper
    sub sp,byte +0x2
    mov bx,[GameStatePtr]
    ; Grow slip list if necessary
    mov ax,[bx+SlipListCap]
    cmp [bx+SlipListLen],ax
    jl .addSlipperToList
    push byte Slipper_size
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
    call far GrowArray ; 1281 3:1a4
    add sp,byte +0xa
    or ax,ax
    if z
        cwd
        jmp short .end
    endif
.addSlipperToList: ; 1290
    mov bx,[GameStatePtr]
    inc word [bx+SlipListLen]
    mov bx,[GameStatePtr]
    mov ax,[bx+SlipListLen]
    mov cx,ax
    shl ax,byte 0x2
    add ax,cx
    shl ax,1
    add ax,cx
    add ax,[bx+SlipListPtr+FarPtr.Off]
    mov dx,[bx+SlipListPtr+FarPtr.Seg]
    sub ax,0xb
.end: ; 12b6
endfunc

; 12be

func DeleteSlipperAt
    sub sp,byte +0x6
    push di
    push si

    %arg unused:word, x:word, y:word
    mov bx,[GameStatePtr]
    cmp word [bx+SlipListLen],byte +0x0
    if z
    .returnZero: ; 12d8
        xor ax,ax
        jmp word .end
        nop
    endif ; 12de
    push word [y]
    push word [x]
    call far FindSlipper ; 12e4 3:58
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
    cmp word [es:bx+si+Slipper.isblock],byte +0x0
    if ne
        push word [y]
        push word [x]
        call far FindMonster ; 1313 3:0
        add sp,byte +0x4
        mov bx,ax
        shl bx,byte 0x2
        add bx,ax
        shl bx,1
        add bx,ax
        mov si,[GameStatePtr]
        les si,[si+MonsterListPtr]
        mov word [es:bx+si+Monster.slipping],0x0
    endif ; 1334
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
    add word [bp-0x4],byte Slipper_size
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
endfunc

; 1396

func FindSlipperAt
    sub sp,byte +0x4
    %arg unused:word, x:word, y:word
    %local slipperIdx:word
    push word [y]
    push word [x]
    call far FindSlipper ; 13a9 3:58
    add sp,byte +0x4
    mov [slipperIdx],ax
    inc ax
    jz .returnZero
    mov ax,[slipperIdx]
    mov cx,ax
    shl ax,byte 0x2
    add ax,cx
    shl ax,1
    add ax,cx
    mov bx,[GameStatePtr]
    add ax,[bx+SlipListPtr+FarPtr.Off]
    mov dx,[bx+SlipListPtr+FarPtr.Seg]
    jmp short .end
    nop
.returnZero: ; 13d4
    xor ax,ax
    cwd
.end: ; 13d7
endfunc

; 13de

func SlipLoop
    %arg hWnd:word
    %local monsterIndex:word
    %local monsterStatus:word
    %local previousSlipListLen:word ; -8
    %local i:word ; -a
    %local x:word ; -c
    %local y:word ; -e
    %local xdir:word ; -10
    %local ydir:word ; -12
    %local local_14:byte
    %local local_16:word

    sub sp,byte +0x16
    push di
    push si
    mov word [i],0x0
    mov bx,[GameStatePtr]
    cmp word [bx+SlipListLen],byte +0x0
    if le
        jmp word .break
    endif ; 1400
    xor si,si
    mov di,[hWnd]
.loop: ; 1405
    mov ax,[bx+SlipListLen]
    mov [previousSlipListLen],ax
    les bx,[bx+SlipListPtr]
    add bx,si
    cmp word [es:bx+Slipper.isblock],byte +0x0
    jnz .isAMonster
    jmp word .isABlock
.isAMonster: ; 141c
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    add bx,si
    push word [es:bx+Slipper.y]
    push word [es:bx+Slipper.x]
    call far FindMonster ; 142e 3:0
    add sp,byte +0x4
    mov [monsterIndex],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Slipper.xdir]
    mov [xdir],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Slipper.ydir]
    mov [ydir],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Slipper.x]
    mov [x],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Slipper.y]
    mov [y],ax
    push word [ydir]
    push word [xdir]
    mov bx,ax ; y
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    mov al,[bx+Upper]
    push ax ; tile
    call far SetTileDir ; 148a 3:486
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
    call far MoveMonster ; 14a4 7:18da
    add sp,byte +0xc
    mov [monsterStatus],ax
    or ax,ax
    if nz
        jmp word .success ; not blocked
    endif
.monster.blocked: ; 14b6
    ; if the move was blocked,
    ; check if we're on ice
    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    mov al,[bx+Lower]
    mov [local_14],al
    cmp al,Ice
    if ne
        cmp al,IceWallNW
        if b
            jmp word .label8
        endif ; 14d5
        cmp al,IceWallSW
        if a
            jmp word .label8
        endif
    endif
.monster.onIce: ; 14dc
    ; reverse the move direction and try again
    neg word [xdir]
    neg word [ydir]
    push word DummyVarForSlideMovement
    push byte +0x2
    lea ax,[ydir]
    push ax
    lea cx,[xdir]
    push cx
    push word [y]
    push word [x]
    push word [y]
    push word [x]
    call far SlideMovement ; 14fb 7:636
    add sp,byte +0x10
    push word [ydir]
    push word [xdir]
    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    mov al,[bx+Upper]
    push ax
    call far SetTileDir ; 1519 3:486
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
    call far MoveMonster ; 1533 7:18da
    add sp,byte +0xc
    mov [monsterStatus],ax
    or ax,ax
    if z
        jmp word .label9
    endif
.success: ; 1545
    cmp ax,0x1
    if ne
        jmp word .label11
    endif ; 154d
    mov ax,[x]
    mov cx,[monsterIndex]
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
    mov [local_16],cx
    call far SetTileDir ; 15b8 3:486
    add sp,byte +0x6
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,[local_16]
    mov [es:bx+Monster.tile],al
    jmp word .next
    nop
.label11: ; 15d2
    push word [monsterIndex]
    call far DeleteMonster ; 15d5 3:3b4
    add sp,byte +0x2
    jmp word .next
.label9: ; 15e0
    neg word [xdir]
    neg word [ydir]
.label8: ; 15e6
    ; Call SlideMovement
    push word DummyVarForSlideMovement
    push byte +0x2
    jmp word .label13

.isABlock: ; 15ee
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    add bx,si
    mov ax,[es:bx+Slipper.xdir]
    mov [xdir],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Slipper.ydir]
    mov [ydir],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Slipper.x]
    mov [x],ax
    mov bx,[GameStatePtr]
    les bx,[bx+SlipListPtr]
    mov ax,[es:bx+si+Slipper.y]
    mov [y],ax
    push byte +0x0
    push word 0xff
    push word [ydir]
    push word [xdir]
    push ax
    push word [x]
    push di
    call far MoveBlock ; 163c 7:dae
    add sp,byte +0xe
    or ax,ax
    if nz
        jmp word .next ; not blockd
    endif
.block.blocked: ; 164b
    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    mov al,[bx+Lower]
    mov [local_14],al
    cmp al,Ice
    if ne
        cmp al,IceWallNW
        jb .label16
        cmp al,IceWallSW
        ja .label16
    endif ; 166b
.block.onIce:
    neg word [xdir]
    neg word [ydir]
    push word DummyVarForSlideMovement
    push byte +0x1
    lea ax,[ydir]
    push ax
    lea cx,[xdir]
    push cx
    push word [y]
    push word [x]
    push word [y]
    push word [x]
    call far SlideMovement ; 168a 7:636 slide movement
    add sp,byte +0x10
    push byte +0x0
    push word 0xff
    push word [ydir]
    push word [xdir]
    push word [y]
    push word [x]
    push di
    call far MoveBlock ; 16a4 7:dae
    add sp,byte +0xe
    or ax,ax
    jnz .next
    neg word [xdir]
    neg word [ydir]
.label16: ; 16b6
    push word DummyVarForSlideMovement
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
    call far SlideMovement ; 16cf 7:636
    add sp,byte +0x10

.next: ; 16d7
    mov ax,[previousSlipListLen]
    mov bx,[GameStatePtr]
    cmp [bx+SlipListLen],ax
    if e
        add si,byte Slipper_size
        inc word [i]
    endif ; 16ea
    mov ax,[i]
    cmp [bx+SlipListLen],ax
    jng .break
    jmp word .loop

.break: ; 16f6
    cmp word [bx+Autopsy],byte +0x0
    if nz
        push byte +0x1
        call far FUN_2_0cbe ; 16ff 2:cbe
        add sp,byte +0x2
        push byte +0x1
        push byte ChipDeathSound
        call far PlaySoundEffect ; 170b 8:56c
        add sp,byte +0x4
        call far ShowDeathMessage ; 1713 2:b9a
        push byte +0x1
        mov bx,[GameStatePtr]
        push word [bx+LevelNumber]
        call far FUN_4_0356 ; 1722 4:356
        add sp,byte +0x4
    endif ; 172a
    pop si
    pop di
endfunc

; 1734

func ResetInventory
    sub sp,byte +0x2
    ; if arg is nonzero, only reset boots, not keys
    %arg bootsOnly:word
    cmp word [bootsOnly],byte +0x0
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
    mov word [InventoryDirty],0x1
endfunc

; 1770

func PickUpKeyOrBoot
    %arg tile:byte
    sub sp,byte +0x2
    mov al,[tile]
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
    mov [InventoryDirty],ax
    push ax
    push cx
    call far PlaySoundEffect ; 17f8 8:56c
endfunc

; 1804

; Check whether chip has the key necessary to open a door,
; and possibly decrement the inventory count.
func CanOpenDoor
    sub sp,byte +0x2
    %arg tile:byte, consumeKey:word
    mov al,[tile]
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
    cmp word [consumeKey],byte +0x0
    jz .yes ; ↓
    dec word [BlueKeyCount]
.yes: ; 1837
    mov ax,0x1
    mov [InventoryDirty],ax
    jmp short .end ; ↓
    nop

.redDoor: ; 1840
    cmp word [RedKeyCount],byte +0x0
    jz .no ; ↓
    cmp word [consumeKey],byte +0x0
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
    cmp word [consumeKey],byte +0x0
    jz .yes ; ↑
    dec word [YellowKeyCount]
    jmp short .yes ; ↑
    nop

.no: ; 1872
    xor ax,ax
.end: ; 1874
endfunc

; 187c

; force floors, ice, fire, water
func HaveBootsForTile
    %arg tile:byte
    sub sp,byte +0x2
    mov al,[tile]
    sub ah,ah
    sub ax,Water
    cmp ax,ForceRandom-Water
    if a
        jmp word .none ; ↓
    endif ; 1899
    shl ax,1
    xchg ax,bx
    jmp word [cs:.jumpTable+bx]
    nop
.jumpTable:
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
    ; return True and mark the inventory as dirty
    mov ax,0x1
    mov [InventoryDirty],ax
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
    if e
        jmp word .WallSE ; ↓
    endif ; 194e
    if a
        jmp word .returnTrue ; ↓
    endif ; 1953
    cmp al,IceWallNW
    jz .WallNW ; ↓
    jg .label2 ; ↓
    sub al,PanelN
    jz .WallNorth ; ↓
    dec al ; PanelW
    jz .WallWest ; ↓
    dec al ; PanelS
    jz .WallSouth ; ↓
    dec al ; PanelE
    jz .WallEast ; ↓
    jmp word .returnTrue ; ↓
    nop
    nop
.label2: ; 196e
    sub al,IceWallNE
    jz .WallNE ; ↓
    dec al ; IceWallSE
    if e
        jmp word .WallSE ; ↓
    endif ; 1979
    dec al ; IceWallSW
    if e
        jmp word .WallSW ; ↓
    endif ; 1980
    jmp word .returnTrue ; ↓
    nop

.WallNorth: ; 1984
    cmp word [flag],byte +0x0
    jz .check_south ; ↓
.check_north: ; 198a
    cmp word [xdir],byte +0x0
    if nz
        jmp word .returnTrue ; ↓
    endif ; 1993
    cmp word [ydir],byte +0x1
.return_false_if_z_else_true: ; 1997
    jz .returnFalse ; ↓
    jmp word .returnTrue ; ↓
.returnFalse: ; 199c
    xor ax,ax
    jmp word .return ; ↓
    nop

.WallWest: ; 19a2
    cmp word [flag],byte +0x0
    jz .check_east ; ↓
.check_west: ; 19a8
    cmp word [xdir],byte +0x1
    jmp short .label28 ; ↓
    nop
    nop

.WallSouth: ; 19b0
    cmp word [flag],byte +0x0
    jz .check_north ; ↑
.check_south: ; 19b6
    cmp word [xdir],byte +0x0
    if nz
        jmp word .returnTrue ; ↓
    endif ; 19bf
    cmp word [ydir],byte -0x1
    jmp short .return_false_if_z_else_true ; ↑
    nop

.WallEast: ; 19c6
    cmp word [flag],byte +0x0
    jz .check_west ; ↑
.check_east: ; 19cc
    cmp word [xdir],byte -0x1
    jmp short .label28 ; ↓

.WallNW: ; 19d2
    cmp word [flag],byte +0x0
    jz .check_southeast ; ↓
.check_northwest: ; 19d8
    mov bx,[xdir]
    or bx,bx
    jnz .label27 ; ↓
    cmp word [ydir],byte +0x1
    jmp short .label26 ; ↓
    nop

.WallNE: ; 19e6
    cmp word [flag],byte +0x0
    jz .check_southwest ; ↓
    mov bx,[xdir]
    or bx,bx
    jnz .label23 ; ↓
    cmp word [ydir],byte +0x1
    jmp short .label22 ; ↓
    nop

.WallSE: ; 19fa
    cmp word [flag],byte +0x0
    jz .check_northwest ; ↑
.check_southeast: ; 1a00
    mov bx,[xdir]
    or bx,bx
    jnz .label23 ; ↓
    cmp word [ydir],byte -0x1
.label22: ; 1a0b
    jz .returnFalse ; ↑
.label23: ; 1a0d
    inc bx
    jmp short .label28 ; ↓

.WallSW: ; 1a10
    cmp word [flag],byte +0x0
    jz .check_northeast ; ↓
.check_southwest: ; 1a16
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
    jmp word .return_false_if_z_else_true ; ↑
.check_northeast: ; 1a30
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
endfunc

; 1a56

func ChipCanEnterTile
    sub sp,byte +0xe
    push di
    push si

    %arg x:word ; +6
    %arg y:word ; +8
    %arg xdir:word ; +a
    %arg ydir:word ; +c
    %arg ptr:word ; +e
    %arg flag1:word ; +10
    %arg upperOrLower:word ; +12 1=upper 0=lower

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
    if e
        jmp word .nope ; ↓
    endif ; 1a82

    cmp word [upperOrLower],byte +0x0
    if nz
        mov al,[bx+Upper]
    else ; 1a8c
        mov al,[bx+Lower]
    endif ; 1a90
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
    if e
    .return1: ; 1abd
        mov ax,0x1
        jmp word .end ; ↓
        nop
    endif ; 1ac4
    ; if table says it's more complicated (2), keep going
    ; otherwise return 0
    cmp byte [tileTableRow+0],0x2
    if ne
        jmp word .nope ; ↓
    endif ; 1acd
    ; if tile is transparent, check the lower tile instead
    cmp byte [tile],FirstTransparent
    jb .notTransparent ; ↓
    cmp byte [tile],LastTransparent
    ja .notTransparent ; ↓
    jmp word .checkLowerTile ; ↓
.notTransparent: ; 1adc
    ; if the tile is a block, check the lower tile insteadk
    cmp byte [tile],Block
    if e
        jmp word .checkLowerTile ; ↓
    endif ; 1ae5
.doJumpTable:
    mov di,[x]
    mov si,[y]
    mov al,[tile]
    sub ah,ah
    sub ax,Water
    cmp ax,ForceRandom - Water
    if a
        jmp word .nope ; ↓
    endif ; 1afb
    shl ax,1
    xchg ax,bx
    jmp word [cs:.jumpTable+bx]
    nop
.jumpTable:
    dw .water           ; Water
    dw .fire            ; Fire
    dw .nope            ; InvisibleWall
    dw .panelWalls      ; PanelN
    dw .panelWalls      ; PanelW
    dw .panelWalls      ; PanelS
    dw .panelWalls      ; PanelE
    dw .nope            ; Block
    dw .nope            ; Dirt
    dw .ice             ; Ice
    dw .forceFloor      ; ForceS
    dw .nope            ; BlockN
    dw .nope            ; BlockW
    dw .nope            ; BlockS
    dw .nope            ; BlockE
    dw .forceFloor      ; ForceN
    dw .forceFloor      ; ForceE
    dw .forceFloor      ; ForceW
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
    dw .forceFloor      ; ForceRandom

.water: ; 1b64
.fire:
.ice:
.forceFloor:
    ; force floors, ice, water, fire
    ; if we have boots for this tile,
    ; override the returned action to be 4
    ; instead of whatever the table says
    mov al,[tile]
    push ax
    call far HaveBootsForTile ; 1b68 3:187c
    add sp,byte +0x2
    or ax,ax
    if z
        jmp word .return1 ; ↑
    endif ; 1b77
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
    call far CheckPanelWalls ; 1b8e 3:1934
    add sp,byte +0x8
.label12: ; 1b96
    or ax,ax
    if z
        jmp word .nope ; ↓
    endif ; 1b9d
    jmp word .return1 ; ↑


.doors: ; 1ba0
    mov si,[flag1]
    push si
    mov al,[tile]
    push ax
    call far CanOpenDoor ; 1ba8 3:1804
    add sp,byte +0x4
    or ax,ax
    if z
        jmp word .nope ; ↓
    endif ; 1bb7
    or si,si
    if z
        jmp word .return1 ; ↑
    endif ; 1bbe
    push byte +0x1
    push byte OpenDoorSound
.label17: ; 1bc2
    call far PlaySoundEffect ; 1bc2 8:56c
    add sp,byte +0x4
    jmp word .return1 ; ↑
    nop


.iceCorners: ; 1bce
    push byte +0x1
    push word [ydir]
    push word [xdir]
    mov al,[tile]
    push ax
    call far CheckPanelWalls ; 1bda 3:1934
    add sp,byte +0x8
    or ax,ax
    if z
        jmp word .nope ; ↓
    endif ; 1be9
    jmp word .ice ; ↑

.fakeFloor: ; 1bec
    cmp word [flag1],byte +0x0
    if z
        jmp word .return1 ; ↑
    endif ; 1bf5
    mov bx,[tileIndex]
    mov si,[GameStatePtr]
    mov byte [bx+si+Upper],Floor
    jmp word .return1 ; ↑

.hiddenWall: ; 1c02
    cmp word [flag1],byte +0x0
    if z
        jmp word .nope ; ↓
    endif ; 1c0b
    mov bx,[tileIndex]
    mov ax,si
    mov si,[GameStatePtr]
    mov byte [bx+si+Upper],Wall
    push ax
    push di
    call far InvalidateTile ; 1c19 2:2b2
    add sp,byte +0x4
    jmp short .nope ; ↓
    nop

.thief: ; 1c24
    cmp word [flag1],byte +0x0
    if z
        jmp word .return1 ; ↑
    endif ; 1c2d
    push byte +0x1
    push byte ThiefSound
    call far PlaySoundEffect ; 1c31 8:56c
    add sp,byte +0x4
    push byte +0x1
    call far ResetInventory ; 1c3b 3:1734
    add sp,byte +0x2
    jmp word .return1 ; ↑

.socket: ; 1c46
    cmp word [ChipsRemainingCount],byte +0x0
    jnz .nope ; ↓
    cmp word [flag1],byte +0x0
    if z
        jmp word .return1 ; ↑
    endif ; 1c56
    push byte +0x1
    push byte +0x4
    jmp word .label17 ; ↑
    nop

.popupWall: ; 1c5e
    cmp word [flag1],byte +0x0
    if z
        jmp word .return1 ; ↑
    endif ; 1c67
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
    call far ChipCanEnterTile ; 1c88 3:1a56
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
endfunc

; 1ca4

func BlockCanEnterTile
    sub sp,byte +0xc
    push di
    push si

    %arg blockTile:byte, x:word, y:word, xdir:word, ydir:word, outPtr:byte
    %define tile (bp-0x3)
    %define tileTableRow (bp-0xa)
    %define tilePointer (bp-0xc)

    mov bx,[y]
    shl bx,byte 0x5
    add bx,[x]
    add bx,[GameStatePtr]
    mov [tilePointer],bx
    ; Can't enter clone machines
    cmp byte [bx+Lower],CloneMachine
    jz .nope ; ↓
    ; Get destination tile
    mov al,[bx+Upper]
    mov [tile],al;
    ; Compute tile table index
    ; bx = tile
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
    if z
    .yep: ; 1cf9
        mov ax,0x1
        jmp short .end ; ↓
        nop
        nop
    endif ; 1d00
    cmp byte [tileTableRow+2],0x2
    jnz .nope ; ↓
    mov al,[tile]
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
    mov al,[tile]
    push ax
    call far CheckPanelWalls ; 1d2e 3:1934
    add sp,byte +0x8
    or ax,ax
    jnz .yep ; ↑
.nope: ; 1d3a
    xor ax,ax
    mov bx,[outPtr]
    mov [bx],ax
.end: ; 1d41
    pop si
    pop di
endfunc

; 1d4a

func MonsterCanEnterTile
    sub sp,byte +0xc
    push di
    push si

    %arg monster:byte, x:word, y:word, xdir:word, ydir:word, outPtr:byte
    %define tile (bp-0x3)
    %define tileTableRow (bp-0xa)
    %define tilePointer (bp-0xc)

    mov di,[y]
    mov si,[x]
    mov bx,di
    shl bx,byte 0x5
    add bx,[GameStatePtr]
    add bx,si
    mov [tilePointer],bx

    ; if monster is on a clone machine, return
    cmp byte [bx+Lower],CloneMachine
    if e
        jmp word .blocked ; ↓
    endif ; 1d77
    ; Is the top tile chip or swimming chip? use the bottom tile
    mov al,[bx+Upper]
    mov [tile],al
    cmp al,ChipN
    jb .checkSwimmingChip ; ↓
    cmp al,ChipE
    jna .getBottomTile ; ↓
.checkSwimmingChip: ; 1d84
    cmp byte [tile],SwimN
    jb .checkTileTable ; ↓
    cmp byte [tile],SwimE
    ja .checkTileTable ; ↓
.getBottomTile: ; 1d90
    ; top tile is chip or swimming chip
    mov al,[bx+Lower]
    mov [tile],al

.checkTileTable: ; 1d97
    mov bl,[tile]
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
    if e
    .returnTrue: ; 1dc2
        mov ax,0x1
        jmp word .return
    endif ; 1dc8
    ; if table entry == 2 do some other stuff
    cmp byte [tileTableRow + 4],0x2
    if ne
        ; otherwise return zero
        jmp word .blocked ; ↓
    endif ; 1dd1

    ; other stuff ==>
    mov si,[outPtr]
    mov al,[tile]
    sub ah,ah
    cmp ax,PanelSE
    jz .thinWalls ; ↓
    ja .blocked ; ↓
    cmp al,Fire
    jz .fire ; ↓
    jg .checkPanelWallsOrIceWalls ; ↓
    sub al,Water
    jz .water ; ↓
    jmp short .blocked ; ↓
    nop
    nop
.checkPanelWallsOrIceWalls: ; 1dee
    ; check if the tile is a panel wall or ice wall
    sub al,PanelN
    jl .blocked ; ↓
    sub al,PanelE - PanelN
    jng .thinWalls ; ↓
    sub al,IceWallNW - PanelE
    jl .blocked ; ↓
    sub al,IceWallSW - IceWallNW
    jng .thinWalls ; ↓
    jmp short .blocked ; ↓

.water: ; 1e00
    ; gliders survive water
    ; everything else drowns
    mov al,[monster]
    sub ah,ah
    sub ax,GliderN
    jl .returnTrue ; ↑
    jo .returnTrue ; ↑
    sub ax,3
    jg .returnTrue ; ↑
.set_action_to_1_and_return: ; 1e11
    mov word [si],0x1 ; set action to 1
    jmp short .returnTrue ; ↑
    nop

.fire: ; 1e18
    ; fire blocks bugs and walkers
    ; fireballs survive it
    ; everyting else burns
    mov al,[monster]
    sub ah,ah
    sub ax,BugN
    jl .returnTrue ; ↑
    jo .returnTrue ; ↑
    sub ax,3
    jle .blocked ; ↓ bugs are blocked
    dec ax ; Fireball
    jl .returnTrue ; ↑
    sub ax,3
    jle .set_action_to_1_and_return ; ↑ fireballs can enter fire
    sub ax,WalkerN - FireballE
    jl .returnTrue ; ↑
    sub ax,3
    jng .blocked ; ↓ walkers are blocked
    jmp short .returnTrue ; ↑
    nop

.thinWalls: ; 1e3e
    push byte +0x1
    push word [ydir]
    push word [xdir]
    mov al,[tile]
    push ax
    call far CheckPanelWalls ; 1e4a 3:1934
    add sp,byte +0x8
    or ax,ax
    jz .blocked ; ↓
    jmp word .returnTrue ; ↑
.blocked: ; 1e59
    ; set action to 0 and return false
    xor ax,ax
    mov bx,[outPtr]
    mov [bx],ax
.return: ; 1e60
    pop si
    pop di
endfunc

; 1e6a

func PressTankButton
    sub sp,byte +0xc
    push di
    push si

    %arg hDC:word ; +6
    %arg arg_8:word ; +8
    %define tile (bp-0x3)
    %local local_4:byte
    %local x:word ; -6
    %local index:word ; -8
    %local ydir:word ; -a
    %local xdir:word ; -c

    push word [arg_8]
    push byte SwitchSound
    call far PlaySoundEffect ; 1e7e 8:56c
    add sp,byte +0x4
    mov word [index],0x0
    mov bx,[GameStatePtr]
    cmp word [bx+MonsterListLen],byte +0x0
    if le
        jmp word .end ; ↓
    endif ; 1e99
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
    call far GetMonsterDir ; 1ed9 3:4d8
    add sp,byte +0x6
    ; turn tile left and store in map
    lea ax,[ydir]
    push ax
    lea cx,[xdir]
    push cx
    push word [ydir]
    push word [xdir]
    call far TurnLeft ; 1eef 3:b0
    add sp,byte +0x8
    push word [ydir]
    push word [xdir]
    mov al,[tile]
    push ax
    call far SetTileDir ; 1f01 3:486
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
    push word [hDC]
    mov di,bx
    call far UpdateTile ; 1f22 2:1ca
    add sp,byte +0x6
    ; turn direction left again (180 degrees total)
    ; and store new direction in monster list
    lea ax,[ydir]
    push ax
    lea cx,[xdir]
    push cx
    push word [ydir]
    push word [xdir]
    call far TurnLeft ; 1f38 3:b0
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
    call far SetTileDir ; 1f68 3:486
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
endfunc

; 1fac

func PressToggleButton
    sub sp,byte +0xa
    push di
    push si
    %arg hDC:word
    %local x:word ; -4
    %local y:word ; -6
    %define tile (bp-0x7)
    xor di,di
    mov bx,[GameStatePtr]
    cmp [bx+ToggleListLen],di
    if le
        jmp word .end ; ↓
    endif ; 1fca
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
    mov [tile],al
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
    cmp byte [tile],ToggleFloor
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
    mov [tile],al
    cmp al,ToggleWall
    if e
        ; if it's a wall, change to a floor
        mov byte [bx],ToggleFloor
    else ; 2038
        ; if it's a floor, change to a wall
        cmp byte [tile],ToggleFloor
        if e
            mov byte [bx],ToggleWall
        endif
    endif ; 2041
    ; update display?
    push word [y]
    push word [x]
    push word [hDC]
    call far UpdateTile ; 204a 2:1ca
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
    if ng
        jmp word .returnZero ; ↓
    endif ; 208a
    mov si,bx
    mov ax,[si+TrapListPtr+FarPtr.Off]
    mov dx,[si+TrapListPtr+FarPtr.Seg]
    add ax,0x4
    mov bx,ax
    mov es,dx
    mov di,[x]
.loop1: ; 209e
    cmp [es:bx+Connection.toX-4],di
    if e
        mov ax,[y]
        cmp [es:bx+Connection.toY-4],ax
        jz .found ; ↓
    endif ; 20ac
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
    mov ax,[si+TrapListPtr+FarPtr.Off]
    mov dx,[si+TrapListPtr+FarPtr.Seg]
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
endfunc

; 211a

func PressTrapButton
    %arg x:word, y:word, arg_a:word
    %define firstTrap (bp-0x6)
    %define lastTrap (bp-0x4)
    sub sp,byte +0x6
    push si
    push word [arg_a]
    push byte SwitchSound
    call far PlaySoundEffect ; 212d 8:56c
    add sp,byte +0x4
    push word [y]
    push word [x]
    call far FindTrapByButton ; 213b 3:2270
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
    call far FindTrapSpan ; 216c 3:206c
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
endfunc

; 21aa

func EnterTrap
    sub sp,byte +0xa
    push di
    push si
    %arg xdest:word, ydest:word
    %arg xsrc:word, ysrc:word
    %local lastTrap:word ; -4
    %local firstTrap:word ; -6
    %local index:word

    lea ax,[lastTrap]
    push ax
    lea ax,[firstTrap]
    push ax
    push word [ydest]
    push word [xdest]
    call far FindTrapSpan ; 21c7 3:206c
    add sp,byte +0x8
    or ax,ax
    if z
        jmp word .end ; ↓
    endif ; 21d6
    mov di,0x1
    mov cx,[firstTrap]
    cmp cx,[lastTrap]
    jg .label4 ; ↓
    mov [index],di
    ;
    mov si,[GameStatePtr]
    mov ax,[si+TrapListPtr+FarPtr.Off]
    mov dx,[si+TrapListPtr+FarPtr.Seg]
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
    mov di,[index]
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
    mov [index],di
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
    jng .notfound ; ↓
    mov si,bx
    les bx,[si+TrapListPtr]
    mov di,[x]
.loop: ; 2294
    cmp [es:bx+Connection.fromX],di
    if e
        mov ax,[y]
        cmp [es:bx+Connection.fromY],ax
        jz .found ; ↓
    endif ; 22a2
    add bx,byte Connection_size
    inc cx
    cmp [si+TrapListLen],cx
    jg .loop ; ↑
    jmp short .notfound ; ↓
.found: ; 22ae
    mov ax,cx
    jmp short .end ; ↓
.notfound: ; 22b2
    mov ax, -1
.end: ; 22b5
    pop si
    pop di
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
    mov ax,[si+TrapListPtr+FarPtr.Off]
    mov dx,[si+TrapListPtr+FarPtr.Seg]
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
endfunc

; 2318

func AddTrap_Unused
    sub sp,byte +0x2
    push si
    mov bx,[GameStatePtr]
    mov ax,[bx+TrapListCap]
    cmp [bx+TrapListLen],ax
    jl .longEnough ; ↓
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
    call far GrowArray ; 234a 3:1a4
    add sp,byte +0xa
    or ax,ax
    if z
        mov ax,-1
        jmp short .end ; ↓
        nop
    endif
.longEnough: ; 235c
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
.end: ; 23be
    pop si
endfunc

; 23c6

func DeleteTrap_Unused
    sub sp,byte +0x4
    push di
    push si
    mov bx,[bp+0x6]
    or bx,bx
    jl .label1 ; ↓
    mov si,[GameStatePtr]
    cmp [si+TrapListLen],bx
    jng .label1 ; ↓
    dec word [si+TrapListLen]
    mov si,[GameStatePtr]
    cmp [si+TrapListLen],bx
    jng .label1 ; ↓
    mov ax,bx
    shl ax,byte 0x2
    add ax,bx
    shl ax,1
    mov [bp-0x4],ax
.label0: ; 2400
    mov bx,[GameStatePtr]
    mov ax,[bx+TrapListPtr+FarPtr.Off]
    mov dx,[bx+TrapListPtr+FarPtr.Seg]
    add ax,[bp-0x4]
    mov cx,ax
    mov bx,dx
    add ax,0xa
    push ds
    mov di,cx
    mov si,ax
    mov es,bx
    mov ds,dx
    mov cx,0x5
    rep movsw
    pop ds
    add word [bp-0x4],byte +0xa
    inc word [bp+0x6]
    mov ax,[bp+0x6]
    mov bx,[GameStatePtr]
    cmp [bx+TrapListLen],ax
    jg .label0 ; ↑
.label1: ; 2439
    pop si
    pop di
endfunc

; 2442

func PressCloneButton
    %arg hDC:word ; +6
    %arg buttonX:word ; +8
    %arg buttonY:word ; +a
    %arg arg_c:word ; +c
    %define cloneTile (bp-0x3)
    %local local_4:byte ; -4
    %local monsterX:word ; -6
    %local monsterY:word ; -8
    %local ydir:word ; -a
    %local xdir:word ; -c
    %local dummyVar:word ; -e
    %define destX buttonX
    %define destY buttonY
    sub sp,byte %$localsize
    push di
    push si
    ; Play the button sound
    push word [arg_c]
    push byte SwitchSound
    call far PlaySoundEffect ; 2456 8:56c
    add sp,byte +0x4
    ; Find the index in the clone connection list
    ; store it in si
    push word [buttonY]
    push word [buttonX]
    call far FindCloneMachine ; 2464 3:260e
    add sp,byte +0x4
    mov si,ax
    or si,si
    jnl .foundCloneMachine ; ↓
    jmp .end ; ↓
.foundCloneMachine: ; 2475
    ; Load the destination coords
    ; and store monsterX,monsterY
    shl si,byte 0x3
    mov bx,[GameStatePtr]
    les di,[bx+CloneListPtr]
    add di,si
    mov ax,[es:di+Connection.toX]
    mov [monsterX],ax
    mov [destX],ax
    mov cx,[es:di+Connection.toY]
    mov [monsterY],cx
    mov [destY],cx
    ; Load the upper tile at the destination coords
    ; which should be the monster we're cloning
    ; clonetile = gameStatePtr->Upper[si]
    lea dx,[ydir]
    push dx
    lea dx,[xdir]
    push dx
    mov bx,cx
    shl bx,byte 0x5
    add bx,ax
    mov si,[GameStatePtr]
    mov al,[bx+si+Upper]
    mov [cloneTile],al
    ; Get xdir and ydir from monster tile
    push ax
    call far GetMonsterDir ; 24af 3:4d8
    add sp,byte +0x6
    ; Did GetMonsterDir succeed?
    ; if so, we're cloning a monster
    ; if not, we're cloning a block
    or ax,ax
    jnz .cloneMonster ; ↓
    jmp .cloneBlock ; ↓

.cloneMonster: ; 24be
    ; check if the destination tile is in bounds
    ; if not, return
    mov ax,[ydir]
    add [destY],ax
    mov ax,[xdir]
    add [destX],ax
    if s
        jmp .end ; ↓
    endif ; 24cf
    cmp word [destY],byte +0x0
    if l
        jmp .end ; ↓
    endif ; 24d8
    cmp word [destX],byte +0x20
    if ge
        jmp .end ; ↓
    endif ; 24e1
    cmp word [destY],byte +0x20
    if ge
        jmp .end ; ↓
    endif
.inBounds: ; 24ea
    ; Is the monster allowed to enter the destination tile?
    lea ax,[dummyVar]
    push ax
    push word [ydir]
    push word [xdir]
    push word [destY]
    push word [destX]
    mov al,[cloneTile]
    push ax
    call far MonsterCanEnterTile ; 24fe 3:1d4a
    add sp,byte +0xc
    or ax,ax
    jnz .findMonster ; ↓
    ; are we blocked because there is
    ; already a monster with the same tile
    ; in front of the clone machine?
    mov al,[cloneTile]
    mov bx,[destY]
    shl bx,byte 0x5
    add bx,[destX]
    mov si,[GameStatePtr]
    cmp [bx+si+Upper],al
    jz .findMonster ; ↓
    jmp .end ; ↓
.findMonster: ; 2521
    ; Look for the clone machine coords on the
    ; monster list. if it's not there, add it
    push word [monsterY]
    push word [monsterX]
    call far FindMonster ; 2527 3:0
    add sp,byte +0x4
    inc ax
    jz .addMonster ; ↓
    jmp .end ; ↓
.addMonster: ; 2535
    push byte +0x1
    push word [ydir]
    push word [xdir]
    push word [monsterY]
    push word [monsterX]
    mov al,[cloneTile]
    push ax
    call far NewMonster ; 2547 3:228
    add sp,byte +0xc
    push word [destY]
    push word [destX]
    call far InvalidateTile ; 2555 2:2b2
    add sp,byte +0x4
    jmp .end ; ↓

.cloneBlock: ; 2560
    ; Figure out the clone direction based on the clone machine tile
    mov al,[cloneTile]
    sub ah,ah
    sub ax,BlockN
    jz .blockN ; ↓
    dec ax ; BlockW
    jz .blockW ; ↓
    dec ax ; BlockS
    jz .blockS ; ↓
    dec ax ; BlockE
    jz .blockE ; ↓
    jmp short .default ; ↓
    nop
.blockN: ; 2576
    mov word [xdir],0x0
    mov word [ydir],-1
    jmp short .default ; ↓
.blockW: ; 2582
    mov word [xdir],-1
    jmp short .clear_ydir ; ↓
    nop
.blockS: ; 258a
    mov word [xdir],0x0
    mov word [ydir],0x1
    jmp short .default ; ↓
.blockE: ; 2596
    mov word [xdir],0x1
.clear_ydir: ; 259b
    mov word [ydir],0x0
.default: ; 25a0
    ; cloneTile = Block
    mov byte [cloneTile],Block
    ; check if the destination tile is in bounds
    ; if not, return
    mov ax,[ydir]
    add [destY],ax
    mov ax,[xdir]
    add [destX],ax
    js .end ; ↓
    cmp word [destY],byte +0x0
    jl .end ; ↓
    cmp word [destX],byte +0x20
    jnl .end ; ↓
    cmp word [destY],byte +0x20
    jnl .end ; ↓
    ; Check if the block is allowed to enter the destination tile
    ; if not, return
    lea ax,[dummyVar]
    push ax
    push word [ydir]
    push word [xdir]
    push word [destY]
    push word [destX]
    push byte +0xa
    call far BlockCanEnterTile ; 25d6 3:1ca4
    add sp,byte +0xc
    or ax,ax
    jz .end ; ↓
    ; Move the block there immediately
    push byte +0x0
    push byte Block
    push word [ydir]
    push word [xdir]
    mov ax,[destY]
    sub ax,[ydir]
    push ax
    mov ax,[destX]
    sub ax,[xdir]
    push ax
    push word [hDC]
    call far MoveBlock ; 25fd 7:dae
    add sp,byte +0xe
.end: ; 2605
    pop si
    pop di
endfunc

; 260e

; Find the index of the clone machine with a button at x,y
; Returns -1 if not found.
func FindCloneMachine
    %arg x:word, y:word
    sub sp,byte +0x2
    push di
    push si
    xor cx,cx
    mov bx,[GameStatePtr]
    cmp [bx+CloneListLen],cx
    jng .label3 ; ↓
    mov si,bx
    les bx,[si+CloneListPtr]
    mov di,[x]
.label0: ; 2632
    cmp [es:bx+Connection.fromX],di
    jnz .label1 ; ↓
    mov ax,[y]
    cmp [es:bx+Connection.fromY],ax
    jz .label2 ; ↓
.label1: ; 2640
    add bx,byte +0x8
    inc cx
    cmp [si+CloneListLen],cx
    jg .label0 ; ↑
    jmp short .label3 ; ↓
.label2: ; 264c
    mov ax,cx
    jmp short .label4 ; ↓
.label3: ; 2650
    mov ax, -1
.label4: ; 2653
    pop si
    pop di
endfunc

; 265c

func AddCloneMachine_Unused
    sub sp,byte +0x2
    push si
    mov bx,[GameStatePtr]
    mov ax,[bx+CloneListCap]
    cmp [bx+CloneListLen],ax
    jl .havespace ; ↓
    push byte +0x8
    push byte +0x8
    mov ax,bx
    add ax,CloneListCap
    push ax
    mov ax,bx
    add ax,CloneListPtr
    push ax
    mov ax,bx
    add ax,CloneListHandle
    push ax
    call far GrowArray ; 268e 3:1a4
    add sp,byte +0xa
    or ax,ax
    if z
        mov ax,-1
        jmp short .end ; ↓
        nop
    endif ; 26a0
.havespace:
    mov si,[GameStatePtr]
    mov bx,[si+CloneListLen]
    inc word [si+CloneListLen]
    mov ax,[bp+0x6]
    mov si,bx
    mov cx,bx
    shl si,byte 0x3
    mov bx,[GameStatePtr]
    les bx,[bx+CloneListPtr]
    mov [es:bx+si+Connection.fromX],ax
    mov bx,[GameStatePtr]
    les bx,[bx+CloneListPtr]
    mov ax,[bp+0x8]
    mov [es:bx+si+Connection.fromY],ax
    mov bx,[GameStatePtr]
    les bx,[bx+CloneListPtr]
    mov word [es:bx+si+Connection.toX],-1
    mov bx,[GameStatePtr]
    les bx,[bx+CloneListPtr]
    mov word [es:bx+si+Connection.toY],-1
    mov ax,cx
.end: ; 26ee
    pop si
endfunc

; 26f6

func DeleteCloneMachine_Unused
    sub sp,byte +0x4
    push di
    push si
    mov dx,[bp+0x6]
    or dx,dx
    jl .label1 ; ↓
    mov bx,[GameStatePtr]
    cmp [bx+CloneListLen],dx
    jng .label1 ; ↓
    dec word [bx+CloneListLen]
    mov bx,[GameStatePtr]
    cmp [bx+CloneListLen],dx
    jng .label1 ; ↓
    mov ax,dx
    shl ax,byte 0x3
    mov [bp-0x4],ax
.label0: ; 272c
    mov ax,[bx+CloneListPtr+FarPtr.Off]
    mov dx,[bx+CloneListPtr+FarPtr.Seg]
    add ax,[bp-0x4]
    mov cx,ax
    mov bx,dx
    add ax,0x8
    push ds
    mov di,cx
    mov si,ax
    mov es,bx
    mov ds,dx
    movsw
    movsw
    movsw
    movsw
    pop ds
    add word [bp-0x4],byte +0x8
    inc word [bp+0x6]
    mov ax,[bp+0x6]
    mov bx,[GameStatePtr]
    cmp [bx+CloneListLen],ax
    jg .label0 ; ↑
.label1: ; 2760
    pop si
    pop di
endfunc

; 276a

func EnterTeleport
    sub sp,byte +0xe
    push di
    push si
    mov bx,[bp+0xa]
    push word [bx]
    mov si,[bp+0x8]
    push word [si]
    call far FindTeleport ; 2783 3:2910
    add sp,byte +0x4
    mov di,ax
    mov bx,[bp+0xa]
    mov bx,[bx]
    shl bx,byte 0x5
    add bx,[si]
    mov si,[GameStatePtr]
    mov al,[bx+si+Upper]
    mov [bp-0x7],al
    or di,di
    if l
        jmp .end ; ↓
    endif ; 27a7
    lea bx,[di-0x1]
    or bx,bx
    if l
        mov bx,[GameStatePtr]
        mov bx,[bx+TeleportListLen]
        dec bx
    endif ; 27b7
    cmp bx,di
    if e
        jmp .end ; ↓
    endif ; 27be
    mov [bp-0xa],bx
    mov [bp-0xe],di
    mov di,[bp+0xe]
.loop: ; 27c7
    mov bx,[GameStatePtr]
    les bx,[bx+TeleportListPtr]
    mov si,[bp-0xa]
    shl si,byte 0x2
    mov ax,[es:bx+si+Point.x]
    mov [bp-0x6],ax
    add bx,si
    mov cx,[es:bx+Point.y]
    mov [bp-0x4],cx
    mov bx,cx
    shl bx,byte 0x5
    add bx,ax
    mov si,[GameStatePtr]
    cmp byte [bx+si],Teleport
    if ne
        jmp .nextTeleport ; ↓
    endif ; 27f7
    mov si,[bp+0xc]
    add [bp-0x4],di
    add [bp-0x6],si
    if s
        jmp .nextTeleport ; ↓
    endif ; 2805
    cmp word [bp-0x4],byte +0x0
    if l
        jmp .nextTeleport ; ↓
    endif ; 280e
    cmp word [bp-0x6],byte +0x20
    if ge
        jmp .nextTeleport ; ↓
    endif ; 2817
    cmp word [bp-0x4],byte +0x20
    if ge
        jmp .nextTeleport ; ↓
    endif ; 2820
    mov ax,[bp+0x10]
    or ax,ax
    jz .chipTeleport ; ↓
    dec ax
    jz .blockTeleport ; ↓
    dec ax
    jz .monsterTeleport ; ↓
    jmp .nextTeleport ; ↓
.chipTeleport: ; 2830
    mov bx,[bp-0x4]
    shl bx,byte 0x5
    add bx,[bp-0x6]
    add bx,[GameStatePtr]
    cmp byte [bx],Block
    if e
        push byte +0x0
        push word 0xff
        push di
        push si
        push word [bp-0x4]
        push word [bp-0x6]
        push word [bp+0x6]
        call far MoveBlock ; 2852 7:dae
        add sp,byte +0xe
        or ax,ax
        jz .nextTeleport ; ↓
    endif ; 285e
    push byte +0x1
    push byte +0x0
    lea ax,[bp-0xc]
    push ax
    push di
    push si
    push word [bp-0x4]
    push word [bp-0x6]
    call far ChipCanEnterTile ; 286e 3:1a56
    add sp,byte +0xe
    or ax,ax
    jz .nextTeleport ; ↓
    jmp short .playTeleportSound ; ↓
.blockTeleport: ; 287c
    lea ax,[bp-0xc]
    push ax
    push di
    push si
    push word [bp-0x4]
    push word [bp-0x6]
    mov al,[bp-0x7]
    push ax
    call far BlockCanEnterTile ; 288c 3:1ca4
    add sp,byte +0xc
    or ax,ax
    jz .nextTeleport ; ↓
    jmp short .finishTeleport ; ↓
.monsterTeleport: ; 289a
    lea ax,[bp-0xc]
    push ax
    push di
    push si
    push word [bp-0x4]
    push word [bp-0x6]
    mov al,[bp-0x7]
    push ax
    call far MonsterCanEnterTile ; 28aa 3:1d4a
    add sp,byte +0xc
    or ax,ax
    jnz .finishTeleport ; ↓
.nextTeleport: ; 28b6
    dec word [bp-0xa]
    if s ; result is negative
        mov bx,[GameStatePtr]
        mov ax,[bx+TeleportListLen]
        dec ax
        mov [bp-0xa],ax
    endif ; 28c7
    mov ax,[bp-0xe]
    cmp [bp-0xa],ax
    if ne
        jmp .loop ; ↑
    endif ; 28d2
    jmp short .end ; ↓
.playTeleportSound: ; 28d4
    push byte +0x1
    push byte +0xc
    call far PlaySoundEffect ; 28d8 8:56c
    add sp,byte +0x4
.finishTeleport: ; 28e0
    mov bx,[GameStatePtr]
    les bx,[bx+TeleportListPtr]
    mov si,[bp-0xa]
    shl si,byte 0x2
    mov ax,[es:bx+si+Point.x]
    mov bx,[bp+0x8]
    mov [bx],ax
    mov bx,[GameStatePtr]
    les bx,[bx+TeleportListPtr]
    mov ax,[es:bx+si+Point.y]
    mov bx,[bp+0xa]
    mov [bx],ax
.end: ; 2907
    pop si
    pop di
endfunc

; 2910

func FindTeleport
    sub sp,byte +0x2
    push di
    push si
    %arg x:word, y:word
    xor cx,cx
    mov bx,[GameStatePtr]
    cmp [bx+TeleportListLen],cx
    jng .notfound ; ↓
    mov si,bx
    les bx,[si+TeleportListPtr]
    mov di,[x]
.loop: ; 2934
    cmp [es:bx+Point.x],di
    jnz .next ; ↓
    mov ax,[y]
    cmp [es:bx+Point.y],ax
    jz .found ; ↓
.next: ; 2942
    add bx,byte +0x4
    inc cx
    cmp [si+TeleportListLen],cx
    jg .loop ; ↑
    jmp short .notfound ; ↓
.found: ; 294e
    mov ax,cx
    jmp short .end ; ↓
.notfound: ; 2952
    mov ax,-1
.end: ; 2955
    pop si
    pop di
endfunc

; 295e

func AddTeleport
    %arg x:word, y:word
    sub sp,byte +0x2
    push si

    ; Grow teleport list if out of space.
    mov bx,[GameStatePtr]
    mov ax,[bx+TeleportListCap]
    cmp [bx+TeleportListLen],ax
    jl .addTeleportToList
    push byte Point_size
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
    call far GrowArray ; 2990 3:1a4
    add sp,byte +0xa
    or ax,ax
    if z
        mov ax,-1
        jmp short .end
        nop
    endif ; 29a2
.addTeleportToList:
    mov si,[GameStatePtr]
    mov bx,[si+TeleportListLen]
    inc word [si+TeleportListLen]
    mov ax,[x]
    mov si,bx
    mov cx,bx
    shl si,byte 0x2
    mov bx,[GameStatePtr]
    les bx,[bx+TeleportListPtr]
    mov [es:bx+si+Point.x],ax
    mov ax,[y]
    mov bx,[GameStatePtr]
    les bx,[bx+TeleportListPtr]
    mov [es:bx+si+Point.y],ax
    mov ax,cx
.end: ; 29d4
    pop si
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
endfunc

; 2a3e

; Return the bitmap coordinates of the specified tile.
func GetTileImagePos
    sub sp,byte +0x6
    %arg tile:byte
    %local ypos:word ; -4
    %local xpos:word ; -6

    ; ax = a/16 * TileWidth
    ; dx = a%16 * TileHeight
    sub ah,ah
    mov al,[tile]
    shr ax,4
    imul ax,TileWidth
    mov [xpos],ax
    mov al,[tile]
    and ax,0xf
    imul ax,TileHeight
    mov [ypos],ax
    mov ax,[xpos]
    mov dx,[ypos]
endfunc

; 2a70

GLOBAL _segment_3_size
_segment_3_size equ $ - $$

; vim: syntax=nasm

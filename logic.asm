; SEGMENT 3
SEGMENT CODE
BITS 16

GameStatePtr    equ 0x1680

MonsterLen  equ 0x928
MonsterPtr  equ 0x92e
MonsterSeg  equ 0x930

; FindMonster returns the index of the monster at (x, y),
; or -1.
FindMonster: ; 3:0x0
    ; Standard function prologue
    ; See http://blogs.msdn.com/b/oldnewthing/archive/2011/03/16/10141735.aspx
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    push di
    push si

    %stacksize small
    %arg x:word, y:word

    xor cx,cx
    mov bx,[GameStatePtr]
    cmp [bx+MonsterLen],cx
    jng .notfound

    ; Initialize es:bx to point to the first monster
    ; on the monster list
    mov si,bx
    mov ax,[si+MonsterPtr]
    mov dx,[si+MonsterSeg]
    inc ax
    mov bx,ax
    mov es,dx
    mov di,[x]
.loop:
    ; if monster.x == x and monster.y == y
    ;   goto found
    cmp [es:bx],di
    jnz .next
    mov ax,[y]
    cmp [es:bx+0x2],ax
    jz .found
.next:
    add bx,byte +0xB
    inc cx
    cmp [si+MonsterLen],cx
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
    pop ds
    pop bp
    dec bp
    retf

; Same as above, but searches a different array.
FindSomething: ;0x58
    %stacksize small
    %arg x:word, y:word
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    push di
    push si

    xor cx,cx
    mov bx,[GameStatePtr]
    cmp [bx+0x91e],cx
    jng .notfound
    mov si,bx
    mov ax,[si+0x924]
    mov dx,[si+0x926]
    inc ax
    mov bx,ax
    mov es,dx
    mov di,[x]
.loop:
    cmp [es:bx],di
    jnz .next
    mov ax,[y]
    cmp [es:bx+0x2],ax
    jz .found
.next:
    add bx,byte +0xb
    inc cx
    cmp [si+0x91e],cx
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
    pop ds
    pop bp
    dec bp
    retf

;0xB0
TurnLeft:
    ;    x  y  ->  x  y
    ; W -1  0  ->  0  1  S
    ; N  0 -1  -> -1  0  W
    ; S  0  1  ->  1  0  E
    ; E  1  0  ->  0 -1  N

    %stacksize small
    %arg x:word, y:word, xOut:word, yOut:word
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2

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
    pop ds
    pop bp
    dec bp
    retf
    nop

; 116
TurnRight:
    ;    x  y  ->  x  y
    ; W -1  0  ->  0 -1  N
    ; N  0 -1  ->  1  0  E
    ; S  0  1  -> -1  0  W
    ; E  1  0  ->  0  1  S

    %stacksize small
    %arg x:word, y:word, xOut:word, yOut:word
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2

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
    pop ds
    pop bp
    dec bp
    retf
    nop

;17c
TurnAround:
    ;    x  y  ->  x  y
    ; W -1  0  ->  1  0  E
    ; N  0 -1  ->  0  1  S
    ; S  0  1  ->  0 -1  N
    ; E  1  0  -> -1  0  W

    %stacksize small
    %arg x:word, y:word, xOut:word, yOut:word
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2

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
    pop ds
    pop bp
    dec bp
    retf

; 1a4

INCBIN "chips.exe", 0x6200+$, 0x2a70 - 0x1a4

; vim: syntax=nasm

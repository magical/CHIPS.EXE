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

INCBIN "chips.exe", 0x6200+$, 0x2a70 - 0xB0

; vim: syntax=nasm

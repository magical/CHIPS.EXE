SEGMENT CODE ; 7

%include "constants.asm"
GameStatePtr    equ 0x1680

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
TrapListLen         equ 0x93c
TrapListPtr         equ 0x942
HaveMouseTarget     equ 0xa38
MouseTargetX        equ 0xa3a
MouseTargetY        equ 0xa3c
;HaveMouseTarget     equ 0xa40


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

Connection.flag     equ 8

FakeLastLevel equ 144
LastLevel     equ 149

; data
DecadeMessages equ 0xec2

; 0

; Mouse movement
One:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0xc
    push di
    push si

    %define hDC (bp-0xa)
    %define xdir (bp-0x6)
    %define ydir (bp-0x4)

    push word [0x12]    ; hWnd
    call word 0x0:0xffff ; 13 KERNEL.GetDC
    mov [hDC],ax
    test byte [bp+0x6],0x1
    jz .evenTick
    jmp word .oddTick
.evenTick: ; 24
    mov bx,[GameStatePtr]
    cmp word [bx+IsSliding],byte +0x0
    jz .label2
    jmp word .label3
.label2: ; 32
    cmp word [bx+0xa40],byte +0x0 ; no mouse target
    jz .label4
.label10: ; 39
    mov bx,[GameStatePtr]
    mov word [bx+0xa40],0x0
    jmp word .label3
.label4: ; 46
    cmp word [bx+IsBuffered],byte +0x0
    jz .label5
    cmp word [bx+Autopsy],byte NotDeadYet
    jnz .label6
    push byte +0x1
    push byte +0x1
    push word [bx+BufferedY]
    push word [bx+BufferedX]
    push ax
    call word 0x11e:0x1184 ; 61
    add sp,byte +0xa
.label6: ; 69
    mov bx,[GameStatePtr]
    mov word [bx+IsBuffered],0x0
    mov bx,[GameStatePtr]
    mov word [bx+0xa38],0x0
    jmp word .label3
.label5: ; 80
    cmp word [bx+0xa38],byte +0x0
    jnz .label7
    jmp word .label8
.label7: ; 8a
    ; If reached target, set 0xa38 to 0
    ; di = mousex - chipx
    mov ax,[bx+MouseTargetX] ; mouse target x
    sub ax,[bx+ChipX]
    mov di,ax
    ; si = mousey - chipy
    mov si,[bx+MouseTargetY] ; mouse target y
    sub si,[bx+ChipY]
    or ax,ax
    jnz .label9
    or si,si
    jnz .label9
    mov [bx+0xa38],ax ; = 0
    jmp short .label10
    ; mov [bx+0xa40], 0
    ; jmp .label3

.label9: ; aa
    ; cx = abs(x distance)
    cwd
    xor ax,dx
    sub ax,dx
    mov cx,ax

    ; ax = abs(y distance)
    mov ax,si
    cwd
    xor ax,dx
    sub ax,dx

    ; if ydistance >= xdistance
    cmp ax,cx
    jl .label11
    or si,si
    jng .label12
    mov word [xdir],0
    mov word [ydir],1
    jmp short .label13
.label12: ; cc
    mov word [xdir],0
    mov word [ydir],-1
    jmp short .label13
.label11: ; d8
    or di,di
    jng .label14
    mov word [xdir],1
    jmp short .label15
    nop
.label14: ; e4
    mov word [xdir],-1
.label15: ; e9
    mov word [ydir],0
.label13: ; ee
    cmp word [bx+Autopsy],byte +0x0
    jz .label16
    jmp word .dead
.label16: ; f8
    or si,si
    jz .label18
    or di,di
    jz .label18
    mov word [bp-0x8],0x0
    jmp short .label19
    nop
.label18: ; 108
    mov word [bp-0x8],0x1
.label19: ; 10d
    push word [bp-0x8]
    push byte +0x1
    push word [ydir]
    push word [xdir]
    push word [hDC]
    call word 0x19d:0x1184 ; 11b 7:1184
    add sp,byte +0xa
    or ax,ax
    jz .label20
    jmp word .dead
.label20: ; 12a
    mov bx,[GameStatePtr]
    cmp [bx+0xa38],ax
    jz .dead
    mov ax,di
    cwd
    xor ax,dx
    sub ax,dx
    mov cx,ax
    mov ax,si
    cwd
    xor ax,dx
    sub ax,dx
    cmp ax,cx
    jnl .label21
    jmp word .label22
.label21: ; 14b
    or di,di
    jng .label23
    mov word [xdir],1
.label26: ; 154
    mov word [ydir],0
    jmp short .label24
    nop
.label23: ; 15c
    or di,di
    jnl .label25
    mov word [xdir],-1
    jmp short .label26
    nop
.label25: ; 168
    xor ax,ax
    mov [ydir],ax
    mov [xdir],ax
.label24: ; 170
    mov bx,[GameStatePtr]
    cmp word [bx+Autopsy],byte +0x0
    jnz .dead
    mov word [bx+0xa40],0x0
    cmp word [xdir],byte +0x0
    jnz .label27
    cmp word [ydir],byte +0x0
    jz .label28
.label27: ; 18d
    push byte +0x1
    push byte +0x1
    push word [ydir]
    push word [xdir]
    push word [hDC]
    call word 0x2aa:0x1184 ; 19a
    add sp,byte +0xa
    or ax,ax
    jnz .dead
.label28: ; 1a6
    mov bx,[GameStatePtr]
    mov word [bx+0xa38],0x0
.dead: ; 1b0
    mov bx,[GameStatePtr]
    cmp word [bx+Autopsy],byte +0x0
    jnz .label29
    mov ax,[bx+MouseTargetX]
    cmp [bx+ChipX],ax
    jz .label30
    jmp word .label10
.label30: ; 1c8
    mov ax,[bx+MouseTargetY]
    cmp [bx+ChipY],ax
    jz .label29
    jmp word .label10
.label29: ; 1d5
    mov word [bx+0xa38],0x0
    jmp word .label10
.label22: ; 1de
    or si,si
    jng .label31
    mov word [xdir],0
    mov word [ydir],1
    jmp short .label24
.label31: ; 1ee
    or si,si
    jl .label32
    jmp word .label25
.label32: ; 1f5
    mov word [xdir],0
    mov word [ydir],-1
    jmp word .label24
.label8: ; 202
    mov ax,[bx+0xa3e]
    inc word [bx+0xa3e]
    cmp ax,0x2
    jl .label3
    mov bx,[GameStatePtr]
    mov ax,[bx+ChipY]
    shl ax,byte 0x5
    add ax,[bx+ChipX]
    add bx,ax
    mov al,[bx+Upper]
    mov [bp-0x3],al
    cmp al,0x6e
    jz .label3
    cmp al,0x3e
    jz .label3
    cmp byte [bx+Lower],Water
    jnz .label33
    mov al,0x3e
    jmp short .label34
.label33: ; 238
    mov al,0x6e
.label34: ; 23a
    mov [bx],al
    mov bx,[GameStatePtr]
    push word [bx+ChipY]
    push word [bx+ChipX]
    push word [hDC]
    call word 0xffff:0x1ca ; 24b
    add sp,byte +0x6

.label3: ; 253
    mov bx,[GameStatePtr]
    cmp word [bx+0x928],byte +0x0
    jz .label35
    mov al,[bp+0x6]
    and ax,0x3
    cmp ax,0x1
    sbb ax,ax
    neg ax
    push ax
    push word [hDC]
    call word 0xffff:0x74e ; 26f Monster loop
    add sp,byte +0x4
    jmp short .label35
    nop

.oddTick: ; 27a
    mov bx,[GameStatePtr]
    cmp word [bx+IsBuffered],byte +0x0
    jz .label35
    cmp word [bx+IsSliding],byte +0x0
    jnz .label35
    cmp word [bx+0xa40],byte +0x0
    jnz .label35
    cmp word [bx+Autopsy],byte NotDeadYet
    jnz .label36
    push byte +0x1
    push byte +0x1
    push word [bx+BufferedY]
    push word [bx+BufferedX]
    push ax
    call word 0x2ed:0x1184 ; 2a7
    add sp,byte +0xa
.label36: ; 2af
    mov bx,[GameStatePtr]
    mov word [bx+IsBuffered],0x0
    mov bx,[GameStatePtr]
    mov word [bx+0xa38],0x0

.label35: ; 2c3
    mov bx,[GameStatePtr]
    cmp word [bx+IsSliding],byte +0x0
    jnz .label37
    jmp word .label38
.label37: ; 2d1
    mov word [bx+0xa3e],0x0
    push byte +0x1
    push byte +0x0
    mov bx,[GameStatePtr]
    push word [bx+0x81a]
    push word [bx+0x818]
    push word [hDC]
    call word 0x33b:0x1184 ; 2ea
    add sp,byte +0xa
    or ax,ax
    jz .label39
    jmp word .label40
.label39: ; 2f9
    mov bx,[GameStatePtr]
    cmp [bx+0x80c],ax
    jnz .label41
    jmp word .label40
.label41: ; 306
    neg word [bx+0x818]
    mov si,[GameStatePtr]
    neg word [si+0x81a]
    push word 0xc6c
    push ax ; chip
    mov ax,[GameStatePtr]
    add ax,0x81a
    push ax
    mov ax,[GameStatePtr]
    add ax,0x818
    push ax
    mov bx,[GameStatePtr]
    push word [bx+ChipY]
    push word [bx+ChipX]
    push word [bx+ChipY]
    push word [bx+ChipX]
    call word 0x356:0x636 ; 338
    add sp,byte +0x10
    push byte +0x1
    push byte +0x0
    mov bx,[GameStatePtr]
    push word [bx+0x81a]
    push word [bx+0x818]
    push word [hDC]
    call word 0x398:0x1184 ; 353
    add sp,byte +0xa
    or ax,ax
    jnz .label40
    mov si,[GameStatePtr]
    neg word [si+0x818]
    mov si,[GameStatePtr]
    neg word [si+0x81a]
    push word 0xc6c
    push ax ; chip
    mov ax,[GameStatePtr]
    add ax,0x81a
    push ax
    mov ax,[GameStatePtr]
    add ax,0x818
    push ax
    mov bx,[GameStatePtr]
    push word [bx+ChipY]
    push word [bx+ChipX]
    push word [bx+ChipY]
    push word [bx+ChipX]
    call word 0xffff:0x636 ; 395
    add sp,byte +0x10
.label40: ; 39d
    mov bx,[GameStatePtr]
    cmp word [bx+0xa40],byte +0x0
    jz .label42
    mov word [bx+0xa40],0x0
    jmp word .label38
    nop
.label42: ; 3b2
    cmp word [bx+IsBuffered],byte +0x0
    jz .label43
    cmp word [bx+Autopsy],byte +0x0
    jnz .label44
    cmp word [bx+IsSliding],byte +0x0
    jz .label45
    mov ax,[bx+0x818]
    cmp [bx+BufferedX],ax
    jnz .label45
    mov ax,[bx+0x81a]
    cmp [bx+BufferedY],ax
    jz .label44
.label45: ; 3db
    push byte +0x1
    push byte +0x1
    push word [bx+BufferedY]
    push word [bx+BufferedX]
    push word [hDC]
    call word 0x4b8:0x1184 ; 3ea
    add sp,byte +0xa
.label44: ; 3f2
    mov bx,[GameStatePtr]
    mov word [bx+IsBuffered],0x0
    jmp word .label46
    nop
.label43: ; 400
    cmp word [bx+0xa38],byte +0x0
    jnz .label47
    jmp word .label38
.label47: ; 40a
    mov ax,[bx+MouseTargetX]
    sub ax,[bx+ChipX]
    mov di,ax
    mov si,[bx+MouseTargetY]
    sub si,[bx+ChipY]
    or ax,ax
    jnz .label48
    or si,si
    jnz .label48
    jmp word .label46
.label48: ; 427
    cwd
    xor ax,dx
    sub ax,dx
    mov cx,ax
    mov ax,si
    cwd
    xor ax,dx
    sub ax,dx
    cmp ax,cx
    jl .label49
    or si,si
    jng .label50
    mov word [xdir],0x0
    mov word [ydir],0x1
    jmp short .label51
    nop
.label50: ; 44a
    mov word [xdir],0x0
    mov word [ydir],0xffff
    jmp short .label51
.label49: ; 456
    or di,di
    jng .label52
    mov word [xdir],0x1
    jmp short .label53
    nop
.label52: ; 462
    mov word [xdir],0xffff
.label53: ; 467
    mov word [ydir],0x0
.label51: ; 46c
    cmp word [bx+Autopsy],byte +0x0
    jz .label54
    jmp word .label55
.label54: ; 476
    cmp word [bx+0x80c],byte +0x0
    jz .label56
    mov ax,[xdir]
    cmp [bx+0x818],ax
    jnz .label56
    mov ax,[ydir]
    cmp [bx+0x81a],ax
    jnz .label56
    jmp word .label55
.label56: ; 492
    or si,si
    jz .label57
    or di,di
    jz .label57
    mov word [bp-0x8],0x0
    jmp short .label58
    nop
.label57: ; 4a2
    mov word [bp-0x8],0x1
.label58: ; 4a7
    push word [bp-0x8]
    push byte +0x1
    push word [ydir]
    push word [xdir]
    push word [hDC]
    call word 0x56a:0x1184 ; 4b5
    add sp,byte +0xa
    or ax,ax
    jz .label59
    jmp word .label55
.label59: ; 4c4
    mov bx,[GameStatePtr]
    cmp [bx+0xa38],ax
    jnz .label60
    jmp word .label55
.label60: ; 4d1
    mov ax,di
    cwd
    xor ax,dx
    sub ax,dx
    mov cx,ax
    mov ax,si
    cwd
    xor ax,dx
    sub ax,dx
    cmp ax,cx
    jl .label61
    or di,di
    jng .label62
    mov word [xdir],0x1
.label65: ; 4ee
    mov word [ydir],0x0
    jmp short .label63
    nop
.label62: ; 4f6
    or di,di
    jnl .label64
    mov word [xdir],0xffff
    jmp short .label65
    nop
.label61: ; 502
    or si,si
    jng .label66
    mov word [xdir],0x0
    mov word [ydir],0x1
    jmp short .label63
.label66: ; 512
    or si,si
    jnl .label64
    mov word [xdir],0x0
    mov word [ydir],0xffff
    jmp short .label63
.label64: ; 522
    xor ax,ax
    mov [ydir],ax
    mov [xdir],ax
.label63: ; 52a
    mov bx,[GameStatePtr]
    cmp word [bx+Autopsy],byte +0x0
    jnz .label55
    cmp word [bx+0x80c],byte +0x0
    jz .label67
    mov ax,[xdir]
    cmp [bx+0x818],ax
    jnz .label67
    mov ax,[ydir]
    cmp [bx+0x81a],ax
    jz .label55
.label67: ; 54e
    cmp word [xdir],byte +0x0
    jnz .label68
    cmp word [ydir],byte +0x0
    jz .label69
.label68: ; 55a
    push byte +0x1
    push byte +0x1
    push word [ydir]
    push word [xdir]
    push word [hDC]
    call word 0x64:0x1184 ; 567
    add sp,byte +0xa
    or ax,ax
    jnz .label55
.label69: ; 573
    mov bx,[GameStatePtr]
    mov word [bx+0xa38],0x0
.label55: ; 57d
    mov bx,[GameStatePtr]
    cmp word [bx+Autopsy],byte +0x0
    jnz .label46
    mov ax,[bx+MouseTargetX]
    cmp [bx+ChipX],ax
    jnz .label38
    mov ax,[bx+MouseTargetY]
    cmp [bx+ChipY],ax
    jnz .label38
.label46: ; 59c
    mov bx,[GameStatePtr]
    mov word [bx+0xa38],0x0
.label38: ; 5a6
    ; Do slip list loop and release DC
    push word [hDC]
    call word 0x6a7:0x13de ; 5a9 3:13de Slip loop
    add sp,byte +0x2
    push word [0x12]
    push word [hDC]
    call word 0x0:0xffff ; 5b8 USER.ReleaseDC

    ; countdown timer?
    cmp word [0x1694],byte +0x0
    jng .end
    cmp word [bp+0x6],byte +0x0
    jz .end
    mov ax,[bp+0x6]
    mov cx,0xa
    sub dx,dx
    div cx
    or dx,dx
    jnz .end
    dec word [0x1694]
    cmp word [0x1694],byte +0xf
    jg .label71
    push byte +0x1
    push byte +0xd
    call word 0x607:0x56c ; 5e7 8:56c
    add sp,byte +0x4
.label71: ; 5ef
    push byte +0x1
    call word 0x619:0xcbe ; 5f1 2:cbe
    add sp,byte +0x2
    cmp word [0x1694],byte +0x0
    jnz .end
    push byte +0x1
    push byte +0xe
    call word 0xffff:0x56c ; 604 8:56c
    add sp,byte +0x4
    mov bx,[GameStatePtr]
    mov word [bx+Autopsy],OutOfTime
    call word 0x24e:0xb9a ; 616 2:b9a
    push byte +0x1
    mov bx,[GameStatePtr]
    push word [bx+0x800]
    call word 0xffff:0x356 ; 625 4:356
    add sp,byte +0x4
.end: ; 62d
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 636

; Slide movement
Two:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x16
    push di
    push si

    ;  6 x
    ;  8 y
    ;  a x
    ;  c y
    ;  e xdirptr
    ; 10 ydirptr
    ; 12 flag
    ; 14 ptr

    ; -4 (si) far pointer to x dir
    ; -6 seg
    ; -8 (di) far pointer to y dir
    ; -a seg

    mov bx,[bp+0xe]
    mov ax,[bx]
    mov [bp-0xc],ax
    mov bx,[bp+0x10]
    mov ax,[bx]
    mov [bp-0xe],ax
    mov ax,[bp+0x12]
    or ax,ax
    jz .label0 ; ax == 0
    dec ax
    jl .label1 ; ax < 1 => ax < 0
    jo .label1 ; ax - 1 overflows => ax == MININT16
    dec ax
    jng .label2 ; (ax-1) <= 1 => ax <= 2

    ; otherwise
.label1: ; 664
    ; uninitialized
    mov si,[bp-0x6]
    mov di,[bp-0xa]
    jmp short .label3

    ; flag == 0
.label0: ; 66c
    mov bx,[GameStatePtr]
    mov word [bx+0x80c],0x1 ; issliding?
    mov ax,[GameStatePtr]
    add ax,0x818 ; chip slide x?
    mov si,ax
    mov [bp-0x4],ds
    mov ax,[GameStatePtr]
    add ax,0x81a ; chip slide y?
    mov di,ax
    mov [bp-0x8],ds
    jmp short .label3

    ; flag == 2
.label2: ; 68e
    push word [bp+0x8]
    push word [bp+0x6]
    mov bx,[bp+0x8]
    shl bx,byte 0x5
    add bx,[bp+0x6]
    mov si,[GameStatePtr]
    mov al,[bx+si]
    push ax
    call word 0x6b9:0x1396 ; 6a4 FindSlipperAt
    add sp,byte +0x6
    mov [bp-0x12],ax
    mov [bp-0x10],dx
    or dx,ax
    jnz .label4
    call word 0x272:0x1250 ; 6b6 NewSlipper
    mov [bp-0x12],ax
    mov [bp-0x10],dx
.label4: ; 6c1
    mov ax,[bp-0x10]
    or ax,[bp-0x12]
    jnz .label5
    jmp word .label6
.label5: ; 6cc
    mov ax,[bp-0x12]
    mov dx,[bp-0x10]
    add ax,0x5
    mov si,ax
    mov [bp-0x4],dx
    mov ax,[bp-0x12]
    add ax,0x7
    mov di,ax
    mov [bp-0x8],dx

.label3: ; 6e5
    mov ax,[bp+0x6]
    cmp [bp+0xa],ax
    jnz .label7
    mov ax,[bp+0x8]
    cmp [bp+0xc],ax
    jnz .label7
    mov bx,[bp+0xc]
    shl bx,byte 0x5
    add bx,[bp+0xa]
    add bx,[GameStatePtr]
    mov al,[bx+Lower]
    jmp short .label8
.label7: ; 708
    mov bx,[bp+0xc]
    shl bx,byte 0x5
    add bx,[bp+0xa]
    add bx,[GameStatePtr]
    mov al,[bx]
.label8: ; 717
    mov [bp-0x13],al
    cmp al,ChipN
    jc .label9
    cmp al,ChipE
    jna .label10
.label9: ; 722
    cmp byte [bp-0x13],SwimN
    jc .label11
    cmp byte [bp-0x13],SwimE
    ja .label11
.label10: ; 72e
    mov al,[bx+Lower]
    mov [bp-0x13],al
.label11: ; 735
    mov al,[bp-0x13]
    sub ah,ah
    cmp ax,ForceRandom
    jnz .notForceRandom
    jmp word .label13
.notForceRandom: ; 742
    jna .label14
    jmp word .label15

.label14: ; 747
    cmp al,IceWallNW
    jz .iceWallNW
    jg .label17
    sub al,Ice
    jz .label18
    dec al
    jnz .notForceS
    jmp word .forceS
.notForceS: ; 758
    sub al,ForceN - ForceS
    jnz .notForceN
    jmp word .label22
.notForceN: ; 75f
    dec al
    jnz .notForceW
    jmp word .label24
.notForceW: ; 766
    dec al
    jnz .notForceE
    jmp word .label26
.notForceE: ; 76d
    jmp word .label15

.label17: ; 770
    sub al,IceWallNE
    jz .iceWallNE
    dec al
    jnz .notIceWallSE
    jmp word .iceWallSE
.notIceWallSE: ; 77b
    dec al
    jnz .notIceWallSW
    jmp word .iceWallSW
.notIceWallSW: ; 782
    sub al,Teleport - IceWallSW
    jz .label18
    sub al,Trap - Teleport
    jz .label18
    jmp word .label15

    ; Ice
.label18: ; 78d
    mov ax,[bp-0xc]
    mov es,[bp-0x4]
    mov [es:si],ax
    mov ax,[bp-0xe]
.label34: ; 799
    mov es,[bp-0x8]
    mov [es:di],ax
    jmp word .label15
    nop
    nop

    ; Ice wall NW
.iceWallNW: ; 7a4
    cmp word [bp-0xc],byte -0x1
    jnz .label32
    cmp word [bp-0xe],byte +0x0
    jz .forceS
.label32: ; 7b0
    cmp word [bp-0xc],byte +0x0
    jnz .label33
    cmp word [bp-0xe],byte -0x1
    jnz .label33
    jmp word .label24
.label33: ; 7bf
    mov ax,[bp-0xc]
    neg ax
    mov es,[bp-0x4]
    mov [es:si],ax
    mov ax,[bp-0xe]
    neg ax
    jmp short .label34
    nop

    ; Ice wall NE
.iceWallNE: ; 7d2
    cmp word [bp-0xc],byte +0x0
    jnz .label35
    cmp word [bp-0xe],byte -0x1
    jz .label26
.label35: ; 7de
    cmp word [bp-0xc],byte +0x1
    jnz .label33
    cmp word [bp-0xe],byte +0x0
    jnz .label33
    ; Force S
.forceS: ; 7ea
    mov es,[bp-0x4]
    mov word [es:si],0x0
    mov es,[bp-0x8]
    mov word [es:di],0x1
    jmp short .label15

    ; Ice wall SE
.iceWallSE: ; 7fc
    cmp word [bp-0xc],byte +0x0
    jnz .label36
    cmp word [bp-0xe],byte +0x1
    jnz .label36
.label26: ; 808
    ; set slide dir to -1,0
    mov es,[bp-0x4]
    mov word [es:si],-1
    jmp short .label37
.label36: ; 812
    cmp word [bp-0xc],byte +0x1
    jnz .label33
    cmp word [bp-0xe],byte +0x0
    jnz .label33
.label22: ; 81e
    ; set slide dir to 0,-1
    mov es,[bp-0x4]
    mov word [es:si],0
    mov es,[bp-0x8]
    mov word [es:di],-1
    jmp short .label15

    ; Ice wall SW
.iceWallSW: ; 830
    cmp word [bp-0xc],byte -0x1
    jnz .label38
    cmp word [bp-0xe],byte +0x0
    jz .label22
.label38: ; 83c
    cmp word [bp-0xc],byte +0x0
    jz .label39
    jmp word .label33
.label39: ; 845
    cmp word [bp-0xe],byte +0x1
    jz .label24
    jmp word .label33
.label24: ; 84e
    mov es,[bp-0x4]
    mov word [es:si],0x1
.label37: ; 856
    mov es,[bp-0x8]
    mov word [es:di],0x0

.label15: ; 85e
    mov es,[bp-0x4]
    mov ax,[es:si]
    mov bx,[bp+0xe]
    mov [bx],ax
    mov es,[bp-0x8]
    mov ax,[es:di]
    mov bx,[bp+0x10]
    mov [bx],ax
    cmp word [bp+0x12],byte +0x1
    jz .label40
    cmp word [bp+0x12],byte +0x2
    jz .label40
    jmp word .label6
.label40: ; 883
    ; if flag == 2 && *di != 0xff, *di = SetTileDir(*di, xdir, ydir)
    mov di,[bp+0x14]
    cmp word [bp+0x12],byte +0x2
    jnz .label41
    cmp byte [di],0xff
    jz .label41
    push word [bp-0xe]
    push word [bp-0xc]
    mov al,[di]
    push ax
    call word 0x8b3:0x486 ; 89a SetTileDir
    add sp,byte +0x6
    mov [di],al
.label41: ; 8a4

    cmp byte [di],0xff
    jz .label42
    mov al,[di]
    jmp short .label43
    nop

    ; Force Random
.label13: ; 8ae
    push byte +0x4
    call word 0x91e:0x72e ; 8b0 Rand
    add sp,byte +0x2
    or ax,ax
    jnz .label44
    jmp word .label22
.label44: ; 8bf
    dec ax
    jnz .label45
    jmp word .forceS
.label45: ; 8c5
    dec ax
    jnz .label46
    jmp word .label26
.label46: ; 8cb
    dec ax
    jnz .label47
    jmp word .label24
.label47: ; 8d1
    jmp short .label15
    nop

.label42: ; 8d4
    mov bx,[bp+0x8]
    shl bx,byte 0x5
    add bx,[bp+0x6]
    mov si,[GameStatePtr]
    mov al,[bx+si]
.label43: ; 8e3
    les bx,[bp-0x12]
    mov [es:bx],al
    mov ax,[bp+0xa]
    les bx,[bp-0x12]
    mov [es:bx+0x1],ax
    mov ax,[bp+0xc]
    mov [es:bx+0x3],ax
    cmp word [bp+0x12],byte +0x2
    jnz .label48
    mov ax,0x1
    jmp short .label49
    nop
.label48: ; 906
    xor ax,ax
.label49: ; 908
    les bx,[bp-0x12]
    mov [es:bx+0x9],ax
    cmp word [bp+0x12],byte +0x2
    jnz .label6
    push word [bp+0x8]
    push word [bp+0x6]
    call word 0x993:0x0 ; 91b
    add sp,byte +0x4
    mov si,ax
    cmp byte [di],0xff
    jz .label50
    mov al,[di]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    mov di,si
    shl di,byte 0x2
    add di,si
    shl di,1
    add di,si
    mov [es:bx+di],al
.label50: ; 942
    mov bx,si
    mov ax,bx
    shl bx,byte 0x2
    add bx,ax
    shl bx,1
    add bx,ax
    mov si,[GameStatePtr]
    les si,[si+MonsterListPtr]
    mov word [es:bx+si+0x9],0x1
.label6: ; 95d
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 966

; DrawTile
Three:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0xa

    ; 10 tile
    ; 12 tile

    cmp byte [bp+0x12],Floor
    jnz .label0
    jmp word .label1
.label0: ; 97c
    cmp byte [bp+0x10],FirstTransparent
    jnc .label2
    jmp word .label1
.label2: ; 985
    cmp byte [bp+0x10],LastTransparent
    jna .label3
    jmp word .label1
.label3: ; 98e
    push byte +0x20
    call word 0x9a5:0x2a3e ; 990 GetTileImagePos
    add sp,byte +0x2
    mov [bp-0xa],ax
    mov [bp-0x8],dx
    mov al,[bp+0x12]
    push ax
    call word 0x9d1:0x2a3e ; 9a2 GetTileImagePos
    add sp,byte +0x2
    push word [0x1734]
    push word [bp-0xa]
    push word [bp-0x8]
    push byte +0x20
    push byte +0x20
    push word [0x1734]
    push ax
    push dx
    push word 0xcc
    push byte +0x20
    call word 0x0:0x9f1 ; 9c3 GDI.BitBlt
    mov al,[bp+0x10]
    add al,0x60
    push ax
    call word 0x9fe:0x2a3e ; 9ce GetTileImagePos
    add sp,byte +0x2
    push word [0x1734]
    push word [bp-0xa]
    push word [bp-0x8]
    push byte +0x20
    push byte +0x20
    push word [0x1734]
    push ax
    push dx
    push word 0xee
    push word 0x86
    call word 0x0:0xa1e ; 9f0 GDI.BitBlt
    mov al,[bp+0x10]
    add al,0x30
    push ax
    call word 0xa45:0x2a3e ; 9fb GetTileImagePos
    add sp,byte +0x2
    push word [0x1734]
    push word [bp-0xa]
    push word [bp-0x8]
    push byte +0x20
    push byte +0x20
    push word [0x1734]
    push ax
    push dx
    push word 0x88
    push word 0xc6
    call word 0x0:0xffff ; a1d GDI.BitBlt
    push word [bp+0x6]
    push word [bp+0x8]
    push word [bp+0xa]
    push word [bp+0xc]
    push word [bp+0xe]
    push word [0x1734]
    push word [bp-0xa]
    push word [bp-0x8]
    jmp short .label4
    nop
.label1: ; a3e
    mov al,[bp+0x10]
    push ax
    call word 0x5ac:0x2a3e ; a42 GetTileImagePos
    add sp,byte +0x2
    push word [bp+0x6]
    push word [bp+0x8]
    push word [bp+0xa]
    push word [bp+0xc]
    push word [bp+0xe]
    push word [0x1734]
    push ax
    push dx
.label4: ; a5f
    push byte +0x20
    push byte +0x20
    push word 0xcc
    push byte +0x20
    call word 0x0:0xffff ; a68 GDI.StretchBlt
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; a74

Four:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,0x19e
    push di
    push si
    push word [0x12]
    call word 0x0:0x14 ; a88
    mov [bp-0x8],ax
    mov bx,[GameStatePtr]
    cmp word [bx+0xa36],byte +0x20
    jnl .label0
    mov si,[bx+0xa36]
    mov ax,si
    mov cx,0x3
    shl si,byte 0x3
    cwd
    idiv cx
    mov ax,dx
    or ax,ax
    jz .label1
    dec ax
    jz .label2
    dec ax
    jz .label3
    jmp short .label4
    nop
    nop
.label1: ; aba
    mov byte [bp-0x3],0x15
    jmp short .label4
.label2: ; ac0
    mov byte [bp-0x3],0x3a
    jmp short .label4
.label3: ; ac6
    mov byte [bp-0x3],0x3b
.label4: ; aca
    mov al,[bp-0x3]
    push ax
    push byte +0x6e
    lea ax,[si+0x20]
    push ax
    push ax
    mov ax,si
    cwd
    sub ax,dx
    sar ax,1
    mov bx,[GameStatePtr]
    mov cx,[bx+0x80a]
    sub cx,[bx+0xa26]
    sub cx,[bx+0xa2e]
    shl cx,byte 0x5
    sub cx,ax
    jns .label5
    xor cx,cx
.label5: ; af5
    push cx
    mov cx,[bx+0x808]
    sub cx,[bx+0xa24]
    sub cx,[bx+0xa2c]
    shl cx,byte 0x5
    sub cx,ax
    jns .label6
    xor cx,cx
.label6: ; b0b
    push cx
.label10: ; b0c
    push word [bp-0x8]
    call word 0x3ed:0x966 ; b0f
    add sp,byte +0xe
    jmp word .label7
.label0: ; b1a
    cmp word [bx+0xa36],byte +0x68
    jnl .label8
    mov ax,[bx+0xa36]
    mov cx,0x2
    cwd
    idiv cx
    or dx,dx
    jz .label9
    cmp word [bp+0x6],byte +0x0
    jnz .label9
    jmp word .label7
.label9: ; b38
    push byte +0x15
    push cx
    call word 0xe13:0x72e ; b3b
    add sp,byte +0x2
    cmp ax,0x1
    sbb al,al
    and al,0x35
    add al,0x39
    mov [bp-0x3],al
    push ax
    push word 0x120
    push word 0x120
    push byte +0x0
    push byte +0x0
    jmp short .label10
.label8: ; b5c
    cmp word [bx+0xa36],byte +0x69
    jl .label11
    jmp word .label12
.label11: ; b66
    cmp word [bp+0x6],byte +0x0
    jz .label13
    jmp word .label12
.label13: ; b6f
    mov word [bp-0x4],0x0
    push byte +0x0
    push ds
    push word 0xc6e
    push word [0x10]
    call word 0xbe4:0x0 ; b7e
    add sp,byte +0x8
    push word [0x172a]
    push ds
    push word 0x1352
    call word 0x0:0xc59 ; b8e
    mov [bp-0x6],ax
    or ax,ax
    jz .label14
    push word [0x1734]
    push ax
    call word 0x0:0xbcb ; b9f
    mov si,ax
    push word [bp-0x8]
    push byte +0x0
    push byte +0x0
    push word 0x120
    push word 0x120
    push word [0x1734]
    push byte +0x0
    push byte +0x0
    push word 0xcc
    push byte +0x20
    call word 0x0:0xc8a ; bc0
    push word [0x1734]
    push si
    call word 0x0:0xc69 ; bca
    push word [bp-0x6]
    call word 0x0:0xc9a ; bd2
.label14: ; bd7
    push byte +0x0
    push ds
    push word 0xca8
    push word [0x10]
    call word 0xbfb:0x0 ; be1
    add sp,byte +0x8
    mov si,0x1
    mov di,[bp-0x4]
.label17: ; bef
    lea ax,[bp-0xc]
    push ax
    push byte +0x0
    push byte +0x0
    push si
    call word 0xc42:0x1adc ; bf8
    add sp,byte +0x8
    or ax,ax
    jz .label15
    cmp word [bp-0xc],byte -0x1
    jnz .label16
    cmp word [bp-0xa],byte -0x1
    jz .label15
.label16: ; c10
    inc di
.label15: ; c11
    inc si
    cmp si,0x95
    jng .label17
    push word [0x1698]
    push word [0x1696]
    push di
    push ds
    push word 0xd44
    lea ax,[bp-0x19e]
    push ss
    push ax
    call word 0x0:0xffff ; c2b
    add sp,byte +0xe
    push byte +0x0
    lea ax,[bp-0x19e]
    push ss
    push ax
    push word [0x10]
    call word 0xcdc:0x0 ; c3f
    add sp,byte +0x8
    jmp short .label7
    nop
.label12: ; c4a
    cmp word [bp+0x6],byte +0x0
    jz .label18
    push word [0x172a]
    push ds
    push word 0x135a
    call word 0x0:0xffff ; c58
    mov si,ax
    or si,si
    jz .label18
    push word [0x1734]
    push si
    call word 0x0:0xc94 ; c68
    mov di,ax
    push word [bp-0x8]
    push byte +0x0
    push byte +0x0
    push word 0x120
    push word 0x120
    push word [0x1734]
    push byte +0x0
    push byte +0x0
    push word 0xcc
    push byte +0x20
    call word 0x0:0x9c4 ; c89
    push word [0x1734]
    push di
    call word 0x0:0xffff ; c93
    push si
    call word 0x0:0xffff ; c99
.label18: ; c9e
    mov bx,[GameStatePtr]
    dec word [bx+0xa36]
.label7: ; ca6
    mov bx,[GameStatePtr]
    cmp word [bx+0xa36],byte +0x0
    jz .label19
    inc word [bx+0xa36]
.label19: ; cb5
    push word [0x12]
    push word [bp-0x8]
    call word 0x0:0x5b9 ; cbc
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; cca

; EndLevel
Five:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x6
    push di
    push si

    call word 0xd51:0x17a2 ; cd9 2:0x17a2

    ; Show level completed dialog
    push word 0xffff ; 6:
    push word 0x3c6  ; CompleteMsgProc
    push word [0x172a]
    call word 0x0:0xffff ; ce8  KERNEL.MakeProcInstance
    mov si,ax
    push word [0x172a]  ; hInstance
    push ds
    push word 0x1362    ; "DLG_COMPLETE"
    push word [bp+0x6]  ; hWndParent
    mov ax,dx
    push ax
    push si             ; lpDialogFunc
    mov di,ax
    call word 0x0:0xffff ; d00 USER.DialogBox
    push di
    push si
    call word 0x0:0xffff ; d07 KERNEL.FreeProcInstance
    mov bx,[GameStatePtr]
    cmp word [bx+LevelNumber],FakeLastLevel
    jz .lastLevel
    cmp word [bx+LevelNumber],LastLevel
    jz .lastLevel

    ; If the level number is divisible by 10
    ; and greater than or equal to 50
    ; and less than or equal to 140,
    ; show a decade message.
    mov ax,[bx+LevelNumber]
    mov cx,10
    cwd
    idiv cx
    or dx,dx
    jnz .noDecadeMsg
    mov ax,[bx+LevelNumber]
    cwd
    idiv cx
    mov si,ax
    cmp ax,5
    jl .noDecadeMsg
    cmp si,byte 14
    jg .noDecadeMsg
    push byte +0x0
    shl si,1
    push ds
    push word [DecadeMessages + si - 5*2]
    push word [0x10]
    call word 0xd59:0x0 ; d4e 2:0x0
    add sp,byte +0x8

.noDecadeMsg: ; d56
    call word 0xda3:0x17ba ; d56 2:0x17ba
    push byte +0x0
    mov bx,[GameStatePtr]
    mov ax,[bx+LevelNumber]
    inc ax
    push ax
    call word 0x628:0x356 ; d67 4:0x356
    add sp,byte +0x4
    jmp short .end
    nop

.lastLevel: ; d72
    mov word [bx+0xa36],0x1
    mov bx,[GameStatePtr]
    mov word [bx+0x80c],0x0
    mov bx,[GameStatePtr]
    mov word [bx+0x816],0x0
    mov bx,[GameStatePtr]
    mov word [bx+0x91e],0x0
    mov bx,[GameStatePtr]
    mov word [bx+0x928],0x0
    call word 0x5f4:0x17ba ; da0 2:0x17ba
.end: ; da5
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; dae

; move block?
Six:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0xe
    push si

    mov ax,[bp+0xe]
    add ax,[bp+0xa]
    mov [bp-0x6],ax
    mov ax,[bp+0xc]
    add ax,[bp+0x8]
    mov [bp-0x8],ax
    or ax,ax
    jnl .label0
    jmp word .label1
.label0: ; dd5
    cmp word [bp-0x6],byte +0x0
    jnl .label2
    jmp word .label1
.label2: ; dde
    cmp ax,0x20
    jl .label3
    jmp word .label1
.label3: ; de6
    cmp word [bp-0x6],byte +0x20
    jl .label4
    jmp word .label1
.label4: ; def
    mov si,[bp+0xa]
    shl si,byte 0x5
    add si,[bp+0x8]
    mov [bp-0xc],si
    mov bx,[GameStatePtr]
    mov al,[bx+si+0x400]
    mov [bp-0x3],al
    cmp al,0x2b
    jnz .label5
    push word [bp+0xa]
    push word [bp+0x8]
    call word 0xe5d:0x22be ; e10 FindTrap
    add sp,byte +0x4
    mov si,ax
    or si,si
    jnl .label6
    jmp word .label1
.label6: ; e21
    mov bx,ax
    shl bx,byte 0x2
    add bx,ax
    shl bx,1
    mov si,[GameStatePtr]
    les si,[si+0x942]
    cmp word [es:bx+si+0x8],byte +0x1
    jnz .label5
    jmp word .label1
.label5: ; e3c
    cmp byte [bp-0x3],0x6
    jc .label7
    cmp byte [bp-0x3],0x9
    jna .label8
.label7: ; e48
    cmp byte [bp-0x3],0x30
    jnz .label9
.label8: ; e4e
    push byte +0x0
    push word [bp+0xe]
    push word [bp+0xc]
    mov al,[bp-0x3]
    push ax
    call word 0xe8c:0x1934 ; e5a
    add sp,byte +0x8
    or ax,ax
    jnz .label9
    jmp word .label1
.label9: ; e69
    mov bx,[bp-0xc]
    mov si,[GameStatePtr]
    mov al,[bx+si]
    mov [bp-0x3],al
    lea ax,[bp-0xa]
    push ax
    push word [bp+0xe]
    push word [bp+0xc]
    push word [bp-0x6]
    push word [bp-0x8]
    mov al,[bp-0x3]
    push ax
    call word 0x89d:0x1ca4 ; e89
    add sp,byte +0xc
    or ax,ax
    jnz .label10
    jmp word .label1
.label10: ; e98
    mov ax,[bp-0xa]
    dec ax
    jz .label11
    dec ax
    jz .label12
    dec ax
    dec ax
    jz .label13
    dec ax
    jnz .label14
    jmp word .label15
.label14: ; eab
    dec ax
    jnz .label16
    jmp word .label17
.label16: ; eb1
    dec ax
    jnz .label18
    jmp word .label19
.label18: ; eb7
    jmp short .label20
    nop
.label12: ; eba
    push byte +0x1
    push byte +0xa
    call word 0x5ea:0x56c ; ebe
    add sp,byte +0x4
    mov byte [bp+0x10],0xb
    jmp short .label20
.label13: ; ecc
    lea ax,[bp+0x10]
    push ax
    push byte +0x1 ; block
    lea ax,[bp+0xe]
    push ax
    lea ax,[bp+0xc]
    push ax
    push word [bp-0x6]
    push word [bp-0x8]
    push word [bp+0xa]
    push word [bp+0x8]
    call word 0xf8f:0x636 ; ee6
    add sp,byte +0x10
.label11: ; eee
    mov bx,[bp-0x6]
    shl bx,byte 0x5
    add bx,[bp-0x8]
    mov si,[GameStatePtr]
    mov al,[bx+si]
    add bx,si
    mov [bx+0x400],al
.label20: ; f03
    cmp word [bp-0xa],byte +0x4
    jz .label21
    cmp word [bp-0xa],byte +0x6
    jz .label21
    mov bx,[GameStatePtr]
    cmp word [bx+0x91e],byte +0x0
    jz .label21
    push byte +0x1
    push word [bp+0xa]
    push word [bp+0x8]
    mov bx,[bp-0xc]
    mov si,[GameStatePtr]
    mov al,[bx+si]
    push ax
    call word 0xf69:0x12be ; f2c
    add sp,byte +0x8
.label21: ; f34
    cmp byte [bp+0x10],0xff
    jnz .label22
    jmp word .label23
.label22: ; f3d
    mov al,[bp+0x10]
    jmp word .label24
    nop
.label15: ; f44
    push byte +0x1
    push byte +0xb
    call word 0xec1:0x56c ; f48
    add sp,byte +0x4
    mov byte [bp+0x10],0x0
    jmp short .label20
.label17: ; f56
    push word [bp+0xa]
    push word [bp+0x8]
    mov bx,[bp-0xc]
    mov si,[GameStatePtr]
    mov al,[bx+si]
    push ax
    call word 0xfa3:0x1396 ; f66
    add sp,byte +0x6
    or dx,ax
    jz .label25
    lea ax,[bp+0x10]
    push ax
    push byte +0x1 ; block
    lea ax,[bp+0xe]
    push ax
    lea ax,[bp+0xc]
    push ax
    push word [bp-0x6]
    push word [bp-0x8]
    push word [bp+0xa]
    push word [bp+0x8]
    call word 0xfe4:0x636 ; f8c
    add sp,byte +0x10
.label25: ; f94
    push word [bp+0xa]
    push word [bp+0x8]
    push word [bp-0x6]
    push word [bp-0x8]
    call word 0xfc2:0x21aa ; fa0
    add sp,byte +0x8
    jmp word .label11
    nop
.label19: ; fac
    push byte +0x1
    push word [bp+0xe]
    push word [bp+0xc]
    lea ax,[bp-0x6]
    push ax
    lea cx,[bp-0x8]
    push cx
    push word [bp+0x6]
    call word 0x10a2:0x276a ; fbf
    add sp,byte +0xc
    lea ax,[bp+0x10]
    push ax
    push byte +0x1 ; block
    lea ax,[bp+0xe]
    push ax
    lea ax,[bp+0xc]
    push ax
    push word [bp-0x6]
    push word [bp-0x8]
    push word [bp+0xa]
    push word [bp+0x8]
    call word 0xb12:0x636 ; fe1
    add sp,byte +0x10
    mov bx,[bp-0x6]
    shl bx,byte 0x5
    add bx,[bp-0x8]
    mov si,[GameStatePtr]
    mov al,[bx+si]
    add bx,si
    mov [bx+0x400],al
    mov word [bp-0xa],0x4
    jmp word .label20
.label23: ; 1006
    mov al,[bp-0x3]
.label24: ; 1009
    mov bx,[bp-0x6]
    shl bx,byte 0x5
    add bx,[bp-0x8]
    mov si,[GameStatePtr]
    mov [bx+si],al
    push word [bp-0x6]
    push word [bp-0x8]
    push word [bp+0x6]
    call word 0x105c:0x1ca ; 1021
    add sp,byte +0x6
    mov bx,[bp-0xc]
    add bx,[GameStatePtr]
    cmp byte [bx+0x400],0x31
    jz .label26
    mov bx,[bp-0xc]
    add bx,[GameStatePtr]
    mov al,[bx+0x400]
    mov [bx],al
    mov bx,[GameStatePtr]
    mov si,[bp-0xc]
    mov byte [bx+si+0x400],0x0
.label26: ; 1050
    push word [bp+0xa]
    push word [bp+0x8]
    push word [bp+0x6]
    call word 0xb81:0x1ca ; 1059
    add sp,byte +0x6
    cmp word [bp-0xa],byte +0x1
    jz .label27
    jmp word .label28
.label27: ; 106a
    mov si,[bp-0x6]
    shl si,byte 0x5
    add si,[bp-0x8]
    mov bx,[GameStatePtr]
    mov al,[bx+si+0x400]
    mov [bp-0x3],al
    mov si,[bp+0x12]
    or si,si
    jnz .label29
    sub ah,ah
    sub ax,0x23
    jz .label30
    dec ax
    jz .label31
    sub ax,0x3
    jz .label32
    dec ax
    jz .label33
    jmp word .label34
    nop
    nop
.label30: ; 109c
    push word [bp+0x6]
    call word 0x10b8:0x1fac ; 109f
    add sp,byte +0x2
    jmp short .label34
    nop
.label31: ; 10aa
    push byte +0x0
    push word [bp-0x6]
    push word [bp-0x8]
    push word [bp+0x6]
    call word 0x10cb:0x2442 ; 10b5
    add sp,byte +0x8
    jmp short .label34
    nop
.label32: ; 10c0
    push byte +0x0
    push word [bp-0x6]
    push word [bp-0x8]
    call word 0x10da:0x211a ; 10c8
    add sp,byte +0x6
    jmp short .label34
.label33: ; 10d2
    push byte +0x0
    push word [bp+0x6]
    call word 0x1174:0x1e6a ; 10d7
    add sp,byte +0x4
    jmp short .label34
    nop
.label29: ; 10e2
    or si,si
    jz .label34
    cmp byte [bp-0x3],0x23
    jz .label35
    cmp byte [bp-0x3],0x28
    jz .label35
    cmp byte [bp-0x3],0x27
    jz .label35
    cmp byte [bp-0x3],0x24
    jnz .label34
.label35: ; 10fe
    mov word [si],0x1
    mov ax,[bp-0x8]
    mov [si+0x2],ax
    mov ax,[bp-0x6]
    mov [si+0x4],ax
    jmp short .label34
.label28: ; 1110
    mov bx,[bp+0x12]
    or bx,bx
    jz .label34
    mov word [bx],0x0
.label34: ; 111b
    mov si,[bp-0x6]
    shl si,byte 0x5
    add si,[bp-0x8]
    mov bx,[GameStatePtr]
    mov al,[bx+si+0x400]
    mov [bp-0xe],al
    cmp al,0x6c
    jc .label36
    cmp al,0x6f
    jna .label37
.label36: ; 1137
    cmp byte [bp-0xe],0x3c
    jc .label38
    cmp byte [bp-0xe],0x3f
    ja .label38
.label37: ; 1143
    mov word [bx+0x816],0x4
.label38: ; 1149
    mov ax,0x1
    jmp short .label39
.label1: ; 114e
    mov bx,[GameStatePtr]
    cmp word [bx+0x91e],byte +0x0
    jz .label40
    push byte +0x1
    push word [bp+0xa]
    push word [bp+0x8]
    mov bx,[bp+0xa]
    shl bx,byte 0x5
    add bx,[bp+0x8]
    mov si,[GameStatePtr]
    mov al,[bx+si]
    push ax
    call word 0xb3e:0x12be ; 1171
    add sp,byte +0x8
.label40: ; 1179
    xor ax,ax
.label39: ; 117b
    pop si
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 1184

; Process input?
; Move chip?
Seven:
    %define hDC (bp+0x6)
    %define xdir (bp+0x8)
    %define ydir (bp+0xa)
    %define x (bp-8)
    %define y (bp-0xa)
    %define tile (bp-0xb)
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x1c
    push di
    push si

    mov bx,[GameStatePtr]
    mov ax,[bx+ChipX]
    add ax,[xdir]
    mov [x],ax
    mov ax,[bx+ChipY]
    add ax,[ydir]
    mov [y],ax
    mov word [bp-0x10],0x0
    mov byte [bp-0xb],0xff

    ; if [0x22] != 0, return 0
    cmp word [0x22],byte +0x0
    jz .label0
.returnZero: ; 11bb
    xor ax,ax
    jmp word .end

.label0: ; 11c0
    ; If <something> and <something about the mouse>
    ; and no buffered move is stored,
    ; buffer the current move and return.
    mov dx,[bp+0xc]
    or dx,dx
    jz .label2
    cmp word [bx+0xa40],byte +0x0
    jz .label3
    cmp word [bx+IsBuffered],byte +0x0
    jnz .returnZero
    mov word [bx+IsBuffered],0x1
    mov ax,[xdir]
    mov bx,[GameStatePtr]
    mov [bx+BufferedX],ax
    mov ax,[ydir]
    mov bx,[GameStatePtr]
    mov [bx+BufferedY],ax
    jmp short .returnZero
    nop

.label3: ; 11f4 [bp+0xc] != 0 && [bx+0xa40] == 0
    mov word [bx+IsBuffered],0x0
    mov bx,[GameStatePtr]
    mov word [bx+0xa40],0x1
.label2: ; 1204 [bp+0xc] == 0
    mov bx,[GameStatePtr]
    mov word [bx+0xa3e],0x0

; Check board bounds
    cmp word [x],byte +0x0
    jnl .label5
    jmp word .label6
.label5: ; 1217
    cmp word [y],byte +0x0
    jnl .label7
    jmp word .label6
.label7: ; 1220
    cmp word [x],byte +0x20
    jl .label8
    jmp word .label6
.label8: ; 1229
    cmp word [y],byte +0x20
    jl .label9
    jmp word .label6
.label9: ; 1232
    mov bx,[GameStatePtr]
    cmp word [bx+0x80c],byte +0x0
    jz .label10
    mov si,[bx+0x80a]
    shl si,byte 0x5
    add si,[bx+0x808]
    mov al,[bx+si+0x400]
    mov [bp-0xb],al
    or dx,dx
    jz .label10
    cmp al,0xc
    jnz .label11
    jmp word .returnZero
.label11: ; 125a
    cmp al,0x1a
    jnz .label12
    jmp word .returnZero
.label12: ; 1261
    cmp al,0x1b
    jnz .label13
    jmp word .returnZero
.label13: ; 1268
    cmp al,0x1d
    jnz .label14
    jmp word .returnZero
.label14: ; 126f
    cmp al,0x1c
    jnz .label15
    jmp word .returnZero
.label15: ; 1276
    cmp al,0x29
    jnz .label16
    jmp word .returnZero
.label16: ; 127d
    cmp al,0xd
    jz .label17
    cmp al,0x12
    jz .label17
    cmp al,0x14
    jz .label17
    cmp al,0x13
    jz .label17
    cmp al,0x32
    jnz .label10
.label17: ; 1291
    mov ax,[bp+0x8]
    cmp [bx+0x818],ax
    jnz .label10
    mov ax,[bp+0xa]
    cmp [bx+0x81a],ax
    jnz .label10
    jmp word .returnZero
.label10: ; 12a6
    mov si,[bx+0x80a]
    shl si,byte 0x5
    add si,[bx+0x808]
    mov al,[bx+si+0x400]
    mov [bp-0x3],al
    cmp al,0x2b
    jnz .label18
    push word [bx+0x80a]
    push word [bx+0x808]
    call word 0x1311:0x22be ; 12c4 FindTrap
    add sp,byte +0x4
    mov si,ax
    or si,si
    jnl .label19
    jmp word .label6
.label19: ; 12d5
    mov bx,ax
    shl bx,byte 0x2
    add bx,ax
    shl bx,1
    mov si,[GameStatePtr]
    les si,[si+0x942]
    cmp word [es:bx+si+0x8],byte +0x1
    jnz .label18
    jmp word .label6
.label18: ; 12f0
    cmp byte [bp-0x3],0x6
    jc .label20
    cmp byte [bp-0x3],0x9
    jna .label21
.label20: ; 12fc
    cmp byte [bp-0x3],0x30
    jnz .label22
.label21: ; 1302
    push byte +0x0
    push word [bp+0xa]
    push word [bp+0x8]
    mov al,[bp-0x3]
    push ax
    call word 0x134a:0x1934 ; 130e
    add sp,byte +0x8
    or ax,ax
    jnz .label22
    jmp word .label6
.label22: ; 131d
    mov bx,[GameStatePtr]
    mov si,[bx+0x808]
    mov di,[bx+0x80a]
    mov word [bp-0x16],0x0
    mov ax,[bp-0xa]
    shl ax,byte 0x5
    add ax,[bp-0x8]
    add bx,ax
    cmp byte [bx],0xa
    jz .label23
    jmp word .label24
.label23: ; 1341
    push word [bp-0xa]
    push word [bp-0x8]
    call word 0x13df:0x58 ; 1347
    add sp,byte +0x4
    mov [bp-0x4],ax
    inc ax
    jz .label25
    mov ax,[bp-0x4]
    mov cx,ax
    shl ax,byte 0x2
    add ax,cx
    shl ax,1
    add ax,cx
    mov bx,[GameStatePtr]
    les bx,[bx+0x924]
    add bx,ax
    mov ax,[es:bx+0x5]
    mov [bp-0x6],ax
    mov cx,[es:bx+0x7]
    cmp ax,[bp+0x8]
    jnz .label26
    cmp [bp+0xa],cx
    jnz .label26
    jmp word .label6
.label26: ; 1385
    add ax,[bp+0x8]
    jnz .label25
    add cx,[bp+0xa]
    jnz .label25
    jmp word .label6
.label25: ; 1392
    lea ax,[bp-0x16]
    push ax
    push word 0xff
    push word [bp+0xa]
    push word [bp+0x8]
    push word [bp-0xa]
    push word [bp-0x8]
    push word [bp+0x6]
    call word 0x15b4:0xdae ; 13a8
    add sp,byte +0xe
    mov [bp-0x4],ax
    mov bx,[GameStatePtr]
    cmp word [bx+0x816],byte +0x0
    jz .label27
    jmp word .label28
.label27: ; 13c1
    or ax,ax
    jnz .label24
    jmp word .label6
.label24: ; 13c8
    push byte +0x1
    push byte +0x1
    lea ax,[bp-0xe]
    push ax
    push word [bp+0xa]
    push word [bp+0x8]
    push word [bp-0xa]
    push word [bp-0x8]
    call word 0x1473:0x1a56 ; 13dc
    add sp,byte +0xe
    mov [bp-0x10],ax
    or ax,ax
    jnz .label29
    jmp word .label6
.label29: ; 13ee
    mov bx,[GameStatePtr]
    mov ax,[bx+0x80a]
    shl ax,byte 0x5
    add ax,[bx+0x808]
    add bx,ax
    mov al,[bx+0x400]
    mov [bx],al
    mov bx,[GameStatePtr]
    mov ax,[bx+0x80a]
    shl ax,byte 0x5
    add ax,[bx+0x808]
    add bx,ax
    mov byte [bx+0x400],0x0
    mov bx,[GameStatePtr]
    mov ax,[bx+0x80a]
    shl ax,byte 0x5
    add ax,[bx+0x808]
    add bx,ax
    cmp byte [bx],0x2f
    jnz .label30
    push byte +0x8
    call word 0x154f:0xcbe ; 1433
    add sp,byte +0x2
.label30: ; 143b
    mov ax,[bp-0xe]
    dec ax
    jz .label31
    dec ax
    jz .label32
    dec ax
    dec ax
    jnz .label33
    jmp word .label34
.label33: ; 144b
    dec ax
    jnz .label35
    jmp word .label36
.label35: ; 1451
    dec ax
    jnz .label37
    jmp word .label38
.label37: ; 1457
    dec ax
    jnz .label39
    jmp word .label40
.label39: ; 145d
    jmp word .label41
.label31: ; 1460
    mov bx,[bp-0xa]
    shl bx,byte 0x5
    add bx,[bp-0x8]
    add bx,[GameStatePtr]
    mov al,[bx]
    push ax
    call word 0x151c:0x1770 ; 1470
    add sp,byte +0x2
    jmp word .label41
    nop
.label32: ; 147c
    mov bx,[bp-0xa]
    shl bx,byte 0x5
    add bx,[bp-0x8]
    add bx,[GameStatePtr]
    mov al,[bx]
    sub ah,ah
    cmp ax,0x2a
    jz .label42
    ja .label43
    sub al,0x3
    jz .label44
    dec al
    jz .label45
.label43: ; 149c
    mov bx,[GameStatePtr]
    mov word [bx+0x816],0x5
    jmp short .label28
.label44: ; 14a8
    mov bx,[GameStatePtr]
    mov word [bx+0x816],0x2
    jmp short .label28
.label45: ; 14b4
    mov bx,[GameStatePtr]
    mov word [bx+0x816],0x1
    jmp short .label28
.label42: ; 14c0
    mov bx,[GameStatePtr]
    mov word [bx+0x816],0x3
.label28: ; 14ca
    mov ax,[bp-0x8]
    mov bx,[GameStatePtr]
    mov [bx+0x808],ax
    mov ax,[bp-0xa]
    mov bx,[GameStatePtr]
    mov [bx+0x80a],ax
    mov bx,[bp-0xa]
    shl bx,byte 0x5
    add bx,[bp-0x8]
    add bx,[GameStatePtr]
    mov al,[bx]
    mov [bx+0x400],al
    mov bx,[bp-0xa]
    shl bx,byte 0x5
    add bx,[bp-0x8]
    add bx,[GameStatePtr]
    mov [bp-0x18],bx
    mov al,[bx+0x400]
    sub ah,ah
    sub ax,0x3
    jz .label46
    dec ax
    jz .label47
    push word [bp+0xa]
    push word [bp+0x8]
    push byte +0x6c
    call word 0x1611:0x486 ; 1519
    add sp,byte +0x6
    mov bx,[bp-0xa]
    shl bx,byte 0x5
    add bx,[bp-0x8]
    add bx,[GameStatePtr]
    mov [bx],al
    jmp short .label48
.label46: ; 1532
    mov byte [bx],0x33
    jmp short .label48
    nop
.label47: ; 1538
    mov byte [bx],0x34
.label48: ; 153b
    push di
    push si
    mov bx,[GameStatePtr]
    push word [bx+0x80a]
    push word [bx+0x808]
    push word [bp+0x6]
    call word 0x1572:0x56e ; 154c
    add sp,byte +0xa
    push byte +0x1
    push byte +0x2
    call word 0xf4b:0x56c ; 1558
    add sp,byte +0x4
    mov bx,[GameStatePtr]
    push word [bx+0x80a]
    push word [bx+0x808]
    push word [bp+0x6]
    call word 0x157a:0x1ca ; 156f
    add sp,byte +0x6
    call word 0x1024:0xb9a ; 1577
    push byte +0x1
    mov bx,[GameStatePtr]
    push word [bx+0x800]
    call word 0xd6a:0x356 ; 1586
    add sp,byte +0x4
    jmp word .returnZero
    nop
.label36: ; 1592
    push word 0xc6c
    push byte +0x0 ; chip
    lea ax,[bp+0xa]
    push ax
    lea ax,[bp+0x8]
    push ax
    push word [bp-0xa]
    push word [bp-0x8]
    mov bx,[GameStatePtr]
    push word [bx+0x80a]
    push word [bx+0x808]
    call word 0xee9:0x636 ; 15b1
    add sp,byte +0x10
    mov bx,[GameStatePtr]
    cmp word [bx+0x80e],byte +0x0
    jnz .label49
    jmp word .label34
.label49: ; 15c7
    mov al,[bp-0xb]
    mov bx,[bp-0xa]
    shl bx,byte 0x5
    add bx,[bp-0x8]
    add bx,[GameStatePtr]
    cmp [bx],al
    jnz .label50
    jmp word .label34
.label50: ; 15de
    mov bx,[GameStatePtr]
    mov ax,[bx+0x812]
    add ax,[bp+0x8]
    jnz .label34
    mov ax,[bx+0x814]
    add ax,[bp+0xa]
    jnz .label34
    mov word [bx+0xa40],0x1
    mov bx,[GameStatePtr]
    mov word [bx+0x80e],0x0
    jmp short .label34
.label38: ; 1606
    push di
    push si
    push word [bp-0xa]
    push word [bp-0x8]
    call word 0xf2f:0x21aa ; 160e
    add sp,byte +0x8
    jmp short .label34
.label40: ; 1618
    push byte +0x0
    push word [bp+0xa]
    push word [bp+0x8]
    lea ax,[bp-0xa]
    push ax
    lea cx,[bp-0x8]
    push cx
    push word [bp+0x6]
    call word 0x16b0:0x276a ; 162b
    add sp,byte +0xc
    push word 0xc6c
    push byte +0x0 ; chip
    lea ax,[bp+0xa]
    push ax
    lea ax,[bp+0x8]
    push ax
    push word [bp-0xa]
    push word [bp-0x8]
    mov bx,[GameStatePtr]
    push word [bx+0x80a]
    push word [bx+0x808]
    call word 0x183c:0x636 ; 1652
    add sp,byte +0x10
    mov word [bp-0xe],0x5
.label34: ; 165f
    mov bx,[bp-0xa]
    shl bx,byte 0x5
    add bx,[bp-0x8]
    add bx,[GameStatePtr]
    mov al,[bx]
    mov [bx+0x400],al
.label41: ; 1672
    mov ax,[bp-0x8]
    mov bx,[GameStatePtr]
    mov [bx+0x808],ax
    mov ax,[bp-0xa]
    mov bx,[GameStatePtr]
    mov [bx+0x80a],ax
    push word [bp+0xa]
    push word [bp+0x8]
    mov bx,[bp-0xa]
    shl bx,byte 0x5
    add bx,[bp-0x8]
    add bx,[GameStatePtr]
    mov [bp-0x1a],bx
    cmp byte [bx+0x400],0x3
    jnz .label51
    mov al,0x3c
    jmp short .label52
    nop
.label51: ; 16aa
    mov al,0x6c
.label52: ; 16ac
    push ax
    call word 0x172a:0x486 ; 16ad
    add sp,byte +0x6
    mov bx,[bp-0x1a]
    mov [bx],al
    push di
    push si
    mov bx,[GameStatePtr]
    push word [bx+0x80a]
    push word [bx+0x808]
    push word [bp+0x6]
    call word 0x16e5:0x56e ; 16cb
    add sp,byte +0xa
    mov bx,[GameStatePtr]
    push word [bx+0x80a]
    push word [bx+0x808]
    push word [bp+0x6]
    call word 0x176f:0x1ca ; 16e2
    add sp,byte +0x6
    cmp word [bp-0xe],byte +0x4
    jz .label53
    jmp word .label54
.label53: ; 16f3
    mov bx,[GameStatePtr]
    mov si,[bx+0x80a]
    shl si,byte 0x5
    add si,[bx+0x808]
    mov al,[bx+si+0x400]
    sub ah,ah
    cmp ax,0x2f
    jz .label55
    ja .label54
    sub al,0x23
    jz .label56
    dec al
    jz .label57
    sub al,0x3
    jz .label58
    dec al
    jz .label59
    jmp short .label54
    nop
    nop
    nop
.label56: ; 1724
    push word [bp+0x6]
    call word 0x173e:0x1fac ; 1727
    jmp short .label60
.label57: ; 172e
    push byte +0x1
    push word [bx+0x80a]
    push word [bx+0x808]
    push word [bp+0x6]
    call word 0x1753:0x2442 ; 173b
    add sp,byte +0x8
    jmp short .label54
    nop
.label58: ; 1746
    push byte +0x1
    push word [bx+0x80a]
    push word [bx+0x808]
    call word 0x1762:0x211a ; 1750
    add sp,byte +0x6
    jmp short .label54
.label59: ; 175a
    push byte +0x1
    push word [bp+0x6]
    call word 0x17a6:0x1e6a ; 175f
    add sp,byte +0x4
    jmp short .label54
    nop
.label55: ; 176a
    push byte +0x8
    call word 0x17ef:0xcbe ; 176c
.label60: ; 1771
    add sp,byte +0x2
.label54: ; 1774
    cmp word [bp-0x16],byte +0x0
    jz .label61
    mov si,[bp-0x12]
    shl si,byte 0x5
    add si,[bp-0x14]
    mov bx,[GameStatePtr]
    mov al,[bx+si+0x400]
    sub ah,ah
    sub ax,0x23
    jz .label62
    dec ax
    jz .label63
    sub ax,0x3
    jz .label64
    dec ax
    jz .label65
    jmp short .label61
    nop
.label62: ; 17a0
    push word [bp+0x6]
    call word 0x17bc:0x1fac ; 17a3
    add sp,byte +0x2
    jmp short .label61
    nop
.label63: ; 17ae
    push byte +0x0
    push word [bp-0x12]
    push word [bp-0x14]
    push word [bp+0x6]
    call word 0x17cf:0x2442 ; 17b9
    add sp,byte +0x8
    jmp short .label61
    nop
.label64: ; 17c4
    push byte +0x0
    push word [bp-0x12]
    push word [bp-0x14]
    call word 0x17de:0x211a ; 17cc
    add sp,byte +0x6
    jmp short .label61
.label65: ; 17d6
    push byte +0x0
    push word [bp+0x6]
    call word 0x1894:0x1e6a ; 17db
    add sp,byte +0x4
.label61: ; 17e3
    cmp word [0x20],byte +0x0
    jz .label66
    push byte +0x6
    call word 0x18b0:0xcbe ; 17ec
    add sp,byte +0x2
.label66: ; 17f4
    mov bx,[GameStatePtr]
    cmp word [bx+0x80c],byte +0x0
    jz .label67
    cmp word [bp-0xe],byte +0x5
    jz .label67
    mov word [bx+0x80c],0x0
.label67: ; 180b
    mov bx,[GameStatePtr]
    inc word [bx+0xa34]
    mov bx,[GameStatePtr]
    mov si,[bx+0x80a]
    shl si,byte 0x5
    add si,[bx+0x808]
    cmp byte [bx+si+0x400],0x15
    jnz .label68
    push byte +0x1
    push byte +0x3
    call word 0x185b:0x56c ; 182d
    add sp,byte +0x4
    push word [0x12]
    call word 0x13ab:0xcca ; 1839
    add sp,byte +0x2
    mov ax,0x1
    jmp word .end
    nop
.label68: ; 1848
    mov si,[bp-0x10]
    or si,si
    jnz .label69
    cmp [bp+0xe],si
    jz .label69
    push byte +0x1
    push byte +0x5
    call word 0x18c8:0x56c ; 1858
    add sp,byte +0x4
.label69: ; 1860
    mov ax,si
    jmp short .end

.label6: ; 1864
    ; Out of bounds

    ; If chip is on water, change to swimming chip.
    push word [ydir]
    push word [xdir]
    mov bx,[GameStatePtr]
    mov bx,[bx+ChipY]
    shl bx,byte 0x5
    mov si,[GameStatePtr]
    add bx,[si+ChipX]
    add bx,si
    mov [bp-0x1c],bx
    cmp byte [bx+Lower],Water
    jnz .label70
    mov al,SwimN
    jmp short .label71
    nop
.label70: ; 188e
    mov al,ChipN
.label71: ; 1890
    push ax
    call word 0x1956:0x486 ; 1891 SetTileDir
    add sp,byte +0x6

    mov bx,[bp-0x1c]
    mov [bx],al
    mov bx,[GameStatePtr]
    push word [bx+ChipY]
    push word [bx+ChipX]
    push word [hDC]
    call word 0x1436:0x1ca ; 18ad
    add sp,byte +0x6
    cmp word [bp-0x10],byte +0x0
    jnz .label72
    cmp word [bp+0xe],byte +0x0
    jz .label72
    push byte +0x1
    push byte +0x5
    call word 0x155b:0x56c ; 18c5
    add sp,byte +0x4
.label72: ; 18cd
    mov ax,[bp-0x10]
.end: ; 18d0
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 18da

; Move monster
; Called repeatedly in the big freaking monster loop.
; Parameters:
;   HDC
;   x pos
;   y pos
;   x dir
;   y dir
;   tile
; Return value:
;   0 - blocked
;   1 - success
;   2 - dead
Eight:
;warning: no jump target 0
;warning: no jump target 1a0c
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x1a
    push di
    push si

    %define xptr (bp+0x8)
    %define yptr (bp+0xa)
    %define xdirptr (bp+0xc)
    %define ydirptr (bp+0xe)
    %define tile (bp+0x10)

    %define ydir (bp-0x6)
    %define xdir (bp-0xa)
    %define y (bp-0x10)
    %define x (bp-0x12)

    ; y = *yptr + *yptrdir
    ; x = *xptr + *xptrdir
    mov bx,[xptr]
    mov di,[bx]
    mov si,[yptr]
    mov si,[si]
    mov bx,[xdirptr]
    mov ax,[bx]
    mov [bp-0xa],ax
    mov bx,[ydirptr]
    mov cx,[bx]
    mov [bp-0x6],cx
    mov bx,[xptr]
    add ax,[bx]
    mov [bp-0x10],ax
    mov ax,cx
    add ax,si
    mov [bp-0x12],ax
    mov word [bp-0x16],0x0
    cmp word [bp-0x10],byte +0x0
    jnl .label0
    jmp word .label1
.label0: ; 1920
    or ax,ax
    jnl .label2
    jmp word .label1
.label2: ; 1927
    cmp word [bp-0x10],byte +0x20
    jl .label3
    jmp word .label1
.label3: ; 1930
    cmp ax,0x20
    jl .label4
    jmp word .label1
.label4: ; 1938
    mov bx,si
    shl bx,byte 0x5
    add bx,di
    mov [bp-0x18],bx
    add bx,[GameStatePtr]
    mov al,[bx+Lower]
    mov [bp-0x3],al
    cmp al,Trap
    jnz .checkPanelWalls
    ; It's a trap!
    push si
    push di
    call word 0x19a3:0x22be ; 1953 FindTrap
    add sp,byte +0x4
    mov [bp-0x8],ax
    or ax,ax
    jnl .label6
    jmp word .label1
.label6: ; 1965
    mov cx,ax
    shl ax,byte 0x2
    add ax,cx
    shl ax,1
    mov bx,[GameStatePtr]
    les bx,[bx+TrapListPtr]
    add bx,ax
    ; If trap is closed (flag==1), break.
    cmp word [es:bx+Connection.flag],byte +0x1
    jnz .checkPanelWalls
    jmp word .label1

.checkPanelWalls: ; 1982
    ; It's not a trap!

    ; Panel walls!
    cmp byte [bp-0x3],PanelN
    jc .label7
    cmp byte [bp-0x3],PanelE
    jna .label8
.label7: ; 198e
    cmp byte [bp-0x3],PanelSE
    jnz .label9
.label8: ; 1994
    push byte +0x0
    push word [bp-0x6]
    push word [bp-0xa]
    mov al,[bp-0x3]
    push ax
    call word 0x19d2:0x1934 ; 19a0 3:0x1934
    add sp,byte +0x8
    or ax,ax
    jnz .label9
    jmp word .label1
.label9: ; 19af
    mov bx,[bp-0x18]
    add bx,[GameStatePtr]
    mov al,[bx]
    mov [bp-0x3],al
    lea ax,[bp-0x14]
    push ax
    push word [bp-0x6]
    push word [bp-0xa]
    push word [bp-0x12]
    push word [bp-0x10]
    mov al,[bp-0x3]
    push ax
    call word 0x12c7:0x1d4a ; 19cf 3:0x1d4a
    add sp,byte +0xc
    or ax,ax
    jnz .label10
    jmp word .label1
.label10: ; 19de
    mov ax,[bp-0x14]
    cmp ax,0x7
    ja .label11
    shl ax,1
    xchg ax,bx
    jmp word [cs:bx+.jumpTable]

.jumpTable:
    dw .jump1
    dw .jump1
    dw .jump2
    dw .jump3
    dw .jump4
    dw .jump5
    dw .jump6
    dw .jump7

; 19fe
.jump4:
    lea ax,[tile]
    push ax
    push byte +0x2 ; monster
    push word [bp+0xe]
    push word [bp+0xc]
.label12: ; 1a0a
    push word [bp-0x12]
    push word [bp-0x10]
    push si
    push di
    call word 0x1ac4:0x636 ; 1a12 7:0x636
    add sp,byte +0x10
    jmp short .label13

; 1a1c
.jump5:
    push byte +0x1
    push byte +0xb
    call word 0x1830:0x56c ; 1a20 8:0x56c
    add sp,byte +0x4
    mov byte [tile],Floor
; 1a2c
.jump2:
    mov word [bp-0x16],0x1

.jump3:
.label11: ; 1a31
    cmp word [bp-0x14],byte +0x4
    jz .label14
    mov bx,[GameStatePtr]
    cmp word [bx+0x91e],byte +0x0
    jz .label14
    push byte +0x2
    push si
    push di
    mov bx,[bp-0x18]
    add bx,[GameStatePtr]
    mov al,[bx]
    push ax
    call word 0x1a77:0x12be ; 1a50 DeleteSlipperAt
    add sp,byte +0x8
.label14: ; 1a58
    cmp word [bp-0x14],byte +0x2
    jnz .label15
    jmp word .label16
.label15: ; 1a61
    cmp byte [tile],0xff
    jz .label17
    mov al,[tile]
    jmp short .label18

; 1a6c
.jump6:
    push si
    push di
    push word [bp-0x12]
    push word [bp-0x10]
    call word 0x1aa8:0x21aa ; 1a74 3:0x21aa
    add sp,byte +0x8

; 1a7c
.jump1:
.label13:
    mov bx,[bp-0x12]
    shl bx,byte 0x5
    add bx,[bp-0x10]
    add bx,[GameStatePtr]
    mov al,[bx]
    mov [bx+Lower],al
    jmp short .label11
    nop

; 1a92
.jump7:
    push byte +0x2
    push word [bp-0x6]
    push word [bp-0xa]
    lea ax,[bp-0x12]
    push ax
    lea cx,[bp-0x10]
    push cx
    push word [bp+0x6]
    call word 0x1b76:0x276a ; 1aa5 3:0x276a
    add sp,byte +0xc
    lea ax,[tile]
    push ax
    push byte +0x2 ; monster
    push word [bp+0xe]
    push word [bp+0xc]
    push word [bp-0x12]
    push word [bp-0x10]
    push si
    push di
    call word 0x1655:0x636 ; 1ac1 7:0x636
    add sp,byte +0x10
    mov bx,[bp-0x12]
    shl bx,byte 0x5
    add bx,[bp-0x10]
    add bx,[GameStatePtr]
    mov al,[bx]
    mov [bx+0x400],al
    mov word [bp-0x14],0x4
    jmp word .label11
.label17: ; 1ae4
    mov al,[bp-0x3]
.label18: ; 1ae7
    mov bx,[bp-0x12]
    shl bx,byte 0x5
    add bx,[bp-0x10]
    add bx,[GameStatePtr]
    mov [bx],al
    push word [bp-0x12]
    push word [bp-0x10]
    push word [bp+0x6]
    call word 0x1b36:0x1ca ; 1aff 2:0x1ca
    add sp,byte +0x6
.label16: ; 1b07
    mov bx,[bp-0x18]
    add bx,[GameStatePtr]
    cmp byte [bx+Lower],CloneMachine
    jz .label19
    mov bx,[bp-0x18]
    add bx,[GameStatePtr]
    mov al,[bx+Lower]
    mov [bx],al
    mov bx,[bp-0x18]
    add bx,[GameStatePtr]
    mov byte [bx+Lower],0x0
.label19: ; 1b2e
    push si
    push di
    push word [bp+0x6]
    call word 0x16ce:0x1ca ; 1b33 2:0x1ca
    add sp,byte +0x6
    cmp word [bp-0x14],byte +0x1
    jz .label20
    jmp word .label21
.label20: ; 1b44
    mov [bp-0xe],di
    mov [bp-0xc],si
    mov si,[bp-0x12]
    shl si,byte 0x5
    add si,[bp-0x10]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    sub ah,ah
    sub ax,0x23
    jz .label22
    dec ax
    jz .label23
    sub ax,0x3
    jz .label24
    dec ax
    jz .label25
    jmp word .label21
.label22: ; 1b70
    push word [bp+0x6]
    call word 0x1b8c:0x1fac ; 1b73 3:0x1fac
    add sp,byte +0x2
    jmp word .label21
.label23: ; 1b7e
    push byte +0x0
    push word [bp-0x12]
    push word [bp-0x10]
    push word [bp+0x6]
    call word 0x1b9f:0x2442 ; 1b89 3:0x2442
    add sp,byte +0x8
    jmp word .label21
.label24: ; 1b94
    push byte +0x0
    push word [bp-0x12]
    push word [bp-0x10]
    call word 0x1bb4:0x211a ; 1b9c 3:0x211a
    add sp,byte +0x6
    jmp word .label21
    nop
.label25: ; 1ba8
    mov di,[bp+0xc]
    push word [bp-0xc]
    push word [bp-0xe]
    call word 0x1c1b:0x0 ; 1bb1 FindMonster
    add sp,byte +0x4
    mov si,ax
    cmp si,byte -0x1
    jz .notFound
    mov di,[bp+0xc]
    mov ax,[bp-0x10]
    mov cx,si
    shl cx,byte 0x2
    add cx,si
    shl cx,1
    add cx,si
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,cx
    mov [es:bx+0x1],ax
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,cx
    mov ax,[bp-0x12]
    mov [es:bx+0x3],ax
    mov ax,[di]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,cx
    mov [es:bx+0x5],ax
    mov bx,[bp+0xe]
    mov ax,[bx]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,cx
    mov [es:bx+0x7],ax
.notFound: ; 1c13
    push byte +0x0
    push word [bp+0x6]
    call word 0x1cc4:0x1e6a ; 1c18 3:0x1e6a
    add sp,byte +0x4
    cmp si,byte -0x1
    jz .label21
    mov bx,si
    mov ax,si
    shl bx,byte 0x2
    add bx,ax
    shl bx,1
    add bx,ax
    mov si,[GameStatePtr]
    les si,[si+MonsterListPtr]
    mov ax,[es:bx+si+0x5]
    mov [di],ax
    mov si,[GameStatePtr]
    mov ax,bx
    les bx,[si+MonsterListPtr]
    mov si,ax
    mov ax,[es:bx+si+0x7]
    mov bx,[bp+0xe]
    mov [bx],ax
.label21: ; 1c55
    cmp word [bp-0x16],byte +0x0
    jnz .label27
    mov si,[bp-0x12]
    shl si,byte 0x5
    add si,[bp-0x10]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [bp-0x1a],al
    cmp al,0x6c
    jc .label28
    cmp al,0x6f
    jna .label29
.label28: ; 1c77
    cmp byte [bp-0x1a],0x3c
    jc .label27
    cmp byte [bp-0x1a],0x3f
    ja .label27
.label29: ; 1c83
    mov word [bx+Autopsy],0x5
.label27: ; 1c89
    mov ax,[bp-0x10]
    mov bx,[bp+0x8]
    mov [bx],ax
    mov ax,[bp-0x12]
    mov bx,[bp+0xa]
    mov [bx],ax
    cmp word [bp-0x16],byte +0x1
    sbb ax,ax
    add ax,0x2
    jmp short .return
.label1: ; 1ca4
    mov bx,[GameStatePtr]
    cmp word [bx+SlipListLen],byte +0x0
    jz .returnZero
    push byte +0x2
    push si         ; y
    push di         ; x
    mov bx,si
    shl bx,byte 0x5
    add bx,di
    mov si,[GameStatePtr]
    mov al,[bx+si+Upper]
    push ax         ; tile
    call word 0x162e:0x12be ; 1cc1 3:0x12be
    add sp,byte +0x8
.returnZero: ; 1cc9
    xor ax,ax
.return: ; 1ccb
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 1cd3

; vim: syntax=nasm

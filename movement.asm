SEGMENT CODE ; 7

%include "constants.asm"
%include "structs.asm"
%include "variables.asm"

; data

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

    ; args
    ; +6 tick

    %define hDC (bp-0xa)
    %define xdir (bp-0x6)
    %define ydir (bp-0x4)

    ; get the device context
    push word [0x12]    ; hWnd
    call word 0x0:0xffff ; 13 KERNEL.GetDC
    mov [hDC],ax

    ; check whether we're on an even tick or an odd tick
    test byte [bp+0x6],0x1
    jz .evenTick
    jmp word .oddTick

.evenTick: ; 24
    mov bx,[GameStatePtr]
    ; if chip is sliding, don't do anything
    cmp word [bx+IsSliding],byte +0x0
    jz .label2
    jmp word .monsterloop

    ; If 0xa40 is set, just clear it
.label2: ; 32
    cmp word [bx+0xa40],byte +0x0 ; no mouse target
    jz .label4
.label10: ; 39
    mov bx,[GameStatePtr]
    mov word [bx+0xa40],0x0
    jmp word .monsterloop

.label4: ; 46
    ; Use a buffered keystroke if we have one (and if chip isn't dead)
    cmp word [bx+IsBuffered],byte +0x0
    jz .label5
    cmp word [bx+Autopsy],byte NotDeadYet
    jnz .label6
    push byte +0x1
    push byte +0x1
    push word [bx+BufferedY]
    push word [bx+BufferedX]
    push ax
    call word 0x11e:0x1184 ; 61 7:1184 MoveChip
    add sp,byte +0xa
.label6: ; 69
    ; ...and clear the keystroke regardless
    mov bx,[GameStatePtr]
    mov word [bx+IsBuffered],0x0
    mov bx,[GameStatePtr]
    mov word [bx+0xa38],0x0
    jmp word .monsterloop

.label5: ; 80
    ; we don't have a buffered keystroke
    ; But we might have a mouse target...
    cmp word [bx+0xa38],byte +0x0
    jnz .label7
    jmp word .label8
.label7: ; 8a
    ; If we've reached the target, clear 0xa38 and 0xa40 and get on with it
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
    ; jmp .monsterloop

.label9: ; aa
    ; If we /haven't/ reached the target yet, make a step towards it
    ; First, figure out the proper direction
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
    ; If chip is dead, forget all that; go do something else
    cmp word [bx+Autopsy],byte +0x0
    jz .label16
    jmp word .dead

.label16: ; f8
    ; Actually move chip
    ; last argument = (xdist == 0 || ydist == 0)
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
    call word 0x19d:0x1184 ; 11b 7:1184 MoveChip
    add sp,byte +0xa
    or ax,ax
    ; If we succeeded, or chip died, go deal with it
    jz .label20
    jmp word .dead
.label20: ; 12a
    mov bx,[GameStatePtr]
    cmp [bx+0xa38],ax ; 0
    jz .dead
    ; Otherwise we must have been blocked
    ; Try the other direction
    ; abs(di)
    mov ax,di
    cwd
    xor ax,dx
    sub ax,dx
    mov cx,ax
    ; abs(si)
    mov ax,si
    cwd
    xor ax,dx
    sub ax,dx
    cmp ax,cx
    jnl .label21
    jmp word .label22
.label21: ; 14b
    ; if xdist > 0, dir = (1,0)
    or di,di
    jng .label23
    mov word [xdir],1
.setYdirTo0: ; 154
    mov word [ydir],0
    jmp short .label24
    nop
.label23: ; 15c
    ; if xdist < 0, dir = (-1,0)
    or di,di
    jnl .label25
    mov word [xdir],-1
    jmp short .setYdirTo0
    nop
.label25: ; 168
    ; if xdist == 0, dir = (0,0)
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
    call word 0x2aa:0x1184 ; 19a 7:1184 MoveChip
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
    ; mov [bx+0xa40], 0
    ; jmp .monsterloop
.label30: ; 1c8
    mov ax,[bx+MouseTargetY]
    cmp [bx+ChipY],ax
    jz .label29
    jmp word .label10
    ; mov [bx+0xa40], 0
    ; jmp .monsterloop
.label29: ; 1d5
    mov word [bx+0xa38],0x0
    jmp word .label10
    ; mov [bx+0xa40], 0
    ; jmp .monsterloop

.label22: ; 1de
    ; the x distance was greater than the y distance
    ; if ydist > 0, dir = (0,1)
    or si,si
    jng .label31
    mov word [xdir],0
    mov word [ydir],1
    jmp short .label24
.label31: ; 1ee
    ; if ydist == 0, dir = (0,0)
    or si,si
    jl .label32
    jmp word .label25
.label32: ; 1f5
    ; if ydist < 0, dir = (0,-1)
    mov word [xdir],0
    mov word [ydir],-1
    jmp word .label24
    ; go move chip

.label8: ; 202
    ; We don't have a mouse target
    ; If chip is idle for 2 or more even ticks, face south
    mov ax,[bx+0xa3e]
    inc word [bx+0xa3e]
    cmp ax,0x2
    jl .monsterloop
    mov bx,[GameStatePtr]
    mov ax,[bx+ChipY]
    shl ax,byte 0x5
    add ax,[bx+ChipX]
    add bx,ax
    mov al,[bx+Upper]
    mov [bp-0x3],al
    cmp al,ChipS
    jz .monsterloop
    cmp al,SwimS
    jz .monsterloop
    cmp byte [bx+Lower],Water
    jnz .label33
    mov al,SwimS
    jmp short .label34
.label33: ; 238
    mov al,ChipS
.label34: ; 23a
    mov [bx],al
    mov bx,[GameStatePtr]
    push word [bx+ChipY]
    push word [bx+ChipX]
    push word [hDC]
    call word 0xffff:0x1ca ; 24b 2:1ca
    add sp,byte +0x6

.monsterloop: ; 253
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
    ; We're on an odd tick
    ; Not much to do
    ; If we have a buffered keystroke and we're not sliding and 0xa40 isn't set,
    ; then move chip if he isn't dead.
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
    call word 0x2ed:0x1184 ; 2a7 7:1184 MoveChip
    add sp,byte +0xa
.label36: ; 2af
    ; ...if chip /is/ dead, clear the keystroke and mouse target instead.
    mov bx,[GameStatePtr]
    mov word [bx+IsBuffered],0x0
    mov bx,[GameStatePtr]
    mov word [bx+0xa38],0x0

.label35: ; 2c3
    ; Sliding!
    mov bx,[GameStatePtr]
    cmp word [bx+IsSliding],byte +0x0
    jnz .label37
    jmp word .sliploop
.label37: ; 2d1
    ; First off, clear the idle timer
    mov word [bx+0xa3e],0x0
    ; and then move chip in the direction he's sliding
    push byte +0x1
    push byte +0x0
    mov bx,[GameStatePtr]
    push word [bx+SlideY]
    push word [bx+SlideX]
    push word [hDC]
    call word 0x33b:0x1184 ; 2ea 7:1184 MoveChip
    add sp,byte +0xa
    or ax,ax
    jz .label39
    jmp word .label40
.label39: ; 2f9
    mov bx,[GameStatePtr]
    cmp [bx+IsSliding],ax ; == 0
    jnz .label41
    jmp word .label40
.label41: ; 306
    neg word [bx+SlideX]
    mov si,[GameStatePtr]
    neg word [si+SlideY]
    push word 0xc6c
    push ax ; 0
    mov ax,[GameStatePtr]
    add ax,SlideY
    push ax
    mov ax,[GameStatePtr]
    add ax,SlideX
    push ax
    mov bx,[GameStatePtr]
    push word [bx+ChipY]
    push word [bx+ChipX]
    push word [bx+ChipY]
    push word [bx+ChipX]
    call word 0x356:0x636 ; 338 7:636 slide movement
    add sp,byte +0x10
    push byte +0x1
    push byte +0x0
    mov bx,[GameStatePtr]
    push word [bx+SlideY]
    push word [bx+SlideX]
    push word [hDC]
    call word 0x398:0x1184 ; 353 7:1184 MoveChip
    add sp,byte +0xa
    or ax,ax
    jnz .label40
    mov si,[GameStatePtr]
    neg word [si+SlideX]
    mov si,[GameStatePtr]
    neg word [si+SlideY]
    push word 0xc6c
    push ax ; 0
    mov ax,[GameStatePtr]
    add ax,SlideY
    push ax
    mov ax,[GameStatePtr]
    add ax,SlideX
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
    jmp word .sliploop
    nop
.label42: ; 3b2
    cmp word [bx+IsBuffered],byte +0x0
    jz .label43
    cmp word [bx+Autopsy],byte +0x0
    jnz .label44
    cmp word [bx+IsSliding],byte +0x0
    jz .label45
    mov ax,[bx+SlideX]
    cmp [bx+BufferedX],ax
    jnz .label45
    mov ax,[bx+SlideY]
    cmp [bx+BufferedY],ax
    jz .label44
.label45: ; 3db
    push byte +0x1
    push byte +0x1
    push word [bx+BufferedY]
    push word [bx+BufferedX]
    push word [hDC]
    call word 0x4b8:0x1184 ; 3ea 7:1184 MoveChip
    add sp,byte +0xa
.label44: ; 3f2
    mov bx,[GameStatePtr]
    mov word [bx+IsBuffered],0x0
    jmp word .label46
    nop
.label43: ; 400
    cmp word [bx+0xa38],byte +0x0
    jnz .label47
    jmp word .sliploop
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
    mov word [xdir],0
    mov word [ydir],1
    jmp short .label51
    nop
.label50: ; 44a
    mov word [xdir],0
    mov word [ydir],-1
    jmp short .label51
.label49: ; 456
    or di,di
    jng .label52
    mov word [xdir],1
    jmp short .label53
    nop
.label52: ; 462
    mov word [xdir],-1
.label53: ; 467
    mov word [ydir],0
.label51: ; 46c
    cmp word [bx+Autopsy],byte +0x0
    jz .label54
    jmp word .label55
.label54: ; 476
    cmp word [bx+IsSliding],byte +0x0
    jz .label56
    mov ax,[xdir]
    cmp [bx+SlideX],ax
    jnz .label56
    mov ax,[ydir]
    cmp [bx+SlideY],ax
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
    call word 0x56a:0x1184 ; 4b5 7:1184 MoveChip
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
    cmp [bx+SlideX],ax
    jnz .label67
    mov ax,[ydir]
    cmp [bx+SlideY],ax
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
    call word 0x64:0x1184 ; 567 7:1184 MoveChip
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
    jnz .sliploop
    mov ax,[bx+MouseTargetY]
    cmp [bx+ChipY],ax
    jnz .sliploop
.label46: ; 59c
    mov bx,[GameStatePtr]
    mov word [bx+0xa38],0x0

.sliploop: ; 5a6
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
    ; -c xdir
    ; -e ydir

    ; fetch *xdirptr and *ydirptr
    mov bx,[bp+0xe]
    mov ax,[bx]
    mov [bp-0xc],ax
    mov bx,[bp+0x10]
    mov ax,[bx]
    mov [bp-0xe],ax

    ; check the flag
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

    ; set xdir and ydir pointers
    ; to slidex and slidey if chip
    ; or sliplist xdir and ydir if monster

    ; flag == 0
.label0: ; 66c
    mov bx,[GameStatePtr]
    mov word [bx+0x80c],0x1 ; issliding?
    mov ax,[GameStatePtr]
    add ax,SlideX ; chip slide x?
    mov si,ax
    mov [bp-0x4],ds
    mov ax,[GameStatePtr]
    add ax,SlideY ; chip slide y?
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
    mov al,[bx+si+Upper]
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
    jmp word .return
.label5: ; 6cc
    mov ax,[bp-0x12]
    mov dx,[bp-0x10]
    add ax,Monster.xdir
    mov si,ax
    mov [bp-0x4],dx
    mov ax,[bp-0x12]
    add ax,Monster.ydir
    mov di,ax
    mov [bp-0x8],dx

; get the tile
; XXX when would x0 != x1?
.label3: ; 6e5
    mov ax,[bp+0x6]
    cmp [bp+0xa],ax
    jne .label7
    mov ax,[bp+0x8]
    cmp [bp+0xc],ax
    jne .label7
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
    mov al,[bx+Upper]

; switch statement
.label8: ; 717
    mov [bp-0x13],al
    cmp al,ChipN
    jb .label9
    cmp al,ChipE
    jna .label10
.label9: ; 722
    cmp byte [bp-0x13],SwimN
    jb .label11
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
    jmp word .forceRandom
.notForceRandom: ; 742
    jna .label14
    jmp word .label15

.label14: ; 747
    cmp al,IceWallNW
    jz .iceWallNW
    jg .label17
    sub al,Ice
    jz .ice
    dec al
    jnz .notForceS
    jmp word .forceS
.notForceS: ; 758
    sub al,ForceN - ForceS
    jnz .notForceN
    jmp word .setSlideNorth
.notForceN: ; 75f
    dec al
    jnz .notForceW
    jmp word .forceE
.notForceW: ; 766
    dec al
    jnz .notForceE
    jmp word .forceW
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
    jz .ice
    sub al,Trap - Teleport
    jz .ice
    jmp word .label15

    ; Ice
.ice: ; 78d
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
    jz .setSlideSouth
.label32: ; 7b0
    cmp word [bp-0xc],byte +0x0
    jnz .label33
    cmp word [bp-0xe],byte -0x1
    jnz .label33
    jmp word .setSlideEast
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
    jz .setSlideWest
.label35: ; 7de
    cmp word [bp-0xc],byte +0x1
    jnz .label33
    cmp word [bp-0xe],byte +0x0
    jnz .label33
    ; Force S
.forceS: ; 7ea
.setSlideSouth:
    mov es,[bp-0x4]
    mov word [es:si],0x0
    mov es,[bp-0x8]
    mov word [es:di],0x1
    jmp short .label15

    ; Ice wall SE
.iceWallSE: ; 7fc
    ; check if we're sliding south
    cmp word [bp-0xc],byte +0x0
    jnz .label36
    cmp word [bp-0xe],byte +0x1
    jnz .label36
.forceW:
.setSlideWest: ; 808
    ; set slide dir to -1,0
    mov es,[bp-0x4]
    mov word [es:si],-1
    jmp short .label37
.label36: ; 812
    ; check if we're sliding west (0,1)
    cmp word [bp-0xc],byte +0x1
    jnz .label33
    cmp word [bp-0xe],byte +0x0
    jnz .label33
.setSlideNorth: ; 81e
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
    jz .setSlideNorth
.label38: ; 83c
    cmp word [bp-0xc],byte +0x0
    jz .label39
    jmp word .label33
.label39: ; 845
    cmp word [bp-0xe],byte +0x1
    jz .setSlideEast
    jmp word .label33
.forceE:
.setSlideEast: ; 84e
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
    jmp word .return
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
.forceRandom: ; 8ae
    push byte +0x4
    call word 0x91e:0x72e ; 8b0 Rand
    add sp,byte +0x2
    or ax,ax
    jnz .label44
    jmp word .setSlideNorth
.label44: ; 8bf
    dec ax
    jnz .label45
    jmp word .setSlideSouth
.label45: ; 8c5
    dec ax
    jnz .label46
    jmp word .setSlideWest
.label46: ; 8cb
    dec ax
    jnz .label47
    jmp word .setSlideEast
.label47: ; 8d1
    jmp short .label15
    nop

.label42: ; 8d4
    mov bx,[bp+0x8]
    shl bx,byte 0x5
    add bx,[bp+0x6]
    mov si,[GameStatePtr]
    mov al,[bx+si+Upper]
.label43: ; 8e3
    les bx,[bp-0x12]
    mov [es:bx+Monster.tile],al
    mov ax,[bp+0xa]
    les bx,[bp-0x12]
    mov [es:bx+Monster.x],ax
    mov ax,[bp+0xc]
    mov [es:bx+Monster.y],ax
    cmp word [bp+0x12],byte +0x2
    jnz .label48
    mov ax,0x1
    jmp short .label49
    nop
.label48: ; 906
    xor ax,ax
.label49: ; 908
    les bx,[bp-0x12]
    mov [es:bx+Monster.slipping],ax
    cmp word [bp+0x12],byte +0x2
    jnz .return
    push word [bp+0x8]
    push word [bp+0x6]
    call word 0x993:0x0 ; 91b 3:0 FindMonster
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
    mov [es:bx+di+Monster.tile],al
.label50: ; 942
    mov bx,si
    mov ax,bx
    shl bx,byte 0x2
    add bx,ax
    shl bx,1
    add bx,ax
    mov si,[GameStatePtr]
    les si,[si+MonsterListPtr]
    mov word [es:bx+si+Monster.slipping],0x1
.return: ; 95d
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

    ; args
    ; 0 hDC
    ; 2 x position (px)?
    ; 4 y position (px)?
    ; 6 width?
    ; 8 height?
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

; EndGame
; show final ending animation and text box
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

    %define hDC (bp-8)

    push word [hWnd]
    call word 0x0:0x14 ; a88 USER.GetDC
    mov [hDC],ax
    mov bx,[GameStatePtr]

    cmp word [bx+0xa36],byte 32
    jge .atLeast32

    ; set bp-0x3 to an exit tile depending on 0xa36 % 3
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
    mov byte [bp-0x3], Exit
    jmp short .label4
.label2: ; ac0
    mov byte [bp-0x3], Exit2
    jmp short .label4
.label3: ; ac6
    mov byte [bp-0x3], Exit3

.label4: ; aca
    mov al,[bp-0x3]
    push ax
    push byte ChipS
    lea ax,[si+0x20] ; (_a36 * 8 + 32)
    push ax ; height?
    push ax ; width?
    ; ax =  si / 2 (signed)
    mov ax,si
    cwd
    sub ax,dx
    sar ax,1

    mov bx,[GameStatePtr]
    mov cx,[bx+ChipY]
    sub cx,[bx+0xa26]
    sub cx,[bx+0xa2e]
    shl cx,byte 0x5
    sub cx,ax
    jns .label5
    xor cx,cx
.label5: ; af5
    push cx  ; y position

    mov cx,[bx+ChipX]
    sub cx,[bx+0xa24]
    sub cx,[bx+0xa2c]
    shl cx,byte 0x5
    sub cx,ax
    jns .label6
    xor cx,cx
.label6: ; b0b
    push cx ; x position

.label10: ; b0c
    push word [hDC]
    call word 0x3ed:0x966 ; b0f 7:966 DrawTile
    add sp,byte +0xe
    jmp word .label7



.atLeast32: ; b1a
    cmp word [bx+0xa36],byte +0x68
    jge .atLeast104
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
    push byte Exit

    ; if random int is 0, push ChipS; if >=1, ChipExit
    push cx
    call word 0xe13:0x72e ; b3b 3:72e RandInt
    add sp,byte +0x2
    cmp ax,0x1
    sbb al,al
    and al,0x35
    add al,ChipExit
    mov [bp-0x3],al
    push ax

    push word 0x120
    push word 0x120
    push byte +0x0
    push byte +0x0
    jmp short .label10 ; draw tile

.atLeast104: ; b5c
    cmp word [bx+0xa36],byte +0x69
    jl .equals104
    jmp word .label12
.equals104: ; b66
    cmp word [bp+0x6],byte +0x0
    jz .label13
    jmp word .label12
.label13: ; b6f
    mov word [bp-0x4],0x0
    push byte +0x0
    push ds
    push word 0xc6e
    push word [0x10]
    call word 0xbe4:0x0 ; b7e 2:0
    add sp,byte +0x8
    push word [0x172a]
    push ds
    push word 0x1352
    call word 0x0:0xc59 ; b8e USER.LoadBitmap
    mov [bp-0x6],ax
    or ax,ax
    jz .label14
    push word [0x1734]
    push ax
    call word 0x0:0xbcb ; b9f GDI.SelectObject
    mov si,ax
    push word [hDC]
    push byte +0x0
    push byte +0x0
    push word 0x120
    push word 0x120
    push word [0x1734]
    push byte +0x0
    push byte +0x0
    push word 0xcc
    push byte +0x20
    call word 0x0:0xc8a ; bc0 GDI.BitBlt
    push word [0x1734]
    push si
    call word 0x0:0xc69 ; bca GDI.SelectObject
    push word [bp-0x6]
    call word 0x0:0xc9a ; bd2 GDI.DeleteObject
.label14: ; bd7
    push byte +0x0
    push ds
    push word 0xca8
    push word [0x10]
    call word 0xbfb:0x0 ; be1 2:0
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
    push word YouCompletedNLevelsMsg
    lea ax,[bp-0x19e]
    push ss
    push ax
    call word 0x0:0xffff ; c2b USER._wsprintf
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
    mov word [bx+IsSliding],0x0
    mov bx,[GameStatePtr]
    mov word [bx+Autopsy],NotDeadYet
    mov bx,[GameStatePtr]
    mov word [bx+SlipListLen],0x0
    mov bx,[GameStatePtr]
    mov word [bx+MonsterListLen],0x0
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
    mov al,[bx+si+Lower]
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
    les si,[si+TrapListPtr]
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
    call word 0x5ea:0x56c ; ebe 8:56c
    add sp,byte +0x4
    mov byte [bp+0x10],Dirt
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
    mov byte [bp+0x10],Floor
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
    %define flag1 (bp+0xc) ; 0 if sliding (forced move), 1 if not
    %define flag2 (bp+0xe)

    %define tile1 (bp-0x3)
    %define xdest (bp-0x8)
    %define ydest (bp-0xa)
    %define tile2 (bp-0xb)
    %define action (bp-0xe)

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

    ; x = chipx + xdir
    ; y = chipy + ydir
    mov bx,[GameStatePtr]
    mov ax,[bx+ChipX]
    add ax,[xdir]
    mov [xdest],ax
    mov ax,[bx+ChipY]
    add ax,[ydir]
    mov [ydest],ax
    mov word [bp-0x10],0x0
    mov byte [tile2],0xff

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
    mov dx,[flag1]
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

.label3: ; 11f4 [flag1] != 0 && [bx+0xa40] == 0
    mov word [bx+IsBuffered],0x0
    mov bx,[GameStatePtr]
    mov word [bx+0xa40],0x1
.label2: ; 1204 [flag1] == 0
    mov bx,[GameStatePtr]
    mov word [bx+0xa3e],0x0

; Check board bounds
    cmp word [xdest],byte +0x0
    jnl .xNotLessThan0
    jmp word .label6
.xNotLessThan0: ; 1217
    cmp word [ydest],byte +0x0
    jnl .yNotLessThan0
    jmp word .label6
.yNotLessThan0: ; 1220
    cmp word [xdest],byte +0x20
    jl .xNotGreaterThan32
    jmp word .label6
.xNotGreaterThan32: ; 1229
    cmp word [ydest],byte +0x20
    jl .yNotGreaterThan32
    jmp word .label6
.yNotGreaterThan32: ; 1232

; if chip is sliding or this is a forced move
; and we're standing on ice or a teleport,
; then exit
    mov bx,[GameStatePtr]
    cmp word [bx+IsSliding],byte +0x0
    jz .notSliding
    ; get the tile under chip
    mov si,[bx+ChipY]
    shl si,byte 0x5
    add si,[bx+ChipX]
    mov al,[bx+si+Lower]
    mov [tile2],al
    or dx,dx ; flag1
    jz .notSliding
    cmp al,Ice
    jnz .notOnIce
    jmp word .returnZero
.notOnIce: ; 125a
    cmp al,IceWallNW
    jnz .notOnIceNW
    jmp word .returnZero
.notOnIceNW: ; 1261
    cmp al,IceWallNE
    jnz .notOnIceNE
    jmp word .returnZero
.notOnIceNE: ; 1268
    cmp al,IceWallSW
    jnz .notOnIceSW
    jmp word .returnZero
.notOnIceSW: ; 126f
    cmp al,IceWallSE
    jnz .notOnIceSE
    jmp word .returnZero
.notOnIceSE: ; 1276
    cmp al,Teleport
    jnz .notOnTeleport
    jmp word .returnZero
.notOnTeleport: ; 127d

; are we on a force floor?
    cmp al,ForceS
    jz .onForceFloor
    cmp al,ForceN
    jz .onForceFloor
    cmp al,ForceW
    jz .onForceFloor
    cmp al,ForceE
    jz .onForceFloor
    cmp al,ForceRandom
    jnz .notSliding

; if chip is on a force floor, set the slide dir and return
.onForceFloor: ; 1291
    mov ax,[xdir]
    cmp [bx+SlideX],ax
    jnz .notSliding
    mov ax,[ydir]
    cmp [bx+SlideY],ax
    jnz .notSliding
    jmp word .returnZero

.notSliding: ; 12a6

; if chip is standing on a trap
; do something
    mov si,[bx+ChipY]
    shl si,byte 0x5
    add si,[bx+ChipX]
    mov al,[bx+si+Lower]
    mov [tile1],al
    cmp al,Trap
    jnz .label18
    push word [bx+ChipY]
    push word [bx+ChipX]
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
    les si,[si+TrapListPtr]
    cmp word [es:bx+si+Connection.flag],byte +0x1
    jnz .label18
    jmp word .label6

; check panel walls
.label18: ; 12f0
    cmp byte [tile1],PanelN
    jc .label20
    cmp byte [tile1],PanelE
    jna .label21
.label20: ; 12fc
    cmp byte [tile1],PanelSE
    jnz .label22
.label21: ; 1302
    push byte +0x0
    push word [ydir]
    push word [xdir]
    mov al,[tile1]
    push ax
    call word 0x134a:0x1934 ; 130e 3:0x1934 CanEnterOrExitPanelWalls
    add sp,byte +0x8
    or ax,ax
    jnz .label22
    jmp word .label6

; something about blocks
.label22: ; 131d
    mov bx,[GameStatePtr]
    mov si,[bx+ChipX]
    mov di,[bx+ChipY]
    mov word [bp-0x16],0x0
    mov ax,[ydest]
    shl ax,byte 0x5
    add ax,[xdest]
    add bx,ax
    cmp byte [bx+Upper],Block
    jz .label23
    jmp word .label24
.label23: ; 1341
    push word [ydest]
    push word [xdest]
    call word 0x13df:0x58 ; 1347 3:58
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
    les bx,[bx+SlipListPtr]
    add bx,ax
    mov ax,[es:bx+Monster.xdir]
    mov [bp-0x6],ax
    mov cx,[es:bx+Monster.ydir]
    cmp ax,[xdir]
    jnz .label26
    cmp [ydir],cx
    jnz .label26
    jmp word .label6
.label26: ; 1385
    add ax,[xdir]
    jnz .label25
    add cx,[ydir]
    jnz .label25
    jmp word .label6
.label25: ; 1392
    lea ax,[bp-0x16]
    push ax
    push word 0xff
    push word [ydir]
    push word [xdir]
    push word [ydest]
    push word [xdest]
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
    lea ax,[action]
    push ax
    push word [ydir]
    push word [xdir]
    push word [ydest]
    push word [xdest]
    call word 0x1473:0x1a56 ; 13dc 3:1a56 probably ChipCanEnterTile
    add sp,byte +0xe
    mov [bp-0x10],ax
    or ax,ax
    jnz .label29
    jmp word .label6
.label29: ; 13ee
    ; pop source tile
    ; set upper to lower
    mov bx,[GameStatePtr]
    mov ax,[bx+ChipY]
    shl ax,byte 0x5
    add ax,[bx+ChipX]
    add bx,ax
    mov al,[bx+Lower]
    mov [bx+Upper],al
    ; set lower to Floor
    mov bx,[GameStatePtr]
    mov ax,[bx+ChipY]
    shl ax,byte 0x5
    add ax,[bx+ChipX]
    add bx,ax
    mov byte [bx+Lower],Floor

    ; if chip is on a hint tile,
    ; display hint text (?)
    ; and continue
    mov bx,[GameStatePtr]
    mov ax,[bx+ChipY]
    shl ax,byte 0x5
    add ax,[bx+ChipX]
    add bx,ax
    cmp byte [bx],Hint
    jnz .label30
    push byte +0x8
    call word 0x154f:0xcbe ; 1433
    add sp,byte +0x2

.label30: ; 143b
    mov ax,[action]
    dec ax
    jz .action1
    dec ax
    jz .action2
    dec ax
    dec ax
    jnz .label33
    jmp word .action4
.label33: ; 144b
    dec ax
    jnz .label35
    jmp word .action5
.label35: ; 1451
    dec ax
    jnz .label37
    jmp word .action6
.label37: ; 1457
    dec ax
    jnz .label39
    jmp word .action7
.label39: ; 145d
    jmp word .label41

.action1: ; 1460
    mov bx,[ydest]
    shl bx,byte 0x5
    add bx,[xdest]
    add bx,[GameStatePtr]
    mov al,[bx]
    push ax
    call word 0x151c:0x1770 ; 1470
    add sp,byte +0x2
    jmp word .label41
    nop

.action2: ; 147c
    mov bx,[ydest]
    shl bx,byte 0x5
    add bx,[xdest]
    add bx,[GameStatePtr]
    mov al,[bx+Upper]
    sub ah,ah
    cmp ax,Bomb
    jz .deathByBomb
    ja .deathByMonster
    sub al,Water
    jz .deathByWater
    dec al
    jz .deathByFire
.deathByMonster: ; 149c
    mov bx,[GameStatePtr]
    mov word [bx+Autopsy],Eaten
    jmp short .label28
.deathByWater: ; 14a8
    mov bx,[GameStatePtr]
    mov word [bx+Autopsy],Burned
    jmp short .label28
.deathByFire: ; 14b4
    mov bx,[GameStatePtr]
    mov word [bx+Autopsy],Drowned
    jmp short .label28
.deathByBomb: ; 14c0
    mov bx,[GameStatePtr]
    mov word [bx+Autopsy],Bombed
.label28: ; 14ca
    mov ax,[xdest]
    mov bx,[GameStatePtr]
    mov [bx+ChipX],ax
    mov ax,[ydest]
    mov bx,[GameStatePtr]
    mov [bx+ChipY],ax
    mov bx,[ydest]
    shl bx,byte 0x5
    add bx,[xdest]
    add bx,[GameStatePtr]
    mov al,[bx]
    mov [bx+Lower],al
    mov bx,[ydest]
    shl bx,byte 0x5
    add bx,[xdest]
    add bx,[GameStatePtr]
    mov [bp-0x18],bx
    mov al,[bx+Lower]
    sub ah,ah
    sub ax,0x3
    jz .label46
    dec ax
    jz .label47
    push word [ydir]
    push word [xdir]
    push byte +0x6c
    call word 0x1611:0x486 ; 1519
    add sp,byte +0x6
    mov bx,[ydest]
    shl bx,byte 0x5
    add bx,[xdest]
    add bx,[GameStatePtr]
    mov [bx],al
    jmp short .label48
.label46: ; 1532
    mov byte [bx],ChipSplash
    jmp short .label48
    nop
.label47: ; 1538
    mov byte [bx],ChipBurned
.label48: ; 153b
    push di
    push si
    mov bx,[GameStatePtr]
    push word [bx+ChipY]
    push word [bx+ChipX]
    push word [bp+0x6]
    call word 0x1572:0x56e ; 154c
    add sp,byte +0xa
    push byte +0x1
    push byte +0x2
    call word 0xf4b:0x56c ; 1558
    add sp,byte +0x4
    mov bx,[GameStatePtr]
    push word [bx+ChipY]
    push word [bx+ChipX]
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


.action5: ; 1592
    push word 0xc6c
    push byte +0x0 ; chip
    lea ax,[ydir]
    push ax
    lea ax,[xdir]
    push ax
    push word [ydest]
    push word [xdest]
    mov bx,[GameStatePtr]
    push word [bx+ChipY]
    push word [bx+ChipX]
    call word 0xee9:0x636 ; 15b1
    add sp,byte +0x10
    mov bx,[GameStatePtr]
    cmp word [bx+0x80e],byte +0x0
    jnz .label49
    jmp word .label34
.label49: ; 15c7
    mov al,[tile2]
    mov bx,[ydest]
    shl bx,byte 0x5
    add bx,[xdest]
    add bx,[GameStatePtr]
    cmp [bx],al
    jnz .label50
    jmp word .label34
.label50: ; 15de
    mov bx,[GameStatePtr]
    mov ax,[bx+0x812]
    add ax,[xdir]
    jnz .label34
    mov ax,[bx+0x814]
    add ax,[ydir]
    jnz .label34
    mov word [bx+0xa40],0x1
    mov bx,[GameStatePtr]
    mov word [bx+0x80e],0x0
    jmp short .label34


.action6: ; 1606
    push di
    push si
    push word [ydest]
    push word [xdest]
    call word 0xf2f:0x21aa ; 160e
    add sp,byte +0x8
    jmp short .label34


.action7: ; 1618
    push byte +0x0
    push word [ydir]
    push word [xdir]
    lea ax,[ydest]
    push ax
    lea cx,[xdest]
    push cx
    push word [bp+0x6]
    call word 0x16b0:0x276a ; 162b
    add sp,byte +0xc
    push word 0xc6c
    push byte +0x0 ; chip
    lea ax,[ydir]
    push ax
    lea ax,[xdir]
    push ax
    push word [ydest]
    push word [xdest]
    mov bx,[GameStatePtr]
    push word [bx+ChipY]
    push word [bx+ChipX]
    call word 0x183c:0x636 ; 1652
    add sp,byte +0x10
    mov word [action],0x5
    ; fallthrough


.action4:
.label34: ; 165f
    mov bx,[ydest]
    shl bx,byte 0x5
    add bx,[xdest]
    add bx,[GameStatePtr]
    mov al,[bx]
    mov [bx+Lower],al

; default case
.label41: ; 1672
    mov ax,[xdest]
    mov bx,[GameStatePtr]
    mov [bx+ChipX],ax
    mov ax,[ydest]
    mov bx,[GameStatePtr]
    mov [bx+ChipY],ax
    push word [ydir]
    push word [xdir]
    mov bx,[ydest]
    shl bx,byte 0x5
    add bx,[xdest]
    add bx,[GameStatePtr]
    mov [bp-0x1a],bx
    cmp byte [bx+Lower],0x3
    jnz .label51
    mov al,SwimN
    jmp short .label52
    nop
.label51: ; 16aa
    mov al,ChipN
.label52: ; 16ac
    push ax
    call word 0x172a:0x486 ; 16ad 3:486 SetTileDir
    add sp,byte +0x6
    mov bx,[bp-0x1a]
    mov [bx],al
    push di
    push si
    mov bx,[GameStatePtr]
    push word [bx+ChipY]
    push word [bx+ChipX]
    push word [bp+0x6]
    call word 0x16e5:0x56e ; 16cb 2:56e
    add sp,byte +0xa
    mov bx,[GameStatePtr]
    push word [bx+ChipY]
    push word [bx+ChipX]
    push word [bp+0x6]
    call word 0x176f:0x1ca ; 16e2 2:1ca
    add sp,byte +0x6
    cmp word [action],byte +0x4
    jz .label53
    jmp word .label54
.label53: ; 16f3
    mov bx,[GameStatePtr]
    mov si,[bx+ChipY]
    shl si,byte 0x5
    add si,[bx+ChipX]
    mov al,[bx+si+Lower]
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
    push word [bx+ChipY]
    push word [bx+ChipX]
    push word [bp+0x6]
    call word 0x1753:0x2442 ; 173b
    add sp,byte +0x8
    jmp short .label54
    nop
.label58: ; 1746
    push byte +0x1
    push word [bx+ChipY]
    push word [bx+ChipX]
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
    mov al,[bx+si+Lower]
    sub ah,ah
    sub ax,ToggleButton
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
    call word 0x17cf:0x2442 ; 17b9 3:0x2442
    add sp,byte +0x8
    jmp short .label61
    nop
.label64: ; 17c4
    push byte +0x0
    push word [bp-0x12]
    push word [bp-0x14]
    call word 0x17de:0x211a ; 17cc 3:0x211a
    add sp,byte +0x6
    jmp short .label61
.label65: ; 17d6
    push byte +0x0
    push word [bp+0x6]
    call word 0x1894:0x1e6a ; 17db 3:0x1e6a
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
    cmp word [action],byte +0x5
    jz .label67
    mov word [bx+0x80c],0x0
.label67: ; 180b
    mov bx,[GameStatePtr]
    inc word [bx+0xa34]
    mov bx,[GameStatePtr]
    mov si,[bx+ChipY]
    shl si,byte 0x5
    add si,[bx+ChipX]
    cmp byte [bx+si+Lower],0x15
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
    ; Out of bounds or some other failure

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
    call word 0x1436:0x1ca ; 18ad 2:0x1ca UpdateTile
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
;   facing (previous monster tile, if applicable, or 0xff)
; Return value:
;   0 - blocked
;   1 - success
;   2 - dead
Eight:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x1a
    push di ; xsrc
    push si ; ysrc

    %define unknown (bp+0x6) ; probably hDC
    %define xptr (bp+0x8)
    %define yptr (bp+0xa)
    %define xdirptr (bp+0xc)
    %define ydirptr (bp+0xe)
    %define facing (bp+0x10)

    %define tile (bp-0x3)
    %define ydir (bp-0x6)
    %define trap (bp-0x8)
    %define xdir (bp-0xa)
    %define ysrc (bp-0xc)
    %define xsrc (bp-0xe)
    %define xdest (bp-0x10)
    %define ydest (bp-0x12)
    %define action (bp-0x14)
    %define dead (bp-0x16)
    %define srcidx (bp-0x18)

    ; xdir = *xdirptr
    ; ydir = *ydirptr
    ; ydest = *yptr + *yptrdir
    ; xdest = *xptr + *xptrdir
    mov bx,[xptr]
    mov di,[bx]
    mov si,[yptr]
    mov si,[si]
    mov bx,[xdirptr]
    mov ax,[bx]
    mov [xdir],ax
    mov bx,[ydirptr]
    mov cx,[bx]
    mov [ydir],cx
    mov bx,[xptr]
    add ax,[bx]
    mov [xdest],ax
    mov ax,cx
    add ax,si
    mov [ydest],ax
    mov word [dead],0x0

; check that xdest and ydest are in [0,32)
    cmp word [xdest],byte +0x0
    jnl .yNotLessThan0
    jmp word .deleteSlipperAndReturn
.yNotLessThan0: ; 1920
    or ax,ax
    jnl .xNotLessThan0
    jmp word .deleteSlipperAndReturn
.xNotLessThan0: ; 1927
    cmp word [xdest],byte +0x20
    jl .yLessThan32
    jmp word .deleteSlipperAndReturn
.yLessThan32: ; 1930
    cmp ax,0x20
    jl .xLessThan32
    jmp word .deleteSlipperAndReturn
.xLessThan32: ; 1938

; get tile we're leaving from
    mov bx,si
    shl bx,byte 0x5
    add bx,di
    mov [srcidx],bx
    add bx,[GameStatePtr]
    mov al,[bx+Lower]
    mov [tile],al

; check if the floor is a trap
    cmp al,Trap
    jnz .checkPanelWalls
    ; It's a trap!
    push si ; ysrc
    push di ; xsrc
    call word 0x19a3:0x22be ; 1953 FindTrap
    add sp,byte +0x4
    mov [trap],ax
    or ax,ax
    jnl .label6
    jmp word .deleteSlipperAndReturn
.label6: ; 1965
    ; multiply by 10
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
    jmp word .deleteSlipperAndReturn

.checkPanelWalls: ; 1982
    ; It's not a trap!

    ; Panel walls!
    ; Check if we can exit the tile we're standing on
    cmp byte [tile],PanelN
    jc .label7
    cmp byte [tile],PanelE
    jna .label8
.label7: ; 198e
    cmp byte [tile],PanelSE
    jnz .label9
.label8: ; 1994
    push byte +0x0 ; exit
    push word [bp-0x6]
    push word [bp-0xa]
    mov al,[tile]
    push ax
    call word 0x19d2:0x1934 ; 19a0 3:0x1934 CanEnterOrExitPanelWalls
    add sp,byte +0x8
    or ax,ax
    jnz .label9
    jmp word .deleteSlipperAndReturn

; Okay, check if we can enter the destination tile
.label9: ; 19af
    mov bx,[srcidx]
    add bx,[GameStatePtr]
    mov al,[bx+Upper]
    mov [tile],al
    lea ax,[action]
    push ax
    push word [ydir]
    push word [xdir]
    push word [ydest]
    push word [xdest]
    mov al,[tile]
    push ax
    call word 0x12c7:0x1d4a ; 19cf 3:0x1d4a MonsterCanEnterTile
    add sp,byte +0xc
    or ax,ax
    jnz .label10
    jmp word .deleteSlipperAndReturn
.label10: ; 19de
    mov ax,[action]
    cmp ax,0x7
    ja .jumpDefault
    shl ax,1
    xchg ax,bx
    jmp word [cs:bx+.jumpTable]

.jumpTable:
    dw .jump0
    dw .jump1
    dw .jump2 ; water/fire
    dw .jumpDefault
    dw .jump4 ; slide
    dw .jump5 ; bomb
    dw .jump6 ; trap
    dw .jump7 ; teleport

; 19fe
.jump4:
    lea ax,[facing]
    push ax
    push byte +0x2 ; monster
    push word [ydirptr]
    push word [xdirptr]
    push word [ydest]
    push word [xdest]
    push si ; ysrc
    push di ; xsrc
    call word 0x1ac4:0x636 ; 1a12 7:0x636 SlideMovement
    add sp,byte +0x10
    jmp short .label13

; 1a1c
.jump5:
    ; play bomb sound?
    push byte +0x1
    push byte +0xb
    call word 0x1830:0x56c ; 1a20 8:0x56c
    add sp,byte +0x4
    mov byte [facing],Floor
; 1a2c
.jump2:
    ; dead
    mov word [dead],0x1

.jumpDefault:
.label11: ; 1a31
    cmp word [action],byte +0x4
    jz .label14
    mov bx,[GameStatePtr]
    cmp word [bx+SlipListLen],byte +0x0
    jz .label14
    push byte +0x2
    push si ; ysrc
    push di ; xsrc
    mov bx,[srcidx]
    add bx,[GameStatePtr]
    mov al,[bx+Upper]
    push ax
    call word 0x1a77:0x12be ; 1a50 DeleteSlipperAt
    add sp,byte +0x8
.label14: ; 1a58
    cmp word [action],byte +0x2
    jnz .label15
    jmp word .label16
.label15: ; 1a61
    cmp byte [facing],0xff
    jz .label17
    mov al,[facing]
    jmp short .label18

; 1a6c
.jump6:
    push si ; ysrc
    push di ; xsrc
    push word [ydest]
    push word [xdest]
    call word 0x1aa8:0x21aa ; 1a74 3:0x21aa
    add sp,byte +0x8

; 1a7c
.jump0:
.jump1:
.label13:
    mov bx,[ydest]
    shl bx,byte 0x5
    add bx,[xdest]
    add bx,[GameStatePtr]
    mov al,[bx]
    mov [bx+Lower],al
    jmp short .label11
    nop

; 1a92
.jump7:
    ; teleport
    push byte +0x2
    push word [ydir]
    push word [xdir]
    lea ax,[ydest]
    push ax
    lea cx,[xdest]
    push cx
    push word [unknown]
    call word 0x1b76:0x276a ; 1aa5 3:0x276a
    add sp,byte +0xc
    lea ax,[facing]
    push ax
    push byte +0x2 ; monster
    push word [ydirptr]
    push word [xdirptr]
    push word [ydest]
    push word [xdest]
    push si ; ysrc
    push di ; xsrc
    call word 0x1655:0x636 ; 1ac1 7:0x636
    add sp,byte +0x10
    mov bx,[ydest]
    shl bx,byte 0x5
    add bx,[xdest]
    add bx,[GameStatePtr]
    mov al,[bx+Upper]
    mov [bx+Lower],al
    mov word [action],0x4
    jmp word .label11


.label17: ; 1ae4
    mov al,[tile]
.label18: ; 1ae7
    mov bx,[ydest]
    shl bx,byte 0x5
    add bx,[xdest]
    add bx,[GameStatePtr]
    mov [bx+Upper],al
    push word [ydest]
    push word [xdest]
    push word [unknown]
    call word 0x1b36:0x1ca ; 1aff 2:0x1ca
    add sp,byte +0x6

; end of the jump table cases???


.label16: ; 1b07
    ; pop tile from source
    mov bx,[srcidx]
    add bx,[GameStatePtr]
    cmp byte [bx+Lower],CloneMachine
    jz .label19
    mov bx,[srcidx]
    add bx,[GameStatePtr]
    mov al,[bx+Lower]
    mov [bx+Upper],al
    mov bx,[srcidx]
    add bx,[GameStatePtr]
    mov byte [bx+Lower],Floor
.label19: ; 1b2e
    push si ; ysrc
    push di ; xsrc
    push word [unknown]
    call word 0x16ce:0x1ca ; 1b33 2:0x1ca
    add sp,byte +0x6
    cmp word [action],byte +0x1
    jz .label20
    jmp word .autopsy

.label20: ; 1b44
    mov [xsrc],di
    mov [ysrc],si
    mov si,[ydest]
    shl si,byte 0x5
    add si,[xdest]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    sub ah,ah
    sub ax,ToggleButton
    jz .toggleButton
    dec ax ; CloneButton
    jz .cloneButton
    sub ax,0x3 ; TrapButton
    jz .trapButton
    dec ax ; TankButton
    jz .tankButton
    jmp word .autopsy
.toggleButton: ; 1b70
    push word [unknown]
    call word 0x1b8c:0x1fac ; 1b73 3:0x1fac
    add sp,byte +0x2
    jmp word .autopsy
.cloneButton: ; 1b7e
    push byte +0x0
    push word [ydest]
    push word [xdest]
    push word [unknown]
    call word 0x1b9f:0x2442 ; 1b89 3:0x2442
    add sp,byte +0x8
    jmp word .autopsy
.trapButton: ; 1b94
    push byte +0x0
    push word [ydest]
    push word [xdest]
    call word 0x1bb4:0x211a ; 1b9c 3:0x211a
    add sp,byte +0x6
    jmp word .autopsy
    nop
.tankButton: ; 1ba8
    mov di,[xdirptr]
    push word [ysrc]
    push word [xsrc]
    call word 0x1c1b:0x0 ; 1bb1 FindMonster
    add sp,byte +0x4
    mov si,ax
    cmp si,byte -0x1
    jz .notFound
    mov di,[xdirptr]
    mov ax,[xdest]
    mov cx,si
    shl cx,byte 0x2
    add cx,si
    shl cx,1
    add cx,si
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,cx
    mov [es:bx+Monster.x],ax
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,cx
    mov ax,[ydest]
    mov [es:bx+Monster.y],ax
    mov ax,[di]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,cx
    mov [es:bx+Monster.xdir],ax
    mov bx,[ydirptr]
    mov ax,[bx]
    mov bx,[GameStatePtr]
    les bx,[bx+MonsterListPtr]
    add bx,cx
    mov [es:bx+Monster.ydir],ax
.notFound: ; 1c13
    push byte +0x0
    push word [unknown]
    call word 0x1cc4:0x1e6a ; 1c18 3:0x1e6a
    add sp,byte +0x4
    cmp si,byte -0x1
    jz .autopsy
    ; set *xdirptr and *ydirptr
    mov bx,si
    mov ax,si
    shl bx,byte 0x2
    add bx,ax
    shl bx,1
    add bx,ax
    mov si,[GameStatePtr]
    les si,[si+MonsterListPtr]
    mov ax,[es:bx+si+Monster.xdir]
    mov [di],ax
    mov si,[GameStatePtr]
    mov ax,bx
    les bx,[si+MonsterListPtr]
    mov si,ax
    mov ax,[es:bx+si+Monster.ydir]
    mov bx,[ydirptr]
    mov [bx],ax

; if the monster isn't dead,
; and landed on top of chip,
; set autopsy status to Eaten
.autopsy: ; 1c55
    cmp word [dead],byte +0x0
    jnz .label27
    mov si,[ydest]
    shl si,byte 0x5
    add si,[xdest]
    mov bx,[GameStatePtr]
    mov al,[bx+si+Lower]
    mov [bp-0x1a],al
    cmp al,ChipN
    jc .label28
    cmp al,ChipE
    jna .label29
.label28: ; 1c77
    cmp byte [bp-0x1a],SwimN
    jc .label27
    cmp byte [bp-0x1a],SwimE
    ja .label27
.label29: ; 1c83
    mov word [bx+Autopsy],Eaten

; assign xdest and ydest to xptr and yptr
; return 1, or 2 if not dead
.label27: ; 1c89
    mov ax,[xdest]
    mov bx,[xptr]
    mov [bx],ax
    mov ax,[ydest]
    mov bx,[yptr]
    mov [bx],ax
    cmp word [dead],byte +0x1
    sbb ax,ax
    add ax,0x2
    jmp short .return

.deleteSlipperAndReturn: ; 1ca4
    mov bx,[GameStatePtr]
    cmp word [bx+SlipListLen],byte +0x0
    jz .returnZero
    push byte +0x2
    push si         ; ysrc
    push di         ; xsrc
    mov bx,si
    shl bx,byte 0x5
    add bx,di
    mov si,[GameStatePtr]
    mov al,[bx+si+Upper]
    push ax         ; facing
    call word 0x162e:0x12be ; 1cc1 3:0x12be DeleteSlipperAt
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
; 0

FUN_1_0000:
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    db 0xff
    db 0xff
.label0: ; 12
    mov al,0xff
    push ax
    call 0xffff:0x2c3 ; 15 1:2c3
    xor bp,bp
    push bp
    call 0x0:0xffff ; 1d KERNEL.InitTask
    or ax,ax
    jz .label0 ; ↑
    mov [0x14be],es
    add cx,0x100
    jc .label0 ; ↑
    mov [0x1484],cx
    mov [0x1486],si
    mov [0x1488],di
    mov [0x148a],bx
    mov [0x148c],es
    mov [0x148e],dx
    call 0x0:0xffff ; 48 KERNEL.GetVersion
    mov [0x14c0],ax
    mov ah,0x30
    test word [cs:0x10],0x1
    jz .label1 ; ↓
    call 0x0:0xffff ; 5b KERNEL.DOS3Call
    jmp short .label2 ; ↓
.label1: ; 62
    int 0x21
.label2: ; 64
    mov [0x14c2],ax
    test word [cs:0x10],0x1
    jnz .label3 ; ↓
    mov al,0x0
    mov [0x14c5],al
.label3: ; 75
    xor ax,ax
    push ax
    call 0x0:0xffff ; 78 KERNEL.WaitEvent
    push word [0x1488]
    call 0x0:0xffff ; 81 USER.InitApp
    or ax,ax
    jz .label0 ; ↑
    call 0x18:FUN_1_01d6 ; 8a 1:1d6
    call 0x8d:FUN_1_03b4 ; 8f 1:3b4
    call 0x92:0x536 ; 94 1:536
    call 0x694 ; 99
    push word [0x14fa]
    push word [0x14f8]
    push word [0x14f6]
    call 0x97:FUN_1_01aa ; a8 1:1aa
    add sp,byte +0x6
    push ax
    call 0xab:FUN_1_02b5 ; b1 1:2b5
    mov ax,0x15
    jmp 0x5cb
    jmp 0x60e
    add cl,ch
    dec bx
    add ax,0x4500
    push bp
    mov bp,sp
    push ds
    mov ax,[bp+0x6]
    mov [0x1498],ax
    mov word [0x149a],0x0
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; dc

rand:
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ax,0x43fd
    mov dx,0x3
    push dx
    push ax
    push word [0x149a]
    push word [0x1498]
    call 0xb4:mul32 ; f1 1:662 mul32
    add ax,0x9ec3
    adc dx,byte +0x26
    mov [0x1498],ax
    mov [0x149a],dx
    mov ax,dx
    and ah,0x7f
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 110

div32_probably:
    push bp
    mov bp,sp
    push di
    push si
    push bx
    xor di,di
    mov ax,[bp+0x8]
    or ax,ax
    jnl .label0 ; ↓
    inc di
    mov dx,[bp+0x6]
    neg ax
    neg dx
    sbb ax,byte +0x0
    mov [bp+0x8],ax
    mov [bp+0x6],dx
.label0: ; 130
    mov ax,[bp+0xc]
    or ax,ax
    jnl .label1 ; ↓
    inc di
    mov dx,[bp+0xa]
    neg ax
    neg dx
    sbb ax,byte +0x0
    mov [bp+0xc],ax
    mov [bp+0xa],dx
.label1: ; 148
    or ax,ax
    jnz .label2 ; ↓
    mov cx,[bp+0xa]
    mov ax,[bp+0x8]
    xor dx,dx
    div cx
    mov bx,ax
    mov ax,[bp+0x6]
    div cx
    mov dx,bx
    jmp short .label6 ; ↓
.label2: ; 161
    mov bx,ax
    mov cx,[bp+0xa]
    mov dx,[bp+0x8]
    mov ax,[bp+0x6]
.label3: ; 16c
    shr bx,1
    rcr cx,1
    shr dx,1
    rcr ax,1
    or bx,bx
    jnz .label3 ; ↑
    div cx
    mov si,ax
    mul word [bp+0xc]
    xchg ax,cx
    mov ax,[bp+0xa]
    mul si
    add dx,cx
    jc .label4 ; ↓
    cmp dx,[bp+0x8]
    ja .label4 ; ↓
    jc .label5 ; ↓
    cmp ax,[bp+0x6]
    jna .label5 ; ↓
.label4: ; 195
    dec si
.label5: ; 196
    xor dx,dx
    xchg ax,si
.label6: ; 199
    dec di
    jnz .label7 ; ↓
    neg dx
    neg ax
    sbb dx,byte +0x0
.label7: ; 1a3
    pop bx
    pop si
    pop di
    pop bp
    retf 0x8

; 1aa

FUN_1_01aa:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    push word [0x1488]
    push word [0x1486]
    push word [0x148c]
    push word [0x148a]
    push word [0x148e]
    call 0xffff:0x628 ; 1c8 2:628 WinMain
    sub bp,byte +0x2
    mov sp,bp
    pop ds
    pop bp
    dec bp
    retf

; 1d6

FUN_1_01d6:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    mov ax,0x3500
    test word [cs:0x10],0x1
    jz .label0 ; ↓
    call 0x0:0x5c ; 1ec KERNEL.DOS3Call
    jmp short .label1 ; ↓
.label0: ; 1f3
    int 0x21
.label1: ; 1f5
    mov [0x14aa],bx
    mov [0x14ac],es
    push cs
    pop ds
    mov ax,0x2500
    mov dx,0x5c6
    test word [cs:0x10],0x1
    jz .label2 ; ↓
    call 0x0:0x1ed ; 20e KERNEL.DOS3Call
    jmp short .label3 ; ↓
.label2: ; 215
    int 0x21
.label3: ; 217
    push ss
    pop ds
    mov cx,[0x1518]
    jcxz .label5 ; ↓
    mov es,[0x14be]
    mov si,[es:0x2c]
    mov ax,[0x151a]
    mov dx,[0x151c]
    xor bx,bx
    call far [0x1516] ; 231
    jnc .label4 ; ↓
    jmp 0x6a0
.label4: ; 23a
    mov ax,[0x151e]
    mov dx,[0x1520]
    mov bx,0x3
    call far [0x1516] ; 244
.label5: ; 248
    mov es,[0x14be]
    mov cx,[es:0x2c]
    jcxz .label10 ; ↓
    mov es,cx
    xor di,di
.label6: ; 257
    cmp byte [es:di],0x0
    jz .label10 ; ↓
    mov cx,0xd
    mov si,0x149c
    repe cmpsb
    jz .label7 ; ↓
    mov cx,0x7fff
    xor ax,ax
    repne scasb
    jnz .label10 ; ↓
    jmp short .label6 ; ↑
.label7: ; 272
    push es
    push ds
    pop es
    pop ds
    mov si,di
    mov di,0x14ce
    mov cl,0x4
.label8: ; 27d
    lodsb
    sub al,0x41
    jc .label9 ; ↓
    shl al,cl
    xchg ax,dx
    lodsb
    sub al,0x41
    jc .label9 ; ↓
    or al,dl
    stosb
    jmp short .label8 ; ↑
.label9: ; 28f
    push ss
    pop ds
.label10: ; 291
    mov si,0x1522
    mov di,0x1522
    call 0x37c ; 297
    mov si,0x1522
    mov di,0x1522
    call 0x37c ; 2a0
    mov si,0x1522
    mov di,0x1522
    call 0x37c ; 2a9
    sub bp,byte +0x2
    mov sp,bp
    pop ds
    pop bp
    dec bp
    retf

; 2b5

FUN_1_02b5:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    xor cx,cx
    jmp short .label0 ; ↓
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    mov cx,0x1
    jmp short .label0 ; ↓
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    push si
    push di
    mov cx,0x100
    jmp short .label0 ; ↓
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    push si
    push di
    mov cx,0x101
.label0: ; 2f2
    mov [0x1503],ch
    push cx
    or cl,cl
    jnz .label1 ; ↓
    mov si,0x167c
    mov di,0x167c
    call 0x37c ; 301
    mov si,0x1522
    mov di,0x1522
    call 0x37c ; 30a
    mov si,[bp+0x6]
    push si
    call 0x694 ; 311
    add sp,byte +0x2
.label1: ; 317
    mov si,0x1522
    mov di,0x1522
    call 0x37c ; 31d
    mov si,0x1522
    mov di,0x1522
    call 0x37c ; 326
    call 0x353 ; 329
    pop ax
    or ah,ah
    jnz .label3 ; ↓
    mov ax,[bp+0x6]
    mov ah,0x4c
    test word [cs:0x10],0x1
    jz .label2 ; ↓
    call 0x0:0x20f ; 33f KERNEL.DOS3Call
    jmp short .label3 ; ↓
.label2: ; 346
    int 0x21
.label3: ; 348
    pop di
    pop si
    sub bp,byte +0x2
    mov sp,bp
    pop ds
    pop bp
    dec bp
    retf

; 353

FUN_1_0353:
    mov cx,[0x1518]
    jcxz .label0 ; ↓
    mov bx,0x2
    call far [0x1516] ; 35c
.label0: ; 360
    push ds
    lds dx,[0x14aa]
    mov ax,0x2500
    test word [cs:0x10],0x1
    jz .label1 ; ↓
    call 0x0:0x340 ; 371 KERNEL.DOS3Call
    jmp short .label2 ; ↓
.label1: ; 378
    int 0x21
.label2: ; 37a
    pop ds
    ret

; 37c

FUN_1_037c:
.label0: ; 37c
    cmp si,di
    jnc .label1 ; ↓
    sub di,byte +0x4
    mov ax,[di]
    or ax,[di+0x2]
    jz .label0 ; ↑
    call far [di] ; 38a
    jmp short .label0 ; ↑
.label1: ; 38e
    ret

; 38f

    db 0x00
FUN_1_0390:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    mov ax,0xfc
    push ax
    push cs
    call 0x6dd ; 39f
    mov ax,0xff
    push ax
    push cs
    call 0x6dd ; 3a7
    sub bp,byte +0x2
    mov sp,bp
    pop ds
    pop bp
    dec bp
    retf
    db 0x00

; 3b4

FUN_1_03b4:
    pop word [0x1508]
    pop word [0x150a]
    mov ax,0x104
    mov cx,0x8
    call 0x71a ; 3c2
    mov [0x14fe],dx
    mov [0x14fc],ax
    push dx
    push ax
    push word [0x1488]
    push dx
    push ax
    mov ax,0x104
    push ax
    call 0x0:0xffff ; 3d8 KERNEL.GetModuleFileName
    pop bx
    pop es
    add bx,ax
    mov byte [es:bx],0x0
    mov dx,0x1
    mov di,0x1
    mov si,0x81
    mov ds,[0x14be]
.label0: ; 3f2
    lodsb
    cmp al,0x20
    jz .label0 ; ↑
    cmp al,0x9
    jz .label0 ; ↑
    cmp al,0xd
    jz .label11 ; ↓
    or al,al
    jz .label11 ; ↓
    inc di
.label1: ; 404
    dec si
.label2: ; 405
    lodsb
    cmp al,0x20
    jz .label0 ; ↑
    cmp al,0x9
    jz .label0 ; ↑
    cmp al,0xd
    jz .label11 ; ↓
    or al,al
    jz .label11 ; ↓
    cmp al,0x22
    jz .label7 ; ↓
    cmp al,0x5c
    jz .label3 ; ↓
    inc dx
    jmp short .label2 ; ↑
.label3: ; 421
    xor cx,cx
.label4: ; 423
    inc cx
    lodsb
    cmp al,0x5c
    jz .label4 ; ↑
    cmp al,0x22
    jz .label5 ; ↓
    add dx,cx
    jmp short .label1 ; ↑
.label5: ; 431
    mov ax,cx
    shr cx,1
    adc dx,cx
    test al,0x1
    jnz .label2 ; ↑
    jmp short .label7 ; ↓
.label6: ; 43d
    dec si
.label7: ; 43e
    lodsb
    cmp al,0xd
    jz .label11 ; ↓
    or al,al
    jz .label11 ; ↓
    cmp al,0x22
    jz .label2 ; ↑
    cmp al,0x5c
    jz .label8 ; ↓
    inc dx
    jmp short .label7 ; ↑
.label8: ; 452
    xor cx,cx
.label9: ; 454
    inc cx
    lodsb
    cmp al,0x5c
    jz .label9 ; ↑
    cmp al,0x22
    jz .label10 ; ↓
    add dx,cx
    jmp short .label6 ; ↑
.label10: ; 462
    mov ax,cx
    shr cx,1
    adc dx,cx
    test al,0x1
    jnz .label7 ; ↑
    jmp short .label2 ; ↑
.label11: ; 46e
    push ss
    pop ds
    mov [0x14f6],di
    add dx,di
    inc di
    shl di,1
    add dx,di
    inc dx
    and dl,0xfe
    sub sp,dx
    mov ax,sp
    mov [0x14f8],ax
    mov bx,ax
    add di,bx
    push ss
    pop es
    lds si,[0x14fc]
    mov [ss:bx],si
    inc bx
    inc bx
    mov ds,[ss:0x14be]
    mov si,0x81
    jmp short .label13 ; ↓
.label12: ; 49f
    xor ax,ax
    stosb
.label13: ; 4a2
    lodsb
    cmp al,0x20
    jz .label13 ; ↑
    cmp al,0x9
    jz .label13 ; ↑
    cmp al,0xd
    jz .label25 ; ↓
    or al,al
    jz .label25 ; ↓
    mov [ss:bx],di
    inc bx
    inc bx
.label14: ; 4b8
    dec si
.label15: ; 4b9
    lodsb
    cmp al,0x20
    jz .label12 ; ↑
    cmp al,0x9
    jz .label12 ; ↑
    cmp al,0xd
    jz .label24 ; ↓
    or al,al
    jz .label24 ; ↓
    cmp al,0x22
    jz .label20 ; ↓
    cmp al,0x5c
    jz .label16 ; ↓
    stosb
    jmp short .label15 ; ↑
.label16: ; 4d5
    xor cx,cx
.label17: ; 4d7
    inc cx
    lodsb
    cmp al,0x5c
    jz .label17 ; ↑
    cmp al,0x22
    jz .label18 ; ↓
    mov al,0x5c
    rep stosb
    jmp short .label14 ; ↑
.label18: ; 4e7
    mov al,0x5c
    shr cx,1
    rep stosb
    jnc .label20 ; ↓
    mov al,0x22
    stosb
    jmp short .label15 ; ↑
.label19: ; 4f4
    dec si
.label20: ; 4f5
    lodsb
    cmp al,0xd
    jz .label24 ; ↓
    or al,al
    jz .label24 ; ↓
    cmp al,0x22
    jz .label15 ; ↑
    cmp al,0x5c
    jz .label21 ; ↓
    stosb
    jmp short .label20 ; ↑
.label21: ; 509
    xor cx,cx
.label22: ; 50b
    inc cx
    lodsb
    cmp al,0x5c
    jz .label22 ; ↑
    cmp al,0x22
    jz .label23 ; ↓
    mov al,0x5c
    rep stosb
    jmp short .label19 ; ↑
.label23: ; 51b
    mov al,0x5c
    shr cx,1
    rep stosb
    jnc .label15 ; ↑
    mov al,0x22
    stosb
    jmp short .label20 ; ↑
.label24: ; 528
    xor ax,ax
    stosb
.label25: ; 52b
    push ss
    pop ds
    mov word [bx],0x0
    jmp far [0x1508]
    db 0x00
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    push ds
    call 0x0:0xffff ; 541 KERNEL.GetDOSEnvironment
    or ax,ax
    jz .label26 ; ↓
    mov dx,ax
.label26: ; 54c
    mov bx,dx
    mov es,dx
    xor ax,ax
    xor si,si
    xor di,di
    mov cx,0xffff
    or bx,bx
    jz .label28 ; ↓
    cmp byte [es:0x0],0x0
    jz .label28 ; ↓
.label27: ; 565
    repne scasb
    inc si
    scasb
    jnz .label27 ; ↑
.label28: ; 56b
    mov ax,di
    inc ax
    and al,0xfe
    inc si
    mov di,si
    shl si,1
    mov cx,0x9
    call 0x71a ; 578
    push ax
    mov ax,si
    call 0x71a ; 57e
    mov [0x14fa],ax
    push es
    push ds
    pop es
    pop ds
    mov cx,di
    mov bx,ax
    xor si,si
    pop di
    dec cx
    jcxz .label31 ; ↓
    mov ax,[si]
    cmp ax,[ss:0x149c]
    jnz .label29 ; ↓
    push cx
    push si
    push di
    mov di,0x149c
    mov cx,0x6
    repe cmpsw
    pop di
    pop si
    pop cx
    jz .label30 ; ↓
.label29: ; 5ab
    mov [es:bx],di
    inc bx
    inc bx
.label30: ; 5b0
    lodsb
    stosb
    or al,al
    jnz .label30 ; ↑
    loop 0x592
.label31: ; 5b8
    mov [es:bx],cx
    pop ds
    sub bp,byte +0x2
    mov sp,bp
    pop ds
    pop bp
    dec bp
    retf
    db 0x00

; 5c6

FUN_1_05c6:
    push ss
    pop ds
    mov ax,0x3
    push ax
    push ax
    push cs
    call 0x390 ; 5ce
    push cs
    call 0x6dd ; 5d2
    push cs
    call 0x6a6 ; 5d6
    xor bx,bx
    or ax,ax
    jz .label1 ; ↓
    mov di,ax
    mov ax,0x9
    cmp byte [di],0x4d
    jnz .label0 ; ↓
    mov ax,0xf
.label0: ; 5ec
    add di,ax
    push di
    push ds
    pop es
    mov al,0xd
    mov cx,0x22
    repne scasb
    mov [di-0x1],bl
    pop ax
.label1: ; 5fc
    push bx
    push ds
    push ax
    call 0x0:0xffff ; 5ff KERNEL.FatalAppExit
    mov ax,0xff
    push ax
    call 0x0:0xffff ; 608 KERNEL.FatalExit
    db 0x00
    push bp
    mov bp,sp
    push di
    push si
    mov si,[bp+0x6]
    xor ax,ax
    cwd
    xor bx,bx
.label2: ; 61b
    lodsb
    cmp al,0x20
    jz .label2 ; ↑
    cmp al,0x9
    jz .label2 ; ↑
    push ax
    cmp al,0x2d
    jz .label3 ; ↓
    cmp al,0x2b
    jnz .label4 ; ↓
.label3: ; 62d
    lodsb
.label4: ; 62e
    cmp al,0x39
    ja .label5 ; ↓
    sub al,0x30
    jc .label5 ; ↓
    shl bx,1
    rcl dx,1
    mov cx,bx
    mov di,dx
    shl bx,1
    rcl dx,1
    shl bx,1
    rcl dx,1
    add bx,cx
    adc dx,di
    add bx,ax
    adc dx,byte +0x0
    jmp short .label3 ; ↑
.label5: ; 651
    pop ax
    cmp al,0x2d
    xchg ax,bx
    jnz .label6 ; ↓
    neg ax
    adc dx,byte +0x0
    neg dx
.label6: ; 65e
    pop si
    pop di
    pop bp
    retf

; 662

mul32:
    push bp
    mov bp,sp
    mov ax,[bp+0x8]
    mov cx,[bp+0xc]
    or cx,ax
    mov cx,[bp+0xa]
    jnz .label0
    mov ax,[bp+0x6]
    mul cx
    pop bp
    retf 0x8
.label0: ; 67b
    push bx
    mul cx
    mov bx,ax
    mov ax,[bp+0x6]
    mul word [bp+0xc]
    add bx,ax
    mov ax,[bp+0x6]
    mul cx
    add dx,bx
    pop bx
    pop bp
    retf 0x8

; 694

FUN_1_0694:
    push bp
    mov bp,sp
    pop bp
    ret

; 699

FUN_1_0699:
    mov ax,0x14
    jmp 0x5cb
    db 0x00
    mov ax,0x2
    jmp 0x5cb
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    push si
    push di
    push ds
    pop es
    mov dx,[bp+0x6]
    mov si,0x152a
.label0: ; 6ba
    lodsw
    cmp ax,dx
    jz .label1 ; ↓
    inc ax
    xchg ax,si
    jz .label1 ; ↓
    xchg ax,di
    xor ax,ax
    mov cx,0xffff
    repne scasb
    mov si,di
    jmp short .label0 ; ↑
.label1: ; 6cf
    xchg ax,si
    pop di
    pop si
    sub bp,byte +0x2
    mov sp,bp
    pop ds
    pop bp
    dec bp
    retf 0x2

; 6dd

FUN_1_06dd:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    push di
    cmp word [0x150c],byte +0x0
    jz .label0 ; ↓
    push word [bp+0x6]
    push cs
    call 0x6a6 ; 6f3
    or ax,ax
    jz .label0 ; ↓
    xchg ax,dx
    mov di,dx
    xor ax,ax
    mov cx,0xffff
    repne scasb
    not cx
    dec cx
    mov bx,[0x14c8]
    call 0x699 ; 70b
.label0: ; 70e
    pop di
    sub bp,byte +0x2
    mov sp,bp
    pop ds
    pop bp
    dec bp
    retf 0x2

; 71a

FUN_1_071a:
    push bp
    mov bp,sp
    push bx
    push es
    push cx
    mov cx,0x1000
    xchg cx,[0x150e]
    push cx
    push ax
    call 0xf4:FUN_1_085a ; 729 1:85a
    pop bx
    pop word [0x150e]
    pop cx
    mov dx,ds
    or ax,ax
    jz .label0 ; ↓
    pop es
    pop bx
    jmp short .label1 ; ↓
.label0: ; 73e
    mov ax,cx
    jmp 0x5cb
.label1: ; 743
    mov sp,bp
    pop bp
    ret

; 747

    db 0x00
FUN_1_0748:
    push cx
    push di
    test byte [bx+0x2],0x1
    jz .label8 ; ↓
    call 0x83a ; 750
    mov di,si
    mov ax,[si]
    test al,0x1
    jz .label0 ; ↓
    sub cx,ax
    dec cx
.label0: ; 75e
    inc cx
    inc cx
    mov si,[bx+0x4]
    or si,si
    jz .label8 ; ↓
    add cx,si
    jnc .label1 ; ↓
    xor ax,ax
    mov dx,0xfff0
    jcxz .label6 ; ↓
    jmp short .label8 ; ↓
.label1: ; 774
    push ss
    pop es
    mov ax,[es:0x150e]
    cmp ax,0x1000
    jz .label4 ; ↓
    mov dx,0x8000
.label2: ; 782
    cmp dx,ax
    jc .label3 ; ↓
    shr dx,1
    jnz .label2 ; ↑
    jmp short .label7 ; ↓
.label3: ; 78c
    cmp dx,byte +0x8
    jc .label7 ; ↓
    shl dx,1
    mov ax,dx
.label4: ; 795
    dec ax
    mov dx,ax
    add ax,cx
    jnc .label5 ; ↓
    xor ax,ax
.label5: ; 79e
    not dx
    and ax,dx
.label6: ; 7a2
    push dx
    call 0x7d4 ; 7a3
    pop dx
    jnc .label9 ; ↓
    cmp dx,byte -0x10
    jz .label8 ; ↓
.label7: ; 7ae
    mov ax,0x10
    jmp short .label4 ; ↑
.label8: ; 7b3
    stc
    jmp short .label10 ; ↓
.label9: ; 7b6
    mov dx,ax
    sub dx,[bx+0x4]
    mov [bx+0x4],ax
    mov [bx+0xa],di
    mov si,[bx+0xc]
    dec dx
    mov [si],dx
    inc dx
    add si,dx
    mov word [si],0xfffe
    mov [bx+0xc],si
.label10: ; 7d1
    pop di
    pop cx
    ret

; 7d4

FUN_1_07d4:
    mov dx,ax
    test byte [bx+0x2],0x4
    jz .label0 ; ↓
    jmp short .label4 ; ↓
.label0: ; 7de
    push dx
    push cx
    push bx
    mov si,[bx+0x6]
    mov bx,[cs:0x10]
    xor cx,cx
    or dx,dx
    jnz .label1 ; ↓
    test bx,0x10
    jnz .label5 ; ↓
    inc cx
.label1: ; 7f6
    mov ax,0x2
    test bx,0x1
    jnz .label2 ; ↓
    mov ax,0x20
.label2: ; 802
    push si
    push cx
    push dx
    push ax
    call 0x0:0xffff ; 806 KERNEL.GlobalReAlloc
    or ax,ax
    jz .label5 ; ↓
    cmp ax,si
    jnz .label4 ; ↓
    push si
    call 0x0:0xffff ; 814 KERNEL.GlobalSize
    or dx,ax
    jz .label4 ; ↓
    pop bx
    pop cx
    pop dx
    mov ax,dx
    test byte [bx+0x2],0x4
    jz .label3 ; ↓
    dec dx
    mov [bx-0x2],dx
.label3: ; 82c
    clc
    jmp short .label6 ; ↓
.label4: ; 82f
    mov ax,0x12
    jmp 0x5cb
.label5: ; 835
    pop bx
    pop cx
    pop dx
    stc
.label6: ; 839
    ret

; 83a

FUN_1_083a:
    push di
    mov si,[bx+0xa]
    cmp si,[bx+0xc]
    jnz .label0 ; ↓
    mov si,[bx+0x8]
.label0: ; 846
    lodsw
    cmp ax,byte -0x2
    jz .label1 ; ↓
    mov di,si
    and al,0xfe
    add si,ax
    jmp short .label0 ; ↑
.label1: ; 854
    dec di
    dec di
    mov si,di
    pop di
    ret

; 85a

FUN_1_085a:
    inc bp
    push bp
    mov bp,sp
    push ds
    sub sp,byte +0x4
    cmp word [bp+0x6],byte +0x0
    jnz .label0 ; ↓
    mov word [bp+0x6],0x1
.label0: ; 86d
    mov ax,0xffff
    push ax
    call 0x0:0x907 ; 871 KERNEL.LockSegment
    mov ax,0x20
    push ax
    push word [bp+0x6]
    call 0x0:0xffff ; 87d KERNEL.LocalAlloc
    mov [bp-0x4],ax
    mov ax,0xffff
    push ax
    call 0x0:0x92f ; 889 KERNEL.UnlockSegment
    cmp word [bp-0x4],byte +0x0
    jnz .label1 ; ↓
    mov ax,[0x1512]
    or ax,[0x1510]
    jz .label1 ; ↓
    push word [bp+0x6]
    call far [0x1510] ; 8a0
    add sp,byte +0x2
    or ax,ax
    jnz .label0 ; ↑
.label1: ; 8ab
    mov ax,[bp-0x4]
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 8b6

FUN_1_08b6:
    inc bp
    push bp
    mov bp,sp
    push ds
    cmp word [bp+0x6],byte +0x0
    jz .label0 ; ↓
    push word [bp+0x6]
    call 0x0:0xffff ; 8c4 KERNEL.LocalFree
.label0: ; 8c9
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 8d0

FUN_1_08d0:
    inc bp
    push bp
    mov bp,sp
    push ds
    sub sp,byte +0x6
    cmp word [bp+0x6],byte +0x0
    jnz .label0 ; ↓
    push word [bp+0x8]
    call 0x8f8:FUN_1_085a ; 8e1 1:85a
    add sp,byte +0x2
    jmp short .label4 ; ↓
    nop
.label0: ; 8ec
    cmp word [bp+0x8],byte +0x0
    jnz .label1 ; ↓
    push word [bp+0x6]
    call 0x72c:FUN_1_08b6 ; 8f5 1:8b6
    add sp,byte +0x2
    xor ax,ax
    jmp short .label4 ; ↓
    nop
.label1: ; 902
    mov ax,0xffff
    push ax
    call 0x0:0xffff ; 906 KERNEL.LockSegment
    push word [bp+0x6]
    cmp word [bp+0x8],byte +0x0
    jz .label2 ; ↓
    mov ax,[bp+0x8]
    jmp short .label3 ; ↓
    nop
.label2: ; 91a
    mov ax,0x1
.label3: ; 91d
    push ax
    mov ax,0x62
    push ax
    call 0x0:0xffff ; 922 KERNEL.LocalReAlloc
    mov [bp-0x4],ax
    mov ax,0xffff
    push ax
    call 0x0:0xffff ; 92e KERNEL.UnlockSegment
    mov ax,[bp-0x4]
.label4: ; 936
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 93e

FUN_1_093e:
    inc bp
    push bp
    mov bp,sp
    push ds
    push word [bp+0x6]
    call 0x0:0xffff ; 946 KERNEL.LocalSize
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 951

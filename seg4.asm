; 0

GetTileRect:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0xa
    push di
    push si
    mov ax,[bp+0x6]
    mov bx,[0x1680]
    sub ax,[bx+0xa24]
    sub ax,[bx+0xa2c]
    shl ax,byte 0x5
    mov [bp-0xa],ax
    mov ax,[bp+0x8]
    sub ax,[bx+0xa26]
    sub ax,[bx+0xa2e]
    shl ax,byte 0x5
    mov [bp-0x8],ax
    mov ax,[bp-0xa]
    add ax,0x20
    mov [bp-0x6],ax
    mov ax,[bp-0x8]
    add ax,0x20
    mov [bp-0x4],ax
    mov ax,0x1674
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
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 5e

FUN_4_005e:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    push si
    xor si,si
.label0: ; 6e
    mov bx,[0x1680]
    mov byte [bx+si+0x400],0x0
    mov bx,[0x1680]
    add bx,si
    mov al,[bx+0x400]
    mov [bx],al
    inc si
    cmp si,0x400
    jl .label0 ; ↑
    mov bx,[0x1680]
    mov word [bx+0x91e],0x0
    mov bx,[0x1680]
    mov word [bx+0x928],0x0
    mov bx,[0x1680]
    mov word [bx+0x932],0x0
    mov bx,[0x1680]
    mov word [bx+0x93c],0x0
    mov bx,[0x1680]
    mov word [bx+0x946],0x0
    mov bx,[0x1680]
    mov word [bx+0x950],0x0
    mov bx,[0x1680]
    mov word [bx+0x81c],0x0
    pop si
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; d8

FUN_4_00d8:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    push si
    mov si,[bp+0x6]
    push ds
    push word 0x2d4
    push si
    call 0xfd:ReadLevelData ; ee 4:a56 ReadLevelData
    add sp,byte +0x6
    or ax,ax
    jnz .label0 ; ↓
    call 0x336:FUN_4_005e ; fa 4:5e
    push byte +0x10
    push ds
    push word 0x966
    push word [0x10]
    call 0x236:0x0 ; 109 2:0 ShowMessageBox
    add sp,byte +0x8
    push word [0x10]
    push word 0x111
    push byte +0x6a
    push byte +0x0
    push byte +0x0
    call 0x0:0xffff ; 11e USER.PostMessage
.label0: ; 123
    mov bx,[0x1680]
    mov [bx+0x800],si
    pop si
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 134

UpdateWindowTitle:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,0x8c
    mov bx,[0x1680]
    add bx,0x95a
    mov [bp-0x8c],bx
    cmp byte [bx],0x0
    jz .label0 ; ↓
    mov ax,bx
    jmp short .label1 ; ↓
    nop
.label0: ; 158
    mov ax,0x98e
.label1: ; 15b
    mov cx,ax
    mov [bp-0x8],ds
    push ds
    push cx
    cmp byte [bx],0x0
    jz .label2 ; ↓
    mov ax,0x98f
    jmp short .label3 ; ↓
.label2: ; 16c
    mov ax,0x992
.label3: ; 16f
    mov [bp-0x4],ds
    push ds
    push ax
    push ds
    push word 0x68
    push ds
    push word 0x993
    lea ax,[bp-0x8a]
    push ss
    push ax
    call 0x0:0xffff ; 182 USER._wsprintf
    add sp,byte +0x14
    push word [bp+0x6]
    lea ax,[bp-0x8a]
    push ss
    push ax
    call 0x0:0xffff ; 193 USER.SetWindowText
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 1a0

UpdateNextPrevMenuItems:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x4
    push si
    mov si,[bp+0x6]
    push word [0x26]
    push byte +0x6f
    mov [bp-0x4],si
    cmp si,byte +0x1
    jng .label0 ; ↓
    xor ax,ax
    jmp short .label1 ; ↓
    nop
.label0: ; 1c4
    mov ax,0x1
.label1: ; 1c7
    push ax
    call 0x0:0x1f0 ; 1c8 USER.EnableMenuItem
    mov ax,[bp-0x4]
    mov bx,[0x1680]
    cmp [bx+0x802],ax
    jg .label2 ; ↓
    cmp word [0xa34],byte +0x0
    jnz .label2 ; ↓
    mov cx,0x1
    jmp short .label3 ; ↓
.label2: ; 1e6
    xor cx,cx
.label3: ; 1e8
    push word [0x26]
    push byte +0x6e
    push cx
    call 0x0:0xffff ; 1ef USER.EnableMenuItem
    pop si
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 1fc

ResetTimerAndChipCount:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    mov bx,[0x1680]
    mov ax,[bx+0x804]
    mov [0x1694],ax
    mov ax,[bx+0x806]
    mov [0x1692],ax
    push word [0x18]
    push byte +0x2
    cmp word [0x1694],byte +0x1
    sbb ax,ax
    and ax,0x2
    push ax
    call 0x0:0xffff ; 22c USER.SetWindowWord
    push byte +0x1
    call 0x398:0x16fa ; 233 2:16fa
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 240

FUN_4_0240:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0xe
    mov bx,[0x1680]
    mov ax,[bx+0x922]
    mov [bp-0x4],ax
    or ax,ax
    jz .label0 ; ↓
    push ax
    call 0x0:0x280 ; 25d KERNEL.GlobalUnlock
    mov bx,[0x1680]
    push word [bx+0x922]
    call 0x0:0x28d ; 26a KERNEL.GlobalFree
.label0: ; 26f
    mov bx,[0x1680]
    mov ax,[bx+0x92c]
    mov [bp-0x6],ax
    or ax,ax
    jz .label1 ; ↓
    push ax
    call 0x0:0x2a2 ; 27f KERNEL.GlobalUnlock
    mov bx,[0x1680]
    push word [bx+0x92c]
    call 0x0:0x2af ; 28c KERNEL.GlobalFree
.label1: ; 291
    mov bx,[0x1680]
    mov ax,[bx+0x936]
    mov [bp-0x8],ax
    or ax,ax
    jz .label2 ; ↓
    push ax
    call 0x0:0x2c4 ; 2a1 KERNEL.GlobalUnlock
    mov bx,[0x1680]
    push word [bx+0x936]
    call 0x0:0x2d1 ; 2ae KERNEL.GlobalFree
.label2: ; 2b3
    mov bx,[0x1680]
    mov ax,[bx+0x940]
    mov [bp-0xa],ax
    or ax,ax
    jz .label3 ; ↓
    push ax
    call 0x0:0x2e6 ; 2c3 KERNEL.GlobalUnlock
    mov bx,[0x1680]
    push word [bx+0x940]
    call 0x0:0x2f3 ; 2d0 KERNEL.GlobalFree
.label3: ; 2d5
    mov bx,[0x1680]
    mov ax,[bx+0x94a]
    mov [bp-0xc],ax
    or ax,ax
    jz .label4 ; ↓
    push ax
    call 0x0:0x308 ; 2e5 KERNEL.GlobalUnlock
    mov bx,[0x1680]
    push word [bx+0x94a]
    call 0x0:0x315 ; 2f2 KERNEL.GlobalFree
.label4: ; 2f7
    mov bx,[0x1680]
    mov ax,[bx+0x954]
    mov [bp-0xe],ax
    or ax,ax
    jz .label5 ; ↓
    push ax
    call 0x0:0xffff ; 307 KERNEL.GlobalUnlock
    mov bx,[0x1680]
    push word [bx+0x954]
    call 0x0:0xffff ; 314 KERNEL.GlobalFree
.label5: ; 319
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 320

FUN_4_0320:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x4
    cmp word [bp+0x6],byte +0x0
    jnz .label0 ; ↓
    call 0xffff:FUN_4_0240 ; 333 4:240
.label0: ; 338
    mov bx,[0x1680]
    lea dx,[bx+0xa42]
    cmp dx,bx
    jna .label2 ; ↓
.label1: ; 344
    mov word [bx],0x0
    add bx,byte +0x2
    cmp bx,dx
    jc .label1 ; ↑
.label2: ; 34f
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 356

FUN_4_0356:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0xa
    push di
    push si
    mov si,[bp+0x8]
    mov bx,[0x1680]
    mov ax,[bx+0x810]
    mov [bp-0x6],ax
    push byte +0x0
    push byte +0x0
    push word 0x7f02
    call 0x0:0xffff ; 37a USER.LoadCursor
    mov di,ax
    push word [0x12]
    call 0x0:0xffff ; 385 USER.SetCapture
    push di
    call 0x0:0xffff ; 38b USER.SetCursor
    mov [bp-0x8],ax
    push byte +0x1
    call 0xffff:0x176e ; 395 2:176e
    add sp,byte +0x2
    push byte +0x0
    call 0xffff:0x1734 ; 39f 3:1734 ResetInventory
    add sp,byte +0x2
    or si,si
    jz .label1 ; ↓
    mov bx,[0x1680]
    cmp word [bx+0xa34],byte +0x1e
    jng .label1 ; ↓
    cmp word [bp+0x6],0x90
    jz .label1 ; ↓
    cmp word [bp+0x6],0x95
    jz .label1 ; ↓
    inc word [bx+0xa32]
    mov bx,[0x1680]
    cmp word [bx+0xa32],byte +0xa
    jl .label1 ; ↓
    push byte +0x24
    push ds
    push word 0x90c
    push word [0x10]
    call 0x550:0x0 ; 3dd 2:0 ShowMessageBox
    add sp,byte +0x8
    cmp ax,0x6
    jnz .label0 ; ↓
    inc word [bp+0x6]
    xor si,si
    jmp short .label1 ; ↓
    nop
.label0: ; 3f2
    mov bx,[0x1680]
    mov word [bx+0xa32],0x0
.label1: ; 3fc
    mov di,[bp-0xa]
    or si,si
    jz .label2 ; ↓
    mov bx,[0x1680]
    mov di,[bx+0xa30]
    mov ax,[bx+0xa32]
    mov [bp-0x4],ax
.label2: ; 412
    push byte +0x0
    call 0x43c:FUN_4_0320 ; 414 4:320
    add sp,byte +0x2
    or si,si
    jz .label3 ; ↓
    lea ax,[di+0x1]
    mov bx,[0x1680]
    mov [bx+0xa30],ax
    mov ax,[bp-0x4]
    mov bx,[0x1680]
    mov [bx+0xa32],ax
.label3: ; 436
    push word [bp+0x6]
    call 0x53b:FUN_4_00d8 ; 439 4:d8
    add sp,byte +0x2
    cmp word [0x24],byte +0x0
    jnz .label4 ; ↓
    or si,si
    jnz .label4 ; ↓
    mov bx,[0x1680]
    push word [bx+0x800]
    call 0xffff:0x308 ; 454 8:308
    add sp,byte +0x2
.label4: ; 45c
    call 0x3a2:0x54c ; 45c 3:54c InitBoard
    cmp word [0xa34],byte +0x0
    jz .label5 ; ↓
    mov bx,[0x1680]
    mov word [bx+0xa26],0x0
    mov bx,[0x1680]
    mov ax,[bx+0xa26]
    mov [bx+0xa24],ax
    mov bx,[0x1680]
    mov word [bx+0xa2e],0x0
    mov bx,[0x1680]
    mov ax,[bx+0xa2e]
    mov [bx+0xa2c],ax
    mov bx,[0x1680]
    mov word [bx+0xa28],0x20
    mov bx,[0x1680]
    mov word [bx+0xa2a],0x20
    jmp .label10 ; ↓
    nop
.label5: ; 4ac
    mov bx,[0x1680]
    mov word [bx+0xa2a],0x9
    mov bx,[0x1680]
    mov ax,[bx+0xa2a]
    mov [bx+0xa28],ax
    mov bx,[0x1680]
    mov word [bx+0xa2e],0x10
    mov bx,[0x1680]
    mov ax,[bx+0xa2e]
    mov [bx+0xa2c],ax
    mov bx,[0x1680]
    mov ax,[bx+0xa28]
    mov cx,ax
    sub ax,0x20
    neg ax
    mov dx,ax
    mov ax,cx
    mov di,dx
    cwd
    sub ax,dx
    sar ax,1
    sub ax,[bx+0x808]
    neg ax
    or ax,ax
    jnl .label6 ; ↓
    xor ax,ax
.label6: ; 4fe
    cmp ax,di
    jng .label7 ; ↓
    mov ax,di
.label7: ; 504
    mov [bx+0xa24],ax
    mov bx,[0x1680]
    mov ax,[bx+0xa2a]
    mov cx,ax
    sub ax,0x20
    neg ax
    mov dx,ax
    mov ax,cx
    mov di,dx
    cwd
    sub ax,dx
    sar ax,1
    sub ax,[bx+0x80a]
    neg ax
    or ax,ax
    jnl .label8 ; ↓
    xor ax,ax
.label8: ; 52e
    cmp ax,di
    jng .label9 ; ↓
    mov ax,di
.label9: ; 534
    mov [bx+0xa26],ax
.label10: ; 538
    call 0x561:ResetTimerAndChipCount ; 538 4:1fc ResetTimerAndChipCount
    mov bx,[0x1680]
    mov word [bx+0x810],0x1
    cmp word [bp-0x6],byte +0x0
    jnz .label11 ; ↓
    call 0x59e:0x17a2 ; 54d 2:17a2 PauseTimer
.label11: ; 552
    mov bx,[0x1680]
    push word [bx+0x800]
    push word [0x10]
    call 0x571:UpdateWindowTitle ; 55e 4:134 UpdateWindowTitle
    add sp,byte +0x4
    mov bx,[0x1680]
    push word [bx+0x800]
    call 0xf1:UpdateNextPrevMenuItems ; 56e 4:1a0 UpdateNextPrevMenuItems
    add sp,byte +0x2
    mov bx,[0x1680]
    mov word [bx+0xa2c],0x0
    mov bx,[0x1680]
    mov word [bx+0xa2e],0x0
    push word [0x12]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0xffff ; 594 USER.InvalidateRect
    push byte +0x3f
    call 0x5b0:0xcbe ; 59b 2:cbe
    add sp,byte +0x2
    or si,si
    jnz .label12 ; ↓
    push si
    push si
    push si
    push word [bp+0x6]
    call 0x5c3:0x1adc ; 5ad 2:1adc
    add sp,byte +0x8
    or ax,ax
    jnz .label12 ; ↓
    push ax
    push ax
    push byte -0x1
    push word [bp+0x6]
    call 0x5ce:0x1c1c ; 5c0 2:1c1c
    add sp,byte +0x8
    push word 0xc8
    call 0x5e1:0x198e ; 5cb 2:198e GetIniInt
    add sp,byte +0x2
    cmp ax,[bp+0x6]
    jnl .label12 ; ↓
    push word [bp+0x6]
    push word 0xc8
    call 0x10c:0x19ca ; 5de 2:19ca StoreIniInt
    add sp,byte +0x4
.label12: ; 5e6
    push word [bp-0x8]
    call 0x0:0x38c ; 5e9 USER.SetCursor
    call 0x0:0xffff ; 5ee USER.ReleaseCapture
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 5fc

FUN_4_05fc:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
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
    mov ax,[bp+0x6]
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
    mov si,[bp+0xc]
.label0: ; 652
    mov di,[bp-0xa]
    cmp [bp-0x14],di
    jng .label4 ; ↓
    mov si,[bp-0xc]
    mov dx,[bp+0xc]
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
    mov si,[bp+0xc]
.label4: ; 69f
    add cx,byte +0x20
    dec word [bp-0xe]
    jnz .label0 ; ↑
.label5: ; 6a7
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 6b0

DecodePassword:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    push si
    mov si,[bp+0x6]
    cmp byte [si],0x0
    jz .label1 ; ↓
.label0: ; 6c6
    xor byte [si],0x99
    inc si
    cmp byte [si],0x0
    jnz .label0 ; ↑
.label1: ; 6cf
    pop si
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 6d8

DecodeLevelFields:
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
    mov si,[bp+0x6]
    mov ax,[bp+0x8]
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
    jmp .label25 ; ↓
.label1: ; 713
    shl ax,1
    xchg ax,bx
    jmp [cs:bx+0x71c]
    nop
    dw .label2 ; ↓
    dw 0x73e
    dw .label3 ; ↓
    dw .label6 ; ↓
    dw .label12 ; ↓
    dw .label17 ; ↓
    dw .label19 ; ↓
    dw .label21 ; ↓
    dw .label25 ; ↓
    dw .label23 ; ↓
.label2: ; 730
; 0x730
    db 0x8b,0x4,0x8b ; 0000072F  088B048B          or [bp+di-0x74fc],cl
    push ds
    adc byte [0x8789],0x4
    or cl,ch
    sti
    add [bx+si+0x48b],dx
    mov bx,[0x1680]
    mov [bx+0x806],ax
    jmp .label25 ; ↓
    nop
.label3: ; 74c
    cmp byte [bp-0x9],0x40
    jna .label4 ; ↓
    mov byte [si+0x3f],0x0
.label4: ; 756
    mov ax,[0x1680]
    add ax,0x95a
.label5: ; 75c
    push ds
    push ax
    push ds
    push si
    call 0x0:0xffff ; 760 KERNEL.lstrcpy
    jmp .label25 ; ↓
.label6: ; 768
    mov [bp-0x6],si
    mov al,[bp-0x9]
    mov cl,0xa
    sub ah,ah
    div cl
    sub ah,ah
    mov bx,[0x1680]
    mov [bx+0x93c],ax
    mov bx,[0x1680]
    mov ax,[bx+0x93e]
    cmp [bx+0x93c],ax
    jg .label7 ; ↓
    jmp .label25 ; ↓
.label7: ; 78f
    push byte +0xa
    push word [bx+0x93c]
    lea ax,[bx+0x93e]
    push ax
    lea ax,[bx+0x942]
    push ax
    lea ax,[bx+0x940]
    push ax
    call 0x846:0x1a4 ; 7a4 3:1a4 GrowArray
    add sp,byte +0xa
    or ax,ax
    jz .label11 ; ↓
    mov word [bp-0x8],0x0
    mov bx,[0x1680]
    cmp word [bx+0x93c],byte +0x0
    jg .label8 ; ↓
    jmp .label25 ; ↓
.label8: ; 7c3
    mov [bp+0x6],si
    mov word [bp-0x4],0x0
.label9: ; 7cb
    les bx,[bx+0x942]
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
    mov bx,[0x1680]
    cmp [bx+0x93c],ax
    jg .label9 ; ↑
.label10: ; 7f6
    mov si,[bp+0x6]
    jmp .label25 ; ↓
.label11: ; 7fc
    mov bx,[0x1680]
    mov word [bx+0x93c],0x0
    jmp .label25 ; ↓
    nop
.label12: ; 80a
    mov [bp-0x6],si
    mov al,[bp-0x9]
    shr al,byte 0x3
    sub ah,ah
    mov bx,[0x1680]
    mov [bx+0x946],ax
    mov bx,[0x1680]
    mov ax,[bx+0x948]
    cmp [bx+0x946],ax
    jg .label13 ; ↓
    jmp .label25 ; ↓
.label13: ; 82e
    push byte +0x8
    push word [bx+0x946]
    lea ax,[bx+0x948]
    push ax
    lea ax,[bx+0x94c]
    push ax
    lea ax,[bx+0x94a]
    push ax
    call 0x45f:0x1a4 ; 843 3:1a4 GrowArray
    add sp,byte +0xa
    or ax,ax
    jz .label16 ; ↓
    mov word [bp-0x8],0x0
    mov bx,[0x1680]
    cmp word [bx+0x946],byte +0x0
    jg .label14 ; ↓
    jmp .label25 ; ↓
.label14: ; 862
    mov [bp+0x6],si
    mov word [bp-0x4],0x0
.label15: ; 86a
    les bx,[bx+0x94c]
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
    mov bx,[0x1680]
    cmp [bx+0x946],ax
    jg .label15 ; ↑
    jmp .label10 ; ↑
    nop
.label16: ; 898
    mov bx,[0x1680]
    mov word [bx+0x946],0x0
    jmp .label25 ; ↓
    nop
.label17: ; 8a6
    cmp byte [bp-0x9],0xa
    jna .label18 ; ↓
    mov byte [si+0x9],0x0
.label18: ; 8b0
    mov ax,[0x1680]
    add ax,0xa1a
    push ds
    push ax
    push ds
    push si
    call 0x0:0x761 ; 8ba KERNEL.lstrcpy
    mov ax,[0x1680]
    add ax,0xa1a
    push ax
    call 0xa3e:DecodePassword ; 8c6 4:6b0 DecodePassword
    add sp,byte +0x2
    jmp short .label25 ; ↓
.label19: ; 8d0
    cmp byte [bp-0x9],0x80
    jna .label20 ; ↓
    mov byte [si+0x7f],0x0
.label20: ; 8da
    mov ax,[0x1680]
    add ax,0x99a
    jmp .label5 ; ↑
    nop
.label21: ; 8e4
    cmp byte [bp-0x9],0xa
    jna .label22 ; ↓
    mov byte [si+0x9],0x0
.label22: ; 8ee
    mov ax,[0x1680]
    add ax,0xa1a
    jmp .label5 ; ↑
    nop
.label23: ; 8f8
    mov di,si
    mov al,[bp-0x9]
    shr al,1
    sub ah,ah
    mov bx,[0x1680]
    mov [bx+0x81c],ax
    xor dx,dx
    mov bx,[0x1680]
    cmp [bx+0x81c],dx
    jng .label25 ; ↓
    mov [bp+0x6],si
    xor bx,bx
.label24: ; 91a
    mov ax,[di]
    mov si,[0x1680]
    mov [bx+si+0x81e],ax
    add bx,byte +0x2
    add di,byte +0x2
    inc dx
    mov si,[0x1680]
    cmp [si+0x81c],dx
    jg .label24 ; ↑
    jmp .label10 ; ↑
.label25: ; 938
    mov al,[bp-0x9]
    sub ah,ah
    add si,ax
    cmp si,[bp-0xc]
    jnc .label26 ; ↓
    jmp .label0 ; ↑
.label26: ; 947
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 950

FUN_4_0950:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x4
    push si
    mov si,[bp+0x6]
    push si
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call 0x0:0x988 ; 969 KERNEL._lread
    cmp ax,0x2
    jnc .label1 ; ↓
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
    call 0x0:0x9a0 ; 987 KERNEL._lread
    cmp ax,0x2
    jc .label0 ; ↑
    cmp word [bp-0x4],byte +0x2
    jnz .label0 ; ↑
    push si
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call 0x0:0x9d7 ; 99f KERNEL._lread
    cmp ax,0x2
    jc .label0 ; ↑
    mov ax,[bp-0x4]
.label2: ; 9ac
    pop si
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 9b4

FUN_4_09b4:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x4
    push di
    push si
    mov di,0x1
    cmp [bp+0x8],di
    jng .label3 ; ↓
    mov si,[bp+0x6]
.label0: ; 9ce
    push si
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call 0x0:0xac6 ; 9d6 KERNEL._lread
    cmp ax,0x2
    jc .label2 ; ↓
    push si
    push byte +0x0
    push word [bp-0x4]
    push byte +0x1
    call 0x0:0xffff ; 9e8 KERNEL._llseek
    cmp ax,0xffff
    jnz .label1 ; ↓
    cmp dx,ax
    jz .label2 ; ↓
.label1: ; 9f6
    inc di
    cmp di,[bp+0x8]
    jl .label0 ; ↑
    jmp short .label3 ; ↓
.label2: ; 9fe
    xor ax,ax
    jmp short .label4 ; ↓
.label3: ; a02
    mov ax,0x1
.label4: ; a05
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; a0e

FUN_4_0a0e:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,0x8a
    push di
    push si
    push ds
    push word 0x2d4
    lea ax,[bp-0x8a]
    push ss
    push ax
    push byte +0x0
    call 0x0:0xa75 ; a2a KERNEL.OpenFile
    mov di,ax
    cmp di,byte -0x1
    jnz .label0 ; ↓
    xor ax,ax
    jmp short .label1 ; ↓
.label0: ; a3a
    push di
    call 0xa88:FUN_4_0950 ; a3b 4:950
    add sp,byte +0x2
    mov si,ax
    push di
    call 0x0:0xffff ; a46 KERNEL._lclose
    mov ax,si
.label1: ; a4d
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; a56

ReadLevelData:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,0x490
    push di
    push si
    push word [bp+0xa]
    push word [bp+0x8]
    lea ax,[bp-0x90]
    push ss
    push ax
    push byte +0x20
    call 0x0:0xffff ; a74 KERNEL.OpenFile
    mov [bp-0x4],ax
    inc ax
    jnz .label0 ; ↓
    jmp .label14 ; ↓
.label0: ; a82
    push word [bp-0x4]
    call 0xaaf:FUN_4_0950 ; a85 4:950
    add sp,byte +0x2
    mov si,ax
    mov bx,[0x1680]
    mov [bx+0x802],si
    or si,si
    jnz .label1 ; ↓
    jmp .label13 ; ↓
.label1: ; a9e
    mov di,[bp+0x6]
    cmp si,di
    jnc .label2 ; ↓
    jmp .label13 ; ↓
.label2: ; aa8
    push di
    push word [bp-0x4]
    call 0x417:FUN_4_09b4 ; aac 4:9b4
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
    call 0x0:0xadd ; ac5 KERNEL._lread
    cmp ax,0x2
    jnc .label4 ; ↓
    jmp .label13 ; ↓
.label4: ; ad2
    push word [bp-0x4]
    lea ax,[bp-0x6]
    push ss
    push ax
    push byte +0x2
    call 0x0:0xaff ; adc KERNEL._lread
    cmp ax,0x2
    jnc .label5 ; ↓
    jmp .label13 ; ↓
.label5: ; ae9
    cmp di,[bp-0x6]
    jz .label6 ; ↓
    jmp .label13 ; ↓
.label6: ; af1
    push word [bp-0x4]
    mov ax,[0x1680]
    add ax,0x804
    push ds
    push ax
    push byte +0x2
    call 0x0:0xffff ; afe KERNEL._lread
    cmp ax,0x2
    jnc .label7 ; ↓
    jmp .label13 ; ↓
.label7: ; b0b
    push word [bp-0x4]
    mov ax,[0x1680]
    add ax,0x806
    push ds
    push ax
    push byte +0x2
    call 0x0:0xb30 ; b18 KERNEL._lread
    cmp ax,0x2
    jnc .label8 ; ↓
    jmp .label13 ; ↓
.label8: ; b25
    push word [bp-0x4]
    lea ax,[bp-0x8]
    push ss
    push ax
    push byte +0x2
    call 0x0:0xb56 ; b2f KERNEL._lread
    cmp ax,0x2
    jnc .label9 ; ↓
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
    call 0x0:0xb6f ; b55 KERNEL._lread
    cmp ax,0x2
    jnc .label11 ; ↓
    jmp .label13 ; ↓
.label11: ; b62
    push word [bp-0x4]
    lea ax,[bp-0x490]
    push ss
    push ax
    push word [bp-0x6]
    call 0x0:0xba1 ; b6e KERNEL._lread
    cmp ax,[bp-0x6]
    jnc .label12 ; ↓
    jmp .label13 ; ↓
.label12: ; b7b
    push byte +0x20
    push byte +0x20
    push word [0x1680]
    push word [bp-0x8]
    push word [bp-0x6]
    lea ax,[bp-0x490]
    push ax
    call 0xbd9:FUN_4_05fc ; b8e 4:5fc
    add sp,byte +0xc
    push word [bp-0x4]
    lea ax,[bp-0x6]
    push ss
    push ax
    push byte +0x2
    call 0x0:0xbb7 ; ba0 KERNEL._lread
    cmp ax,0x2
    jc .label13 ; ↓
    push word [bp-0x4]
    lea ax,[bp-0x490]
    push ss
    push ax
    push word [bp-0x6]
    call 0x0:0xbe9 ; bb6 KERNEL._lread
    cmp ax,[bp-0x6]
    jc .label13 ; ↓
    push byte +0x20
    push byte +0x20
    mov ax,[0x1680]
    add ah,0x4
    push ax
    push word [bp-0x8]
    push word [bp-0x6]
    lea ax,[bp-0x490]
    push ax
    call 0xc13:FUN_4_05fc ; bd6 4:5fc
    add sp,byte +0xc
    push word [bp-0x4]
    lea ax,[bp-0x6]
    push ss
    push ax
    push byte +0x2
    call 0x0:0xbff ; be8 KERNEL._lread
    cmp ax,0x2
    jc .label13 ; ↓
    push word [bp-0x4]
    lea ax,[bp-0x490]
    push ss
    push ax
    push word [bp-0x6]
    call 0x0:0xc52 ; bfe KERNEL._lread
    cmp ax,[bp-0x6]
    jc .label13 ; ↓
    push word [bp-0x6]
    lea ax,[bp-0x490]
    push ax
    call 0xd87:DecodeLevelFields ; c10 4:6d8 DecodeLevelFields
    add sp,byte +0x4
    push word [bp-0x4]
    call 0x0:0xc2a ; c1b KERNEL._lclose
    mov ax,0x1
    jmp short .label15 ; ↓
    nop
.label13: ; c26
    push word [bp-0x4]
    call 0x0:0xe2c ; c29 KERNEL._lclose
.label14: ; c2e
    xor ax,ax
.label15: ; c30
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; c3a

FUN_4_0c3a:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x4
    push word [bp+0x6]
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call 0x0:0xc69 ; c51 KERNEL._lread
    cmp ax,0x2
    jnc .label0 ; ↓
    jmp .label7 ; ↓
.label0: ; c5e
    push word [bp+0x6]
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call 0x0:0xc8b ; c68 KERNEL._lread
    cmp ax,0x2
    jnc .label1 ; ↓
    jmp .label7 ; ↓
.label1: ; c75
    mov ax,[bp+0x8]
    cmp [bp-0x4],ax
    jz .label2 ; ↓
    jmp .label7 ; ↓
.label2: ; c80
    push word [bp+0x6]
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call 0x0:0xca2 ; c8a KERNEL._lread
    cmp ax,0x2
    jnc .label3 ; ↓
    jmp .label7 ; ↓
.label3: ; c97
    push word [bp+0x6]
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call 0x0:0xcb9 ; ca1 KERNEL._lread
    cmp ax,0x2
    jnc .label4 ; ↓
    jmp .label7 ; ↓
.label4: ; cae
    push word [bp+0x6]
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call 0x0:0xcdc ; cb8 KERNEL._lread
    cmp ax,0x2
    jnc .label5 ; ↓
    jmp .label7 ; ↓
.label5: ; cc5
    cmp word [bp-0x4],byte +0x0
    jz .label6 ; ↓
    cmp word [bp-0x4],byte +0x1
    jnz .label7 ; ↓
.label6: ; cd1
    push word [bp+0x6]
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call 0x0:0xcff ; cdb KERNEL._lread
    cmp ax,0x2
    jc .label7 ; ↓
    push word [bp+0x6]
    push byte +0x0
    push word [bp-0x4]
    push byte +0x1
    call 0x0:0xd13 ; cef KERNEL._llseek
    push word [bp+0x6]
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call 0x0:0xd22 ; cfe KERNEL._lread
    cmp ax,0x2
    jc .label7 ; ↓
    push word [bp+0x6]
    push byte +0x0
    push word [bp-0x4]
    push byte +0x1
    call 0x0:0x9e9 ; d12 KERNEL._llseek
    push word [bp+0x6]
    lea ax,[bp-0x4]
    push ss
    push ax
    push byte +0x2
    call 0x0:0xd36 ; d21 KERNEL._lread
    cmp ax,0x2
    jc .label7 ; ↓
    push word [bp+0x6]
    push ds
    push word [bp+0xa]
    push word [bp-0x4]
    call 0x0:0x96a ; d35 KERNEL._lread
    cmp ax,[bp-0x4]
    jc .label7 ; ↓
    mov ax,[bp-0x4]
    mov bx,[bp+0xc]
    mov [bx],ax
    mov ax,0x1
    jmp short .label8 ; ↓
    nop
    nop
.label7: ; d4e
    xor ax,ax
.label8: ; d50
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; d58

FUN_4_0d58:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,0x222
    push di
    push si
    push ds
    push word 0x2d4
    lea ax,[bp-0x92]
    push ss
    push ax
    push byte +0x20
    call 0x0:0xa2b ; d74 KERNEL.OpenFile
    mov di,ax
    cmp di,byte -0x1
    jnz .label0 ; ↓
    jmp .label9 ; ↓
.label0: ; d83
    push di
    call 0xda4:FUN_4_0950 ; d84 4:950
    add sp,byte +0x2
    mov si,ax
    or si,si
    jnz .label1 ; ↓
    jmp .label8 ; ↓
.label1: ; d95
    cmp si,[bp+0x6]
    jnc .label2 ; ↓
    jmp .label8 ; ↓
.label2: ; d9d
    push word [bp+0x6]
    push di
    call 0xdc5:FUN_4_09b4 ; da1 4:9b4
    add sp,byte +0x4
    or ax,ax
    jnz .label3 ; ↓
    jmp .label8 ; ↓
.label3: ; db0
    mov word [bp-0xa],0x190
    lea ax,[bp-0xa]
    push ax
    lea ax,[bp-0x222]
    push ax
    push word [bp+0x6]
    push di
    call 0xe23:FUN_4_0c3a ; dc2 4:c3a
    add sp,byte +0x8
    or ax,ax
    jz .label8 ; ↓
    mov si,[bp-0xa]
    lea dx,[bp+si-0x222]
    lea si,[bp-0x222]
    cmp dx,si
    jna .label8 ; ↓
    mov [bp-0x6],dx
    mov [bp-0x8],di
.label4: ; de3
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
    jc .label4 ; ↑
    jmp short .label8 ; ↓
    nop
.label5: ; e02
    cmp byte [bp-0x4],0xa
    jna .label6 ; ↓
    mov byte [si+0x9],0x0
.label6: ; e0c
    push ds
    push word [bp+0x8]
    push ds
    push si
    call 0x0:0x8bb ; e12 KERNEL.lstrcpy
    cmp byte [bp-0x3],0x8
    jz .label7 ; ↓
    push word [bp+0x8]
    call 0xe7d:DecodePassword ; e20 4:6b0 DecodePassword
    add sp,byte +0x2
.label7: ; e28
    push word [bp-0x8]
    call 0x0:0xe38 ; e2b KERNEL._lclose
    mov ax,0x1
    jmp short .label10 ; ↓
    nop
.label8: ; e36
    push di
    call 0x0:0xa47 ; e37 KERNEL._lclose
.label9: ; e3c
    xor ax,ax
.label10: ; e3e
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; e48

FUN_4_0e48:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,0x82
    push si
    mov si,[bp+0x6]
    cmp si,byte +0x1
    jng .label1 ; ↓
    push byte +0x0
    push byte +0x0
    lea ax,[bp-0x42]
    push ax
    push si
    call 0x3e0:0x1adc ; e68 2:1adc
    add sp,byte +0x8
    or ax,ax
    jz .label0 ; ↓
    lea ax,[bp-0x82]
    push ax
    push si
    call 0xec0:FUN_4_0d58 ; e7a 4:d58
    add sp,byte +0x4
    or ax,ax
    jz .label0 ; ↓
    lea ax,[bp-0x42]
    push ss
    push ax
    lea ax,[bp-0x82]
    push ss
    push ax
    call 0x0:0xffff ; e91 USER.lstrcmpi
    or ax,ax
    jz .label1 ; ↓
.label0: ; e9a
    xor ax,ax
    jmp short .label2 ; ↓
.label1: ; e9e
    mov ax,0x1
.label2: ; ea1
    pop si
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; eaa

FUN_4_0eaa:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,0x23e
    push di
    push si
    mov di,[bp+0x6]
    call 0x8c9:FUN_4_0a0e ; ebd 4:a0e
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
    call 0x110c:0x1adc ; ee0 2:1adc
    add sp,byte +0x8
    or ax,ax
    jnz .label0 ; ↑
    lea ax,[bp-0x26]
    push ax
    push word [di]
    call 0xf36:FUN_4_0d58 ; ef2 4:d58
    add sp,byte +0x4
    or ax,ax
    jnz .label2 ; ↓
    jmp .label17 ; ↓
.label2: ; f01
    push ds
    push word [bp+0x8]
    lea ax,[bp-0x26]
    push ss
    push ax
    call 0x0:0xfcb ; f0a USER.lstrcmpi
    or ax,ax
    jz .label0 ; ↑
    jmp .label17 ; ↓
.label3: ; f16
    push ds
    push word 0x2d4
    lea ax,[bp-0xae]
    push ss
    push ax
    push byte +0x20
    call 0x0:0xd75 ; f22 KERNEL.OpenFile
    mov [bp-0xa],ax
    inc ax
    jnz .label4 ; ↓
    jmp .label17 ; ↓
.label4: ; f30
    push word [bp-0xa]
    call 0xf67:FUN_4_0950 ; f33 4:950
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
    call 0xfbc:FUN_4_0c3a ; f64 4:c3a
    add sp,byte +0x8
    or ax,ax
    jnz .label7 ; ↓
    jmp .label16 ; ↓
.label7: ; f73
    mov si,[bp-0xc]
    lea di,[bp+si-0x23e]
    lea si,[bp-0x23e]
    cmp di,si
    jna .label13 ; ↓
    mov [bp-0x6],di
.label8: ; f85
    lodsb
    mov [bp-0x3],al
    lodsb
    mov [bp-0x4],al
    cmp byte [bp-0x3],0x6
    jz .label9 ; ↓
    cmp byte [bp-0x3],0x8
    jnz .label12 ; ↓
.label9: ; f99
    cmp byte [bp-0x4],0xa
    jna .label10 ; ↓
    mov byte [si+0x9],0x0
.label10: ; fa3
    lea ax,[bp-0x26]
    push ss
    push ax
    push ds
    push si
    call 0x0:0xe13 ; faa KERNEL.lstrcpy
    cmp byte [bp-0x3],0x8
    jz .label11 ; ↓
    lea ax,[bp-0x26]
    push ax
    call 0x118d:DecodePassword ; fb9 4:6b0 DecodePassword
    add sp,byte +0x2
.label11: ; fc1
    push ds
    push word [bp+0x8]
    lea ax,[bp-0x26]
    push ss
    push ax
    call 0x0:0x10c9 ; fca USER.lstrcmpi
    or ax,ax
    jz .label15 ; ↓
.label12: ; fd3
    mov al,[bp-0x4]
    sub ah,ah
    add si,ax
    cmp si,di
    jc .label8 ; ↑
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
    call 0x0:0x1006 ; ff1 KERNEL._lclose
    mov ax,[bp-0x8]
    mov bx,[bp+0x6]
    mov [bx],ax
    jmp .label0 ; ↑
    nop
.label16: ; 1002
    push word [bp-0xa]
    call 0x0:0xc1c ; 1005 KERNEL._lclose
.label17: ; 100a
    xor ax,ax
.label18: ; 100c
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 1016

PASSWORDMSGPROC:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
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
    call 0x0:0xffff ; 1051 WEP4UTIL.1202
    jmp .label12 ; ↓
    nop
.label1: ; 105a
    push word [bp+0xe]
    push word 0x111
    push byte +0x2
    push byte +0x0
    push byte +0x0
    call 0x0:0x11f ; 1066 USER.PostMessage
    jmp .label11 ; ↓
.label2: ; 106e
    mov si,[bp+0xe]
    push si
    call 0x0:0xffff ; 1072 WEP4UTIL.103
    push word [0x169c]
    push ds
    push word 0x99a
    lea ax,[bp-0x4c]
    push ss
    push ax
    call 0x0:0x10e6 ; 1084 USER._wsprintf
    add sp,byte +0xa
    push si
    push byte +0x64
    lea ax,[bp-0x4c]
    push ss
    push ax
    call 0x0:0xffff ; 1094 USER.SetDlgItemText
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
    call 0x0:0xffff ; 10b9 USER.GetDlgItemText
    lea ax,[bp-0xc]
    push ss
    push ax
    push ds
    push word [0x169a]
    call 0x0:0xe92 ; 10c8 USER.lstrcmpi
    or ax,ax
    jz .label8 ; ↓
    cmp byte [bp-0xc],0x0
    jz .label6 ; ↓
    lea ax,[bp-0xc]
    push ss
    push ax
    push ds
    push word 0x9c2
    lea ax,[bp-0x4c]
    push ss
    push ax
    call 0x0:0x10fa ; 10e5 USER._wsprintf
    add sp,byte +0xc
    jmp short .label7 ; ↓
    nop
.label6: ; 10f0
    push ds
    push word 0x9eb
    lea ax,[bp-0x4c]
    push ss
    push ax
    call 0x0:0x183 ; 10f9 USER._wsprintf
    add sp,byte +0x8
.label7: ; 1101
    push byte +0x10
    lea ax,[bp-0x4c]
    push ss
    push ax
    push si
    call 0x1199:0x0 ; 1109 2:0 ShowMessageBox
    add sp,byte +0x8
    push si
    push byte +0x65
    call 0x0:0xffff ; 1114 USER.GetDlgItem
    push ax
    call 0x0:0xffff ; 111a USER.SetFocus
    push si
    push byte +0x65
    push word 0x401
    push byte +0x0
    push byte -0x1
    push byte +0x0
    call 0x0:0xffff ; 112b USER.SendDlgItemMessage
    jmp short .label11 ; ↓
.label8: ; 1132
    mov word [0x169c],0x1
    push si
    push byte +0x1
    jmp short .label10 ; ↓
    nop
.label9: ; 113e
    mov word [0x169c],0x0
    push word [bp+0xe]
    push byte +0x0
.label10: ; 1149
    call 0x0:0xffff ; 1149 USER.EndDialog
.label11: ; 114e
    mov ax,0x1
.label12: ; 1151
    pop si
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf 0xa
    nop

; 115c

FUN_4_115c:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x12
    push di
    push si
    mov si,[bp+0x8]
    mov bx,[0x1680]
    mov ax,[bx+0x800]
    mov [bp-0x12],ax
    cmp ax,si
    jz .label2 ; ↓
    cmp word [0x2e],byte +0x0
    jz .label0 ; ↓
    cmp ax,0x91
    jnz .label2 ; ↓
.label0: ; 1189
    push si
    call 0x11a5:FUN_4_0e48 ; 118a 4:e48
    add sp,byte +0x2
    or ax,ax
    jnz .label2 ; ↓
    call 0x11ee:0x17da ; 1196 2:17da PauseGame
    lea ax,[bp-0x10]
    push ax
    push word [bp+0x8]
    call 0x11bb:FUN_4_0d58 ; 11a2 4:d58
    add sp,byte +0x4
    or ax,ax
    jz .label1 ; ↓
    mov ax,[bp+0x8]
    mov [0x169c],ax
    lea ax,[bp-0x10]
    mov [0x169a],ax
    push word 0xb91
    push word 0x1016
    push word [0x172a]
    call 0x0:0xffff ; 11c4 KERNEL.MakeProcInstance
    mov di,ax
    mov [bp-0x4],dx
    push word [0x172a]
    push ds
    push word 0xa06
    push word [bp+0x6]
    mov ax,dx
    push ax
    push di
    mov si,dx
    call 0x0:0xffff ; 11df USER.DialogBox
    push si
    push di
    call 0x0:0xffff ; 11e6 KERNEL.FreeProcInstance
    call 0x11f9:0x1834 ; 11eb 2:1834 UnpauseGame
    mov ax,[0x169c]
    jmp short .label3 ; ↓
    nop
.label1: ; 11f6
    call 0xe6b:0x1834 ; 11f6 2:1834 UnpauseGame
.label2: ; 11fb
    mov ax,0x1
.label3: ; 11fe
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 1207

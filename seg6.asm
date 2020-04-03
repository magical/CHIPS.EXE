SEGMENT CODE ; 6

%include "variables.asm"

; 0

GOTOLEVELMSGPROC:
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
    jmp .label20 ; ↓
.label0: ; 2c
    push word [bp+0xe]
    push word [bp+0xc]
    push word [bp+0xa]
    push word [bp+0x8]
    push word [bp+0x6]
    call 0x0:0x1ce ; 3b WEP4UTIL.1202
    jmp .label20 ; ↓
    nop
.label1: ; 44
    push word [bp+0xe]
    push word 0x111
    push byte +0x2
    push byte +0x0
    push byte +0x0
    call 0x0:0x1e3 ; 50 USER.PostMessage
    jmp .label19 ; ↓
.label2: ; 58
    push word [bp+0xe]
    call 0x0:0x1f4 ; 5b WEP4UTIL.103
    jmp .label19 ; ↓
    nop
.label3: ; 64
    mov ax,[bp+0xa]
    dec ax
    jz .label5 ; ↓
    dec ax
    jnz .label4 ; ↓
    jmp .label17 ; ↓
.label4: ; 70
    jmp .label19 ; ↓
    nop
.label5: ; 74
    mov si,[bp+0xe]
    push si
    push byte +0x64
    lea ax,[bp-0x6]
    push ss
    push ax
    push byte +0x0
    call 0x0:0xffff ; 81 USER.GetDlgItemInt
    mov [bp-0x4],ax
    call 0x133:0xa0e ; 89 4:a0e
    mov di,ax
    cmp word [bp-0x6],byte +0x0
    jnz .label6 ; ↓
    push si
    push byte +0x64
    lea ax,[bp-0xa]
    push ss
    push ax
    push byte +0x4
    call 0x0:0xe8 ; a0 USER.GetDlgItemText
    cmp byte [bp-0xa],0x0
    jnz .label6 ; ↓
    mov word [bp-0x6],0x1
    mov word [bp-0x4],0x0
.label6: ; b5
    cmp word [bp-0x6],byte +0x0
    jnz .label7 ; ↓
    jmp .label16 ; ↓
.label7: ; be
    cmp word [bp-0x4],byte +0x0
    jnl .label8 ; ↓
    jmp .label16 ; ↓
.label8: ; c7
    cmp di,[bp-0x4]
    jnl .label9 ; ↓
    jmp .label16 ; ↓
.label9: ; cf
    cmp word [IgnorePasswords],byte +0x0
    jz .label10 ; ↓
    cmp word [bp-0x4],0x91
    jnz .label14 ; ↓
.label10: ; dd
    push si
    push byte +0x65
    lea ax,[bp-0x16]
    push ss
    push ax
    push byte +0xa
    call 0x0:0xffff ; e7 USER.GetDlgItemText
    cmp byte [bp-0x16],0x0
    jnz .label13 ; ↓
    cmp word [bp-0x4],byte +0x0
    jnz .label13 ; ↓
    push byte +0x30
    push ds
    push word 0xa36
.label11: ; fe
    push si
    call 0x156:0x0 ; ff 2:0 ShowMessageBox
    add sp,byte +0x8
    push si
    push byte +0x64
    call 0x0:0x15f ; 10a USER.GetDlgItem
    push ax
    call 0x0:0x165 ; 110 USER.SetFocus
    push si
    push byte +0x64
.label12: ; 118
    push word 0x401
    push byte +0x0
    push byte -0x1
    push byte +0x0
    call 0x0:0xffff ; 121 USER.SendDlgItemMessage
    jmp short .label19 ; ↓
.label13: ; 128
    lea ax,[bp-0x16]
    push ax
    lea ax,[bp-0x4]
    push ax
    call 0x39b:0xeaa ; 130 4:eaa
    add sp,byte +0x4
    or ax,ax
    jz .label15 ; ↓
.label14: ; 13c
    mov ax,[bp-0x4]
    mov bx,[GameStatePtr]
    mov [bx+0x800],ax
    push si
    push byte +0x1
    jmp short .label18 ; ↓
.label15: ; 14c
    push byte +0x30
    push ds
    push word 0xa5e
    push si
    call 0x208:0x0 ; 153 2:0 ShowMessageBox
    add sp,byte +0x8
    push si
    push byte +0x65
    call 0x0:0x1fc ; 15e USER.GetDlgItem
    push ax
    call 0x0:0xffff ; 164 USER.SetFocus
    push si
    push byte +0x65
    jmp short .label12 ; ↑
.label16: ; 16e
    push byte +0x30
    push ds
    push word 0xa80
    jmp short .label11 ; ↑
.label17: ; 176
    push word [bp+0xe]
    push byte +0x0
.label18: ; 17b
    call 0x0:0xffff ; 17b USER.EndDialog
.label19: ; 180
    mov ax,0x1
.label20: ; 183
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf 0xa

; 18e

BESTTIMEMSGPROC:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x50
    push di
    push si
    mov ax,[bp+0xc]
    sub ax,0xf
    jz .label1 ; ↓
    dec ax
    jz .label2 ; ↓
    sub ax,0x9
    jz .label1 ; ↓
    sub ax,0xf7
    jz .label4 ; ↓
    dec ax
    jnz .label0 ; ↓
    jmp .label13 ; ↓
.label0: ; 1b8
    xor ax,ax
    jmp .label26 ; ↓
    nop
.label1: ; 1be
    push word [bp+0xe]
    push word [bp+0xc]
    push word [bp+0xa]
    push word [bp+0x8]
    push word [bp+0x6]
    call 0x0:0xffff ; 1cd WEP4UTIL.1202
    jmp .label26 ; ↓
    nop
.label2: ; 1d6
    push word [bp+0xe]
    push word 0x111
    push byte +0x2
.label3: ; 1de
    push byte +0x0
    push byte +0x0
    call 0x0:0xffff ; 1e2 USER.PostMessage
    jmp .label25 ; ↓
.label4: ; 1ea
    mov di,[bp+0xe]
    mov word [bp-0x6],0x0
    push di
    call 0x0:0xffff ; 1f3 WEP4UTIL.103
    push di
    push byte +0x64
    call 0x0:0x346 ; 1fb USER.GetDlgItem
    mov si,ax
    push word 0xc8
    call 0x24c:0x198e ; 205 2:198e GetIniInt
    add sp,byte +0x2
    mov [bp-0x8],ax
    or ax,ax
    jg .label6 ; ↓
    push si
    push word 0x402
    push byte +0x0
    push ds
    push word 0xaa2
    call 0x0:0x2a0 ; 21e USER.SendMessage
.label5: ; 223
    mov di,[bp-0x6]
    jmp .label10 ; ↓
    nop
    nop
    nop
.label6: ; 22c
    mov [bp-0xa],si
    mov dx,0x1
    cmp ax,dx
    jl .label5 ; ↑
    mov [bp-0x4],dx
    mov si,dx
    mov di,[bp-0x6]
.label7: ; 23e
    lea ax,[bp-0x10]
    push ax
    lea ax,[bp-0xc]
    push ax
    push byte +0x0
    push si
    call 0xffff:0x1adc ; 249 2:1adc
    add sp,byte +0x8
    or ax,ax
    jz .label8 ; ↓
    cmp word [bp-0xc],byte +0x0
    jl .label8 ; ↓
    cmp word [bp-0xe],byte +0x0
    jl .label8 ; ↓
    push word [bp-0xe]
    push word [bp-0x10]
    push word [bp-0xc]
    push si
    push ds
    push word 0xab7
    lea ax,[bp-0x50]
    push ss
    push ax
    call 0x0:0x28b ; 274 USER._wsprintf
    add sp,byte +0x10
    inc di
    jmp short .label9 ; ↓
    nop
.label8: ; 280
    push si
    push ds
    push word 0xad9
    lea ax,[bp-0x50]
    push ss
    push ax
    call 0x0:0x2c9 ; 28a USER._wsprintf
    add sp,byte +0xa
.label9: ; 292
    push word [bp-0xa]
    push word 0x402
    push byte -0x1
    lea ax,[bp-0x50]
    push ss
    push ax
    call 0x0:0x376 ; 29f USER.SendMessage
    inc si
    cmp si,[bp-0x8]
    jng .label7 ; ↑
.label10: ; 2aa
    cmp di,byte +0x1
    jz .label11 ; ↓
    mov ax,0xaf2
    jmp short .label12 ; ↓
.label11: ; 2b4
    mov ax,0xaf4
.label12: ; 2b7
    mov si,ax
    mov [bp-0x8],ds
    push ds
    push si
    push di
    push ds
    push word 0xaf5
    lea ax,[bp-0x50]
    push ss
    push ax
    call 0x0:0x2f1 ; 2c8 USER._wsprintf
    add sp,byte +0xe
    push word [bp+0xe]
    push byte +0x66
    lea ax,[bp-0x50]
    push ss
    push ax
    call 0x0:0x303 ; 2da USER.SetDlgItemText
    push word [0x1698]
    push word [TotalScore]
    push ds
    push word 0xb14
    lea ax,[bp-0x50]
    push ss
    push ax
    call 0x0:0xffff ; 2f0 USER._wsprintf
    add sp,byte +0xc
    push word [bp+0xe]
    push byte +0x67
    lea ax,[bp-0x50]
    push ss
    push ax
    call 0x0:0xffff ; 302 USER.SetDlgItemText
    jmp .label25 ; ↓
.label13: ; 30a
    mov ax,[bp+0xa]
    cmp ax,0x65
    jz .label20 ; ↓
    jna .label14 ; ↓
    jmp .label25 ; ↓
.label14: ; 317
    dec al
    jz .label15 ; ↓
    dec al
    jz .label16 ; ↓
    sub al,0x62
    jz .label17 ; ↓
    jmp .label25 ; ↓
.label15: ; 326
    push word [bp+0xe]
    jmp .label23 ; ↓
.label16: ; 32c
    push word [bp+0xe]
    push byte +0x0
    jmp short .label24 ; ↓
    nop
.label17: ; 334
    mov ax,[bp+0x8]
    dec ax
    jz .label18 ; ↓
    dec ax
    jz .label19 ; ↓
    jmp short .label25 ; ↓
    nop
.label18: ; 340
    push word [bp+0xe]
    push byte +0x65
    call 0x0:0x367 ; 345 USER.GetDlgItem
    push ax
    push byte +0x1
    call 0x0:0xffff ; 34d USER.EnableWindow
    jmp short .label25 ; ↓
.label19: ; 354
    push word [bp+0xe]
    push word 0x111
    push byte +0x65
    jmp .label3 ; ↑
    nop
.label20: ; 360
    mov di,[bp+0xe]
    push di
    push byte +0x64
    call 0x0:0xffff ; 366 USER.GetDlgItem
    push ax
    push word 0x409
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0xffff ; 375 USER.SendMessage
    mov [bp-0x6],ax
    mov [bp-0x4],dx
    cmp ax,0xffff
    jnz .label21 ; ↓
    cmp dx,ax
    jz .label25 ; ↓
.label21: ; 389
    mov si,ax
    inc si
    mov bx,[GameStatePtr]
    cmp si,[bx+0x800]
    jz .label22 ; ↓
    push si
    push di
    call 0x3aa:0x115c ; 398 4:115c
    add sp,byte +0x4
    or ax,ax
    jz .label25 ; ↓
.label22: ; 3a4
    push byte +0x0
    push si
    call 0xffff:0x356 ; 3a7 4:356
    add sp,byte +0x4
    push di
.label23: ; 3b0
    push byte +0x1
.label24: ; 3b2
    call 0x0:0x74a ; 3b2 USER.EndDialog
.label25: ; 3b7
    mov ax,0x1
.label26: ; 3ba
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf 0xa
    nop

; 3c6

COMPLETEMSGPROC:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,0x9a
    push di
    push si
    mov ax,[bp+0xc]
    sub ax,0xf
    jz .label1 ; ↓
    dec ax
    jz .label2 ; ↓
    sub ax,0x9
    jz .label1 ; ↓
    sub ax,0xf7
    jz .label3 ; ↓
    dec ax
    jnz .label0 ; ↓
    jmp .label30 ; ↓
.label0: ; 3f1
    xor ax,ax
    jmp .label35 ; ↓
.label1: ; 3f6
    push word [bp+0xe]
    push word [bp+0xc]
    push word [bp+0xa]
    push word [bp+0x8]
    push word [bp+0x6]
    call 0x0:0x3c ; 405 WEP4UTIL.1202
    jmp .label35 ; ↓
    nop
.label2: ; 40e
    push word [bp+0xe]
    push word 0x111
    push byte +0x6a
    push byte +0x0
    push byte +0x0
    call 0x0:0x51 ; 41a USER.PostMessage
    jmp .label34 ; ↓
.label3: ; 422
    mov di,[bp+0xe]
    push di
    call 0x0:0x5c ; 426 WEP4UTIL.103
    mov ax,[TimeRemaining]
    mov cx,ax
    shl ax,byte 0x2
    add ax,cx
    shl ax,1
    mov [bp-0x12],ax
    cwd
    mov [bp-0xc],ax
    mov [bp-0xa],dx
    mov ax,0x1f4
    mov bx,[GameStatePtr]
    imul word [bx+0x800]
    mov [bp-0x8],ax
    mov [bp-0x6],dx
    mov word [bp-0x4],0x0
    mov ax,[bx+0xa30]
    mov [bp-0x9a],ax
    or ax,ax
    jng .label7 ; ↓
    mov si,[bp-0x4]
.label4: ; 466
    push byte +0x0
    push byte +0x5
    mov ax,[bp-0x8]
    mov dx,[bp-0x6]
    shl ax,1
    rcl dx,1
    shl ax,1
    rcl dx,1
    push dx
    push ax
    call 0xffff:0x110 ; 47a 1:110 div32_probably
    mov [bp-0x8],ax
    mov [bp-0x6],dx
    or dx,dx
    jl .label6 ; ↓
    jg .label5 ; ↓
    cmp ax,0x1f4
    jc .label6 ; ↓
.label5: ; 490
    inc si
    cmp [bp-0x9a],si
    jg .label4 ; ↑
.label6: ; 497
    mov di,[bp+0xe]
.label7: ; 49a
    mov ax,[bp-0x8]
    mov dx,[bp-0x6]
    add [bp-0xc],ax
    adc [bp-0xa],dx
    cmp word [bp-0x9a],byte +0x0
    jnz .label8 ; ↓
    mov ax,0xb34
    jmp short .label11 ; ↓
.label8: ; 4b2
    cmp word [bp-0x9a],byte +0x3
    jl .label10 ; ↓
    cmp word [bp-0x9a],byte +0x5
    jl .label9 ; ↓
    mov ax,0xb6b
    jmp short .label11 ; ↓
    nop
.label9: ; 4c6
    mov ax,0xb56
    jmp short .label11 ; ↓
    nop
.label10: ; 4cc
    mov ax,0xb47
.label11: ; 4cf
    mov [bp-0x10],ax
    mov [bp-0xe],ds
    push ds
    push ax
    push ds
    push word 0xb80
    lea ax,[bp-0x98]
    push ss
    push ax
    call 0x0:0x505 ; 4e1 USER._wsprintf
    add sp,byte +0xc
    push di
    push byte +0x65
    lea ax,[bp-0x98]
    push ss
    push ax
    call 0x0:0x516 ; 4f2 USER.SetDlgItemText
    push word [bp-0x12]
    push ds
    push word 0xb83
    lea ax,[bp-0x98]
    push ss
    push ax
    call 0x0:0x52b ; 504 USER._wsprintf
    add sp,byte +0xa
    push di
    push byte +0x66
    lea ax,[bp-0x98]
    push ss
    push ax
    call 0x0:0x53c ; 515 USER.SetDlgItemText
    push word [bp-0x6]
    push word [bp-0x8]
    push ds
    push word 0xb93
    lea ax,[bp-0x98]
    push ss
    push ax
    call 0x0:0x551 ; 52a USER._wsprintf
    add sp,byte +0xc
    push di
    push byte +0x67
    lea ax,[bp-0x98]
    push ss
    push ax
    call 0x0:0x562 ; 53b USER.SetDlgItemText
    push word [bp-0xa]
    push word [bp-0xc]
    push ds
    push word 0xba5
    lea ax,[bp-0x98]
    push ss
    push ax
    call 0x0:0x648 ; 550 USER._wsprintf
    add sp,byte +0xc
    push di
    push byte +0x6c
    lea ax,[bp-0x98]
    push ss
    push ax
    call 0x0:0x6ec ; 561 USER.SetDlgItemText
    mov bx,[GameStatePtr]
    push word [bx+0x800]
    push word 0xc9
    call 0x57f:0x19ca ; 571 2:19ca StoreIniInt
    add sp,byte +0x4
    push word 0xc8
    call 0x5a4:0x198e ; 57c 2:198e GetIniInt
    add sp,byte +0x2
    mov si,ax
    mov bx,[GameStatePtr]
    cmp [bx+0x800],si
    jng .label12 ; ↓
    jmp .label28 ; ↓
.label12: ; 593
    lea ax,[bp-0x18]
    push ax
    lea ax,[bp-0x14]
    push ax
    push byte +0x0
    push word [bx+0x800]
    call 0x5fe:0x1adc ; 5a1 2:1adc
    add sp,byte +0x8
    or ax,ax
    jnz .label13 ; ↓
    jmp .label28 ; ↓
.label13: ; 5b0
    cmp word [bp-0x14],byte +0x0
    jnl .label14 ; ↓
    jmp .label28 ; ↓
.label14: ; 5b9
    cmp word [bp-0x16],byte +0x0
    jnl .label15 ; ↓
    jmp .label28 ; ↓
.label15: ; 5c2
    mov ax,[bp-0x12]
    cwd
    add ax,[bp-0x8]
    adc dx,[bp-0x6]
    cmp dx,[bp-0x16]
    jg .label17 ; ↓
    jl .label16 ; ↓
    cmp ax,[bp-0x18]
    jnc .label17 ; ↓
.label16: ; 5d8
    mov dx,[bp-0x16]
    mov ax,[bp-0x18]
.label17: ; 5de
    mov [bp-0x10],ax
    mov [bp-0xe],dx
    push dx
    push ax
    mov ax,[bp-0x14]
    cmp ax,[TimeRemaining]
    jnl .label18 ; ↓
    mov ax,[TimeRemaining]
.label18: ; 5f2
    push ax
    mov bx,[GameStatePtr]
    push word [bx+0x800]
    call 0x6d1:0x1c1c ; 5fb 2:1c1c
    add sp,byte +0x8
    mov ax,[bp-0x10]
    mov dx,[bp-0xe]
    sub ax,[bp-0x18]
    sbb dx,[bp-0x16]
    add [TotalScore],ax
    adc [0x1698],dx
    mov ax,[TimeRemaining]
    cmp [bp-0x14],ax
    jnl .label21 ; ↓
    sub ax,[bp-0x14]
    cmp ax,0x1
    jng .label19 ; ↓
    mov ax,0xbea
    jmp short .label20 ; ↓
.label19: ; 62c
    mov ax,0xbec
.label20: ; 62f
    mov si,ax
    mov [bp-0x4],ds
    push ds
    push si
    mov ax,[TimeRemaining]
    sub ax,[bp-0x14]
    push ax
    push ds
    push word 0xbed
    lea ax,[bp-0x98]
    push ss
    push ax
    call 0x0:0x6a3 ; 647 USER._wsprintf
    add sp,byte +0xe
    jmp short .label27 ; ↓
    nop
.label21: ; 652
    mov ax,[bp-0x18]
    mov dx,[bp-0x16]
    cmp [bp-0xa],dx
    jl .label26 ; ↓
    jg .label22 ; ↓
    cmp [bp-0xc],ax
    jna .label26 ; ↓
.label22: ; 664
    mov ax,[bp-0xc]
    mov dx,[bp-0xa]
    sub ax,[bp-0x18]
    sbb dx,[bp-0x16]
    or dx,dx
    jl .label24 ; ↓
    jg .label23 ; ↓
    cmp ax,0x1
    jna .label24 ; ↓
.label23: ; 67b
    mov ax,0xc1f
    jmp short .label25 ; ↓
.label24: ; 680
    mov ax,0xc21
.label25: ; 683
    mov si,ax
    mov [bp-0x4],ds
    push ds
    push si
    mov ax,[bp-0xc]
    mov dx,[bp-0xa]
    sub ax,[bp-0x18]
    sbb dx,[bp-0x16]
    push dx
    push ax
    push ds
    push word 0xc22
    lea ax,[bp-0x98]
    push ss
    push ax
    call 0x0:0x716 ; 6a2 USER._wsprintf
    add sp,byte +0x10
    jmp short .label27 ; ↓
.label26: ; 6ac
    mov byte [bp-0x98],0x0
.label27: ; 6b1
    push di
    push byte +0x69
    lea ax,[bp-0x98]
    push ss
    push ax
    jmp short .label29 ; ↓
.label28: ; 6bc
    push word [bp-0xa]
    push word [bp-0xc]
    push word [TimeRemaining]
    mov bx,[GameStatePtr]
    push word [bx+0x800]
    call 0x6fe:0x1c1c ; 6ce 2:1c1c
    add sp,byte +0x8
    mov ax,[bp-0xc]
    mov dx,[bp-0xa]
    add [TotalScore],ax
    adc [0x1698],dx
    push di
    push byte +0x69
    push ds
    push word 0xbb7
.label29: ; 6eb
    call 0x0:0x727 ; 6eb USER.SetDlgItemText
    push word [0x1698]
    push word [TotalScore]
    push word 0xca
    call 0x102:0x1a86 ; 6fb 2:1a86 StoreIniLong
    add sp,byte +0x6
    push word [0x1698]
    push word [TotalScore]
    push ds
    push word 0xc59
    lea ax,[bp-0x98]
    push ss
    push ax
    call 0x0:0x275 ; 715 USER._wsprintf
    add sp,byte +0xc
    push di
    push byte +0x68
    lea ax,[bp-0x98]
    push ss
    push ax
    call 0x0:0x2db ; 726 USER.SetDlgItemText
    jmp short .label34 ; ↓
    nop
.label30: ; 72e
    mov ax,[bp+0xa]
    sub ax,0x6a
    jz .label31 ; ↓
    dec ax
    jz .label32 ; ↓
    jmp short .label34 ; ↓
    nop
.label31: ; 73c
    push word [bp+0xe]
    push byte +0x1
    jmp short .label33 ; ↓
    nop
.label32: ; 744
    push word [bp+0xe]
    push byte +0x0
.label33: ; 749
    call 0x0:0x17c ; 749 USER.EndDialog
.label34: ; 74e
    mov ax,0x1
.label35: ; 751
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    db 0xca,0x0a ; retf 0xa

; 75b

; vim: syntax=nasm

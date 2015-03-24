SEGMENT CODE ; 9

; Clock graphics

; Data:
;   172a    hModule
;   1720    HGLOBAL returned by LoadResource
;   16c4    far pointer returned by LockResource
;   16f0-1720   near pointers to digits (length 24)
;
;   a18     Color mode

%define DigitWidth 17
%define DigitHeight 23

; 0
FindBitmap:
    %stacksize small
    %arg name:word
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2

    push word [0x172a]  ; hModule
    mov ax,[name]       ; lpName
    sub dx,dx
    push dx
    push ax
    push dx             ; lpType
    push byte +0x2 ; RT_BITMAP
    call word 0x0:0xffff ; 1b KERNEL.FindResource
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 28
; Computes the data size of a 4-bpp bitmap with the given width and height.
BitmapSize:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2

    %stacksize small
    %arg w:word, h:word

    ; Compute the stride (size of a row).
    ;   ax = (((w << 2) + 31) & ~24) >> 3
    ;
    ; Equivalent to
    ;   ax = ((w + 7) & ~7) >> 1
    ; or
    ;   ax = (w*4 + 31) / 32 * 4
    mov ax,[w]
    shl ax,byte 0x2
    add ax,0x1f
    and al,0xe7
    sar ax,byte 0x3

    ; Multiply by the height.
    imul word [h]

    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop


; 4E
LoadDigits:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x8
    push di
    push si

    push word 200       ; ID of the digits resource
    call word 0x8f:0x0  ; 60 9:0 FindBitmap
    add sp,byte +0x2
    mov si,ax

    push word [0x172a]  ; hModule
    push si             ; hResInfo
    call word 0x0:0xffff ; 6f KERNEL.LoadResource
    mov [0x1720],ax

    or ax,ax
    jz .end
    push ax             ; hResInfo
    call word 0x0:0xffff ; 7c KERNEL.LockResource
    mov [0x16c4],ax
    mov [0x16c6],dx

    push byte DigitHeight ; y dimension of digits
    push byte DigitWidth ; x dimension of digits
    call word 0xffff:0x28 ; 8c 9:0x28 BitmapSize
    add sp,byte +0x4

    ; Store near pointers to digits at 0x16f0
    mov si,ax
    mov di,0x68 ; bitmap header length
    mov word [bp-0x4],0x16f0
    mov bx,[bp-0x4]
    mov dx,si
.loop: ; a3
    mov [bx],di
    add di,dx
    add bx,byte +0x2
    cmp bx,0x1720
    jc .loop
    mov ax,0x1
.end: ; b3
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; BC
FreeDigits:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    cmp word [0x1720],byte +0x0
    jz .null
    push word [0x1720]
    call word 0x0:0xffff ; d4 KERNEL.GlobalUnlock
    push word [0x1720]
    call word 0x0:0xffff ; dd KERNEL.FreeResource
.null: ; e2
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; ea
DrawDigit:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x4

    %stacksize small
    %arg hdc:word, xDest:word, yDest:word, digit:word, color:word
    %define colorOffset (bp-4)

    cmp word [color],byte +0x0
    jnz .label3
    cmp word [0xa18],byte +0x1
    jz .label3
    mov word [colorOffset],0x0
    jmp short .label4
    nop
.label3: ; 10c
    mov word [colorOffset],0xc
.label4: ; 111

    ; http://msdn.microsoft.com/en-us/library/dd162974%28v=vs.85%29.aspx
    push word [hdc]     ; HDC
    push word [xDest]   ; XDest
    push word [yDest]   ; YDest
    push byte DigitWidth; Width
    push byte DigitHeight;Height
    push byte 0         ; XSrc
    push byte 0         ; YSrc
    push byte 0         ; uStartScan
    push byte DigitHeight;cScanLines
    mov bx,[digit]
    add bx,[colorOffset]
    shl bx,1
    mov ax,[bx+0x16f0]
    add ax,[0x16c4]
    mov dx,[0x16c6]
    push dx             ; lpvBits
    push ax
    push dx             ; lpbmi
    push word [0x16c4]
    push byte +0x0      ; fuColorUse
    call word 0x0:0xffff ; 143 GDI.SetDIBitsToDevice
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; vim: syntax=nasm

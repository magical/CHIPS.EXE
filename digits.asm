SEGMENT CODE ; 9

; Clock graphics

; Data:
;   172a    hModule
;   1720    HGLOBAL returned by LoadResource
;   16c4    far pointer returned by LockResource
;   16f0-1720   near pointers to digits (length 24)
;
;   a18     Color mode

%include "variables.asm"
%include "func.mac"

%define SEGMENT_NUMBER 9
%include "extern.inc"
%include "windows.inc"

%define DigitWidth 17
%define DigitHeight 23

func FindBitmap
    %arg name:word
    sub sp,byte +0x2

    push word [OurHInstance]  ; hModule
    mov ax,[name]       ; lpName
    sub dx,dx
    push dx
    push ax
    push dx             ; lpType
    push byte +0x2 ; RT_BITMAP
    call far KERNEL.FindResource ; 1b
endfunc

; 28

; Computes the data size of a 4-bpp bitmap with the given width and height.
func BitmapSize
    sub sp,byte +0x2

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
endfunc

; 4e

func LoadDigits
    sub sp,byte +0x8
    push di
    push si

    push word 200       ; ID of the digits resource
    call far FindBitmap ; 60 9:0
    add sp,byte +0x2
    mov si,ax

    push word [OurHInstance]  ; hModule
    push si             ; hResInfo
    call far KERNEL.LoadResource ; 6f
    mov [DigitResourceHandle],ax

    or ax,ax
    jz .end
    push ax             ; hResInfo
    call far KERNEL.LockResource ; 7c
    mov [DigitBitmapData],ax
    mov [DigitBitmapData+2],dx

    push byte DigitHeight ; y dimension of digits
    push byte DigitWidth ; x dimension of digits
    call far BitmapSize ; 8c 9:28 9:0x28
    add sp,byte +0x4

    ; Store near pointers to digits in DigitPtrArray
    mov si,ax
    mov di,0x68 ; bitmap header length
    mov word [bp-0x4],DigitPtrArray
    mov bx,[bp-0x4]
    mov dx,si
.loop: ; a3
    mov [bx],di
    add di,dx
    add bx,byte +0x2
    cmp bx,DigitPtrArray.end
    jb .loop
    mov ax,0x1
.end: ; b3
    pop si
    pop di
endfunc

; bc

func FreeDigits
    sub sp,byte +0x2
    cmp word [DigitResourceHandle],byte +0x0
    jz .null
    push word [DigitResourceHandle]
    call far KERNEL.GlobalUnlock ; d4
    push word [DigitResourceHandle]
    call far KERNEL.FreeResource ; dd
.null: ; e2
endfunc

; ea

func DrawDigit
    sub sp,byte +0x4

    %arg hdc:word, xDest:word, yDest:word, digit:word, color:word
    %define colorOffset (bp-4)

    cmp word [color],byte +0x0
    jnz .label3
    cmp word [ColorMode],byte +0x1
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
    mov ax,[DigitPtrArray+bx]
    add ax,[DigitBitmapData]
    mov dx,[DigitBitmapData+2]
    push dx             ; lpvBits
    push ax
    push dx             ; lpbmi
    push word [DigitBitmapData]
    push byte +0x0      ; fuColorUse
    call far GDI.SetDIBitsToDevice ; 143
endfunc

; 150

GLOBAL _segment_9_size
_segment_9_size equ $ - $$


; vim: syntax=nasm

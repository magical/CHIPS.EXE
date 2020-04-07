SEGMENT CODE ; 5
; Tile graphics

; Data
;   26      HMENU
;   a14     HGDIOBJ tile object
;   a16     LPVOID  bitmap data?
;   a18             bitmap to use: 1, 2, 3, or 4 (monochrome, locolor, hicolor, hicolor)
;   169e            horizontal padding
;   16a0            vertical padding: 0x20 or 8, depending on vertical resolution
;   16c0            horizontal screen resolution
;   16c2            vertical screen resolution
;   172e    BOOL    records whether windows version >= 3.10

%include "constants.asm"
%include "variables.asm"
%include "func.mac"

func InitGraphics
    sub sp,byte +0x4
    push si

    %define hDC (bp-4)

    mov si,[bp+6] ; ???
    push byte +0x0 ; NULL
    call 0x0:0xffff ; 13 USER.GetDC
    mov [hDC],ax

    push ax
    push byte +0x8 ; HORZRES
    call 0x0:0x2c ; 1e GDI.GetDeviceCaps
    mov [HorizontalResolution],ax

    push word [hDC]
    push byte +0xa ; VERTRES
    call 0x0:0x71 ; 2b GDI.GetDeviceCaps
    mov [VerticalResolution],ax

    mov word [HorizontalPadding],0x20

    cmp ax,350
    jng .label0
    mov ax,0x20
    jmp short .label1
    nop
.label0: ; 44
    mov ax,0x8
.label1: ; 47
    mov [VerticalPadding],ax
    or si,si
    jz .label2
    push byte ID_COLOR
    call 0xffff:0x198e ; 50 2:198e GetIniInt
    add sp,byte +0x2
    or ax,ax
    jnz .label2
    xor dx,dx
    jmp short .label3
.label2: ; 60
    mov dx,0x1
.label3: ; 63
    or dx,dx
    jz .useMonochrome
    or si,si
    jz .checkRastercaps
    push word [hDC]
    push byte +0x18 ; NUMCOLORS
    call 0x0:0x80 ; 70 GDI.GetDeviceCaps
    cmp ax,0x2
    jng .useMonochrome
.checkRastercaps: ; 7a
    push word [hDC]
    push byte +0x26 ; RASTERCAPS
    call 0x0:0x8f ; 7f GDI.GetDeviceCaps
    test ah,0x1 ; RC_BITBLT
    jz .checkVertRes
    push word [hDC]
    push byte +0x68 ; SIZEPALETTE
    call 0x0:0xffff ; 8e GDI.GetDeviceCaps
    cmp ax,0x100
    jl .checkVertRes
    mov word [ColorMode],0x4
    jmp short .releaseDC
.checkVertRes: ; a0
    cmp word [VerticalResolution],350
    jg .useHicolor
    mov ax,0x2
    jmp short .setColors
    nop
.useHicolor: ; ae
    mov ax,0x3
.setColors: ; b1
    mov [ColorMode],ax ; bitmap to use
    jmp short .releaseDC
.useMonochrome: ; b6
    mov word [ColorMode],0x1
.releaseDC: ; bc
    push byte +0x0
    push word [hDC]
    call 0x0:0xffff ; c1 USER.ReleaseDC

    ; ax = (GetVersion() >= 3.10)
    call 0x0:0xffff ; c6 KERNEL.GetVersion
    ; swap low byte and high byte
    mov si,ax
    mov al,ah
    mov cx,si
    mov dl,al
    mov dh,cl
    cmp dx,0x30a
    jl .label10
    mov ax,0x1
    jmp short .label11
.label10: ; e0
    xor ax,ax
.label11: ; e2
    mov [IsWin31],ax

    ; Check or uncheck the 'Color' menu item as appropriate.
    push word [hMenu]        ; hMenu
    push byte ID_COLOR      ; uIDCheckItem
    cmp word [ColorMode],byte +0x1
    jz .label12
    mov ax,0x8  ; MF_CHECKED
    jmp short .label13
    nop
.label12: ; f8
    xor ax,ax   ; MF_UNCHECKED
.label13: ; fa
    push ax                 ; uCheck
    call 0x0:0xffff ; fb USER.CheckMenuItem

    push word [hwndMain]
    call 0x0:0xffff ; 104 USER.DrawMenuBar
    pop si
endfunc

; 112

;load tile bitmap
func LoadTiles
    %arg hInstance:word, hBitmapOut:word, loadDigits:word

    sub sp,byte +0x2
    push si

    mov word [0xa14],0x0
    mov ax,[ColorMode]
    dec ax
    jz .monochrome
    dec ax
    jz .lowcolor
.hicolor:
    mov si,[hBitmapOut]
    push word [hInstance]
    push ds
    push word HicolorTiles ; "obj32_4"
    jmp short .loadBitmap
    nop
.monochrome: ; 13c
    mov si,[hBitmapOut]
    push word [hInstance]
    push ds
    push word MonochromeTiles ; "obj32_1"
    jmp short .loadBitmap
.lowcolor: ; 148
    mov si,[hBitmapOut]
    push word [hInstance]
    push ds
    push word LocolorTiles ; "obj32_4E"

.loadBitmap: ; 152
    call 0x0:0xffff ; 152 USER.LoadBitmap
    mov [si],ax
    or ax,ax
    jz .failure
    cmp word [loadDigits],byte +0x0
    jnz .label18
    call 0xffff:0x4e ; 163 9:0x4e LoadDigits
    or ax,ax
    jz .failure
.label18: ; 16c
    mov ax,0x1
    jmp short .end
    nop
.failure: ; 172
    ; Return 0
    xor ax,ax
.end: ; 174
    pop si
endfunc

; 17e

; delete tile bitmap
func FreeTiles
    sub sp,byte +0x2

    cmp word [0xa14],byte +0x0
    jz .hObjectIsNull
    push word [0xa14]
    call 0x0:0xffff ; 194 GDI.DeleteObject
    mov word [0xa14],0x0
.hObjectIsNull: ; 19f

    cmp word [0xa16],byte +0x0
    jz .pointerIsNull
    push word [0xa16]
    call 0x0:0xffff ; 1aa KERNEL.LocalFree
    mov word [0xa16],0x0
.pointerIsNull: ; 1b5
endfunc

; vim: syntax=nasm

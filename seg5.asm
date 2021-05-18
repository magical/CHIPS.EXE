SEGMENT CODE ; 5

; Tile graphics

; Data
;   26      HMENU
;   a14     HGDIOBJ tile object
;   a16     LPVOID  bitmap data?
;   a18             bitmap to use: 1, 2, 3, or 4 (monochrome, lowcolor, hicolor, hicolor)
;   169e            horizontal padding
;   16a0            vertical padding: 0x20 or 8, depending on vertical resolution
;   16c0            horizontal screen resolution
;   16c2            vertical screen resolution
;   172e    BOOL    records whether windows version >= 3.10

%include "constants.asm"
%include "variables.asm"
%include "func.mac"
%include "if.mac"

%include "extern.inc"
%include "windows.inc"

func InitGraphics
    sub sp,byte +0x4
    push si

    %local hDC:word ; -4

    mov si,[bp+6] ; ???
    push byte +0x0 ; NULL
    call far USER.GetDC ; 13
    mov [hDC],ax
    ; get horizontal screen size
    push ax
    push byte +0x8 ; HORZRES
    call far GDI.GetDeviceCaps ; 1e
    mov [HorizontalResolution],ax
    ; get vertical screen size
    push word [hDC]
    push byte +0xa ; VERTRES
    call far GDI.GetDeviceCaps ; 2b
    mov [VerticalResolution],ax
    ; set padding
    ; decrease the vertical padding if the screen is too small
    mov word [HorizontalPadding],0x20
    cmp ax,350
    if g
        mov ax,0x20
    else ; 44
        mov ax,0x8
    endif ; 47
    mov [VerticalPadding],ax
    ; ok now time to figure out the tileset
    ; first check the user's preferences
    or si,si ; is color requested?
    jz .label2
    push byte ID_COLOR ; check the ini setting too
    call far GetIniInt ; 50 2:198e
    add sp,byte +0x2
    or ax,ax
    jnz .label2
    ; both the menu item and the ini allow it, so try using color
    xor dx,dx ; not monochrome
    jmp short .label3
.label2: ; 60
    ; no color allowed
    mov dx,0x1 ; monochrome
.label3: ; 63
    ; next check what the device actually supports
    ; - if color isn't allowed, use monochrome
    ; - if the device only has 2 colors, monochrome
    ; - if it can blit and has at least 256 colors, true color
    ; - otherwise decide based on the screen size
    or dx,dx
    jz .monochrome
    or si,si
    if nz
        push word [hDC]
        push byte +0x18 ; NUMCOLORS
        call far GDI.GetDeviceCaps ; 70
        cmp ax,0x2
        jle .monochrome
    endif ; 7a
    push word [hDC]
    push byte +0x26 ; RASTERCAPS
    call far GDI.GetDeviceCaps ; 7f
    test ah,0x1 ; RC_BITBLT
    if nz
        push word [hDC]
        push byte +0x68 ; SIZEPALETTE
        call far GDI.GetDeviceCaps ; 8e
        cmp ax,0x100
        if ge
            mov word [ColorMode],0x4 ; true color?
            jmp short .releaseDC
        endif
    endif ; a0
    cmp word [VerticalResolution],350
    if le
        ; the lowcolor tileset is only used if we have less than 256 colors
        ; and a vertical resolution no greater than 350
        ; which i think rules out everything except EGA.
        ; (and CGA, but CGA is way too small to play on)
        mov ax,0x2 ; lowcolor
    else ; ae
        mov ax,0x3 ; hicolor
    endif ; b1
    mov [ColorMode],ax ; bitmap to use
    jmp short .releaseDC
.monochrome: ; b6
    mov word [ColorMode],0x1 ; monochrome
.releaseDC: ; bc
    push byte +0x0
    push word [hDC]
    call far USER.ReleaseDC ; c1

    ; ax = (GetVersion() >= 3.10)
    call far KERNEL.GetVersion ; c6
    ; swap low byte and high byte
    mov si,ax
    mov al,ah
    mov cx,si
    mov dl,al
    mov dh,cl
    cmp dx,0x30a
    if ge
        mov ax,0x1
    else ; e0
        xor ax,ax
    endif ; e2
    mov [IsWin31],ax

    ; Check or uncheck the 'Color' menu item as appropriate.
    push word [hMenu]        ; hMenu
    push byte ID_COLOR      ; uIDCheckItem
    cmp word [ColorMode],byte +0x1
    if ne
        mov ax,0x8  ; MF_CHECKED
    else ; f8
        xor ax,ax   ; MF_UNCHECKED
    endif ; fa
    push ax                 ; uCheck
    call far USER.CheckMenuItem ; fb

    push word [hwndMain]
    call far USER.DrawMenuBar ; 104
    pop si
endfunc

; 112

; Load tile bitmap and return a handle to it
func LoadTiles
    %arg hInstance:word ; +6
    %arg hBitmapOut:word ; +8 is set to the tile bitmap handle
    %arg loadDigits:word ; +a if true, call LoadDigits

    sub sp,byte +0x2
    push si

    mov word [VarA14],0x0
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
    call far USER.LoadBitmap ; 152
    mov [si],ax
    or ax,ax
    jz .failure
    cmp word [loadDigits],byte +0x0
    jnz .label18
    call far LoadDigits ; 163 9:4e 9:0x4e
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

; 17c

; Delete tile bitmap
; doesn't actually do anything because LoadTiles doesn't actually keep a copy around
func FreeTiles
    sub sp,byte +0x2

    cmp word [VarA14],byte +0x0
    if nz
        push word [VarA14]
        call far GDI.DeleteObject ; 194
        mov word [VarA14],0x0
    endif ; 19f

    cmp word [VarA16],byte +0x0
    if nz
        push word [VarA16]
        call far KERNEL.LocalFree ; 1aa
        mov word [VarA16],0x0
    endif ; 1b5
endfunc

; 1bc

GLOBAL _segment_5_size
_segment_5_size equ $ - $$

; vim: syntax=nasm

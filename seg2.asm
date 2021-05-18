SEGMENT CODE ; 2

; UI Code

%include "base.inc"
%include "constants.asm"
%include "structs.asm"
%include "variables.asm"
%include "func.mac"
%include "if.mac"

%include "extern.inc"
%include "windows.inc"

EXTERN srand

EXTERN WEP4UTIL.FCHKWEPVERS
EXTERN WEP4UTIL.WEPABOUT2
EXTERN WEP4UTIL.WEPHELP

EXPORT MAINWNDPROC      MAINWNDPROC     1
EXPORT COUNTERWNDPROC   COUNTERWNDPROC  2
EXPORT BOARDWNDPROC     BOARDWNDPROC    9
EXPORT INVENTORYWNDPROC INVENTORYWNDPROC 14
EXPORT HINTWNDPROC      HINTWNDPROC     15
EXPORT INFOWNDPROC      INFOWNDPROC     16

; 0

func ShowMessageBox
    %arg hWnd:word ; +6
    %arg message:dword ; +8
    %arg flags:word ; +c
    sub sp,byte +0x2
    push si
    call far PauseTimer ; e 2:17a2
    ; if sound is enabled, play a message beep before
    ; popping the message box open
    cmp word [SoundEnabled],byte +0x0
    if nz
        ; Warning
        test byte [flags],0x30
        if nz
            mov si,0x30 ; MB_ICONWARNING
            jmp short .playBeep ; ↓
            nop
        endif ; 26
        ; Info
        test byte [flags],0x40
        if nz
            mov si,0x40 ; MB_ICONINFORMATION
            jmp short .playBeep ; ↓
            nop
        endif ; 32
        ; Error
        test byte [flags],0x10
        if nz
            mov si,0x10 ; MB_ICONERROR
            jmp short .playBeep ; ↓
            nop
        endif ; 3e
        ; Question
        mov al,[flags]
        and ax,0x20
        cmp ax,0x1
        cmc
        sbb si,si
        and si,byte +0x20 ; MB_ICONQUESTION
    .playBeep: ; 4d
        push si
        call far USER.MessageBeep ; 4e
    endif ; 53
    ; Show the message box and unpause
    push word [hWnd]
    push word [message+FarPtr.Seg] ; segment
    push word [message+FarPtr.Off]
    push ds
    push word MessageBoxCaption
    push word [flags]
    call far USER.MessageBox ; 63
    mov si,ax
    call far UnpauseTimer ; 6a 2:17ba
    mov ax,si
    pop si
endfunc

; 7a

; BOOL IsCoordOnscreen(int x, int y)
;
; Reports whether the given tile coordinate lies within the viewport
func IsCoordOnscreen
    sub sp,byte +0x2
    %arg x:word ; x position in level
    %arg y:word ; y position in level
    ; ViewportX > x
    mov dx,[x]
    mov bx,[GameStatePtr]
    cmp [bx+ViewportX],dx
    jg .no
    ; ViewportX + ViewportWidth <= x
    mov ax,[bx+ViewportX]
    add ax,[bx+ViewportWidth]
    cmp ax,dx
    jng .no
    ; ViewportY > y
    mov dx,[y]
    cmp [bx+ViewportY],dx
    jg .no
    ; ViewportY + ViewportHeight >= y
    mov ax,[bx+ViewportY]
    add ax,[bx+ViewportHeight]
    cmp ax,dx
    jng .no
.yes:
    mov ax,0x1
    jmp short .end
.no: ; ba
    xor ax,ax
.end: ; bc
endfunc

; c4

func DrawTile
    sub sp,byte +0xa
    cmp byte [bp+0xe],0x0
    if z
        jmp .opaque ; ↓
    endif ; da
    cmp byte [bp+0xc],FirstTransparent
    if b
        jmp .opaque ; ↓
    endif ; e3
    cmp byte [bp+0xc],LastTransparent
    if a
        jmp .opaque ; ↓
    endif ; ec
    ; Transparent tile
    push byte +0x20
    call far GetTileImagePos ; ee 3:2a3e
    add sp,byte +0x2
    mov [bp-0xa],ax
    mov [bp-0x8],dx
    mov al,[bp+0xe]
    push ax
    call far GetTileImagePos ; 100 3:2a3e
    add sp,byte +0x2
    push word [TileDC]
    push word [bp-0xa]
    push word [bp-0x8]
    push byte TileWidth
    push byte TileHeight
    push word [TileDC]
    push ax
    push dx
    push word 0xcc
    push byte +0x20
    call far GDI.BitBlt ; 121
    mov al,[bp+0xc]
    add al,0x60
    push ax
    call far GetTileImagePos ; 12c 3:2a3e
    add sp,byte +0x2
    push word [TileDC]
    push word [bp-0xa]
    push word [bp-0x8]
    push byte TileWidth
    push byte TileHeight
    push word [TileDC]
    push ax
    push dx
    push word 0xee
    push word 0x86
    call far GDI.BitBlt ; 14e
    mov al,[bp+0xc]
    add al,0x30
    push ax
    call far GetTileImagePos ; 159 3:2a3e
    add sp,byte +0x2
    push word [TileDC]
    push word [bp-0xa]
    push word [bp-0x8]
    push byte TileWidth
    push byte TileHeight
    push word [TileDC]
    push ax
    push dx
    push word 0x88
    push word 0xc6
    call far GDI.BitBlt ; 17b
    push word [bp+0x6]
    push word [bp+0x8]
    push word [bp+0xa]
    push byte TileWidth
    push byte TileHeight
    push word [TileDC]
    push word [bp-0xa]
    push word [bp-0x8]
    jmp short .blit ; ↓
    nop
.opaque: ; 19a
    ; Opaque tile
    mov al,[bp+0xc]
    push ax
    call far GetTileImagePos ; 19e 3:2a3e
    add sp,byte +0x2
    push word [bp+0x6]
    push word [bp+0x8]
    push word [bp+0xa]
    push byte TileWidth
    push byte TileHeight
    push word [TileDC]
    push ax
    push dx
.blit: ; 1b9
    push word 0xcc
    push byte +0x20
    call far GDI.BitBlt ; 1be
endfunc

; 1ca

func UpdateTile
    sub sp,byte +0x2
    push si
    mov si,[bp+0xa]
    push si
    push word [bp+0x8]
    call far IsCoordOnscreen ; 1df 2:7a
    add sp,byte +0x4
    or ax,ax
    jz .end ; ↓
    mov ax,si
    shl si,byte 0x5
    add si,[bp+0x8]
    add si,[GameStatePtr]
    mov cl,[si+Lower]
    push cx
    mov cl,[si+Upper]
    push cx
    mov bx,[GameStatePtr]
    sub ax,[bx+ViewportY]
    sub ax,[bx+UnusedOffsetY]
    shl ax,byte TileShift
    push ax
    mov ax,[bp+0x8]
    sub ax,[bx+ViewportX]
    sub ax,[bx+UnusedOffsetX]
    shl ax,byte TileShift
    push ax
    push word [bp+0x6]
    call far DrawTile ; 221 2:c4
    add sp,byte +0xa
.end: ; 229
    pop si
endfunc

; 232

func DrawInventoryTile
    sub sp,byte +0x2
    push byte +0x0
    mov al,[bp+0xc]
    push ax
    push word [bp+0xa]
    push word [bp+0x8]
    push word [bp+0x6]
    call far DrawTile ; 24e 2:c4
endfunc

; 25a

; void InvertTile(hdc, x, y)
; Invert the tile at the given coordinates. (unused)
func InvertTile_Unused
    sub sp,byte +0x2
    ; if the coordinate isn't onscreen, do nothing
    push word [bp+0xa]
    push word [bp+0x8]
    call far IsCoordOnscreen ; 26d 2:7a
    add sp,byte +0x4
    or ax,ax
    jz .end ; ↓
    ; PatBlt(hdc, (x-ViewportX)*32, (y-ViewportY)*32, 32, 32, DSTINVERT)
    push word [bp+0x6]
    mov ax,[bp+0x8]
    mov bx,[GameStatePtr]
    sub ax,[bx+ViewportX]
    sub ax,[bx+UnusedOffsetX]
    shl ax,byte TileShift
    push ax
    mov ax,[bp+0xa]
    sub ax,[bx+ViewportY]
    sub ax,[bx+UnusedOffsetY]
    shl ax,byte TileShift
    push ax
    push byte TileWidth
    push byte TileHeight
    push byte +0x55 ; DSTINVERT
    push byte +0x9
    call far GDI.PatBlt ; 2a6
.end: ; 2ab
endfunc

; 2b2

; Invalidate a tile, forcing it to be redrawn.
func InvalidateTile
    sub sp,byte +0xa
    push di
    push si
    push word [bp+0x8]
    push word [bp+0x6]
    call far IsCoordOnscreen ; 2c7 2:7a
    add sp,byte +0x4
    or ax,ax
    jz .end ; ↓
    push word [bp+0x8]
    push word [bp+0x6]
    call far GetTileRect ; 2d9 4:0
    add sp,byte +0x4
    lea di,[bp-0xa]
    mov si,ax
    push ss
    pop es
    movsw
    movsw
    movsw
    movsw
    push word [hwndBoard]
    lea ax,[bp-0xa]
    push ss
    push ax
    push byte +0x0
    call far USER.InvalidateRect ; 2f7
.end: ; 2fc
    pop si
    pop di
endfunc

; 306

func ScrollViewport
    sub sp,byte +0x1c
    push di
    push si
    %arg hdc:word ; +6
    %arg viewportDeltaX:word ; +8 number of tiles
    %arg viewportDeltaY:word ; +a to move viewport by
    %arg oldChipX:word ; +c
    %arg oldChipY:word ; +e
    %arg newChipX:word ; +10
    %arg newChipY:word ; +12
    %local local_4:word ; -4
    %local local_6:word ; -6
    %local local_8:word ; -8
    %local local_a:word ; -a
    %local yScrollPixels:word ; -c
    %local local_e:word ; -e
    %local local_10:word ; -10
    %local rect.bottom:word ; -12
    %local rect.right:word ; -14
    %local rect.top:word ; -16
    %local rect.left:word ; -18
    %define rect rect.left
    ;;; if viewport position didn't change, return
    mov di,[viewportDeltaX]
    or di,di
    jnz .label0 ; ↓
    cmp [viewportDeltaY],di
    jnz .label0 ; ↓
    jmp .end ; ↓
    ;;
.label0: ; 324
    ; si = 32*(dx - 0)
    mov bx,[GameStatePtr]
    mov si,di
    sub si,[bx+UnusedOffsetX]
    shl si,byte TileShift
    ; ax = 32*(dy - 0)
    mov ax,[viewportDeltaY]
    sub ax,[bx+UnusedOffsetY]
    shl ax,byte TileShift
    mov [yScrollPixels],ax
    ; GetClientRectangle(hwndBoard, &rect)
    ; Note: getClientRectangle returns only the width and height of the window,
    ; not the absolute coordinates. the width is in rect.right and the height
    ; in rect.bottom.
    %define rect.height rect.bottom
    %define rect.width rect.right
    push word [hwndBoard]
    lea ax,[rect]
    push ss
    push ax
    call far USER.GetClientRect ; 347
    ; vw-0
    mov bx,[GameStatePtr]
    mov ax,[bx+ViewportWidth]
    sub ax,[bx+UnusedOffsetX]
    ; dx = rect.width/32
    ; cx = rect.width/32 + 1
    mov cx,[rect.width]
    sar cx,byte TileShift
    mov dx,cx
    inc cx
    ; bx = vw-0
    mov bx,ax
    ; if vw-0 > rect.width/32+1 then ax = rect.width/32+1
    cmp ax,cx
    if g
        mov ax,cx
    endif ; 369
    ; stash ax
    mov [local_4],ax
    ; ax = vw-0
    mov ax,bx
    ; cx = vh-0
    mov bx,[GameStatePtr]
    mov cx,[bx+ViewportHeight]
    sub cx,[bx+UnusedOffsetY]
    ; bx = rect.height/32+1
    mov bx,[rect.height]
    sar bx,byte TileShift
    mov [bp-0x1a],bx
    inc bx
    mov [bp-0x1c],cx
    ; if cx > bx then cx = bx
    cmp cx,bx
    if g
        mov cx,bx
    endif ; 38d
    mov [local_e],cx
    ; ax = vw-0-1
    dec ax
    ; if ax > rect.width/32 then ax = dx
    cmp ax,dx
    if g
        mov ax,dx
    endif ; 397
    mov [local_6],ax
    ; ax = vh-0-1
    ; if ax > rect.height/32 then ax = rect.height/32
    mov ax,[bp-0x1c]
    dec ax
    cmp ax,[bp-0x1a]
    if g
        mov ax,[bp-0x1a]
    endif ; 3a6
    mov [local_10],ax
    ;; Draw chip in his new position, scroll the window,
    ;; set the new viewport position, and update the tile chip left
    ;
    ; UpdateTile(hdc, new x, new y)
    push word [newChipY]
    push word [newChipX]
    push word [bp+0x6]
    call far UpdateTile ; 3b2 2:1ca
    add sp,byte +0x6
    ; ScrollWindow(hwndBoard, -32*(dx-0), -32*(dy-0), NULL, NULL)
    push word [hwndBoard]
    ; x scroll amount = -32*(dx - 0)
    mov ax,si
    neg ax
    push ax
    ; y scroll amount = -32*(dy - 0)
    mov ax,[yScrollPixels]
    neg ax
    push ax
    push byte +0x0
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far USER.ScrollWindow ; 3d1
    ; update ViewportX and ViewportY
    mov bx,[GameStatePtr]
    add [bx+ViewportX],di
    mov ax,[viewportDeltaY]
    mov bx,[GameStatePtr]
    add [bx+ViewportY],ax
    ; UpdateTile(hdc, oldx, oldy)
    push word [oldChipY]
    push word [oldChipX]
    push word [bp+0x6]
    call far UpdateTile ; 3f2 2:1ca
    add sp,byte +0x6
    ;; Now draw any tiles that were
    ;; scrolled into view
.check_x_delta:
    ; skip if x delta is zero
    or si,si
    if z
        jmp .check_y_delta ; ↓
    endif ; 401
    or si,si
    if g
        mov ax,[local_6]
        sub ax,di ; ax -= delta x
        mov [local_a],ax
        mov bx,[local_4]
    else ; 412
        mov word [local_a],0x0
        mov bx,di
        neg bx
    endif ; 41b
    mov si,[GameStatePtr]
    mov ax,[si+ViewportY]
    mov [local_4],ax
    mov [local_8],bx
    mov cx,ax
    add ax,[si+ViewportHeight]
    cmp ax,cx
    if g
    .loop1: ; 433
        mov si,[local_a]
        cmp si,[local_8]
        if l
            mov di,[bp+0x6]
        .loop2: ; 43e
            ; UpdateTile(hdc, vx+0+si, local_4)
            push word [local_4]
            mov bx,[GameStatePtr]
            mov ax,[bx+ViewportX]
            add ax,[bx+UnusedOffsetX]
            add ax,si
            push ax
            push di
            call far UpdateTile ; 451 2:1ca
            add sp,byte +0x6
            inc si
            cmp si,[local_8]
            jl .loop2 ; ↑
        endif ; 45f
        mov bx,[GameStatePtr]
        mov ax,[bx+ViewportY]
        add ax,[bx+ViewportHeight]
        inc word [local_4]
        cmp ax,[local_4]
        jg .loop1 ; ↑
    endif ; 473
    ; rect = {local_a*32, -0*32, local_8*32, (vh-0)*32}
    ; ValidateRect(hwndBoard, &rect)
    mov ax,[local_a]
    shl ax,byte TileShift
    mov [rect.left],ax
    mov ax,[local_8]
    shl ax,byte TileShift
    mov [rect.right],ax
    mov bx,[GameStatePtr]
    mov ax,[bx+UnusedOffsetY]
    shl ax,byte TileShift
    neg ax
    mov [rect.top],ax
    mov ax,[bx+ViewportHeight]
    sub ax,[bx+UnusedOffsetY]
    shl ax,byte TileShift
    mov [rect.bottom],ax
    push word [hwndBoard]
    lea ax,[rect]
    push ss
    push ax
    call far USER.ValidateRect ; 4ac
.check_y_delta: ; 4b1
    ; skip if y delta is zero
    cmp word [yScrollPixels],byte +0x0
    if z
        jmp .end ; ↓
    endif ; 4ba
    if g
        mov di,[local_10]
        sub di,[viewportDeltaY]
        mov ax,[local_e]
    else ; 4c8
        xor di,di
        mov ax,[viewportDeltaY]
        neg ax
    endif ; 4cf
    mov [local_4],ax
    mov bx,[GameStatePtr]
    mov ax,[bx+ViewportX]
    mov [local_6],ax
    mov cx,ax
    add ax,[bx+ViewportWidth]
    cmp ax,cx
    if g
        mov [local_8],di
    .loop3: ; 4ea
        mov si,[local_8]
        cmp si,[local_4]
        if l
            mov di,[bp+0x6]
        .loop4: ; 4f5
            mov bx,[GameStatePtr]
            mov ax,[bx+ViewportY]
            add ax,[bx+UnusedOffsetY]
            add ax,si
            push ax
            push word [local_6]
            push di
            call far UpdateTile ; 508 2:1ca
            add sp,byte +0x6
            inc si
            cmp si,[local_4]
            jl .loop4 ; ↑
        endif ; 516
        mov bx,[GameStatePtr]
        mov ax,[bx+ViewportX]
        add ax,[bx+ViewportWidth]
        inc word [local_6]
        cmp ax,[local_6]
        jg .loop3 ; ↑
        mov di,[local_8]
    endif ; 52d
    ; rect = {-0*32, di*32, (vw-0)*32, (local_4-0)*32}
    ; ValidateRect(hwndBoard, &rect)
    mov ax,[bx+UnusedOffsetX]
    shl ax,byte TileShift
    neg ax
    mov [rect.left],ax
    mov ax,[bx+ViewportWidth]
    sub ax,[bx+UnusedOffsetX]
    shl ax,byte TileShift
    mov [rect.right],ax
    shl di,byte TileShift
    mov [rect.top],di
    mov ax,[local_4]
    shl ax,byte TileShift
    mov [rect.bottom],ax
    push word [hwndBoard]
    lea ax,[bp-0x18]
    push ss
    push ax
    call far USER.ValidateRect ; 55f
.end: ; 564
    pop si
    pop di
endfunc

; 56e

; void UpdateChip(hdc, new x, new y, old x, old y)
func UpdateChip
    sub sp,byte +0x6
    push si
    %arg hdc:word ; +6
    %arg newX:word ; +8
    %arg newY:word ; +a
    %arg oldX:word ; +c
    %arg oldY:word ; +e
    ;; calculate new viewportx (but do not store)
    ; ax = chipx - vw/2
    mov bx,[GameStatePtr]
    mov ax,[bx+ViewportWidth]
    mov cx,ax
    sub ax,0x20
    neg ax
    mov dx,ax
    mov ax,cx
    mov si,dx
    cwd
    sub ax,dx
    sar ax,1
    sub ax,[bp+0x8]
    neg ax
    ; clamp to [0, 32 - vw]
    or ax,ax
    if l
        xor ax,ax
    endif ; 5a1
    cmp ax,si
    if g
        mov ax,si
    endif ; 5a7
    ; cx = difference between new position and old position
    sub ax,[bx+ViewportX]
    mov [bp-0x6],ax
    mov cx,ax
    ;; calculate new ViewportY
    mov ax,[bx+ViewportHeight]
    mov dx,ax
    sub ax,0x20
    neg ax
    mov si,ax
    mov ax,dx
    cwd
    sub ax,dx
    sar ax,1
    sub ax,[newY]
    neg ax
    ; clamp to [0, 32 - vh]
    or ax,ax
    if l
        xor ax,ax
    endif ; 5cf
    cmp ax,si
    if g
        mov ax,si
    endif ; 5d5
    ; ax = difference between new y position and old position
    sub ax,[bx+ViewportY]
    ;; if viewport pos is the same, just update src and dest tiles
    or cx,cx
    jnz .viewportMoved ; ↓
    cmp ax,cx
    jnz .viewportMoved ; ↓
    ; UpdateTile(hdc, oldX, oldY)
    mov si,[hdc]
    push word [oldY]
    push word [oldX]
    push si
    call far UpdateTile ; 5eb 2:1ca
    add sp,byte +0x6
    ; UpdateTile(hdc, newX, newY)
    push word [newY]
    push word [newX]
    push si
    call far UpdateTile ; 5fa 2:1ca
    add sp,byte +0x6
    jmp short .end ; ↓
.viewportMoved: ; 604
    ; if viewport has moved, scroll the board
    push word [oldY] ; old chipy
    push word [oldX] ; old chipx
    push word [newY] ; new chipy
    push word [newX] ; new chipx
    push ax            ; viewport y diff
    push word [bp-0x6] ; viewport x diff
    push word [hdc]    ; hdc probably
    call far ScrollViewport ; 617 2:306
    add sp,byte +0xe
.end: ; 61f
    pop si
endfunc

; 628

func WinMain
    %assign %$argsize 0xa
    %arg nCmdShow:word ; +6
    %arg lpCmdLine:dword ; +8
    %arg hPrevInstance:word ; +c
    %arg hInstance:word ; +e
    sub sp,byte +0x14
    push word 0x218
    call far WEP4UTIL.FCHKWEPVERS ; 638
    or ax,ax
    if z
    .returnZero: ; 641
        xor ax,ax
        jmp short .end ; ↓
        nop
    endif ; 646
    cmp word [hPrevInstance],byte +0x0
    if z
        push word [hInstance]
        call far CreateClasses ; 64f 2:6c8
        add sp,byte +0x2
        or ax,ax
        jz .returnZero
    endif ; 65b
    push word [nCmdShow]
    push word [hInstance]
    call far CreateWindowsAndInitGame ; 661 2:8e8
    add sp,byte +0x4
    or ax,ax
    jz .returnZero
    mov word [Var2c],0x1
.messageLoop: ; 673
    lea ax,[bp-0x14]
    push ss
    push ax
    push byte +0x0
    push byte +0x0
    push byte +0x0
    push byte +0x1
    call far USER.PeekMessage ; 680
    or ax,ax
    ; FIXME: call WaitMessage if ax==0
    jz .messageLoop ; ↑
    cmp word [bp-0x12],byte +0x12
    jz .quit ; ↓
    push word [hwndMain]
    push word [hAccel]
    lea ax,[bp-0x14]
    push ss
    push ax
    call far USER.TranslateAccelerator ; 69c
    or ax,ax
    jnz .messageLoop ; ↑
    lea ax,[bp-0x14]
    push ss
    push ax
    call far USER.TranslateMessage ; 6aa
    lea ax,[bp-0x14]
    push ss
    push ax
    call far USER.DispatchMessage ; 6b4
    jmp short .messageLoop ; ↑
    nop
.quit: ; 6bc
    mov ax,[bp-0x10]
.end: ; 6bf
endfunc

; 6c8

func CreateClasses
    sub sp,byte +0x6a
    push si
    mov si,[bp+0x6]
    mov word [bp-0x6a],0x1000           ; style
    mov word [bp-0x68],MAINWNDPROC      ; lpfnWndProc
    mov word [bp-0x66],SEG MAINWNDPROC  ;
    xor ax,ax
    mov [bp-0x64],ax                    ; cbClassExtra
    mov [bp-0x62],ax                    ; cbWndExtra
    mov [bp-0x60],si                    ; hInstance
    push si
    push ax
    push word 0x100
    call far USER.LoadIcon ; 6f8
    mov [bp-0x5e],ax                    ; hIcon
    push byte +0x0
    push byte +0x0
    push word 0x7f00
    call far USER.LoadCursor ; 707
    mov [bp-0x5c],ax                    ; hCursor
    push byte +0x4
    call far GDI.GetStockObject ; 711
    mov [bp-0x5a],ax                    ; hbcBackground
    sub ax,ax
    mov [bp-0x56],ax                    ; lpszMenuName
    mov [bp-0x58],ax                    ;
    mov word [bp-0x54],MainClassName    ; lpszClassName
    mov [bp-0x52],ds                    ;
    lea ax,[bp-0x6a]
    push ss
    push ax
    call far USER.RegisterClass ; 72e
    or ax,ax
    if z
    .label0: ; 737
        xor ax,ax
        jmp .end ; ↓
    endif ; 73c
    mov word [bp-0x6a],0x8
    mov word [bp-0x68],BOARDWNDPROC
    mov word [bp-0x66],SEG BOARDWNDPROC
    xor ax,ax
    mov [bp-0x64],ax
    mov [bp-0x62],ax
    mov [bp-0x60],si
    mov [bp-0x5e],ax
    push ax
    push ax
    push word 0x7f03
    call far USER.LoadCursor ; 75e
    mov [bp-0x5c],ax
    push byte +0x4
    call far GDI.GetStockObject ; 768
    mov [bp-0x5a],ax
    sub ax,ax
    mov [bp-0x56],ax
    mov [bp-0x58],ax
    mov word [bp-0x54],BoardClassName
    mov [bp-0x52],ds
    lea ax,[bp-0x6a]
    push ss
    push ax
    call far USER.RegisterClass ; 785
    or ax,ax
    jz .label0 ; ↑
    mov word [bp-0x6a],0x8
    mov word [bp-0x68],INFOWNDPROC
    mov word [bp-0x66],SEG INFOWNDPROC
    xor ax,ax
    mov [bp-0x64],ax
    mov [bp-0x62],ax
    mov [bp-0x60],si
    mov [bp-0x5e],ax
    push ax
    push ax
    push word 0x7f00
    call far USER.LoadCursor ; 7b0
    mov [bp-0x5c],ax
    push byte +0x4
    call far GDI.GetStockObject ; 7ba
    mov [bp-0x5a],ax
    sub ax,ax
    mov [bp-0x56],ax
    mov [bp-0x58],ax
    mov word [bp-0x54],InfoClassName
    mov [bp-0x52],ds
    lea ax,[bp-0x6a]
    push ss
    push ax
    call far USER.RegisterClass ; 7d7
    or ax,ax
    if z
        jmp .label0 ; ↑
    endif ; 7e3
    mov word [bp-0x6a],0x8
    mov word [bp-0x68],COUNTERWNDPROC
    mov word [bp-0x66],SEG COUNTERWNDPROC
    mov word [bp-0x64],0x0
    mov word [bp-0x62],0x4
    mov [bp-0x60],si
    xor ax,ax
    mov [bp-0x5e],ax
    push ax
    push ax
    push word 0x7f00
    call far USER.LoadCursor ; 809
    mov [bp-0x5c],ax
    push byte +0x4
    call far GDI.GetStockObject ; 813
    mov [bp-0x5a],ax
    sub ax,ax
    mov [bp-0x56],ax
    mov [bp-0x58],ax
    mov word [bp-0x54],CounterClassName
    mov [bp-0x52],ds
    lea ax,[bp-0x6a]
    push ss
    push ax
    call far USER.RegisterClass ; 830
    or ax,ax
    if z
        jmp .label0 ; ↑
    endif ; 83c
    mov word [bp-0x6a],0x8
    mov word [bp-0x68],INVENTORYWNDPROC
    mov word [bp-0x66],SEG INVENTORYWNDPROC
    xor ax,ax
    mov [bp-0x64],ax
    mov [bp-0x62],ax
    mov [bp-0x60],si
    mov [bp-0x5e],ax
    push ax
    push ax
    push word 0x7f00
    call far USER.LoadCursor ; 85e
    mov [bp-0x5c],ax
    push byte +0x4
    call far GDI.GetStockObject ; 868
    mov [bp-0x5a],ax
    sub ax,ax
    mov [bp-0x56],ax
    mov [bp-0x58],ax
    mov word [bp-0x54],InventoryClassName
    mov [bp-0x52],ds
    lea ax,[bp-0x6a]
    push ss
    push ax
    call far USER.RegisterClass ; 885
    or ax,ax
    if z
        jmp .label0 ; ↑
    endif ; 891
    mov word [bp-0x6a],0x8
    mov word [bp-0x68],HINTWNDPROC
    mov word [bp-0x66],SEG HINTWNDPROC
    xor ax,ax
    mov [bp-0x64],ax
    mov [bp-0x62],ax
    mov [bp-0x60],si
    mov [bp-0x5e],ax
    push ax
    push ax
    push word 0x7f00
    call far USER.LoadCursor ; 8b3
    mov [bp-0x5c],ax
    push byte +0x4
    call far GDI.GetStockObject ; 8bd
    mov [bp-0x5a],ax
    sub ax,ax
    mov [bp-0x56],ax
    mov [bp-0x58],ax
    mov word [bp-0x54],HintClassName
    mov [bp-0x52],ds
    lea ax,[bp-0x6a]
    push ss
    push ax
    call far USER.RegisterClass ; 8da
.end: ; 8df
    pop si
endfunc

; 8e8

func CreateWindowsAndInitGame
    sub sp,byte +0x16
    push di
    push si
    %arg hInstance:word ; +6
    %arg nCmdShow:word ; +8
    mov si,[hInstance]
    mov word [bp-0x6],(WS_CLIPCHILDREN | WS_TILEDWINDOW)&0xffff
    mov word [bp-0x4],(WS_CLIPCHILDREN | WS_TILEDWINDOW)>>16
    mov [OurHInstance],si
    push si
    push ds
    push word s_ChipsMenu
    call far USER.LoadMenu ; 90d
    mov [hMenu],ax
    push byte +0x40
    push word GameStateSize
    call far KERNEL.LocalAlloc ; 91a
    mov [GameStatePtrCopy],ax
    mov [GameStatePtr],ax
    or ax,ax
    if z
    .label0: ; 929
        xor ax,ax
        jmp .end ; ↓
    endif ; 92e
    call far USER.GetCurrentTime ; 92e
    push ax
    call far srand ; 934 1:c4
    add sp,byte +0x2
    push byte +0x1
    call far InitGraphics ; 93e 5:0
    add sp,byte +0x2
    mov ax,[HorizontalPadding]
    mov [bp-0xe],ax
    mov cx,[VerticalPadding]
    mov [bp-0xc],cx
    add cx,TileHeight * 9
    mov [bp-0x8],cx
    add ax,TileWidth * 9
    mov [bp-0xa],ax
    xor dx,dx
    mov [bp-0x14],dx
    mov [bp-0x16],dx
    add cx,[VerticalPadding]
    mov [bp-0x10],cx
    add ax,[HorizontalPadding]
    add ax,0xa0
    mov [bp-0x12],ax
    lea ax,[bp-0x16]
    push ss                                             ; lpRect
    push ax
    push word (WS_CLIPCHILDREN | WS_TILEDWINDOW)>>16    ; dwStyle
    push dx ; 0
    push byte +0x1                                      ; bMenu
    call far USER.AdjustWindowRect ; 984
    push ds
    push word s_MainClass
    push ds
    push word MainWindowCaption ; "Chip's Challenge"
    push word (WS_CLIPCHILDREN | WS_TILEDWINDOW)>>16
    push byte (WS_CLIPCHILDREN | WS_TILEDWINDOW)&0xffff
    push word 0x8000 ; x = CW_USEDEFAULT
    push word 0x8000 ; y = CW_USEDEFAULT
    mov ax,[bp-0x12]
    sub ax,[bp-0x16]
    push ax
    mov ax,[bp-0x10]
    sub ax,[bp-0x14]
    push ax
    push byte +0x0
    push word [hMenu]
    push si
    push byte +0x0
    push byte +0x0
    call far USER.CreateWindow ; 9b5
    mov [hwndMain],ax
    or ax,ax
    if z
        jmp .label0 ; ↑
    endif ; 9c4
    push ds
    push word s_BoardClass
    push byte +0x0
    push byte +0x0
    push word 0x5000
    push byte +0x0
    push word [bp-0xe]
    push word [bp-0xc]
    mov ax,[bp-0xa]
    sub ax,[bp-0xe]
    push ax
    mov ax,[bp-0x8]
    sub ax,[bp-0xc]
    push ax
    push word [hwndMain]
    push byte +0x1
    push si
    push byte +0x0
    push byte +0x0
    call far USER.CreateWindow ; 9f0
    mov [hwndBoard],ax
    or ax,ax
    if z
        jmp .label0 ; ↑
    endif ; 9ff
    push ds
    push word s_InfoClass
    push byte +0x0
    push byte +0x0
    push word 0x5200
    push byte +0x0
    mov ax,[HorizontalPadding]
    add ax,TileWidth * 9 + 0x13
    push ax
    mov ax,[VerticalPadding]
    sub ax,0x6
    push ax
    push word 0x9a
    push word 0x12c
    push word [hwndMain]
    push byte +0x7
    push si
    push byte +0x0
    push byte +0x0
    call far USER.CreateWindow ; a2b
    mov [hwndInfo],ax
    or ax,ax
    if z
        jmp .label0 ; ↑
    endif ; a3a
    push ds
    push word s_CounterClass1
    push byte +0x0
    push byte +0x0
    push word 0x5400
    push byte +0x0
    push byte +0x2d
    push byte +0x22
    push byte +0x37
    push byte +0x1d
    push ax
    push byte +0x2
    push si
    push byte +0x0
    push byte +0x0
    call far USER.CreateWindow ; a57
    mov [hwndCounter],ax
    or ax,ax
    jnz .label5 ; ↓
    jmp .label0 ; ↑
.label5: ; a66
    push ds
    push word s_CounterClass2
    push byte +0x0
    push byte +0x0
    push word 0x5400
    push byte +0x0
    push byte +0x2d
    push byte +0x60
    push byte +0x37
    push byte +0x1d
    push word [hwndInfo]
    push byte +0x3
    push si
    push byte +0x0
    push byte +0x0
    call far USER.CreateWindow ; a86
    mov [hwndCounter2],ax
    or ax,ax
    if z
        jmp .label0 ; ↑
    endif ; a95
    push ds
    push word s_CounterClass3
    push byte +0x0
    push byte +0x0
    push word 0x5400
    push byte +0x0
    push byte +0x2d
    push word 0xba
    push byte +0x37
    push byte +0x1d
    push word [hwndInfo]
    push byte +0x4
    push si
    push byte +0x0
    push byte +0x0
    call far USER.CreateWindow ; ab6
    mov [hwndCounter3],ax
    or ax,ax
    if z
        jmp .label0 ; ↑
    endif ; ac5
    push ds
    push word s_InventoryClass
    push byte +0x0
    push byte +0x0
    push word 0x5400
    push byte +0x0
    push byte 0x4d - TileWidth*2
    push word 0xfd - TileWidth
    push word TileWidth * 4
    push byte TileWidth * 2
    push word [hwndInfo]
    push byte +0x5
    push si
    push byte +0x0
    push byte +0x0
    call far USER.CreateWindow ; ae7
    mov [hwndInventory],ax
    or ax,ax
    if z
        jmp .label0 ; ↑
    endif ; af6
    mov di,[nCmdShow]
    cmp di,byte +0x6
    jz .label9 ; ↓
    cmp di,byte +0x2
    jz .label9 ; ↓
    cmp di,byte +0x7
    jnz .label10 ; ↓
.label9: ; b08
    call far PauseTimer ; b08 2:17a2
    inc word [GamePaused]
.label10: ; b11
    push word [hwndMain]
    push di
    call far USER.ShowWindow ; b16
    push word [hwndMain]
    call far USER.UpdateWindow ; b1f
    push word ID_CurrentLevel
    call far GetIniInt ; b27 2:198e
    add sp,byte +0x2
    cmp ax,0x1
    if l
        mov si,0x1
    else ; b3a
        push word ID_CurrentLevel
        call far GetIniInt ; b3d 2:198e
        add sp,byte +0x2
        mov si,ax
    endif ; b47
    push word ID_CurrentScore
    call far GetIniLong ; b4a 2:1a1c
    add sp,byte +0x2
    or dx,dx
    if l
        xor ax,ax
        cwd
    else ; b5c
        push word ID_CurrentScore
        call far GetIniLong ; b5f 2:1a1c
        add sp,byte +0x2
    endif ; b67
    mov [TotalScore+_LoWord],ax
    mov [TotalScore+_HiWord],dx
    cmp si,byte +0x1
    if g
        push si
        call far TryIniPassword ; b74 4:e48
        add sp,byte +0x2
        or ax,ax
        if z
            mov si,0x1
        endif
    endif ; b83
    push byte +0x0
    push si
    call far FUN_4_0356 ; b86 4:356
    add sp,byte +0x4
    mov ax,0x1
.end: ; b91
    pop si
    pop di
endfunc

; b9a

func ShowDeathMessage
    sub sp,byte +0x6
    push si
    mov si,[SoundEnabled]
    mov word [SoundEnabled],0x0
    mov bx,[GameStatePtr]
    mov ax,[bx+Autopsy]
    dec ax
    cmp ax,0x5
    ja .default ; ↓
    shl ax,1
    xchg ax,bx
    jmp [cs:.jumpTable+bx]
.jumpTable:
    dw .label1 ; Burned
    dw .label2 ; Drowned
    dw .label3 ; Bombed
    dw .label4 ; Squished
    dw .label5 ; Eaten
    dw .label6 ; OutOfTime
.default: ; bd4
    mov ax,s_Ooops
    jmp short .showMessage ; ↓
    nop
.label1: ; bda
    mov ax,FireDeathMessage
    jmp short .showMessage ; ↓
    nop
.label2: ; be0
    mov ax,WaterDeathMessage
    jmp short .showMessage ; ↓
    nop
.label3: ; be6
    mov ax,BombDeathMessage
    jmp short .showMessage ; ↓
    nop
.label4: ; bec
    mov ax,BlockDeathMessage
    jmp short .showMessage ; ↓
    nop
.label5: ; bf2
    mov ax,MonsterDeathMessage
    jmp short .showMessage ; ↓
    nop
.label6: ; bf8
    mov ax,TimeDeathMessage
.showMessage: ; bfb
    mov cx,ax
    push byte +0x0
    push ds
    push cx
    push word [hwndMain]
    call far ShowMessageBox ; c05 2:0
    add sp,byte +0x8
    mov [SoundEnabled],si
    pop si
endfunc

; c1a

func ShowHint
    sub sp,byte +0x2
    cmp word [hwndHint],byte +0x0
    jnz .end ; ↓
    push ds
    push word s_HintClass
    push byte +0x0
    push byte +0x0
    push word 0x5400
    push byte +0x0
    push byte +0xd
    push word 0x8b
    push word 0x80
    push word 0x92
    push word [hwndInfo]
    push byte +0x6
    push word [OurHInstance]
    push byte +0x0
    push byte +0x0
    call far USER.CreateWindow ; c54
    mov [hwndHint],ax
    or ax,ax
    jz .end ; ↓
    push word [hwndCounter3]
    push byte +0x0
    call far USER.ShowWindow ; c66
    push word [hwndInventory]
    push byte +0x0
    call far USER.ShowWindow ; c71
.end: ; c76
endfunc

; c7e

func HideHint
    sub sp,byte +0x2
    cmp word [hwndHint],byte +0x0
    jz .end ; ↓
    push word [hwndHint]
    call far USER.DestroyWindow ; c96
    mov word [hwndHint],0x0
    push word [hwndCounter3]
    push byte +0x5
    call far USER.ShowWindow ; ca7
    push word [hwndInventory]
    push byte +0x5
    call far USER.ShowWindow ; cb2
.end: ; cb7
endfunc

; cbe

; refresh timer, chip counter, inventory and hint box
func FUN_2_0cbe
    sub sp,byte +0x2
    push di
    push si
    mov si,[bp+0x6]
    ; Update timer
    test si,0x1
    if nz
        push word [hwndCounter2]
        push byte +0x0
        push word [TimeRemaining]
        call far USER.SetWindowWord ; ce0
        push word [hwndCounter2]
        push byte +0x2
        call far USER.GetWindowWord ; ceb
        and al,0xfe
        mov di,ax
        cmp word [TimeRemaining],byte +0xf
        if le
            or di,byte +0x1
        endif ; cfe
        push word [hwndCounter2]
        push byte +0x2
        push di
        call far USER.SetWindowWord ; d05
        push word [hwndCounter2]
        push byte +0x0
        push byte +0x0
        push byte +0x0
        call far USER.InvalidateRect ; d14
    endif ; d19
    ; Update chips remaining
    test si,0x2
    if nz
        push word [hwndCounter3]
        push byte +0x0
        push word [ChipsRemainingCount]
        call far USER.SetWindowWord ; d29
        push word [hwndCounter3]
        push byte +0x2
        cmp word [ChipsRemainingCount],byte +0x1
        sbb ax,ax
        neg ax
        push ax
        call far USER.SetWindowWord ; d3e
        push word [hwndCounter3]
        push byte +0x0
        push byte +0x0
        push byte +0x0
        call far USER.InvalidateRect ; d4d
    endif ; d52
    ; Update level number
    test si,0x20
    if nz
        push word [hwndCounter]
        push byte +0x0
        mov bx,[GameStatePtr]
        push word [bx+LevelNumber]
        call far USER.SetWindowWord ; d66
        push word [hwndCounter]
        push byte +0x0
        push byte +0x0
        push byte +0x0
        call far USER.InvalidateRect ; d75
    endif ; d7a
    ; Update inventory
    test si,0x4
    if nz
        push word [hwndInventory]
        push byte +0x0
        push byte +0x0
        push byte +0x0
        call far USER.InvalidateRect ; d8a
    endif ; d8f
    ; Update hint
    mov ax,si
    test al,0x8
    if nz
        mov bx,[GameStatePtr]
        mov si,[bx+ChipY]
        shl si,byte 0x5
        add si,[bx+ChipX]
        cmp byte [bx+si+Lower],Hint
        if e
            call far ShowHint ; dab 2:c1a
        else ; db2
            call far HideHint ; db2 2:c7e
        endif
    endif ; db7
    mov word [InventoryDirty],0x0
    pop si
    pop di
endfunc

; dc6

; draw main window background
func PaintBackground
    %arg hwnd:word ; +6
    %arg rect:word ; +8
    sub sp,byte +0x20
    push di
    push si
    push word [OurHInstance]
    push ds
    push word s_background
    call far USER.LoadBitmap ; ddd
    mov si,ax
    or si,si
    if z
        jmp .fallback ; ↓
    endif ; deb
    mov di,[rect]
    push word [TileDC]
    push si
    call far GDI.SelectObject ; df3
    mov [bp-0x8],ax
    push si
    push byte +0xe
    lea ax,[bp-0x20]
    push ss
    push ax
    call far GDI.GetObject ; e03
    mov ax,[di+0x6]
    cwd
    idiv word [bp-0x1c]
    imul word [bp-0x1c]
    mov [bp-0x6],ax
    mov ax,[di+0x4]
    cwd
    idiv word [bp-0x1e]
    imul word [bp-0x1e]
    mov [bp-0x4],ax
    cmp ax,[di+0x8]
    jnl .label4 ; ↓
    mov [bp-0xa],si
.loop: ; e2a
    mov si,[bp-0x6]
    cmp si,[di+0xa]
    jnl .label3 ; ↓
.loop2: ; e32
    push word [di]
    push word [bp-0x4]
    push si
    push word [bp-0x1e]
    push word [bp-0x1c]
    push word [TileDC]
    push byte +0x0
    push byte +0x0
    push word 0xcc
    push byte +0x20
    call far GDI.BitBlt ; e4b
    add si,[bp-0x1c]
    cmp si,[di+0xa]
    jl .loop2 ; ↑
.label3: ; e58
    mov ax,[di+0x8]
    mov cx,[bp-0x1e]
    add [bp-0x4],cx
    cmp [bp-0x4],ax
    jl .loop ; ↑
    mov si,[bp-0xa]
.label4: ; e69
    push word [TileDC]
    push word [bp-0x8]
    call far GDI.SelectObject ; e70
    push si
    call far GDI.DeleteObject ; e76
    jmp short .drawBorders ; ↓
    nop
.fallback: ; e7e
    ; If we couldn't load the background bitmap,
    ; draw something else instead
    mov bx,[rect]
    push word [bx]
    push word [bx+0x4]
    push word [bx+0x6]
    mov ax,[bx+0x8]
    sub ax,[bx+0x4]
    push ax
    mov ax,[bx+0xa]
    sub ax,[bx+0x6]
    push ax
    push byte +0x0
    push byte +0x42
    call far GDI.PatBlt ; e9b
.drawBorders: ; ea0
    mov ax,[HorizontalPadding]
    mov [bp-0x12],ax
    mov cx,[VerticalPadding]
    mov [bp-0x10],cx
    add cx,TileWidth * 9
    mov [bp-0xc],cx
    add ax,TileHeight * 9
    mov [bp-0xe],ax
    push byte +0x2
    push cx
    push ax
    push word [bp-0x10]
    push word [bp-0x12]
    mov bx,[rect]
    push word [bx]
    call far DrawSolidBorder ; ec9 2:1006
    add sp,byte +0xc
    lea ax,[bp-0x12]
    push ss
    push ax
    push byte +0x2
    push byte +0x2
    call far USER.InflateRect ; eda
    push byte +0x1
    push byte +0x4
    push word [bp-0xc]
    push word [bp-0xe]
    push word [bp-0x10]
    push word [bp-0x12]
    mov bx,[rect]
    push word [bx]
    call far Draw3DBorder ; ef4 2:f06
    add sp,byte +0xe
    pop si
    pop di
endfunc

; f06

; Draw an inset/outset border
func Draw3DBorder
    %arg hdc:word ; +6
    %arg rect.x0:word ; +8
    %arg rect.y0:word
    %arg rect.x1:word
    %arg rect.y1:word
    %define rect rect.x0
    %arg borderWidth:word ; +10
    %arg inset:word ; +12 or outset?
    %local bottomRightBrush:word ; -4 HGDIOBJ
    %local topLeftBrush:word     ; -6 HGDIOBJ
    %local savedObj:word         ; -8 HGDIOBJ
    sub sp,byte +0x8
    push di
    push si
    mov si,[bp+0x12]
    ; get a GRAY_BRUSH or a WHITE_BRUSH
    ; depending on whether si == 0 or not
    cmp si,byte +0x1
    sbb ax,ax
    and ax,0x2
    push ax
    call far GDI.GetStockObject ; f21
    mov di,ax
    ; get a GRAY_BRUSH or a WHITE_BRUSH
    ; depending on whether si != 0 or not
    cmp si,byte +0x1
    cmc
    sbb ax,ax
    and ax,0x2
    push ax
    call far GDI.GetStockObject ; f32
    mov [bp-0x4],ax
    ; select the first brush
    push word [hdc]
    push di
    call far GDI.SelectObject ; f3e
    mov [savedObj],ax
    cmp word [borderWidth],byte +0x0
    if le
        jmp .cleanup ; ↓
    endif ; f4f
    mov [topLeftBrush],di
    mov si,[hdc]
    mov di,[borderWidth]
.loop: ; f58
    lea ax,[rect]
    push ss
    push ax
    push byte +0x1
    push byte +0x1
    call far USER.InflateRect ; f61
    push si
    push word [topLeftBrush]
    call far GDI.SelectObject ; f6a
    push si
    mov ax,[rect.x0]
    inc ax
    push ax
    push word [rect.y0]
    mov ax,[rect.x1]
    sub ax,[rect.x0]
    sub ax,0x2
    push ax
    push byte +0x1
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call far GDI.PatBlt ; f89
    push si
    push word [rect.x0]
    push word [rect.y0]
    push byte +0x1
    mov ax,[rect.y1]
    sub ax,[rect.y0]
    dec ax
    push ax
    push word 0xf0
    push byte +0x21
    call far GDI.PatBlt ; fa4
    push si
    push word [bottomRightBrush]
    call far GDI.SelectObject ; fad
    push si
    push word [rect.x0]
    mov ax,[rect.y1]
    dec ax
    push ax
    mov ax,[rect.x1]
    sub ax,[rect.x0]
    dec ax
    push ax
    push byte +0x1
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call far GDI.PatBlt ; fca
    push si
    mov ax,[rect.x1]
    dec ax
    push ax
    push word [rect.y0]
    push byte +0x1
    mov ax,[rect.y1]
    sub ax,[rect.y0]
    push ax
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call far GDI.PatBlt ; fe6
    dec di
    if nz
        jmp .loop ; ↑
    endif
.cleanup: ; ff1
    ; restore the selected object
    push word [hdc]
    push word [savedObj]
    call far GDI.SelectObject ; ff7
    pop si
    pop di
endfunc

; 1006

; draw a solid border
func DrawSolidBorder
    %arg hdc:word
    %arg rect.x0:word ; +8
    %arg rect.y0:word
    %arg rect.x1:word
    %arg rect.y1:word
    %define rect rect.x0
    %arg borderWidth:word ; +10
    %local savedObj:word ; -4
    sub sp,byte +0x4
    push di
    push si
    mov si,[hdc]
    ; get a light gray brush and select it
    push si
    push byte +0x1 ; LTGRAY BRUSH
    call far GDI.GetStockObject ; 101b
    push ax
    call far GDI.SelectObject ; 1021
    mov [savedObj],ax
    ; check a flag
    cmp word [borderWidth],byte +0x0
    if le
        jmp .cleanup ; ↓
    endif ; 1032
    mov di,[borderWidth]
.loop: ; 1035
    lea ax,[rect]
    push ss
    push ax
    push byte +0x1
    push byte +0x1
    call far USER.InflateRect ; 103e
    push si ; HDC
    mov ax,[rect.x0]
    inc ax
    push ax
    push word [rect.y0]
    mov ax,[rect.x1]
    sub ax,[rect.x0]
    sub ax,0x2
    push ax
    push byte +0x1
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call far GDI.PatBlt ; 105d
    push si ; HDC
    push word [rect.x0]
    push word [rect.y0]
    push byte +0x1
    mov ax,[rect.y1]
    sub ax,[rect.y0]
    dec ax
    push ax
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call far GDI.PatBlt ; 1078
    push si ; HDC
    push word [rect.x0]
    mov ax,[rect.y1]
    dec ax
    push ax
    mov ax,[rect.x1]
    sub ax,[rect.x0]
    dec ax
    push ax
    push byte +0x1
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call far GDI.PatBlt ; 1095
    push si ; HDC
    mov ax,[rect.x1]
    dec ax
    push ax
    push word [rect.y0]
    push byte +0x1
    mov ax,[rect.y1]
    sub ax,[rect.y0]
    push ax
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call far GDI.PatBlt ; 10b1
    dec di
    if nz
        jmp .loop ; ↑
    endif
.cleanup: ; 10bc
    push si ; HDC
    push word [savedObj]
    call far GDI.SelectObject ; 10c0
    pop si
    pop di
endfunc

; 10ce

; Draw board
; and level placard
; and/or pause screen
func PaintBoardWindow
    sub sp,0xcc
    push di
    push si
    cmp word [GamePaused],byte +0x0
    if z
        jmp .label7 ; ↓
    endif ; 10e8
    cmp word [DebugModeEnabled],byte +0x0
    if nz
        jmp .label7 ; ↓
    endif ; 10f2
    mov si,[bp+0x8]
    push word [bp+0x6]
    lea ax,[bp-0x26]
    push ss
    push ax
    call far USER.GetClientRect ; 10fd
    push word [si]
    push word [bp-0x26]
    push word [bp-0x24]
    mov ax,[bp-0x22]
    sub ax,[bp-0x26]
    push ax
    mov ax,[bp-0x20]
    sub ax,[bp-0x24]
    push ax
    push byte +0x0
    push byte +0x42
    call far GDI.PatBlt ; 111c
    ; computes font height by multiplying the desired point size by the screen's DPI,
    ; as suggested by Microsoft's documentation:
    ; (https://docs.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-logfonta)
    ;
    ;    lfHeight = MulDiv(-32, GetDeviceCaps(hDC, LOGPIXELSY), 72)
    push byte -0x20
    push word [si]
    push byte +0x5a ; LOGPIXELSY
    call far GDI.GetDeviceCaps ; 1127
    push ax
    push byte +0x48
    call far GDI.MulDiv ; 112f
    mov [LOGFONT.lfHeight],ax
    mov word [LOGFONT.lfWeight],400
    mov byte [LOGFONT.lfItalic],0
    push ds
    push word LOGFONT.lfFaceName ; Arial
    cmp word [IsWin31],byte +0x0
    if ne
        mov ax,s_Arial1
    else ; 1152
        mov ax,s_Helv1
    endif ; 1155
    mov [bp-0x6],ax
    mov [bp-0x4],ds
    push ds
    push ax
    call far KERNEL.lstrcpy ; 115d
    push ds
    push word LOGFONT
    call far GDI.CreateFontIndirect ; 1166
    mov di,ax
    or di,di
    if z
        jmp .end ; ↓
    endif ; 1174
    push word [si]
    push di
    call far GDI.SelectObject ; 1177
    mov [bp-0x1a],ax
    push word [si]
    push byte +0x2
    call far GDI.SetBkMode ; 1183
    mov [bp-0x1c],ax
    push word [si]
    push byte +0x0
    push byte +0x0
    call far GDI.SetBkColor ; 1191
    mov [bp-0x14],ax
    mov [bp-0x12],dx
    push word [si]
    mov [bp-0xc8],si
    mov [bp-0xca],di
    cmp word [ColorMode],byte +0x1
    if z
        mov ax,0xffff
        mov dx,0xff
    else ; 11b6
        mov ax,0xff
        cwd
    endif ; 11ba
    push dx
    push ax
    call far GDI.SetTextColor ; 11bc
    mov [bp-0x18],ax
    mov [bp-0x16],dx
    mov bx,[bp-0xc8]
    push word [bx]
    push ds
    push word s_PAUSED
    push byte +0x6
    lea ax,[bp-0x26]
    push ss
    push ax
    push word 0x925
    call far USER.DrawText ; 11db
    mov bx,[bp-0xc8]
    push word [bx]
    push word [bp-0x1c]
    call far GDI.SetBkMode ; 11e9
    mov bx,[bp-0xc8]
    push word [bx]
    push word [bp-0x12]
    push word [bp-0x14]
    call far GDI.SetBkColor ; 11fa
    mov bx,[bp-0xc8]
    push word [bx]
    push word [bp-0x16]
    push word [bp-0x18]
    call far GDI.SetBkColor ; 120b
    mov bx,[bp-0xc8]
    push word [bx]
    push word [bp-0x1a]
    call far GDI.SelectObject ; 1219
    push word [bp-0xca]
    jmp .label42 ; ↓
    nop
.label7: ; 1226
    mov bx,[GameStatePtr]
    cmp word [bx+EndingTick],byte +0x0
    if nz
        push byte +0x1
        call far EndGame ; 1233 7:a74
        add sp,byte +0x2
        jmp .end ; ↓
    endif ; 123e
    cmp word [bx+ViewportWidth],byte +0x0
    if z
        jmp .end ; ↓
    endif ; 1248
    cmp word [bx+ViewportHeight],byte +0x0
    if z
        jmp .end ; ↓
    endif ; 1252
    mov si,[bp+0x8]
    mov ax,[si+0x4]
    sar ax,byte TileShift
    add ax,[bx+ViewportX]
    add ax,[bx+UnusedOffsetX]
    cmp ax,[bx+ViewportX]
    if l
        mov ax,[bx+ViewportX]
    endif ; 126d
    mov [bp-0x8],ax
    mov ax,[bx+ViewportX]
    mov cx,ax
    add ax,[bx+ViewportWidth]
    mov di,[si+0x8]
    add di,byte TileWidth-1
    sar di,byte TileShift
    add di,cx
    add di,[bx+UnusedOffsetX]
    dec ax
    cmp di,ax
    if g
        mov di,ax
    endif ; 1290
    mov ax,[bx+ViewportY]
    mov cx,ax
    add ax,[bx+ViewportHeight]
    mov dx,[si+0xa]
    add dx,byte TileHeight-1
    sar dx,byte TileShift
    mov bx,cx
    add cx,dx
    mov dx,bx
    mov bx,[GameStatePtr]
    add cx,[bx+UnusedOffsetY]
    dec ax
    cmp cx,ax
    if g
        mov cx,ax
    endif ; 12b8
    mov [bp-0xa],cx
    mov ax,[si+0x6]
    sar ax,byte TileShift
    mov bx,dx
    add dx,ax
    mov ax,bx
    mov bx,[GameStatePtr]
    add dx,[bx+UnusedOffsetY]
    cmp dx,ax
    if l
        mov dx,ax
    endif ; 12d5
    mov [bp-0x6],dx
    cmp cx,dx
    if l
        jmp .label24 ; ↓
    endif ; 12df
    mov [bp-0x4],di
.label16: ; 12e2
    mov si,[bp-0x8]
    cmp si,di
    jg .label18 ; ↓
.label17: ; 12e9
    push word [bp-0x6]
    push si
    mov bx,[bp+0x8]
    push word [bx]
    call far UpdateTile ; 12f2 2:1ca
    add sp,byte +0x6
    inc si
    cmp si,di
    jng .label17 ; ↑
.label18: ; 12ff
    mov ax,[bp-0xa]
    inc word [bp-0x6]
    cmp [bp-0x6],ax
    jng .label16 ; ↑
    mov si,[bp+0x8]
.label19: ; 130d
    mov dx,[bp-0x4]
    mov bx,[GameStatePtr]
    sub dx,[bx+ViewportX]
    sub dx,[bx+UnusedOffsetX]
    inc dx
    shl dx,byte TileShift
    mov [bp-0x8],dx
    mov di,[bp-0xa]
    sub di,[bx+ViewportY]
    sub di,[bx+UnusedOffsetY]
    inc di
    shl di,byte TileShift
    cmp dx,[si+0x8]
    if l
        push word [si]
        push dx
        push word [si+0x6]
        mov ax,[si+0x8]
        sub ax,dx
        push ax
        mov ax,[si+0xa]
        sub ax,[si+0x6]
        push ax
        push byte +0x0
        push byte +0x42
        call far GDI.PatBlt ; 134e
    endif ; 1353
    cmp [si+0xa],di
    if g
        push word [si]
        push word [si+0x4]
        push di
        mov ax,[si+0x8]
        sub ax,[si+0x4]
        push ax
        sub di,[si+0xa]
        neg di
        push di
        push byte +0x0
        push byte +0x42
        call far GDI.PatBlt ; 136f
    endif ; 1374
    mov bx,[GameStatePtr]
    cmp word [bx+IsLevelPlacardVisible],byte +0x0
    if z
        jmp .end ; ↓
    endif ; 1382
    cmp byte [bx+LevelTitle],0x0
    if z
        cmp byte [bx+LevelPassword],0x0
        if z
            jmp .end ; ↓
        endif
    endif ; 1393
    cmp word [ColorMode],byte +0x1
    jnz .label25
    mov ax,0xffff
    mov dx,0xff
    jmp short .label26 ; ↓
.label24: ; 13a2
    mov [bp-0x4],di
    jmp .label19 ; ↑
.label25: ; 13a8
    mov ax,0xffff
    xor dx,dx
.label26: ; 13ad
    mov [bp-0x6],ax
    mov [bp-0x4],dx
    push word [si]
    push byte +0x2
    call far GDI.SetBkMode ; 13b7
    mov [bp-0x1c],ax
    push word [si]
    push byte +0x0
    push byte +0x0
    call far GDI.SetBkColor ; 13c5
    mov [bp-0x14],ax
    mov [bp-0x12],dx
    push word [si]
    push word [bp-0x4]
    push word [bp-0x6]
    call far GDI.SetTextColor ; 13d8
    mov [bp-0x18],ax
    mov [bp-0x16],dx
    mov word [bp-0x1e],0x0
    mov word [bp-0xe],0x10
.label27: ; 13ed
    mov ax,[bp-0xe]
    neg ax
    push ax
    mov bx,[bp+0x8]
    push word [bx]
    push byte +0x5a ; LOGPIXELSY
    call far GDI.GetDeviceCaps ; 13fa
    push ax
    push byte +0x48
    call far GDI.MulDiv ; 1402
    mov [LOGFONT.lfHeight],ax
    mov word [LOGFONT.lfWeight],700
    mov byte [LOGFONT.lfItalic],0
    push ds
    push word LOGFONT.lfFaceName
    cmp word [IsWin31],byte +0x0
    if nz
        mov ax,s_Arial2
    else ; 1426
        mov ax,s_Helv2
    endif ; 1429
    mov si,ax
    mov [bp-0x4],ds
    push ds
    push ax
    call far KERNEL.lstrcpy ; 1430
    push ds
    push word LOGFONT
    call far GDI.CreateFontIndirect ; 1439
    mov [bp-0x10],ax
    or ax,ax
    if nz
        mov bx,[bp+0x8]
        push word [bx]
        push ax
        call far GDI.SelectObject ; 144b
        mov [bp-0x1a],ax
    endif ; 1453
    mov bx,[bp+0x8]
    push word [bx]
    lea ax,[bp-0x46]
    push ss
    push ax
    call far GDI.GetTextMetrics ; 145d
    mov ax,[bp-0x46]
    mov [bp-0x4],ax
    xor ax,ax
    mov [bp-0xa],ax
    mov [bp-0x6],ax
    mov bx,[GameStatePtr]
    mov cx,[bx+ViewportWidth]
    shl cx,byte TileShift
    mov [bp-0x8],cx
    ; this is a convoluted way of checking if LevelTitle starts with a NUL
    ; we cache the result in di for later reference
    cmp byte [bx+LevelTitle],0x1
    sbb cx,cx
    inc cx
    mov di,cx
    cmp cx,ax ; note ax=0
    if nz
        mov [bp-0x26],ax
        mov [bp-0x24],ax
        mov cx,1000
        mov [bp-0x22],cx
        mov [bp-0x20],cx
        mov cx,bx
        add cx,LevelTitle
        push ds
        push cx
        push ds
        push word s_5b5 ; " %s "
        lea cx,[bp-0xc6]
        push ss
        push cx
        call far USER._wsprintf ; 14ad
        add sp,byte +0xc
        mov si,ax
        mov bx,[bp+0x8]
        push word [bx]
        lea ax,[bp-0xc6]
        push ss
        push ax
        push si
        lea ax,[bp-0x26]
        push ss
        push ax
        push word 0xd21
        call far USER.DrawText ; 14cb
        mov [bp-0x20],ax
        mov ax,[bp-0x22]
        sub ax,[bp-0x26]
        if s
            xor ax,ax
        endif ; 14dd
        mov [bp-0x6],ax
        mov ax,[bp-0x20]
        sub ax,[bp-0x24]
        mov [bp-0xa],ax
    endif ; 14e9
    ; same deal, but the password instead of the title
    ; we cache the result in si
    mov bx,[GameStatePtr]
    cmp byte [bx+LevelPassword],0x1
    sbb ax,ax
    inc ax
    mov si,ax
    or ax,ax
    if nz
        xor ax,ax
        mov [bp-0x26],ax
        mov [bp-0x24],ax
        mov ax,1000
        mov [bp-0x22],ax
        mov [bp-0x20],ax
        mov ax,bx
        add ax,LevelPassword
        push ds
        push ax
        push ds
        push word s_5ba ; " Password: %s "
        lea ax,[bp-0xc6]
        push ss
        push ax
        call far USER._wsprintf ; 151d
        add sp,byte +0xc
        mov [bp-0xc],ax
        mov bx,[bp+0x8]
        push word [bx]
        lea ax,[bp-0xc6]
        push ss
        push ax
        push word [bp-0xc]
        lea ax,[bp-0x26]
        push ss
        push ax
        push word 0xd21
        call far USER.DrawText ; 153e
        mov [bp-0x20],ax
        mov ax,[bp-0x22]
        sub ax,[bp-0x26]
        cmp ax,[bp-0x6]
        if l
            mov ax,[bp-0x6]
        endif ; 1554
        mov [bp-0x6],ax
        mov ax,[bp-0x20]
        sub ax,[bp-0x24]
        add [bp-0xa],ax
    endif ; 1560
    mov ax,[bp-0x6]
    add ax,0x8
    cmp ax,[bp-0x8]
    jng .label35 ; ↓
    cmp word [bp-0xe],byte +0x6
    jng .label35 ; ↓
    jmp .label40 ; ↓
.label35: ; 1574
    mov word [bp-0x1e],0x1
    or di,di ; level title is nonempty
    jz .label36 ; ↓
    or si,si ; password is nonempt
    jz .label36 ; ↓
    mov word [bp-0xc],0x3
    jmp short .label37 ; ↓
.label36: ; 1588
    mov word [bp-0xc],0x2
.label37: ; 158d
    mov ax,[bp-0x4]
    imul word [bp-0xc]
    mov bx,[GameStatePtr]
    mov cx,[bx+ViewportHeight]
    shl cx,byte TileShift
    sub cx,ax
    mov [bp-0x24],cx
    mov ax,[bp-0x8]
    sub ax,[bp-0x6]
    cwd
    sub ax,dx
    sar ax,1
    mov [bp-0xcc],ax
    mov [bp-0x26],ax
    mov bx,[bp+0x8]
    push word [bx]
    push ax
    push cx
    push word [bp-0x6]
    push word [bp-0xa]
    push byte +0x0
    push byte +0x42
    call far GDI.PatBlt ; 15c6
    mov word [bp-0x26],0x0
    mov ax,[bp-0x4]
    add ax,[bp-0x24]
    mov [bp-0x20],ax
    mov ax,[bp-0x8]
    mov [bp-0x22],ax
    or di,di ; level title is nonempty
    if nz
        mov ax,[GameStatePtr]
        add ax,LevelTitle
        push ds
        push ax
        push ds
        push word s_5c9 ; " %s "
        lea ax,[bp-0xc6]
        push ss
        push ax
        call far USER._wsprintf ; 15f5
        add sp,byte +0xc
        mov di,ax
        mov bx,[bp+0x8]
        push word [bx]
        lea ax,[bp-0xc6]
        push ss
        push ax
        push di
        lea ax,[bp-0x26]
        push ss
        push ax
        push word 0x821
        call far USER.DrawText ; 1613
        mov ax,[bp-0x4]
        add [bp-0x24],ax
        add [bp-0x20],ax
    endif ; 1621
    or si,si ; password is nonempty
    if nz
        mov ax,[GameStatePtr]
        add ax,LevelPassword
        push ds
        push ax
        push ds
        push word s_5ce ; " Password: %s "
        lea ax,[bp-0xc6]
        push ss
        push ax
        call far USER._wsprintf ; 1637
        add sp,byte +0xc
        mov si,ax
        mov bx,[bp+0x8]
        push word [bx]
        lea ax,[bp-0xc6]
        push ss
        push ax
        push si
        lea ax,[bp-0x26]
        push ss
        push ax
        push word 0x821
        call far USER.DrawText ; 1655
        mov ax,[bp-0x4]
        add [bp-0x24],ax
        add [bp-0x20],ax
    endif ; 1663
    mov ax,[bp-0xcc]
    mov [bp-0x26],ax
    add ax,[bp-0x6]
    mov [bp-0x22],ax
    mov ax,[bp-0x20]
    sub ax,[bp-0xa]
    sub ax,[bp-0x4]
    mov [bp-0x24],ax
    add ax,[bp-0xa]
    mov [bp-0x20],ax
    push byte +0x1
    push byte +0x4
    push ax
    push word [bp-0x22]
    push word [bp-0x24]
    push word [bp-0x26]
    mov bx,[bp+0x8]
    push word [bx]
    call far Draw3DBorder ; 1695 2:f06
    add sp,byte +0xe
.label40: ; 169d
    dec word [bp-0xe]
    cmp word [bp-0x1e],byte +0x0
    if z
        jmp .label27 ; ↑
    endif ; 16a9
    mov di,[bp-0x10]
    mov bx,[bp+0x8]
    push word [bx]
    push word [bp-0x1c]
    call far GDI.SetBkMode ; 16b4
    mov bx,[bp+0x8]
    push word [bx]
    push word [bp-0x12]
    push word [bp-0x14]
    call far GDI.SetBkColor ; 16c4
    mov bx,[bp+0x8]
    push word [bx]
    push word [bp-0x16]
    push word [bp-0x18]
    call far GDI.SetBkColor ; 16d4
    or di,di
    jz .end ; ↓
    mov bx,[bp+0x8]
    push word [bx]
    push word [bp-0x1a]
    call far GDI.SelectObject ; 16e5
    push di
.label42: ; 16eb
    call far GDI.DeleteObject ; 16eb
.end: ; 16f0
    pop si
    pop di
endfunc

; 16fa

; create timer
; if the timer already exists, it is reset
func StartTimer
    sub sp,byte +0x6
    push si
    mov ax,[bp+0x6]
    dec ax
    jz .label0 ; ↓
    dec ax
    jz .label1 ; ↓
    mov cx,[bp-0x4]
    mov si,[bp-0x6]
    jmp short .label3 ; ↓
    nop
.label0: ; 171a
    mov si,110 ; milliseconds
    jmp short .label2 ; ↓
    nop
.label1: ; 1720
    mov si,220 ; milliseconds
.label2: ; 1723
    mov cx,[hwndBoard]
.label3: ; 1727
    push cx             ; hWnd
    push word [bp+0x6]  ; nIDEvent
    push si             ; uElapse
    push byte +0x0      ; lpTimerFunc
    push byte +0x0
    call far USER.SetTimer ; 1730
    or ax,ax
    jnz .label4 ; ↓
    push byte +0x30
    push ds
    push word SystemTimerErrorMsg
    push word [hwndMain]
    call far ShowMessageBox ; 1743 2:0
    add sp,byte +0x8
    push word [hwndMain]
    push word 0x111
    push byte ID_QUIT
    push byte +0x0
    push byte +0x0
    call far USER.PostMessage ; 1758
    xor ax,ax
    jmp short .label5 ; ↓
    nop
.label4: ; 1762
    mov ax,0x1
.label5: ; 1765
    pop si
endfunc

; 176e

; destroy timer
func StopTimer
    sub sp,byte +0x4
    push si
    mov si,[bp+0x6]
    mov ax,si
    dec ax
    jl .label0 ; ↓
    jo .label0 ; ↓
    dec ax
    jng .label1 ; ↓
.label0: ; 1789
    mov cx,[bp-0x4]
    jmp short .label2 ; ↓
.label1: ; 178e
    mov cx,[hwndBoard]
.label2: ; 1792
    push cx
    push si
    call far USER.KillTimer ; 1794
    pop si
endfunc

; 17a2

; void PauseTimer()
;
; Stops the game tick from advancing.
; This function can be called multiple times;
; the timer will only resume when a matching number of
; calls to UnpauseTimer are made.
func PauseTimer
    sub sp,byte +0x2
    inc word [Var22]
endfunc

; 17ba

; void UnpauseTimer()
func UnpauseTimer
    sub sp,byte +0x2
    mov ax,[Var22]
    dec ax
    if s
        xor ax,ax
    endif ; 17cf
    mov [Var22],ax
endfunc

; 17da

; Pause the game and show the pause screen.
; Also updates the check state of the Pause menu item.
func PauseGame
    sub sp,byte +0x2
    call far PauseTimer ; 17e7 2:17a2
    push word [hMenu]
    push byte ID_PAUSE
    inc word [GamePaused]
    cmp word [GamePaused],byte +0x0
    if g
        mov ax,0x8 ; MF_CHECKED
    else ; 1802
        xor ax,ax
    endif ; 1804
    push ax
    call far USER.CheckMenuItem ; 1805
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    push word [hwndMain]
    call far UpdateWindowTitle ; 1816 4:134
    add sp,byte +0x4
    push word [hwndBoard]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far USER.InvalidateRect ; 1828
endfunc

; 1834

; Pause the game and hide the pause screen.
; Also updates the check state of the Pause menu item.
func UnpauseGame
    sub sp,byte +0x2
    push word [hMenu]
    push byte ID_PAUSE
    mov ax,[GamePaused]
    dec ax
    if s
        xor ax,ax
    endif ; 184f
    mov [GamePaused],ax
    or ax,ax
    if g
        mov ax,0x8 ; MF_CHECKED
    else ; 185c
        xor ax,ax
    endif ; 185e
    push ax
    call far USER.CheckMenuItem ; 185f
    push word [hwndMain]
    call far USER.DrawMenuBar ; 1868
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    push word [hwndMain]
    call far UpdateWindowTitle ; 1879 4:134
    add sp,byte +0x4
    push word [hwndBoard]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far USER.InvalidateRect ; 188b
    call far UnpauseTimer ; 1890 2:17ba
endfunc

; 189c

func PauseMusic
    sub sp,byte +0x2
    call far StopMIDI ; 18a9 8:2d4
endfunc

; 18b6

func UnpauseMusic
    sub sp,byte +0x2
    cmp word [MusicEnabled],byte +0x0
    if nz
        mov bx,[GameStatePtr]
        push word [bx+LevelNumber]
        call far FUN_8_0308 ; 18d2 8:308
    endif ; 18d7
endfunc

; 18de

; char* GetIniKey(int id, int* pDefaultValue)
;
; Returns the key for the requested INI setting.
; If pDefaultValue is not NULL, it is set to the default
; value for the requested key.
func GetIniKey
    sub sp,byte +0x2
    mov ax,[bp+0x6]
    cmp ax,ID_HighestLevel
    jz .highestLevelKey
    if ng
        sub ax,117
        jz .midiKey
        dec ax ; 118
        jz .soundsKey
        sub ax,4 ; 122
        jz .colorKey
        jmp .end
        nop
        nop
        nop
    endif ; 1908
    sub ax,ID_CurrentLevel
    jz .currentLevelKey
    dec ax ; 202 ID_CurrentScore
    jz .currentScoreKey
    dec ax ; 203 ID_NumMidiFiles
    jz .numMidiFilesKey
    jmp short .end
    nop
    ;;
.midiKey: ; 1916
    mov bx,[bp+0x8]
    or bx,bx
    if nz
        mov word [bx],MusicEnabledDefault
    endif ; 1921
    mov ax,MIDIKey
    jmp short .returnString
    ;;
.soundsKey: ; 1926
    mov bx,[bp+0x8]
    or bx,bx
    if nz
        mov word [bx],SoundEnabledDefault
    endif ; 1931
    mov ax,SoundsKey
    jmp short .returnString
    ;;
.colorKey: ; 1936
    mov bx,[bp+0x8]
    or bx,bx
    if nz
        mov word [bx],ColorDefault
    endif ; 1941
    mov ax,ColorKey
    jmp short .returnString
    ;;
.highestLevelKey: ; 1946
    mov bx,[bp+0x8]
    or bx,bx
    if nz
        mov word [bx],FirstLevel
    endif ; 1951
    mov ax,HighestLevelKey
    jmp short .returnString
    ;;
.currentLevelKey: ; 1956
    mov bx,[bp+0x8]
    or bx,bx
    if nz
        mov word [bx],FirstLevel
    endif ; 1961
    mov ax,CurrentLevelKey
    jmp short .returnString
    ;;
.currentScoreKey: ; 1966
    mov bx,[bp+0x8]
    or bx,bx
    if nz
        mov word [bx],0x0
    endif
    mov ax,CurrentScoreKey
    jmp short .returnString
    ;;
.numMidiFilesKey: ; 1976
    mov bx,[bp+0x8]
    or bx,bx
    if nz
        mov word [bx],NumMidiFilesDefault
    endif ; 1981
    mov ax,NumMidiFilesKey ; "Number of Midi Files"
.returnString:
    mov dx,ds
.end: ; 1986
endfunc

; 198e

; int GetIniInt(int id)
func GetIniInt
    sub sp,byte +0x8
    push si
    lea ax,[bp-0x8]
    push ax
    push word [bp+0x6]
    call far GetIniKey ; 19a3 2:18de
    add sp,byte +0x4
    mov si,ax
    mov [bp-0x4],dx
    push ds
    push word IniSectionName
    push dx
    push si
    push word [bp-0x8]
    push ds
    push word IniFileName
    call far KERNEL.GetPrivateProfileInt ; 19bd
    pop si
endfunc

; 19ca

; StoreIniInt(int id, int value)
func StoreIniInt
    sub sp,byte +0x16
    push si
    push byte +0x0
    push word [bp+0x6]
    call far GetIniKey ; 19dd 2:18de
    add sp,byte +0x4
    mov si,ax
    mov [bp-0x4],dx
    push word [bp+0x8]
    push ds
    push word s_5dd ; "%d"
    lea ax,[bp-0x16]
    push ss
    push ax
    call far USER._wsprintf ; 19f6
    add sp,byte +0xa
    push ds
    push word IniSectionName
    push word [bp-0x4]
    push si
    lea ax,[bp-0x16]
    push ss
    push ax
    push ds
    push word IniFileName
    call far KERNEL.WritePrivateProfileString ; 1a0f
    pop si
endfunc

; 1a1c

; long GetIniLong(int id)
;
; Retrieves an long int value from the INI file.
func GetIniLong
    sub sp,byte +0x28
    push si
    lea ax,[bp-0x8]
    push ax
    push word [bp+0x6]
    call far GetIniKey ; 1a31 2:18de
    add sp,byte +0x4
    mov si,ax
    mov [bp-0x4],dx
    mov ax,[bp-0x8]
    cwd
    push dx
    push ax
    push ds
    push word s_5e0 ; "%li"
    lea ax,[bp-0x18]
    push ss
    push ax
    call far USER._wsprintf ; 1a4d
    add sp,byte +0xc
    push ds
    push word IniSectionName
    push word [bp-0x4]
    push si
    lea ax,[bp-0x18]
    push ss
    push ax
    lea ax,[bp-0x28]
    push ss
    push ax
    push byte +0x10
    push ds
    push word IniFileName
    call far KERNEL.GetPrivateProfileString ; 1a6d
    lea ax,[bp-0x28]
    push ax
    call far atol ; 1a76 1:c0
    add sp,byte +0x2
    pop si
endfunc

; 1a86

; StoreIniLong(int id, long value)
func StoreIniLong
    sub sp,byte +0x16
    push si
    push byte +0x0
    push word [bp+0x6]
    call far GetIniKey ; 1a99 2:18de
    add sp,byte +0x4
    mov si,ax
    mov [bp-0x4],dx
    push word [bp+0xa]
    push word [bp+0x8]
    push ds
    push word s_5e4 ; "%li"
    lea ax,[bp-0x16]
    push ss
    push ax
    call far USER._wsprintf ; 1ab5
    add sp,byte +0xc
    push ds
    push word IniSectionName
    push word [bp-0x4]
    push si
    lea ax,[bp-0x16]
    push ss
    push ax
    push ds
    push word IniFileName
    call far KERNEL.WritePrivateProfileString ; 1ace
    pop si
endfunc

; 1adc

; GetLevelProgressFromIni
;
; Parses lines in the INI file like:
;       Level1=FRST,999,12340
;       Level2=SCND
func GetLevelProgressFromIni
    sub sp,byte +0x24
    push di
    push si
    push word [bp+0x6]
    push ds
    push word s_5e8 ; "Level%d"
    lea ax,[bp-0x10]
    push ss
    push ax
    call far USER._wsprintf ; 1af7
    add sp,byte +0xa
    push ds
    push word IniSectionName
    lea ax,[bp-0x10]
    push ss
    push ax
    push ds
    push word s_2c4 ; ""
    lea ax,[bp-0x24]
    push ss
    push ax
    push byte +0x13
    push ds
    push word IniFileName
    call far KERNEL.GetPrivateProfileString ; 1b17
    mov di,ax
    cmp di,byte +0x4
    jnl .label0 ; ↓
    xor ax,ax
    jmp .label15 ; ↓
.label0: ; 1b28
    lea ax,[(bp-0x24) + di]
    mov [bp-0x6],ax
    lea si,[bp-0x24]
    cmp byte [si],0x0
    jz .label2 ; ↓
.label1: ; 1b36
    cmp byte [si],','
    jz .label2 ; ↓
    inc si
    cmp byte [si],0x0
    jnz .label1 ; ↑
.label2: ; 1b41
    mov byte [si],0x0
    cmp word [bp+0x8],byte +0x0
    jz .label3 ; ↓
    push ds
    push word [bp+0x8]
    lea ax,[bp-0x24]
    push ss
    push ax
    call far KERNEL.lstrcpy ; 1b53
.label3: ; 1b58
    cmp word [bp+0xa],byte +0x0
    jz .label4 ; ↓
    mov bx,[bp+0xa]
    mov word [bx],0xffff
.label4: ; 1b65
    cmp word [bp+0xc],byte +0x0
    jz .label5 ; ↓
    mov bx,[bp+0xc]
    mov word [bx],0xffff
    mov word [bx+0x2],0xffff
.label5: ; 1b77
    inc si
    cmp si,[bp-0x6]
    jb .label6 ; ↓
    jmp .label14 ; ↓
.label6: ; 1b80
    mov [bp-0x4],si
    cmp byte [si],0x0
    jz .label8 ; ↓
.label7: ; 1b88
    cmp byte [si],','
    jz .label8 ; ↓
    inc si
    cmp byte [si],0x0
    jnz .label7 ; ↑
.label8: ; 1b93
    mov byte [si],0x0
    cmp word [bp+0xa],byte +0x0
    jz .label10 ; ↓
    push word [bp-0x4]
    call far atoi ; 1b9f 1:bc
    add sp,byte +0x2
    or ax,ax
    jnl .label9 ; ↓
    mov bx,[bp+0xa]
    mov word [bx],0x0
    jmp short .label10 ; ↓
.label9: ; 1bb4
    push word [bp-0x4]
    call far atoi ; 1bb7 1:bc
    add sp,byte +0x2
    mov bx,[bp+0xa]
    mov [bx],ax
.label10: ; 1bc4
    inc si
    cmp si,[bp-0x6]
    jnb .label14 ; ↓
    mov [bp-0x4],si
    mov di,[bp+0xc]
    cmp byte [si],0x0
    jz .label12 ; ↓
.label11: ; 1bd5
    cmp byte [si],','
    jz .label12 ; ↓
    inc si
    cmp byte [si],0x0
    jnz .label11 ; ↑
.label12: ; 1be0
    mov byte [si],0x0
    or di,di
    jz .label14 ; ↓
    push word [bp-0x4]
    call far atol ; 1bea 1:c0
    add sp,byte +0x2
    or dx,dx
    jnl .label13 ; ↓
    sub ax,ax
    mov [di+0x2],ax
    mov [di],ax
    jmp short .label14 ; ↓
    nop
.label13: ; 1c00
    push word [bp-0x4]
    call far atol ; 1c03 1:c0
    add sp,byte +0x2
    mov [di],ax
    mov [di+0x2],dx
.label14: ; 1c10
    mov ax,0x1
.label15: ; 1c13
    pop si
    pop di
endfunc

; 1c1c

; SaveLevelProgressToIni
;
; Writes a level password to the ini file,
; and (optionally) a completion time and score.
func SaveLevelProgressToIni
    sub sp,byte +0x4c
    push si
    mov si,[bp+0x8]
    push word [bp+0x6]
    push ds
    push word s_5f0 ; "Level%d"
    lea ax,[bp-0xc]
    push ss
    push ax
    call far USER._wsprintf ; 1c39
    add sp,byte +0xa
    or si,si
    if ge
        push word [bp+0xc]
        push word [bp+0xa]
        push si
        mov ax,[GameStatePtr]
        add ax,LevelPassword
        push ds
        push ax
        push ds
        push word s_5f8 ; "%s,%d,%li"
        lea ax,[bp-0x4c]
        push ss
        push ax
        call far USER._wsprintf ; 1c5d
        add sp,byte +0x12
    else ; 1c68
        mov ax,[GameStatePtr]
        add ax,LevelPassword
        ; TODO: could remove this printf call...
        push ds
        push ax
        push ds
        push word s_602 ; "%s"
        lea ax,[bp-0x4c]
        push ss
        push ax
        call far USER._wsprintf ; 1c79
        add sp,byte +0xc
    endif ; 1c81
    push ds
    push word IniSectionName
    lea ax,[bp-0xc]
    push ss
    push ax
    lea ax,[bp-0x4c]
    push ss
    push ax
    push ds
    push word IniFileName
    call far KERNEL.WritePrivateProfileString ; 1c93
    pop si
endfunc

; 1ca0

; get midi or sound effect path
func GetAudioPath
    %arg index:word     ; +0x6  Index of the MIDI or Sound entry
    %arg buffer:word    ; +0x8  Buffer to store the file name
    %arg bufSize:word   ; +0xA  Size of the file name buffer
    %arg isSound:word   ; +0xC  Looking for a sound (non-zero) or MIDI file (zero)
    sub sp,byte +0x16
    push di
    push si
    cmp word [isSound],byte +0x0
    if nz
        ; Sound effect
        mov si,[index]
        mov bx,si
        mov di,[SoundKeyArray+(bx+si)]
    else  ; 1cc0
        ; MIDI
        mov si,[index]
        push si
        push ds
        push word s_605 ; "MidiFile%d"
        lea ax,[bp-0x16]
        push ss
        push ax
        call far USER._wsprintf ; 1ccd
        add sp,byte +0xa
        lea di,[bp-0x16]
    endif ; 1cd8
    push ds
    push word IniSectionName
    push ds
    push di
    push ds
    push word s_610 ; "$"
    push ds
    push word [buffer]
    push word [bufSize]
    push ds
    push word IniFileName
    call far KERNEL.GetPrivateProfileString ; 1ced
    mov bx,[buffer]
    cmp byte [bx],'$'
    if nz
        jmp .label9 ; ↓
    endif ; 1cfd
    mov [bp-0x6],di
    cmp byte [bx+0x1],0x0
    if nz
        jmp .label9 ; ↓
    endif ; 1d09
    cmp word [isSound],byte +0x0
    jnz .label4 ; ↓
    cmp si,byte +0x3
    jl .label4 ; ↓
    mov byte [bx],0x0
    jmp .label9 ; ↓
.label4: ; 1d1a
    cmp word [isSound],byte +0x0
    if nz
        ; Sound effect
        push ds
        push bx
        mov bx,[index]
        shl bx,1
        push ds
        push word [SoundDefaultArray+bx]
    else ; 1d2e
        ; MIDI
        mov ax,bx
        mov [bp-0x4],ax
        cmp word [index],byte +0x2
        jnz .label7 ; ↓
        push ds
        push ax
        mov bx,[index]
        shl bx,1
        push ds
        push word [MidiFileDefaultArray+bx]
        call far KERNEL.lstrlen ; 1d45
        sub ax,[bufSize]
        neg ax
        dec ax
        push ax
        call far KERNEL.GetWindowsDirectory ; 1d51
        mov si,ax
        or si,si
        if nz
            mov bx,[bp-0x4]
            add bx,si
            cmp byte [bx-0x1],'\'
            if nz
                mov bx,[bp-0x4]
                mov byte [bx+si],'\'
                inc word [bp-0x4]
            endif ; 1d70
            add [bp-0x4],si
        endif
    .label7: ; 1d73
        push ds
        push word [bp-0x4]
        mov bx,[index]
        shl bx,1
        push ds
        push word [bx+MidiFileDefaultArray]
    endif ; 1d81
    call far KERNEL.lstrcpy ; 1d81
    push ds
    push word IniSectionName
    push ds
    push word [bp-0x6]
    push ds
    push word [buffer]
    push ds
    push word IniFileName
    call far KERNEL.WritePrivateProfileString ; 1d96
.label9: ; 1d9b
    push ds
    push word [buffer]
    call far KERNEL.lstrlen ; 1d9f
    pop si
    pop di
endfunc

; 1dae

; ResetLevelProgressInIni
FUN_2_1dae:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0xe
    push di
    push si
    mov si,0x1
    push word ID_HighestLevel
    call far GetIniInt ; 1dc3 2:198e
    add sp,byte +0x2
    mov di,ax
    cmp di,byte +0x1
    jl .label1 ; ↓
    mov [bp-0x4],di
.loop: ; 1dd5
    push si
    push ds
    push word s_612 ; "Level%d"
    lea ax,[bp-0xe]
    push ss
    push ax
    call far USER._wsprintf ; 1ddf
    add sp,byte +0xa
    push ds
    push word IniSectionName
    lea ax,[bp-0xe]
    push ss
    push ax
    push byte +0x0
    push byte +0x0
    push ds
    push word IniFileName
    call far KERNEL.WritePrivateProfileString ; 1df8
    inc si
    cmp si,di
    jng .loop ; ↑
.label1: ; 1e02
    push byte FirstLevel
    push word ID_HighestLevel
    call far StoreIniInt ; 1e07 2:19ca
    add sp,byte +0x4
    push byte +0x0
    push byte +0x0
    push word ID_CurrentScore
    call far StoreIniLong ; 1e16 2:1a86
    add sp,byte +0x6
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 1e28

func MenuItemCallback
    sub sp,byte +0xc
    push di
    push si
    mov ax,[bp+0xa]
    sub ax,0x64
    cmp ax,0x16
    ja .default ; ↓
    shl ax,1
    xchg ax,bx
    jmp [cs:.jumpTable+bx]
.jumpTable:
    dw .label1 ; 100 ID_ABOUT
    dw .default ; 101
    dw .default ; 102
    dw .default ; 103
    dw .default ; 104
    dw .default ; 105
    dw .label3 ; 106 ID_QUIT
    dw .label4 ; 107 ID_HELP
    dw .label6 ; 108 ID_CHEAT
    dw .label8 ; 109 ID_METAHELP
    dw .label9 ; 110 ID_NEXT
    dw .label14 ; 111 ID_PREVIOUS
    dw .default ; 112
    dw .label18 ; 113 ID_RESTART
    dw .label19 ; 114 ID_NEWGAME
    dw .label21 ; 115 ID_BESTTIMES
    dw .label22 ; 116 ID_PAUSE
    dw .label24 ; 117 ID_BGM
    dw .label27 ; 118 ID_SOUND
    dw .label29 ; 119 ID_GOTO
    dw .label31 ; 120 ID_HOWTOPLAY
    dw .label32 ; 121 ID_COMMANDS
    dw .label33 ; 122 ID_COLOR

.default: ; 1e78
    push word [bp+0x6]
    push word [bp+0x8]
    push word [bp+0xa]
    push word [bp+0xe]
    push word [bp+0xc]
    call far USER.DefWindowProc ; 1e87
    jmp .label43 ; ↓
    nop

.label1: ; 1e90
    call far PauseGame ; 1e90 2:17da
    push word [OurHInstance]
    push word [bp+0x6]
    call far WEP4UTIL.WEPABOUT2
.label2: ; 1ea1
    call far UnpauseGame ; 1ea1 2:1834
    jmp .label42 ; ↓
    nop

.label3: ; 1eaa
    mov si,[bp+0x6]
    push si
    push byte +0x0
    call far USER.ShowWindow ; 1eb0
    push si
    call far USER.DestroyWindow ; 1eb6
    jmp .label42 ; ↓

.label4: ; 1ebe
    mov word [Var2a],0x1
    push word [OurHInstance]
    push word [bp+0x6]
    push word 0x101
    push ds
    push word s_Contents
.label5: ; 1ed2
    call far WEP4UTIL.WEPHELP ; 1ed2
    jmp .label42 ; ↓

.label6: ; 1eda
    push word [hMenu]
    push byte ID_CHEAT
    cmp word [IgnorePasswords],byte +0x1
    sbb ax,ax
    neg ax
    mov [IgnorePasswords],ax
    cmp ax,0x1
.label7: ; 1eef
    cmc
    sbb ax,ax
    and ax,0x8 ; MF_CHECKED
    push ax
    call far USER.CheckMenuItem ; 1ef6
    push word [hwndMain]
    call far USER.DrawMenuBar ; 1eff
    jmp .label42 ; ↓
    nop

.label8: ; 1f08
    mov word [Var2a],0x1
    push word [OurHInstance]
    push word [bp+0x6]
    push byte +0x4
    push byte +0x0
    push byte +0x0
    jmp short .label5 ; ↑
    nop

.label9: ; 1f1e
    mov bx,[GameStatePtr]
    mov ax,[bx+LevelNumber]
    inc ax
    push ax
    push word [bp+0x6]
    call far FUN_4_115c ; 1f2b 4:115c
    add sp,byte +0x4
    or ax,ax
    if z
        jmp .label42 ; ↓
    endif ; 1f3a
    push byte +0x0
    mov bx,[GameStatePtr]
    mov ax,[bx+LevelNumber]
    inc ax
.label11: ; 1f45
    push ax
.label12: ; 1f46
    call far FUN_4_0356 ; 1f46 4:356
.label13: ; 1f4b
    add sp,byte +0x4
    jmp .label42 ; ↓
    nop

.label14: ; 1f52
    mov bx,[GameStatePtr]
    cmp word [bx+LevelNumber],byte +0x1
    if le
        jmp .label42 ; ↓
    endif ; 1f60
    mov ax,[bx+LevelNumber]
    dec ax
    cmp ax,0x1
    if l
        mov ax,0x1
    endif ; 1f6d
    push ax
    push word [bp+0x6]
    call far FUN_4_115c ; 1f71 4:115c
    add sp,byte +0x4
    or ax,ax
    if z
        jmp .label42 ; ↓
    endif ; 1f80
    push byte +0x0
    mov bx,[GameStatePtr]
    mov ax,[bx+LevelNumber]
    dec ax
    jns .label11 ; ↑
    xor ax,ax
    jmp short .label11 ; ↑
    nop

.label18: ; 1f92
    push byte +0x1
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    jmp short .label12 ; ↑

.label19: ; 1f9e
    push word ID_HighestLevel
    call far GetIniInt ; 1fa1 2:198e
    add sp,byte +0x2
    dec ax
    if nz
        push byte +0x24
        push ds
        push word NewGamePrompt
        push word [hwndMain]
        call far ShowMessageBox ; 1fb6 2:0
        add sp,byte +0x8
        cmp ax,ID_YES
        if ne
            jmp .label42 ; ↓
        endif
    endif ; 1fc6
    call far FUN_2_1dae ; 1fc6 2:1dae
    sub ax,ax
    mov [TotalScore+_HiWord],ax
    mov [TotalScore+_LoWord],ax
    push ax
    push byte FirstLevel
    jmp .label12 ; ↑
    nop

.label21: ; 1fda
    call far PauseGame ; 1fda 2:17da
    push word SEG BESTTIMESMSGPROC ; 1fdd 6:18e BESTTIMESMSGPROC
    push word BESTTIMESMSGPROC
    push word [OurHInstance]
    call far KERNEL.MakeProcInstance ; 1fe9
    mov si,ax
    mov [bp-0x4],dx
    push word [OurHInstance]
    push ds
    push word s_DLG_BESTTIMES
    push word [hwndMain]
    mov ax,dx
    push ax
    push si
    mov di,dx
    call far USER.DialogBox ; 2005
    push di
    push si
    call far KERNEL.FreeProcInstance ; 200c
    jmp .label2 ; ↑

.label22: ; 2014
    cmp word [GamePaused],byte +0x0
    if nz
        call far UnpauseMusic ; 201b 2:18b6
        jmp .label2 ; ↑
        nop
    endif ; 2024
    call far PauseMusic ; 2024 2:189c
    call far PauseGame ; 2029 2:17da
    jmp .label42 ; ↓
    nop

.label24: ; 2032
    cmp word [MusicEnabled],byte +0x1
    sbb ax,ax
    neg ax
    mov [MusicEnabled],ax
    or ax,ax
    if z
        call far StopMIDI ; 2042 8:2d4
    else ; 204a
        mov bx,[GameStatePtr]
        push word [bx+LevelNumber]
        call far FUN_8_0308 ; 2052 8:308
        add sp,byte +0x2
    endif ; 205a
    push word [MusicEnabled]
    push byte ID_BGM
    call far StoreIniInt ; 2060 2:19ca
    add sp,byte +0x4
    push word [hMenu]
    push byte ID_BGM
    cmp word [MusicEnabled],byte +0x1
    jmp .label7 ; ↑

.label27: ; 2076
    cmp word [SoundEnabled],byte +0x1
    sbb ax,ax
    neg ax
    mov [SoundEnabled],ax
    push ax
    push byte ID_SOUND
    call far StoreIniInt ; 2085 2:19ca
    add sp,byte +0x4
    push word [hMenu]
    push byte ID_SOUND
    cmp word [SoundEnabled],byte +0x1
    cmc
    sbb ax,ax
    and ax,0x8 ; MF_CHECKED
    push ax
    call far USER.CheckMenuItem ; 209f
    push word [hwndMain]
    call far USER.DrawMenuBar ; 20a8
    cmp word [SoundEnabled],byte +0x0
    if z
        jmp .label42 ; ↓
    endif ; 20b7
    push byte +0x1
    push byte +0x7
    call far PlaySoundEffect ; 20bb 8:56c
    jmp .label13 ; ↑
    nop

.label29: ; 20c4
    call far PauseGame ; 20c4 2:17da
    push word SEG GOTOLEVELMSGPROC ; 20c7 6:0 GOTOLEVELMSGPROC
    push word GOTOLEVELMSGPROC
    push word [OurHInstance]
    call far KERNEL.MakeProcInstance ; 20d3
    mov si,ax
    mov [bp-0x6],dx
    mov bx,[GameStatePtr]
    mov di,[bx+LevelNumber]
    push word [OurHInstance]
    push ds
    push word s_DLG_GOTO
    push word [hwndMain]
    mov ax,dx
    push ax
    push si
    mov [bp-0xc],si
    mov [bp-0xa],ax
    call far USER.DialogBox ; 20fb
    push word [bp-0xa]
    push word [bp-0xc]
    call far KERNEL.FreeProcInstance ; 2106
    call far UnpauseGame ; 210b 2:1834
    mov bx,[GameStatePtr]
    mov ax,[bx+LevelNumber]
    mov [bp-0x4],ax
    mov [bx+LevelNumber],di
    cmp di,[bp-0x4]
    if z
        jmp .label42 ; ↓
    endif ; 2127
    push byte +0x0
    push word [bp-0x4]
    jmp .label12 ; ↑
    nop

.label31: ; 2130
    mov word [Var2a],0x1
    push word [OurHInstance]
    push word [bp+0x6]
    push word 0x101
    push ds
    push word s_How_To_Play
    jmp .label5 ; ↑
    nop

.label32: ; 2148
    mov word [Var2a],0x1
    push word [OurHInstance]
    push word [bp+0x6]
    push word 0x101
    push ds
    push word s_Commands
    jmp .label5 ; ↑
    nop

.label33: ; 2160
    mov ax,[ColorMode]
    mov [bp-0x4],ax
    push byte +0x0
    push byte +0x0
    push word 0x7f02
    call far USER.LoadCursor ; 216d
    mov si,ax
    push word [hwndMain]
    call far USER.SetCapture ; 2178
    push si
    call far USER.SetCursor ; 217e
    mov di,ax
    cmp word [ColorMode],byte +0x1
    if ne
        mov word [ColorMode],0x1
    else ; 2194
        push byte +0x0
        call far InitGraphics ; 2196 5:0
        add sp,byte +0x2
    endif ; 219e
    push byte +0x1
    lea ax,[bp-0x6]
    push ax
    push word [OurHInstance]
    call far LoadTiles ; 21a8 5:112
    add sp,byte +0x6
    or ax,ax
    jz .label36 ; ↓
    push word [TileDC]
    push word [bp-0x6]
    call far GDI.SelectObject ; 21bb
    push ax
    call far GDI.DeleteObject ; 21c1
    mov ax,[bp-0x6]
    mov [TileBitmapObj],ax
    push word [hwndBoard]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far USER.InvalidateRect ; 21d6
    push word [hwndInventory]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far USER.InvalidateRect ; 21e5
    cmp word [hwndHint],byte +0x0
    jz .label37 ; ↓
    push word [hwndHint]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far USER.InvalidateRect ; 21fb
    jmp short .label37 ; ↓
.label36: ; 2202
    mov ax,[bp-0x4]
    mov [ColorMode],ax
.label37: ; 2208
    cmp word [ColorMode],byte +0x1
    if nz
        mov ax,0x1
    else ; 2214
        xor ax,ax
    endif ; 2216
    push ax
    push byte ID_COLOR
    call far StoreIniInt ; 2219 2:19ca
    add sp,byte +0x4
    push word [hMenu]
    push byte ID_COLOR
    cmp word [ColorMode],byte +0x1
    if nz
        mov ax,0x8 ; MF_CHECKED
    else ; 2234
        xor ax,ax
    endif ; 2236
    push ax
    call far USER.CheckMenuItem ; 2237
    push word [hwndMain]
    call far USER.DrawMenuBar ; 2240
    push di
    call far USER.SetCursor ; 2246
    call far USER.ReleaseCapture ; 224b

.label42: ; 2250
    xor ax,ax
    cwd
.label43: ; 2253
    pop si
    pop di
endfunc

; 225c

func MAINWNDPROC
    %assign %$argsize 0xa
    %arg lParam:dword ; +6
    %arg wParam:word ; +a
    %arg uMsg:word ; +c
    %arg hwnd:word ; +e
    sub sp,byte +0x26
    push di
    push si
    ; switch on uMsg
    ; this is a basically a jump table encoded as a long chain of ifs
    mov ax,[uMsg]
    cmp ax,0x1c ; WM_SHOWWINDOW
    if z
        jmp .label27 ; ↓
    endif ; 2276
    ja .label5 ; ↓
    cmp ax,0x1a ; WM_WININICHANGE
    if z
        jmp .label23 ; ↓
    endif ; 2280
    if a
        jmp .label68 ; ↓
    endif ; 2285
    dec al ; WM_CREATE
    jz .label10 ; ↓
    dec al ; WM_DESTROY
    if z
        jmp .label18 ; ↓
    endif ; 2290
    sub al,0xf-2 ; WM_PAINT
    if z
        jmp .label22 ; ↓
    endif ; 2297
    jmp .label68 ; ↓
.label5: ; 229a
    sub ax,0x100 ; WM_KEYDOWN
    if z
        jmp .label33 ; ↓
    endif ; 22a2
    sub ax,0x111-0x100 ; WM_COMMAND
    if z
        jmp .label62 ; ↓
    endif
    dec ax ; WM_SYSCOMMAND
    if e
        jmp .label63 ; ↓
    endif
    sub ax,0x2a7 ; MM_MCINOTIFY
    if z
        jmp .label66 ; ↓
    endif
    jmp .label68 ; ↓
    nop
.label10: ; 22bc
    ; WM_CREATE
    push word [OurHInstance]
    push ds
    push word s_ChipsMenu2
    call far USER.LoadAccelerators ; 22c4
    mov [hAccel],ax
    or ax,ax
    if z
        jmp .label15 ; ↓
    endif ; 22d3
    mov si,[hwnd]
    push byte +0x0
    push word TileBitmapObj
    push word [OurHInstance]
    call far LoadTiles ; 22df 5:112
    add sp,byte +0x6
    or ax,ax
    if z
        jmp .label16 ; ↓
    endif ; 22ee
    mov si,[hwnd]
    push si
    call far USER.GetDC ; 22f2
    mov di,ax
    or di,di
    if z
        jmp .label16 ; ↓
    endif ; 2300
    ; create a memory DC that's compatible with our main window
    push di
    call far GDI.CreateCompatibleDC ; 2301
    mov [TileDC],ax
    push si
    push di
    call far USER.ReleaseDC ; 230b
    cmp word [TileDC],byte +0x0
    if z
        jmp .label16 ; ↓
    endif ; 231a
    ; select our tile bitmap into it
    push word [TileDC]
    push word [TileBitmapObj]
    call far GDI.SelectObject ; 2322
    mov [SavedObj],ax
    push byte +0x1 ; free game lists
    call far ClearGameState ; 232c 4:320
    add sp,byte +0x2
    push byte ID_BGM
    call far GetIniInt ; 2336 2:198e
    add sp,byte +0x2
    mov [MusicEnabled],ax
    push byte ID_SOUND
    call far GetIniInt ; 2343 2:198e
    add sp,byte +0x2
    mov [SoundEnabled],ax
    call far InitSound ; 234e 8:0
    call far InitAudioFiles ; 2353 8:4a0
    push word [hMenu]
    push byte ID_BGM
    cmp word [MusicEnabled],byte +0x1
    cmc
    sbb ax,ax
    and ax,0x8 ; MF_CHECKED
    push ax
    call far USER.CheckMenuItem ; 236a
    push word [hMenu]
    push byte ID_SOUND
    cmp word [SoundEnabled],byte +0x1
    cmc
    sbb ax,ax
    and ax,0x8 ; MF_CHECKED
    push ax
    call far USER.CheckMenuItem ; 2381
    push word [hMenu]
    push byte ID_BGM
    cmp word [MusicMenuItemEnabled],byte +0x1
    sbb ax,ax
    neg ax
    push ax
    call far USER.EnableMenuItem ; 2396
    push word [hMenu]
    push byte ID_SOUND
    cmp word [SoundMenuItemEnabled],byte +0x1
    sbb ax,ax
    neg ax
    push ax
    call far USER.EnableMenuItem ; 23ab
    push si
    call far USER.DrawMenuBar ; 23b1
    jmp .label67 ; ↓
    nop
.label15: ; 23ba
    mov si,[hwnd]
.label16: ; 23bd
    push si
    push ds
    push word NotEnoughMemoryErrorMsg
    push ds
    push word MessageBoxCaption
    push word 0x1030
    call far USER.MessageBox ; 23c9
    mov ax,0xffff
.label17: ; 23d1
    cwd
    jmp .label69 ; ↓
    nop
.label18: ; 23d6
    ; WM_DESTROY
    push byte +0x1
    call far StopTimer ; 23d8 2:176e
    add sp,byte +0x2
    call far StopMIDI ; 23e0 8:2d4
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    push word ID_CurrentLevel
    call far StoreIniInt ; 23f0 2:19ca
    add sp,byte +0x4
    call far FreeGameLists ; 23f8 4:240
    cmp word [Var2a],byte +0x0
    if nz
        push word [OurHInstance]
        push word [hwnd]
        push byte +0x2
        push byte +0x0
        push byte +0x0
        call far WEP4UTIL.WEPHELP ; 2411
    endif ; 2416
    push word [TileDC]
    push word [SavedObj]
    call far GDI.SelectObject ; 241e
    push word [TileBitmapObj]
    call far GDI.DeleteObject ; 2427
    call far FreeDigits ; 242c 9:bc
    push word [TileDC]
    call far GDI.DeleteDC ; 2435
    call far FreeTiles ; 243a 5:17c
    call far FreeAudioFiles ; 243f 8:5b8
    call far TeardownSound ; 2444 8:e6
    cmp word [IsWin31],byte +0x0
    if nz
        push byte +0x17     ; uiAction = SPI_SETKEYBOARDDELAY
        push word [KeyboardDelay]
        push byte +0x0
        push byte +0x0
        push byte +0x0
        call far USER.SystemParametersInfo ; 245c
    endif ; 2461
    cmp word [GameStatePtrCopy],byte +0x0
    if nz
        push word [GameStatePtrCopy]
        call far KERNEL.LocalFree ; 246c
    endif ; 2471
    push byte +0x0
    call far USER.PostQuitMessage ; 2473
    jmp .label67 ; ↓
    nop
.label22: ; 247c
    mov si,[hwnd]
    push si
    lea ax,[bp-0x26]
    push ss
    push ax
    call far USER.BeginPaint ; 2485
    lea ax,[bp-0x26]
    push ax
    push si
    call far PaintBackground ; 248f 2:dc6
    add sp,byte +0x4
    push si
    lea ax,[bp-0x26]
    push ss
    push ax
    call far USER.EndPaint ; 249d
    jmp .label67 ; ↓
    nop
.label23: ; 24a6
    cmp word [IsWin31],byte +0x0
    jnz .label24 ; ↓
    jmp .label67 ; ↓
.label24: ; 24b0
    push ds
    push word s_KeyboardDelay
    push word [lParam+FarPtr.Seg]
    push word [lParam+FarPtr.Off]
    call far USER.lstrcmpi ; 24ba
    or ax,ax
    jz .label25 ; ↓
    mov ax,[lParam+FarPtr.Seg]
    or ax,[lParam+FarPtr.Off]
    jz .label25 ; ↓
    jmp .label67 ; ↓
.label25: ; 24ce
    push byte +0x16     ; uiAction = SPI_GETKEYBOARDDELAY
    push byte +0x0      ; uiParam
    push ds
    push word KeyboardDelay ; pvParam
.label26: ; 24d6
    push byte +0x0      ; fWinIni
    call far USER.SystemParametersInfo ; 24d8
    jmp .label67 ; ↓
.label27: ; 24e0
    cmp word [Var2c],byte +0x0
    jz .label29 ; ↓
    push word [hwnd]
    call far USER.IsIconic ; 24ea
    or ax,ax
    jnz .label29 ; ↓
    cmp [wParam],ax
    if e
        call far PauseMusic ; 24f8 2:189c
        call far PauseGame ; 24fd 2:17da
    else ; 2504
        call far UnpauseMusic ; 2504 2:18b6
        call far UnpauseGame ; 2509 2:1834
    endif
.label29: ; 250e
    cmp word [IsWin31],byte +0x0
    if z
        jmp .label67 ; ↓
    endif ; 2518
    cmp word [wParam],byte +0x0
    jnz .label32 ; ↓
    push byte +0x17
    push word [KeyboardDelay]
.label31: ; 2524
    push byte +0x0
    push byte +0x0
    jmp short .label26 ; ↑
.label32: ; 252a
    push byte +0x16     ; uiAction = SPI_GETKEYBOARDDELAY
    push byte +0x0      ; uiParam
    push ds
    push word KeyboardDelay ; pvParam
    push byte +0x0      ; fWinIni
    call far USER.SystemParametersInfo ; 2534
    push byte +0x17
    push byte +0x0
    jmp short .label31 ; ↑
    nop
.label33: ; 2540
    ; WM_KEYDOWN
    mov bx,[GameStatePtr]
    cmp word [bx+IsLevelPlacardVisible],byte +0x0
    if nz
        mov word [bx+IsLevelPlacardVisible],0x0
        push word [hwndBoard]
        push byte +0x0
        push byte +0x0
        push byte +0x0
        call far USER.InvalidateRect ; 255b
        push word [hwndBoard]
        call far USER.UpdateWindow ; 2564
        call far UnpauseTimer ; 2569 2:17ba
    endif ; 256e
    ; switch on wparam
    ; which tells us the pressed key
    mov ax,[wParam]
    cmp ax,0x74 ; 0x74 = VK_F5
    if e
        jmp .label54 ; ↓
    endif ; 2579
    if a
        jmp .label67 ; ↓
    endif ; 257e
    cmp al,0x28 ; 0x28 = VK_DOWN
    jz .label47 ; ↓
    ja .label37 ; ↓
    sub al,0x1b ; 0x1B = VK_ESC
    jz .label42 ; ↓
    sub al,0xa  ; 0x25 = VK_LEFT
    jz .label43 ; ↓
    dec al      ; 0x26 = VK_UP
    jz .label45 ; ↓
    dec al      ; 0x27 = VK_RIGHT
    jz .label46 ; ↓
    jmp .label67 ; ↓
    nop
.label37: ; 2598
    sub al,'D'  ; 0x44 = VK_D
    if z
        jmp .label50 ; ↓
    endif ; 259f
    sub al,0x7  ; 0x4B = VK_K
    if z
        jmp .label52 ; ↓
    endif ; 25a6
    sub al,0x9  ; 0x54 = VK_T
    if z
        jmp .label54 ; ↓
    endif ; 25ad
    sub al,0x10 ; 0x64 = VK_NUMPAD4
    jz .label50 ; ↓
    sub al,0x7  ; 0x6B = VK_ADD
    if z
        jmp .label52 ; ↓
    endif ; 25b8
    jmp .label67 ; ↓
    nop

.label42: ; 25bc
    push word [hwnd]
    push word 0x112
    push word 0xf020
    push byte +0x0
    push byte +0x0
    call far USER.PostMessage ; 25c9
    jmp .label67 ; ↓
    nop

.label43: ; 25d2
    mov word [bp-0x4],0xffff
.label44: ; 25d7
    mov word [bp-0x6],0x0
    jmp short .label48 ; ↓
.label45: ; 25de
    mov word [bp-0x4],0x0
    mov word [bp-0x6],0xffff
    jmp short .label48 ; ↓
.label46: ; 25ea
    mov word [bp-0x4],0x1
    jmp short .label44 ; ↑
    nop
.label47: ; 25f2
    mov word [bp-0x4],0x0
    mov word [bp-0x6],0x1
.label48: ; 25fc
    push word [hwndBoard]
    call far USER.GetDC ; 2600
    mov si,ax
    or si,si
    if z
        jmp .label67 ; ↓
    endif ; 260e
    push byte +0x1
    push byte +0x1
    push word [bp-0x6]
    push word [bp-0x4]
    push si
    call far MoveChip ; 2619 7:1184
    add sp,byte +0xa
    push word [hwndBoard]
    push si
    call far USER.ReleaseDC ; 2626
    jmp .label67 ; ↓

.label50: ; 262e
    push byte VK_CONTROL
    call far USER.GetKeyState ; 2630
    or ax,ax
    if nl
        jmp .label67 ; ↓
    endif ; 263c
    or byte [CheatKeys],0x2
    jmp short .label56 ; ↓
    nop
.label52: ; 2644
    push byte VK_CONTROL
    call far USER.GetKeyState ; 2646
    or ax,ax
    if nl
        jmp .label67 ; ↓
    endif ; 2652
    or byte [CheatKeys],0x4
    jmp short .label56 ; ↓
    nop
.label54: ; 265a
    push byte VK_CONTROL
    call far USER.GetKeyState ; 265c
    or ax,ax
    if nl
        jmp .label67 ; ↓
    endif ; 2668
    or byte [CheatKeys],0x1
.label56: ; 266d
    cmp word [CheatKeys],byte +0x1
    if e
        mov ax,0x1
    else ; 267a
        xor ax,ax
    endif ; 267c
    or ax,0x6
    if e
        jmp .label67 ; ↓
    endif ; 2684
    cmp word [CheatVisible],byte +0x0
    if nz
        jmp .label67 ; ↓
    endif ; 268e
    push word [hMenu]
    push byte +0x0
    call far USER.GetSubMenu ; 2694
    mov si,ax
    or si,si
    if z
        jmp .label67 ; ↓
    endif ; 26a2
    push si
    push byte +0x0
    push byte ID_CHEAT
    push ds
    push word CheatMenuText
    call far USER.AppendMenu ; 26ab
    mov word [CheatVisible],0x1
    push word [hwnd]
    push word 0x111
    push byte ID_CHEAT
    push byte +0x0
    push byte +0x0
    call far USER.SendMessage ; 26c2
    jmp short .label67 ; ↓
    nop

.label62: ; 26ca
    push word [lParam+_HiWord]
    push word [lParam+_LoWord]
    push word [wParam]
    push word [uMsg]
    push word [hwnd]
    call far MenuItemCallback ; 26d9 2:1e28
    add sp,byte +0xa
    jmp short .label69 ; ↓
    nop
.label63: ; 26e4
    mov ax,[wParam]
    and al,0xf0
    sub ax,0xf020
    jz .label64 ; ↓
    sub ax,0x10
    jz .label65 ; ↓
    sub ax,0xf0
    jz .label65 ; ↓
    jmp short .label68 ; ↓
.label64: ; 26fa
    call far PauseMusic ; 26fa 2:189c
    call far PauseGame ; 26ff 2:17da
    jmp short .label68 ; ↓
.label65: ; 2706
    push word [hwnd]
    call far USER.IsIconic ; 2709
    or ax,ax
    jz .label68 ; ↓
    call far UnpauseMusic ; 2712 2:18b6
    call far UnpauseGame ; 2717 2:1834
    jmp short .label68 ; ↓

.label66: ; 271e
    mov ax,[wParam]
    dec ax
    jnz .label67 ; ↓
    call far FUN_8_022a ; 2724 8:22a

.label67: ; 2729
    xor ax,ax
    jmp .label17 ; ↑
.label68: ; 272e
    push word [hwnd]
    push word [uMsg]
    push word [wParam]
    push word [lParam+_HiWord]
    push word [lParam+_LoWord]
    call far USER.DefWindowProc ; 273d
.label69: ; 2742
    pop si
    pop di
endfunc

; 274e

func BOARDWNDPROC
    %assign %$argsize 0xa
    %arg lParam:dword ; +6
    %arg wParam:word ; +a
    %arg uMsg:word ; +c
    %arg hwnd:word ; +e
    sub sp,byte +0x22
    push si
    mov ax,[uMsg]
    sub ax,0xf
    jz .label0 ; ↓
    sub ax,0x104
    jz .label1 ; WM_TIMER
    sub ax,0xee
    jz .label6 ; ↓
    push word [hwnd]
    push word [uMsg]
    push word [wParam]
    push word [lParam+_HiWord]
    push word [lParam+_LoWord]
    call far USER.DefWindowProc ; 277d
    jmp .label9 ; ↓
    nop
.label0: ; 2786
    mov si,[hwnd]
    push si
    lea ax,[bp-0x22]
    push ss
    push ax
    call far USER.BeginPaint ; 278f
    lea ax,[bp-0x22]
    push ax
    push si
    call far PaintBoardWindow ; 2799 2:10ce
    add sp,byte +0x4
    push si
    lea ax,[bp-0x22]
    push ss
    push ax
    call far USER.EndPaint ; 27a7
    jmp .label8 ; ↓
    nop
.label1: ; 27b0
    cmp word [Var22],byte +0x0
    if nz
        jmp .label8 ; ↓
    endif ; 27ba
    mov ax,[wParam]
    dec ax
    if nz
        jmp .label8 ; ↓
    endif ; 27c3
    mov bx,[GameStatePtr]
    cmp word [bx+EndingTick],byte +0x0
    if nz
        push byte +0x0
        call far EndGame ; 27d0 7:a74
    .label4: ; 27d5
        add sp,byte +0x2
        jmp short .label8 ; ↓
    endif ; 27da
    inc word [CurrentTick]
    push word [CurrentTick]
    call far DoTick ; 27e2 7:0
    jmp short .label4 ; ↑
    nop
.label6: ; 27ea
    mov bx,[GameStatePtr]
    cmp word [bx+IsLevelPlacardVisible],byte +0x0
    if nz
        mov word [bx+IsLevelPlacardVisible],0x0
        push word [hwndBoard]
        push byte +0x0
        push byte +0x0
        push byte +0x0
        call far USER.InvalidateRect ; 2805
        push word [hwndBoard]
        call far USER.UpdateWindow ; 280e
        call far UnpauseTimer ; 2813 2:17ba
    endif ; 2818
    mov bx,[GameStatePtr]
    mov word [bx+HaveMouseTarget],0x1
    mov ax,[lParam+_LoWord]
    shr ax,byte TileShift
    mov bx,[GameStatePtr]
    add ax,[bx+ViewportX]
    add ax,[bx+UnusedOffsetX]
    mov [bx+MouseTargetX],ax
    mov ax,[lParam+_HiWord]
    shr ax,byte TileShift
    mov bx,[GameStatePtr]
    add ax,[bx+ViewportY]
    add ax,[bx+UnusedOffsetY]
    mov [bx+MouseTargetY],ax
    mov bx,[GameStatePtr]
    mov word [bx+IsBuffered],0x0
.label8: ; 2858
    xor ax,ax
    cwd
.label9: ; 285b
    pop si
endfunc

; 2866

func INFOWNDPROC
    %assign %$argsize 0xa
    %arg lParam:dword ; +6
    %arg wParam:word ; +a
    %arg uMsg:word ; +c
    %arg hwnd:word ; +e
    sub sp,byte +0x26
    push di
    push si
    mov ax,[uMsg]
    sub ax,WM_PAINT
    if ne
        push word [hwnd]
        push word [uMsg]
        push word [wParam]
        push word [lParam+_HiWord]
        push word [lParam+_LoWord]
        call far USER.DefWindowProc ; 288c
        jmp .label6 ; ↓
    endif ; 2894
    push word [hwnd]
    lea ax,[bp-0x24]
    push ss
    push ax
    call far USER.BeginPaint ; 289c
    push word [OurHInstance]
    push ds
    push word s_infownd
    call far USER.LoadBitmap ; 28a9
    mov si,ax
    or si,si
    jz .label1 ; ↓
    push word [TileDC]
    push si
    call far GDI.SelectObject ; 28b9
    mov di,ax
    push word [bp-0x24]
    push byte +0x0
    push byte +0x0
    push word 0x9a
    push word 0x12c
    push word [TileDC]
    push byte +0x0
    push byte +0x0
    push word 0xcc
    push byte +0x20
    call far GDI.BitBlt ; 28da
    push word [TileDC]
    push di
    call far GDI.SelectObject ; 28e4
    push si
    call far GDI.DeleteObject ; 28ea
    jmp short .label5 ; ↓
    nop
.label1: ; 28f2
    push byte +0x1
    call far GDI.GetStockObject ; 28f4
    mov si,ax
    or si,si
    jz .label2 ; ↓
    push word [bp-0x24]
    push si
    call far GDI.SelectObject ; 2903
    mov [bp-0x4],ax
.label2: ; 290b
    push word [bp-0x24]
    push word [bp-0x20]
    push word [bp-0x1e]
    mov ax,[bp-0x1c]
    sub ax,[bp-0x20]
    push ax
    mov ax,[bp-0x1a]
    sub ax,[bp-0x1e]
    push ax
    mov [bp-0x26],si
    or si,si
    if nz
        mov ax,0x21
        mov dx,0xf0
    else ; 2932
        mov ax,0x42
        cwd
    endif ; 2936
    push dx
    push ax
    call far GDI.PatBlt ; 2938
    cmp word [bp-0x26],byte +0x0
    jz .label5 ; ↓
    push word [bp-0x24]
    push word [bp-0x4]
    call far GDI.SelectObject ; 2949
.label5: ; 294e
    push word [hwnd]
    lea ax,[bp-0x24]
    push ss
    push ax
    call far USER.EndPaint ; 2956
    xor ax,ax
    cwd
.label6: ; 295e
    pop si
    pop di
endfunc

; 296a

func COUNTERWNDPROC
    %assign %$argsize 0xa
    %arg lParam:dword ; +6
    %arg wParam:word ; +a
    %arg uMsg:word ; +c
    %arg hwnd:word ; +e
    sub sp,byte +0x36
    push di
    push si
    mov ax,[uMsg]
    sub ax,0xf
    jz .label0 ; ↓
    push word [hwnd]
    push word [uMsg]
    push word [wParam]
    push word [lParam+_HiWord]
    push word [lParam+_LoWord]
    call far USER.DefWindowProc ; 2990
    jmp .label5 ; ↓
.label0: ; 2998
    mov di,[hwnd]
    push di
    lea ax,[bp-0x36]
    push ss
    push ax
    call far USER.BeginPaint ; 29a1
    push di
    push byte +0x0
    call far USER.GetWindowWord ; 29a9
    mov si,ax
    push di
    push byte +0x2
    call far USER.GetWindowWord ; 29b3
    mov cx,ax
    and ax,0x1
    mov [bp-0xa],ax
    test cl,0x2
    jz .label1 ; ↓
    mov si,0xb
    mov [bp-0x8],si
    mov [bp-0xe],si
    jmp short .label4 ; ↓
.label1: ; 29d0
    mov ax,si
    mov cx,0xa
    sub dx,dx
    div cx
    mov [bp-0xe],dx
    sub si,dx
    mov ax,si
    mov dx,0x64
    mov bx,dx
    sub dx,dx
    div bx
    mov ax,dx
    sub dx,dx
    div cx
    mov [bp-0x8],ax
    mov ax,si
    sub dx,dx
    div bx
    mov [bp-0xc],ax
    or ax,ax
    jz .label2 ; ↓
    mov si,ax
    jmp short .label3 ; ↓
    nop
.label2: ; 2a04
    mov si,cx
.label3: ; 2a06
    cmp word [bp-0x8],byte +0x0
    jnz .label4 ; ↓
    cmp si,cx
    jnz .label4 ; ↓
    mov [bp-0x8],si
.label4: ; 2a13
    push di
    lea ax,[bp-0x16]
    push ss
    push ax
    call far USER.GetClientRect ; 2a19
    mov ax,[bp-0x10]
    sub ax,0x17
    cwd
    sub ax,dx
    sar ax,1
    mov [bp-0x4],ax
    push word [bp-0xa]
    push si
    push ax
    mov ax,[bp-0x12]
    sub ax,0x33
    cwd
    sub ax,dx
    sar ax,1
    mov [bp-0x6],ax
    push ax
    push word [bp-0x36]
    call far DrawDigit ; 2a43 9:ea
    add sp,byte +0xa
    push word [bp-0xa]
    push word [bp-0x8]
    push word [bp-0x4]
    mov ax,[bp-0x6]
    add ax,0x11
    push ax
    push word [bp-0x36]
    call far DrawDigit ; 2a5e 9:ea
    add sp,byte +0xa
    push word [bp-0xa]
    push word [bp-0xe]
    push word [bp-0x4]
    mov ax,[bp-0x6]
    add ax,0x22
    push ax
    push word [bp-0x36]
    call far DrawDigit ; 2a79 9:ea
    add sp,byte +0xa
    push di
    lea ax,[bp-0x36]
    push ss
    push ax
    call far USER.EndPaint ; 2a87
    xor ax,ax
    cwd
.label5: ; 2a8f
    pop si
    pop di
endfunc

; 2a9a

func INVENTORYWNDPROC
    %assign %$argsize 0xa
    %arg lParam:dword ; +6
    %arg wParam:word ; +a
    %arg uMsg:word ; +c
    %arg hwnd:word ; +e
    sub sp,byte +0x22
    push si
    mov ax,[uMsg]
    sub ax,0xf
    jz .label0 ; ↓
    push word [hwnd]
    push word [uMsg]
    push word [wParam]
    push word [lParam+_HiWord]
    push word [lParam+_LoWord]
    call far USER.DefWindowProc ; 2abf
    jmp .label1 ; ↓
    nop
.label0: ; 2ac8
    mov si,[hwnd]
    push si
    lea ax,[bp-0x22]
    push ss
    push ax
    call far USER.BeginPaint ; 2ad1
    cmp word [RedKeyCount],byte +0x1
    cmc
    sbb al,al
    and al,0x65
    push ax
    push byte +0x0
    push byte +0x0
    push word [bp-0x22]
    call far DrawInventoryTile ; 2ae8 2:232
    add sp,byte +0x8
    cmp word [BlueKeyCount],byte +0x1
    cmc
    sbb al,al
    and al,0x64
    push ax
    push byte +0x0
    push byte TileWidth * 1
    push word [bp-0x22]
    call far DrawInventoryTile ; 2b02 2:232
    add sp,byte +0x8
    cmp word [YellowKeyCount],byte +0x1
    cmc
    sbb al,al
    and al,0x67
    push ax
    push byte +0x0
    push byte TileWidth * 2
    push word [bp-0x22]
    call far DrawInventoryTile ; 2b1c 2:232
    add sp,byte +0x8
    cmp word [GreenKeyCount],byte +0x1
    cmc
    sbb al,al
    and al,0x66
    push ax
    push byte +0x0
    push byte TileWidth * 3
    push word [bp-0x22]
    call far DrawInventoryTile ; 2b36 2:232
    add sp,byte +0x8
    cmp word [IceSkateCount],byte +0x1
    cmc
    sbb al,al
    and al,0x6a
    push ax
    push byte TileHeight
    push byte +0x0
    push word [bp-0x22]
    call far DrawInventoryTile ; 2b50 2:232
    add sp,byte +0x8
    cmp word [SuctionBootCount],byte +0x1
    cmc
    sbb al,al
    and al,0x6b
    push ax
    push byte TileHeight
    push byte TileWidth * 1
    push word [bp-0x22]
    call far DrawInventoryTile ; 2b6a 2:232
    add sp,byte +0x8
    cmp word [FireBootCount],byte +0x1
    cmc
    sbb al,al
    and al,0x69
    push ax
    push byte TileHeight
    push byte TileWidth * 2
    push word [bp-0x22]
    call far DrawInventoryTile ; 2b84 2:232
    add sp,byte +0x8
    cmp word [FlipperCount],byte +0x1
    cmc
    sbb al,al
    and al,0x68
    push ax
    push byte TileHeight
    push byte TileWidth * 3
    push word [bp-0x22]
    call far DrawInventoryTile ; 2b9e 2:232
    add sp,byte +0x8
    push si
    lea ax,[bp-0x22]
    push ss
    push ax
    call far USER.EndPaint ; 2bac
    xor ax,ax
    cwd
.label1: ; 2bb4
    pop si
endfunc

; 2bbe

MaxHintFontSize equ 12
MinHintFontSize equ 6

func HINTWNDPROC
    %assign %$argsize 0xa
    %arg lParam:dword ; +6
    %arg wParam:word ; +a
    %arg uMsg:word ; +c
    %arg hwnd:word ; +e
    %local hFont:word ; -4
    %local fontSize:word ; -6
    %local local_8:word ; text length
    %local local_a:word
    %local local_c:word
    %local local_10:dword
    %local local_14:dword
    %local local_16:word
    %local hSavedObj:word ; -18
    %local rect.bottom:word
    %local rect.right:word
    %local rect.top:word
    %local rect.left:word
    %define rect (bp-0x20) ; RECT
    %local computedTextRect.bottom:word
    %define computedTextRect (bp-0x28)
    ; The next 0x20 bytes are a PAINSTRUCT
    ; https://docs.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-paintstruct
    ; we don't really care what's in it except that
    ; the first member is a HDC
    %define hdcPaint (bp-0x48) ; HDC
    sub sp,0xc8
    push di
    push si
    mov ax,[uMsg]
    sub ax,WM_PAINT
    jz .paint ; ↓
.default:
    push word [hwnd]
    push word [uMsg]
    push word [wParam]
    push word [lParam+_HiWord]
    push word [lParam+_LoWord]
    call far USER.DefWindowProc ; 2be5
    jmp .end ; ↓
    nop
.paint: ; 2bee
    push word [hwnd]    ; hWnd
    lea ax,[hdcPaint]
    push ss             ; lpPaint
    push ax
    call far USER.BeginPaint ; 2bf6
    push word [hwnd]
    lea ax,[rect]
    push ss
    push ax
    call far USER.GetClientRect ; 2c03
    lea ax,[rect]
    push ss
    push ax
    push byte -0x3
    push byte -0x3
    call far USER.InflateRect ; 2c11
    push byte +0x0
    push byte +0x3
    push word [rect.bottom]
    push word [rect.right]
    push word [rect.top]
    push word [rect.left]
    push word [hdcPaint]
    call far Draw3DBorder ; 2c29 2:f06
    add sp,byte +0xe
    push word [hdcPaint]
    push word [rect.left]
    push word [rect.top]
    mov ax,[rect.right]
    sub ax,[rect.left]
    push ax
    mov ax,[rect.bottom]
    sub ax,[rect.top]
    push ax
    push byte +0x0
    push byte +0x42
    call far GDI.PatBlt ; 2c4c
    lea ax,[rect]
    push ss
    push ax
    push byte -0x1
    push byte -0x1
    call far USER.InflateRect ; 2c5a
    ; set text color to white or yellow depending on ColorMode
    push word [hdcPaint]
    cmp word [ColorMode],byte +0x1
    jnz .label1 ; ↓
    mov ax,0xffff ; ffffff = white
    jmp short .label2 ; ↓
.label1: ; 2c6e
    mov ax,0xff00 ; ffff00 = yellow
.label2: ; 2c71
    mov dx,0xff
    push dx
    push ax
    call far GDI.SetTextColor ; 2c76
    mov [bp-0x10],ax
    mov [bp-0xe],dx
    ; set background color to black
    push word [hdcPaint]
    push byte +0x0
    push byte +0x0
    call far GDI.SetBkColor ; 2c88
    mov [bp-0x14],ax
    mov [bp-0x12],dx
    ; prepend "Hint: " to the hint and place on stack
    mov ax,[GameStatePtr]
    add ax,LevelHint
    push ds
    push ax
    push ds
    push word s_658 ; "Hint: %s"
    lea ax,[bp-0xc8]
    push ss
    push ax
    call far USER._wsprintf ; 2ca5
    add sp,byte +0xc
    mov [bp-0x8],ax
    mov word [bp-0x16],0x0
    mov word [fontSize],MaxHintFontSize
.fontSizeLoop: ; 2cba
    ; computes font height by multiplying the desired point size by the screen's DPI,
    ; see comment in FUN_2_10ce.
    ;
    ; lfHeight = MulDiv(-fontSize, GetDeviceCaps(hDC, LOGPIXELSY), 72)
    mov ax,[fontSize]
    neg ax
    push ax
    push word [hdcPaint]
    push byte +0x5a ; LOGPIXELSY
    call far GDI.GetDeviceCaps ; 2cc5
    push ax
    push byte +0x48
    call far GDI.MulDiv ; 2ccd
    mov [LOGFONT.lfHeight],ax
    mov word [LOGFONT.lfWeight],700
    mov byte [LOGFONT.lfItalic],1
    push ds
    push word LOGFONT.lfFaceName
    cmp word [IsWin31],byte +0x0
    if nz
        mov ax,s_Arial3
    else ; 2cf0
        mov ax,s_Helv3
    endif ; 2cf3
    mov si,ax
    mov [local_a],ds
    push ds
    push ax
    call far KERNEL.lstrcpy ; 2cfa
    ; try and load the font
    ; if it fails no biggie, just use
    ; whatever font was already selected
    push ds
    push word LOGFONT
    call far GDI.CreateFontIndirect ; 2d03
    mov [hFont],ax
    or ax,ax
    jz .createFontFailed ; ↓
    push word [hdcPaint]
    push ax
    call far GDI.SelectObject ; 2d13
    mov [hSavedObj],ax
.createFontFailed: ; 2d1b
    ; copy rect
    lea di,[computedTextRect]
    lea si,[rect]
    mov ax,ss
    mov es,ax
    movsw
    movsw
    movsw
    movsw
    ; calculate how large the text would be if we drew it
    push word [hdcPaint]
    lea ax,[bp-0xc8]
    push ss
    push ax
    push word [bp-0x8]
    lea ax,[computedTextRect]
    push ss
    push ax
    push word 0xc11 ; DT_NOPREFIX | DT_CALCRECT | DT_WORDBREAK | DT_CENTER
    call far USER.DrawText ; 2d3d
    ; if the bottom of the text bounding box extends
    ; below the bottom of the hint box,
    ; decrease the font size and try again
    mov ax,[rect.bottom]
    cmp [computedTextRect.bottom],ax
    jng .drawTheText ; ↓
    cmp word [fontSize],byte MinHintFontSize
    jg .label8 ; ↓
.drawTheText: ; 2d50
    ; font size is ok, text fits;
    ; acually draw the text now
    push word [hdcPaint]
    lea ax,[bp-0xc8]
    push ss
    push ax
    push word [bp-0x8]
    lea ax,[rect]
    push ss
    push ax
    push word 0x811 ; DT_NOPREFIX | DT_WORDBREAK | DT_CENTER
    call far USER.DrawText ; 2d64
    mov word [bp-0x16],0x1
.label8: ; 2d6e
    ; free the font object and restore the old HGDIOBJ if necessary
    cmp word [hFont],byte +0x0
    jz .nextFontSize ; ↓
    push word [hdcPaint]
    push word [hSavedObj]
    call far GDI.SelectObject ; 2d7a
    push word [hFont]
    call far GDI.DeleteObject ; 2d82
.nextFontSize: ; 2d87
    dec word [fontSize]
    cmp word [bp-0x16],byte +0x0
    jnz .label10 ; ↓
    jmp .fontSizeLoop ; ↑
.label10: ; 2d93
    ; restore the old text color and background color
    push word [hdcPaint]
    push word [bp-0xe]
    push word [bp-0x10]
    call far GDI.SetTextColor ; 2d9c
    push word [hdcPaint]
    push word [bp-0x12]
    push word [bp-0x14]
    call far GDI.SetBkColor ; 2daa
    push word [hwnd]  ; hWnd
    lea ax,[hdcPaint] ; lpPaint
    push ss
    push ax
    call far USER.EndPaint ; 2db7
    xor ax,ax
    cwd
.end: ; 2dbf
    pop si
    pop di
endfunc

; 2dc7

GLOBAL _segment_2_size
_segment_2_size equ $ - $$

; vim: syntax=nasm

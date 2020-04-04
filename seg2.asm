SEGMENT CODE ; 2

; UI Code

%include "constants.asm"
%include "structs.asm"
%include "variables.asm"
%include "func.mac"

func ShowMessageBox
    %arg hWnd:word ; +6
    %arg message:dword ; +8
    %arg flags:word ; +c
    sub sp,byte +0x2
    push si
    call 0x6d:PauseTimer ; e 2:17a2
    ; if sound is enabled, play a message beep before
    ; popping the message box open
    cmp word [SoundEnabled],byte +0x0
    jz .showMessage ; ↓
    test byte [flags],0x30
    jz .checkInfo ; ↓
    mov si,0x30 ; MB_ICONWARNING
    jmp short .playBeep ; ↓
    nop
.checkInfo: ; 26
    test byte [flags],0x40
    jz .checkError ; ↓
    mov si,0x40 ; MB_ICONINFORMATION
    jmp short .playBeep ; ↓
    nop
.checkError: ; 32
    test byte [flags],0x10
    jz .checkQuestion ; ↓
    mov si,0x10 ; MB_ICONERROR
    jmp short .playBeep ; ↓
    nop
.checkQuestion: ; 3e
    mov al,[flags]
    and ax,0x20
    cmp ax,0x1
    cmc
    sbb si,si
    and si,byte +0x20 ; MB_ICONQUESTION
.playBeep: ; 4d
    push si
    call 0x0:0xffff ; 4e USER.MessageBeep
.showMessage: ; 53
    push word [hWnd]
    push word [message+2] ; segment
    push word [message]
    push ds
    push word MessageBoxCaption
    push word [flags]
    call 0x0:0xffff ; 63 USER.MessageBox
    mov si,ax
    call 0x1e2:UnpauseTimer ; 6a 2:17ba
    mov ax,si
    pop si
endfunc

; 7a

; BOOL IsCoordOnscreen(int x, int y)
;
; Reports whether the given coordinate lies within the viewport
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

DrawTile:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0xa
    cmp byte [bp+0xe],0x0
    jnz .label0 ; ↓
    jmp .label3 ; ↓
.label0: ; da
    cmp byte [bp+0xc],FirstTransparent
    jnc .label1 ; ↓
    jmp .label3 ; ↓
.label1: ; e3
    cmp byte [bp+0xc],LastTransparent
    jna .label2 ; ↓
    jmp .label3 ; ↓
.label2: ; ec
    push byte +0x20
    call 0x103:0x2a3e ; ee 3:2a3e GetTileImagePos
    add sp,byte +0x2
    mov [bp-0xa],ax
    mov [bp-0x8],dx
    mov al,[bp+0xe]
    push ax
    call 0x12f:0x2a3e ; 100 3:2a3e GetTileImagePos
    add sp,byte +0x2
    push word [0x1734]
    push word [bp-0xa]
    push word [bp-0x8]
    push byte TileWidth
    push byte TileHeight
    push word [0x1734]
    push ax
    push dx
    push word 0xcc
    push byte +0x20
    call 0x0:0x14f ; 121 GDI.BitBlt
    mov al,[bp+0xc]
    add al,0x60
    push ax
    call 0x15c:0x2a3e ; 12c 3:2a3e GetTileImagePos
    add sp,byte +0x2
    push word [0x1734]
    push word [bp-0xa]
    push word [bp-0x8]
    push byte TileWidth
    push byte TileHeight
    push word [0x1734]
    push ax
    push dx
    push word 0xee
    push word 0x86
    call 0x0:0x17c ; 14e GDI.BitBlt
    mov al,[bp+0xc]
    add al,0x30
    push ax
    call 0x1a1:0x2a3e ; 159 3:2a3e GetTileImagePos
    add sp,byte +0x2
    push word [0x1734]
    push word [bp-0xa]
    push word [bp-0x8]
    push byte TileWidth
    push byte TileHeight
    push word [0x1734]
    push ax
    push dx
    push word 0x88
    push word 0xc6
    call 0x0:0x1bf ; 17b GDI.BitBlt
    push word [bp+0x6]
    push word [bp+0x8]
    push word [bp+0xa]
    push byte TileWidth
    push byte TileHeight
    push word [0x1734]
    push word [bp-0xa]
    push word [bp-0x8]
    jmp short .label4 ; ↓
    nop
.label3: ; 19a
    mov al,[bp+0xc]
    push ax
    call 0xffff:0x2a3e ; 19e 3:2a3e GetTileImagePos
    add sp,byte +0x2
    push word [bp+0x6]
    push word [bp+0x8]
    push word [bp+0xa]
    push byte TileWidth
    push byte TileHeight
    push word [0x1734]
    push ax
    push dx
.label4: ; 1b9
    push word 0xcc
    push byte +0x20
    call 0x0:0xffff ; 1be GDI.BitBlt
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 1ca

UpdateTile:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    push si
    mov si,[bp+0xa]
    push si
    push word [bp+0x8]
    call 0x224:IsCoordOnscreen ; 1df 2:7a IsCoordOnscreen
    add sp,byte +0x4
    or ax,ax
    jz .label0 ; ↓
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
    call 0x251:DrawTile ; 221 2:c4 DrawTile
    add sp,byte +0xa
.label0: ; 229
    pop si
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 232

DrawInventoryTile:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    push byte +0x0
    mov al,[bp+0xc]
    push ax
    push word [bp+0xa]
    push word [bp+0x8]
    push word [bp+0x6]
    call 0x270:DrawTile ; 24e 2:c4 DrawTile
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 25a

; void InvertTile(hdc, x, y)
; Invert the tile at the given coordinates. (unused)
func InvertTile_Unused
    sub sp,byte +0x2
    ; if the coordinate isn't onscreen, do nothing
    push word [bp+0xa]
    push word [bp+0x8]
    call 0x2ca:IsCoordOnscreen ; 26d 2:7a IsCoordOnscreen
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
    call 0x0:0xffff ; 2a6 GDI.PatBlt
.end: ; 2ab
endfunc

; 2b2

; Invalidate a tile. Unused.
FUN_2_02b2:
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
    push word [bp+0x8]
    push word [bp+0x6]
    call 0xffff:IsCoordOnscreen ; 2c7 2:7a IsCoordOnscreen
    add sp,byte +0x4
    or ax,ax
    jz .label0 ; ↓
    push word [bp+0x8]
    push word [bp+0x6]
    call 0xffff:0x0 ; 2d9 4:0
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
    call 0x0:0xffff ; 2f7 USER.InvalidateRect
.label0: ; 2fc
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

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
    %local local_c:word ; -c
    %local local_e:word ; -e
    %local local_10:word ; -10
    %local rect.height:word ; -12
    %local rect.width:word ; -14
    %local rect.y:word ; -16
    %local rect.x:word ; -18
    %define rect rect.x
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
    mov [local_c],ax
    ; GetClientRectangle(hwndBoard, &rect)
    push word [hwndBoard]
    lea ax,[rect]
    push ss
    push ax
    call 0x0:0xffff ; 347 USER.GetClientRect
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
    jng .label1 ; ↓
    mov ax,cx
.label1: ; 369
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
    jng .label2 ; ↓
    mov cx,bx
.label2: ; 38d
    mov [local_e],cx
    ; ax = vw-0-1
    dec ax
    ; if ax > rect.width/32 then ax = dx
    cmp ax,dx
    jng .label3 ; ↓
    mov ax,dx
.label3: ; 397
    mov [local_6],ax
    ; ax = vh-0-1
    ; if ax > rect.height/32 then ax = rect.height/32
    mov ax,[bp-0x1c]
    dec ax
    cmp ax,[bp-0x1a]
    jng .label4 ; ↓
    mov ax,[bp-0x1a]
.label4: ; 3a6
    mov [local_10],ax
    ;; Draw chip in his new position, scroll the window,
    ;; set the new viewport position, and update the tile chip left
    ;
    ; UpdateTile(hdc, new x, new y)
    push word [newChipY]
    push word [newChipX]
    push word [bp+0x6]
    call 0x3f5:UpdateTile ; 3b2 2:1ca UpdateTile
    add sp,byte +0x6
    ; ScrollWindow(hwndBoard, -32*(dx-0), -32*(dy-0), NULL, NULL)
    push word [hwndBoard]
    ; x scroll amount = -32*(dx - 0)
    mov ax,si
    neg ax
    push ax
    ; y scroll amount = -32*(dy - 0)
    mov ax,[local_c]
    neg ax
    push ax
    push byte +0x0
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0xffff ; 3d1 USER.ScrollWindow
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
    call 0x454:UpdateTile ; 3f2 2:1ca UpdateTile
    add sp,byte +0x6
    ;; Now draw any tiles that were
    ;; scrolled into view
.check_x_delta:
    ; if x delta is nonzero
    or si,si
    jnz .update_x_tiles ; ↓
    jmp .check_y_delta ; ↓
.update_x_tiles: ; 401
    or si,si
    jng .label6 ; ↓
    mov ax,[local_6]
    sub ax,di ; ax -= delta x
    mov [local_a],ax
    mov bx,[local_4]
    jmp short .label7 ; ↓
.label6: ; 412
    mov word [local_a],0x0
    mov bx,di
    neg bx
.label7: ; 41b
    mov si,[GameStatePtr]
    mov ax,[si+ViewportY]
    mov [local_4],ax
    mov [local_8],bx
    mov cx,ax
    add ax,[si+ViewportHeight]
    cmp ax,cx
    jng .label11 ; ↓
.loop1: ; 433
    mov si,[local_a]
    cmp si,[local_8]
    jnl .label10 ; ↓
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
    call 0x50b:UpdateTile ; 451 2:1ca UpdateTile
    add sp,byte +0x6
    inc si
    cmp si,[local_8]
    jl .loop2 ; ↑
.label10: ; 45f
    mov bx,[GameStatePtr]
    mov ax,[bx+ViewportY]
    add ax,[bx+ViewportHeight]
    inc word [local_4]
    cmp ax,[local_4]
    jg .loop1 ; ↑
    ; rect = {local_a*32, -0*32, local_8*32, (vh-0)*32}
    ; ValidateRect(hwndBoard, &rect)
.label11: ; 473
    mov ax,[local_a]
    shl ax,byte TileShift
    mov [rect.x],ax
    mov ax,[local_8]
    shl ax,byte TileShift
    mov [rect.width],ax
    mov bx,[GameStatePtr]
    mov ax,[bx+UnusedOffsetY]
    shl ax,byte TileShift
    neg ax
    mov [rect.y],ax
    mov ax,[bx+ViewportHeight]
    sub ax,[bx+UnusedOffsetY]
    shl ax,byte TileShift
    mov [rect.height],ax
    push word [hwndBoard]
    lea ax,[rect]
    push ss
    push ax
    call 0x0:0x560 ; 4ac USER.ValidateRect
.check_y_delta: ; 4b1
    ; if y delta is nonzero
    cmp word [local_c],byte +0x0
    jnz .update_y_tiles ; ↓
    jmp .end ; ↓
.update_y_tiles: ; 4ba
    jng .label14 ; ↓
    mov di,[local_10]
    sub di,[viewportDeltaY]
    mov ax,[local_e]
    jmp short .label15 ; ↓
    nop
.label14: ; 4c8
    xor di,di
    mov ax,[viewportDeltaY]
    neg ax
.label15: ; 4cf
    mov [local_4],ax
    mov bx,[GameStatePtr]
    mov ax,[bx+ViewportX]
    mov [local_6],ax
    mov cx,ax
    add ax,[bx+ViewportWidth]
    cmp ax,cx
    jng .label19 ; ↓
    mov [local_8],di
.loop3: ; 4ea
    mov si,[local_8]
    cmp si,[local_4]
    jnl .label18 ; ↓
    mov di,[bp+0x6]
.loop4: ; 4f5
    mov bx,[GameStatePtr]
    mov ax,[bx+ViewportY]
    add ax,[bx+UnusedOffsetY]
    add ax,si
    push ax
    push word [local_6]
    push di
    call 0x5ee:UpdateTile ; 508 2:1ca UpdateTile
    add sp,byte +0x6
    inc si
    cmp si,[local_4]
    jl .loop4 ; ↑
.label18: ; 516
    mov bx,[GameStatePtr]
    mov ax,[bx+ViewportX]
    add ax,[bx+ViewportWidth]
    inc word [local_6]
    cmp ax,[local_6]
    jg .loop3 ; ↑
    mov di,[local_8]
.label19: ; 52d
    ; rect = {-0*32, di*32, (vw-0)*32, (local_4-0)*32}
    ; ValidateRect(hwndBoard, &rect)
    mov ax,[bx+UnusedOffsetX]
    shl ax,byte TileShift
    neg ax
    mov [rect.x],ax
    mov ax,[bx+ViewportWidth]
    sub ax,[bx+UnusedOffsetX]
    shl ax,byte TileShift
    mov [rect.width],ax
    shl di,byte TileShift
    mov [rect.y],di
    mov ax,[local_4]
    shl ax,byte TileShift
    mov [rect.height],ax
    push word [hwndBoard]
    lea ax,[bp-0x18]
    push ss
    push ax
    call 0x0:0xffff ; 55f USER.ValidateRect
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
    jnl .label0 ; ↓
    xor ax,ax
.label0: ; 5a1
    cmp ax,si
    jng .label1 ; ↓
    mov ax,si
.label1: ; 5a7
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
    jnl .label2 ; ↓
    xor ax,ax
.label2: ; 5cf
    cmp ax,si
    jng .label3 ; ↓
    mov ax,si
.label3: ; 5d5
    ; ax = difference between new y position and old position
    sub ax,[bx+ViewportY]
    ;; if viewport pos is the same, just update src and dest tiles
    or cx,cx
    jnz .label4 ; ↓
    cmp ax,cx
    jnz .label4 ; ↓
    ; UpdateTile(hdc, oldX, oldY)
    mov si,[hdc]
    push word [oldY]
    push word [oldX]
    push si
    call 0x5fd:UpdateTile ; 5eb 2:1ca UpdateTile
    add sp,byte +0x6
    ; UpdateTile(hdc, newX, newY)
    push word [newY]
    push word [newX]
    push si
    call 0x61a:UpdateTile ; 5fa 2:1ca UpdateTile
    add sp,byte +0x6
    jmp short .label5 ; ↓
    ; if viewport has moved, scroll the board
.label4: ; 604
    push word [oldY] ; old chipy
    push word [oldX] ; old chipx
    push word [newY] ; new chipy
    push word [newX] ; new chipx
    push ax            ; viewport y diff
    push word [bp-0x6] ; viewport x diff
    push word [hdc]    ; hdc probably
    call 0x652:ScrollViewport ; 617 2:306
    add sp,byte +0xe
.label5: ; 61f
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
    call 0x0:0xffff ; 638 WEP4UTIL.2
    or ax,ax
    jnz .label1 ; ↓
.returnZero: ; 641
    xor ax,ax
    jmp short .end ; ↓
    nop
.label1: ; 646
    cmp word [hPrevInstance],byte +0x0
    jnz .label2 ; ↓
    push word [hInstance]
    call 0x664:CreateClasses ; 64f 2:6c8 CreateClasses
    add sp,byte +0x2
    or ax,ax
    jz .returnZero
.label2: ; 65b
    push word [nCmdShow]
    push word [hInstance]
    call 0x6e6:CreateWindows ; 661 2:8e8 CreateWindows
    add sp,byte +0x4
    or ax,ax
    jz .returnZero
    mov word [Var2c],0x1
.label3: ; 673
    lea ax,[bp-0x14]
    push ss
    push ax
    push byte +0x0
    push byte +0x0
    push byte +0x0
    push byte +0x1
    call 0x0:0xffff ; 680 USER.PeekMessage
    or ax,ax
    ; FIXME: call WaitMessage if ax==0
    jz .label3 ; ↑
    cmp word [bp-0x12],byte +0x12
    jz .label4 ; ↓
    push word [hwndMain]
    push word [hAccel]
    lea ax,[bp-0x14]
    push ss
    push ax
    call 0x0:0xffff ; 69c USER.TranslateAccelerator
    or ax,ax
    jnz .label3 ; ↑
    lea ax,[bp-0x14]
    push ss
    push ax
    call 0x0:0xffff ; 6aa USER.TranslateMessage
    lea ax,[bp-0x14]
    push ss
    push ax
    call 0x0:0xffff ; 6b4 USER.DispatchMessage
    jmp short .label3 ; ↑
    nop
.label4: ; 6bc
    mov ax,[bp-0x10]
.end: ; 6bf
endfunc

; 6c8

CreateClasses:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x6a
    push si
    mov si,[bp+0x6]
    mov word [bp-0x6a],0x1000           ; style
    mov word [bp-0x68],MAINWNDPROC      ; lpfnWndProc
    mov word [bp-0x66],0x749            ;
    xor ax,ax
    mov [bp-0x64],ax                    ; cbClassExtra
    mov [bp-0x62],ax                    ; cbWndExtra
    mov [bp-0x60],si                    ; hInstance
    push si
    push ax
    push word 0x100
    call 0x0:0xffff ; 6f8 USER.LoadIcon
    mov [bp-0x5e],ax                    ; hIcon
    push byte +0x0
    push byte +0x0
    push word 0x7f00
    call 0x0:0x75f ; 707 USER.LoadCursor
    mov [bp-0x5c],ax                    ; hCursor
    push byte +0x4
    call 0x0:0xffff ; 711 GDI.GetStockObject
    mov [bp-0x5a],ax                    ; hbcBackground
    sub ax,ax
    mov [bp-0x56],ax                    ; lpszMenuName
    mov [bp-0x58],ax                    ;
    mov word [bp-0x54],MainClassName    ; lpszClassName
    mov [bp-0x52],ds                    ;
    lea ax,[bp-0x6a]
    push ss
    push ax
    call 0x0:0xffff ; 72e USER.RegisterClass
    or ax,ax
    jnz .label1 ; ↓
.label0: ; 737
    xor ax,ax
    jmp .label5 ; ↓
.label1: ; 73c
    mov word [bp-0x6a],0x8
    mov word [bp-0x68],BOARDWNDPROC
    mov word [bp-0x66],0x11
    xor ax,ax
    mov [bp-0x64],ax
    mov [bp-0x62],ax
    mov [bp-0x60],si
    mov [bp-0x5e],ax
    push ax
    push ax
    push word 0x7f03
    call 0x0:0xffff ; 75e USER.LoadCursor
    mov [bp-0x5c],ax
    push byte +0x4
    call 0x0:0x7bb ; 768 GDI.GetStockObject
    mov [bp-0x5a],ax
    sub ax,ax
    mov [bp-0x56],ax
    mov [bp-0x58],ax
    mov word [bp-0x54],BoardClassName
    mov [bp-0x52],ds
    lea ax,[bp-0x6a]
    push ss
    push ax
    call 0x0:0x7d8 ; 785 USER.RegisterClass
    or ax,ax
    jz .label0 ; ↑
    mov word [bp-0x6a],0x8
    mov word [bp-0x68],INFOWNDPROC
    mov word [bp-0x66],0x7f0
    xor ax,ax
    mov [bp-0x64],ax
    mov [bp-0x62],ax
    mov [bp-0x60],si
    mov [bp-0x5e],ax
    push ax
    push ax
    push word 0x7f00
    call 0x0:0x80a ; 7b0 USER.LoadCursor
    mov [bp-0x5c],ax
    push byte +0x4
    call 0x0:0x814 ; 7ba GDI.GetStockObject
    mov [bp-0x5a],ax
    sub ax,ax
    mov [bp-0x56],ax
    mov [bp-0x58],ax
    mov word [bp-0x54],InfoClassName
    mov [bp-0x52],ds
    lea ax,[bp-0x6a]
    push ss
    push ax
    call 0x0:0x831 ; 7d7 USER.RegisterClass
    or ax,ax
    jnz .label2 ; ↓
    jmp .label0 ; ↑
.label2: ; 7e3
    mov word [bp-0x6a],0x8
    mov word [bp-0x68],COUNTERWNDPROC
    mov word [bp-0x66],0x849
    mov word [bp-0x64],0x0
    mov word [bp-0x62],0x4
    mov [bp-0x60],si
    xor ax,ax
    mov [bp-0x5e],ax
    push ax
    push ax
    push word 0x7f00
    call 0x0:0x85f ; 809 USER.LoadCursor
    mov [bp-0x5c],ax
    push byte +0x4
    call 0x0:0x869 ; 813 GDI.GetStockObject
    mov [bp-0x5a],ax
    sub ax,ax
    mov [bp-0x56],ax
    mov [bp-0x58],ax
    mov word [bp-0x54],CounterClassName
    mov [bp-0x52],ds
    lea ax,[bp-0x6a]
    push ss
    push ax
    call 0x0:0x886 ; 830 USER.RegisterClass
    or ax,ax
    jnz .label3 ; ↓
    jmp .label0 ; ↑
.label3: ; 83c
    mov word [bp-0x6a],0x8
    mov word [bp-0x68],INVENTORYWNDPROC
    mov word [bp-0x66],0x89e
    xor ax,ax
    mov [bp-0x64],ax
    mov [bp-0x62],ax
    mov [bp-0x60],si
    mov [bp-0x5e],ax
    push ax
    push ax
    push word 0x7f00
    call 0x0:0x8b4 ; 85e USER.LoadCursor
    mov [bp-0x5c],ax
    push byte +0x4
    call 0x0:0x8be ; 868 GDI.GetStockObject
    mov [bp-0x5a],ax
    sub ax,ax
    mov [bp-0x56],ax
    mov [bp-0x58],ax
    mov word [bp-0x54],InventoryClassName
    mov [bp-0x52],ds
    lea ax,[bp-0x6a]
    push ss
    push ax
    call 0x0:0x8db ; 885 USER.RegisterClass
    or ax,ax
    jnz .label4 ; ↓
    jmp .label0 ; ↑
.label4: ; 891
    mov word [bp-0x6a],0x8
    mov word [bp-0x68],HINTWNDPROC
    mov word [bp-0x66],0xb0b
    xor ax,ax
    mov [bp-0x64],ax
    mov [bp-0x62],ax
    mov [bp-0x60],si
    mov [bp-0x5e],ax
    push ax
    push ax
    push word 0x7f00
    call 0x0:0x708 ; 8b3 USER.LoadCursor
    mov [bp-0x5c],ax
    push byte +0x4
    call 0x0:0x712 ; 8bd GDI.GetStockObject
    mov [bp-0x5a],ax
    sub ax,ax
    mov [bp-0x56],ax
    mov [bp-0x58],ax
    mov word [bp-0x54],HintClassName
    mov [bp-0x52],ds
    lea ax,[bp-0x6a]
    push ss
    push ax
    call 0x0:0x72f ; 8da USER.RegisterClass
.label5: ; 8df
    pop si
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 8e8

func CreateWindows
    sub sp,byte +0x16
    push di
    push si
    %arg hInstance:word ; +6
    %arg nCmdShow:word ; +8
    mov si,[hInstance]
    mov word [bp-0x6],0x0
    mov word [bp-0x4],0x2cf
    mov [OurHInstance],si
    push si
    push ds
    push word s_ChipsMenu
    call 0x0:0xffff ; 90d USER.LoadMenu
    mov [hMenu],ax
    push byte +0x40
    push word GameStateSize
    call 0x0:0xffff ; 91a KERNEL.LocalAlloc
    mov [0x1722],ax
    mov [GameStatePtr],ax
    or ax,ax
    jnz .label1 ; ↓
.label0: ; 929
    xor ax,ax
    jmp .label16 ; ↓
.label1: ; 92e
    call 0x0:0xffff ; 92e USER.GetCurrentTime
    push ax
    call 0xffff:0xc4 ; 934 1:c4 srand
    add sp,byte +0x2
    push byte +0x1
    call 0xffff:0x0 ; 93e 5:0 InitGraphics
    add sp,byte +0x2
    mov ax,[0x169e]
    mov [bp-0xe],ax
    mov cx,[0x16a0]
    mov [bp-0xc],cx
    add cx,TileHeight * 32
    mov [bp-0x8],cx
    add ax,TileWidth * 32
    mov [bp-0xa],ax
    xor dx,dx
    mov [bp-0x14],dx
    mov [bp-0x16],dx
    add cx,[0x16a0]
    mov [bp-0x10],cx
    add ax,[0x169e]
    add ax,0xa0
    mov [bp-0x12],ax
    lea ax,[bp-0x16]
    push ss                                             ; lpRect
    push ax
    push word (WS_CLIPCHILDREN | WS_TILEDWINDOW)>>16    ; dwStyle
    push dx ; 0
    push byte +0x1                                      ; bMenu
    call 0x0:0xffff ; 984 USER.AdjustWindowRect
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
    call 0x0:0x9f1 ; 9b5 USER.CreateWindow
    mov [hwndMain],ax
    or ax,ax
    jnz .label2 ; ↓
    jmp .label0 ; ↑
.label2: ; 9c4
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
    call 0x0:0xa2c ; 9f0 USER.CreateWindow
    mov [hwndBoard],ax
    or ax,ax
    jnz .label3 ; ↓
    jmp .label0 ; ↑
.label3: ; 9ff
    push ds
    push word s_InfoClass
    push byte +0x0
    push byte +0x0
    push word 0x5200
    push byte +0x0
    mov ax,[0x169e]
    add ax,TileWidth * 32 + 0x13
    push ax
    mov ax,[0x16a0]
    sub ax,0x6
    push ax
    push word 0x9a
    push word 0x12c
    push word [hwndMain]
    push byte +0x7
    push si
    push byte +0x0
    push byte +0x0
    call 0x0:0xa58 ; a2b USER.CreateWindow
    mov [hwndInfo],ax
    or ax,ax
    jnz .label4 ; ↓
    jmp .label0 ; ↑
.label4: ; a3a
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
    call 0x0:0xa87 ; a57 USER.CreateWindow
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
    call 0x0:0xab7 ; a86 USER.CreateWindow
    mov [hwndCounter2],ax
    or ax,ax
    jnz .label6 ; ↓
    jmp .label0 ; ↑
.label6: ; a95
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
    call 0x0:0xae8 ; ab6 USER.CreateWindow
    mov [hwndCounter3],ax
    or ax,ax
    jnz .label7 ; ↓
    jmp .label0 ; ↑
.label7: ; ac5
    push ds
    push word s_InventoryClass
    push byte +0x0
    push byte +0x0
    push word 0x5400
    push byte +0x0
    push byte 13 + 0x40 - TileWidth*4/2
    push word 0xdd + 0x20 - TileWidth*2/2
    push word TileWidth * 4
    push byte TileWidth * 2
    push word [hwndInfo]
    push byte +0x5
    push si
    push byte +0x0
    push byte +0x0
    call 0x0:0xffff ; ae7 USER.CreateWindow
    mov [hwndInventory],ax
    or ax,ax
    jnz .label8 ; ↓
    jmp .label0 ; ↑
.label8: ; af6
    mov di,[nCmdShow]
    cmp di,byte +0x6
    jz .label9 ; ↓
    cmp di,byte +0x2
    jz .label9 ; ↓
    cmp di,byte +0x7
    jnz .label10 ; ↓
.label9: ; b08
    call 0x3b5:PauseTimer ; b08 2:17a2
    inc word [GamePaused]
.label10: ; b11
    push word [hwndMain]
    push di
    call 0x0:0xc67 ; b16 USER.ShowWindow
    push word [hwndMain]
    call 0x0:0xffff ; b1f USER.UpdateWindow
    push word ID_CurrentLevel
    call 0xb40:GetIniInt ; b27 2:198e
    add sp,byte +0x2
    cmp ax,0x1
    jnl .label11 ; ↓
    mov si,0x1
    jmp short .label12 ; ↓
    nop
.label11: ; b3a
    push word ID_CurrentLevel
    call 0xb4d:GetIniInt ; b3d 2:198e
    add sp,byte +0x2
    mov si,ax
.label12: ; b47
    push word ID_CurrentScore
    call 0xb62:GetIniLong; b4a 2:1a1c
    add sp,byte +0x2
    or dx,dx
    jnl .label13 ; ↓
    xor ax,ax
    cwd
    jmp short .label14 ; ↓
    nop
.label13: ; b5c
    push word ID_CurrentScore
    call 0xc08:GetIniLong; b5f 2:1a1c
    add sp,byte +0x2
.label14: ; b67
    mov [TotalScore],ax
    mov [TotalScore+2],dx
    cmp si,byte +0x1
    jng .label15 ; ↓
    push si
    call 0xb89:0xe48 ; b74 4:e48
    add sp,byte +0x2
    or ax,ax
    jnz .label15 ; ↓
    mov si,0x1
.label15: ; b83
    push byte +0x0
    push si
    call 0x2dc:0x356 ; b86 4:356
    add sp,byte +0x4
    mov ax,0x1
.label16: ; b91
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
    ja .label0 ; ↓
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
.label0: ; bd4
    mov ax,s_Ooops
    jmp short .label7 ; ↓
    nop
.label1: ; bda
    mov ax,FireDeathMessage
    jmp short .label7 ; ↓
    nop
.label2: ; be0
    mov ax,WaterDeathMessage
    jmp short .label7 ; ↓
    nop
.label3: ; be6
    mov ax,BombDeathMessage
    jmp short .label7 ; ↓
    nop
.label4: ; bec
    mov ax,BlockDeathMessage
    jmp short .label7 ; ↓
    nop
.label5: ; bf2
    mov ax,MonsterDeathMessage
    jmp short .label7 ; ↓
    nop
.label6: ; bf8
    mov ax,TimeDeathMessage
.label7: ; bfb
    mov cx,ax
    push byte +0x0
    push ds
    push cx
    push word [hwndMain]
    call 0xdae:ShowMessageBox ; c05 2:0 ShowMessageBox
    add sp,byte +0x8
    mov [SoundEnabled],si
    pop si
endfunc

; c1a

ShowHint:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    cmp word [hwndHint],byte +0x0
    jnz .label0 ; ↓
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
    call 0x0:0x9b6 ; c54 USER.CreateWindow
    mov [hwndHint],ax
    or ax,ax
    jz .label0 ; ↓
    push word [hwndCounter3]
    push byte +0x0
    call 0x0:0xc72 ; c66 USER.ShowWindow
    push word [hwndInventory]
    push byte +0x0
    call 0x0:0xca8 ; c71 USER.ShowWindow
.label0: ; c76
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; c7e

func HideHint
    sub sp,byte +0x2
    cmp word [hwndHint],byte +0x0
    jz .end ; ↓
    push word [hwndHint]
    call 0x0:0xffff ; c96 USER.DestroyWindow
    mov word [hwndHint],0x0
    push word [hwndCounter3]
    push byte +0x5
    call 0x0:0xcb3 ; ca7 USER.ShowWindow
    push word [hwndInventory]
    push byte +0x5
    call 0x0:0xffff ; cb2 USER.ShowWindow
.end: ; cb7
endfunc

; cbe

; refresh timer, chip counter, inventory and hint box
FUN_2_0cbe:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    push di
    push si
    mov si,[bp+0x6]
    test si,0x1
    jz .label1 ; ↓
    push word [hwndCounter2]
    push byte +0x0
    push word [TimeRemaining]
    call 0x0:0xd06 ; ce0 USER.SetWindowWord
    push word [hwndCounter2]
    push byte +0x2
    call 0x0:0xffff ; ceb USER.GetWindowWord
    and al,0xfe
    mov di,ax
    cmp word [TimeRemaining],byte +0xf
    jg .label0 ; ↓
    or di,byte +0x1
.label0: ; cfe
    push word [hwndCounter2]
    push byte +0x2
    push di
    call 0x0:0xd2a ; d05 USER.SetWindowWord
    push word [hwndCounter2]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0xd4e ; d14 USER.InvalidateRect
.label1: ; d19
    test si,0x2
    jz .label2 ; ↓
    push word [hwndCounter3]
    push byte +0x0
    push word [ChipsRemainingCount]
    call 0x0:0xd3f ; d29 USER.SetWindowWord
    push word [hwndCounter3]
    push byte +0x2
    cmp word [ChipsRemainingCount],byte +0x1
    sbb ax,ax
    neg ax
    push ax
    call 0x0:0xd67 ; d3e USER.SetWindowWord
    push word [hwndCounter3]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0xd76 ; d4d USER.InvalidateRect
.label2: ; d52
    test si,0x20
    jz .label3 ; ↓
    push word [hwndCounter]
    push byte +0x0
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    call 0x0:0xffff ; d66 USER.SetWindowWord
    push word [hwndCounter]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0xd8b ; d75 USER.InvalidateRect
.label3: ; d7a
    test si,0x4
    jz .label4 ; ↓
    push word [hwndInventory]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0x2f8 ; d8a USER.InvalidateRect
.label4: ; d8f
    mov ax,si
    test al,0x8
    jz .label6 ; ↓
    mov bx,[GameStatePtr]
    mov si,[bx+ChipY]
    shl si,byte 0x5
    add si,[bx+ChipX]
    cmp byte [bx+si+Lower],Hint
    jnz .label5 ; ↓
    call 0xdb5:ShowHint ; dab 2:c1a ShowHint
    jmp short .label6 ; ↓
.label5: ; db2
    call 0x79b:HideHint ; db2 2:c7e HideHint
.label6: ; db7
    mov word [InventoryDirty],0x0
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; dc6

; draw main window background
FUN_2_0dc6:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x20
    push di
    push si
    push word [OurHInstance]
    push ds
    push word s_background
    call 0x0:0xffff ; ddd USER.LoadBitmap
    mov si,ax
    or si,si
    jnz .label0 ; ↓
    jmp .label5 ; ↓
.label0: ; deb
    mov di,[bp+0x8]
    push word [0x1734]
    push si
    call 0x0:0xe71 ; df3 GDI.SelectObject
    mov [bp-0x8],ax
    push si
    push byte +0xe
    lea ax,[bp-0x20]
    push ss
    push ax
    call 0x0:0xffff ; e03 GDI.GetObject
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
.label1: ; e2a
    mov si,[bp-0x6]
    cmp si,[di+0xa]
    jnl .label3 ; ↓
.label2: ; e32
    push word [di]
    push word [bp-0x4]
    push si
    push word [bp-0x1e]
    push word [bp-0x1c]
    push word [0x1734]
    push byte +0x0
    push byte +0x0
    push word 0xcc
    push byte +0x20
    call 0x0:0x122 ; e4b GDI.BitBlt
    add si,[bp-0x1c]
    cmp si,[di+0xa]
    jl .label2 ; ↑
.label3: ; e58
    mov ax,[di+0x8]
    mov cx,[bp-0x1e]
    add [bp-0x4],cx
    cmp [bp-0x4],ax
    jl .label1 ; ↑
    mov si,[bp-0xa]
.label4: ; e69
    push word [0x1734]
    push word [bp-0x8]
    call 0x0:0xffff ; e70 GDI.SelectObject
    push si
    call 0x0:0xffff ; e76 GDI.DeleteObject
    jmp short .label6 ; ↓
    nop
.label5: ; e7e
    mov bx,[bp+0x8]
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
    call 0x0:0x2a7 ; e9b GDI.PatBlt
.label6: ; ea0
    mov ax,[0x169e]
    mov [bp-0x12],ax
    mov cx,[0x16a0]
    mov [bp-0x10],cx
    add cx,TileWidth * 32
    mov [bp-0xc],cx
    add ax,TileHeight * 32
    mov [bp-0xe],ax
    push byte +0x2
    push cx
    push ax
    push word [bp-0x10]
    push word [bp-0x12]
    mov bx,[bp+0x8]
    push word [bx]
    call 0xef7:DrawSolidBorder ; ec9 2:1006
    add sp,byte +0xc
    lea ax,[bp-0x12]
    push ss
    push ax
    push byte +0x2
    push byte +0x2
    call 0x0:0xf62 ; eda USER.InflateRect
    push byte +0x1
    push byte +0x4
    push word [bp-0xc]
    push word [bp-0xe]
    push word [bp-0x10]
    push word [bp-0x12]
    mov bx,[bp+0x8]
    push word [bx]
    call 0xb2a:FUN_2_0f06 ; ef4 2:f06
    add sp,byte +0xe
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; f06

; draw an inset/outset border
func FUN_2_0f06
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
    call 0x0:0xf33 ; f21 GDI.GetStockObject
    mov di,ax
    ; get a GRAY_BRUSH or a WHITE_BRUSH
    ; depending on whether si != 0 or not
    cmp si,byte +0x1
    cmc
    sbb ax,ax
    and ax,0x2
    push ax
    call 0x0:0x101c ; f32 GDI.GetStockObject
    mov [bp-0x4],ax
    ; select the first brush
    push word [bp+0x6]
    push di
    call 0x0:0xf6b ; f3e GDI.SelectObject
    mov [bp-0x8],ax
    ;
    cmp word [bp+0x10],byte +0x0
    jg .label0 ; ↓
    jmp .cleanup ; ↓
.label0: ; f4f
    mov [bp-0x6],di
    mov si,[bp+0x6]
    mov di,[bp+0x10]
.loop: ; f58
    lea ax,[bp+0x8]
    push ss
    push ax
    push byte +0x1
    push byte +0x1
    call 0x0:0x103f ; f61 USER.InflateRect
    push si
    push word [bp-0x6]
    call 0x0:0xfae ; f6a GDI.SelectObject
    push si
    mov ax,[bp+0x8]
    inc ax
    push ax
    push word [bp+0xa]
    mov ax,[bp+0xc]
    sub ax,[bp+0x8]
    sub ax,0x2
    push ax
    push byte +0x1
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call 0x0:0xfa5 ; f89 GDI.PatBlt
    push si
    push word [bp+0x8]
    push word [bp+0xa]
    push byte +0x1
    mov ax,[bp+0xe]
    sub ax,[bp+0xa]
    dec ax
    push ax
    push word 0xf0
    push byte +0x21
    call 0x0:0xfcb ; fa4 GDI.PatBlt
    push si
    push word [bp-0x4]
    call 0x0:0xff8 ; fad GDI.SelectObject
    push si
    push word [bp+0x8]
    mov ax,[bp+0xe]
    dec ax
    push ax
    mov ax,[bp+0xc]
    sub ax,[bp+0x8]
    dec ax
    push ax
    push byte +0x1
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call 0x0:0xfe7 ; fca GDI.PatBlt
    push si
    mov ax,[bp+0xc]
    dec ax
    push ax
    push word [bp+0xa]
    push byte +0x1
    mov ax,[bp+0xe]
    sub ax,[bp+0xa]
    push ax
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call 0x0:0x105e ; fe6 GDI.PatBlt
    dec di
    jz .cleanup ; ↓
    jmp .loop ; ↑
.cleanup: ; ff1
    ; restore the selected object
    push word [bp+0x6]
    push word [bp-0x8]
    call 0x0:0x1022 ; ff7 GDI.SelectObject
    pop si
    pop di
endfunc

; 1006

; draw a solid border
func DrawSolidBorder
    sub sp,byte +0x4
    push di
    push si
    mov si,[bp+0x6]
    ; get a light gray brush and select it
    push si
    push byte +0x1 ; LTGRAY BRUSH
    call 0x0:0x769 ; 101b GDI.GetStockObject
    push ax
    call 0x0:0x10c1 ; 1021 GDI.SelectObject
    mov [bp-0x4],ax
    ; check a flag
    cmp word [bp+0x10],byte +0x0
    jg .label0 ; ↓
    jmp .cleanup ; ↓
.label0: ; 1032
    mov di,[bp+0x10]
.loop: ; 1035
    lea ax,[bp+0x8]
    push ss
    push ax
    push byte +0x1
    push byte +0x1
    call 0x0:0xffff ; 103e USER.InflateRect
    push si
    mov ax,[bp+0x8]
    inc ax
    push ax
    push word [bp+0xa]
    mov ax,[bp+0xc]
    sub ax,[bp+0x8]
    sub ax,0x2
    push ax
    push byte +0x1
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call 0x0:0x1079 ; 105d GDI.PatBlt
    push si
    push word [bp+0x8]
    push word [bp+0xa]
    push byte +0x1
    mov ax,[bp+0xe]
    sub ax,[bp+0xa]
    dec ax
    push ax
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call 0x0:0x1096 ; 1078 GDI.PatBlt
    push si
    push word [bp+0x8]
    mov ax,[bp+0xe]
    dec ax
    push ax
    mov ax,[bp+0xc]
    sub ax,[bp+0x8]
    dec ax
    push ax
    push byte +0x1
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call 0x0:0x10b2 ; 1095 GDI.PatBlt
    push si
    mov ax,[bp+0xc]
    dec ax
    push ax
    push word [bp+0xa]
    push byte +0x1
    mov ax,[bp+0xe]
    sub ax,[bp+0xa]
    push ax
    push word 0xf0 ; PATCOPY
    push byte +0x21
    call 0x0:0x111d ; 10b1 GDI.PatBlt
    dec di
    jz .cleanup ; ↓
    jmp .loop ; ↑
.cleanup: ; 10bc
    push si
    push word [bp-0x4]
    call 0x0:0x1178 ; 10c0 GDI.SelectObject
    pop si
    pop di
endfunc

; 10ce

; draw board?
; and level placard
; and/or pause screen
FUN_2_10ce:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,0xcc
    push di
    push si
    cmp word [GamePaused],byte +0x0
    jnz .label0 ; ↓
    jmp .label7 ; ↓
.label0: ; 10e8
    cmp word [DebugModeEnabled],byte +0x0
    jz .label1 ; ↓
    jmp .label7 ; ↓
.label1: ; 10f2
    mov si,[bp+0x8]
    push word [bp+0x6]
    lea ax,[bp-0x26]
    push ss
    push ax
    call 0x0:0x348 ; 10fd USER.GetClientRect
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
    call 0x0:0xe9c ; 111c GDI.PatBlt
    ; computes font height by multiplying the desired point size by the screen's DPI,
    ; as suggested by Microsoft's documentation:
    ; (https://docs.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-logfonta)
    ;
    ;    lfHeight = MulDiv(-32, GetDeviceCaps(hDC, LOGPIXELSY), 72)
    push byte -0x20
    push word [si]
    push byte +0x5a ; LOGPIXELSY
    call 0x0:0xffff ; 1127 GDI.GetDeviceCaps
    push ax
    push byte +0x48
    call 0x0:0xffff ; 112f GDI.MulDiv
    mov [LOGFONT.lfHeight],ax
    mov word [LOGFONT.lfWeight],400
    mov byte [LOGFONT.lfItalic],0
    push ds
    push word LOGFONT.lfFaceName ; Arial
    cmp word [IsWin31],byte +0x0
    jz .label2 ; ↓
    mov ax,s_Arial1
    jmp short .label3 ; ↓
.label2: ; 1152
    mov ax,s_Helv1
.label3: ; 1155
    mov [bp-0x6],ax
    mov [bp-0x4],ds
    push ds
    push ax
    call 0x0:0xffff ; 115d KERNEL.lstrcpy
    push ds
    push word LOGFONT
    call 0x0:0xffff ; 1166 GDI.CreateFontIndirect
    mov di,ax
    or di,di
    jnz .label4 ; ↓
    jmp .label43 ; ↓
.label4: ; 1174
    push word [si]
    push di
    call 0x0:0x121a ; 1177 GDI.SelectObject
    mov [bp-0x1a],ax
    push word [si]
    push byte +0x2
    call 0x0:0x11ea ; 1183 GDI.SetBkMode
    mov [bp-0x1c],ax
    push word [si]
    push byte +0x0
    push byte +0x0
    call 0x0:0x11fb ; 1191 GDI.SetBkColor
    mov [bp-0x14],ax
    mov [bp-0x12],dx
    push word [si]
    mov [bp-0xc8],si
    mov [bp-0xca],di
    cmp word [ColorMode],byte +0x1
    jnz .label5 ; ↓
    mov ax,0xffff
    mov dx,0xff
    jmp short .label6 ; ↓
    nop
.label5: ; 11b6
    mov ax,0xff
    cwd
.label6: ; 11ba
    push dx
    push ax
    call 0x0:0xffff ; 11bc GDI.SetTextColor
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
    call 0x0:0xffff ; 11db USER.DrawText
    mov bx,[bp-0xc8]
    push word [bx]
    push word [bp-0x1c]
    call 0x0:0xffff ; 11e9 GDI.SetBkMode
    mov bx,[bp-0xc8]
    push word [bx]
    push word [bp-0x12]
    push word [bp-0x14]
    call 0x0:0x120c ; 11fa GDI.SetBkColor
    mov bx,[bp-0xc8]
    push word [bx]
    push word [bp-0x16]
    push word [bp-0x18]
    call 0x0:0xffff ; 120b GDI.SetBkColor
    mov bx,[bp-0xc8]
    push word [bx]
    push word [bp-0x1a]
    call 0x0:0xdf4 ; 1219 GDI.SelectObject
    push word [bp-0xca]
    jmp .label42 ; ↓
    nop
.label7: ; 1226
    mov bx,[GameStatePtr]
    cmp word [bx+EndingTick],byte +0x0
    jz .label8 ; ↓
    push byte +0x1
    call 0xffff:0xa74 ; 1233 7:a74 EndGame
    add sp,byte +0x2
    jmp .label43 ; ↓
.label8: ; 123e
    cmp word [bx+ViewportWidth],byte +0x0
    jnz .label9 ; ↓
    jmp .label43 ; ↓
.label9: ; 1248
    cmp word [bx+ViewportHeight],byte +0x0
    jnz .label10 ; ↓
    jmp .label43 ; ↓
.label10: ; 1252
    mov si,[bp+0x8]
    mov ax,[si+0x4]
    sar ax,byte TileShift
    add ax,[bx+ViewportX]
    add ax,[bx+UnusedOffsetX]
    cmp ax,[bx+ViewportX]
    jnl .label11 ; ↓
    mov ax,[bx+ViewportX]
.label11: ; 126d
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
    jng .label12 ; ↓
    mov di,ax
.label12: ; 1290
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
    jng .label13 ; ↓
    mov cx,ax
.label13: ; 12b8
    mov [bp-0xa],cx
    mov ax,[si+0x6]
    sar ax,byte TileShift
    mov bx,dx
    add dx,ax
    mov ax,bx
    mov bx,[GameStatePtr]
    add dx,[bx+UnusedOffsetY]
    cmp dx,ax
    jnl .label14 ; ↓
    mov dx,ax
.label14: ; 12d5
    mov [bp-0x6],dx
    cmp cx,dx
    jnl .label15 ; ↓
    jmp .label24 ; ↓
.label15: ; 12df
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
    call 0xecc:UpdateTile ; 12f2 2:1ca UpdateTile
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
    jnl .label20 ; ↓
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
    call 0x0:0x1370 ; 134e GDI.PatBlt
.label20: ; 1353
    cmp [si+0xa],di
    jng .label21 ; ↓
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
    call 0x0:0x15c7 ; 136f GDI.PatBlt
.label21: ; 1374
    mov bx,[GameStatePtr]
    cmp word [bx+IsLevelPlacardVisible],byte +0x0
    jnz .label22 ; ↓
    jmp .label43 ; ↓
.label22: ; 1382
    cmp byte [bx+LevelTitle],0x0
    jnz .label23 ; ↓
    cmp byte [bx+LevelPassword],0x0
    jnz .label23 ; ↓
    jmp .label43 ; ↓
.label23: ; 1393
    cmp word [ColorMode],byte +0x1
    jnz .label25 ; ↓
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
    call 0x0:0x1184 ; 13b7 GDI.SetBkMode
    mov [bp-0x1c],ax
    push word [si]
    push byte +0x0
    push byte +0x0
    call 0x0:0x1192 ; 13c5 GDI.SetBkColor
    mov [bp-0x14],ax
    mov [bp-0x12],dx
    push word [si]
    push word [bp-0x4]
    push word [bp-0x6]
    call 0x0:0x11bd ; 13d8 GDI.SetTextColor
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
    call 0x0:0x1128 ; 13fa GDI.GetDeviceCaps
    push ax
    push byte +0x48
    call 0x0:0x1130 ; 1402 GDI.MulDiv
    mov [LOGFONT.lfHeight],ax
    mov word [LOGFONT.lfWeight],700
    mov byte [LOGFONT.lfItalic],0
    push ds
    push word LOGFONT.lfFaceName
    cmp word [IsWin31],byte +0x0
    jz .label28 ; ↓
    mov ax,s_Arial2
    jmp short .label29 ; ↓
    nop
.label28: ; 1426
    mov ax,s_Helv2
.label29: ; 1429
    mov si,ax
    mov [bp-0x4],ds
    push ds
    push ax
    call 0x0:0x115e ; 1430 KERNEL.lstrcpy
    push ds
    push word LOGFONT
    call 0x0:0x1167 ; 1439 GDI.CreateFontIndirect
    mov [bp-0x10],ax
    or ax,ax
    jz .label30 ; ↓
    mov bx,[bp+0x8]
    push word [bx]
    push ax
    call 0x0:0xf3f ; 144b GDI.SelectObject
    mov [bp-0x1a],ax
.label30: ; 1453
    mov bx,[bp+0x8]
    push word [bx]
    lea ax,[bp-0x46]
    push ss
    push ax
    call 0x0:0xffff ; 145d GDI.GetTextMetrics
    mov ax,[bp-0x46]
    mov [bp-0x4],ax
    xor ax,ax
    mov [bp-0xa],ax
    mov [bp-0x6],ax
    mov bx,[GameStatePtr]
    mov cx,[bx+ViewportWidth]
    shl cx,byte TileShift
    mov [bp-0x8],cx
    cmp byte [bx+LevelTitle],0x1
    sbb cx,cx
    inc cx
    mov di,cx
    cmp cx,ax
    jz .label32 ; ↓
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
    call 0x0:0x151e ; 14ad USER._wsprintf
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
    call 0x0:0x153f ; 14cb USER.DrawText
    mov [bp-0x20],ax
    mov ax,[bp-0x22]
    sub ax,[bp-0x26]
    jns .label31 ; ↓
    xor ax,ax
.label31: ; 14dd
    mov [bp-0x6],ax
    mov ax,[bp-0x20]
    sub ax,[bp-0x24]
    mov [bp-0xa],ax
.label32: ; 14e9
    mov bx,[GameStatePtr]
    cmp byte [bx+LevelPassword],0x1
    sbb ax,ax
    inc ax
    mov si,ax
    or ax,ax
    jz .label34 ; ↓
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
    call 0x0:0x15f6 ; 151d USER._wsprintf
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
    call 0x0:0x1614 ; 153e USER.DrawText
    mov [bp-0x20],ax
    mov ax,[bp-0x22]
    sub ax,[bp-0x26]
    cmp ax,[bp-0x6]
    jnl .label33 ; ↓
    mov ax,[bp-0x6]
.label33: ; 1554
    mov [bp-0x6],ax
    mov ax,[bp-0x20]
    sub ax,[bp-0x24]
    add [bp-0xa],ax
.label34: ; 1560
    mov ax,[bp-0x6]
    add ax,0x8
    cmp ax,[bp-0x8]
    jng .label35 ; ↓
    cmp word [bp-0xe],byte +0x6
    jng .label35 ; ↓
    jmp .label40 ; ↓
.label35: ; 1574
    mov word [bp-0x1e],0x1
    or di,di
    jz .label36 ; ↓
    or si,si
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
    call 0x0:0xf8a ; 15c6 GDI.PatBlt
    mov word [bp-0x26],0x0
    mov ax,[bp-0x4]
    add ax,[bp-0x24]
    mov [bp-0x20],ax
    mov ax,[bp-0x8]
    mov [bp-0x22],ax
    or di,di
    jz .label38 ; ↓
    mov ax,[GameStatePtr]
    add ax,LevelTitle
    push ds
    push ax
    push ds
    push word s_5c9 ; " %s "
    lea ax,[bp-0xc6]
    push ss
    push ax
    call 0x0:0xffff ; 15f5 USER._wsprintf
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
    call 0x0:0x11dc ; 1613 USER.DrawText
    mov ax,[bp-0x4]
    add [bp-0x24],ax
    add [bp-0x20],ax
.label38: ; 1621
    or si,si
    jz .label39 ; ↓
    mov ax,[GameStatePtr]
    add ax,LevelPassword
    push ds
    push ax
    push ds
    push word s_5ce ; " Password: %s "
    lea ax,[bp-0xc6]
    push ss
    push ax
    call 0x0:0x14ae ; 1637 USER._wsprintf
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
    call 0x0:0x14cc ; 1655 USER.DrawText
    mov ax,[bp-0x4]
    add [bp-0x24],ax
    add [bp-0x20],ax
.label39: ; 1663
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
    call 0x1746:FUN_2_0f06 ; 1695 2:f06
    add sp,byte +0xe
.label40: ; 169d
    dec word [bp-0xe]
    cmp word [bp-0x1e],byte +0x0
    jnz .label41 ; ↓
    jmp .label27 ; ↑
.label41: ; 16a9
    mov di,[bp-0x10]
    mov bx,[bp+0x8]
    push word [bx]
    push word [bp-0x1c]
    call 0x0:0x13b8 ; 16b4 GDI.SetBkMode
    mov bx,[bp+0x8]
    push word [bx]
    push word [bp-0x12]
    push word [bp-0x14]
    call 0x0:0x16d5 ; 16c4 GDI.SetBkColor
    mov bx,[bp+0x8]
    push word [bx]
    push word [bp-0x16]
    push word [bp-0x18]
    call 0x0:0x13c6 ; 16d4 GDI.SetBkColor
    or di,di
    jz .label43 ; ↓
    mov bx,[bp+0x8]
    push word [bx]
    push word [bp-0x1a]
    call 0x0:0x144c ; 16e5 GDI.SelectObject
    push di
.label42: ; 16eb
    call 0x0:0xe77 ; 16eb GDI.DeleteObject
.label43: ; 16f0
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 16fa

; create timer
FUN_2_16fa:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
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
    mov si,0x6e
    jmp short .label2 ; ↓
    nop
.label1: ; 1720
    mov si,0xdc
.label2: ; 1723
    mov cx,[hwndBoard]
.label3: ; 1727
    push cx
    push word [bp+0x6]
    push si
    push byte +0x0
    push byte +0x0
    call 0x0:0xffff ; 1730 USER.SetTimer
    or ax,ax
    jnz .label4 ; ↓
    push byte +0x30
    push ds
    push word SystemTimerErrorMsg
    push word [hwndMain]
    call 0x17ea:ShowMessageBox ; 1743 2:0 ShowMessageBox
    add sp,byte +0x8
    push word [hwndMain]
    push word 0x111
    push byte +0x6a
    push byte +0x0
    push byte +0x0
    call 0x0:0xffff ; 1758 USER.PostMessage
    xor ax,ax
    jmp short .label5 ; ↓
    nop
.label4: ; 1762
    mov ax,0x1
.label5: ; 1765
    pop si
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 176e

; destroy timer
FUN_2_176e:
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
    call 0x0:0xffff ; 1794 USER.KillTimer
    pop si
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 17a2

; void PauseTimer()
;
; Stops the game tick from advancing.
; This function can be called multiple times;
; the timer will only resume when a matching number of
; calls to UnpauseTimer are made.
PauseTimer:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    inc word [Var22]
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 17ba

; void UnpauseTimer()
UnpauseTimer:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    mov ax,[Var22]
    dec ax
    jns .label0 ; ↓
    xor ax,ax
.label0: ; 17cf
    mov [Var22],ax
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 17da

PauseGame:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    call 0x1893:PauseTimer ; 17e7 2:17a2
    push word [hMenu]
    push byte ID_PAUSE
    inc word [GamePaused]
    cmp word [GamePaused],byte +0x0
    jng .label0 ; ↓
    mov ax,0x8
    jmp short .label1 ; ↓
.label0: ; 1802
    xor ax,ax
.label1: ; 1804
    push ax
    call 0x0:0x1860 ; 1805 USER.CheckMenuItem
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    push word [hwndMain]
    call 0x187c:0x134 ; 1816 4:134 UpdateWindowTitle
    add sp,byte +0x4
    push word [hwndBoard]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0x188c ; 1828 USER.InvalidateRect
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 1834

UnpauseGame:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    push word [hMenu]
    push byte ID_PAUSE
    mov ax,[GamePaused]
    dec ax
    jns .label0 ; ↓
    xor ax,ax
.label0: ; 184f
    mov [GamePaused],ax
    or ax,ax
    jng .label1 ; ↓
    mov ax,0x8
    jmp short .label2 ; ↓
    nop
.label1: ; 185c
    xor ax,ax
.label2: ; 185e
    push ax
    call 0x0:0xffff ; 185f USER.CheckMenuItem
    push word [hwndMain]
    call 0x0:0xffff ; 1868 USER.DrawMenuBar
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    push word [hwndMain]
    call 0xb77:0x134 ; 1879 4:134 UpdateWindowTitle
    add sp,byte +0x4
    push word [hwndBoard]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0xd15 ; 188b USER.InvalidateRect
    call 0x19a6:UnpauseTimer ; 1890 2:17ba
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 189c

PauseMusic:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    call 0x18d5:0x2d4 ; 18a9 8:2d4
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 18b6

UnpauseMusic:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x2
    cmp word [MusicEnabled],byte +0x0
    jz .label0 ; ↓
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    call 0xffff:0x308 ; 18d2 8:308
.label0: ; 18d7
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 18de

; char* GetIniKey(int id, int* pDefaultValue)
;
; Returns the key for the requested INI setting.
; If pDefaultValue is not NULL, it is set to the default
; value for the requested key.
func GetIniKey
    sub sp,byte +0x2
    mov ax,[bp+0x6]
    cmp ax,200
    jz .highestLevelKey
    jg .label0
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
.label0: ; 1908
    sub ax,201
    jz .currentLevelKey
    dec ax ; 202
    jz .currentScoreKey
    dec ax ; 203
    jz .numMidiFilesKey
    jmp short .end
    nop
    ;;
.midiKey: ; 1916
    mov bx,[bp+0x8]
    or bx,bx
    jz .skip_midi_default
    mov word [bx],MusicEnabledDefault
.skip_midi_default: ; 1921
    mov ax,MIDIKey
    jmp short .set_dx_and_return
    ;;
.soundsKey: ; 1926
    mov bx,[bp+0x8]
    or bx,bx
    jz .skip_sounds_default
    mov word [bx],SoundEnabledDefault
.skip_sounds_default: ; 1931
    mov ax,SoundsKey
    jmp short .set_dx_and_return
    ;;
.colorKey: ; 1936
    mov bx,[bp+0x8]
    or bx,bx
    jz .skip_color_default
    mov word [bx],ColorDefault
.skip_color_default: ; 1941
    mov ax,ColorKey
    jmp short .set_dx_and_return
    ;;
.highestLevelKey: ; 1946
    mov bx,[bp+0x8]
    or bx,bx
    jz .skip_highestLevel_default
    mov word [bx],FirstLevel
.skip_highestLevel_default: ; 1951
    mov ax,HighestLevelKey
    jmp short .set_dx_and_return
    ;;
.currentLevelKey: ; 1956
    mov bx,[bp+0x8]
    or bx,bx
    jz .skip_currentLevel_default
    mov word [bx],FirstLevel
.skip_currentLevel_default: ; 1961
    mov ax,CurrentLevelKey
    jmp short .set_dx_and_return
    ;;
.currentScoreKey: ; 1966
    mov bx,[bp+0x8]
    or bx,bx
    jz .skip_currentScore_default
    mov word [bx],0x0
.skip_currentScore_default:
    mov ax,CurrentScoreKey
    jmp short .set_dx_and_return
    ;;
.numMidiFilesKey: ; 1976
    mov bx,[bp+0x8]
    or bx,bx
    jz .skip_numMidiFiles_default
    mov word [bx],NumMidiFilesDefault
.skip_numMidiFiles_default: ; 1981
    mov ax,NumMidiFilesKey ; "Number of Midi Files"
.set_dx_and_return: ; 1984
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
    call 0x12f5:GetIniKey ; 19a3 2:18de
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
    call 0x0:0xffff ; 19bd KERNEL.GetPrivateProfileInt
    pop si
endfunc

; 19ca

; StoreIniInt(int id, int value)
func StoreIniInt
    sub sp,byte +0x16
    push si
    push byte +0x0
    push word [bp+0x6]
    call 0x1a34:GetIniKey ; 19dd 2:18de
    add sp,byte +0x4
    mov si,ax
    mov [bp-0x4],dx
    push word [bp+0x8]
    push ds
    push word s_5dd ; "%d"
    lea ax,[bp-0x16]
    push ss
    push ax
    call 0x0:0x1a4e ; 19f6 USER._wsprintf
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
    call 0x0:0x1acf ; 1a0f KERNEL.WritePrivateProfileString
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
    call 0x1a9c:GetIniKey ; 1a31 2:18de
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
    call 0x0:0x1ab6 ; 1a4d USER._wsprintf
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
    call 0x0:0x1b18 ; 1a6d KERNEL.GetPrivateProfileString
    lea ax,[bp-0x28]
    push ax
    call 0x1ba2:0xc0 ; 1a76 1:c0 atol
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
    call 0x1698:GetIniKey ; 1a99 2:18de
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
    call 0x0:0x1af8 ; 1ab5 USER._wsprintf
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
    call 0x0:0x1c94 ; 1ace KERNEL.WritePrivateProfileString
    pop si
endfunc

; 1adc

; GetLevelProgress
FUN_2_1adc:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x24
    push di
    push si
    push word [bp+0x6]
    push ds
    push word s_5e8 ; "Level%d"
    lea ax,[bp-0x10]
    push ss
    push ax
    call 0x0:0x1c3a ; 1af7 USER._wsprintf
    add sp,byte +0xa
    push ds
    push word IniSectionName
    lea ax,[bp-0x10]
    push ss
    push ax
    push ds
    push word 0x2c4 ; ""
    lea ax,[bp-0x24]
    push ss
    push ax
    push byte +0x13
    push ds
    push word IniFileName
    call 0x0:0x1cee ; 1b17 KERNEL.GetPrivateProfileString
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
    call 0x0:0x1d82 ; 1b53 KERNEL.lstrcpy
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
    jc .label6 ; ↓
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
    call 0x1bba:0xbc ; 1b9f 1:bc atoi
    add sp,byte +0x2
    or ax,ax
    jnl .label9 ; ↓
    mov bx,[bp+0xa]
    mov word [bx],0x0
    jmp short .label10 ; ↓
.label9: ; 1bb4
    push word [bp-0x4]
    call 0x1bed:0xbc ; 1bb7 1:bc atoi
    add sp,byte +0x2
    mov bx,[bp+0xa]
    mov [bx],ax
.label10: ; 1bc4
    inc si
    cmp si,[bp-0x6]
    jnc .label14 ; ↓
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
    call 0x1c06:0xc0 ; 1bea 1:c0 atol
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
    call 0x937:0xc0 ; 1c03 1:c0 atol
    add sp,byte +0x2
    mov [di],ax
    mov [di+0x2],dx
.label14: ; 1c10
    mov ax,0x1
.label15: ; 1c13
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 1c1c

; SaveLevelProgress
;
; Writes a level password to the ini file,
; and (optionally) a completion time and score.
FUN_2_1c1c:
    mov ax,ds
    nop
    inc bp
    push bp
    mov bp,sp
    push ds
    mov ds,ax
    sub sp,byte +0x4c
    push si
    mov si,[bp+0x8]
    push word [bp+0x6]
    push ds
    push word s_5f0 ; "Level%d"
    lea ax,[bp-0xc]
    push ss
    push ax
    call 0x0:0x1c5e ; 1c39 USER._wsprintf
    add sp,byte +0xa
    or si,si
    jl .label0 ; ↓
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
    call 0x0:0x1c7a ; 1c5d USER._wsprintf
    add sp,byte +0x12
    jmp short .label1 ; ↓
    nop
.label0: ; 1c68
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
    call 0x0:0x1cce ; 1c79 USER._wsprintf
    add sp,byte +0xc
.label1: ; 1c81
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
    call 0x0:0xffff ; 1c93 KERNEL.WritePrivateProfileString
    pop si
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

; 1ca0

; get midi or sound effect path
FUN_2_1ca0:
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
    cmp word [bp+0xc],byte +0x0
    jz .label0 ; ↓
    mov si,[bp+0x6]
    mov bx,si
    mov di,[SoundKeyArray+(bx+si)]
    jmp short .label1 ; ↓
.label0: ; 1cc0
    mov si,[bp+0x6]
    push si
    push ds
    push word s_605 ; "MidiFile%d"
    lea ax,[bp-0x16]
    push ss
    push ax
    call 0x0:0x1638 ; 1ccd USER._wsprintf
    add sp,byte +0xa
    lea di,[bp-0x16]
.label1: ; 1cd8
    push ds
    push word IniSectionName
    push ds
    push di
    push ds
    push word s_610 ; "$"
    push ds
    push word [bp+0x8]
    push word [bp+0xa]
    push ds
    push word IniFileName
    call 0x0:0xffff ; 1ced KERNEL.GetPrivateProfileString
    mov bx,[bp+0x8]
    cmp byte [bx],'$'
    jz .label2 ; ↓
    jmp .label9 ; ↓
.label2: ; 1cfd
    mov [bp-0x6],di
    cmp byte [bx+0x1],0x0
    jz .label3 ; ↓
    jmp .label9 ; ↓
.label3: ; 1d09
    cmp word [bp+0xc],byte +0x0
    jnz .label4 ; ↓
    cmp si,byte +0x3
    jl .label4 ; ↓
    mov byte [bx],0x0
    jmp .label9 ; ↓
.label4: ; 1d1a
    cmp word [bp+0xc],byte +0x0
    jz .label5 ; ↓
    push ds
    push bx
    mov bx,[bp+0x6]
    shl bx,1
    push ds
    push word [SoundDefaultArray+bx]
    jmp short .label8 ; ↓
.label5: ; 1d2e
    mov ax,bx
    mov [bp-0x4],ax
    cmp word [bp+0x6],byte +0x2
    jnz .label7 ; ↓
    push ds
    push ax
    mov bx,[bp+0x6]
    shl bx,1
    push ds
    push word [MidiFileDefaultArray+bx]
    call 0x0:0xffff ; 1d45 KERNEL.lstrlen
    sub ax,[bp+0xa]
    neg ax
    dec ax
    push ax
    call 0x0:0xffff ; 1d51 KERNEL.GetWindowsDirectory
    mov si,ax
    or si,si
    jz .label7 ; ↓
    mov bx,[bp-0x4]
    add bx,si
    cmp byte [bx-0x1],'\'
    jz .label6 ; ↓
    mov bx,[bp-0x4]
    mov byte [bx+si],'\'
    inc word [bp-0x4]
.label6: ; 1d70
    add [bp-0x4],si
.label7: ; 1d73
    push ds
    push word [bp-0x4]
    mov bx,[bp+0x6]
    shl bx,1
    push ds
    push word [bx+MidiFileDefaultArray]
.label8: ; 1d81
    call 0x0:0x1431 ; 1d81 KERNEL.lstrcpy
    push ds
    push word IniSectionName
    push ds
    push word [bp-0x6]
    push ds
    push word [bp+0x8]
    push ds
    push word IniFileName
    call 0x0:0x1df9 ; 1d96 KERNEL.WritePrivateProfileString
.label9: ; 1d9b
    push ds
    push word [bp+0x8]
    call 0x0:0x1d46 ; 1d9f KERNEL.lstrlen
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf
    nop

; 1dae

; ResetLevelProgress
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
    call 0x1e0a:GetIniInt ; 1dc3 2:198e
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
    call 0x0:0x19f7 ; 1ddf USER._wsprintf
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
    call 0x0:0x1a10 ; 1df8 KERNEL.WritePrivateProfileString
    inc si
    cmp si,di
    jng .loop ; ↑
.label1: ; 1e02
    push byte FirstLevel
    push word ID_HighestLevel
    call 0x1e19:StoreIniInt ; 1e07 2:19ca
    add sp,byte +0x4
    push byte +0x0
    push byte +0x0
    push word ID_CurrentScore
    call 0x1e93:StoreIniLong ; 1e16 2:1a86
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

MenuItemCallback:
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
    call 0x0:0xffff ; 1e87 USER.DefWindowProc
    jmp .label43 ; ↓
    nop

.label1: ; 1e90
    call 0x1ea4:PauseGame ; 1e90 2:17da PauseGame
    push word [OurHInstance]
    push word [bp+0x6]
    call 0x0:0xffff ; 1e9c WEP4UTIL.4
.label2: ; 1ea1
    call 0x1fa4:UnpauseGame ; 1ea1 2:1834 UnpauseGame
    jmp .label42 ; ↓
    nop

.label3: ; 1eaa
    mov si,[bp+0x6]
    push si
    push byte +0x0
    call 0x0:0xb17 ; 1eb0 USER.ShowWindow
    push si
    call 0x0:0xc97 ; 1eb6 USER.DestroyWindow
    jmp .label42 ; ↓

.label4: ; 1ebe
    mov word [Var2a],0x1
    push word [OurHInstance]
    push word [bp+0x6]
    push word 0x101
    push ds
    push word s_Contents
.label5: ; 1ed2
    call 0x0:0xffff ; 1ed2 WEP4UTIL.5
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
    and ax,0x8
    push ax
    call 0x0:0x20a0 ; 1ef6 USER.CheckMenuItem
    push word [hwndMain]
    call 0x0:0x20a9 ; 1eff USER.DrawMenuBar
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
    call 0x1f49:0x115c ; 1f2b 4:115c
    add sp,byte +0x4
    or ax,ax
    jnz .label10 ; ↓
    jmp .label42 ; ↓
.label10: ; 1f3a
    push byte +0x0
    mov bx,[GameStatePtr]
    mov ax,[bx+LevelNumber]
    inc ax
.label11: ; 1f45
    push ax
.label12: ; 1f46
    call 0x1f74:0x356 ; 1f46 4:356
.label13: ; 1f4b
    add sp,byte +0x4
    jmp .label42 ; ↓
    nop

.label14: ; 1f52
    mov bx,[GameStatePtr]
    cmp word [bx+LevelNumber],byte +0x1
    jg .label15 ; ↓
    jmp .label42 ; ↓
.label15: ; 1f60
    mov ax,[bx+LevelNumber]
    dec ax
    cmp ax,0x1
    jnl .label16 ; ↓
    mov ax,0x1
.label16: ; 1f6d
    push ax
    push word [bp+0x6]
    call 0x1819:0x115c ; 1f71 4:115c
    add sp,byte +0x4
    or ax,ax
    jnz .label17 ; ↓
    jmp .label42 ; ↓
.label17: ; 1f80
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
    call 0x1fb9:GetIniInt ; 1fa1 2:198e
    add sp,byte +0x2
    dec ax
    jz .label20 ; ↓
    push byte +0x24
    push ds
    push word NewGamePrompt
    push word [hwndMain]
    call 0x1fc9:ShowMessageBox ; 1fb6 2:0 ShowMessageBox
    add sp,byte +0x8
    cmp ax,0x6
    jz .label20 ; ↓
    jmp .label42 ; ↓
.label20: ; 1fc6
    call 0x1fdd:FUN_2_1dae ; 1fc6 2:1dae
    sub ax,ax
    mov [TotalScore+2],ax
    mov [TotalScore],ax
    push ax
    push byte FirstLevel
    jmp .label12 ; ↑
    nop

.label21: ; 1fda
    call 0x201e:PauseGame ; 1fda 2:17da PauseGame
    push word 0x20ca ; 1fdd 6:18e BESTTIMESMSGPROC
    push word 0x18e
    push word [OurHInstance]
    call 0x0:0x20d4 ; 1fe9 KERNEL.MakeProcInstance
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
    call 0x0:0x20fc ; 2005 USER.DialogBox
    push di
    push si
    call 0x0:0x2107 ; 200c KERNEL.FreeProcInstance
    jmp .label2 ; ↑

.label22: ; 2014
    cmp word [GamePaused],byte +0x0
    jz .label23 ; ↓
    call 0x2027:UnpauseMusic ; 201b 2:18b6 UnpauseMusic
    jmp .label2 ; ↑
    nop
.label23: ; 2024
    call 0x202c:PauseMusic ; 2024 2:189c PauseMusic
    call 0x2063:PauseGame ; 2029 2:17da PauseGame
    jmp .label42 ; ↓
    nop

.label24: ; 2032
    cmp word [MusicEnabled],byte +0x1
    sbb ax,ax
    neg ax
    mov [MusicEnabled],ax
    or ax,ax
    jnz .label25 ; ↓
    call 0x2055:0x2d4 ; 2042 8:2d4
    jmp short .label26 ; ↓
    nop
.label25: ; 204a
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    call 0x20be:0x308 ; 2052 8:308
    add sp,byte +0x2
.label26: ; 205a
    push word [MusicEnabled]
    push byte ID_BGM
    call 0x2088:StoreIniInt ; 2060 2:19ca
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
    call 0x20c7:StoreIniInt ; 2085 2:19ca
    add sp,byte +0x4
    push word [hMenu]
    push byte ID_SOUND
    cmp word [SoundEnabled],byte +0x1
    cmc
    sbb ax,ax
    and ax,0x8
    push ax
    call 0x0:0x1806 ; 209f USER.CheckMenuItem
    push word [hwndMain]
    call 0x0:0x1869 ; 20a8 USER.DrawMenuBar
    cmp word [SoundEnabled],byte +0x0
    jnz .label28 ; ↓
    jmp .label42 ; ↓
.label28: ; 20b7
    push byte +0x1
    push byte +0x7
    call 0x18ac:0x56c ; 20bb 8:56c PlaySoundEffect
    jmp .label13 ; ↑
    nop

.label29: ; 20c4
    call 0x210e:PauseGame ; 20c4 2:17da PauseGame
    push word 0xffff ; 20c7 6:0 GOTOLEVELMSGPROC
    push word 0x0
    push word [OurHInstance]
    call 0x0:0xffff ; 20d3 KERNEL.MakeProcInstance
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
    call 0x0:0xffff ; 20fb USER.DialogBox
    push word [bp-0xa]
    push word [bp-0xc]
    call 0x0:0xffff ; 2106 KERNEL.FreeProcInstance
    call 0x19e0:UnpauseGame ; 210b 2:1834 UnpauseGame
    mov bx,[GameStatePtr]
    mov ax,[bx+LevelNumber]
    mov [bp-0x4],ax
    mov [bx+LevelNumber],di
    cmp di,[bp-0x4]
    jnz .label30 ; ↓
    jmp .label42 ; ↓
.label30: ; 2127
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
    call 0x0:0x7b1 ; 216d USER.LoadCursor
    mov si,ax
    push word [hwndMain]
    call 0x0:0xffff ; 2178 USER.SetCapture
    push si
    call 0x0:0x2247 ; 217e USER.SetCursor
    mov di,ax
    cmp word [ColorMode],byte +0x1
    jz .label34 ; ↓
    mov word [ColorMode],0x1
    jmp short .label35 ; ↓
.label34: ; 2194
    push byte +0x0
    call 0x21ab:0x0 ; 2196 5:0 InitGraphics
    add sp,byte +0x2
.label35: ; 219e
    push byte +0x1
    lea ax,[bp-0x6]
    push ax
    push word [OurHInstance]
    call 0x22e2:0x112 ; 21a8 5:112 LoadTiles
    add sp,byte +0x6
    or ax,ax
    jz .label36 ; ↓
    push word [0x1734]
    push word [bp-0x6]
    call 0x0:0x2323 ; 21bb GDI.SelectObject
    push ax
    call 0x0:0x2428 ; 21c1 GDI.DeleteObject
    mov ax,[bp-0x6]
    mov [0x172c],ax
    push word [hwndBoard]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0x21e6 ; 21d6 USER.InvalidateRect
    push word [hwndInventory]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0x21fc ; 21e5 USER.InvalidateRect
    cmp word [hwndHint],byte +0x0
    jz .label37 ; ↓
    push word [hwndHint]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0x1829 ; 21fb USER.InvalidateRect
    jmp short .label37 ; ↓
.label36: ; 2202
    mov ax,[bp-0x4]
    mov [ColorMode],ax
.label37: ; 2208
    cmp word [ColorMode],byte +0x1
    jz .label38 ; ↓
    mov ax,0x1
    jmp short .label39 ; ↓
.label38: ; 2214
    xor ax,ax
.label39: ; 2216
    push ax
    push byte ID_COLOR
    call 0x2339:StoreIniInt ; 2219 2:19ca
    add sp,byte +0x4
    push word [hMenu]
    push byte ID_COLOR
    cmp word [ColorMode],byte +0x1
    jz .label40 ; ↓
    mov ax,0x8
    jmp short .label41 ; ↓
    nop
.label40: ; 2234
    xor ax,ax
.label41: ; 2236
    push ax
    call 0x0:0x236b ; 2237 USER.CheckMenuItem
    push word [hwndMain]
    call 0x0:0x23b2 ; 2240 USER.DrawMenuBar
    push di
    call 0x0:0xffff ; 2246 USER.SetCursor
    call 0x0:0xffff ; 224b USER.ReleaseCapture

.label42: ; 2250
    xor ax,ax
    cwd
.label43: ; 2253
    pop si
    pop di
    lea sp,[bp-0x2]
    pop ds
    pop bp
    dec bp
    retf

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
    mov ax,[uMsg]
    cmp ax,0x1c ; WM_SHOWWINDOW
    jnz .label0 ; ↓
    jmp .label27 ; ↓
.label0: ; 2276
    ja .label5 ; ↓
    cmp ax,0x1a ; WM_WININICHANGE
    jnz .label1 ; ↓
    jmp .label23 ; ↓
.label1: ; 2280
    jna .label2 ; ↓
    jmp .label68 ; ↓
.label2: ; 2285
    dec al ; WM_CREATE
    jz .label10 ; ↓
    dec al ; WM_DESTROY
    jnz .label3 ; ↓
    jmp .label18 ; ↓
.label3: ; 2290
    sub al,0xf-2 ; WM_PAINT
    jnz .label4 ; ↓
    jmp .label22 ; ↓
.label4: ; 2297
    jmp .label68 ; ↓
.label5: ; 229a
    sub ax,0x100 ; WM_KEYDOWN
    jnz .label6 ; ↓
    jmp .label33 ; ↓
.label6: ; 22a2
    sub ax,0x111-0x100 ; WM_COMMAND
    jnz .label7 ; ↓
    jmp .label62 ; ↓
.label7: ; 22aa
    dec ax ; WM_SYSCOMMAND
    jnz .label8 ; ↓
    jmp .label63 ; ↓
.label8: ; 22b0
    sub ax,0x2a7 ; MM_MCINOTIFY
    jnz .label9 ; ↓
    jmp .label66 ; ↓
.label9: ; 22b8
    jmp .label68 ; ↓
    nop
.label10: ; 22bc
    push word [OurHInstance]
    push ds
    push word s_ChipsMenu2
    call 0x0:0xffff ; 22c4 USER.LoadAccelerators
    mov [hAccel],ax
    or ax,ax
    jnz .label11 ; ↓
    jmp .label15 ; ↓
.label11: ; 22d3
    mov si,[hwnd]
    push byte +0x0
    push word 0x172c
    push word [OurHInstance]
    call 0x243d:0x112 ; 22df 5:112 LoadTiles
    add sp,byte +0x6
    or ax,ax
    jnz .label12 ; ↓
    jmp .label16 ; ↓
.label12: ; 22ee
    mov si,[hwnd]
    push si
    call 0x0:0xffff ; 22f2 USER.GetDC
    mov di,ax
    or di,di
    jnz .label13 ; ↓
    jmp .label16 ; ↓
.label13: ; 2300
    push di
    call 0x0:0xffff ; 2301 GDI.CreateCompatibleDC
    mov [0x1734],ax
    push si
    push di
    call 0x0:0xffff ; 230b USER.ReleaseDC
    cmp word [0x1734],byte +0x0
    jnz .label14 ; ↓
    jmp .label16 ; ↓
.label14: ; 231a
    push word [0x1734]
    push word [0x172c]
    call 0x0:0x241f ; 2322 GDI.SelectObject
    mov [0x1724],ax
    push byte +0x1
    call 0x23fb:0x320 ; 232c 4:320
    add sp,byte +0x2
    push byte ID_BGM
    call 0x2346:GetIniInt ; 2336 2:198e
    add sp,byte +0x2
    mov [MusicEnabled],ax
    push byte ID_SOUND
    call 0x23db:GetIniInt ; 2343 2:198e
    add sp,byte +0x2
    mov [SoundEnabled],ax
    call 0x2356:0x0 ; 234e 8:0 InitSound
    call 0x23e3:0x4a0 ; 2353 8:4a0
    push word [hMenu]
    push byte ID_BGM
    cmp word [MusicEnabled],byte +0x1
    cmc
    sbb ax,ax
    and ax,0x8
    push ax
    call 0x0:0x2382 ; 236a USER.CheckMenuItem
    push word [hMenu]
    push byte ID_SOUND
    cmp word [SoundEnabled],byte +0x1
    cmc
    sbb ax,ax
    and ax,0x8
    push ax
    call 0x0:0x1ef7 ; 2381 USER.CheckMenuItem
    push word [hMenu]
    push byte ID_BGM
    cmp word [MusicMenuItemEnabled],byte +0x1
    sbb ax,ax
    neg ax
    push ax
    call 0x0:0x23ac ; 2396 USER.EnableMenuItem
    push word [hMenu]
    push byte ID_SOUND
    cmp word [SoundMenuItemEnabled],byte +0x1
    sbb ax,ax
    neg ax
    push ax
    call 0x0:0xffff ; 23ab USER.EnableMenuItem
    push si
    call 0x0:0x1f00 ; 23b1 USER.DrawMenuBar
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
    call 0x0:0x64 ; 23c9 USER.MessageBox
    mov ax,0xffff
.label17: ; 23d1
    cwd
    jmp .label69 ; ↓
    nop
.label18: ; 23d6
    push byte +0x1
    call 0x23f3:FUN_2_176e ; 23d8 2:176e
    add sp,byte +0x2
    call 0x2442:0x2d4 ; 23e0 8:2d4
    mov bx,[GameStatePtr]
    push word [bx+LevelNumber]
    push word ID_CurrentLevel
    call 0x2492:StoreIniInt ; 23f0 2:19ca
    add sp,byte +0x4
    call 0x1f2e:0x240 ; 23f8 4:240 FreeGameLists
    cmp word [Var2a],byte +0x0
    jz .label19 ; ↓
    push word [OurHInstance]
    push word [hwnd]
    push byte +0x2
    push byte +0x0
    push byte +0x0
    call 0x0:0x1ed3 ; 2411 WEP4UTIL.5
.label19: ; 2416
    push word [0x1734]
    push word [0x1724]
    call 0x0:0x16e6 ; 241e GDI.SelectObject
    push word [0x172c]
    call 0x0:0x16ec ; 2427 GDI.DeleteObject
    call 0xffff:0xbc ; 242c 9:bc
    push word [0x1734]
    call 0x0:0xffff ; 2435 GDI.DeleteDC
    call 0x941:0x17c ; 243a 5:17c
    call 0x2447:0x5b8 ; 243f 8:5b8
    call 0x2045:0xe6 ; 2444 8:e6 TeardownSound
    cmp word [IsWin31],byte +0x0
    jz .label20 ; ↓
    push byte +0x17     ; uiAction = SPI_SETKEYBOARDDELAY
    push word [KeyboardDelay]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0x24d9 ; 245c USER.SystemParametersInfo
.label20: ; 2461
    cmp word [0x1722],byte +0x0
    jz .label21 ; ↓
    push word [0x1722]
    call 0x0:0xffff ; 246c KERNEL.LocalFree
.label21: ; 2471
    push byte +0x0
    call 0x0:0xffff ; 2473 USER.PostQuitMessage
    jmp .label67 ; ↓
    nop
.label22: ; 247c
    mov si,[hwnd]
    push si
    lea ax,[bp-0x26]
    push ss
    push ax
    call 0x0:0xffff ; 2485 USER.BeginPaint
    lea ax,[bp-0x26]
    push ax
    push si
    call 0x1dc6:FUN_2_0dc6 ; 248f 2:dc6
    add sp,byte +0x4
    push si
    lea ax,[bp-0x26]
    push ss
    push ax
    call 0x0:0xffff ; 249d USER.EndPaint
    jmp .label67 ; ↓
    nop
.label23: ; 24a6
    cmp word [IsWin31],byte +0x0
    jnz .label24 ; ↓
    jmp .label67 ; ↓
.label24: ; 24b0
    push ds
    push word s_KeyboardDelay
    push word [lParam+2]
    push word [lParam]
    call 0x0:0xffff ; 24ba USER.lstrcmpi
    or ax,ax
    jz .label25 ; ↓
    mov ax,[lParam+2]
    or ax,[lParam]
    jz .label25 ; ↓
    jmp .label67 ; ↓
.label25: ; 24ce
    push byte +0x16     ; uiAction = SPI_GETKEYBOARDDELAY
    push byte +0x0      ; uiParam
    push ds
    push word KeyboardDelay ; pvParam
.label26: ; 24d6
    push byte +0x0      ; fWinIni
    call 0x0:0xffff ; 24d8 USER.SystemParametersInfo
    jmp .label67 ; ↓
.label27: ; 24e0
    cmp word [Var2c],byte +0x0
    jz .label29 ; ↓
    push word [hwnd]
    call 0x0:0xffff ; 24ea USER.IsIconic
    or ax,ax
    jnz .label29 ; ↓
    cmp [wParam],ax
    jnz .label28 ; ↓
    call 0x2500:PauseMusic ; 24f8 2:189c PauseMusic
    call 0x2507:PauseGame ; 24fd 2:17da PauseGame
    jmp short .label29 ; ↓
.label28: ; 2504
    call 0x250c:UnpauseMusic ; 2504 2:18b6 UnpauseMusic
    call 0x256c:UnpauseGame ; 2509 2:1834 UnpauseGame
.label29: ; 250e
    cmp word [IsWin31],byte +0x0
    jnz .label30 ; ↓
    jmp .label67 ; ↓
.label30: ; 2518
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
    call 0x0:0x245d ; 2534 USER.SystemParametersInfo
    push byte +0x17
    push byte +0x0
    jmp short .label31 ; ↑
    nop
.label33: ; 2540
    mov bx,[GameStatePtr]
    cmp word [bx+IsLevelPlacardVisible],byte +0x0
    jz .label34 ; ↓
    mov word [bx+IsLevelPlacardVisible],0x0
    push word [hwndBoard]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0x2806 ; 255b USER.InvalidateRect
    push word [hwndBoard]
    call 0x0:0x280f ; 2564 USER.UpdateWindow
    call 0x26dc:UnpauseTimer ; 2569 2:17ba
.label34: ; 256e
    mov ax,[wParam]
    cmp ax,0x74
    jnz .label35 ; ↓
    jmp .label54 ; ↓
.label35: ; 2579
    jna .label36 ; ↓
    jmp .label67 ; ↓
.label36: ; 257e
    cmp al,0x28
    jz .label47 ; ↓
    ja .label37 ; ↓
    sub al,0x1b
    jz .label42 ; ↓
    sub al,0xa
    jz .label43 ; ↓
    dec al
    jz .label45 ; ↓
    dec al
    jz .label46 ; ↓
    jmp .label67 ; ↓
    nop
.label37: ; 2598
    sub al,0x44
    jnz .label38 ; ↓
    jmp .label50 ; ↓
.label38: ; 259f
    sub al,0x7
    jnz .label39 ; ↓
    jmp .label52 ; ↓
.label39: ; 25a6
    sub al,0x9
    jnz .label40 ; ↓
    jmp .label54 ; ↓
.label40: ; 25ad
    sub al,0x10
    jz .label50 ; ↓
    sub al,0x7
    jnz .label41 ; ↓
    jmp .label52 ; ↓
.label41: ; 25b8
    jmp .label67 ; ↓
    nop

.label42: ; 25bc
    push word [hwnd]
    push word 0x112
    push word 0xf020
    push byte +0x0
    push byte +0x0
    call 0x0:0x1759 ; 25c9 USER.PostMessage
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
    call 0x0:0x22f3 ; 2600 USER.GetDC
    mov si,ax
    or si,si
    jnz .label49 ; ↓
    jmp .label67 ; ↓
.label49: ; 260e
    push byte +0x1
    push byte +0x1
    push word [bp-0x6]
    push word [bp-0x4]
    push si
    call 0x27d3:0x1184 ; 2619 7:1184 MoveChip
    add sp,byte +0xa
    push word [hwndBoard]
    push si
    call 0x0:0x230c ; 2626 USER.ReleaseDC
    jmp .label67 ; ↓

.label50: ; 262e
    push byte VK_CONTROL
    call 0x0:0x2647 ; 2630 USER.GetKeyState
    or ax,ax
    jl .label51 ; ↓
    jmp .label67 ; ↓
.label51: ; 263c
    or byte [CheatKeys],0x2
    jmp short .label56 ; ↓
    nop
.label52: ; 2644
    push byte VK_CONTROL
    call 0x0:0x265d ; 2646 USER.GetKeyState
    or ax,ax
    jl .label53 ; ↓
    jmp .label67 ; ↓
.label53: ; 2652
    or byte [CheatKeys],0x4
    jmp short .label56 ; ↓
    nop
.label54: ; 265a
    push byte VK_CONTROL
    call 0x0:0xffff ; 265c USER.GetKeyState
    or ax,ax
    jl .label55 ; ↓
    jmp .label67 ; ↓
.label55: ; 2668
    or byte [CheatKeys],0x1
.label56: ; 266d
    cmp word [CheatKeys],byte +0x1
    jnz .label57 ; ↓
    mov ax,0x1
    jmp short .label58 ; ↓
    nop
.label57: ; 267a
    xor ax,ax
.label58: ; 267c
    or ax,0x6
    jnz .label59 ; ↓
    jmp .label67 ; ↓
.label59: ; 2684
    cmp word [CheatVisible],byte +0x0
    jz .label60 ; ↓
    jmp .label67 ; ↓
.label60: ; 268e
    push word [hMenu]
    push byte +0x0
    call 0x0:0xffff ; 2694 USER.GetSubMenu
    mov si,ax
    or si,si
    jnz .label61 ; ↓
    jmp .label67 ; ↓
.label61: ; 26a2
    push si
    push byte +0x0
    push byte ID_CHEAT
    push ds
    push word CheatMenuText
    call 0x0:0xffff ; 26ab USER.AppendMenu
    mov word [CheatVisible],0x1
    push word [hwnd]
    push word 0x111
    push byte ID_CHEAT
    push byte +0x0
    push byte +0x0
    call 0x0:0xffff ; 26c2 USER.SendMessage
    jmp short .label67 ; ↓
    nop

.label62: ; 26ca
    push word [lParam+2]
    push word [lParam]
    push word [wParam]
    push word [uMsg]
    push word [hwnd]
    call 0x26fd:MenuItemCallback ; 26d9 2:1e28 MenuItemCallback
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
    call 0x2702:PauseMusic ; 26fa 2:189c PauseMusic
    call 0x2715:PauseGame ; 26ff 2:17da PauseGame
    jmp short .label68 ; ↓
.label65: ; 2706
    push word [hwnd]
    call 0x0:0x24eb ; 2709 USER.IsIconic
    or ax,ax
    jz .label68 ; ↓
    call 0x271a:UnpauseMusic ; 2712 2:18b6 UnpauseMusic
    call 0x279c:UnpauseGame ; 2717 2:1834 UnpauseGame
    jmp short .label68 ; ↓

.label66: ; 271e
    mov ax,[wParam]
    dec ax
    jnz .label67 ; ↓
    call 0x2351:0x22a ; 2724 8:22a

.label67: ; 2729
    xor ax,ax
    jmp .label17 ; ↑
.label68: ; 272e
    push word [hwnd]
    push word [uMsg]
    push word [wParam]
    push word [lParam+2]
    push word [lParam]
    call 0x0:0x277e ; 273d USER.DefWindowProc
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
    jz .label1 ; ↓
    sub ax,0xee
    jz .label6 ; ↓
    push word [hwnd]
    push word [uMsg]
    push word [wParam]
    push word [lParam+2]
    push word [lParam]
    call 0x0:0x288d ; 277d USER.DefWindowProc
    jmp .label9 ; ↓
    nop
.label0: ; 2786
    mov si,[hwnd]
    push si
    lea ax,[bp-0x22]
    push ss
    push ax
    call 0x0:0x289d ; 278f USER.BeginPaint
    lea ax,[bp-0x22]
    push ax
    push si
    call 0x2816:FUN_2_10ce ; 2799 2:10ce
    add sp,byte +0x4
    push si
    lea ax,[bp-0x22]
    push ss
    push ax
    call 0x0:0x249e ; 27a7 USER.EndPaint
    jmp .label8 ; ↓
    nop
.label1: ; 27b0
    cmp word [Var22],byte +0x0
    jz .label2 ; ↓
    jmp .label8 ; ↓
.label2: ; 27ba
    mov ax,[wParam]
    dec ax
    jz .label3 ; ↓
    jmp .label8 ; ↓
.label3: ; 27c3
    mov bx,[GameStatePtr]
    cmp word [bx+EndingTick],byte +0x0
    jz .label5 ; ↓
    push byte +0x0
    call 0x27e5:0xa74 ; 27d0 7:a74 EndGame
.label4: ; 27d5
    add sp,byte +0x2
    jmp short .label8 ; ↓
.label5: ; 27da
    inc word [CurrentTick]
    push word [CurrentTick]
    call 0x1236:0x0 ; 27e2 7:0 DoTick
    jmp short .label4 ; ↑
    nop
.label6: ; 27ea
    mov bx,[GameStatePtr]
    cmp word [bx+IsLevelPlacardVisible],byte +0x0
    jz .label7 ; ↓
    mov word [bx+IsLevelPlacardVisible],0x0
    push word [hwndBoard]
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call 0x0:0x21d7 ; 2805 USER.InvalidateRect
    push word [hwndBoard]
    call 0x0:0xb20 ; 280e USER.UpdateWindow
    call 0x221c:UnpauseTimer ; 2813 2:17ba
.label7: ; 2818
    mov bx,[GameStatePtr]
    mov word [bx+HaveMouseTarget],0x1
    mov ax,[lParam]
    shr ax,byte TileShift
    mov bx,[GameStatePtr]
    add ax,[bx+ViewportX]
    add ax,[bx+UnusedOffsetX]
    mov [bx+MouseTargetX],ax
    mov ax,[lParam+2]
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
    sub ax,0xf
    jz .label0 ; ↓
    push word [hwnd]
    push word [uMsg]
    push word [wParam]
    push word [lParam+2]
    push word [lParam]
    call 0x0:0x1e88 ; 288c USER.DefWindowProc
    jmp .label6 ; ↓
.label0: ; 2894
    push word [hwnd]
    lea ax,[bp-0x24]
    push ss
    push ax
    call 0x0:0x2486 ; 289c USER.BeginPaint
    push word [OurHInstance]
    push ds
    push word s_infownd
    call 0x0:0xdde ; 28a9 USER.LoadBitmap
    mov si,ax
    or si,si
    jz .label1 ; ↓
    push word [0x1734]
    push si
    call 0x0:0x28e5 ; 28b9 GDI.SelectObject
    mov di,ax
    push word [bp-0x24]
    push byte +0x0
    push byte +0x0
    push word 0x9a
    push word 0x12c
    push word [0x1734]
    push byte +0x0
    push byte +0x0
    push word 0xcc
    push byte +0x20
    call 0x0:0xe4c ; 28da GDI.BitBlt
    push word [0x1734]
    push di
    call 0x0:0x2904 ; 28e4 GDI.SelectObject
    push si
    call 0x0:0x21c2 ; 28ea GDI.DeleteObject
    jmp short .label5 ; ↓
    nop
.label1: ; 28f2
    push byte +0x1
    call 0x0:0xf22 ; 28f4 GDI.GetStockObject
    mov si,ax
    or si,si
    jz .label2 ; ↓
    push word [bp-0x24]
    push si
    call 0x0:0x294a ; 2903 GDI.SelectObject
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
    jz .label3 ; ↓
    mov ax,0x21
    mov dx,0xf0
    jmp short .label4 ; ↓
    nop
.label3: ; 2932
    mov ax,0x42
    cwd
.label4: ; 2936
    push dx
    push ax
    call 0x0:0x2c4d ; 2938 GDI.PatBlt
    cmp word [bp-0x26],byte +0x0
    jz .label5 ; ↓
    push word [bp-0x24]
    push word [bp-0x4]
    call 0x0:0x21bc ; 2949 GDI.SelectObject
.label5: ; 294e
    push word [hwnd]
    lea ax,[bp-0x24]
    push ss
    push ax
    call 0x0:0x2a88 ; 2956 USER.EndPaint
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
    push word [lParam+2]
    push word [lParam]
    call 0x0:0x2ac0 ; 2990 USER.DefWindowProc
    jmp .label5 ; ↓
.label0: ; 2998
    mov di,[hwnd]
    push di
    lea ax,[bp-0x36]
    push ss
    push ax
    call 0x0:0x2ad2 ; 29a1 USER.BeginPaint
    push di
    push byte +0x0
    call 0x0:0x29b4 ; 29a9 USER.GetWindowWord
    mov si,ax
    push di
    push byte +0x2
    call 0x0:0xcec ; 29b3 USER.GetWindowWord
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
    call 0x0:0x2c04 ; 2a19 USER.GetClientRect
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
    call 0x2a61:0xea ; 2a43 9:ea DrawDigit
    add sp,byte +0xa
    push word [bp-0xa]
    push word [bp-0x8]
    push word [bp-0x4]
    mov ax,[bp-0x6]
    add ax,0x11
    push ax
    push word [bp-0x36]
    call 0x2a7c:0xea ; 2a5e 9:ea DrawDigit
    add sp,byte +0xa
    push word [bp-0xa]
    push word [bp-0xe]
    push word [bp-0x4]
    mov ax,[bp-0x6]
    add ax,0x22
    push ax
    push word [bp-0x36]
    call 0x242f:0xea ; 2a79 9:ea DrawDigit
    add sp,byte +0xa
    push di
    lea ax,[bp-0x36]
    push ss
    push ax
    call 0x0:0x2bad ; 2a87 USER.EndPaint
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
    push word [lParam+2]
    push word [lParam]
    call 0x0:0x2be6 ; 2abf USER.DefWindowProc
    jmp .label1 ; ↓
    nop
.label0: ; 2ac8
    mov si,[hwnd]
    push si
    lea ax,[bp-0x22]
    push ss
    push ax
    call 0x0:0x2bf7 ; 2ad1 USER.BeginPaint
    cmp word [RedKeyCount],byte +0x1
    cmc
    sbb al,al
    and al,0x65
    push ax
    push byte +0x0
    push byte +0x0
    push word [bp-0x22]
    call 0x2b05:DrawInventoryTile ; 2ae8 2:232 DrawInventoryTile
    add sp,byte +0x8
    cmp word [BlueKeyCount],byte +0x1
    cmc
    sbb al,al
    and al,0x64
    push ax
    push byte +0x0
    push byte TileWidth * 1
    push word [bp-0x22]
    call 0x2b1f:DrawInventoryTile ; 2b02 2:232 DrawInventoryTile
    add sp,byte +0x8
    cmp word [YellowKeyCount],byte +0x1
    cmc
    sbb al,al
    and al,0x67
    push ax
    push byte +0x0
    push byte TileWidth * 2
    push word [bp-0x22]
    call 0x2b39:DrawInventoryTile ; 2b1c 2:232 DrawInventoryTile
    add sp,byte +0x8
    cmp word [GreenKeyCount],byte +0x1
    cmc
    sbb al,al
    and al,0x66
    push ax
    push byte +0x0
    push byte TileWidth * 3
    push word [bp-0x22]
    call 0x2b53:DrawInventoryTile ; 2b36 2:232 DrawInventoryTile
    add sp,byte +0x8
    cmp word [IceSkateCount],byte +0x1
    cmc
    sbb al,al
    and al,0x6a
    push ax
    push byte TileHeight
    push byte +0x0
    push word [bp-0x22]
    call 0x2b6d:DrawInventoryTile ; 2b50 2:232 DrawInventoryTile
    add sp,byte +0x8
    cmp word [SuctionBootCount],byte +0x1
    cmc
    sbb al,al
    and al,0x6b
    push ax
    push byte TileHeight
    push byte TileWidth * 1
    push word [bp-0x22]
    call 0x2b87:DrawInventoryTile ; 2b6a 2:232 DrawInventoryTile
    add sp,byte +0x8
    cmp word [FireBootCount],byte +0x1
    cmc
    sbb al,al
    and al,0x69
    push ax
    push byte TileHeight
    push byte TileWidth * 2
    push word [bp-0x22]
    call 0x2ba1:DrawInventoryTile ; 2b84 2:232 DrawInventoryTile
    add sp,byte +0x8
    cmp word [FlipperCount],byte +0x1
    cmc
    sbb al,al
    and al,0x68
    push ax
    push byte TileHeight
    push byte TileWidth * 3
    push word [bp-0x22]
    call 0x2c2c:DrawInventoryTile ; 2b9e 2:232 DrawInventoryTile
    add sp,byte +0x8
    push si
    lea ax,[bp-0x22]
    push ss
    push ax
    call 0x0:0x27a8 ; 2bac USER.EndPaint
    xor ax,ax
    cwd
.label1: ; 2bb4
    pop si
endfunc

; 2bbe

func HINTWNDPROC
    %assign %$argsize 0xa
    %arg lParam:dword ; +6
    %arg wParam:word ; +a
    %arg uMsg:word ; +c
    %arg hwnd:word ; +e
    sub sp,0xc8
    push di
    push si
    mov ax,[uMsg]
    sub ax,0xf
    jz .label0 ; ↓
    push word [hwnd]
    push word [uMsg]
    push word [wParam]
    push word [lParam+2]
    push word [lParam]
    call 0x0:0x273e ; 2be5 USER.DefWindowProc
    jmp .label11 ; ↓
    nop
.label0: ; 2bee
    push word [hwnd]
    lea ax,[bp-0x48]
    push ss
    push ax
    call 0x0:0x2790 ; 2bf6 USER.BeginPaint
    push word [hwnd]
    lea ax,[bp-0x20]
    push ss
    push ax
    call 0x0:0x10fe ; 2c03 USER.GetClientRect
    lea ax,[bp-0x20]
    push ss
    push ax
    push byte -0x3
    push byte -0x3
    call 0x0:0xedb ; 2c11 USER.InflateRect
    push byte +0x0
    push byte +0x3
    push word [bp-0x1a]
    push word [bp-0x1c]
    push word [bp-0x1e]
    push word [bp-0x20]
    push word [bp-0x48]
    call 0x24fb:FUN_2_0f06 ; 2c29 2:f06
    add sp,byte +0xe
    push word [bp-0x48]
    push word [bp-0x20]
    push word [bp-0x1e]
    mov ax,[bp-0x1c]
    sub ax,[bp-0x20]
    push ax
    mov ax,[bp-0x1a]
    sub ax,[bp-0x1e]
    push ax
    push byte +0x0
    push byte +0x42
    call 0x0:0x134f ; 2c4c GDI.PatBlt
    lea ax,[bp-0x20]
    push ss
    push ax
    push byte -0x1
    push byte -0x1
    call 0x0:0x2c12 ; 2c5a USER.InflateRect
    push word [bp-0x48]
    cmp word [ColorMode],byte +0x1
    jnz .label1 ; ↓
    mov ax,0xffff
    jmp short .label2 ; ↓
.label1: ; 2c6e
    mov ax,0xff00
.label2: ; 2c71
    mov dx,0xff
    push dx
    push ax
    call 0x0:0x2d9d ; 2c76 GDI.SetTextColor
    mov [bp-0x10],ax
    mov [bp-0xe],dx
    push word [bp-0x48]
    push byte +0x0
    push byte +0x0
    call 0x0:0x2dab ; 2c88 GDI.SetBkColor
    mov [bp-0x14],ax
    mov [bp-0x12],dx
    mov ax,[GameStatePtr]
    add ax,LevelHint
    push ds
    push ax
    push ds
    push word s_658 ; "Hint: %s"
    lea ax,[bp-0xc8]
    push ss
    push ax
    call 0x0:0x1de0 ; 2ca5 USER._wsprintf
    add sp,byte +0xc
    mov [bp-0x8],ax
    mov word [bp-0x16],0x0
    mov word [bp-0x6],0xc
.label3: ; 2cba
    mov ax,[bp-0x6]
    neg ax
    push ax
    push word [bp-0x48]
    push byte +0x5a ; LOGPIXELSY
    call 0x0:0x13fb ; 2cc5 GDI.GetDeviceCaps
    push ax
    push byte +0x48
    call 0x0:0x1403 ; 2ccd GDI.MulDiv
    mov [LOGFONT.lfHeight],ax
    mov word [LOGFONT.lfWeight],700
    mov byte [LOGFONT.lfItalic],1
    push ds
    push word LOGFONT.lfFaceName
    cmp word [IsWin31],byte +0x0
    jz .label4 ; ↓
    mov ax,s_Arial3
    jmp short .label5 ; ↓
.label4: ; 2cf0
    mov ax,s_Helv3
.label5: ; 2cf3
    mov si,ax
    mov [bp-0xa],ds
    push ds
    push ax
    call 0x0:0x1b54 ; 2cfa KERNEL.lstrcpy
    push ds
    push word LOGFONT
    call 0x0:0x143a ; 2d03 GDI.CreateFontIndirect
    mov [bp-0x4],ax
    or ax,ax
    jz .label6 ; ↓
    push word [bp-0x48]
    push ax
    call 0x0:0x2d7b ; 2d13 GDI.SelectObject
    mov [bp-0x18],ax
.label6: ; 2d1b
    lea di,[bp-0x28]
    lea si,[bp-0x20]
    mov ax,ss
    mov es,ax
    movsw
    movsw
    movsw
    movsw
    push word [bp-0x48]
    lea ax,[bp-0xc8]
    push ss
    push ax
    push word [bp-0x8]
    lea ax,[bp-0x28]
    push ss
    push ax
    push word 0xc11
    call 0x0:0x2d65 ; 2d3d USER.DrawText
    mov ax,[bp-0x1a]
    cmp [bp-0x22],ax
    jng .label7 ; ↓
    cmp word [bp-0x6],byte +0x6
    jg .label8 ; ↓
.label7: ; 2d50
    push word [bp-0x48]
    lea ax,[bp-0xc8]
    push ss
    push ax
    push word [bp-0x8]
    lea ax,[bp-0x20]
    push ss
    push ax
    push word 0x811
    call 0x0:0x1656 ; 2d64 USER.DrawText
    mov word [bp-0x16],0x1
.label8: ; 2d6e
    cmp word [bp-0x4],byte +0x0
    jz .label9 ; ↓
    push word [bp-0x48]
    push word [bp-0x18]
    call 0x0:0x28ba ; 2d7a GDI.SelectObject
    push word [bp-0x4]
    call 0x0:0x28eb ; 2d82 GDI.DeleteObject
.label9: ; 2d87
    dec word [bp-0x6]
    cmp word [bp-0x16],byte +0x0
    jnz .label10 ; ↓
    jmp .label3 ; ↑
.label10: ; 2d93
    push word [bp-0x48]
    push word [bp-0xe]
    push word [bp-0x10]
    call 0x0:0x13d9 ; 2d9c GDI.SetTextColor
    push word [bp-0x48]
    push word [bp-0x12]
    push word [bp-0x14]
    call 0x0:0x16c5 ; 2daa GDI.SetBkColor
    push word [hwnd]
    lea ax,[bp-0x48]
    push ss
    push ax
    call 0x0:0x2957 ; 2db7 USER.EndPaint
    xor ax,ax
    cwd
.label11: ; 2dbf
    pop si
    pop di
endfunc

; 2dc7

; vim: syntax=nasm

SEGMENT CODE ; 8

; Sound & music

%include "constants.asm"
;%include "structs.asm"
%include "variables.asm"
%include "func.mac"

; 0

%define SEM_NOOPENFILEERRORBOX 0x8000

func InitSound
    sub sp,byte +0x2
    push si
    ; Tell OpenFile not to display an error message on file not found
    push word SEM_NOOPENFILEERRORBOX
    call 0x0:0xd1 ; 11 KERNEL.SetErrorMode
    mov si,ax
    ; Load MMSYSTEM.DLL
    push ds
    push word s_MMSYSTEM_DLL
    call 0x0:0xffff ; 1c KERNEL.LoadLibrary
    mov [hmoduleMMSystem],ax
    cmp ax,0x20
    ja .loadedMMSystem ; ↓
    jmp .failedToLoadLibrary ; ↓
.loadedMMSystem: ; 2c
    ; Look up a bunch of functions from the library
    push ax
    push ds
    push word s_sndPlaySound
    call 0x0:0x46 ; 31 KERNEL.GetProcAddress
    mov [fpSndPlaySound],ax
    mov [fpSndPlaySound+2],dx
    push word [hmoduleMMSystem]
    push ds
    push word s_mciSendCommand
    call 0x0:0x5a ; 45 KERNEL.GetProcAddress
    mov [fpMciSendCommand],ax
    mov [fpMciSendCommand+2],dx
    push word [hmoduleMMSystem]
    push ds
    push word s_mciGetErrorString
    call 0x0:0x6e ; 59 KERNEL.GetProcAddress
    mov [fpMciGetErrorString],ax
    mov [fpMciGetErrorString+2],dx
    push word [hmoduleMMSystem]
    push ds
    push word s_midiOutGetNumDevs
    call 0x0:0x82 ; 6d KERNEL.GetProcAddress
    mov [fpMidiOutGetNumDevs],ax
    mov [fpMidiOutGetNumDevs+2],dx
    push word [hmoduleMMSystem]
    push ds
    push word s_waveOutGetNumDevs
    call 0x0:0xffff ; 81 KERNEL.GetProcAddress
    mov [fpWaveOutGetNumDevs],ax
    mov [fpWaveOutGetNumDevs+2],dx
    ; Enable (or disable) Background Music menu item if midiOutGetNumDevs() != 0
    call far [fpMidiOutGetNumDevs] ; 8d
    cmp ax,0x1
    sbb ax,ax
    inc ax
    mov [MusicMenuItemEnabled],ax
    ; Enable (or disable) Sound Effects menu item if waveOutGetNumDevs() != 0
    call far [fpWaveOutGetNumDevs] ; 9a
    cmp ax,0x1
    sbb ax,ax
    inc ax
    mov [SoundMenuItemEnabled],ax
    ; If we can't play midi, turn music off
    cmp word [MusicMenuItemEnabled],byte +0x0
    jnz .dontDisableMusic ; ↓
    mov word [MusicEnabled],0x0
.dontDisableMusic: ; b4
    ; if we can't play sounds, turn sound effects off
    or ax,ax
    jnz .done ; ↓
    mov [SoundEnabled],ax
    jmp short .done ; ↓
    nop
.failedToLoadLibrary: ; be
    xor ax,ax
    mov [hmoduleMMSystem],ax
    mov [SoundMenuItemEnabled],ax
    mov [MusicMenuItemEnabled],ax
    mov [SoundEnabled],ax
    mov [MusicEnabled],ax
.done: ; cf
    ; change error mode back
    push si
    call 0x0:0xffff ; d0 KERNEL.SetErrorMode
    ; Return 1 if we loaded the module sucessfully, 0 otherwise
    cmp word [hmoduleMMSystem],byte +0x1
    sbb ax,ax
    inc ax
    pop si
endfunc

; e6

func TeardownSound
    sub sp,byte +0x2
    cmp word [hmoduleMMSystem],byte +0x0
    jz .label0 ; ↓
    push word [hmoduleMMSystem]
    call 0x0:0xffff ; fe KERNEL.FreeLibrary
.label0: ; 103
    mov word [hmoduleMMSystem],0x0
endfunc

; 110

; start midi
func FUN_8_0110
    sub sp,byte +0x5e
    cmp word [bp+0xc],byte +0x0
    jz .label0 ; ↓
    jmp .label5 ; ↓
.label0: ; 126
    mov word [bp-0x56], s_sequencer
    mov [bp-0x54],ds
    mov ax,[bp+0x8]
    mov dx,[bp+0xa]
    mov [bp-0x52],ax
    mov [bp-0x50],dx
    mov word [bp-0x4e],EmptyStringForMciSendCommand
    mov [bp-0x4c],ds
    push byte +0x0
    push word 0x803
    push byte +0x0
    push word 0x2200
    lea ax,[bp-0x5e]
    push ss
    push ax
    call far [fpMciSendCommand] ; 151
    mov [bp-0x6],ax
    mov [bp-0x4],dx
    or dx,ax
    jz .label2 ; ↓
.label1: ; 15f
    mov ax,[bp-0x6]
    mov dx,[bp-0x4]
    jmp .label7 ; ↓
.label2: ; 168
    mov word [bp-0x42],0x4003
    mov word [bp-0x40],0x0
    mov ax,[bp-0x5a]
    mov [0x1736],ax
    push ax
    push word 0x814
    push byte +0x0
    push word 0x100
    lea ax,[bp-0x4a]
    push ss
    push ax
    call far [fpMciSendCommand] ; 186
    mov [bp-0x6],ax
    mov [bp-0x4],dx
    or dx,ax
    jz .label4 ; ↓
.label3: ; 194
    push word [0x1736]
    push word 0x804
    push byte +0x0
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far [fpMciSendCommand] ; 1a3
    mov word [0x13c4],0x0
    jmp short .label1 ; ↑
    nop
.label4: ; 1b0
    cmp word [bp-0x46],byte -0x1
    jz .label5 ; ↓
    push byte +0x4
    push ds
    push word s_The_MIDI_Mapper_is_not_available_Continue?
    push word [hwndMain]
    call 0x2c7:0x0 ; 1c0 2:0 ShowMessageBox
    add sp,byte +0x8
    cmp ax,0x7
    jnz .label5 ; ↓
    push word [0x1736]
    push word 0x804
    push byte +0x0
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far [fpMciSendCommand] ; 1dc
    mov word [0x13c4],0x0
    jmp short .label6 ; ↓
.label5: ; 1e8
    mov word [0x13c4],0x1
    mov ax,[bp+0x6]
    mov [bp-0x3a],ax
    mov [bp-0x38],ds
    sub ax,ax
    mov [bp-0x34],ax
    mov [bp-0x36],ax
    push word [0x1736]
    push word 0x806
    push ax
    push byte +0x5
    lea ax,[bp-0x3a]
    push ss
    push ax
    call far [fpMciSendCommand] ; 20e
    mov [bp-0x6],ax
    mov [bp-0x4],dx
    or dx,ax
    jz .label6 ; ↓
    jmp .label3 ; ↑
.label6: ; 21f
    xor ax,ax
    cwd
.label7: ; 222
endfunc

; 22a

func FUN_8_022a
    sub sp,byte +0x2
    push byte +0x1
    push byte +0x0
    push byte +0x0
    push word [hwndMain]
    call 0x33a:FUN_8_0110 ; 241 8:110
    add sp,byte +0x8
    or dx,ax
    jnz .label0 ; ↓
    mov ax,0x1
    jmp short .label1 ; ↓
.label0: ; 252
    xor ax,ax
.label1: ; 254
endfunc

; 25c

func ShowMIDIError
    sub sp,0x11a
    push si
    push word [bp+0xc] ; filename seg
    push word [bp+0xa] ; filename
    push ds
    push word s_MIDI_Error_on_file_s
    lea ax,[bp-0x11a]
    push ss
    push ax
    call 0x0:0xffff ; 27b USER._wsprintf
    add sp,byte +0xc
    mov ax,[fpMciGetErrorString+2]
    or ax,[fpMciGetErrorString]
    jz .label0 ; ↓
    push word [bp+0x8]
    push word [bp+0x6]
    lea ax,[bp-0x11a]
    push ss
    push ax
    call 0x0:0xffff ; 298 KERNEL.lstrlen
    mov si,ax
    lea ax,[bp+si-0x11b]
    push ss
    push ax
    push word 0x80
    call far [fpMciGetErrorString] ; 2a8
    or ax,ax
    jz .label0 ; ↓
    push byte +0x30
    lea ax,[bp-0x11a]
    push ss
    push ax
    jmp short .label1 ; ↓
.label0: ; 2ba
    push byte +0x30
    push ds
    push word s_Unknown_Error
.label1: ; 2c0
    push word [hwndMain]
    call 0xffff:0x0 ; 2c4 2:0 ShowMessageBox
    add sp,byte +0x8
    pop si
endfunc

; 2d4

; stop music?
func FUN_8_02d4
    sub sp,byte +0x2
    cmp word [0x13c4],byte +0x0
    jz .label0 ; ↓
    push word [0x1736]
    push word 0x804
    push byte +0x0
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far [fpMciSendCommand] ; 2f7
.label0: ; 2fb
    mov word [0x13c4],0x0
endfunc

; 308

; change level
func FUN_8_0308
    sub sp,byte +0x12
    push di
    push si
    ; some preliminary checks
    cmp word [MusicEnabled],byte +0x0
    jnz .musicEnabled ; ↓
    jmp .returnZero ; ↓
.musicEnabled: ; 321
    mov ax,[fpMciSendCommand+2]
    or ax,[fpMciSendCommand]
    jnz .mciSendCommandExists ; ↓
    jmp .returnZero ; ↓
.mciSendCommandExists: ; 32d
    cmp word [NumMIDIFiles],byte +0x0
    jnz .haveSomeMIDIFiles ; ↓
    jmp .returnZero ; ↓
.haveSomeMIDIFiles: ; 337
    call 0x3a9:FUN_8_02d4 ; 337 8:2d4
    mov ax,[bp+0x6] ; level number
    cwd
    idiv word [NumMIDIFiles]
    mov si,dx

.loop: ; 346
    mov ax,[NumMIDIFiles]
    shl ax,1
    add ax,MIDIArray-2
    mov [bp-0x6],ax
.label4: ; 351
    mov bx,si
    cmp word [bx+si+MIDIArray],byte +0x0
    jz .label5 ; ↓
    jmp .label9 ; ↓
.label5: ; 35d
    lea cx,[si+0x1]
    cmp cx,[NumMIDIFiles]
    jnl .label7 ; ↓
    mov [bp-0xc],si
    mov bx,cx
    shl bx,1
    add bx,MIDIArray-2
    mov dx,[NumMIDIFiles]
    sub dx,cx
    mov [bp-0x4],cx
.label6: ; 37a
    mov ax,[bx+0x2]
    mov [bx],ax
    add bx,byte +0x2
    dec dx
    jnz .label6 ; ↑
    mov si,[bp-0xc]
.label7: ; 388
    mov bx,[bp-0x6]
    sub word [bp-0x6],byte +0x2
    mov word [bx],0x0
    dec word [NumMIDIFiles]
    cmp [NumMIDIFiles],si
    jnz .label8 ; ↓
    xor si,si
.label8: ; 39f
    cmp word [NumMIDIFiles],byte +0x0
    jnz .label4 ; ↑
    call 0xffff:FUN_8_02d4 ; 3a6 8:2d4
    push word [hwndMain]
    push word 0x111
    push byte +0x75
    push byte +0x0
    push byte +0x0
    call 0x0:0x482 ; 3b8 USER.SendMessage
    push byte +0x30
    push ds
    push word s_None_of_the_MIDI_files_specified___
    push word [hwndMain]
    call 0x4c5:0x0 ; 3c7 2:0 ShowMessageBox
    add sp,byte +0x8
    push word [hMenu]
    push byte ID_BGM
    push byte +0x1
    call 0x0:0xffff ; 3d7 USER.EnableMenuItem
    jmp .returnZero ; ↓
    nop
.label9: ; 3e0
    shl bx,1
    add bx,MIDIArray
    mov [bp-0x12],bx
    mov ax,[bx]
    mov di,ax
    mov [bp-0xe],ds
    push byte +0x0
    push byte +0x0
    push word 0x7f02 ; hourglass
    call 0x0:0xffff ; 3f7 USER.LoadCursor
    mov [bp-0x8],ax
    push word [hwndMain]
    call 0x0:0xffff ; 403 USER.SetCapture
    push word [bp-0x8]
    call 0x0:0x42f ; 40b USER.SetCursor
    mov [bp-0xa],ax
    push byte +0x0
    push word [bp-0xe]
    push di
    push word [hwndMain]
    call 0x46f:FUN_8_0110 ; 41d 8:110
    add sp,byte +0x8
    mov [bp-0x6],ax
    mov [bp-0x4],dx
    push word [bp-0xa]
    call 0x0:0xffff ; 42e USER.SetCursor
    call 0x0:0xffff ; 433 USER.ReleaseCapture
    mov ax,[bp-0x4]
    or ax,[bp-0x6]
    jz .label11 ; ↓
    cmp word [bp-0x6],0x113
    jnz .break ; ↓
    cmp word [bp-0x4],byte +0x0
    jnz .break ; ↓
    mov bx,[bp-0x12]
    push word [bx]
    call 0x0:0x5e8 ; 452 KERNEL.LocalFree
    mov bx,[bp-0x12]
    mov word [bx],0x0
    jmp .loop ; ↑
    nop

.break: ; 462
    push word [bp-0xe] ; filename
    push di
    push word [bp-0x4]
    push word [bp-0x6]
    call 0x244:ShowMIDIError ; 46c 8:25c
    add sp,byte +0x8
    push word [hwndMain]
    push word 0x111
    push byte +0x75
    push byte +0x0
    push byte +0x0
    call 0x0:0xffff ; 481 USER.SendMessage
.label11: ; 486
    mov ax,[bp-0x4]
    or ax,[bp-0x6]
    jnz .returnZero ; ↓
    mov ax,0x1
    jmp short .label13 ; ↓
    nop
.returnZero: ; 494
    xor ax,ax
.label13: ; 496
    pop si
    pop di
endfunc

; 4a0

func FUN_8_04a0
    sub sp,0x102
    push di
    push si
    xor di,di
    mov si,SoundArray
.label0: ; 4b5
    push byte +0x0
    push byte +0x1
    push word 0x100
    lea ax,[bp-0x102]
    push ax
    push di
    call 0x4f4:0x1ca0 ; 4c2 2:1ca0
    add sp,byte +0x8
    inc ax
    push ax
    call 0x0:0x541 ; 4cc KERNEL.LocalAlloc
    mov [si],ax
    or ax,ax
    jz .label1 ; ↓
    push ds
    push ax
    lea ax,[bp-0x102]
    push ss
    push ax
    call 0x0:0x554 ; 4df KERNEL.lstrcpy
.label1: ; 4e4
    inc di
    add si,byte +0x2
    cmp si,SoundArray.end
    jc .label0 ; ↑
    push word 0xcb
    call 0x50a:0x198e ; 4f1 2:198e
    add sp,byte +0x2
    cmp ax,0x14
    jl .label2 ; ↓
    mov ax,0x14
    jmp short .label3 ; ↓
    nop
.label2: ; 504
    push word 0xcb
    call 0x519:0x198e ; 507 2:198e
    add sp,byte +0x2
.label3: ; 50f
    mov [NumMIDIFiles],ax
    push ax
    push word 0xcb
    call 0x539:0x19ca ; 516 2:19ca
    add sp,byte +0x4
    xor di,di
    cmp [NumMIDIFiles],di
    jng .label6 ; ↓
    mov si,MIDIArray
.label4: ; 529
    push byte +0x0
    push byte +0x0
    push word 0x100
    lea ax,[bp-0x102]
    push ax
    push di
    call 0x1c3:0x1ca0 ; 536 2:1ca0
    add sp,byte +0x8
    inc ax
    push ax
    call 0x0:0xffff ; 540 KERNEL.LocalAlloc
    mov [si],ax
    or ax,ax
    jz .label5 ; ↓
    push ds
    push ax
    lea ax,[bp-0x102]
    push ss
    push ax
    call 0x0:0xffff ; 553 KERNEL.lstrcpy
.label5: ; 558
    add si,byte +0x2
    inc di
    cmp di,[NumMIDIFiles]
    jl .label4 ; ↑
.label6: ; 562
    pop si
    pop di
endfunc

; 56c

func PlaySoundEffect
    sub sp,byte +0x6
    cmp word [SoundEnabled],byte +0x0
    jz .label0 ; ↓
    mov ax,[fpSndPlaySound+2]
    or ax,[fpSndPlaySound]
    jz .label0 ; ↓
    mov bx,[bp+0x6]
    shl bx,1
    mov ax,[SoundArray+bx]
    mov dx,ds
    mov cx,ax
    mov [bp-0x4],dx
    or dx,ax
    jz .label0 ; ↓
    push word [bp-0x4]
    push cx
    cmp word [bp+0x8],byte +0x1
    sbb ax,ax
    and ax,0x10
    or al,0x3
    push ax
    call far [fpSndPlaySound] ; 5ad
.label0: ; 5b1
endfunc

; 5b8

func FUN_8_05b8
    sub sp,byte +0x4
    push di
    push si
    mov ax,[fpSndPlaySound+2]
    or ax,[fpSndPlaySound]
    jz .label0 ; ↓
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far [fpSndPlaySound] ; 5d6
.label0: ; 5da
    mov si,SoundArray
    mov di,[bp-0x4]
.label1: ; 5e0
    cmp word [si],byte +0x0
    jz .label2 ; ↓
    push word [si]
    call 0x0:0x608 ; 5e7 KERNEL.LocalFree
.label2: ; 5ec
    add si,byte +0x2
    cmp si,SoundArray.end
    jc .label1 ; ↑
    xor di,di
    cmp [NumMIDIFiles],di
    jng .label5 ; ↓
    mov si,MIDIArray
.label3: ; 600
    cmp word [si],byte +0x0
    jz .label4 ; ↓
    push word [si]
    call 0x0:0xffff ; 607 KERNEL.LocalFree
.label4: ; 60c
    add si,byte +0x2
    inc di
    cmp di,[NumMIDIFiles]
    jl .label3 ; ↑
.label5: ; 616
    pop si
    pop di
endfunc

; 620

; vim: syntax=nasm

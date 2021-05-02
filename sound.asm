SEGMENT CODE ; 8

; Sound & music

%include "base.inc"
%include "constants.asm"
;%include "structs.asm"
%include "variables.asm"
%include "func.mac"

%include "extern.inc"
%include "windows.inc"

; 0

%define SEM_NOOPENFILEERRORBOX 0x8000

func InitSound
    sub sp,byte +0x2
    push si
    ; Tell OpenFile not to display an error message on file not found
    push word SEM_NOOPENFILEERRORBOX
    call far KERNEL.SetErrorMode ; 11
    mov si,ax
    ; Load MMSYSTEM.DLL
    push ds
    push word s_MMSYSTEM_DLL
    call far KERNEL.LoadLibrary ; 1c
    mov [hmoduleMMSystem],ax
    cmp ax,0x20
    ja .loadedMMSystem ; ↓
    jmp .failedToLoadLibrary ; ↓
.loadedMMSystem: ; 2c
    ; Look up a bunch of functions from the library
    push ax
    push ds
    push word s_sndPlaySound
    call far KERNEL.GetProcAddress ; 31
    mov [fpSndPlaySound+FarPtr.Off],ax
    mov [fpSndPlaySound+FarPtr.Seg],dx
    push word [hmoduleMMSystem]
    push ds
    push word s_mciSendCommand
    call far KERNEL.GetProcAddress ; 45
    mov [fpMciSendCommand+FarPtr.Off],ax
    mov [fpMciSendCommand+FarPtr.Seg],dx
    push word [hmoduleMMSystem]
    push ds
    push word s_mciGetErrorString
    call far KERNEL.GetProcAddress ; 59
    mov [fpMciGetErrorString+FarPtr.Off],ax
    mov [fpMciGetErrorString+FarPtr.Seg],dx
    push word [hmoduleMMSystem]
    push ds
    push word s_midiOutGetNumDevs
    call far KERNEL.GetProcAddress ; 6d
    mov [fpMidiOutGetNumDevs+FarPtr.Off],ax
    mov [fpMidiOutGetNumDevs+FarPtr.Seg],dx
    push word [hmoduleMMSystem]
    push ds
    push word s_waveOutGetNumDevs
    call far KERNEL.GetProcAddress ; 81
    mov [fpWaveOutGetNumDevs+FarPtr.Off],ax
    mov [fpWaveOutGetNumDevs+FarPtr.Seg],dx
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
    call far KERNEL.SetErrorMode ; d0
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
    call far KERNEL.FreeLibrary ; fe
.label0: ; 103
    mov word [hmoduleMMSystem],0x0
endfunc

; 110

; start midi
func StartMIDI
    %arg hWnd:word
    %arg filename:dword
    %arg param_c:word
    ; return value in dx:ax
    sub sp,byte +0x5e
    cmp word [param_c],byte +0x0
    jz .label0 ; ↓
    jmp .label5 ; ↓
.label0: ; 126
    mov word [bp-0x56], s_sequencer
    mov [bp-0x54],ds
    mov ax,[filename+FarPtr.Off]
    mov dx,[filename+FarPtr.Seg]
    mov [bp-0x52],ax
    mov [bp-0x50],dx
    mov word [bp-0x4e],EmptyStringForMciSendCommand
    mov [bp-0x4c],ds
    push byte +0x0
    push word 0x803     ; MCI_OPEN
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
.returnSomething: ; 15f
    mov ax,[bp-0x6]
    mov dx,[bp-0x4]
    jmp .return ; ↓
.label2: ; 168
    mov word [bp-0x42],0x4003
    mov word [bp-0x40],0x0
    mov ax,[bp-0x5a]
    mov [MCIDeviceID],ax
    push ax
    push word 0x814     ; MCI_STATUS
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
    push word [MCIDeviceID]
    push word 0x804     ; MCI_CLOSE
    push byte +0x0
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far [fpMciSendCommand] ; 1a3
    mov word [MIDIPlaying],0x0
    jmp short .returnSomething ; ↑
    nop
.label4: ; 1b0
    cmp word [bp-0x46],byte -0x1
    jz .label5 ; ↓
    push byte +0x4
    push ds
    push word s_The_MIDI_Mapper_is_not_available_Continue?
    push word [hwndMain]
    call far ShowMessageBox ; 1c0 2:0
    add sp,byte +0x8
    cmp ax,0x7
    jnz .label5 ; ↓
    push word [MCIDeviceID]
    push word 0x804     ; MCI_CLOSE
    push byte +0x0
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far [fpMciSendCommand] ; 1dc
    mov word [MIDIPlaying],0x0
    jmp short .returnZero ; ↓
.label5: ; 1e8
    mov word [MIDIPlaying],0x1
    mov ax,[hWnd]
    mov [bp-0x3a],ax
    mov [bp-0x38],ds
    sub ax,ax
    mov [bp-0x34],ax
    mov [bp-0x36],ax
    push word [MCIDeviceID]
    push word 0x806     ; MCI_PLAY
    push ax
    push byte +0x5
    lea ax,[bp-0x3a]
    push ss
    push ax
    call far [fpMciSendCommand] ; 20e
    mov [bp-0x6],ax
    mov [bp-0x4],dx
    or dx,ax
    jz .returnZero ; ↓
    jmp .label3 ; ↑
.returnZero: ; 21f
    xor ax,ax
    cwd
.return: ; 222
endfunc

; 22a

func FUN_8_022a
    sub sp,byte +0x2
    push byte +0x1
    push byte +0x0
    push byte +0x0
    push word [hwndMain]
    call far StartMIDI ; 241 8:110
    add sp,byte +0x8
    or dx,ax
    jnz .returnZero ; ↓
    mov ax,0x1
    jmp short .end ; ↓
.returnZero: ; 252
    xor ax,ax
.end: ; 254
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
    call far USER._wsprintf ; 27b
    add sp,byte +0xc
    mov ax,[fpMciGetErrorString+FarPtr.Seg]
    or ax,[fpMciGetErrorString+FarPtr.Off]
    jz .label0 ; ↓
    push word [bp+0x8]
    push word [bp+0x6]
    lea ax,[bp-0x11a]
    push ss
    push ax
    call far KERNEL.lstrlen ; 298
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
    call far ShowMessageBox ; 2c4 2:0
    add sp,byte +0x8
    pop si
endfunc

; 2d4

; stop music
func StopMIDI
    sub sp,byte +0x2
    cmp word [MIDIPlaying],byte +0x0
    jz .label0 ; ↓
    push word [MCIDeviceID]
    push word 0x804     ; MCI_CLOSE
    push byte +0x0
    push byte +0x0
    push byte +0x0
    push byte +0x0
    call far [fpMciSendCommand] ; 2f7
.label0: ; 2fb
    mov word [MIDIPlaying],0x0
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
    mov ax,[fpMciSendCommand+FarPtr.Seg]
    or ax,[fpMciSendCommand+FarPtr.Off]
    jnz .mciSendCommandExists ; ↓
    jmp .returnZero ; ↓
.mciSendCommandExists: ; 32d
    cmp word [NumMIDIFiles],byte +0x0
    jnz .haveSomeMIDIFiles ; ↓
    jmp .returnZero ; ↓
.haveSomeMIDIFiles: ; 337
    call far StopMIDI ; 337 8:2d4
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
    call far StopMIDI ; 3a6 8:2d4
    push word [hwndMain]
    push word 0x111
    push byte ID_BGM
    push byte +0x0
    push byte +0x0
    call far USER.SendMessage ; 3b8
    push byte +0x30
    push ds
    push word s_None_of_the_MIDI_files_specified___
    push word [hwndMain]
    call far ShowMessageBox ; 3c7 2:0
    add sp,byte +0x8
    push word [hMenu]
    push byte ID_BGM
    push byte +0x1
    call far USER.EnableMenuItem ; 3d7
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
    call far USER.LoadCursor ; 3f7
    mov [bp-0x8],ax
    push word [hwndMain]
    call far USER.SetCapture ; 403
    push word [bp-0x8]
    call far USER.SetCursor ; 40b
    mov [bp-0xa],ax
    push byte +0x0
    push word [bp-0xe]
    push di
    push word [hwndMain]
    call far StartMIDI ; 41d 8:110
    add sp,byte +0x8
    mov [bp-0x6],ax
    mov [bp-0x4],dx
    push word [bp-0xa]
    call far USER.SetCursor ; 42e
    call far USER.ReleaseCapture ; 433
    mov ax,[bp-0x4]
    or ax,[bp-0x6]
    jz .label11 ; ↓
    cmp word [bp-0x6],0x113
    jnz .break ; ↓
    cmp word [bp-0x4],byte +0x0
    jnz .break ; ↓
    mov bx,[bp-0x12]
    push word [bx]
    call far KERNEL.LocalFree ; 452
    mov bx,[bp-0x12]
    mov word [bx],0x0
    jmp .loop ; ↑
    nop

.break: ; 462
    push word [bp-0xe] ; filename
    push di
    push word [bp-0x4]
    push word [bp-0x6]
    call far ShowMIDIError ; 46c 8:25c
    add sp,byte +0x8
    push word [hwndMain]
    push word 0x111
    push byte ID_BGM
    push byte +0x0
    push byte +0x0
    call far USER.SendMessage ; 481
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

; Get the path to all sound and MIDI files and store them in the
; global sound/midi arrays.
func InitAudioFiles
    sub sp,0x102
    push di
    push si
    ;; Sound
    xor di,di
    mov si,SoundArray
.soundLoop: ; 4b5
    push byte +0x0
    push byte +0x1
    push word 0x100
    lea ax,[bp-0x102]
    push ax
    push di
    call far GetAudioPath ; 4c2 2:1ca0
    add sp,byte +0x8
    inc ax
    push ax
    call far KERNEL.LocalAlloc ; 4cc
    mov [si],ax
    or ax,ax
    jz .nextSound ; ↓
    push ds
    push ax
    lea ax,[bp-0x102]
    push ss
    push ax
    call far KERNEL.lstrcpy ; 4df
.nextSound: ; 4e4
    inc di
    add si,byte +0x2
    cmp si,SoundArray.end
    jb .soundLoop ; ↑
    ;; MIDI
    push word ID_NumMidiFiles
    call far GetIniInt ; 4f1 2:198e
    add sp,byte +0x2
    cmp ax,NumMidiFilesMax
    jl .label2 ; ↓
    mov ax,NumMidiFilesMax
    jmp short .label3 ; ↓
    nop
.label2: ; 504
    push word ID_NumMidiFiles
    call far GetIniInt ; 507 2:198e
    add sp,byte +0x2
.label3: ; 50f
    mov [NumMIDIFiles],ax
    push ax
    push word ID_NumMidiFiles
    call far StoreIniInt ; 516 2:19ca
    add sp,byte +0x4
    xor di,di
    cmp [NumMIDIFiles],di
    jng .label6 ; ↓
    mov si,MIDIArray
.midiLoop: ; 529
    push byte +0x0
    push byte +0x0
    push word 0x100
    lea ax,[bp-0x102]
    push ax
    push di
    call far GetAudioPath ; 536 2:1ca0
    add sp,byte +0x8
    inc ax
    push ax
    call far KERNEL.LocalAlloc ; 540
    mov [si],ax
    or ax,ax
    jz .nextMidiFile ; ↓
    push ds
    push ax
    lea ax,[bp-0x102]
    push ss
    push ax
    call far KERNEL.lstrcpy ; 553
.nextMidiFile: ; 558
    add si,byte +0x2
    inc di
    cmp di,[NumMIDIFiles]
    jl .midiLoop ; ↑
.label6: ; 562
    pop si
    pop di
endfunc

; 56c

func PlaySoundEffect
    sub sp,byte +0x6
    cmp word [SoundEnabled],byte +0x0
    jz .label0 ; ↓
    mov ax,[fpSndPlaySound+FarPtr.Seg]
    or ax,[fpSndPlaySound+FarPtr.Off]
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

; Free the paths stored in SoundArray and MIDIArray
func FreeAudioFiles
    sub sp,byte +0x4
    push di
    push si
    mov ax,[fpSndPlaySound+FarPtr.Seg]
    or ax,[fpSndPlaySound+FarPtr.Off]
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
    call far KERNEL.LocalFree ; 5e7
.label2: ; 5ec
    add si,byte +0x2
    cmp si,SoundArray.end
    jb .label1 ; ↑
    xor di,di
    cmp [NumMIDIFiles],di
    jng .label5 ; ↓
    mov si,MIDIArray
.label3: ; 600
    cmp word [si],byte +0x0
    jz .label4 ; ↓
    push word [si]
    call far KERNEL.LocalFree ; 607
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

GLOBAL _segment_8_size
_segment_8_size equ $ - $$

; vim: syntax=nasm

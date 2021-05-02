; base.inc - common definitions

; Useful constants for dealing with far pointers and long ints.
;
; Declare far pointers as a dword and use these constants to access
; the segment and offset parts.
;
;       mov bx,[GameStatePtr]
;       mov ax,[bx+TrapListPtr+FarPtr.Off]
;       mov dx,[bx+TrapListPtr+FarPtr.Seg]
;

STRUC FarPtr
    .Off        resw 1  ; 0x0
    .Seg        resw 1  ; 0x2
ENDSTRUC

STRUC LongInt
    _LoWord     resw 1
    _HiWord     resw 1
ENDSTRUC

; vim: syntax=nasm

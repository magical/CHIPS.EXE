; base.inc - common definitions

; Useful constants for dealing with far pointers.
;
; Declare far pointers as a dword and use these constants to access
; the segment and offset parts.
;
;       mov bx,[GameStatePtr]
;       mov dx,[bx+TrapListPtr+FarPtr.Off]
;       mov ax,[bx+TrapListPtr+FarPtr.Seg]
;

STRUC FarPtr
    .Off        resw 1  ; 0x0
    .Seg        resw 1  ; 0x2
ENDSTRUC

; vim: syntax=nasm

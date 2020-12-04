; Resource types
%define RT_BITMAP       0x8002
%define RT_ICON         0x8003
%define RT_MENU         0x8004
%define RT_DIALOG       0x8005
%define RT_STRING       0x8006
%define RT_ACCELERATOR  0x8009
%define RT_RCDATA       0x800a
%define RT_VERSIONINFO  0x800e


; MENU Resources
%define MF_CHECKED  0x08
%define MF_POPUP    0x10
%define MF_END      0x80

%macro POPUP 1-2 0
    dw MF_POPUP|%2  ; flags
    db %1, 0        ; text
%endmacro

%macro MENUITEM 2-3 0
    dw %3           ; flags
    dw %2           ; action
    db %1, 0        ; text
%endmacro


; DIALOG Resources
; NOTE: These are not intended to exactly match the declarations in RC scripts
;       in order to make them more convenient for use in nasm.  However, they
;       are designed to look at least somewhat familiar...
; rect values are specified as {x, y, width, height}

; Common styles
%define WS_DISABLED         0x08000000

; Styles for DIALOG
%define DS_SETFONT          0x40
%define DS_MODALFRAME       0x80

; Styles for EDITTEXT
%define ES_UPPERCASE        0x08
%define ES_AUTOHSCROLL      0x80

; Styles for LISTBOX
%define LBS_NOTIFY          0x01
%define LBS_USETABSTOPS     0x80

; DIALOG num items, rect, [style]
%macro DIALOG 2-3 0
    dd 0x90c80000|%3    ; style (WS_POPUP|WS_VISIBLE|WS_CAPTION|WS_SYSMENU)
    db %1               ; number of items
    dw %2               ; position and size
    db 0                ; menu
    db 0                ; window class
%endmacro

%macro CAPTION 1
    db %1, 0            ; text
%endmacro

%macro FONT 2
    dw %1               ; font size
    db %2, 0            ; font face
%endmacro

%macro DLGITEM    8
    dw %{4:7}           ; position and size
    dw %3               ; id
    dd %8               ; style
    db %1               ; class
    db %2, 0            ; text
    db 0
%endmacro

; PUSHBUTTON text, id, rect, [style]
%macro PUSHBUTTON 3-4 0
    ; class 0x80 (button)
    ; style 0x50010000 (WS_CHILD|WS_VISIBLE|WS_TABSTOP)
    DLGITEM 0x80, %1, %2, %3, 0x50010000|%4
%endmacro

; DEFPUSHBUTTON text, id, rect, [style]
%macro DEFPUSHBUTTON 3-4 0
    ; class 0x80 (button)
    ; style 0x50010001 (WS_CHILD|WS_VISIBLE|WS_TABSTOP|BS_DEFPUSHBUTTON)
    DLGITEM 0x80, %1, %2, %3, 0x50010001|%4
%endmacro

; EDITTEXT id, rect, [style]
%macro EDITTEXT 2-3 0
    ; class 0x81
    ; style 0x50810000 (WS_CHILD|WS_VISIBLE|WS_BORDER|WS_TABSTOP)
    DLGITEM 0x81, "", %1, %2, 0x50810000|%3
%endmacro

; LTEXT text, id, rect, [style]
%macro LTEXT 3-4 0
    ; class 0x82 (static text)
    ; style 0x50020000 (WS_CHILD|WS_VISIBLE|WS_TABSTOP|SS_LEFT)
    DLGITEM 0x82, %1, %2, %3, 0x50020000|%4
%endmacro

; CTEXT text, id, rect, [style]
%macro CTEXT 3-4 0
    ; class 0x82 (static text)
    ; style 0x50020001 (WS_CHILD|WS_VISIBLE|WS_TABSTOP|SS_CENTER)
    DLGITEM 0x82, %1, %2, %3, 0x50020001|%4
%endmacro

; RTEXT text, id, rect, [style]
%macro RTEXT 3-4 0
    ; class 0x82 (static text)
    ; style 0x50020002 (WS_CHILD|WS_VISIBLE|WS_TABSTOP|SS_RIGHT)
    DLGITEM 0x82, %1, %2, %3, 0x50020002|%4
%endmacro

; LISTBOX id, rect, [style]
%macro LISTBOX 2-3 0
    ; class 0x83 (list box)
    ; style 0x50a10000 (WS_CHILD|WS_VISIBLE|WS_BORDER|WS_VSCROLL|WS_TABSTOP)
    DLGITEM 0x83, "", %1, %2, 0x50a10000|%3
%endmacro

; variables.asm - header file for data segment addresses
;                 to make up for the lack of linking

hWnd            equ 0x12
GameStatePtr    equ 0x1680
DecadeMessages  equ 0xec2
TileTable       equ 0x66c
TotalScore      equ 0x1696

BlueKeyCount    equ 0x1682
RedKeyCount     equ 0x1684
GreenKeyCount   equ 0x1686
YellowKeyCount  equ 0x1688
FlipperCount    equ 0x168a
FireBootCount   equ 0x168c
IceSkateCount   equ 0x168e
SuctionBootCount equ 0x1690
ChipsRemainingCount equ 0x1692

GreatJobChipMsg equ 0xc6e
MelindaHerselfMsg equ 0xca8
YouCompletedNLevelsMsg equ 0xd44
Chipend equ 0x1352
Chipend2 equ 0x135a

; vim: syntax=nasm

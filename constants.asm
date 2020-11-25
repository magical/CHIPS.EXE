; constants.asm - header file for constants

; Tiles
Floor           equ 0x00
Wall            equ 0x01
ICChip          equ 0x02
Water           equ 0x03
Fire            equ 0x04
InvisibleWall   equ 0x05
PanelN          equ 0x06
PanelW          equ 0x07
PanelS          equ 0x08
PanelE          equ 0x09
Block           equ 0x0A
Dirt            equ 0x0B
Ice             equ 0x0C
ForceS          equ 0x0D
BlockN          equ 0x0E
BlockW          equ 0x0F
BlockS          equ 0x10
BlockE          equ 0x11
ForceN          equ 0x12
ForceE          equ 0x13
ForceW          equ 0x14
Exit            equ 0x15
BlueDoor        equ 0x16
RedDoor         equ 0x17
GreenDoor       equ 0x18
YellowDoor      equ 0x19
IceWallNW       equ 0x1A
IceWallNE       equ 0x1B
IceWallSE       equ 0x1C
IceWallSW       equ 0x1D
FakeFloor       equ 0x1E
FakeWall        equ 0x1F

; Unused20      equ 0x20 ; Combination tile
Thief           equ 0x21
Socket          equ 0x22
ToggleButton    equ 0x23
CloneButton     equ 0x24
ToggleWall      equ 0x25
ToggleFloor     equ 0x26
TrapButton      equ 0x27
TankButton      equ 0x28
Teleport        equ 0x29
Bomb            equ 0x2A
Trap            equ 0x2B
HiddenWall      equ 0x2C
Gravel          equ 0x2D
PopupWall       equ 0x2E
Hint            equ 0x2F

PanelSE         equ 0x30
CloneMachine    equ 0x31
ForceRandom     equ 0x32
ChipSplash      equ 0x33
ChipBurned      equ 0x34
ChipBombed      equ 0x35
; Unused36
; Unused37
; Unused38 / IceBlock
ChipExit        equ 0x39
Exit2           equ 0x3A
Exit3           equ 0x3B
SwimN           equ 0x3C
SwimW           equ 0x3D
SwimS           equ 0x3E
SwimE           equ 0x3F

BugN            equ 0x40
BugW            equ 0x41
BugS            equ 0x42
BugE            equ 0x43
FireballN       equ 0x44
FireballW       equ 0x45
FireballS       equ 0x46
FireballE       equ 0x47
BallN           equ 0x48
BallW           equ 0x49
BallS           equ 0x4A
BallE           equ 0x4B
TankN           equ 0x4C
TankW           equ 0x4D
TankS           equ 0x4E
TankE           equ 0x4F
GliderN         equ 0x50
GliderW         equ 0x51
GliderS         equ 0x52
GliderE         equ 0x53
TeethN          equ 0x54
TeethW          equ 0x55
TeethS          equ 0x56
TeethE          equ 0x57
WalkerN         equ 0x58
WalkerW         equ 0x59
WalkerS         equ 0x5A
WalkerE         equ 0x5B
BlobN           equ 0x5C
BlobW           equ 0x5D
BlobS           equ 0x5E
BlobE           equ 0x5F
ParameciumN     equ 0x60
ParameciumW     equ 0x61
ParameciumS     equ 0x62
ParameciumE     equ 0x63

BlueKey         equ 0x64
RedKey          equ 0x65
GreenKey        equ 0x66
YellowKey       equ 0x67

Flipper         equ 0x68
FireBoots       equ 0x69
IceSkates       equ 0x6A
SuctionBoots    equ 0x6B

ChipN           equ 0x6C
ChipW           equ 0x6D
ChipS           equ 0x6E
ChipE           equ 0x6F

FirstMonster    equ 0x40
LastMonster     equ 0x63

FirstTransparent equ 0x40
LastTransparent  equ 0x6F

; Causes of death
NotDeadYet  equ 0
Burned      equ 1
Drowned     equ 2
Bombed      equ 3
Squished    equ 4
Eaten       equ 5
OutOfTime   equ 6

; Sound effects
PickUpToolSound         equ 0
OpenDoorSound           equ 1
ChipDeathSound          equ 2
LevelCompleteSound      equ 3
SocketSound             equ 4
BlockedMoveSound        equ 5
ThiefSound              equ 6
SoundOnSound            equ 7
PickUpChipSound         equ 8
SwitchSound             equ 9
SplashSound             equ 10
BombSound               equ 11
TeleportSound           equ 12
TickSound               equ 13
ChipDeathByTimeSound    equ 14

; Last level
FirstLevel    equ 1
FakeLastLevel equ 144
LastLevel     equ 149

; Dialog box controls (standard)
ID_OK           equ 0x01
ID_CANCEL       equ 0x02
ID_YES          equ 0x06
ID_NO           equ 0x07

; Menu actions
ID_ABOUT        equ 0x64
ID_QUIT         equ 0x6A
ID_HELP         equ 0x6B
ID_CHEAT        equ 0x6C
ID_METAHELP     equ 0x6D

ID_NEXT         equ 0x6E
ID_PREVIOUS     equ 0x6F
ID_RESTART      equ 0x71
ID_NEWGAME      equ 0x72
ID_BESTTIMES    equ 0x73
ID_PAUSE        equ 0x74
ID_BGM          equ 0x75
ID_SOUND        equ 0x76
ID_GOTO         equ 0x77
ID_COLOR        equ 0x7A

ID_HOWTOPLAY    equ 0x78
ID_COMMANDS     equ 0x79

; INI keys & defaults
ID_HighestLevel equ 200 ; 0xc8
ID_CurrentLevel equ 201 ; 0xc9
ID_CurrentScore equ 202 ; 0xca
ID_NumMidiFiles equ 203 ; 0xcb

SoundEnabledDefault     equ 0
MusicEnabledDefault     equ 0
ColorDefault            equ 1
NumMidiFilesDefault     equ 3
NumMidiFilesMax         equ 20

; Tile sizes
TileWidth       equ 32
TileHeight      equ 32
TileShift       equ 5


;;; Windows stuff

; Events
WM_PAINT        equ 0xf

; Window styles
WS_CLIPCHILDREN equ 0x200<<16
WS_TILEDWINDOW  equ 0x0cf<<16

; Virtual key codes
VK_CONTROL      equ 0x11

; vim: syntax=nasm

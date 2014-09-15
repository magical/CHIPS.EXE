INCBIN "chips.exe", 0x4800, 0x68

db "Chip's Challenge", 0, 0
db "Not enough system timers are available.", 0
db "Starting a new game will begin you back at level 1, reset your score to zero, and forget the passwords to any levels you have visited.", 10, "Is this what you want?", 0
db "There is not enough memory to load Chip's Challenge.", 0, 0
db "Ooops! Don't step in the fire without fire boots!", 0
db "Ooops! Chip can't swim without flippers!", 0, 0
db "Ooops! Don't touch the bombs!", 0
db "Ooops! Watch out for moving blocks!", 0
db "Ooops! Look out for creatures!", 0, 0
db "Ooops! Out of time!", 0

db "Contents", 0, 0
db "How To Play", 0
db "Commands", 0, 0

db "entpack.ini", 0
db "Chip's Challenge", 0, 0
db "MIDI", 0, 0
db "Sounds", 0, 0
db "Highest Level", 0
db "Current Level", 0
db "Current Score", 0
db "Color", 0, 0, 0
db "KeyboardDelay", 0
db "CHIPS.DAT", 0
db "Number of Midi Files", 0, 0

dw PickUpToolSoundKey
dw OpenDoorSoundKey
dw ChipDeathSoundKey
dw LevelCompleteSoundKey
dw SocketSoundKey
dw BlockedMoveSoundKey
dw ThiefSoundKey
dw SoundOnSoundKey
dw PickUpChipSoundKey
dw SwitchSoundKey
dw SplashSoundKey
dw BombSoundKey
dw TeleportSoundKey
dw TickSoundKey
dw ChipDeathByTimeSoundKey

dw PickUpToolSoundDefault
dw OpenDoorSoundDefault
dw ChipDeathSoundDefault
dw LevelCompleteSoundDefault
dw SocketSoundDefault
dw BlockedMoveSoundDefault
dw ThiefSoundDefault
dw SoundOnSoundDefault
dw PickUpChipSoundDefault
dw SwitchSoundDefault
dw SplashSoundDefault
dw BombSoundDefault
dw TeleportSoundDefault
dw TickSoundDefault
dw ChipDeathByTimeSoundDefault

dw MidiFileDefault1
dw MidiFileDefault2
dw MidiFileDefault3

PickUpToolSoundKey      db "PickUpToolSound", 0
OpenDoorSoundKey        db "OpenDoorSound", 0
ChipDeathSoundKey       db "ChipDeathSound", 0
LevelCompleteSoundKey   db "LevelCompleteSound", 0
SocketSoundKey          db "SocketSound", 0
BlockedMoveSoundKey     db "BlockedMoveSound", 0
ThiefSoundKey           db "ThiefSound", 0
SoundOnSoundKey         db "SoundOnSound", 0
PickUpChipSoundKey      db "PickUpChipSound", 0
SwitchSoundKey          db "SwitchSound", 0
SplashSoundKey          db "SplashSound", 0
BombSoundKey            db "BombSound", 0
TeleportSoundKey        db "TeleportSound", 0
TickSoundKey            db "TickSound", 0
ChipDeathByTimeSoundKey db "ChipDeathByTimeSound", 0

PickUpToolSoundDefault          db "blip2.wav", 0
OpenDoorSoundDefault            db "door.wav", 0
ChipDeathSoundDefault           db "bummer.wav", 0
LevelCompleteSoundDefault       db "ditty1.wav", 0
SocketSoundDefault              db "chimes.wav", 0
BlockedMoveSoundDefault         db "oof3.wav", 0
ThiefSoundDefault               db "strike.wav", 0
SoundOnSoundDefault             db "chimes.wav", 0
PickUpChipSoundDefault          db "click3.wav", 0
SwitchSoundDefault              db "pop2.wav", 0
SplashSoundDefault              db "water2.wav", 0
BombSoundDefault                db "hit3.wav", 0
TeleportSoundDefault            db "teleport.wav", 0
TickSoundDefault                db "click1.wav", 0
ChipDeathByTimeSoundDefault     db "bell.wav", 0

MidiFileDefault1 db "chip01.mid", 0
MidiFileDefault2 db "chip02.mid", 0
MidiFileDefault3 db "canyon.mid", 0

db "MainClass", 0
db "BoardClass", 0
db "InfoClass", 0
db "CounterClass", 0
db "InventoryClass", 0
db "HintClass", 0
db "ChipsMenu", 0
db "Chip's Challenge", 0
db "MainClass", 0
db "BoardClass", 0
db "InfoClass", 0
db "CounterClass", 0
db "CounterClass", 0
db "CounterClass", 0
db "InventoryClass", 0
db "Ooops!", 0
db "HintClass", 0
db "background", 0
db "Arial", 0
db "Helv", 0
db "PAUSED", 0
db "Arial", 0
db "Helv", 0

db " %s ", 0
db " Password: %s ", 0
db " %s ", 0
db " Password: %s ", 0
db "%d", 0
db "%li", 0
db "%li", 0
db "Level%d", 0
db "Level%d", 0
db "%s,%d,%li", 0
db "%s", 0
db "MidiFile%d", 0
db "$", 0
db "Level%d", 0
db "DLG_GOTO", 0
db "DLG_BESTTIMES", 0
db "&Ignore Passwords", 0
db "ChipsMenu", 0, 0
dw 0
db "infownd", 0
db "Hint: %s", 0
db "Arial", 0
db "Helv", 0

; Tile table (0x66c)
; Columns: Chip, ??, Block, ??, Monsters, ??
;
db 1,0,1,0,1,1  ; 0x0
db 0,0,0,0,0,0  ; 0x1
db 1,1,0,0,0,0  ; 0x2
db 2,2,1,2,2,2  ; 0x3
db 2,2,1,1,2,2  ; 0x4
db 0,0,0,0,0,0  ; 0x5
db 2,4,2,1,2,1  ; 0x6
db 2,4,2,1,2,1  ; 0x7
db 2,4,2,1,2,1  ; 0x8
db 2,4,2,1,2,1  ; 0x9
db 2,0,0,0,0,0  ; 0xa
db 1,3,0,0,0,0  ; 0xb
db 2,5,1,4,1,4  ; 0xc
db 2,5,1,4,1,4  ; 0xd
db 0,0,0,0,0,0  ; 0xe
db 0,0,0,0,0,0  ; 0xf
db 0,0,0,0,0,0  ; 0x10
db 0,0,0,0,0,0  ; 0x11
db 2,5,1,4,1,4  ; 0x12
db 2,5,1,4,1,4  ; 0x13
db 2,5,1,4,1,4  ; 0x14
db 1,4,1,1,0,0  ; 0x15
db 2,3,0,0,0,0  ; 0x16
db 2,3,0,0,0,0  ; 0x17
db 2,3,0,0,0,0  ; 0x18
db 2,3,0,0,0,0  ; 0x19
db 2,5,2,4,2,4  ; 0x1a
db 2,5,2,4,2,4  ; 0x1b
db 2,5,2,4,2,4  ; 0x1c
db 2,5,2,4,2,4  ; 0x1d
db 2,0,0,0,0,0  ; 0x1e
db 2,0,0,0,0,0  ; 0x1f
db 0,0,0,0,0,0  ; 0x20
db 2,4,0,0,0,0  ; 0x21
db 2,3,0,0,0,0  ; 0x22
db 1,4,1,1,1,1  ; 0x23
db 1,4,1,1,1,1  ; 0x24
db 0,0,0,0,0,0  ; 0x25
db 1,4,1,1,1,1  ; 0x26
db 1,4,1,1,1,1  ; 0x27
db 1,4,1,1,1,1  ; 0x28
db 1,7,1,7,1,7  ; 0x29
db 1,2,1,5,1,5  ; 0x2a
db 1,6,1,6,1,6  ; 0x2b
db 2,0,0,0,0,0  ; 0x2c
db 1,4,1,1,0,0  ; 0x2d
db 2,4,0,0,0,0  ; 0x2e
db 1,4,1,1,1,1  ; 0x2f
db 2,4,2,1,2,1  ; 0x30
db 0,0,0,0,0,0  ; 0x31
db 2,5,1,4,0,0  ; 0x32
db 0,0,0,0,0,0  ; 0x33
db 0,0,0,0,0,0  ; 0x34
db 0,0,0,0,0,0  ; 0x35
db 0,0,0,0,0,0  ; 0x36
db 0,0,0,0,0,0  ; 0x37
db 0,0,0,0,0,0  ; 0x38
db 0,0,0,0,0,0  ; 0x39
db 0,0,0,0,0,0  ; 0x3a
db 0,0,0,0,0,0  ; 0x3b
db 0,0,1,1,1,0  ; 0x3c
db 0,0,1,1,1,0  ; 0x3d
db 0,0,1,1,1,0  ; 0x3e
db 0,0,1,1,1,0  ; 0x3f
db 2,2,0,0,0,0  ; 0x40
db 2,2,0,0,0,0  ; 0x41
db 2,2,0,0,0,0  ; 0x42
db 2,2,0,0,0,0  ; 0x43
db 2,2,0,0,0,0  ; 0x44
db 2,2,0,0,0,0  ; 0x45
db 2,2,0,0,0,0  ; 0x46
db 2,2,0,0,0,0  ; 0x47
db 2,2,0,0,0,0  ; 0x48
db 2,2,0,0,0,0  ; 0x49
db 2,2,0,0,0,0  ; 0x4a
db 2,2,0,0,0,0  ; 0x4b
db 2,2,0,0,0,0  ; 0x4c
db 2,2,0,0,0,0  ; 0x4d
db 2,2,0,0,0,0  ; 0x4e
db 2,2,0,0,0,0  ; 0x4f
db 2,2,0,0,0,0  ; 0x50
db 2,2,0,0,0,0  ; 0x51
db 2,2,0,0,0,0  ; 0x52
db 2,2,0,0,0,0  ; 0x53
db 2,2,0,0,0,0  ; 0x54
db 2,2,0,0,0,0  ; 0x55
db 2,2,0,0,0,0  ; 0x56
db 2,2,0,0,0,0  ; 0x57
db 2,2,0,0,0,0  ; 0x58
db 2,2,0,0,0,0  ; 0x59
db 2,2,0,0,0,0  ; 0x5a
db 2,2,0,0,0,0  ; 0x5b
db 2,2,0,0,0,0  ; 0x5c
db 2,2,0,0,0,0  ; 0x5d
db 2,2,0,0,0,0  ; 0x5e
db 2,2,0,0,0,0  ; 0x5f
db 2,2,0,0,0,0  ; 0x60
db 2,2,0,0,0,0  ; 0x61
db 2,2,0,0,0,0  ; 0x62
db 2,2,0,0,0,0  ; 0x63
db 2,1,1,1,1,1  ; 0x64
db 2,1,1,1,1,1  ; 0x65
db 2,1,1,1,1,1  ; 0x66
db 2,1,1,1,1,1  ; 0x67
db 2,1,1,1,0,0  ; 0x68
db 2,1,1,1,0,0  ; 0x69
db 2,1,1,1,0,0  ; 0x6a
db 2,1,1,1,0,0  ; 0x6b
db 0,0,1,1,1,0  ; 0x6c
db 0,0,1,1,1,0  ; 0x6d
db 0,0,1,1,1,0  ; 0x6e
db 0,0,1,1,1,0  ; 0x6f

INCBIN "chips.exe", 0x4800+$, 0x1738-0x90C

; vim: syntax=nasm

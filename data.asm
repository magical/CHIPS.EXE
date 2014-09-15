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

INCBIN "chips.exe", 0x4800+$, 0x1738-0x66C

; vim: syntax=nasm

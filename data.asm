SEGMENT DATA ; 10

[MAP SYMBOLS data.map]

; Variables

; INSTANCEDATA -
; a data structure used by the windows kernel
; to track local allocations and stuff
    dw 0 ; 0x0 null
    dw 0 ; 0x2 old stack pointer
    dw 5 ; 0x4 old stack segment
    dw 0 ; 0x6 heap pointer
    dw 0 ; 0x8 atom table pointer
    dw 0 ; 0xa top of stack
    dw 0 ; 0xc lowest stack address used
    dw 0 ; 0xe bottom of stack

; 0x10
; segment 2 variables

hwndMain     dw 0 ; 0x10 HWND main window
hwndBoard    dw 0 ; 0x12 HWND board window
hwndInfo     dw 0 ; 0x14
hwndCounter  dw 0 ; 0x16 level counter
hwndCounter2 dw 0 ; 0x18 time counter
hwndCounter3 dw 0 ; 0x1a chips left counter
hwndInventory  dw 0 ; 0x1c
hwndHint     dw 0 ; 0x1e

InventoryDirty dw 0 ; 0x20
Var22        dw 0 ; 0x22 *
GamePaused   dw 0 ; 0x24
hMenu        dw 0 ; 0x26 HMENU
hAccel       dw 0 ; 0x28 HACCEL
Var2a        dw 0 ; 0x2a whether we've called WEP4UTIL.WEPHELP
Var2c        dw 0 ; 0x2c whether to pause the game and music when minimized

IgnorePasswords dw 0 ; 0x2e passwords disabled
CheatVisible    dw 0 ; 0x30 whether the ignore passwords menu option is visible
CheatKeys       dw 0 ; 0x32 bitset of cheat keys that have been pressed

KeyboardDelay   dw -1 ; 0x34

; LOGFONT struct
LOGFONT:
.lfHeight       dw 0 ; 0x36 lfHeight
                dw 0 ; 0x38 lfWidth
                dw 0 ; 0x3a lfEscapement
                dw 0 ; 0x3c lfOrientation
.lfWeight       dw 0 ; 0x3e lfWeight
.lfItalic       db 0 ; 0x40 lfItalic
                db 0 ; 0x41 lfUnderline
                db 0 ; 0x42 lfStrikeOut
                db 0 ; 0x43 lfCharSet
                db 0 ; 0x44 lfOutPrecision
                db 0 ; 0x45 lfClipPrecision
                db 0x02 ; 0x46 lfQuality PROOF_QUALITY
                db 0x22 ; 0x47 lfPitchAndFamily FF_SWISS | VARIABLE_PITCH
.lfFaceName:    db "Arial" ; 0x48 char[32] lfFaceName
                times 32-($-.lfFaceName) db 0

; 0x68
; segment 2 strings

MessageBoxCaption db "Chip's Challenge", 0, 0
SystemTimerErrorMsg db "Not enough system timers are available.", 0
NewGamePrompt db "Starting a new game will begin you back at level 1, reset your score to zero, and forget the passwords to any levels you have visited.", 10, "Is this what you want?", 0
NotEnoughMemoryErrorMsg db "There is not enough memory to load Chip's Challenge.", 0, 0

FireDeathMessage        db "Ooops! Don't step in the fire without fire boots!", 0
WaterDeathMessage       db "Ooops! Chip can't swim without flippers!", 0, 0
BombDeathMessage        db "Ooops! Don't touch the bombs!", 0
BlockDeathMessage       db "Ooops! Watch out for moving blocks!", 0
MonsterDeathMessage     db "Ooops! Look out for creatures!", 0, 0
TimeDeathMessage        db "Ooops! Out of time!", 0

s_Contents      db "Contents", 0, 0
s_How_To_Play   db "How To Play", 0
s_Commands      db "Commands", 0, 0

IniFileName     db "entpack.ini", 0
IniSectionName  db "Chip's Challenge", 0, 0
MIDIKey         db "MIDI", 0, 0
SoundsKey       db "Sounds", 0, 0
HighestLevelKey db "Highest Level", 0
CurrentLevelKey db "Current Level", 0
CurrentScoreKey db "Current Score", 0
ColorKey        db "Color", 0
s_2c4           db 0, 0
s_KeyboardDelay db "KeyboardDelay", 0
DataFileName    db "CHIPS.DAT", 0
NumMidiFilesKey db "Number of Midi Files", 0, 0

SoundKeyArray:
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

SoundDefaultArray:
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

MidiFileDefaultArray:
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

MainClassName   db "MainClass", 0
BoardClassName  db "BoardClass", 0
InfoClassName   db "InfoClass", 0
CounterClassName db "CounterClass", 0
InventoryClassName db "InventoryClass", 0
HintClassName   db "HintClass", 0

s_ChipsMenu     db "ChipsMenu", 0
MainWindowCaption db "Chip's Challenge", 0
s_MainClass     db "MainClass", 0
s_BoardClass    db "BoardClass", 0
s_InfoClass     db "InfoClass", 0
s_CounterClass1 db "CounterClass", 0
s_CounterClass2 db "CounterClass", 0
s_CounterClass3 db "CounterClass", 0
s_InventoryClass db "InventoryClass", 0
s_Ooops         db "Ooops!", 0
s_HintClass     db "HintClass", 0

s_background    db "background", 0
s_Arial1        db "Arial", 0
s_Helv1         db "Helv", 0
s_PAUSED        db "PAUSED", 0
s_Arial2        db "Arial", 0
s_Helv2         db "Helv", 0

; TODO: come up with some imaginative names for these
s_5b5 db " %s ", 0
s_5ba db " Password: %s ", 0
s_5c9 db " %s ", 0
s_5ce db " Password: %s ", 0
s_5dd db "%d", 0
s_5e0 db "%li", 0
s_5e4 db "%li", 0
s_5e8 db "Level%d", 0
s_5f0 db "Level%d", 0
s_5f8 db "%s,%d,%li", 0
s_602 db "%s", 0
s_605 db "MidiFile%d", 0
s_610 db "$", 0
s_612 db "Level%d", 0

s_DLG_GOTO      db "DLG_GOTO", 0
s_DLG_BESTTIMES db "DLG_BESTTIMES", 0
CheatMenuText   db "&Ignore Passwords", 0
s_ChipsMenu2    db "ChipsMenu", 0, 0
CurrentTick     dw 0
s_infownd       db "infownd", 0
s_658           db "Hint: %s", 0
s_Arial3        db "Arial", 0
s_Helv3         db "Helv", 0

; 66c
; logic.asm data

; Tile table
; Chip/Block/Monsters
; Even columns: 0=blocked 1=ok 2=special
; Odd columns: action
TileTable:
db 1,0,1,0,1,1  ; 0x0  Floor
db 0,0,0,0,0,0  ; 0x1  Wall
db 1,1,0,0,0,0  ; 0x2  ICChip
db 2,2,1,2,2,2  ; 0x3  Water
db 2,2,1,1,2,2  ; 0x4  Fire
db 0,0,0,0,0,0  ; 0x5  InvisibleWall
db 2,4,2,1,2,1  ; 0x6  PanelN
db 2,4,2,1,2,1  ; 0x7  PanelW
db 2,4,2,1,2,1  ; 0x8  PanelS
db 2,4,2,1,2,1  ; 0x9  PanelE
db 2,0,0,0,0,0  ; 0xa  Block
db 1,3,0,0,0,0  ; 0xb  Dirt
db 2,5,1,4,1,4  ; 0xc  Ice
db 2,5,1,4,1,4  ; 0xd  ForceS
db 0,0,0,0,0,0  ; 0xe  BlockN
db 0,0,0,0,0,0  ; 0xf  BlockW
db 0,0,0,0,0,0  ; 0x10 BlockS
db 0,0,0,0,0,0  ; 0x11 BlockE
db 2,5,1,4,1,4  ; 0x12 ForceN
db 2,5,1,4,1,4  ; 0x13 ForceE
db 2,5,1,4,1,4  ; 0x14 ForceW
db 1,4,1,1,0,0  ; 0x15 Exit
db 2,3,0,0,0,0  ; 0x16 BlueDoor
db 2,3,0,0,0,0  ; 0x17 RedDoor
db 2,3,0,0,0,0  ; 0x18 GreenDoor
db 2,3,0,0,0,0  ; 0x19 YellowDoor
db 2,5,2,4,2,4  ; 0x1a IceWallNW
db 2,5,2,4,2,4  ; 0x1b IceWallNE
db 2,5,2,4,2,4  ; 0x1c IceWallSE
db 2,5,2,4,2,4  ; 0x1d IceWallSW
db 2,0,0,0,0,0  ; 0x1e FakeFloor
db 2,0,0,0,0,0  ; 0x1f FakeWall
db 0,0,0,0,0,0  ; 0x20
db 2,4,0,0,0,0  ; 0x21 Thief
db 2,3,0,0,0,0  ; 0x22 Socket
db 1,4,1,1,1,1  ; 0x23 ToggleButton
db 1,4,1,1,1,1  ; 0x24 CloneButton
db 0,0,0,0,0,0  ; 0x25 ToggleWall
db 1,4,1,1,1,1  ; 0x26 ToggleFloor
db 1,4,1,1,1,1  ; 0x27 TrapButton
db 1,4,1,1,1,1  ; 0x28 TankButton
db 1,7,1,7,1,7  ; 0x29 Teleport
db 1,2,1,5,1,5  ; 0x2a Bomb
db 1,6,1,6,1,6  ; 0x2b Trap
db 2,0,0,0,0,0  ; 0x2c HiddenWall
db 1,4,1,1,0,0  ; 0x2d Gravel
db 2,4,0,0,0,0  ; 0x2e PopupWall
db 1,4,1,1,1,1  ; 0x2f Hint
db 2,4,2,1,2,1  ; 0x30 PanelSE
db 0,0,0,0,0,0  ; 0x31 CloneMachine
db 2,5,1,4,0,0  ; 0x32 ForceRandom
db 0,0,0,0,0,0  ; 0x33 ChipSplash
db 0,0,0,0,0,0  ; 0x34 ChipBurned
db 0,0,0,0,0,0  ; 0x35 ChipBombed
db 0,0,0,0,0,0  ; 0x36
db 0,0,0,0,0,0  ; 0x37
db 0,0,0,0,0,0  ; 0x38
db 0,0,0,0,0,0  ; 0x39 ChipExit
db 0,0,0,0,0,0  ; 0x3a Exit2
db 0,0,0,0,0,0  ; 0x3b Exit3
db 0,0,1,1,1,0  ; 0x3c SwimN
db 0,0,1,1,1,0  ; 0x3d SwimW
db 0,0,1,1,1,0  ; 0x3e SwimS
db 0,0,1,1,1,0  ; 0x3f SwimE
db 2,2,0,0,0,0  ; 0x40 BugN
db 2,2,0,0,0,0  ; 0x41 BugW
db 2,2,0,0,0,0  ; 0x42 BugS
db 2,2,0,0,0,0  ; 0x43 BugE
db 2,2,0,0,0,0  ; 0x44 FireballN
db 2,2,0,0,0,0  ; 0x45 FireballW
db 2,2,0,0,0,0  ; 0x46 FireballS
db 2,2,0,0,0,0  ; 0x47 FireballE
db 2,2,0,0,0,0  ; 0x48 BallN
db 2,2,0,0,0,0  ; 0x49 BallW
db 2,2,0,0,0,0  ; 0x4a BallS
db 2,2,0,0,0,0  ; 0x4b BallE
db 2,2,0,0,0,0  ; 0x4c TankN
db 2,2,0,0,0,0  ; 0x4d TankW
db 2,2,0,0,0,0  ; 0x4e TankS
db 2,2,0,0,0,0  ; 0x4f TankE
db 2,2,0,0,0,0  ; 0x50 GliderN
db 2,2,0,0,0,0  ; 0x51 GliderW
db 2,2,0,0,0,0  ; 0x52 GliderS
db 2,2,0,0,0,0  ; 0x53 GliderE
db 2,2,0,0,0,0  ; 0x54 TeethN
db 2,2,0,0,0,0  ; 0x55 TeethW
db 2,2,0,0,0,0  ; 0x56 TeethS
db 2,2,0,0,0,0  ; 0x57 TeethE
db 2,2,0,0,0,0  ; 0x58 WalkerN
db 2,2,0,0,0,0  ; 0x59 WalkerW
db 2,2,0,0,0,0  ; 0x5a WalkerS
db 2,2,0,0,0,0  ; 0x5b WalkerE
db 2,2,0,0,0,0  ; 0x5c BlobN
db 2,2,0,0,0,0  ; 0x5d BlobW
db 2,2,0,0,0,0  ; 0x5e BlobS
db 2,2,0,0,0,0  ; 0x5f BlobE
db 2,2,0,0,0,0  ; 0x60 ParameciumN
db 2,2,0,0,0,0  ; 0x61 ParameciumW
db 2,2,0,0,0,0  ; 0x62 ParameciumS
db 2,2,0,0,0,0  ; 0x63 ParameciumE
db 2,1,1,1,1,1  ; 0x64 BlueKey
db 2,1,1,1,1,1  ; 0x65 RedKey
db 2,1,1,1,1,1  ; 0x66 GreenKey
db 2,1,1,1,1,1  ; 0x67 YellowKey
db 2,1,1,1,0,0  ; 0x68 Flipper
db 2,1,1,1,0,0  ; 0x69 FireBoots
db 2,1,1,1,0,0  ; 0x6a IceSkates
db 2,1,1,1,0,0  ; 0x6b SuctionBoots
db 0,0,1,1,1,0  ; 0x6c ChipN
db 0,0,1,1,1,0  ; 0x6d ChipW
db 0,0,1,1,1,0  ; 0x6e ChipS
db 0,0,1,1,1,0  ; 0x6f ChipE

; 90c
; segment 4 strings

MelindaMessage:
    db "You seem to be having trouble with this level.", 10
    db "Would you like to skip to the next level?", 0, 0

CorruptDataMessage      db "Corrupt or inaccessible CHIPS.DAT file.", 0
s_98e       db 0
sColon      db ": ", 0
sNoColon    db 0
s_sss       db "%s%s%s", 0
PasswordPromptMessage   db "Please enter the password for level %d:", 0
WrongPasswordMessage    db 'Sorry, "%s" is not the correct password.', 0
EmptyPasswordMessage    db "You must enter a password.", 0

s_DLG_PASSWORD db "DLG_PASSWORD", 0, 0

; a14
; segment 5 vars & strings

VarA14          dw 0 ; a14 HGDIOBJ unused - tile bitmap handle?
VarA16          dw 0 ; a16 BYTE*   unused - tile bitmap data?
ColorMode       dw 0 ; a18 which bitmap to load: 1, 2, 3, or 4(?)
HicolorTiles    db "obj32_4", 0
LocolorTiles    db "obj32_4E", 0
MonochromeTiles db "obj32_1", 0, 0

; if this is set to nonzero, the viewport will be fixed in place
; at the top left of the map. it also disables the pause screen.
DebugModeEnabled dw 0 ; a34

; a36
; segment 6 strings

s_You_must_enter_a_level_andor_password db "You must enter a level and/or password.", 0
s_You_must_enter_a_valid_password db "You must enter a valid password.", 0, 0
s_That_is_not_a_valid_level_number db "That is not a valid level number.", 0
s_No_levels_completed db "No levels completed.", 0
LevelTimeAndScoreMsg db "Level %d:  %d seconds, %li points", 0
LevelNotCompletedMsg db "Level %d:  not completed", 0
s_plural_1 db "s", 0
s_singular_1 db 0
s_You_have_completed_d_levels db "You have completed %d level%s.", 0
s_Your_total_score_is_li_points db "Your total score is %li points.", 0
s_Yowser_First_Try db "Yowser! First Try!", 0
s_Go_Bit_Buster db "Go Bit Buster!", 0
s_Finished_Good_Work db "Finished! Good Work!", 0
s_At_last_You_did_it db "At last! You did it!", 0
s_b80 db "%s", 0
s_Time_Bonus_d db "Time Bonus:  %d", 0
s_Level_Bonus_li db "Level Bonus:  %li", 0
s_Level_Score_li db "Level Score:  %li", 0
s_You_have_established_a_time_record db "You have established a time record for this level!", 0
s_plural_2 db "s", 0
s_singular_2 db 0
s_You_beat_the_previous_time_record db "You beat the previous time record by %d second%s!", 0
s_plural_3 db "s", 0
s_singular_3 db 0
s_You_increased_your_score db "You increased your score on this level by %li point%s!", 0
s_Total_Score_li db "Total Score:  %li", 0
align 2, db 0

; c6c
; movement.asm strings & data

; Used as a pointer argument to SlideMovement when we don't care about its value
DummyVarForSlideMovement dw 0xFF ; c6c

GreatJobChipMsg:
    db "Great Job, Chip!", 10
    db "You did it!  You finished the challenge!", 0
MelindaHerselfMsg:
    db "Melinda herself offers Chip membership in the exclusive Bit Busters computer club, and gives him access to the club's computer system.  Chip is in heaven!", 0, 0
YouCompletedNLevelsMsg:
    db "You completed %d levels, and your total score for the challenge is %li points.", 10, 10
    db "You can still improve your score, by completing levels that you skipped, and getting better times on each level.  When you replay a level, if your new score is better than your old, your score will be adjusted by the difference.  Select Best Times from the Game menu to see your scores for each level.", 0

; ec2

DecadeMessages:
    dw .level50
    dw .level60
    dw .level70
    dw .level80
    dw .level90
    dw .level100
    dw .level110
    dw .level120
    dw .level130
    dw .level140

.level50 db "Picking up chips is what the challenge is all about. But on the ice, Chip gets chapped and feels like a chump instead of a champ.", 0
.level60 db "Chip hits the ice and decides to chill out. Then he runs into a fake wall and turns the maze into a thrash-a-thon!", 0
.level70 db "Chip is halfway through the world's hardest puzzle. If he succeeds, maybe the kids will stop calling him computer breath!", 0
.level80 db "Chip used to spend his time programming computer games and making models. But that was just practice for this brain-buster!", 0
.level90 db "'I can do it! I know I can!' Chip thinks as the going gets tougher. Besides, Melinda the Mental Marvel waits at the end!", 0
.level100 db "Besides being an angel on earth, Melinda is the top scorer in the Challenge--and the president of the Bit Busters.", 0
.level110 db "Chip can't wait to join the Bit Busters! The club's already figured out the school's password and accessed everyone's grades!", 0
.level120 db "If Chip's grades aren't as good as Melinda's, maybe she'll come over to his house and help him study!", 0
.level130 db "'I've made it this far,' Chip thinks. 'Totally fair, with my mega-brain.' Then he starts the next maze. 'Totally unfair!' he yelps.", 0
.level140 db "Groov-u-loids! Chip makes it almost to the end. He's stoked!", 0

s_chipend db "chipend", 0
s_chipend2 db "chipend", 0
s_DLG_COMPLETE db "DLG_COMPLETE", 0
align 2, db 0

; 1370
; sound.asm strings & data

s_MIDI_Error_on_file_s db "MIDI Error on file %s: ", 0
s_None_of_the_MIDI_files_specified___ db "None of the MIDI files specified in entpack.ini were found.", 0

MIDIPlaying             dw 0 ; 13c4
MusicEnabled            dw 1 ; 13c6
SoundEnabled            dw 1 ; 13c8
MusicMenuItemEnabled    dw 0 ; 13ca
SoundMenuItemEnabled    dw 0 ; 13cc
fpSndPlaySound          dd 0 ; 13ce
fpMciSendCommand        dd 0 ; 13d2
fpMciGetErrorString     dd 0 ; 13d6

hmoduleMMSystem dw 0 ; 13da
NumMIDIFiles dw 0 ; 13dc

; 13de

s_MMSYSTEM_DLL db "MMSYSTEM.DLL", 0
s_sndPlaySound db "sndPlaySound", 0
s_mciSendCommand db "mciSendCommand", 0
s_mciGetErrorString db "mciGetErrorString", 0
s_midiOutGetNumDevs db "midiOutGetNumDevs", 0
s_waveOutGetNumDevs db "waveOutGetNumDevs", 0

s_sequencer db "sequencer", 0 ; 143d
EmptyStringForMciSendCommand db 0, 0

s_The_MIDI_Mapper_is_not_available_Continue? db "The MIDI Mapper is not available. Continue?", 0
s_Unknown_Error db "Unknown Error", 0
align 2, db 0

; 1484
; crt.asm data

Var1484 dw 0
crt_hPrevInstance dw 0
crt_hInstance dw 0
crt_lpCmdLine dd 0
crt_nCmdShow dw 0

dw 1, -1, 0, 0
RandomSeed dd 1

s_cFileInfo db "_C_FILE_INFO=", 0

Int0_Save dd 0

; 14ae

dw 0, 0, 0, 0, 0, 0, 0, 0  ; 14ae
Var14BE dw 0
WindowsVersion dw 0
DOSVersion dw 0
        db 2
Var14C5 db 1
        dw 0 ; 14c6
Var14C8 dw 20
        dw 20
        dw 40

; 14ce

Var14CE db   00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00 ; 14ce
        db 0xC1, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00 ; 14e2

Var14F6 dw 0 ; argc
Var14F8 dw 0 ; argv
Var14FA dw 0 ; envp
Var14FC dd Var1500
Var1500 dw 0 ; 1500
Var1502 dw 0
        dw 0 ; 1504
        dw 0 ; 1506
Var1508 dd 0
Var150C dw 0
Var150E dw 0x1000 ; lock for __mymalloc
Var1510 dd 0
        dw 0 ; 1514
Var1516 dw 0
Var1518 dw 0
Var151A dw 0
Var151C dw 0
Var151E dw 0
Var1520 dw 0 ; 1520

%macro dwb 2+
    dw %1
    db %2
%endmacro

NMSG db "<<NMSG>>"
NMSG_Table:
    ;  code  text
    dwb   0, "R6000", 13, 10, "- stack overflow", 13, 10, 0
    dwb   3, "R6003", 13, 10, "- integer divide by 0", 13, 10, 0
    dwb   9, "R6009", 13, 10, "- not enough space for environment", 13, 10, 0
    dwb  18, "R6018", 13, 10, "- unexpected heap error", 13, 10, 0
    dwb  20, "R6020", 13, 10, "- unexpected QuickWin error", 13, 10, 0
    dwb   8, "R6008", 13, 10, "- not enough space for arguments", 13, 10, 0
    dwb  21, "R6021", 13, 10, "- no main procedure", 13, 10, 0
    dwb 252, 13, 10, 0
    dwb 255, "run-time error ", 0
    dwb   2, "R6002", 13, 10, "- floating-point support not loaded", 13, 10, 0
    dwb  -1, 0xff, 0

TempRect dw 0, 0, 0, 0 ; 1674 Temporary space for returning a RECT by value, used by GetTileRect
Var167C dd 0 ; atexit function pointers

; end crt.asm data

; 1680
; miscellaneous

; Near pointer to game state structure
; see structs.asm for field descriptions
GameStatePtr dw 0 ; 1680

; Inventory
BlueKeyCount            dw 0 ; 1682
RedKeyCount             dw 0 ; 1684
GreenKeyCount           dw 0 ; 1686
YellowKeyCount          dw 0 ; 1688

FlipperCount            dw 0 ; 168a
FireBootCount           dw 0 ; 168c
IceSkateCount           dw 0 ; 168e
SuctionBootCount        dw 0 ; 1690

ChipsRemainingCount     dw 0 ; 1692
TimeRemaining           dw 0 ; 1694

TotalScore              dd 0 ; 1696

PasswordPromptPassword  dw 0 ; 169a pointer to decoded password (for password prompt)
PasswordPromptLevel     dw 0 ; 169c level for password prompt

HorizontalPadding       dw 0 ; 169e main window horizontal padding (always 0x20) (seg5.asm)
VerticalPadding         dw 0 ; 16a0 main window vertical padding (0x20 or 8, depending on vertical resolution) (seg5.asm)
SoundArray     times 15 dw 0 ; 16a2 Pointers to sound effect filenames (sound.asm)
                             ;      Sound indices defined in constants.asm
               .end:
HorizontalResolution    dw 0 ; 16c0 horizontal screen resolution in px (seg5.asm)
VerticalResolution      dw 0 ; 16c2 vertical screen resolution in px (seg5.asm)
DigitBitmapData         dd 0 ; 16c4 Far pointer to digit bitmap (digits.asm)
MIDIArray      times 20 dw 0 ; 16c8 Pointers to MIDI filenames (sound.asm)
DigitPtrArray  times 24 dw 0 ; 16f0 Digit image pointers (digits.asm)
               .end:
DigitResourceHandle     dw 0 ; 1720 HGLOBAL (digits.asm)
GameStatePtrCopy        dw 0 ; 1722 copy of GameStatePtr used for deallocation
SavedObj                dw 0 ; 1724 HGDIOBJ previously selected object; restored on exit
fpWaveOutGetNumDevs     dd 0 ; 1726
MainInstance            dw 0 ; 172a HINSTANCE from WinMain
TileBitmapObj           dw 0 ; 172c HGDIOBJ current tile bitmap object
; If the game is running on Windows 3.1 or higher,
; it uses Arial instead of Helv[etica] as its font
; and fiddles with the KeyboardDelay setting.
IsWin31                 dw 0 ; 172e BOOL
fpMidiOutGetNumDevs     dd 0 ; 1730
MainDC                  dw 0 ; 1734 HDC drawing context for all drawing operations on the main window
MCIDeviceID             dw 0 ; 1736 MCIDEVICEID

; 1738

; vim: syntax=nasm

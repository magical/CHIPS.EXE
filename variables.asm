; variables.asm - header file of data segment addresses
;                 to make up for the lack of linking
;
; Generated by genvars.sh

hwndMain                            equ 0x10
hwndBoard                           equ 0x12
hwndInfo                            equ 0x14
hwndCounter                         equ 0x16
hwndCounter2                        equ 0x18
hwndCounter3                        equ 0x1A
hwndInventory                       equ 0x1C
hwndHint                            equ 0x1E
Var22                               equ 0x22
GamePaused                          equ 0x24
hMenu                               equ 0x26
IgnorePasswords                     equ 0x2E
CheatVisible                        equ 0x30
CheatKeys                           equ 0x32
KeyboardDelay                       equ 0x34
LOGFONT                             equ 0x36
LOGFONT.lfHeight                    equ 0x36
LOGFONT.lfWeight                    equ 0x3E
LOGFONT.lfItalic                    equ 0x40
LOGFONT.lfFaceName                  equ 0x48
MessageBoxCaption                   equ 0x68
SystemTimerErrorMsg                 equ 0x7A
NewGamePrompt                       equ 0xA2
NotEnoughMemoryErrorMsg             equ 0x140
FireDeathMessage                    equ 0x176
WaterDeathMessage                   equ 0x1A8
BombDeathMessage                    equ 0x1D2
BlockDeathMessage                   equ 0x1F0
MonsterDeathMessage                 equ 0x214
TimeDeathMessage                    equ 0x234
s_Contents                          equ 0x248
s_How_To_Play                       equ 0x252
s_Commands                          equ 0x25E
IniFileName                         equ 0x268
IniSectionName                      equ 0x274
s_KeyboardDelay                     equ 0x2C6
SoundDefaultArray                   equ 0x312
MidiFileDefaultArray                equ 0x330
PickUpToolSoundKey                  equ 0x336
OpenDoorSoundKey                    equ 0x346
ChipDeathSoundKey                   equ 0x354
LevelCompleteSoundKey               equ 0x363
SocketSoundKey                      equ 0x376
BlockedMoveSoundKey                 equ 0x382
ThiefSoundKey                       equ 0x393
SoundOnSoundKey                     equ 0x39E
PickUpChipSoundKey                  equ 0x3AB
SwitchSoundKey                      equ 0x3BB
SplashSoundKey                      equ 0x3C7
BombSoundKey                        equ 0x3D3
TeleportSoundKey                    equ 0x3DD
TickSoundKey                        equ 0x3EB
ChipDeathByTimeSoundKey             equ 0x3F5
PickUpToolSoundDefault              equ 0x40A
OpenDoorSoundDefault                equ 0x414
ChipDeathSoundDefault               equ 0x41D
LevelCompleteSoundDefault           equ 0x428
SocketSoundDefault                  equ 0x433
BlockedMoveSoundDefault             equ 0x43E
ThiefSoundDefault                   equ 0x447
SoundOnSoundDefault                 equ 0x452
PickUpChipSoundDefault              equ 0x45D
SwitchSoundDefault                  equ 0x468
SplashSoundDefault                  equ 0x471
BombSoundDefault                    equ 0x47C
TeleportSoundDefault                equ 0x485
TickSoundDefault                    equ 0x492
ChipDeathByTimeSoundDefault         equ 0x49D
MidiFileDefault1                    equ 0x4A6
MidiFileDefault2                    equ 0x4B1
MidiFileDefault3                    equ 0x4BC
MainClassName                       equ 0x4C7
BoardClassName                      equ 0x4D1
InfoClassName                       equ 0x4DC
CounterClassName                    equ 0x4E6
InventoryClassName                  equ 0x4F3
HintClassName                       equ 0x502
s_ChipsMenu                         equ 0x50C
MainWindowCaption                   equ 0x516
s_MainClass                         equ 0x527
s_BoardClass                        equ 0x531
s_InfoClass                         equ 0x53C
s_CounterClass1                     equ 0x546
s_CounterClass2                     equ 0x553
s_CounterClass3                     equ 0x560
s_InventoryClass                    equ 0x56D
s_Ooops                             equ 0x57C
s_HintClass                         equ 0x583
s_background                        equ 0x58D
s_Arial1                            equ 0x598
s_Helv1                             equ 0x59E
s_PAUSED                            equ 0x5A3
s_Arial2                            equ 0x5AA
s_Helv2                             equ 0x5B0
s_DLG_GOTO                          equ 0x61A
s_DLG_BESTTIMES                     equ 0x623
CheatMenuText                       equ 0x631
CurrentTick                         equ 0x64E
s_Arial3                            equ 0x661
s_Helv3                             equ 0x667
TileTable                           equ 0x66C
MelindaMessage                      equ 0x90C
ColorMode                           equ 0xA18
HicolorTiles                        equ 0xA1A
LocolorTiles                        equ 0xA22
MonochromeTiles                     equ 0xA2B
DebugModeEnabled                    equ 0xA34
DummyVarForSlideMovement            equ 0xC6C
GreatJobChipMsg                     equ 0xC6E
MelindaHerselfMsg                   equ 0xCA8
YouCompletedNLevelsMsg              equ 0xD44
DecadeMessages                      equ 0xEC2
DecadeMessages.level50              equ 0xED6
DecadeMessages.level60              equ 0xF58
DecadeMessages.level70              equ 0xFCB
DecadeMessages.level80              equ 0x1045
DecadeMessages.level90              equ 0x10C1
DecadeMessages.level100             equ 0x113A
DecadeMessages.level110             equ 0x11AD
DecadeMessages.level120             equ 0x122B
DecadeMessages.level130             equ 0x1291
DecadeMessages.level140             equ 0x1315
Chipend                             equ 0x1352
Chipend2                            equ 0x135A
s_MIDI_Error_on_file_s              equ 0x1370
s_None_of_the_MIDI_files_specified___ equ 0x1388
MusicEnabled                        equ 0x13C6
SoundEnabled                        equ 0x13C8
MusicMenuItemEnabled                equ 0x13CA
SoundMenuItemEnabled                equ 0x13CC
fpSndPlaySound                      equ 0x13CE
fpMciSendCommand                    equ 0x13D2
fpMciGetErrorString                 equ 0x13D6
hmoduleMMSystem                     equ 0x13DA
NumMIDIFiles                        equ 0x13DC
s_MMSYSTEM_DLL                      equ 0x13DE
s_sndPlaySound                      equ 0x13EB
s_mciSendCommand                    equ 0x13F8
s_mciGetErrorString                 equ 0x1407
s_midiOutGetNumDevs                 equ 0x1419
s_waveOutGetNumDevs                 equ 0x142B
s_sequencer                         equ 0x143D
EmptyStringForMciSendCommand        equ 0x1447
s_The_MIDI_Mapper_is_not_available_Continue? equ 0x1449
s_Unknown_Error                     equ 0x1475
GameStatePtr                        equ 0x1680
BlueKeyCount                        equ 0x1682
RedKeyCount                         equ 0x1684
GreenKeyCount                       equ 0x1686
YellowKeyCount                      equ 0x1688
FlipperCount                        equ 0x168A
FireBootCount                       equ 0x168C
IceSkateCount                       equ 0x168E
SuctionBootCount                    equ 0x1690
ChipsRemainingCount                 equ 0x1692
TimeRemaining                       equ 0x1694
TotalScore                          equ 0x1696
SoundArray                          equ 0x16A2
SoundArray.end                      equ 0x16C0
HorizontalResolution                equ 0x16C0
VerticalResolution                  equ 0x16C2
DigitBitmapData                     equ 0x16C4
MIDIArray                           equ 0x16C8
DigitPtrArray                       equ 0x16F0
DigitPtrArray.end                   equ 0x1720
DigitResourceHandle                 equ 0x1720
fpWaveOutGetNumDevs                 equ 0x1726
OurHInstance                        equ 0x172A
IsWin31                             equ 0x172E
fpMidiOutGetNumDevs                 equ 0x1730
MCIDeviceID                         equ 0x1736

; vim: syntax=nasm

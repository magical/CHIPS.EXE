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
InventoryDirty                      equ 0x20
Var22                               equ 0x22
GamePaused                          equ 0x24
hMenu                               equ 0x26
hAccel                              equ 0x28
Var2a                               equ 0x2A
Var2c                               equ 0x2C
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
MIDIKey                             equ 0x286
SoundsKey                           equ 0x28C
HighestLevelKey                     equ 0x294
CurrentLevelKey                     equ 0x2A2
CurrentScoreKey                     equ 0x2B0
ColorKey                            equ 0x2BE
s_2c4                               equ 0x2C4
s_KeyboardDelay                     equ 0x2C6
DataFileName                        equ 0x2D4
NumMidiFilesKey                     equ 0x2DE
SoundKeyArray                       equ 0x2F4
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
s_5b5                               equ 0x5B5
s_5ba                               equ 0x5BA
s_5c9                               equ 0x5C9
s_5ce                               equ 0x5CE
s_5dd                               equ 0x5DD
s_5e0                               equ 0x5E0
s_5e4                               equ 0x5E4
s_5e8                               equ 0x5E8
s_5f0                               equ 0x5F0
s_5f8                               equ 0x5F8
s_602                               equ 0x602
s_605                               equ 0x605
s_610                               equ 0x610
s_612                               equ 0x612
s_DLG_GOTO                          equ 0x61A
s_DLG_BESTTIMES                     equ 0x623
CheatMenuText                       equ 0x631
s_ChipsMenu2                        equ 0x643
CurrentTick                         equ 0x64E
s_infownd                           equ 0x650
s_658                               equ 0x658
s_Arial3                            equ 0x661
s_Helv3                             equ 0x667
TileTable                           equ 0x66C
MelindaMessage                      equ 0x90C
CorruptDataMessage                  equ 0x966
s_98e                               equ 0x98E
sColon                              equ 0x98F
sNoColon                            equ 0x992
s_sss                               equ 0x993
PasswordPromptMessage               equ 0x99A
WrongPasswordMessage                equ 0x9C2
EmptyPasswordMessage                equ 0x9EB
s_DLG_PASSWORD                      equ 0xA06
VarA14                              equ 0xA14
VarA16                              equ 0xA16
ColorMode                           equ 0xA18
HicolorTiles                        equ 0xA1A
LocolorTiles                        equ 0xA22
MonochromeTiles                     equ 0xA2B
DebugModeEnabled                    equ 0xA34
s_You_must_enter_a_level_andor_password equ 0xA36
s_You_must_enter_a_valid_password   equ 0xA5E
s_That_is_not_a_valid_level_number  equ 0xA80
s_No_levels_completed               equ 0xAA2
LevelTimeAndScoreMsg                equ 0xAB7
LevelNotCompletedMsg                equ 0xAD9
s_plural_1                          equ 0xAF2
s_singular_1                        equ 0xAF4
s_You_have_completed_d_levels       equ 0xAF5
s_Your_total_score_is_li_points     equ 0xB14
s_Yowser_First_Try                  equ 0xB34
s_Go_Bit_Buster                     equ 0xB47
s_Finished_Good_Work                equ 0xB56
s_At_last_You_did_it                equ 0xB6B
s_b80                               equ 0xB80
s_Time_Bonus_d                      equ 0xB83
s_Level_Bonus_li                    equ 0xB93
s_Level_Score_li                    equ 0xBA5
s_You_have_established_a_time_record equ 0xBB7
s_plural_2                          equ 0xBEA
s_singular_2                        equ 0xBEC
s_You_beat_the_previous_time_record equ 0xBED
s_plural_3                          equ 0xC1F
s_singular_3                        equ 0xC21
s_You_increased_your_score          equ 0xC22
s_Total_Score_li                    equ 0xC59
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
s_DLG_COMPLETE                      equ 0x1362
s_MIDI_Error_on_file_s              equ 0x1370
s_None_of_the_MIDI_files_specified___ equ 0x1388
Var13c4                             equ 0x13C4
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
Var1484                             equ 0x1484
crt_hPrevInstance                   equ 0x1486
crt_hInstance                       equ 0x1488
crt_lpCmdLine                       equ 0x148A
crt_nCmdShow                        equ 0x148E
RandomSeed                          equ 0x1498
s_cFileInfo                         equ 0x149C
Int0_Save                           equ 0x14AA
Var14BE                             equ 0x14BE
WindowsVersion                      equ 0x14C0
DOSVersion                          equ 0x14C2
Var14C5                             equ 0x14C5
Var14C8                             equ 0x14C8
Var14CE                             equ 0x14CE
Var14F6                             equ 0x14F6
Var14F8                             equ 0x14F8
Var14FA                             equ 0x14FA
Var14FC                             equ 0x14FC
Var1500                             equ 0x1500
Var1502                             equ 0x1502
Var1508                             equ 0x1508
Var150C                             equ 0x150C
Var150E                             equ 0x150E
Var1510                             equ 0x1510
Var1516                             equ 0x1516
Var1518                             equ 0x1518
Var151A                             equ 0x151A
Var151C                             equ 0x151C
Var151E                             equ 0x151E
Var1520                             equ 0x1520
NMSG                                equ 0x1522
NMSG_Table                          equ 0x152A
Var167C                             equ 0x167C
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
PasswordPromptPassword              equ 0x169A
PasswordPromptLevel                 equ 0x169C
HorizontalPadding                   equ 0x169E
VerticalPadding                     equ 0x16A0
SoundArray                          equ 0x16A2
SoundArray.end                      equ 0x16C0
HorizontalResolution                equ 0x16C0
VerticalResolution                  equ 0x16C2
DigitBitmapData                     equ 0x16C4
MIDIArray                           equ 0x16C8
DigitPtrArray                       equ 0x16F0
DigitPtrArray.end                   equ 0x1720
DigitResourceHandle                 equ 0x1720
GameStatePtrCopy                    equ 0x1722
SavedObj                            equ 0x1724
fpWaveOutGetNumDevs                 equ 0x1726
OurHInstance                        equ 0x172A
TileBitmapObj                       equ 0x172C
IsWin31                             equ 0x172E
fpMidiOutGetNumDevs                 equ 0x1730
TileDC                              equ 0x1734
MCIDeviceID                         equ 0x1736

; vim: syntax=nasm

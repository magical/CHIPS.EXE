; crt.asm
EXTERN winflags                      ; 1:10
EXTERN loc_12                        ; 1:12
EXTERN start                         ; 1:1a
EXTERN __nomain                      ; 1:b6
EXTERN atoi                          ; 1:bc
EXTERN atol                          ; 1:c0
EXTERN __aFldiv                      ; 1:110
EXTERN __stubmain                    ; 1:1aa
EXTERN __cinit                       ; 1:1d6
EXTERN exit                          ; 1:2b5
EXTERN __exit                        ; 1:2c3
EXTERN __cexit                       ; 1:2d2
EXTERN __c_exit                      ; 1:2e3
EXTERN __ctermsub                    ; 1:353
EXTERN FUN_1_037C                    ; 1:37c
EXTERN __FF_MSGBANNER                ; 1:390
EXTERN __setargv                     ; 1:3b4
EXTERN __setenvp                     ; 1:536
EXTERN __cintDIV                     ; 1:536
EXTERN __amsg_exit                   ; 1:5cb
EXTERN __catox                       ; 1:60e
EXTERN __aFlmul                      ; 1:662
EXTERN __wcinit                      ; 1:694
EXTERN __wopen                       ; 1:699
EXTERN __fptrap                      ; 1:6a0
EXTERN __NMSG_TEXT                   ; 1:6a6
EXTERN __NMSG_WRITE                  ; 1:6dd
EXTERN __myalloc                     ; 1:71a
EXTERN __growseg                     ; 1:748
EXTERN __incseg                      ; 1:7d4
EXTERN __findlast                    ; 1:83a

; seg2.asm
EXTERN ShowMessageBox                ; 2:0
EXTERN IsCoordOnscreen               ; 2:7a
EXTERN DrawTile                      ; 2:c4
EXTERN UpdateTile                    ; 2:1ca
EXTERN DrawInventoryTile             ; 2:232
EXTERN InvertTile_Unused             ; 2:25a
EXTERN InvalidateTile                ; 2:2b2
EXTERN ScrollViewport                ; 2:306
EXTERN UpdateChip                    ; 2:56e
EXTERN WinMain                       ; 2:628
EXTERN CreateClasses                 ; 2:6c8
EXTERN CreateWindowsAndInitGame      ; 2:8e8
EXTERN ShowDeathMessage              ; 2:b9a
EXTERN ShowHint                      ; 2:c1a
EXTERN HideHint                      ; 2:c7e
EXTERN FUN_2_0cbe                    ; 2:cbe
EXTERN FUN_2_0dc6                    ; 2:dc6
EXTERN Draw3DBorder                  ; 2:f06
EXTERN DrawSolidBorder               ; 2:1006
EXTERN FUN_2_10ce                    ; 2:10ce
EXTERN FUN_2_16fa                    ; 2:16fa
EXTERN FUN_2_176e                    ; 2:176e
EXTERN PauseTimer                    ; 2:17a2
EXTERN UnpauseTimer                  ; 2:17ba
EXTERN PauseGame                     ; 2:17da
EXTERN UnpauseGame                   ; 2:1834
EXTERN PauseMusic                    ; 2:189c
EXTERN UnpauseMusic                  ; 2:18b6
EXTERN GetIniKey                     ; 2:18de
EXTERN GetIniInt                     ; 2:198e
EXTERN StoreIniInt                   ; 2:19ca
EXTERN GetIniLong                    ; 2:1a1c
EXTERN StoreIniLong                  ; 2:1a86
EXTERN GetLevelProgressFromIni       ; 2:1adc
EXTERN SaveLevelProgressToIni        ; 2:1c1c
EXTERN GetAudioPath                  ; 2:1ca0
EXTERN FUN_2_1dae                    ; 2:1dae
EXTERN MenuItemCallback              ; 2:1e28
EXTERN MAINWNDPROC                   ; 2:225c
EXTERN BOARDWNDPROC                  ; 2:274e
EXTERN INFOWNDPROC                   ; 2:2866
EXTERN COUNTERWNDPROC                ; 2:296a
EXTERN INVENTORYWNDPROC              ; 2:2a9a
EXTERN HINTWNDPROC                   ; 2:2bbe

; logic.asm
EXTERN FindMonster                   ; 3:0
EXTERN FindSlipper                   ; 3:58
EXTERN TurnLeft                      ; 3:b0
EXTERN TurnRight                     ; 3:116
EXTERN TurnAround                    ; 3:17c
EXTERN GrowArray                     ; 3:1a4
EXTERN NewMonster                    ; 3:228
EXTERN DeleteMonster                 ; 3:3b4
EXTERN DeleteMonsterAt               ; 3:45e
EXTERN SetTileDir                    ; 3:486
EXTERN GetMonsterDir                 ; 3:4d8
EXTERN InitBoard                     ; 3:54c
EXTERN RandInt                       ; 3:72e
EXTERN MonsterLoop                   ; 3:74e
EXTERN NewSlipper                    ; 3:1250
EXTERN DeleteSlipperAt               ; 3:12be
EXTERN FindSlipperAt                 ; 3:1396
EXTERN SlipLoop                      ; 3:13de
EXTERN ResetInventory                ; 3:1734
EXTERN PickUpKeyOrBoot               ; 3:1770
EXTERN CanOpenDoor                   ; 3:1804
EXTERN HaveBootsForTile              ; 3:187c
EXTERN CheckPanelWalls               ; 3:1934
EXTERN ChipCanEnterTile              ; 3:1a56
EXTERN BlockCanEnterTile             ; 3:1ca4
EXTERN MonsterCanEnterTile           ; 3:1d4a
EXTERN PressTankButton               ; 3:1e6a
EXTERN PressToggleButton             ; 3:1fac
EXTERN FindTrapSpan                  ; 3:206c
EXTERN PressTrapButton               ; 3:211a
EXTERN EnterTrap                     ; 3:21aa
EXTERN FindTrapByButton              ; 3:2270
EXTERN FindTrap                      ; 3:22be
EXTERN AddTrap_Unused                ; 3:2318
EXTERN DeleteTrap_Unused             ; 3:23c6
EXTERN PressCloneButton              ; 3:2442
EXTERN FindCloneMachine              ; 3:260e
EXTERN AddCloneMachine_Unused        ; 3:265c
EXTERN DeleteCloneMachine_Unused     ; 3:26f6
EXTERN EnterTeleport                 ; 3:276a
EXTERN FindTeleport                  ; 3:2910
EXTERN AddTeleport                   ; 3:295e
EXTERN DeleteTeleport_Unused         ; 3:29dc
EXTERN GetTileImagePos               ; 3:2a3e

; seg4.asm
EXTERN GetTileRect                   ; 4:0
EXTERN ResetLevelData                ; 4:5e
EXTERN ReadLevelDataOrDie            ; 4:d8
EXTERN UpdateWindowTitle             ; 4:134
EXTERN UpdateNextPrevMenuItems       ; 4:1a0
EXTERN ResetTimerAndChipCount        ; 4:1fc
EXTERN FreeGameLists                 ; 4:240
EXTERN ClearGameState                ; 4:320
EXTERN FUN_4_0356                    ; 4:356
EXTERN ExpandTilesRLE                ; 4:5fc
EXTERN DecodePassword                ; 4:6b0
EXTERN DecodeLevelFields             ; 4:6d8
EXTERN FUN_4_0950                    ; 4:950
EXTERN SkipNFields                   ; 4:9b4
EXTERN FUN_4_0a0e                    ; 4:a0e
EXTERN ReadLevelData                 ; 4:a56
EXTERN FUN_4_0c3a                    ; 4:c3a
EXTERN GetLevelPassword              ; 4:d58
EXTERN TryIniPassword                ; 4:e48
EXTERN FUN_4_0eaa                    ; 4:eaa
EXTERN PASSWORDMSGPROC               ; 4:1016
EXTERN FUN_4_115c                    ; 4:115c

; seg5.asm
EXTERN InitGraphics                  ; 5:
EXTERN LoadTiles                     ; 5:112
EXTERN FreeTiles                     ; 5:17c

; seg6.asm
EXTERN GOTOLEVELMSGPROC              ; 6:0
EXTERN BESTTIMESMSGPROC              ; 6:18e
EXTERN COMPLETEMSGPROC               ; 6:3c6

; movement.asm
EXTERN DoTick                        ; 7:0
EXTERN SlideMovement                 ; 7:636
EXTERN DrawStretchedTile             ; 7:966
EXTERN EndGame                       ; 7:a74
EXTERN EndLevel                      ; 7:cca
EXTERN MoveBlock                     ; 7:dae
EXTERN MoveChip                      ; 7:1184
EXTERN MoveMonster                   ; 7:18da

; sound.asm
EXTERN InitSound                     ; 8:0
EXTERN TeardownSound                 ; 8:e6
EXTERN StartMIDI                     ; 8:110
EXTERN FUN_8_022a                    ; 8:22a
EXTERN ShowMIDIError                 ; 8:25c
EXTERN StopMIDI                      ; 8:2d4
EXTERN FUN_8_0308                    ; 8:308
EXTERN InitAudioFiles                ; 8:4a0
EXTERN PlaySoundEffect               ; 8:56c
EXTERN FreeAudioFiles                ; 8:5b8

; digits.asm
EXTERN FindBitmap                    ; 9:
EXTERN BitmapSize                    ; 9:28
EXTERN LoadDigits                    ; 9:4e
EXTERN FreeDigits                    ; 9:bc
EXTERN DrawDigit                     ; 9:ea


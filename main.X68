*-----------------------------------------------------------
* Title      : Main
* Written by : Albert Castrejon
* Date       : 5/30/25
* Description: Main file that will run all of the game loops
*-----------------------------------------------------------
    ORG    $1000
    
    INCLUDE     "Equates.X68"
    
START:
    jsr     INITIALIZE_GAME
    
RUN_TITLE_LOOP:
    jsr     TITLE_LOOP
    cmp.b   #1, (ReadyForGame)
    bne     RUN_TITLE_LOOP                      ; Branch if not ready to start game (no song selected)
     
REPLAY_SONG:
    jsr     INITIALIZE_SOUNDS 
    jsr     LOAD_LEVEL
    
RUN_MAIN_GAME_LOOP: 
    jsr     GET_DELTA_TIME
    jsr     LEVEL_LOOP
    
    ; Ensure Delta time
    move.l  #DELAY_TASK, d0
    moveq.l #1, d1
    trap    #15
    
    cmp.b   #1, (SongFinished)
    bne     RUN_MAIN_GAME_LOOP                  ; Branch if song not finished
    
    cmp.l   #1, (SongFailed)
    beq     RUN_END_GAME_LOOP                   ; Branch and skip if song failed
    
    ; Start the song ending sequence
    jsr     SONG_ENDING_SEQUENCE
    
    ; Display Win sticker
    move.l  #WIN_LOSS_STICKER_SCREEN_POS, -(sp) ; Screen start Position
    move.w  #WIN_LOSS_STICKER_HEIGHT, -(sp)     ; Chunk height
    move.w  #WIN_LOSS_STICKER_WIDTH, -(sp)      ; Chunk width
    move.l  #TOP_LEFT, -(sp)                    ; Chunk start Position
    move.l  #WinSticker, -(sp)                  ; Bitmap Address 
    jsr     DRAW_BITMAP_CHUNK
    lea     BITMAP_CHUNK_PARAM_SIZE(sp), sp     ; Fix stack
    
    ; Display Win banner
    move.l  #END_BANNER_POS, -(sp)              ; Screen start Position
    move.w  #END_BANNER_HEIGHT, -(sp)           ; Chunk height
    move.w  #END_BANNER_WIDTH, -(sp)            ; Chunk width
    move.l  #TOP_LEFT, -(sp)                    ; Chunk start Position
    move.l  #WinBanner, -(sp)                   ; Bitmap Address 
    jsr     DRAW_BITMAP_CHUNK
    lea     BITMAP_CHUNK_PARAM_SIZE(sp), sp     ; Fix stack
    
    ;Update Screen
    moveq.l #PAINT_BUFFER_SCREEN_TASK, d0
    trap    #15
    
RUN_END_GAME_LOOP:
    jsr     END_GAME_LOOP
    
    cmp.l   #1, (RetrySong)
    beq     REPLAY_SONG                         ; Branch if replay song selected
    cmp.l   #1, (LevelSelect)
    beq     START                               ; Branch if song select selected
    cmp.l   #0, (ExitGame)
    beq     RUN_END_GAME_LOOP                   ; Branch if Exit game NOT selected
    
    
    ; Load Exit string
    move.l  #CLEAR_SCREEN_TASK, d0
    move.l  #CLEAR_SCREEN_CODE, d1
    trap    #15
    
    SIMHALT
    
    
    
    INCLUDE     "InitGame.X68"
    INCLUDE     "TitleGameLoop.X68"
    INCLUDE     "SoundFileInit.X68"
    INCLUDE     "InitLevel.X68"
    INCLUDE     "LevelGameLoop.X68"
    INCLUDE     "EndSongManager.X68"
    INCLUDE     "ScoreManager.X68"
    INCLUDE     "GatoPhysicsHandler.X68"
    INCLUDE     "SystemClock.X68"
    INCLUDE     "RandomNumberGenerator.X68"
    INCLUDE     "BitmapChunker.X68"
    INCLUDE     "RoundingDivide.X68"
    INCLUDE     "SevenSegmentDisplay.X68"
    INCLUDE     "PerformanceStates.X68"
    
    

; Time Variables
DeltaTime                   ds.l    1
PreviousTime                ds.l    1
TimeElapsed                 dc.l    0

; Flags
ReadyForGame                dc.b    0
SongFinished                dc.b    0
HighscoreAchieved           dc.l    0
SongFailed                  dc.l    0
RetrySong                   dc.l    0
LevelSelect                 dc.l    0
ExitGame                    dc.l    0
InputFlags                  DCB.B   5,0
                            ds.w    0                            
HeldInputs                  DCB.B   5,0

; Sound file Error message                     
Error_WrongSOUNDSignature   dc.b    'Incorrect MIDI File Signature, SOND Required.', 0

; Sound Effects
CassetteTapeStart           dc.b    'SoundFX/CassetteTapeStart.wav',0
CassetteTapeButton          dc.b    'SoundFX/CassetteTapeButton.wav',0
CassetteTapeRestart         dc.b    'SoundFX/CassetteTapeRestart.wav',0
CassetteTapeEject           dc.b    'SoundFX/CassetteTapeEject.wav',0
PencilWrite                 dc.b    'SoundFX/PencilWrite.wav',0
                            
MissedNoteFXString          dc.b    'SoundFX/MissSound.wav',0
Overstrum1String            dc.b    'SoundFX/Overstrum1.wav',0
Overstrum2String            dc.b    'SoundFX/Overstrum2.wav',0
Overstrum3String            dc.b    'SoundFX/Overstrum3.wav',0
Overstrum4String            dc.b    'SoundFX/Overstrum4.wav',0
Overstrum5String            dc.b    'SoundFX/Overstrum5.wav',0
Overstrum6String            dc.b    'SoundFX/Overstrum6.wav',0
OverstrumSounds             dc.l    Overstrum1String, Overstrum2String, Overstrum3String
                            dc.l    Overstrum4String, Overstrum5String, Overstrum6String

; Song name strings
DreamsName                  dc.b    'Dreams By: Fleetwood Mac',0
ParalyzerName               dc.b    'Paralyzer By: Finger Eleven',0
PonderTheNightName          dc.b    'Ponder The Night By: Albert',0     
FreeBirdName                dc.b    'Free Bird By: Lynyrd Skynyrd',0    
SongNames                   dc.l    PonderTheNightName, DreamsName, ParalyzerName, FreeBirdName

; Song path strings
DreamsString                dc.b    'Music/Dreams.wav',0
ParalyzerString             dc.b    'Music/Paralyzer.wav',0
PonderTheNightString        dc.b    'Music/PonderTheNight.wav',0  
FreeBirdString              dc.b    'Music/FreeBird.wav',0                        
SongStrings                 dc.l    PonderTheNightString, DreamsString, ParalyzerString, FreeBirdString                 

; Song Sound files
DreamsSound                 INCBIN  "Music/Dreams.SOUND"
                            ds.w    0
ParalyzerSound              INCBIN  "Music/Paralyzer.SOUND"
                            ds.w    0
PonderTheNightSound         INCBIN  "Music/PonderTheNight.SOUND"  
                            ds.w    0
FreeBirdSound               INCBIN  "Music/FreeBird.SOUND"                     
SongSounds                  dc.l    PonderTheNightSound, DreamsSound, ParalyzerSound, FreeBirdSound

; Index for the currently hovered song on main menu
CurrentChoiceIndex          dc.l    0

; Song to load when picked in main menu
ChosenSong                  ds.l    1
ChosenSound                 ds.l    1
     
; Note spawn time variables/tables                       
SongLane1Timings            ds.b    (SongLane1Timings-PonderThenightSound)
CurrentLane1Timing          dc.l    SongLane1Timings

SongLane2Timings            ds.b    (SongLane1Timings-PonderThenightSound)
CurrentLane2Timing          dc.l    SongLane2Timings

SongLane3Timings            ds.b    (SongLane1Timings-PonderThenightSound)
CurrentLane3Timing          dc.l    SongLane3Timings

SongLane4Timings            ds.b    (SongLane1Timings-PonderThenightSound)
CurrentLane4Timing          dc.l    SongLane4Timings

SongLane5Timings            ds.b    (SongLane1Timings-PonderThenightSound)
CurrentLane5Timing          dc.l    SongLane5Timings

SongLaneTimingTable         dc.l    0, SongLane1Timings, SongLane2Timings, SongLane3Timings, SongLane4Timings, SongLane5Timings
CurrentLaneTimings          dc.l    CurrentLane1Timing, CurrentLane2Timing
                            dc.l    CurrentLane3Timing, CurrentLane4Timing, CurrentLane5Timing

; Gameplay Variables                     
TotalNotes                      ds.l    1
NoteSpawnOffsetTime             ds.l    1
NoteSpeedPixelCentiSecond       ds.l    1
                            
CurrentCombo                    dc.l    0

ProgressSpeedPixelCentiSecond   ds.l    1
ProgressBarFillHeightPos        dc.l    PROGRESS_BAR_BOTTOM_Y<<FIXED_POINT_BITS

PlayAreaBoarderColor            dc.l    DECENT_COLOR

; Note Position variables/tables
Lane1NotePosTable           DCB.l   ((SongLane1Timings-PonderThenightSound)/4),NOTE_SPAWN_Y<<FIXED_POINT_BITS
OldestLane1NoteOffset       dc.l    0
Lane1CurrentNote            dc.l    Lane1NotePosTable
Lane1CurrentNoteIndex       dc.l    -1

Lane2NotePosTable           DCB.l   ((SongLane1Timings-PonderThenightSound)/4),NOTE_SPAWN_Y<<FIXED_POINT_BITS
OldestLane2NoteOffset       dc.l    0
Lane2CurrentNote            dc.l    Lane2NotePosTable
Lane2CurrentNoteIndex       dc.l    -1

Lane3NotePosTable           DCB.l   ((SongLane1Timings-PonderThenightSound)/4),NOTE_SPAWN_Y<<FIXED_POINT_BITS
OldestLane3NoteOffset       dc.l    0
Lane3CurrentNote            dc.l    Lane3NotePosTable
Lane3CurrentNoteIndex       dc.l    -1

Lane4NotePosTable           DCB.l   ((SongLane1Timings-PonderThenightSound)/4),NOTE_SPAWN_Y<<FIXED_POINT_BITS
OldestLane4NoteOffset       dc.l    0
Lane4CurrentNote            dc.l    Lane4NotePosTable
Lane4CurrentNoteIndex       dc.l    -1

Lane5NotePosTable           DCB.l   ((SongLane1Timings-PonderThenightSound)/4),NOTE_SPAWN_Y<<FIXED_POINT_BITS
OldestLane5NoteOffset       dc.l    0
Lane5CurrentNote            dc.l    Lane5NotePosTable
Lane5CurrentNoteIndex       dc.l    -1

LanePosTables               dc.l    Lane1NotePosTable, Lane2NotePosTable, Lane3NotePosTable, Lane4NotePosTable, Lane5NotePosTable

OldestLaneNotes             dc.l    OldestLane1NoteOffset, OldestLane2NoteOffset
                            dc.l    OldestLane3NoteOffset, OldestLane4NoteOffset, OldestLane5NoteOffset
                            
LaneCurrentNotes            dc.l    Lane1CurrentNote, Lane2CurrentNote
                            dc.l    Lane3CurrentNote, Lane4CurrentNote, Lane5CurrentNote
                            
LaneCurrentNoteIndexs       dc.l    Lane1CurrentNoteIndex, Lane2CurrentNoteIndex
                            dc.l    Lane3CurrentNoteIndex, Lane4CurrentNoteIndex, Lane5CurrentNoteIndex
                            
ExitMessageString           dc.b    'Couldn',APOSTROPHE,'t Handle The Heat Huh?',0 
                            dc.w    0

; Bitmaps
LevelBackground             INCBIN  "Bitmaps/Level.bmp"
TitleImage                  INCBIN  "Bitmaps/Title.bmp"

LossSticker                 INCBIN  "Bitmaps/LossSticker.bmp"
WinSticker                  INCBIN  "Bitmaps/WinSticker.bmp"
    
GatoAsleep                  INCBIN  "Bitmaps/GatoAsleep.bmp"
GatoMad                     INCBIN  "Bitmaps/MadGato.bmp"

LossBanner                  INCBIN  "Bitmaps/SongFailed.bmp"
WinBanner                   INCBIN  "Bitmaps/WinBanner.bmp"

DifficultySkull             INCBIN  "Bitmaps/DifficultySkull.bmp"



    END    START














































*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

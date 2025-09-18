*-----------------------------------------------------------
* Title      : End Song Manager
* Written by : Albert Castrejon
* Date       : 6/16/25
* Description: Handles the end state of a song
*-----------------------------------------------------------

; Displays all of the song stats
SONG_ENDING_SEQUENCE:
    ; Display stats window ----------------------------------------------------
    move.l  #SET_PEN_COLOR_TASK, d0
    move.l  #0, d1
    trap    #15
    move.l  #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15
    move.l  #SET_PEN_WIDTH_TASK, d0
    move.l  #3, d1
    trap    #15

    move.l  #DRAW_RECT_TASK, d0
    move.l  #(SCREEN_WIDTH/2-(STATS_OUTER_BOX_WIDTH/2)), d1
    move.l  #(SCREEN_HEIGHT/2-(STATS_OUTER_BOX_HEIGHT/2)), d2
    move.l  #(SCREEN_WIDTH/2+(STATS_OUTER_BOX_WIDTH/2)), d3
    move.l  #(SCREEN_HEIGHT/2+(STATS_OUTER_BOX_HEIGHT/2)), d4
    trap    #15
    
    move.l  #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #0, d1
    trap    #15
    move.l  #DRAW_RECT_TASK, d0
    move.l  #(SCREEN_WIDTH/2-(STATS_INNER_BOX_WIDTH/2)), d1
    move.l  #(SCREEN_HEIGHT/2-(STATS_OUTER_BOX_HEIGHT/2)+STATS_BOXES_TOP_PADDING), d2
    move.l  #(SCREEN_WIDTH/2+(STATS_INNER_BOX_WIDTH/2)), d3
    move.l  d1, d4
    add.l   #STATS_INNER_BOX_HEIGHT, d4
    trap    #15
    ; Display Info strings ----------------------------------------------------

    ; Set font
    move.l  #SET_FONT_PROPERTIES_TASK, d0
    move.l  #STATS_FONT_COLOR, d1
    move.l  #STATS_INNER_FONT_STYLE, d2
    trap    #15
    
    
    ; Display stat strings with their corrasponding number --------------------
    move.l  #0, d7
    lea     StatStrings, a2
    lea     Stats, a3
    
    
    move.l  #STATS_INNER_TEXT_Y, d5
    move.w  #((STATS_INNER_NUMBER_X<<BITS_IN_BYTE)+STATS_INNER_NUMBER_Y), d6
DISPLAY_STATS:
    
    ; Display stat string
    move.l  #PRINT_STRING_PIXEL_POS_TASK, d0
    move.l  #(STATS_INNER_TEXT_X+STATS_INNER_TEXT_PADDING), d1
    move.l  d5, d2
    move.l  (a2), a1
    trap    #15
    
    ; Display stat number
    move.l  #SET_CURSOR_TASK, d0
    move.w  d6, d1
    trap    #15
    move.l  #PRINT_SIGNED_NUMBER_TASK, d0
    move.l  (a3), a4
    move.l  (a4), d1
    move.l  #STATS_INNER_NUMBER_COLUMNS, d2
    trap    #15
    
    
    add.l   #BYTES_IN_LONG, a2
    add.l   #BYTES_IN_LONG, a3
    add.l   #1, d7
    
    ; Update Y string value
    add.l   #STATS_INNER_TEXT_LINE_SIZE, d5
    
    ; Updata Y number value
    add.l   #STATS_INNER_NUMBER_Y_OFFSET, d6
    
    cmp.l   #STAT_STRING_AMOUNT, d7
    blt     DISPLAY_STATS
    
    ; Display End Song options ------------------------------------------------
    move.l  #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15
    move.l  #SET_FONT_PROPERTIES_TASK, d0
    move.l  #STATS_FONT_COLOR, d1
    move.l  #STATS_OUTER_FONT_STYLE, d2
    trap    #15
    ; Display Replay String
    move.l  #PRINT_STRING_PIXEL_POS_TASK, d0
    lea     ReplayString, a1
    move.l  #(STATS_OUTER_TEXT_X), d1
    move.l  #(STATS_OUTER_TEXT_Y), d2
    trap    #15
    ; Display Level Select String
    move.l  #PRINT_STRING_PIXEL_POS_TASK, d0
    lea     LevelSelectString, a1
    move.l  #(STATS_OUTER_TEXT_X+LEVEL_SELECT_OFFSET), d1
    move.l  #(STATS_OUTER_TEXT_Y), d2
    trap    #15
    ; Display Exit game String
    move.l  #PRINT_STRING_PIXEL_POS_TASK, d0
    lea     ExitGameString, a1
    move.l  #(STATS_OUTER_TEXT_X+EXIT_GAME_OFFSET), d1
    move.l  #(STATS_OUTER_TEXT_Y), d2
    trap    #15
    
    ; Display completion percent and high score message -----------------------
    moveq.l #0, d3
    
    move.l  (EndNotesHit), d0
    move.l  (EndTotalNotes), d1
    
    ; (Notes hit * 100) / Total notes
    mulu    #100, d0
    divu    d1, d0                      ; Percentage of song complete
    swap    d0
    move.w  #0, d0
    swap    d0
    
    ; Get the ones place
    divu    #10, d0
    swap    d0
    move.w  d0, d1                          ; Ones place -> d1
    move.w  #0, d0
    swap    d0

    ; Get the Hundreds and tens place
    divu    #10, d0
    move.w  d0, d3                          ; Hundreds place -> d3
    swap    d0
    move.w  d0, d2                          ; Tens place -> d2
    
    
    ; Create percentage value string
    lea     ReportCompletionString, a0
    add.l   #COMPLETION_PERCENT_OFFSET, a0
    
    add.l   #START_OF_ASCII_NUMBERS, d3
    move.b  d3, (a0)+                       ; Push hundreds place to string
    add.l   #START_OF_ASCII_NUMBERS, d2
    move.b  d2, (a0)+                       ; Push tens place to string
    add.l   #START_OF_ASCII_NUMBERS, d1
    move.b  d1, (a0)+                       ; Push ones place to string
    
    move.l  #PRINT_STRING_PIXEL_POS_TASK, d0
    lea     ReportCompletionString, a1      ; Display built completion string
    move.l  #COMPLETION_TEXT_X, d1
    move.l  #COMPLETION_TEXT_Y, d2
    trap    #15
    
    ; Output (HighscoreAchieved) - Flag set to 1 if a high score percent was set
    jsr     SAVE_SONG_INFORMATION           ; Save completion percent if higher
    
    cmp.l   #1, (HighscoreAchieved)
    bne     SKIP_DISPLAY_HIGHSCORE_MESSAGE
    
    move.l  #PRINT_STRING_PIXEL_POS_TASK, d0
    lea     HighScoreString, a1
    move.l  #HIGHSCORE_TEXT_X, d1
    move.l  #HIGHSCORE_TEXT_Y, d2
    trap    #15
    
SKIP_DISPLAY_HIGHSCORE_MESSAGE
    ; Reset fill color
    move.l  #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #0, d1
    trap    #15
    
    
    jsr     RESET_LEVEL_DATA
    
    ; Wait for a small amount to prevent clicking an option right after play
    move.l  #DELAY_TASK, d0
    move.l  #25, d1
    trap    #15
    
    rts
    
    ; Loop handing actions during stat report
END_GAME_LOOP:
    ; Get Inputs
    moveq.l #KEY_INPUT_TASK, d0
    move.l  #LEVEL_TARGET_INPUTS, d1
    trap    #15
    
    jsr     PROCESS_END_INPUTS

    rts
    
    
PROCESS_END_INPUTS:
    move.l  (HeldInputs), d0
    move.l  d1, (HeldInputs)                ; Add all bits currently pressed to held inputs flag
    not.l   d0                              ; NOT all bits 
    and.l   d0, d1                          ; Remove all inputs held down creating OnPress behavior

    
    btst.l  #ONE_PRESSED_BIT_OFFSET, d1       ; Compares '1' bit with 0
    beq     ONE_NOT_PRESSED_END               ; Branch if '1' not pressed '1' bit == 0
   
    move.l  #1, (RetrySong)
    
    ; Play button sound
    move.l  #PLAY_SOUND_DIRECTX_TASK, d0
    lea     CassetteTapeRestart, a1
    trap    #15
    
ONE_NOT_PRESSED_END:
    btst.l  #TWO_PRESSED_BIT_OFFSET, d1       ; Compares '2' bit with 0
    beq     TWO_NOT_PRESSED_END               ; Branch if '2' not pressed '2' bit == 0

    move.l  #1, (LevelSelect)
    
    ; Play button sound
    move.l  #PLAY_SOUND_DIRECTX_TASK, d0
    lea     CassetteTapeEject, a1
    trap    #15

TWO_NOT_PRESSED_END:
    btst.l  #THREE_PRESSED_BIT_OFFSET, d1       ; Compares '3' bit with 0
    beq     THREE_NOT_PRESSED_END               ; Branch if '3' not pressed '3' bit == 0
    
    move.l  #1, (ExitGame)

THREE_NOT_PRESSED_END:
    rts
    
    
; Resets all variables to be ready for use for retrys and back to song selection
RESET_LEVEL_DATA:
    move.l  #0, (TimeElapsed)
    
    move.b  #0, (SongFinished)
    move.l  #0, (RetrySong)
    move.l  #0, (LevelSelect)
    move.l  #0, (ExitGame)             
    move.b  #0, (ReadyForGame)
                            
    move.l  #SongLane1Timings, (CurrentLane1Timing)
    move.l  #SongLane2Timings, (CurrentLane2Timing)
    move.l  #SongLane3Timings, (CurrentLane3Timing)
    move.l  #SongLane4Timings, (CurrentLane4Timing)
    move.l  #SongLane5Timings, (CurrentLane5Timing) 
    
    lea     SongLaneTimingTable, a0
    add.l   #4, a0
    ; Reset to begining of timing table
    move.l  #SongLane1Timings, (a0)
    add.l   #4, a0
    move.l  #SongLane2Timings, (a0)
    add.l   #4, a0
    move.l  #SongLane3Timings, (a0)
    add.l   #4, a0
    move.l  #SongLane4Timings, (a0)
    add.l   #4, a0
    move.l  #SongLane5Timings, (a0)
                               
    move.l  #DECENT_COLOR, (PlayAreaBoarderColor)
    
    move.l  #0, (OldestLane1NoteOffset)
    move.l  #Lane1NotePosTable, (Lane1CurrentNote)
    move.l  #-1, (Lane1CurrentNoteIndex)
    
    move.l  #0, (OldestLane2NoteOffset)
    move.l  #Lane2NotePosTable, (Lane2CurrentNote)
    move.l  #-1, (Lane2CurrentNoteIndex)

    move.l  #0, (OldestLane3NoteOffset)
    move.l  #Lane3NotePosTable, (Lane3CurrentNote)
    move.l  #-1, (Lane3CurrentNoteIndex)

    move.l  #0, (OldestLane4NoteOffset)
    move.l  #Lane4NotePosTable, (Lane4CurrentNote)
    move.l  #-1, (Lane4CurrentNoteIndex)

    move.l  #0, (OldestLane5NoteOffset)
    move.l  #Lane5NotePosTable, (Lane5CurrentNote)
    move.l  #-1, (Lane5CurrentNoteIndex)
    
    move.l  #0, (PerformancePositiveModifier)
    move.l  #0, (PerformanceNegativeModifier)
    move.l  #PERFORMANCE_DECENT, (CurrentPerformance)
    move.l  #(PERFORMANCE_STATE_SCORE_SIZE*PERFORMANCE_DECENT), (PerformanceScore)
    
    move.l  #0, (HighscoreAchieved)
    
    move.l  #0, (EndTotalNotes)
    move.l  #0, (EndNotesHit)
    move.l  #0, (EndNotesMissed)
    move.l  #0, (EndBestCombo)
    move.l  #0, (EndOverstrums)
    
    ; reset cursor
    move.l  #SET_CURSOR_TASK, d0
    move.l  #0, d1
    trap    #15
    
    ; Reset Note positions
    move.l  #0, d0
NEXT_NOTE_POSITION_TABLE:    
    lea     LanePosTables, a0
    lea     (a0, d0), a0
    move.l  (a0), a0
    
    lea     OldestLaneNotes, a1
    lea     (a1, d0), a1
    move.l  (a1), a1
RESET_NOTE_POSITIONS:
    move.l  #(NOTE_SPAWN_Y<<FIXED_POINT_BITS), (a0)+
    cmp.l   a1, a0
    blt     RESET_NOTE_POSITIONS
    add.l   #4, d0
    cmp.l   #16, d0
    ble     NEXT_NOTE_POSITION_TABLE
    
    
    ; Reset note spawn timings
    move.l  #4, d0
NEXT_LANE_TIMING_TABLE:    
    lea     SongLaneTimingTable, a0
    lea     (a0, d0), a0
    move.l  (a0), a0
    
    lea     CurrentLaneTimings, a1
    lea     (a1, d0), a1
    sub.l   #4, a1
    move.l  (a1), a1
RESET_LANE_TIMING:
    move.b  #$FF, (a0)+
    cmp.l   a1, a0
    blt     RESET_LANE_TIMING    
    add.l   #4, d0
    cmp.l   #20, d0
    ble     NEXT_LANE_TIMING_TABLE

    move.l  #0, (CurrentCombo)

    move.l  #(PROGRESS_BAR_BOTTOM_Y<<FIXED_POINT_BITS), (ProgressBarFillHeightPos)


    rts

    
EndTotalNotes           dc.l 0
EndNotesHit             dc.l 0
EndNotesMissed          dc.l 0
EndBestCombo            dc.l 0
EndOverstrums           dc.l 0
Stats                   dc.l EndTotalNotes, EndNotesHit, EndNotesMissed
                        dc.l EndBestCombo, EndOverstrums

TotalNotesString        dc.b 'Total Notes',0
NotesHitString          dc.b 'Notes Hit',0
NotesMissedString       dc.b 'Notes Missed',0
BestComboString         dc.b 'Best Combo',0
OverstrumsString        dc.b 'Overstrums',0
StatStrings             dc.l TotalNotesString, NotesHitString, NotesMissedString
                        dc.l BestComboString, OverstrumsString

HighScoreString         dc.b 'NEW HIGH SCORE!!!',0
ReportCompletionString  dc.b 'Note Completion -    %',0
ReplayString            dc.b '1:Replay',0
LevelSelectString       dc.b '2:Song Select',0
ExitGameString          dc.b '3:Exit Game',0
                        ds.w 0








*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

*-----------------------------------------------------------
* Title      : Level Game Loop
* Written by : Albert Castrejon
* Date       : 5/30/25
* Description: Controls the game loop that handles the main ryhthm game
*-----------------------------------------------------------


LEVEL_LOOP:

    ;Update Time Elapsed
    move.l  (DeltaTime), d0
    add.l   d0, (TimeElapsed)

    ; Poll for 1, 2, 3, 4 inputs
    moveq.l #KEY_INPUT_TASK, d0
    move.l  #LEVEL_TARGET_INPUTS, d1
    trap    #15
    
    move.l  (HeldInputs), d0
    move.l  d1, (HeldInputs)                ; Add all bits currently pressed to held inputs flag
    not.l   d0                              ; NOT all bits 
    and.l   d0, d1                          ; Remove all inputs held down creating OnPress behavior
    move.l  d1, (InputFlags)                ; Add inputs to input flags
    
    ; Poll for 5 input
    moveq.l #KEY_INPUT_TASK, d0
    move.l  #FIVE_PRESSED_INPUT, d1
    trap    #15
    
    lea     HeldInputs, a0
    add.l   #4, a0
    move.b  (a0), d0
    move.b  d1, (a0)                        ; Add all bits currently pressed to held inputs flag
    not.b   d0                              ; NOT all bits
    and.b   d0, d1                          ; Remove all inputs held down creating OnPress behavior
    
    lea     InputFlags, a0
    add.l   #4, a0
    move.b  d1, (a0)                        ; Add inputs to input flag in 5th position
    
    ; Input d6: lane to check collision
    moveq.l #1, d6
    jsr     PROCESS_INPUTS
    moveq.l #2, d6
    jsr     PROCESS_INPUTS
    moveq.l #3, d6
    jsr     PROCESS_INPUTS
    moveq.l #4, d6
    jsr     PROCESS_INPUTS
    moveq.l #5, d6
    jsr     PROCESS_INPUTS
    
    ; Check song finished flag
    cmp.b   #1, (SongFinished)
    beq     FINISH_LEVEL_LOOP               ; Branch and skip if song is finished ~ No more notes
    
    jsr     DRAW_PLAY_AREA_STATIC_ELEMENTS
    
    ; Check total notes remaining
    cmp.l   #0, (TotalNotes)
    bne     SKIP_SET_FINISH_FLAG            ; Branch and skip if notes still remaining
    move.b  #1, (SongFinished)
    
SKIP_SET_FINISH_FLAG:
    
    ; Get note speed * delta time -> d7
    move.l  (NoteSpeedPixelCentiSecond), d7
    move.l  (DeltaTime), d1
    mulu    d1, d7
    
    ; Draw notes for all lanes
    moveq.l #1, d6
    jsr     DRAW_NOTES
    moveq.l #2, d6
    jsr     DRAW_NOTES
    moveq.l #3, d6
    jsr     DRAW_NOTES
    moveq.l #4, d6
    jsr     DRAW_NOTES
    moveq.l #5, d6
    jsr     DRAW_NOTES
    
    jsr     UPDATE_PROGRESS_BAR
    
    ;Update Screen
    moveq.l #PAINT_BUFFER_SCREEN_TASK, d0
    trap    #15
    
    
    
FINISH_LEVEL_LOOP:
    rts

 
    ; Input d6 - Target lane to check collisions for
PROCESS_INPUTS:
    cmp.b   #1, (SongFinished)
    beq     FINISH_COLLISION_CHECK          ; Skip if song finished
    sub.l   #1, d6
    move.l  d6, d5                          ; Input flag index with bytes -> d5
    
    lsl.l   #2, d6                          ; For indexing with longs -> d6
    
    
    
    lea     OldestLaneNotes, a1
    lea     (a1, d6), a1
    move.l  (a1), a1                        ; Oldest, (Farthest down on screen), index offset
    
    lea     LanePosTables, a0
    lea     (a0, d6), a0
    move.l  (a0), a0                        ; Table of note positions
    
    adda.l  (a1), a0                        ; + Oldest index offset = Index to start drawing/checking

    
    move.l  (a0), d2                        ; Farthest down note pos -> d2
    lsr.l   #FIXED_POINT_BITS, d2           ; Convert to whole pixel
    
    lea     InputFlags, a5
    add.l   d5, a5                          ; Check desired lane input flag

    cmp.b   #0, (a5)                        ; Compares input bit with 0
    beq     FINISH_COLLISION_CHECK          ; Branch if input not pressed ~Input bit == 0
   
    move.l  #TARGET_LINE_Y, d3
    sub.l   d2, d3                          ; Target line - farthest down note pos
    
    bpl     SKIP_NEGATION                   ; Branches if number is already positive
    neg.l   d3                              ; Negates the difference for the absolute value
    
SKIP_NEGATION:
    ; Checks the difference between position and the size of the note
    cmp.l   #(NOTE_SIZE), d3
    bgt     NOTE_MISSED                     ; Branch if the difference is greater ~Not colliding 
    
    ; Increment Combo and update max combo if needed
    add.l   #1, (CurrentCombo)
    move.l  (CurrentCombo), d0
    cmp.l   (EndBestCombo), d0
    blt     SKIP_SET_MAX_COMBO
    move.l  d0, (EndBestCombo)
SKIP_SET_MAX_COMBO:
    ; Draw combo in seven segment
    move.l  (CurrentCombo), -(sp)
    jsr     DRAW_TWO_DIGIT_NUMBER
    lea     (BYTES_IN_SEGMENT_PARAMS)(sp), sp
    
    ; Decrement total notes remaining
    subi.l  #1, (TotalNotes)
    add.l   #BYTES_IN_LONG, (a1)            ; Remove from considerations for future draws/logic
    
    ; Add score and increase notes hit
    add.l   #1, (EndNotesHit)
    jsr     INCREASE_PERFORMANCE
    
    bra.s   FINISH_COLLISION_CHECK
NOTE_MISSED:
    ; Reset current combo and draw in seven segment
    move.l  #0, (CurrentCombo)
    move.l  (CurrentCombo), -(sp)
    jsr     DRAW_TWO_DIGIT_NUMBER
    lea     (BYTES_IN_SEGMENT_PARAMS)(sp), sp
    
    ; Play Overstrum sound
    jsr     GET_RANDOM_0_5_D7               ; Random from 0-5
    lsl.l   #2, d7                          ; Long indexing
    lea     OverstrumSounds, a0
    lea     (a0, d7), a0
    move.l  (a0), a1
    move.l  #PLAY_SOUND_DIRECTX_TASK, d0
    trap    #15
    
    ; Subtract score and increase overstrums
    add.l   #1, (EndOverstrums)
    jsr     DECREASE_PERFORMANCE
    jsr     DECREASE_PERFORMANCE            ; Double call to reduce spamming
    
    
FINISH_COLLISION_CHECK:
    rts

    ; Draws the notes in a specific lane
    ; Input d6 - Lane to draw
DRAW_NOTES:
    cmp.b   #1, (SongFinished)
    beq     FINISH_DRAW_NOTES               ; Skip if no notes remaining
    
    sub.l   #1, d6                          ; For indexing
    lsl.l   #2, d6
    
    lea     CurrentLaneTimings, a0
    lea     (a0, d6), a0                    ; Current timing index
    move.l  (a0), a0                        ; Next Note timing
    move.l  (a0), a4                        
    
    lea     OldestLaneNotes, a1
    lea     (a1, d6), a1
    move.l  (a1), a1                        ; Farthest down note offset
    
    lea     LaneCurrentNotes, a2
    lea     (a2, d6), a2
    move.l  (a2), a2                        ; Current note index
    
    lea     LaneCurrentNoteIndexs, a3
    lea     (a3, d6), a3
    move.l  (a3), a3                        ; Current index
      
    
    move.l  (TimeElapsed), d0
    mulu    #10, d0                         ; Multiply by 10 for thousands of a second
    
    ; Check the next notes timing
    moveq.l #0, d1
    move.w  (a4), d1
    cmp.l   d1, d0
    blt     START_DRAW_LOOP                 ; Branch if the time elapsed < Next notes spawn time
    
    ; Increase the index of the next note spawn time, Current/most recent note index spawned, current index
    add.l   #BYTES_IN_LONG, (a2)
    add.l   #1, (a3)
    add.l   #2, (a0)

START_DRAW_LOOP:
    ; Checks index
    cmp.l   #0, (a3)
    blt     FINISH_DRAW_NOTES               ; Branch and skip if index is invald ~ -1
    
    lea     LanePosTables, a0
    lea     (a0, d6), a0
    move.l  (a0), a0                        ; Table of note positions
    
    adda.l  (a1), a0                        ; + Passed notes offset
    
    cmp.l   (a2), a0                        ; Note index >= Current note
    bge     FINISH_DRAW_NOTES               ; Skip to the end if no notes to currently draw
DRAW_LOOP:
    
    lea     DRAW_NOTE_ROUTINE_TABLE, a3 
    moveq.l #0, d0 
    lea     (a3, d6), a3
    move.l  (a3), a3                        ; Pick lane to draw to
    jsr     (a3)                            ; Draw note in specified lane

    add.l   d7, (a0)                        ; Update position for next draw
    
    ; Checks if the current note position < Bottom of the play area
    cmp.l   #((PLAY_AREA_BOTTOM_Y-NOTE_SIZE/2)<<FIXED_POINT_BITS), (a0)
    blt     SKIP_REMOVE_NOTE                ; Branch and skip if current note is inside play area
   
    ; When note exceeds play area, reset combo and decrease score -------------
    ; Reset combo
    move.l  #0, (CurrentCombo)
    move.l  (CurrentCombo), -(sp)
    jsr     DRAW_TWO_DIGIT_NUMBER
    lea     (BYTES_IN_SEGMENT_PARAMS)(sp), sp
    add.l   #BYTES_IN_LONG, (a1) ;Remove from considerations for future draws/logic
    subi.l  #1, (TotalNotes)
    
    ; Play missed sound
    move.l  #PLAY_SOUND_DIRECTX_TASK, d0
    lea     MissedNoteFXString, a1
    trap    #15
    
    add.l   #1, (EndNotesMissed)
    jsr     DECREASE_PERFORMANCE
    ; -------------------------------------------------------------------------
SKIP_REMOVE_NOTE
    add.l   #4, a0
    cmp.l   (a2), a0                        ; Repeat if there are still notes to draw between the current note
                                            ; and farthest down note
    blt     DRAW_LOOP
    
FINISH_DRAW_NOTES:
    rts


    ; Draws and updates the progress bar
    
UPDATE_PROGRESS_BAR:
    ; Draw fill update
    move.l  #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #PROGRESS_BAR_LEFT_X, d1
    move.l  (ProgressBarFillHeightPos), d2
    lsr.l   #FIXED_POINT_BITS, d2           ; Fix to whole number of pixels
    move.l  #PROGRESS_BAR_RIGHT_X, d3
    move.l  #PROGRESS_BAR_BOTTOM_Y, d4
    trap    #15
    
    ; Reset fill color
    move.l  #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #0, d1
    trap    #15
    
    ; Update progross position
    move.l  (ProgressSpeedPixelCentiSecond), d6
    move.l  (DeltaTime), d1
    mulu    d1, d6 
    sub.l   d6, (ProgressBarFillHeightPos)  
    
    rts


    ; Draws a note in lane 1
DRAW_NOTE_LANE1:
    
    ; Draws the Outer layer
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #LANE1_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #(LANE1_X-(NOTE_WIDTH/2)), d1
    move.l  (a0), d2
    lsr.l   #FIXED_POINT_BITS, d2           ; Fix to whole number of pixels
    subi.l  #(NOTE_SIZE/2), d2
    move.l  #(LANE1_X+(NOTE_WIDTH/2)), d3
    move.l  d2, d4
    addi.l  #NOTE_SIZE, d4
    trap    #15
    
    ; Draws the inner layer
    moveq.l #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #LANE1_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #(LANE1_X-(NOTE_WIDTH/2)+5), d1
    move.l  (a0), d2
    lsr.l   #FIXED_POINT_BITS, d2           ; Fix to whole number of pixels
    add.l   #5, d2
    subi.l  #(NOTE_SIZE/2), d2
    move.l  #(LANE1_X+(NOTE_WIDTH/2)-5), d3
    move.l  d2, d4
    addi.l  #NOTE_SIZE, d4
    sub.l   #10, d4
    trap    #15
    
    ; Reset pen and fill color
    moveq.l #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #0, d1
    trap    #15
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15
    
    rts
    
    ; Draws a note in lane 1
DRAW_NOTE_LANE2:
    ; Draws the outer layer
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #LANE2_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #(LANE2_X-(NOTE_WIDTH/2)), d1
    move.l  (a0), d2
    lsr.l   #FIXED_POINT_BITS, d2           ; Fix to whole number of pixels
    subi.l  #(NOTE_SIZE/2), d2
    move.l  #(LANE2_X+(NOTE_WIDTH/2)), d3
    move.l  d2, d4
    addi.l  #NOTE_SIZE, d4
    trap    #15
    
    ; Draws the inner layer
    moveq.l #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #LANE2_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #(LANE2_X-(NOTE_WIDTH/2)+5), d1
    move.l  (a0), d2
    lsr.l   #FIXED_POINT_BITS, d2           ; Fix to whole number of pixels
    add.l   #5, d2
    subi.l  #(NOTE_SIZE/2), d2
    move.l  #(LANE2_X+(NOTE_WIDTH/2)-5), d3
    move.l  d2, d4
    addi.l  #NOTE_SIZE, d4
    sub.l   #10, d4
    trap    #15
    
    ; Reset pen and fill color
    moveq.l #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #0, d1
    trap    #15
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15

    rts

DRAW_NOTE_LANE3:
    ; Draws the outer layer
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #LANE3_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #(LANE3_X-(NOTE_WIDTH/2)), d1
    move.l  (a0), d2
    lsr.l   #FIXED_POINT_BITS, d2           ; Fix to whole number of pixels
    subi.l  #(NOTE_SIZE/2), d2
    move.l  #(LANE3_X+(NOTE_WIDTH/2)), d3
    move.l  d2, d4
    addi.l  #NOTE_SIZE, d4
    trap    #15
    
    ; Draws the inner layer
    moveq.l #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #LANE3_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #(LANE3_X-(NOTE_WIDTH/2)+5), d1
    move.l  (a0), d2
    lsr.l   #FIXED_POINT_BITS, d2           ; Fix to whole number of pixels
    add.l   #5, d2
    subi.l  #(NOTE_SIZE/2), d2
    move.l  #(LANE3_X+(NOTE_WIDTH/2)-5), d3
    move.l  d2, d4
    addi.l  #NOTE_SIZE, d4
    sub.l   #10, d4
    trap    #15
    
    ; Reset pen and fill color
    moveq.l #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #0, d1
    trap    #15
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15

    
    rts
    
DRAW_NOTE_LANE4:
    ; Draws the outer layer
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #LANE4_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #(LANE4_X-(NOTE_WIDTH/2)), d1
    move.l  (a0), d2
    lsr.l   #FIXED_POINT_BITS, d2           ; Fix to whole number of pixels
    subi.l  #(NOTE_SIZE/2), d2
    move.l  #(LANE4_X+(NOTE_WIDTH/2)), d3
    move.l  d2, d4
    addi.l  #NOTE_SIZE, d4
    trap    #15
    
    ; Draws the inner layer
    moveq.l #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #LANE4_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #(LANE4_X-(NOTE_WIDTH/2)+5), d1
    move.l  (a0), d2
    lsr.l   #FIXED_POINT_BITS, d2           ; Fix to whole number of pixels
    add.l   #5, d2
    subi.l  #(NOTE_SIZE/2), d2
    move.l  #(LANE4_X+(NOTE_WIDTH/2)-5), d3
    move.l  d2, d4
    addi.l  #NOTE_SIZE, d4
    sub.l   #10, d4
    trap    #15
    
    ; Reset pen and fill color
    moveq.l #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #0, d1
    trap    #15
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15

    
    rts
    
DRAW_NOTE_LANE5:
    ; Draw the outer layer
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #LANE5_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #(LANE5_X-(NOTE_WIDTH/2)), d1
    move.l  (a0), d2
    lsr.l   #FIXED_POINT_BITS, d2           ; Fix to whole number of pixels
    subi.l  #(NOTE_SIZE/2), d2
    move.l  #(LANE5_X+(NOTE_WIDTH/2)), d3
    move.l  d2, d4
    addi.l  #NOTE_SIZE, d4
    trap    #15
    
    ; Draw the inner layer
    moveq.l #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #LANE5_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #(LANE5_X-(NOTE_WIDTH/2)+5), d1
    move.l  (a0), d2
    lsr.l   #FIXED_POINT_BITS, d2           ; Fix to whole number of pixels
    add.l   #5, d2
    subi.l  #(NOTE_SIZE/2), d2
    move.l  #(LANE5_X+(NOTE_WIDTH/2)-5), d3
    move.l  d2, d4
    addi.l  #NOTE_SIZE, d4
    sub.l   #10, d4
    trap    #15
    
    ; Reset pen and fill color
    moveq.l #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #0, d1
    trap    #15
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15

    
    rts
          
    ; Displays all of the static gameplay elements
DRAW_PLAY_AREA_STATIC_ELEMENTS:
    ; Paint background of play area with black box
    move.l  #SET_PEN_WIDTH_TASK, d0
    move.l  #PLAY_AREA_BORDER_WIDTH, d1
    trap    #15
    
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  (PlayAreaBoarderColor), d1
    trap    #15
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #PLAY_AREA_LEFT_X, d1
    move.l  #PLAY_AREA_TOP_Y, d2
    move.l  #PLAY_AREA_RIGHT_X, d3
    move.l  #PLAY_AREA_BOTTOM_Y, d4
    trap    #15
    
    ; Reset line width
    move.l  #SET_PEN_WIDTH_TASK, d0
    move.l  #1, d1
    trap    #15
    
    ; Paint target Line
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15
    moveq.l #DRAW_LINE_START_END_TASK, d0
    moveq.l #TARGET_LINE_X1, d1
    move.l  #TARGET_LINE_Y, d2
    move.l  #TARGET_LINE_X2, d3
    move.l  #TARGET_LINE_Y, d4
    trap    #15
    
    ; Paint target line hammers -----------------------------------------------
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #LANE1_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_FILLED_OVAL_TASK, d0
    move.l  #(LANE1_X-(NOTE_WIDTH/2)), d1
    move.l  #(HAMMER_Y-(NOTE_SIZE/2)), d2
    move.l  #(LANE1_X+(NOTE_WIDTH/2)), d3
    move.l  #(HAMMER_Y+(NOTE_SIZE/2)), d4
    trap    #15
    
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #LANE2_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_FILLED_OVAL_TASK, d0
    move.l  #(LANE2_X-(NOTE_WIDTH/2)), d1
    move.l  #(HAMMER_Y-(NOTE_SIZE/2)), d2
    move.l  #(LANE2_X+(NOTE_WIDTH/2)), d3
    move.l  #(HAMMER_Y+(NOTE_SIZE/2)), d4
    trap    #15
    
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #LANE3_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_FILLED_OVAL_TASK, d0
    move.l  #(LANE3_X-(NOTE_WIDTH/2)), d1
    move.l  #(HAMMER_Y-(NOTE_SIZE/2)), d2
    move.l  #(LANE3_X+(NOTE_WIDTH/2)), d3
    move.l  #(HAMMER_Y+(NOTE_SIZE/2)), d4
    trap    #15
    
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #LANE4_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_FILLED_OVAL_TASK, d0
    move.l  #(LANE4_X-(NOTE_WIDTH/2)), d1
    move.l  #(HAMMER_Y-(NOTE_SIZE/2)), d2
    move.l  #(LANE4_X+(NOTE_WIDTH/2)), d3
    move.l  #(HAMMER_Y+(NOTE_SIZE/2)), d4
    trap    #15
    
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #LANE5_HAMMER_COLOR, d1
    trap    #15
    moveq.l #DRAW_FILLED_OVAL_TASK, d0
    move.l  #(LANE5_X-(NOTE_WIDTH/2)), d1
    move.l  #(HAMMER_Y-(NOTE_SIZE/2)), d2
    move.l  #(LANE5_X+(NOTE_WIDTH/2)), d3
    move.l  #(HAMMER_Y+(NOTE_SIZE/2)), d4
    trap    #15
    ; -------------------------------------------------------------------------
    
    ; Reset Pen color
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15
    
    rts


DRAW_NOTE_ROUTINE_TABLE         dc.l DRAW_NOTE_LANE1, DRAW_NOTE_LANE2, DRAW_NOTE_LANE3, DRAW_NOTE_LANE4, DRAW_NOTE_LANE5




































*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

*-----------------------------------------------------------
* Title      : Title Game Loop
* Written by : Albert Castrejon
* Date       : 6/6/25
* Description: Runs the game loop that contains the title screen and picking a song
*-----------------------------------------------------------

TITLE_LOOP:
    ; poll for 1, 2, 3, 4 inputs
    moveq.l #KEY_INPUT_TASK, d0
    move.l  #LEVEL_TARGET_INPUTS, d1
    trap    #15
    
    
    jsr PROCESS_TITLE_INPUTS
    
    ; Input d7 - Currently selected song
    move.l  (CurrentChoiceIndex), d7
    jsr REFRESH_TITLE_SCREEN
    
    ;Update Screen
    moveq.l #PAINT_BUFFER_SCREEN_TASK, d0
    trap    #15

    rts



PROCESS_TITLE_INPUTS:
    move.l  (HeldInputs), d0
    move.l  d1, (HeldInputs)                ; Add all bits currently pressed to held inputs flag
    
    not.l   d0                              ; NOT all bits 
    and.l   d0, d1                          ; Remove all inputs held down creating OnPress behavior
                   

    ; Check for '1' pressed
    btst.l  #ONE_PRESSED_BIT_OFFSET, d1
    beq     ONE_NOT_PRESSED_TITLE           ; Branch if '1' not pressed '1' bit == 0
    
    ; Check selected song index
    cmp.l   #0, (CurrentChoiceIndex)
    beq     SKIP_DECREASE_CHOICE_INDEX      ; Branch and skip decrement if already at lowest index
    
    
    ; Play button sound
    move.l  #PLAY_SOUND_DIRECTX_TASK, d0
    lea     CassetteTapeButton, a1
    trap    #15
    
    move.l  d1, -(sp)                           ; Save inputs
    
    ; Get current difficulty padding
    ; -(ChoiceIndex * Difficulty skull width + ChoiceIndex * Difficulty skull padding) + position
    ; Negative since the skulls grow to the left
    moveq.l #0, d0
    move.l  (CurrentChoiceIndex), d0
    lsr.l   #2, d0     
    move.l  #DIFFICULTY_SKULL_PADDING, d1
    mulu    d0, d1
    mulu    #DIFFICULTY_SKULL_WIDTH , d0
    add.l   d1, d0
    
    neg     d0  
    swap    d0                                  ; To get the 'x' value in upper word
    add.l   #DIFFICUTLY_SKULL_POS, d0
    
    
    
    ; Remove a difficulty
    move.l  d0, -(sp)                           ; Screen start Position
    move.w  #DIFFICULTY_SKULL_HEIGHT, -(sp)     ; Chunk height
    move.w  #DIFFICULTY_SKULL_WIDTH, -(sp)      ; Chunk width
    move.l  d0, -(sp)                           ; Chunk start Position
    move.l  #TitleImage, -(sp)             ; Bitmap Address 
    jsr     DRAW_BITMAP_CHUNK
    lea     BITMAP_CHUNK_PARAM_SIZE(sp), sp     ; Fix stack
    
    move.l  (sp)+, d1                           ; Pop back inputs
    
    sub.l   #4, (CurrentChoiceIndex)            ; Post decrement to erase previous skull
SKIP_DECREASE_CHOICE_INDEX:
    
ONE_NOT_PRESSED_TITLE:
    ; Check for '2' pressed
    btst.l  #TWO_PRESSED_BIT_OFFSET, d1     
    beq     TWO_NOT_PRESSED_TITLE           ; Branch and skip if '2' not pressed '2' bit == 0

    move.b  #1, (ReadyForGame)              ; Set the ready flag
    
    ; Play start sound
    move.l  #PLAY_SOUND_DIRECTX_TASK, d0
    lea     CassetteTapeStart, a1
    trap    #15
    
TWO_NOT_PRESSED_TITLE:
    ; Check for '3' pressed
    btst.l  #THREE_PRESSED_BIT_OFFSET, d1
    beq     THREE_NOT_PRESSED_TITLE         ; Branch if '3' not pressed '3' bit == 0

    ; Check selected song index
    cmp.l   #MAX_SONGS_INDEX, (CurrentChoiceIndex)
    beq     SKIP_INCREASE_CHOICE_INDEX      ; Branch and skip increment if already at highest index
    
    
    ; Play button sound
    move.l  #PLAY_SOUND_DIRECTX_TASK, d0
    lea     CassetteTapeButton, a1
    trap    #15
    
    
    add.l   #4, (CurrentChoiceIndex)        ; Pre increment to draw new skull
    
    ; Get current difficulty padding
    ; -(ChoiceIndex * Difficulty skull width) + position
    ; Negative since the skulls grow to the left
    moveq.l #0, d0
    move.l  (CurrentChoiceIndex), d0
    lsr.l   #2, d0     
    move.l  #DIFFICULTY_SKULL_PADDING, d1
    mulu    d0, d1
    mulu    #DIFFICULTY_SKULL_WIDTH , d0
    add.l   d1, d0
    
    neg     d0  
    swap    d0                                  ; To get the 'x' value in upper word
    add.l   #DIFFICUTLY_SKULL_POS, d0
    
    ; Add a difficulty
    move.l  d0, -(sp)                           ; Screen start Position
    move.w  #DIFFICULTY_SKULL_HEIGHT, -(sp)     ; Chunk height
    move.w  #DIFFICULTY_SKULL_WIDTH, -(sp)      ; Chunk width
    move.l  #TOP_LEFT, -(sp)                    ; Chunk start Position
    move.l  #DifficultySkull, -(sp)             ; Bitmap Address 
    jsr     DRAW_BITMAP_CHUNK
    lea     BITMAP_CHUNK_PARAM_SIZE(sp), sp     ; Fix stack
    
    
SKIP_INCREASE_CHOICE_INDEX:    
    
THREE_NOT_PRESSED_TITLE:
    ; Check for '4' pressed
    btst.l  #FOUR_PRESSED_BIT_OFFSET, d1       
    beq     FOUR_NOT_PRESSED_TITLE          ; Branch and skip if '2' not pressed '2' bit == 0
    
    jsr     DELETE_SONG_INFORMATION
    
FOUR_NOT_PRESSED_TITLE:    
    
    rts
    
    
    ; Input d7 - Current song index in bytes
REFRESH_TITLE_SCREEN:
    
    ; Get current song name
    lea     SongNames, a0
    lea     (a0, d7), a0
    move.l  (a0), a0                       
    
    ; Get current song file path
    lea     SongStrings, a1
    lea     (a1, d7), a1
    move.l  (a1), a1                       
    
    ; Get current song sound file reference
    lea     SongSounds, a2
    lea     (a2, d7), a2
    move.l  (a2), a2
    
    
    move.l  a1, (ChosenSong)
    move.l  a2, (ChosenSound)
    
    ; Update Screen based on current choice
    move.l  #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15
    
    move.l  #SET_PEN_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15
    
    move.l  #DRAW_RECT_TASK, d0
    move.l  #SONG_NAME_POS_X, d1
    move.l  #SONG_NAME_POS_Y, d2
    move.l  #(SONG_NAME_POS_X+223), d3
    move.l  #(SONG_NAME_POS_Y+10), d4
    trap    #15                             ; Draw background
    
    move.l  #PRINT_STRING_PIXEL_POS_TASK, d0
    move.l  a0, a1
    move.l  #SONG_NAME_POS_X, d1
    move.l  #SONG_NAME_POS_Y, d2
    trap    #15                             ; Draw song name
    
    ; Get selected song index
    move.l  d7, d6
    lsr.l   #2, d6                          ; Byte based indexing
    
    ; Output (CompletionData) - Current data in the file
    jsr     READ_SONG_INFORMATION
    move.b  (CompletionData), d0
    
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
    lea     SongCompletionString, a0
    add.l   #START_OF_ASCII_NUMBERS, d3
    move.b  d3, (a0)+                       ; Push hundreds place to string
    add.l   #START_OF_ASCII_NUMBERS, d2
    move.b  d2, (a0)+                       ; Push tens place to string
    add.l   #START_OF_ASCII_NUMBERS, d1
    move.b  d1, (a0)+                       ; Push ones place to string
    
    ; Update completion percent on screen based on current choice
    
    move.l  #PRINT_STRING_PIXEL_POS_TASK, d0
    lea     SongCompletionString, a1
    move.l  #PERCENT_POS_X, d1
    move.l  #PERCENT_POS_Y, d2
    trap    #15                             ; Draw String
    

    rts

SongCompletionString        dc.b    '   %',0
                            dc.w    0       ; Padding



















*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

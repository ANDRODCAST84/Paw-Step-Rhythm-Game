*-----------------------------------------------------------
* Title      : InitLevel
* Written by : Albert Castrejon
* Date       : 6/3/25
* Description: Runs all required initialization for level screen
*-----------------------------------------------------------

LOAD_LEVEL:
    ; Print "Loading" to screen
    moveq.l #PRINT_CR_LF_TASK, d0
    lea     LoadingString, a1
    trap    #15
    
    ; Set up flags
    move.b  #0, (SongFinished)
    move.l  #0, (SongFailed)

    ;Update Screen
    moveq.l #PAINT_BUFFER_SCREEN_TASK, d0
    trap    #15
    
    ; Draw background
    move.l  #TOP_LEFT, -(sp) ; Screen start Position
    move.w  #SCREEN_HEIGHT, -(sp)   ; Chunk height
    move.w  #SCREEN_WIDTH, -(sp)    ; Chunk width
    move.l  #TOP_LEFT, -(sp) ; Chunk start Position
    move.l  #LevelBackground, -(sp) ; Bitmap Address 
    jsr     DRAW_BITMAP_CHUNK
    lea     BITMAP_CHUNK_PARAM_SIZE(sp), sp ; Fix stack
    
    ; Draw cat
    move.l  #GATO_SCREEN_START_POS, -(sp) ; Screen start Position
    move.w  #GATO_FULL_HEIGHT, -(sp)   ; Chunk height
    move.w  #GATO_FULL_WIDTH, -(sp)    ; Chunk width
    move.l  #0, -(sp) ; Chunk start Position
    move.l  #GatoAsleep, -(sp) ; Bitmap Address 
    jsr     DRAW_BITMAP_CHUNK
    lea     BITMAP_CHUNK_PARAM_SIZE(sp), sp ; Fix stack

    move.l  #SET_PEN_FILL_COLOR_TASK, d0
    move.l  #0, d1
    trap    #15

    ; Draw progress bar
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #PROGRESS_BAR_LEFT_X, d1
    move.l  #PROGRESS_BAR_TOP_Y, d2
    move.l  #PROGRESS_BAR_RIGHT_X, d3
    move.l  #PROGRESS_BAR_BOTTOM_Y, d4
    trap    #15

    move.l  (CurrentCombo), -(sp)
    jsr     DRAW_TWO_DIGIT_NUMBER
    lea     (BYTES_IN_SEGMENT_PARAMS)(sp), sp
    
    ;Update Screen
    moveq.l #PAINT_BUFFER_SCREEN_TASK, d0
    trap    #15
    
    ; Stop all previous sounds
    moveq.l #CONTROL_DIRECTX_PLAYER_TASK, d0
    move.l  #STOP_ALL_SOUNDS, d2
    trap    #15
    
    ; Set init start time
    moveq.l #GET_TIME_TASK, d0
    trap    #15
    move.l  d1, (PreviousTime)
       
    ; Start song
    move.l  #LOAD_DIRECTX_SOUND_TASK, d0
    move.l  (ChosenSong), a1
    move.l  #CHOSEN_SONG_LOAD_NUMBER, d1
    trap    #15

    moveq.l #CONTROL_DIRECTX_PLAYER_TASK, d0
    move.l  #CHOSEN_SONG_LOAD_NUMBER, d1
    move.l  #PLAY_SOUND_ONCE, d2
    trap    #15
    
    rts
    
    
LoadingString   dc.b    'Loading',0

























*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

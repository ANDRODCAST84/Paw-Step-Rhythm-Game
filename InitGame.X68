*-----------------------------------------------------------
* Title      : Init Game
* Written by : Albert Castrejon
* Date       : 6/3/25
* Description: Initializes and starts game
*-----------------------------------------------------------

INITIALIZE_GAME:
    ; Turn on double buffering
    moveq.l #SET_DRAWING_MODE_TASK, d0
    moveq.l #ENABLE_DOUBLE_BUFFER_CODE, d1
    trap    #15
    
    jsr     GENERATE_RANDOM_NUMBER_SEED
    
    ; Print "Loading" to screen
    moveq.l #PRINT_CR_LF_TASK, d0
    lea     LoadingString, a1
    trap    #15

    ;Update Screen
    moveq.l #PAINT_BUFFER_SCREEN_TASK, d0
    trap    #15
    
    ; Draw Title image
    move.l  #TOP_LEFT, -(sp)                ; Screen start Position
    move.w  #SCREEN_HEIGHT, -(sp)           ; Chunk height
    move.w  #SCREEN_WIDTH, -(sp)            ; Chunk width
    move.l  #TOP_LEFT, -(sp)                ; Chunk start Position
    move.l  #TitleImage, -(sp)              ; Bitmap Address 
    jsr     DRAW_BITMAP_CHUNK
    lea     BITMAP_CHUNK_PARAM_SIZE(sp), sp ; Fix stack
    
    ; Set font
    move.l  #SET_FONT_PROPERTIES_TASK, d0
    move.l  #STATS_FONT_COLOR, d1
    move.l  #MAIN_MENU_FONT_STYLE, d2
    trap    #15
    
    ; Print first song
    move.l  #PRINT_STRING_PIXEL_POS_TASK, d0
    lea     PonderTheNightName, a1
    move.l  #SONG_NAME_POS_X, d1
    move.l  #SONG_NAME_POS_Y, d2
    trap    #15
    
    ; Set selected first song
    move.l  #0, (CurrentChoiceIndex)
    move.l  #PonderTheNightString, (ChosenSong)
    move.l  #PonderTheNightSound, (ChosenSound)
    
    ; Display Difficulty
    move.l  #DIFFICUTLY_SKULL_POS, -(sp)        ; Screen start Position
    move.w  #DIFFICULTY_SKULL_HEIGHT, -(sp)     ; Chunk height
    move.w  #DIFFICULTY_SKULL_WIDTH, -(sp)      ; Chunk width
    move.l  #TOP_LEFT, -(sp)                    ; Chunk start Position
    move.l  #DifficultySkull, -(sp)             ; Bitmap Address 
    jsr     DRAW_BITMAP_CHUNK
    lea     BITMAP_CHUNK_PARAM_SIZE(sp), sp     ; Fix stack
    
    ;Update Screen
    moveq.l #PAINT_BUFFER_SCREEN_TASK, d0
    trap    #15
    

    rts






















*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

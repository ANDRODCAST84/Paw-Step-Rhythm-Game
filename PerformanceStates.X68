*-----------------------------------------------------------
* Title      : Performance States
* Written by : Albert Castrejon
* Date       : 6/5/25
* Description: Keeps track and update the current performance state
*-----------------------------------------------------------

* Decreases performance modifiers and applies it to the current score
DECREASE_PERFORMANCE:
    movem.l  ALL_REG, -(sp)
    ; Check if negative modifier < -max, set to -max if true
    subi.l  #NEGATIVE_MODIFIER_INCREMENT, (PerformanceNegativeModifier)
    cmp.l   #-MAX_PERFORMANCE_MODIFIER, (PerformanceNegativeModifier)
    bge     SKIP_SET_LOWEST_NEG_MODIFIER
    
    move.l  #-MAX_PERFORMANCE_MODIFIER, (PerformanceNegativeModifier)  
  
SKIP_SET_LOWEST_NEG_MODIFIER:
    ; Check if positive modifier < 0, set to 0 if true
    subi.l  #NEGATIVE_MODIFIER_INCREMENT, (PerformancePositiveModifier)
    cmp.l   #0, (PerformancePositiveModifier)
    bge     SKIP_SET_LOWEST_POS_MODIFIER
    
    move.l  #0, (PerformancePositiveModifier)    
SKIP_SET_LOWEST_POS_MODIFIER:
    move.l  (PerformanceNegativeModifier), d0
    add.l   d0, (PerformanceScore)
    jsr     HANDLE_PERFORMANCE 
    
    movem.l (sp)+, ALL_REG
    rts

* Increases performance modifiers and applies it to the current score
INCREASE_PERFORMANCE:
    movem.l  ALL_REG, -(sp)
    ; Check if positive modifier > max, set to max if true
    addi.l  #POSITIVE_MODIFIER_INCREMENT, (PerformancePositiveModifier)
    cmp.l   #MAX_PERFORMANCE_MODIFIER, (PerformancePositiveModifier)
    ble     SKIP_SET_HIGHEST_POS_MODIFIER
    
    move.l  #MAX_PERFORMANCE_MODIFIER, (PerformancePositiveModifier)  
  
SKIP_SET_HIGHEST_POS_MODIFIER:
    ; Check if negative modifier > 0, set to 0 if true
    addi.l  #POSITIVE_MODIFIER_INCREMENT, (PerformanceNegativeModifier)
    cmp.l   #0, (PerformanceNegativeModifier)
    ble     SKIP_SET_HIGHEST_NEG_MODIFIER
    
    move.l  #0, (PerformanceNegativeModifier)    
SKIP_SET_HIGHEST_NEG_MODIFIER:
    move.l  (PerformancePositiveModifier), d0
    add.l   d0, (PerformanceScore)
    jsr     HANDLE_PERFORMANCE
    movem.l (sp)+, ALL_REG 
    rts

    
* Sets the game state based on current performance score
HANDLE_PERFORMANCE:
    cmp.l   #(MAX_PERFORMANCE*PERFORMANCE_STATE_SCORE_SIZE), (PerformanceScore)
    ble     SKIP_SET_HIGHEST_PERFORMANCE
    move.l  #(MAX_PERFORMANCE*PERFORMANCE_STATE_SCORE_SIZE), (PerformanceScore)
SKIP_SET_HIGHEST_PERFORMANCE:

    move.l  (PerformanceScore), d0
    divu    #PERFORMANCE_STATE_SCORE_SIZE, d0   ; Get Performance index
    lsl     #2, d0                              ; Translate to number of bytes
    
    lea     PerformanceHandlingTable, a0
    lea     (a0, d0), a0
    move.l  (a0), a0                            ; Get handle address from table
    
    
    jsr (a0)                                    ; Call handle sub-routine
    rts    

HANDLE_LOST:  
    ; Stop song
    moveq.l #CONTROL_DIRECTX_PLAYER_TASK, d0
    moveq.l #CHOSEN_SONG_LOAD_NUMBER, d1
    moveq.l #STOP_REFERENCED_SOUND, d2
    trap    #15
    
    jsr     GATO_JUMP
    jsr     SONG_ENDING_SEQUENCE
    
    ; Draw loss sticker
    move.l  #WIN_LOSS_STICKER_SCREEN_POS, -(sp) ; Screen start Position
    move.w  #WIN_LOSS_STICKER_HEIGHT, -(sp)     ; Chunk height
    move.w  #WIN_LOSS_STICKER_WIDTH, -(sp)      ; Chunk width
    move.l  #0, -(sp)                           ; Chunk start Position
    move.l  #LossSticker, -(sp)                 ; Bitmap Address 
    jsr     DRAW_BITMAP_CHUNK
    lea     BITMAP_CHUNK_PARAM_SIZE(sp), sp     ; Fix stack
    
    ; Draw loss banner
    move.l  #END_BANNER_POS, -(sp)             ; Screen start Position
    move.w  #END_BANNER_HEIGHT, -(sp)          ; Chunk height
    move.w  #END_BANNER_WIDTH, -(sp)           ; Chunk width
    move.l  #0, -(sp)                           ; Chunk start Position
    move.l  #LossBanner, -(sp)                  ; Bitmap Address 
    jsr     DRAW_BITMAP_CHUNK
    lea     BITMAP_CHUNK_PARAM_SIZE(sp), sp     ; Fix stack
    
    ;Update Screen
    moveq.l #PAINT_BUFFER_SCREEN_TASK, d0
    trap    #15

    ; Set song finished and failed flags
    move.b  #1, (SongFinished)
    move.l  #1, (SongFailed)

    rts
    
HANDLE_TERRIBLE:
    move.l  #TERRIBLE_COLOR, (PlayAreaBoarderColor)
    rts

HANDLE_BAD:
    move.l  #BAD_COLOR, (PlayAreaBoarderColor)
    rts
    
HANDLE_MEDIOCRE:
    move.l  #MEDIOCRE_COLOR, (PlayAreaBoarderColor)
    rts
    
HANDLE_DECENT:
    move.l  #DECENT_COLOR, (PlayAreaBoarderColor)
    rts
    
HANDLE_GOOD:
    move.l  #GOOD_COLOR, (PlayAreaBoarderColor)
    rts
    
HANDLE_EXCELLENT:
    move.l  #EXCELLENT_COLOR, (PlayAreaBoarderColor)
    rts
    
HANDLE_MAX:
    move.l  #MAX_COLOR, (PlayAreaBoarderColor)
    rts
                                    ; 0 - 19       20 - 39          40 - 59
PerformanceHandlingTable    dc.l    HANDLE_LOST, HANDLE_TERRIBLE, HANDLE_BAD
                                    ; 60 - 79          80 - 99        100 - 119
                            dc.l    HANDLE_MEDIOCRE, HANDLE_DECENT, HANDLE_GOOD
                                    ; 120 - 139         140
                            dc.l    HANDLE_EXCELLENT, HANDLE_MAX

PerformancePositiveModifier dc.l    0
PerformanceNegativeModifier dc.l    0
    
                                    ; Initial Performance 
CurrentPerformance          dc.l    PERFORMANCE_DECENT
                                    ; Initial Score
PerformanceScore            dc.l    PERFORMANCE_STATE_SCORE_SIZE*PERFORMANCE_DECENT




























*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

*-----------------------------------------------------------
* Title      : Gato Physics Handler
* Written by : Albert Castrejon
* Date       : 6/17/25
* Description: Handles all the physcis for the cat jumping sequence
*-----------------------------------------------------------

GATO_JUMP:
    ; Set init start time
    moveq.l #GET_TIME_TASK, d0
    trap    #15
    move.l  d1, (PreviousTime)
    
    ; Set up initial cat position
    move.l  #(GATO_SCREEN_START_POS>>BITS_IN_WORD), d0
    lsl.l   #FIXED_POINT_BITS, d0
    move.l  d0, (GatoX)
    move.l  #(GATO_SCREEN_START_POS), d0
    ext.l   d0
    lsl.l   #FIXED_POINT_BITS, d0
    move.l  d0, (GatoY)
    
    move.l  #GATO_JUMP_ACCELERATION, d5         ; Starting jump velecity
    
MOVE_GATO:
    jsr     GET_DELTA_TIME
    move.l  (DeltaTime), d7
    
    jsr     UPDATE_GATO
    jsr     DRAW_GATO
    
    ; Apply acceleration
    move.l  d7, d4
    muls    d4, d4                              ; Time squared
    muls    #GRAVITY_ACCELERATION, d4           ; Apply delta time to acceleration 
    add.l   d4, d5                              ; Update velocity 
    
    ; Ensure delta time 
    move.l  #DELAY_TASK, d0
    move.l  #1, d1
    trap    #15
    
    ; Check if cat fully moves offscreen and continue looping if not
    cmp.l   #((SCREEN_HEIGHT+MAD_GATO_HEIGHT)<<FIXED_POINT_BITS), (GatoY)
    blt     MOVE_GATO
    
    rts
    
    ; Updates the cats position based on the current velocity
    ; Input d5 - Starting jump velocity
    ;       d7 - Delta time
UPDATE_GATO: 
    lea     GatoMad, a0
    lea     LevelBackground, a1

    move.l  d5, d1
    muls    d7, d1                              ; Apply delta time to velocity
    add.l   d1, (GatoY)                         ; Update position
    
    rts
    
    ; Draws the background and cat based on the previous update
    ; Input d5 - The last velocity update
    ;       d7 - Delta time
DRAW_GATO:
    
    ; Get the last amount moved
    move.l  d5, d3
    muls    d7, d3
    lsr.l   #FIXED_POINT_BITS, d3
    
    move.l  (GatoX), d1
    lsr.l   #FIXED_POINT_BITS, d1
    swap    d1
    move.l  (GatoY), d2
    lsr.l   #FIXED_POINT_BITS, d2
    move.w  d2, d1                              ; Screen start position
    
    sub.w   d3, d1                              ; Subtract the last velocity update amount
                     
    ; Draw Background of the previous position
    movem.l ALL_REG, -(sp)
    move.l  d1, -(sp) ; Screen start Position
    move.w  #(MAD_GATO_BACKGROUND_HEIGHT), -(sp) ; Chunk height
    move.w  #MAD_GATO_WIDTH, -(sp)               ; Chunk width
    move.l  d1, -(sp)                            ; Chunk start Position
    move.l  a1, -(sp)                            ; Bitmap Address 
    jsr     DRAW_BITMAP_CHUNK
    lea     BITMAP_CHUNK_PARAM_SIZE(sp), sp      ; Fix stack
    movem.l (sp)+, ALL_REG

    move.l  (GatoX), d1
    lsr.l   #FIXED_POINT_BITS, d1
    swap    d1
    move.l  (GatoY), d2
    lsr.l   #FIXED_POINT_BITS, d2
    move.w  d2, d1                              ; Screen start position
    
    ; Draw cat in new position
    movem.l ALL_REG, -(sp)
    move.l  d1, -(sp)                           ; Screen start Position
    move.w  #MAD_GATO_HEIGHT, -(sp)             ; Chunk height
    move.w  #MAD_GATO_WIDTH, -(sp)              ; Chunk width
    move.l  #TOP_LEFT, -(sp)                           ; Chunk start Position
    move.l  a0, -(sp)                           ; Bitmap Address 
    jsr     DRAW_BITMAP_CHUNK
    lea     BITMAP_CHUNK_PARAM_SIZE(sp), sp     ; Fix stack
    movem.l (sp)+, ALL_REG
    
    ; Update Screen
    moveq.l #PAINT_BUFFER_SCREEN_TASK, d0
    trap    #15

    rts

    
GatoY       ds.l    1
GatoX       ds.l    1






















*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

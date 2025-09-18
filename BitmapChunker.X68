*-----------------------------------------------------------
* Title      : Bitmap Chunker
* Written by : Albert Castrejon
* Date       : 6/3/25
* Description: Draws a chunk of a bitmap at a specified location
*-----------------------------------------------------------

BITMAP_ADDRESS          EQU 16              ; Long: Input bitmap address pointer
CHUNK_START_POS         EQU 20              ; Long: Chunk start position (XXXXYYYY)
CHUNK_WIDTH             EQU 24              ; Word: Chunk Width
CHUNK_HEIGHT            EQU 26              ; Word: Chunk Height
SCREEN_START_POS        EQU 28              ; Long: Screen start position (XXXXYYYY)
    ; Local Variables
BITMAP_WIDTH            EQU 0               
BITMAP_HEIGHT           EQU 4
NEXT_LINE_OFFSET        EQU 8
LOCAL_VAR_TOTAL_BYTES   EQU 12
    ; Output: Screen update with drawn bitmap chunk
DRAW_BITMAP_CHUNK:
    lea     (-LOCAL_VAR_TOTAL_BYTES)(sp), sp ; Allocate space for local variables
    
    move.l  BITMAP_ADDRESS(sp), a0     
     
    lea     OFFSET_BITSPERPIXEL(a0), a1
    move.w  (a1), d7
    ror.w   #BITS_IN_BYTE, d7               ; Bits per pixel -> d7
    
    move.l  OFFSET_PIXELARRAY_OFFSET(a0), d6
    swap    d6
    ror.w   #BITS_IN_BYTE, d6
    
    move.l  a0, a1                          ; Save to get width later
    adda.l  d6, a0                          ; Start+offset -> a0
    
    ; a0 = 
    ; d7 = pixel size
    ; Drawing bitmap ----------------------------------------------
    move.l  SCREEN_START_POS(sp), d3        ; x, y Screen start position
    move.w  d3, d4                          ; y -> d4
    add.w   CHUNK_HEIGHT(sp), d4
    subi.w  #1, d4                          ; Inclusive pixel adjustment
    swap    d3                              ; x -> d3
    
    move.w  CHUNK_WIDTH(sp), d5             ; x counter
    subi.w  #DBRA_ADJUSTMENT, d5            
    move.w  CHUNK_HEIGHT(sp), d6            ; y counter
    subi.w  #DBRA_ADJUSTMENT, d6
    
    move.l  OFFSET_BITMAP_HEIGHT(a1), d0
    ror.w   #BITS_IN_BYTE, d0
    swap    d0
    ror.w   #BITS_IN_BYTE, d0               
    move.l  d0, BITMAP_HEIGHT(sp)           ; Save height locally
    
    move.l  OFFSET_BITMAP_WIDTH(a1), d0   
    ror.w   #BITS_IN_BYTE, d0
    swap    d0
    ror.w   #BITS_IN_BYTE, d0               
    move.l  d0, BITMAP_WIDTH(sp)            ; Save width locally
    
    asl.l   #2, d0                          ; Width * 4 Convert to bytes 
    move.l  d0, NEXT_LINE_OFFSET(sp)        ; Setting up for creating new line offset

    move.l  CHUNK_START_POS(sp), d1         ; x, y Chunk start position
    move.w  d1, d2                          ; y -> d2
    swap    d1                              ; x -> d1
    ext.l   d1
    
    neg.w   d2
    ext.l   d2
    add.l   BITMAP_HEIGHT(sp), d2           
    sub.w   CHUNK_HEIGHT(sp), d2            ; Fix height from window space to pixel array space
    
    mulu    d2, d0                          ; Y * Width
    adda.l  d0, a0                          ; Starting y row
    
    asl.l   #2, d1                          ; Chunk starting pos * 4
    adda.l  d1, a0                          ; Starting x and y
    
    moveq.l #0, d1
    move.w  CHUNK_WIDTH(sp), d1
    asl.l   #2, d1
    sub.l   d1, NEXT_LINE_OFFSET(sp)        ; Subtract chunk width from bitmap width
                                            ; to add after every new line
    move.w  d4, d2                          ; Y Position

DRAW_32BITMAP:
    move.l  #SET_PEN_COLOR_TASK, d0
    ; Gets pixel color data
    move.l  (a0)+, d1
    move.b  d1, d1
    beq.s   SKIP_DRAW_PIXEL
    lsr.l   #BITS_IN_BYTE, d1           ; $00BBGGRR
    trap    #15

    
    move.l  #DRAW_PIXEL_TASK, d0        ; Draws pixel at current
    move.w  d3, d1                      ; X Position and  
    trap    #15                         

SKIP_DRAW_PIXEL:
    addi.w  #1, d3                      ; Increment X position
    dbra    d5, DRAW_32BITMAP

    move.l  (SCREEN_START_POS)(sp), d3  ; Reset X position -> d3
    swap    d3
                                        ; Reset X loop dbra counter
    move.w  CHUNK_WIDTH(sp), d5
    subi.w  #DBRA_ADJUSTMENT, d5
    
    adda.l  NEXT_LINE_OFFSET(sp), a0    ; Increment to new row
    
    subi.w  #1, d2                      ; Decrement Y position
    dbra    d6, DRAW_32BITMAP
    
    
END_DRAW_BITMAP_CHUNK:   
                                        ; Deallocate LocalVars
    lea     (LOCAL_VAR_TOTAL_BYTES)(sp), sp      
    rts














*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

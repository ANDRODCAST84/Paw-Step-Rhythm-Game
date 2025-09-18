*-----------------------------------------------------------
* Title      : Seven Segment Display
* Written by : Albert Castrejon
* Date       : 6/3/25
* Description: Displays a two digit seven segment based number
*-----------------------------------------------------------

TARGET_NUMBER_OFFSET    EQU BYTES_IN_ALL_REG+4

* Draws two digit number
* Input Long-d2: Number to display
* Output       : Draws 7 segment number to screen with lines
* No Return
DRAW_TWO_DIGIT_NUMBER:
    movem.l ALL_REG, -(sp)
    
    ; Draw the Box that surround seven segment display
    move.l  #SET_PEN_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15
    moveq.l #DRAW_RECT_TASK, d0
    move.l  #(SEGMENT_ONES_PLACE_POS_X-SEGMENT_PLACE_X_OFFSET*2-SEGMENT_BACKGROUND_PADDING), d1
    move.l  #(SEGMENT_ONES_PLACE_POS_Y-SEGMENT_BACKGROUND_PADDING), d2
    move.l  #(SEGMENT_ONES_PLACE_POS_X+SEGMENT_LENGTH+SEGMENT_BACKGROUND_PADDING), d3
    move.l  #(SEGMENT_ONES_PLACE_POS_Y+SEGMENT_LENGTH*2+SEGMENT_BACKGROUND_PADDING), d4
    trap    #15

    moveq.l #0, d5                      ; Clear d5 for place value offsets
    moveq.l #0, d6                      ; Clear d6
    moveq.l #0, d7                      ; and d7 for segment encodings

    moveq.l #SET_PEN_WIDTH_TASK, d0
    move.l  #SEGMENT_WIDTH, d1
    trap    #15                         ; Set segment width
    
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #SEVEN_SEGMENT_NUMBER_COLOR, d1
    trap    #15                         ; Set segment color
    
    move.l  (TARGET_NUMBER_OFFSET)(sp), d2

    ; Get the place values from the target number
    divu    #SEGMENT_NUMBER_BASE, d2    ; Divide by 10
    move.w  d2, d3                      
    swap    d2                          ; 1s   -> d2
    
    divu    #SEGMENT_NUMBER_BASE, d3
    move.w  d3, d4                      ; 100s -> d4
    swap    d3                          ; 10s  -> d3
    
    ; Get encodings for each number
    lea     NumberSegmentEncoding, a5
    move.b  (a5, d2.w), d6
    move.b  (a5, d3.w), d7
    move.b  (a5, d4.w), d4
    and.w   #$00FF, d4
    
    ; ONES ----------------------------------------------------------
    lea     SegmentRoutineTable, a5
    move.l  (SegmentRoutineTable), a6
SEVEN_SEGMENT_ONES_LOOP:
    btst    #0, d6                      ; Checks if lowest bit == 0
    beq     SKIP_SEGMENT_ONES_DRAW      ; Skips when lowest bit == 0
    move.w  d4, -(sp)
    jsr     (a6)
    move.w  (sp)+, d4
    
SKIP_SEGMENT_ONES_DRAW:
    add.l   #BYTES_IN_LONG, a5
    move.l  (a5), a6
    lsr     #1, d6
    cmp.b   #0, d6                      ; Branch if remaining segments
    bne     SEVEN_SEGMENT_ONES_LOOP
    
    ; TENS ----------------------------------------------------------
    add.l   #SEGMENT_PLACE_X_OFFSET, d5
    lea     SegmentRoutineTable, a5
    move.l  (SegmentRoutineTable), a6
SEVEN_SEGMENT_TENS_LOOP:
    btst    #0, d7                      ; Checks if lowest bit == 0
    beq     SKIP_SEGMENT_TENS_DRAW      ; Skips when lowest bit == 0
    move.w  d4, -(sp)
    jsr     (a6)
    move.w  (sp)+, d4
    
SKIP_SEGMENT_TENS_DRAW:
    add.l   #BYTES_IN_LONG, a5
    move.l  (a5), a6
    lsr     #1, d7
    cmp.b   #0, d7              ; Branch if remaining segments
    bne     SEVEN_SEGMENT_TENS_LOOP  
    
    

    ; HUNDREDS ------------------------------------------------------
    add.l   #SEGMENT_PLACE_X_OFFSET, d5
    lea     SegmentRoutineTable, a5
    move.l  (SegmentRoutineTable), a6
SEVEN_SEGMENT_HUNDREDS_LOOP:
    btst    #0, d4                      ; Checks if lowest bit == 0
    beq     SKIP_SEGMENT_HUNDREDS_DRAW      ; Skips when lowest bit == 0
    move.w  d4, -(sp)
    jsr     (a6)
    move.w  (sp)+, d4
    
SKIP_SEGMENT_HUNDREDS_DRAW:
    add.l   #BYTES_IN_LONG, a5
    move.l  (a5), a6
    lsr     #1, d4
    cmp.b   #0, d4              ; Branch if remaining segments
    bne     SEVEN_SEGMENT_HUNDREDS_LOOP 
  
    
    moveq.l #SET_PEN_WIDTH_TASK, d0
    move.l  #1, d1
    trap    #15                         ; Reset width
    moveq.l #SET_PEN_COLOR_TASK, d0
    move.l  #WHITE, d1
    trap    #15                         ; Reset segment color
    
    movem.l (sp)+, ALL_REG
    rts
    
* All Segments draw the specified segment from a seven segemnt display
* Input word-d5: an offset in the x position
* Output       : Draws the segment as a line to screen 
* No Return
A_SEGMENT:
    moveq.l #DRAW_LINE_START_END_TASK, d0
    move.l  #SEGMENT_ONES_PLACE_POS_X, d1
    sub.l   d5, d1
    move.l  #SEGMENT_ONES_PLACE_POS_Y, d2
    move.l  #(SEGMENT_ONES_PLACE_POS_X+SEGMENT_LENGTH), d3
    sub.l   d5, d3
    move.l  #SEGMENT_ONES_PLACE_POS_Y, d4
    trap    #15
    rts

B_SEGMENT:
    moveq.l #DRAW_LINE_START_END_TASK, d0
    move.l  #(SEGMENT_ONES_PLACE_POS_X+SEGMENT_LENGTH), d1
    sub.l   d5, d1
    move.l  #SEGMENT_ONES_PLACE_POS_Y, d2
    move.l  #(SEGMENT_ONES_PLACE_POS_X+SEGMENT_LENGTH), d3
    sub.l   d5, d3
    move.l  #(SEGMENT_ONES_PLACE_POS_Y+SEGMENT_LENGTH), d4
    trap    #15

    rts

C_SEGMENT:
    moveq.l #DRAW_LINE_START_END_TASK, d0
    move.l  #(SEGMENT_ONES_PLACE_POS_X+SEGMENT_LENGTH), d1
    sub.l   d5, d1
    move.l  #(SEGMENT_ONES_PLACE_POS_Y+SEGMENT_LENGTH), d2
    move.l  #(SEGMENT_ONES_PLACE_POS_X+SEGMENT_LENGTH), d3
    sub.l   d5, d3
    move.l  #(SEGMENT_ONES_PLACE_POS_Y+SEGMENT_LENGTH*2), d4
    trap    #15

    rts

D_SEGMENT:
    moveq.l #DRAW_LINE_START_END_TASK, d0
    move.l  #(SEGMENT_ONES_PLACE_POS_X), d1
    sub.l   d5, d1
    move.l  #(SEGMENT_ONES_PLACE_POS_Y+SEGMENT_LENGTH*2), d2
    move.l  #(SEGMENT_ONES_PLACE_POS_X+SEGMENT_LENGTH), d3
    sub.l   d5, d3
    move.l  #(SEGMENT_ONES_PLACE_POS_Y+SEGMENT_LENGTH*2), d4
    trap    #15

    rts

E_SEGMENT:
    moveq.l #DRAW_LINE_START_END_TASK, d0
    move.l  #(SEGMENT_ONES_PLACE_POS_X), d1
    sub.l   d5, d1
    move.l  #(SEGMENT_ONES_PLACE_POS_Y+SEGMENT_LENGTH), d2
    move.l  #(SEGMENT_ONES_PLACE_POS_X), d3
    sub.l   d5, d3
    move.l  #(SEGMENT_ONES_PLACE_POS_Y+SEGMENT_LENGTH*2), d4
    trap    #15

    rts

F_SEGMENT:
    moveq.l #DRAW_LINE_START_END_TASK, d0
    move.l  #(SEGMENT_ONES_PLACE_POS_X), d1
    sub.l   d5, d1
    move.l  #(SEGMENT_ONES_PLACE_POS_Y), d2
    move.l  #(SEGMENT_ONES_PLACE_POS_X), d3
    sub.l   d5, d3
    move.l  #(SEGMENT_ONES_PLACE_POS_Y+SEGMENT_LENGTH), d4
    trap    #15

    rts

G_SEGMENT:
    moveq.l #DRAW_LINE_START_END_TASK, d0
    move.l  #(SEGMENT_ONES_PLACE_POS_X), d1
    sub.l   d5, d1
    move.l  #(SEGMENT_ONES_PLACE_POS_Y+SEGMENT_LENGTH), d2
    move.l  #(SEGMENT_ONES_PLACE_POS_X+SEGMENT_LENGTH), d3
    sub.l   d5, d3
    move.l  #(SEGMENT_ONES_PLACE_POS_Y+SEGMENT_LENGTH), d4
    trap    #15

    rts
    
                        dc.w    1
SegmentRoutineTable     dc.l    A_SEGMENT, B_SEGMENT, C_SEGMENT, D_SEGMENT
                        dc.l    E_SEGMENT, F_SEGMENT, G_SEGMENT
                        
                        dc.w    1
NumberSegmentEncoding   dc.b    %00111111, %00000110, %01011011, %01001111, %01100110
                        dc.b    %01101101, %01111101, %00000111, %01111111, %01101111
                        dc.w    1
    
























*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

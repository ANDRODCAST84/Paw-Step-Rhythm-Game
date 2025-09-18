*-----------------------------------------------------------
* Title      : Sound file init
* Written by : Albert Castrejon
* Date       : 6/2/25
* Description: Initializes the songs and their respective sound files
*-----------------------------------------------------------

INITIALIZE_SOUNDS:
    ; Halt on load - Prevent running if wrong file type
    move.l  (ChosenSound), a0
    cmp.l   #SOUND_FILE_SIGNATURE, (a0)    
    beq     CORRECT_SOUND_SIGNATURE
    
    move.l  #PRINT_CR_LF_TASK, d0
    lea     Error_WrongSOUNDSignature, a1
    trap    #15                                     ; Print out error message
    
    SIMHALT
CORRECT_SOUND_SIGNATURE:
    move.l  OFFSET_SOUND_TEMPO(a0), d7              ; Tempo
    move.l  d7, d3                                  ; Save tempo for note offset and speed
    
    divu    OFFSET_SOUND_QUARTER_NOTE_TICKS(a0), d7 ; Tempo / Tick per quarter note -> d7
    swap    d7
    move.w  #0, d7
    swap    d7                                      ; Clear upper word
    
    move.w  OFFSET_KEYPRESS_AMOUNT(a0), d6
    move.l  d6, (TotalNotes)                        ; Number of notes
    move.l  d6, (EndTotalNotes)                     ; Save for end screen
    move.w  OFFSET_EVENTS_AMOUNT(a0), d6            ; Number of events
    subi.w  #DBRA_ADJUSTMENT, d6                    ; Number of events counter -> d6
    
    
    ; Getting note timing spawn offset and Note speed -------------------------
    
    ; Tempo / 1000
    move.l  #1000, -(sp)
    move.l  d3, -(sp)
    jsr     DIVIDE_WITH_ROUNDING
    lea     (ROUNDING_DIVIDE_PARAM_SIZE)(sp), sp
    move.l  (RETURN)(sp), d3                                ; Time in a beat
    
    ; (Time per beat) * 4 = Full measure
    lsl.l   #2, d3
    move.l  d3, (NoteSpawnOffsetTime)                       ; Save note spawn time offset
    
    
    ; (Time per measure) / 10 = Time per measure in Centiseconds
    move.l  #10, -(sp)
    move.l  d3, -(sp)
    jsr     DIVIDE_WITH_ROUNDING
    lea     (ROUNDING_DIVIDE_PARAM_SIZE)(sp), sp
    move.l  (RETURN)(sp), d3
    
    ; (Play Area Height) / (Time per measure in Ccentiseconds) = Note speed in centiseconds
    
    move.l  #((PLAY_AREA_BOTTOM_Y+1)<<FIXED_POINT_BITS), d0 ; PlayArea Height in fixed point
    move.l  d3, -(sp)
    move.l  d0, -(sp)
    jsr     DIVIDE_WITH_ROUNDING
    lea     (ROUNDING_DIVIDE_PARAM_SIZE)(sp), sp
    move.l  (RETURN)(sp), d3
    
    move.l  d3, (NoteSpeedPixelCentiSecond)                 ; Final speed calculation for notes
    ; -------------------------------------------------------------------------
    
    
    
    lea     OFFSET_START_NOTE_EVENTS(a0), a1
    moveq.l #0, d3                                          ; d3 Total Time passed
    
    ; Get all note spawn times reduced by the offset time to account for travel time
PROCESS_EVENTS:
    lea     SongLaneTimingTable, a6
    
    moveq.l #0, d0
    moveq.l #0, d1
    moveq.l #0, d2
    
    move.b  (a1)+, d0                           ; First ticks byte
    
    ; Check if first bit is set indicating multibyte length delta ticks
    btst    #7, d0
    beq     SKIP_VARIABLE_LENGTH_CONVERSION     ; Branch if msb is NOT set ~ 1 byte delta ticks
   
    and.b   #%01111111, d0                      ; Set first bit to 0
    lsl.l   #7, d0                                          
    move.b  (a1)+, d2                           ; Get second ticks byte
    
SKIP_VARIABLE_LENGTH_CONVERSION:
    add.l   d0, d2                              ; Total delta ticks -> d2
    move.b  (a1)+, d1                           ; Event -> d1
    
    
    mulu    d7, d2                              ; Ticks per quarter note * Delta Ticks
    
    
    move.l  #1000, -(sp)
    move.l  d2, -(sp)                           ; / 1000 to get miliseconds
    jsr     DIVIDE_WITH_ROUNDING
    lea     (ROUNDING_DIVIDE_PARAM_SIZE)(sp), sp
    move.l  (RETURN)(sp), d2

    add.l   d2, d3                              ; Add to total Time in miliseconds
    
    ; Check for note pressed event
    cmp.b   #NOTE_PRESSED_EVENT, d1     
    bne     NO_NOTE_PRESSED                     ; Branch and skip if NOT note pressed event
    
    moveq.l #0, d0
    move.b  (a1), d0                            ; Get Note lane
    lsl.l   #2, d0                              ; Multiply by 4 for indexing
    
    lea     (a6, d0), a6                        ; Index to correct lanes timing table
    move.l  (a6), a0                            ; Access the timing table
    add.l   #2, (a6)                            ; Increment that tables index
     
    move.l  d3, d1
    sub.l  (NoteSpawnOffsetTime), d1            ; Reduce time to account for spawning offscreen
    add.l   #1, d1
    move.w  d1, (a0)                            ; Push time to list of spawn times

NO_NOTE_PRESSED:
    add.l   #2, a1                              ; skip to next delta time
    dbra    d6, PROCESS_EVENTS                  ; Continue processing events
    
    ; Get the speed for the progress bar fill
    
    ; (Total time passed) / 10 = total time passed in centiseconds
    move.l  #10, -(sp)
    move.l  d3, -(sp)                           
    jsr     DIVIDE_WITH_ROUNDING
    lea     (ROUNDING_DIVIDE_PARAM_SIZE)(sp), sp
    move.l  (RETURN)(sp), d3    
           
    move.l  #((PROGRESS_BAR_BOTTOM_Y-PROGRESS_BAR_TOP_Y)<<FIXED_POINT_BITS), d0 
    
    ; ProgressBar Height / Total time centiseconds = Speed in fill rate in pixels per centi seconds
    move.l  d3, -(sp)                   
    move.l  d0, -(sp)
    jsr     DIVIDE_WITH_ROUNDING
    lea     (ROUNDING_DIVIDE_PARAM_SIZE)(sp), sp
    move.l  (RETURN)(sp), d0
    
    move.l  d0, (ProgressSpeedPixelCentiSecond) ; Final speed for progressbar progression
    
    rts
    
    
    
    














*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

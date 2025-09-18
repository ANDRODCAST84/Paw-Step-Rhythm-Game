*-----------------------------------------------------------
* Title      : Random Number Generator
* Written by : Albert Castrejon
* Date       : 6/16/25
* Description: Generates random numbers based off time based seed
*-----------------------------------------------------------
    
; Generates a seed based on current time
GENERATE_RANDOM_NUMBER_SEED
    move.l  #GET_TIME_TASK, d0
    trap    #15
    
    move.l  d1, (RandomNumberSeed)
    rts
    
    ; Gets a random number from 0-5 -> 6 total possibilitis
GET_RANDOM_0_5_D7
    move.l  (RandomNumberSeed), d0
    moveq   #-79, d1
    moveq   #18, d2


NINC0	
	add.l	d0, d0
	bcc	    NINC1
	
	eor.b	d1, d0
NINC1
	dbra	d2, NINC0

    ; Get the remeinder to get number between 0-5
    move.l  d0, (RandomNumberSeed)
    clr.l   d7
    move.b  d0, d7
    divu    #6, d7
    swap    d7                      
    ext.l   d7        

    rts


RandomNumberSeed        ds.l    1



















*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

*-----------------------------------------------------------
* Title      : System Clock
* Written by : Albert Castrejon
* Date       : 5/30/25
* Description: Handles getting delta time from the system clock
*-----------------------------------------------------------

*   Output:      DeltaTime = Time since last frame
*                PreviousTime = New Current time to use for next call
GET_DELTA_TIME:    
    moveq.l #GET_TIME_TASK, d0
    trap    #15                 ; New current time -> d1
    move.l  d1, d2              ; Save for next PreviousTime
    
    sub.l   (PreviousTime), d1  ; Current - prev
    move.l  d2, (PreviousTime)  ; Update with new Previous time
    
    move.l  d1, (DeltaTime)     ; Update Delta Time
    
    rts


*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

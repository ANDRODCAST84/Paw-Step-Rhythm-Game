*-----------------------------------------------------------
* Title      : RoundingDivide
* Written by : Albert Castrejon
* Date       : 6/5/25
* Description: Divides 2 numbers with rounding
*-----------------------------------------------------------

ROUNDING_DIVIDE_REG             REG d0-d2
ROUNDING_DIVIDE_REG_SIZE        EQU BYTES_IN_LONG*3

DIVIDEND                        EQU ROUNDING_DIVIDE_REG_SIZE+4
DIVISOR                         EQU ROUNDING_DIVIDE_REG_SIZE+8
ROUNDING_DIVIDE_PARAM_SIZE      EQU BYTES_IN_LONG*2

ROUNDING_DIVIDE_RETURN_OFFSET   EQU ROUNDING_DIVIDE_REG_SIZE+ROUNDING_DIVIDE_PARAM_SIZE

* Put variables and constants here

* Inputs Dividend: Number being divided
*        Divisor:  Nuber to divide by
* Output           Divided number with rounding taken into account
* Return RETURN:   Quotient with rounding
DIVIDE_WITH_ROUNDING:
    movem.l ROUNDING_DIVIDE_REG, -(sp)
    move.l  (DIVISOR)(sp), d0
    move.l  (DIVIDEND)(sp), d1
    move.l  d1, d2
    
    ; Get remeinder
    divu    d0, d2
    move.w  #0, d2
    swap    d2
    
    
    add.l   d2, d1
    
    ; Final Quotient
    divu    d0, d1
    swap    d1
    move.w  #0, d1
    swap    d1
    
    move.l  d1, ROUNDING_DIVIDE_RETURN_OFFSET(sp) ; Put in stack accessable outside of func
                                                  ; using (RETURN)(sp)
    movem.l (sp)+, ROUNDING_DIVIDE_REG
    rts


*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

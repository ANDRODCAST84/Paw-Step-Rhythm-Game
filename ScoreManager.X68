*-----------------------------------------------------------
* Title      : Score Manager
* Written by : Albert Castrejon
* Date       : 6/17/25
* Description: Handles saving and deleting song information
*-----------------------------------------------------------
   
   ; Saves the song stats into the saved data file
SAVE_SONG_INFORMATION:
    jsr     OPEN_COMPLETION_FILE
    move.l  d1, (FileID)
    
    move.l  (EndNotesHit), d0
    move.l  (EndTotalNotes), d1
    
    ; (Notes hit * 100) / Total notes
    mulu    #100, d0
    divu    d1, d0                      ; Percentage of song complete
    move.b  d0, d5
    
    ; Position file cursor to data location for the selected song
    move.l  #POSITION_FILE_TASK, d0
    move.l  (FileID), d1
    move.l  (CurrentChoiceIndex), d2
    lsr.l   #2, d2                      ; Byte based indexing
    trap    #15
    
    ; Read in the data currently there
    move.l  #READ_FILE_TASK, d0
    move.l  (FileID), d1
    move.l  #1, d2
    lea     CompletionData, a1          ; Get data -> CompletionData
    trap    #15
    
    ; Compare New data to previous data
    cmp.b   (CompletionData), d5        
    ble     SKIP_SET_NEW_SCORE          ; Branch and skip setting new score if previous is higher
    
    move.l  #POSITION_FILE_TASK, d0
    move.l  (FileID), d1
    move.l  (CurrentChoiceIndex), d2
    lsr.l   #2, d2                      ; Byte based indexing
    trap    #15
    
    ; Update with new score
    move.b  d5, (CompletionData)        
    move.l  #WRITE_FILE_TASK, d0
    lea     CompletionData, a1
    move.l  (FileID), d1
    move.l  #1, d2
    trap    #15
    
    move.l  #1, (HighscoreAchieved)
    
SKIP_SET_NEW_SCORE:
    move.l  #CLOSE_FILE_TASK, d0
    move.l  (FileID), d1
    trap    #15
    

    rts
    
    
    ; Delete saved data file
DELETE_SONG_INFORMATION:
    move.l  #CLOSE_FILE_TASK, d0
    move.l  (FileID), d1
    trap    #15
    
    move.l  #DELETE_FILE_TASK, d0
    lea     SongCompletionFile, a1
    trap    #15

    rts
    
    ; Input              d6 - Index to read from
    ; Output CompletionData - Data read from file
READ_SONG_INFORMATION:
    jsr     OPEN_COMPLETION_FILE
    
    ; d1 - FileID
    move.l  #POSITION_FILE_TASK, d0
    move.l  d6, d2                      ; Move to desired song data location
    trap    #15
    
    move.l  #READ_FILE_TASK, d0
    move.l  (FileID), d1
    move.l  #1, d2
    lea     CompletionData, a1          ; Get data -> CompletionData
    trap    #15
  
    move.l  #CLOSE_FILE_TASK, d0
    move.l  (FileID), d1
    trap    #15

    rts
    
    ; Return (FileID)
OPEN_COMPLETION_FILE:
    ; Attempt to open an existing file
    move.l  #OPEN_EXISTING_FILE_TASK, d0
    lea     SongCompletionFile, a1
    trap    #15  
    
    ; Check fileID
    cmp.l   #FILE_NOT_FOUND, d1
    bne     SKIP_CREATE_FILE            ; Branch and skip new file creation when fileID != FileNotFound
    
    ; Create and open new save data file
    move.l  #OPEN_NEW_FILE_TASK, d0
    lea     SongCompletionFile, a1
    trap    #15
    
    move.l  d1, (FileID)
    
    move.l  #WRITE_FILE_TASK, d0
    lea     EmptyFileData, a1
    move.l  #EMPTY_FILE_LENGTH, d2
    trap    #15
    
    move.l  #CLOSE_FILE_TASK, d0
    move.l  (FileID), d1
    trap    #15
    
    move.l  #OPEN_EXISTING_FILE_TASK, d0
    lea     SongCompletionFile, a1
    trap    #15
    
    
SKIP_CREATE_FILE:
    move.l  d1, (FileID)
    rts

SongCompletionFile      dc.b    'SavedData/Songs.COMPLETIONS',0
FileID                  ds.l    1
CompletionData          ds.b    1
EmptyFileData           DCB.B   EMPTY_FILE_LENGTH,0
                        ds.w    0
    
    
    
    



*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~

SOUND header

OFF| Hex Data    | Comments
SET| Example     |
------------------
00 | 53 4F 4E 44 | SOND file type
04 | 00 60       | 96 Midi Ticks per quarter note
06 | 00 0F 42 40 | Midi Tempo 
0A | 00 7E       | Total number of events
0C | 00 3F       | Total number of key presses (Event 90)

Start of data
0E | 00 90 01 64 | Start of note events 4bytes each
         .  
	 .
|Delta Ticks, Event, Lane, Velocity|

Events: 90 - Key Pressed
	80 - Key Released

To get delta time in thousands of a second (e.g. 1 second would be 1000) 
((Tempo / Ticks per quarter note) * Delta Ticks) / 1000 = dt

dt * 10000 / (Tempo / Ticks per quarter note) = Delta Ticks

[IMPORTANT NOTE]
There may be variable length Delta Ticks
Example:
0E | 81 60 90 01 64 | Delta Ticks = 82 60

If the first byte of the Delta Ticks has the MSB set to '1',
like in the case '81', flip the MSB and shift over 7 bits.

This happens if the ticks ever exceed 7F, the variable length ticks
can be read as so | 82 60 | =  0x02<<7 + 0x60 = 0x160


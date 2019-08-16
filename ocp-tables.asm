; OCP-tables.asm - central gathering point for all data kept in tables.
; By Sean Igo for the One Chip Poker project
; Copyright 2002-2005, Sean Igo. 

; renderscore's centering table!
; 01234567890123456789
;|     Worthless      | col 5
;|  Jacks or Better   | col 2
;|      Two Pair      | col 6
;|  Three of a Kind   | col 2
;|      Straight      | col 6
;|       Flush        | col 7
;|     Full House     | col 5
;|   Four of a Kind   | col 3
;|   Straight Flush   | col 3
;|    Royal Flush     | col 4

scorectr

	clrf	PCLATH						; DANGER assuming table on page 0! only need this b/c text rendering messes w/it
	addwf	PCL,F						; table lookup!

	retlw	5							;|     Worthless      | col 5
	retlw	2							;|  Jacks or Better   | col 2
	retlw	6							;|      Two Pair      | col 6
	retlw	2							;|  Three of a Kind   | col 2
	retlw	6							;|      Straight      | col 6
	retlw	7							;|       Flush        | col 7
	retlw	5							;|     Full House     | col 5
	retlw	3							;|   Four of a Kind   | col 3
	retlw	3							;|   Straight Flush   | col 3
	retlw	4							;|    Royal Flush     | col 4

	; HANDY ERROR BLOCK FOR CHECKING IF TABLES OOZE OVER PAGES. Don't need for "long"-access tables like scoredata thing.
	; doesn't seem to work in mplab x idea v5.25 - I will try finding out how to do this (make an issue!)
	; FIX IS TO BUILD IN ABSOLUTE MODE, do right click project, get Properties, go to the MPASM (Global Options)
	; settings, check Build in Absolute mode.
	if ((high $) != (high scorectr))
	error "scorectr wraps a page!"
	endif

; more tables: lobyte / hibyte for string for given score.

scorestrlow

	clrf	PCLATH						; DANGER assuming table on page 0! only need this b/c text rendering messes w/it
	addwf	PCL,F						; table lookup!
	retlw	Low str_score0
	retlw	Low str_score1
	retlw	Low str_score2
	retlw	Low str_score3
	retlw	Low str_score4
	retlw	Low str_score5
	retlw	Low str_score6
	retlw	Low str_score7
	retlw	Low str_score8
	retlw	Low str_score9

	if ((High $) != (High scorestrlow)) 
	error "scorestrlow wraps a page!"
	endif

scorestrhigh

	clrf	PCLATH						; DANGER assuming table on page 0! only need this b/c text rendering messes w/it
	addwf	PCL,F						; table lookup!
	retlw	High str_score0
	retlw	High str_score1
	retlw	High str_score2
	retlw	High str_score3
	retlw	High str_score4
	retlw	High str_score5
	retlw	High str_score6
	retlw	High str_score7
	retlw	High str_score8
	retlw	High str_score9

	if ((High $) != (High scorestrhigh)) 
	error "scorestrhigh wraps a page!"
	endif

chardata

	clrf	PCLATH						; DANGER assuming table on page 0! only need this b/c text rendering messes w/it
	addwf	PCL,F						; table lookup!

										;heart char
			;'---*****'					;only get to use lowest order 5 bits
	retlw	b'00001010'		; @ @	
	retlw	b'00010101'		;@ @ @
	retlw	b'00010001'		;@   @
	retlw	b'00010001'		;@   @
	retlw	b'00010001'		;@   @
	retlw	b'00001010'		; @ @
	retlw	b'00000100'		;  @
	retlw	b'00000000'

										;diamond
	retlw	b'00000100'		;  @  
	retlw	b'00001010'		; @ @
	retlw	b'00010001'		;@   @
	retlw	b'00010001'		;@   @
	retlw	b'00010001'		;@   @
	retlw	b'00001010'		; @ @
	retlw	b'00000100'		;  @  
	retlw	b'00000000'

										;club
	retlw	b'00000100'		;  @  
	retlw	b'00001110'		; @@@
	retlw	b'00010101'		;@ @ @
	retlw	b'00011011'		;@@ @@
	retlw	b'00010101'		;@ @ @
	retlw	b'00000100'		;  @  
	retlw	b'00001110'		; @@@
	retlw	b'00000000'

										;spade
	retlw	b'00000100'		;  @  
	retlw	b'00001110'		; @@@
	retlw	b'00011111'		;@@@@@
	retlw	b'00011111'		;@@@@@
	retlw	b'00011111'		;@@@@@
	retlw	b'00000100'		;  @   
	retlw	b'00001110'		; @@@
	retlw	b'00000000'
					
										;ten
	retlw	b'00010111'		;@ @@@
	retlw	b'00010101'		;@ @ @
	retlw	b'00010101'		;@ @ @
	retlw	b'00010101'		;@ @ @
	retlw	b'00010101'		;@ @ @
	retlw	b'00010101'		;@ @ @
	retlw	b'00010111'		;@ @@@
	retlw	b'00000000'

										;"HE"
	retlw	b'00010111'		;@ @@@
	retlw	b'00010110'		;@ @@
	retlw	b'00010110'		;@ @@
	retlw	b'00011111'		;@@@@@
	retlw	b'00010110'		;@ @@
	retlw	b'00010110'		;@ @@
	retlw	b'00010111'		;@ @@@
	retlw	b'00000000'

										;"LD"
	retlw	b'00010110'		;@ @@
	retlw	b'00010101'		;@ @ @
	retlw	b'00010101'		;@ @ @
	retlw	b'00010101'		;@ @ @
	retlw	b'00010101'		;@ @ @
	retlw	b'00010101'		;@ @ @
	retlw	b'00011110'		;@@@@
	retlw	b'00000000'

										;Card back - checkerboard which might be a standard character, but let's not risk it. 
	retlw	b'00010101'		;@ @ @
	retlw	b'00001010'		; @ @
	retlw	b'00010101'		;@ @ @
	retlw	b'00001010'		; @ @
	retlw	b'00010101'		;@ @ @
	retlw	b'00001010'		; @ @
	retlw	b'00010101'		;@ @ @
	retlw	b'00000000'

	if ((High $) != (High chardata)) 
	error "chardata wraps a page!"
	endif

; rankchars is the table that returns the character to send to the LCD for a given rank.

rankchars

	clrf	PCLATH						; DANGER assuming table on page 0! only need this b/c text rendering messes w/it
	addwf	PCL,F						; table lookup!

	retlw	'A'							; 0 - Ace - 'A'
	retlw	'2'							; 1 - 2
	retlw	'3'							; 2 - 3
	retlw	'4'							; 3 - 4
	retlw	'5'							; 4 - 5
	retlw	'6'							; 5 - 6
	retlw	'7'							; 6 - 7
	retlw	'8'							; 7 - 8
	retlw	'9'							; 8 - 9
	retlw	D'4'						; 9 - 10 - custom char 4 is the one-character 10.
	retlw	'J'							; 10 - Jack - 'J'
	retlw	'Q'							; 11 - Queen - 'Q'
	retlw	'K'							; 12 - King - 'K'


	; HANDY ERROR BLOCK FOR CHECKING IF TABLES OOZE OVER PAGES. Don't need for "long"-access tables like scoredata thing.
	if ((High $) != (High rankchars)) 
	error "rankchars wraps a page!"
	endif


; call paydata with the score 0 (worthless) .. 9 (royal flush) in W,
; returns one-coin payoff amount in PayoffH:PayoffL

paydata
	movwf	ttemp						; save off index

	clrf	PCLATH						; DANGER ASSUMES TABLE ON PAGE 0
	clrf	PayoffH						; for all but royal flush, hibyte of payoff amount is zero.

	movf	ttemp,W						; restore index

	addwf	PCL,F						; table lookup!

	retlw	.0							;	Nothing	 		0 		
	retlw	.1							;	Pair 			1 		
	retlw	.2							;	Two pair 		2 		
	retlw	.3							;	Three of a kind 3 		
	retlw	.4							;	Straight 		4 		
	retlw	.6							;	Flush 			6 		
	retlw	.9							;	Full house 		9 		
	retlw	.25							;	Four of a kind 	25 		
	retlw	.50							;	Straight flush 	50 		

										;	Royal flush 	800 (0x320)
	movlw	.3							; special case. since it's the last thing in the list we
	movwf	PayoffH						; can have as many instructions as we want & it won't spoil the
	retlw	0x20						; table. So, can stuff PayoffH and let caller jam the returned W in PayoffL.
			
	if ((High $) != (High paydata)) 
	error "paydata wraps a page!"
	endif


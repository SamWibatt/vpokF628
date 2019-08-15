; OCP-TEXT.ASM - String drawing routines and string data for One Chip Video Poker.
; By Sean Igo for the One Chip Poker project
; Copyright 2002-2005, Sean Igo.
;

; So here's the big main string draw routine.
; Must preload StringL with lobyte and StringH with hibyte of string to draw.
; trashes those!

drawstring
										; so: fetch the byte that's at StringH:L.
	call	ds_getchar		
	xorlw	0x00						; is it a zero? xorlw 0 preserves contents of W while setting Z flag appropriately.
	btfsc	STATUS, Z					; so if z not set, nonzero - skip to drawing bit
	return								; found a zero - done!
	call	LCD_Char					; render character
	incf	StringL,F					; do 16-bit inc of string address.
	btfsc	STATUS,Z
	incf	StringH,F
	goto	drawstring


; ds_getchar is the little routine to call b/c the data's retlws need a stack entry to go back to.
; Long Table style.

ds_getchar
	movf	StringH,W
	movwf	PCLATH
	movf	StringL,W
	movwf	PCL	

; SPECIFIC DRAW ROUTINES ===========================================================================================================

; draw opening splash-screen.

drawsplash
	call	LCD_Clr
	call	LCD_Line1
	movlw	High str_splash0	
	movwf	StringH
	movlw	Low str_splash0	
	movwf	StringL
	call	drawstring

	call	LCD_Line2
	movlw	High str_splash1
	movwf	StringH
	movlw	Low str_splash1
	movwf	StringL
	call	drawstring
	
	call	LCD_Line4
	movlw	High str_splash2
	movwf	StringH
	movlw	Low str_splash2
	movwf	StringL
	call	drawstring
	return

; DATA =============================================================================================================================
;      "01234567890123456789" - guideline for 20 chars wide.

str_splash0
	dt "**** Welcome to ****", 0
str_splash1
	dt "One Chip Video Poker", 0
str_splash2
	dt "-Press Deal to Play-", 0

str_score0
	dt "Worthless", 0
str_score1
	dt "Jacks or Better", 0
str_score2
	dt "Two Pair", 0
str_score3
	dt "Three of a Kind", 0
str_score4
	dt "Straight", 0
str_score5
	dt "Flush", 0
str_score6
	dt "Full House", 0
str_score7
	dt "Four of a Kind", 0
str_score8
	dt "Straight Flush", 0
str_score9
	dt "Royal Flush", 0



; bet screen stuff
; 01234567890123456789
; --------------------
;|    Coins: 00000    |
;|       Bet: 0       |
;|    Bet 1 or max    |
;|Bet Max/Deal to Play| 
; --------------------


str_bet0
	dt	"Coins:", 0
str_bet1
	dt	"Bet:", 0
str_bet2
	dt	"Bet 1 or Max", 0
str_bet3
	dt  "Bet Max/Deal to Play", 0


; game screen stuff
;  --------------------
; |(centered scorename)|
; | RS  RS  RS  RS  RS | <- cards
; | HE  HE  HE  HE  HE | <- held flags
; | Press Deal to Draw | <- for first screen; alternate b/t 
; |Choose Cards to Hold|    THIS and press deal to draw, once a second or so
; |-Press Deal to Play-| <- THIS last line after cards redealt
;  --------------------     
;       Win: 0000        Centered winnings line alternates with scorename on line 1
;  01234567890123456789

str_gamescr0
	dt	" Press Deal to Draw", 0		; render in column 0
str_gamescr1
	dt	"Choose Cards to Hold", 0		; render in column 0
str_gamescr2
	dt	"Win:", 0						; render in column 5, 4-digit win in col 10

; the -Press Deal to Play- is the same as str_splash2.

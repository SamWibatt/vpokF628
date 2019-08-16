; *******************************************************************************************************************
; *******************************************************************************************************************
; *******************************************************************************************************************
; *******************************************************************************************************************
; *******************************************************************************************************************
;
; OCP-MAIN.ASM - main file for One Chip Video Poker.
; By Sean Igo for the One Chip Poker project
; Copyright 2002-2005, Sean Igo.
;
; *******************************************************************************************************************
; *******************************************************************************************************************
; *******************************************************************************************************************
; *******************************************************************************************************************
; *******************************************************************************************************************
;
;wiring:
;
;Port B is the button port, to be used with builtin pullups, so
;no pullups are necessary. All are momentary contact pushbuttons, normally open, connect to ground when closed.
;0 - card 1 hold toggle - to RB0, pin 6
;1 - card 2 hold toggle - to RB1, pin 7
;2 - card 3 hold toggle - to RB2, pin 8
;3 - card 4 hold toggle - to RB3, pin 9
;4 - card 5 hold toggle - to RB4, pin 10
;5 - Bet 1 - to RB5, pin 11
;6 - Bet Max - to RB6, pin 12
;7 - Deal - to RB7, pin 13
;
;Port A is the LCD port.
;LCDPin-Function----Description-----------Pic Pin / other connex
; 1-----Vss --------Ground----------------gnd
; 2-----Vdd --------+ve supply------------+5
; 3-----Vee --------Contrast--------------to wiper of 10K pot b/t +5 and gnd
; 4-----RS ---------Register Select-------to RA4 pin 3, pull up with 10K
; 5-----R/W --------Read/Write------------RA6 pin 15
; 6-----E ----------Enable----------------RA7 pin 16
; 7-----D0 ---------Data bit 0 (8 bit)----nc
; 8-----D1 ---------Data bit 1 (8 bit)----nc
; 9-----D2 ---------Data bit 2 (8 bit)----nc
;10-----D3 ---------Data bit 3 (8 bit)----nc
;11-----D4 ---------Data bit 4------------RA0 pin 17
;12-----D5 ---------Data bit 5------------RA1 pin 18
;13-----D6 ---------Data bit 6------------RA2 pin 1
;14-----D7 ---------Data bit 7------------RA3 pin 2

	LIST	p=16F628				;tell assembler what chip we are using
	include "p16f628.inc"			;include the defaults for the chip - CASE SENSITIVE! windows argh
	ERRORLEVEL	0,	-302			;suppress bank selection messages
	__config 0x3D18					;sets the configuration settings (oscillator type etc.)

; ****************************************************************************************************************************
; ****************************************************************************************************************************
; ****************************************************************************************************************************
; DEBUG DEFINE ***************************************************************************************************************
; ****************************************************************************************************************************
; ****************************************************************************************************************************
; ****************************************************************************************************************************

;#define	DEBUG			;COMMENT OUT FOR REALWORLD VERSION! if defined, makes it possible to step through in software
							;simulator, mostly by skipping input stuff like LCD_Busy and button presses
;#define NO_ORGS			; this causes the org statements in data files to be ignored, so everything is one big packed-together
							; mass. Probably ought to be commented out for certainty about where tables sit.
;#define NO_STIR			; THIS causes there to be no RNG stirring, for testing purposes.

; CONSTANTS-------------------------------------------------------------------------------------------------------------------

LCD_PORT			Equ	PORTA
LCD_TRIS			Equ	TRISA
LCD_RS				Equ	0x04			;LCD handshake lines
LCD_RW				Equ	0x06
LCD_E				Equ	0x07

										;lcd cursor positions INCL command flag, so just load one up & call lcd_cmd
lcdpos_line1		equ	0x80
lcdpos_line2		equ	0xC0
lcdpos_line3		equ	0x94
lcdpos_line4		equ	0xD4

b_flushflag			equ	0				;bit # of flush flag in var fsflags, below
b_straightflag		equ	1				;" straight flag

b_hold1button		equ	0				; bit # in buttonval for Card 1 Hold button
b_hold2button		equ	1				; bit # in buttonval for Card 2 Hold button
b_hold3button		equ	2				; bit # in buttonval for Card 3 Hold button
b_hold4button		equ	3				; bit # in buttonval for Card 4 Hold button
b_hold5button		equ	4				; bit # in buttonval for Card 5 Hold button
b_bet1button		equ 5				; bit # in buttonval for Bet 1 button
b_betmaxbutton		equ 6				; bit # in buttonval for Bet Max button
b_dealbutton		equ 7				; bit # in buttonval for Deal/Draw button

score_royal			equ	9
score_straightflush	equ	8
score_4ofakind		equ	7
score_fullhouse		equ	6
score_flush			equ	5
score_straight		equ	4
score_3ofakind		equ	3
score_twopair		equ	2
score_jacksorbetter	equ	1
score_worthless		equ	0

bankroll_init		equ	.500			; initial bankroll. - was .50.

; VARIABLES------------------------------------------------------------------------------------------------------------------
	cblock 	0x20 						; start of general purpose registers
		count1 							; used in delay routine
		counta 							; used in delay routine 
		countb 							; used in delay routine
		buttonval						; byte read from portb
		buttonlastval					; and previous
		buttonedge						; and the edge-detect version.
		templcd							; temp store for 4 bit mode
		templcd2
		ttemp							; table-temp index holder 
		j								; genl purpose counter (used in showbuttons and maybe later elsewhere)
										; also used in drawcards and getnextcard
		k								; similar - used in dealhand (calls getnextcard)
		rand0							; low byte of 32-bit random number
		rand1
		rand2
		rand3							; high byte of 32-bit random number
		nrnd0							; low byte of random number scratch register (can be used elsewhere but rand32 trashes)
		nrnd1
		nrnd2
		nrnd3							; high byte of random number scratch register

	 	tempsuit						; temp var in flushspot
 		handcopyptr:5					; ptr to copy of hand - used to overlap some other stuff
		temprank						; temp var in paircount
 		scratch0						; temp var in straightspot

 		handptr:0						; pointer to beginning of hand - "union" with card0-4.
 		card0,card1,card2,card3,card4	
 		drawptr:0						; pointer to beginning of draw pool
 		card5,card6,card7,card8,card9	
 		held							; bitfield flags (bits 0..4 corresp to cards
										; 0..4) for which are held.
 		mask							; mask which steps along and finds out held
										; cards in drawcards. temp needed for duration
										; of that.
 		holdmask						; temp for get-hold
 		numdrawn						; counter of how many cards have been drawn
										; so far, in drawcards
 		cind							; save-off for card index in getnextcard.
										; temp, can't share with nrnd b/c gnc calls rand
 		hicard							
 		rawcard							; temp in getnextcard, "raw" random # val (top 6 bits)
 		locard							; shared by drawcards, temp storage for drawn card
 		p								; also shared by lcd_init, as loop counter p
										; shared by sspot, low card
 		fsflags							; bitfield flags; bit 0 = flushflag, bit 1 = straight flag
 		numpairs						; # of pairs in hand.
 		pairrank						; rank of last (only) pair spotted, for determining jacks or better

		score							; save-off for current (pat or drawn) score.
		prevscore						; previous score - for telling if we need to rerender score.

		bet								; number of coins bet on current hand.
	
		CoinsH							; hibyte of player's current coins
		CoinsL

		PayoffH							; hibyte of payoff amount
		PayoffL							; lobyte

		TotalPayoffH					; payoff * bet
		TotalPayoffL

		PrevCoinsH						; for animating payoff
		PrevCoinsL					 

		NumH							; hibyte of 16-bit binary number to convert to decimal
		NumL							; lobyte

		TenK							; decimal digits, unpacked for easy display.
		Thou
		Hund
		Tens
		Ones

		StringL							; low byte of string to render
		StringH							; high byte

		carddelayflag					; if = 1, do delays while drawing cards
		clrct							; counter in LCD_ClrLine
		animct							; timing counter for bet animation, splash screen animation, score/win animation, etc.
		animstate						; state variable for whatever the current animation needs

	endc

	; VARIABLES IN RAM SHARED BY ALL BANKS: 0x70-0x7F
	; MAKE SURE NORMAL VARIABLES DON'T TRAMPLE THIS!!!!!!!!!!!

	cblock	0x70

  		epdata						;data to write to eeprom - eeprom code is all in bank 1, this is a convenience.
		fsrsave

	endc

; CODE-----------------------------------------------------------------------------------------------------------------------
	org	0x0000						;org sets the origin, 0x0000 for the 16F628,
									;this is where the program starts running	
	goto	init_all

	;*************************************************************************************************************************
	;*************************************************************************************************************************
	;*************************************************************************************************************************
	;*************************************************************************************************************************
	;*************************************************************************************************************************
	;*************************************************************************************************************************
	; TABLES INCLUDED HERE FOR STABILITY!
	#include "ocp-tables.asm"
	;*************************************************************************************************************************
	;*************************************************************************************************************************
	;*************************************************************************************************************************
	;*************************************************************************************************************************
	;*************************************************************************************************************************
	;*************************************************************************************************************************

init_all
	movlw	0x07
	movwf	CMCON						; turn comparators off (make it like a 16F84)

   	bsf 	STATUS, RP0					; select bank 1

	bcf		OPTION_REG, NOT_RBPU		; this enables weak pull-ups for any port b pins configured as inputs.

   	movlw 	b'00000000'					; set PortA all outputs, as LCD requires.
	movwf	TRISA				
   	movlw 	b'11111111'					; set PortB all inputs.
   	movwf 	TRISB				

	bcf		STATUS, RP0					;select bank 0


										; ok! time to get rolling. First, housekeeping: clean out the button storage stuff.
	movlw	b'11111111'					; a bit redundant, since we just jammed this in trisb, but oh well.
	movwf	buttonval					; using all-ones since buttons are active low, assume none were pressed a priori.
	movwf	buttonlastval
	movlw	0
	movwf	buttonedge					; and clear out the edge flags.

	call	LCD_Init					; setup LCD
	call	OCP_CustomChars				; setup custom characters!


	; HERE'S WHERE IT REALLY STARTS-------------------------------------------------------------------------------------------
	; get stuff from eeprom
	; show title screen 
	; go!

	call	RestoreCoinsAndSeed			; fetch previously saved # coins and rng seed
	movf	CoinsL,W					; copy coins to PrevCoinsH:L so they're in sync, otherwise
	movwf	PrevCoinsL					; bet screen will animate from PrevCoins uninitialized junk-value
	movf	CoinsH,W
	movwf	PrevCoinsH			

	call	drawsplash
	call	WaitForButton			

	; NOW FOR THE REAL MAIN GAME LOOP.
	; - get bet
	;   - bet screen should show animated coin countup?
	; - deal, score, & render pat hand
	;   - save seed and stash immediately after hand dealt, before scored & rendered
	; - get held flags
	; - draw cards, score, render drawn hand
	; - award payoff if any
	;   - add payoff to stash and save stash immediately, set up to animate payoff
	; - repeat!

mainloop		
	call	betscreen					; on return from here, bet and coins will be ready to go. 

	call	dealhand					; the Big Deal! now pat hand and draw pool are settled.
										; remember random seed in case of power-off.
	call	SaveSeed					; but not coins: if they power off here, they lose the bet coins
										; but never get to play the hand. 

	call	scorehand					; get the score for the hand in W.
	movwf	score						; and save-off in score var.
		
	call	LCD_Clr
	call	rendercards					; it's ON! draw the initial hand.
	call	renderscore					; and we already have the hand's score in score, so draw that too.

	call	getholds					; Get player input for which cards to hold.

	call	drawcards					; so now that we know which cards to hold - draw!

	call	rendercards					; and draw the drawn hand.
	movf	score,W						; save off pat score
	movwf	prevscore
	call	scorehand					; and SCORE new hand!
	movwf	score						; and save-off in score var.
	subwf	prevscore,W					; see if it's the same as original score
	btfsc	STATUS,Z					; if so, don't bother redrawing. avoids flicker
	goto	ml_payoff

										; score differed from pat score, so draw new one.
	call	LCD_Line1					; first, erase original score. 
	call	LCD_ClrLine

	call	renderscore					; so, draw new score.

ml_payoff
	movf	score,W
	call	getpayoff					; gets 1-coin payoff in PayoffH:L
	call	gettotalpayoff				; gets bet-adjusted payoff in TotalPayoffH:L
	movf	CoinsL,W					; copy coins to PrevCoinsH:L for bet screen to animate payoff
	movwf	PrevCoinsL				
	movf	CoinsH,W
	movwf	PrevCoinsH			

	call	addpayoff					; and add payoff to coins.

										; HAND IS DONE!!!!!!!!!!!!!!!!!!!!!!!!

	call	RCS_zerocheck
				
	call	SaveCoins					; AFTER PAYOFF IS MADE, save coins. This then saves the deduction for the bet 
										; and also the payoff.

	call	LCD_Line4					; show "Press Deal to Play"	
	movlw	High str_splash2
	movwf	StringH
	movlw	Low str_splash2
	movwf	StringL
	call	drawstring

										; here, we should bop back and forth on line 1 b/t score and winnings. ?
										; while waiting for the deal button to be pressed.
	clrf	animstate					; here, animation state 0 means score is showing, 1 means winnings.
main_animloop
	movlw	.50							; HARDCODEY value for how often to flip states
	movwf	animct
main_animinnerloop
	call	DelayAndStir				; wait about a 50th of a second, for debouncing. Stir RNG.
	call 	ReadButtons
	btfss	buttonedge,7				; check button 7 (deal) - if edge is zero, it hasn't just been pressed / released
	goto	mai_LoopEnd
	btfsc	buttonval,7					; if button's current value is 0, it's just been pressed (active low!) advance screen.
	goto	mai_LoopEnd
	goto	mainloop					; deal was pressed! start a new game.
	
mai_LoopEnd
	decfsz	animct,F
	goto	main_animinnerloop			; not time to change the phrase @ top of screen yet...

	call	LCD_Line1					; phrase change: in any case, erase top line
	call	LCD_ClrLine

	movlw	1							; toggle low-order bit of animstate.
	xorwf	animstate,F
	btfss	STATUS,Z
	goto	ma_drawwin					; if anim state now = 1, draw winnings.

	call	renderscore					
	goto	main_animloop

ma_drawwin								; and back around again.
	call	renderwin
	goto	main_animloop		

; ReadButtons polls port B to get current snapshot of buttons.
; DOES NOT DO DEBOUNCING DELAY nor RNG stirring - caller needs to do that.
; does do the edge XOR.

ReadButtons
	movf	buttonval,W
	movwf	buttonlastval
										; should just read port B and bam.
	movf	PORTB,W						; grab port b into w.
	movwf	buttonval					; store off, will test later!
	xorwf	buttonlastval,W				; find edges!
	movwf	buttonedge					; and store 'em.
	return

; WaitForButton is really WaitForDealButton.

WaitForButton
	ifdef	DEBUG						;for debug version, do nothing.
	return
	endif

	call	DelayAndStir				; wait about a 50th of a second, for debouncing. Stir RNG.

										; then poll the button.
	call 	ReadButtons

	btfss	buttonedge,7				; check button 7 (deal) - if edge is zero, it hasn't just been pressed / released
	goto	WFB_LoopEnd
	btfsc	buttonval,7					; if button's current value is 0, it's just been pressed (active low!) advance screen.
	goto	WFB_LoopEnd

	return
	
WFB_LoopEnd
	goto	WaitForButton


; program-specific subroutines ------------------------------------------------------------------------------------------------

; Line Clearer - caller puts the cursor at the beginning of a line,
; then calls this to clear it.

LCD_ClrLine
	movlw	.20
	movwf	clrct
cl_eraseloop
	movlw	' '
	call	LCD_Char
	decfsz	clrct,F
	goto	cl_eraseloop
	return

; Delay routine ----------------------------------------------

DelayAndStir
	#ifdef NO_STIR
	#else
	call	rand32						; Stir RNG!
	#endif

;Delay	
	movlw	d'20'						;delay 20 ms (4 MHz clock)
	movwf	count1
d1	movlw	0xC7
	movwf	counta
	movlw	0x01
	movwf	countb
Delay_0
	decfsz	counta, f
	goto	$+2
	decfsz	countb, f
	goto	Delay_0

	decfsz	count1	,f
	goto	d1
	retlw	0x00



; BCD CONVERSION ROUTINE-------------------------------------------------------------------------------------------------------------

; This routine downloaded from http://www.piclist.com - 
; Actually probably got it from Nigel Goodwin's code at www.winpicprog.co.uk,
; but his looks a lot like the code from Scott Dattalo's site http://www.dattalo.com/technical/software/pic/bcd.txt
; which is credited to John Payson. So who knows who really wrote it? Wasn't me.

Convert:                        		; Takes number in NumH:NumL
                                		; Returns decimal in
                                		; TenK:Thou:Hund:Tens:Ones
	swapf   NumH, w
	iorlw	B'11110000'
	movwf   Thou
	addwf   Thou,f
	addlw   0XE2
	movwf   Hund
	addlw   0X32
	movwf   Ones
	
	movf    NumH,w
	andlw   0X0F
	addwf   Hund,f
	addwf   Hund,f
	addwf   Ones,f
	addlw   0XE9
	movwf   Tens
	addwf   Tens,f
	addwf   Tens,f
	
	swapf   NumL,w
	andlw   0X0F
	addwf   Tens,f
	addwf   Ones,f
	
	rlf     Tens,f
	rlf     Ones,f
	comf    Ones,f
	rlf     Ones,f
	
	movf    NumL,w
	andlw   0X0F
	addwf   Ones,f
	rlf     Thou,f
	
	movlw   0X07
	movwf   TenK

										; At this point, the original number is
										; equal to
										; TenK*10000+Thou*1000+Hund*100+Tens*10+Ones
										; if those entities are regarded as two's
										; complement binary.  To be precise, all of
										; them are negative except TenK.  Now the number
										; needs to be normalized, but this can all be
										; done with simple byte arithmetic.

	movlw   0X0A                        ; Ten
Lb1:
	addwf   Ones,f
	decf    Tens,f
	btfss   STATUS,C	
	goto   	Lb1
Lb2:
	addwf   Tens,f
	decf    Hund,f
	btfss   STATUS,C	
	goto   	Lb2
Lb3:
	addwf	Hund,f
	decf	Thou,f
	btfss	STATUS,C	
	goto	Lb3
Lb4:
	addwf   Thou,f
	decf    TenK,f
	btfss   STATUS,C	
	goto   	Lb4

	retlw	0x00


; EXTERNAL ROUTINES------------------------------------------------------------------------------------------------------------------
	#include "ocp-game.asm"	
	#include "ocp-lcd.asm"	
	#include "ocp-paytable.asm"			
	#include "lcrng-F628.asm"
	#include "ocp-text.asm"
	#include "LCD20x4-F628.asm"
	#include "ocp-gamescreen.asm"
	#include "ocp-betscreen.asm"
	#include "ocp-epm.asm"
	#include "ocp-epminit.asm"
	#include "ocp-holds.asm"
	end



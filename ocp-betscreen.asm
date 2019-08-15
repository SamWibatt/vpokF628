; ocpbetscreen.asm - handles UI for player betting.
; by Sean Igo for One Chip Video Poker project
; Copyright 2002-2005, Sean Igo

betscreen
	clrf 	bet
	call	LCD_Clr						; initial clear screen
	call	betscreen_drawfixed			; draw unchanging stuff
	call	betscreen_drawcoins			; draw player's bankroll - before payoff, will animate up
	call	betscreen_drawbet			; and current bet, i.e. 0

	movlw	.1
	movwf	animstate					; set up for bet animation - state 1 means do it, 0 means don't

bscr_outerloop
	movlw	.5
	movwf	animct						; animation rate = ca. 10 per sec, ??? ACTUALLY SHOULD SLOW OR SPEED BY HOW MANY LEFT?

bscr_loop
	call	DelayAndStir				; debounce delay, stir RNG

	call	ReadButtons					; and read the buttons!
										; highest priorities: Bet Max first, then Deal, then Bet 1; others ignored.

										; so: let's look for a leading edge on the Bet Max button.
	btfss	buttonedge,b_betmaxbutton	; check button 6 (bet max) - if edge is zero, it hasn't just been pressed / released
	goto	bscr_checkdeal
	btfsc	buttonval,b_betmaxbutton	; if button's current value is 0, it's just been pressed (active low!) 
	goto	bscr_checkdeal

	call	incbet						; increment bet/dec coins etc; carry SET on return if bet is now max
	call	incbet						; but we're not worried about that, call incbet max bet times, and
	call	incbet						; if bet already has some coins in it, incbet is smart enough to clamp it.		 
	call	incbet
	call	incbet
	call	betscreen_drawcoins_sync	; redraw new coin amount
	call	betscreen_drawbet			; and new bet amount
	return								; bet is now max which means play starts. Bail.

bscr_checkdeal	
										; Bet Max wasn't pressed. let's look for a leading edge on the Deal/Draw button!
	btfss	buttonedge,b_dealbutton		; check button 7 (deal/draw) - if edge is zero, it hasn't just been pressed / released
	goto	bscr_checkbet1
	btfsc	buttonval,b_dealbutton		; if button's current value is 0, it's just been pressed (active low!) 
	goto	bscr_checkbet1

	movf	bet,W						;  check to see if bet is 0. if so, do nothing.
	btfsc	STATUS,Z
	goto	bscr_checkbet1				; bet was zero - ignore deal button
	
	return								; bet nonzero - animation would have stopped by now & stuff. We're done, hop out.
				
bscr_checkbet1
										; deal/draw wasn't just pressed EITHER! check for leading edge on Bet 1.
	btfss	buttonedge,b_bet1button		; check button 5 (bet 1) - if edge is zero, it hasn't just been pressed / released
	goto	bscr_loopend
	btfsc	buttonval,b_bet1button		; if button's current value is 0, it's just been pressed (active low!) 
	goto	bscr_loopend

	call	incbet						; increment bet/dec coins etc; carry SET on return if bet is now max
	btfss	STATUS,C		
	goto	bscr_redraw					; bet is not max - redraw but don't return yet.
	call	betscreen_drawcoins_sync	; bet is max - redraw new coin amount
	call	betscreen_drawbet			; and new bet amount
	return								 

bscr_redraw
	call	betscreen_drawcoins_sync	; redraw new coin amount
	call	betscreen_drawbet			; and new bet amount

bscr_loopend

	movf	animstate,W					; see if animation flag is on or off; if zero, don't do any animating.
	btfsc	STATUS,Z
	goto	bscr_loop					; animation flag is 0, so don't animate anything.

										; so: there's animating. Assume that, if PrevCoinsH:L isn't
										; equal to CoinsH:L that PrevCoinsH:L needs incrementing - IF
										; it's time to do it. So, first check timer.
	decfsz	animct,F
	goto	bscr_loop					; not time yet, go back and look for buttons.

	movf	PrevCoinsH,W
	xorwf	CoinsH,W
	btfss	STATUS,Z
	goto	bscr_inccoins				; not equal, do inc.
	movf	PrevCoinsL,W				; hibyte was equal, try low.
	xorwf	CoinsL,W
	btfsc	STATUS,Z
	goto	bscr_stopanim				; lobyte also equal, stop animation!

bscr_inccoins
	incf	PrevCoinsL,F				; PrevCoinsH:L != CoinsH:L, so increment.
	btfsc	STATUS,Z
	incf	PrevCoinsH,F
	call	betscreen_drawcoins			; redraw new coin amount
	goto	bscr_outerloop

bscr_stopanim
	clrf	animstate					; done animating. 
	call	betscreen_drawcoins_sync	; make sure proper # of coins showing
	goto	bscr_loop

; incbet does the following:	 
; - if bet animation is happening, stop it. 
; - if bet is 5, set carry bit and return.
; - otherwise, bet is assumed to be >= 0 and < 5. increment bet, decrement coins.
; - redraw bet and coins.
; - if bet is NOW 5, set carry bit and return.
; - otherwise clear carry bit and return.
; 
; So, it has the effect of stopping animation if any, then incrementing the bet clamped to 5. 
; If the bet is 5, either on entry or through the incrementing, carry set on return so caller
; can tell. DANGER HARDCODE MAX BET 5.
; Why the carry bit? makes for a quick test on return, while retlw would require another line of testing stuff.
		 
incbet

	clrf	animstate					; stop animation.

	movf	bet,W						; check to see if bet is 5 now.
	sublw	.5
	btfss	STATUS,Z
	goto	ib_doinc					; bet is assumed < 5. go increment it.
	bsf		STATUS,C					; bet is 5:	set carry bit
	return
				 
ib_doinc
										; before we can inc bet, must be sure there are coins!
	movf	CoinsH,W
	btfss	STATUS,Z					; if coins high = 0, check low - 
	goto	ib_reallydoinc
	movf	CoinsL,W					; see if coins low also zero - 
	btfss	STATUS,Z
	goto	ib_reallydoinc
	bsf		STATUS,C					; coins were zero - not max, strictly speaking, but max that CAN be bet, so auto-deal.
	return								; therefore, set carry and bail.

ib_reallydoinc
	incf	bet,F						; bet < 5, so increment it.

	decf	CoinsL,F					; decrement coins lobyte
	movf	CoinsL,W
	sublw	0xFF						; if it now = 0xFF, need dec hibyte
	btfsc	STATUS,Z
	decf	CoinsH,F

	movf	bet,W						; check to see if bet is 5 NOW.
	sublw	.5
	btfss	STATUS,Z
	goto	ib_betnot5					; bet still not 5, leave w/ clear carry.
	bsf		STATUS,C					; bet is 5:	set carry bit
	return
		
ib_betnot5
	bcf		STATUS,C			; bet < 5: clear carry & return.
	return	

; DRUDGEROUS DRAWING ROUTINES =======================================================================================================
; kept down here so as to keep the betscreen UI routine clean.

betscreen_drawfixed
	movlw	.4							; Coins: - draw on line 1, column 4
	call	LCD_Line1W	
	movlw	High str_bet0	
	movwf	StringH
	movlw	Low str_bet0	
	movwf	StringL
	call	drawstring

	movlw	.7							; Bet: - line 2, col 7
	call	LCD_Line2W	
	movlw	High str_bet1	
	movwf	StringH
	movlw	Low str_bet1	
	movwf	StringL
	call	drawstring

	movlw	.3							; Bet 1 or Max - line 3, col 3
	call	LCD_Line3W	
	movlw	High str_bet2	
	movwf	StringH
	movlw	Low str_bet2	
	movwf	StringL
	call	drawstring

	call	LCD_Line4					; finally bet max/deal to play - line 4.
	movlw	High str_bet3
	movwf	StringH
	movlw	Low str_bet3
	movwf	StringL
	call	drawstring
	return

; drawcoins actually draws PrevCoinsH:L, to accommodate animation while keeping Coins having the proper value always.
; drawcoins_sync does the same only first forces PrevCoinsH:L to be the same as CoinsH:L, for after animation stops.

betscreen_drawcoins_sync
	movf	CoinsH,W					; sync coins/prevCoins so it draws properly
	movwf	PrevCoinsH
	movf	CoinsL,W
	movwf	PrevCoinsL
betscreen_drawcoins
	movlw	.11							; player's current coin amount - line 1, col 11
	call	LCD_Line1W	

	movf	PrevCoinsH,W				; do decimal conversion of # coins
	movwf	NumH
	movf	PrevCoinsL,W
	movwf	NumL
	call	Convert

	movf	TenK,W						; now show - currently showing leading zeroes, may fix.
	addlw	0x30						; adjust for ascii
	call	LCD_Char
	movf	Thou,W
	addlw	0x30
	call	LCD_Char
	movf	Hund,W
	addlw	0x30
	call	LCD_Char
	movf	Tens,W
	addlw	0x30
	call	LCD_Char
	movf	Ones,W
	addlw	0x30
	call	LCD_Char

	return

betscreen_drawbet
	movlw	.12							; player's current bet - line 2, col 12
	call	LCD_Line2W	

	movf	bet,W
	addlw	0x30
	call	LCD_Char
	return


; ocp-holds.asm - UI stuff for when player is choosing cards to hold.
; By Sean Igo for the One Chip Poker project
; Copyright 2002-2005, Sean Igo.

; getholds is the routine that polls for the player pressing hold-card buttons
; returns when it gets a leading edge on deal button.
; deal button is higher priority than hold buttons.
; trashes j,k,mask via calls to renderheld; holdmask, p; sets held

getholds
										; here, we should bop back and forth on line 4 b/t choose cards to hold & press deal to draw.
										; while waiting for the deal button to be pressed.
	clrf	animstate					; here, animation state 0 means choose is showing, 1 means press deal.

	call	LCD_Line4					; start off w/prompt = choose cards to hold..no need to clear line 4
	movlw	High str_gamescr1
	movwf	StringH
	movlw	Low str_gamescr1
	movwf	StringL
	call	drawstring

gh_outerloop
	movlw	.100						; HARDCODED value for how often to flip prompt states
	movwf	animct

gh_loop
	call	DelayAndStir				; debounce delay, stir RNG

	call	ReadButtons					; and read the buttons!
										; highest priorities: Bet Max first, then Deal, then Bet 1; others ignored.

										; so: let's look for a leading edge on the Bet Max button.
	btfss	buttonedge,b_dealbutton		; check button 7 (deal) - if edge is zero, it hasn't just been pressed / released
	goto	gh_checkholds
	btfsc	buttonval,b_dealbutton		; if button's current value is 0, it's just been pressed (active low!) 
	goto	gh_checkholds

	call	LCD_Line4					; erase prompt on exit.
	call	LCD_ClrLine
	return								; leading edge on deal = done!

gh_checkholds
	movlw	.1
	movwf	holdmask					; need to keep separate mask here since renderheld uses mask

	movlw	.5
	movwf	p							; check 5 bits.

gh_chloop
	movf	holdmask,W
	andwf	buttonedge,W				; check for edge on relevant button
	btfsc	STATUS,Z					; if result is zero, no edge	
	goto	gh_chloopnext

	movf	holdmask,W
	andwf	buttonval,W					; check for button's bit CLEAR = leading edge
	btfss	STATUS,Z
	goto	gh_chloopnext

	movf	holdmask,W					; aha, leading edge.
	xorwf	held,F						; toggle relevant bit.
	call	renderheld					; draw it. Might happen more than once for simultaneous presses, should be ok.

gh_chloopnext
	bcf		STATUS,C
	rlf		holdmask,F					; set up to check next bit
	decfsz	p,F
	goto	gh_chloop


gh_LoopEnd
	decfsz	animct,F					; dec animation counter for prompt
	goto	gh_loop						; not time to change the phrase @ bottom of screen yet...

	call	LCD_Line4					; phrase change: in any case, erase bottom line
	call	LCD_ClrLine

	movlw	1							; toggle low-order bit of animstate.
	xorwf	animstate,F
	btfss	STATUS,Z
	goto	gha_drawdeal				; if anim state now = 1, draw press deal to draw

										; otherwise render choose cards to hold
	call	LCD_Line4					
	movlw	High str_gamescr1
	movwf	StringH
	movlw	Low str_gamescr1
	movwf	StringL
	call	drawstring
	
	goto	gh_outerloop

gha_drawdeal
	call	LCD_Line4					
	movlw	High str_gamescr0
	movwf	StringH
	movlw	Low str_gamescr0
	movwf	StringL
	call	drawstring

	goto	gh_outerloop				; loop until deal is pressed.	



; renderheld draws the current hold state. Much resembles the card rendering routines in gamescreen, and
; this code may properly belong there.

renderheld
	movlw	.1
	movwf	mask						; set up rolling mask for checking which held flags to draw.
	movwf	k							; k holds the cursor column we need, which luckily starts at 1.

	movlw	.5
	movwf	j							; 5 iterations

rh_loop

	movf	k,W							; get new cursor position - put cursor at line 3, column 1 + (4*card#).
	call	LCD_Line3W	
	incf	k,F
	incf	k,F
	incf	k,F
	incf	k,F							; get column # for 4 spaces over for next card.

	movf	mask,W						; now: find out if "held" bit for card is 1. if it is, draw a "held".
	andwf	held,W
	btfsc	STATUS,Z
	goto	rh_drawspace				; if it isn't, draw blanks - b/c may need to erase an old one.
	
	movlw	.5							; character 5 is "HE"
	call	LCD_Char					
	movlw	.6							; character 6 is "LD"							
	call	LCD_Char
	goto	rh_loopend

rh_drawspace
	movlw	' '							; if there used to be a "HELD" in this spot but isn't,
	call	LCD_Char					; this will erase it. If there wasn't one, this draws redundant spaces. Oh well.
	movlw	' '
	call	LCD_Char

rh_loopend

	bcf		STATUS,C					; clear carry bit so can shift bits successfully
	rlf		mask,F						; and roll mask.

	decfsz	j,F
	goto	rh_loop
	return

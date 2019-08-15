; ocp-gamescreen.asm - routines for main game screen.
; By Sean Igo for One Chip Poker project
; Copyright 2002-2005, Sean Igo.

rendercards

	; so - we want to render cards from left to right. easy enough.
	; - set FSR to handptr, mask to 0x01, cursor to line 2, column 1. 
	
	movlw	.1
	movwf	mask						; set up rolling mask for checking which card backs to draw.
	movwf	carddelayflag				; also - 1 in carddelayflag says we need to delay while drawing cards.
	movwf	k							; k holds the cursor column we need, which luckily starts at 1.

	movlw	.5
	movwf	j							; 5 iterations

rc_backsloop
	movf	k,W							; get new cursor position - put cursor at line 2, column 1 + (4*card#).
	call	LCD_Line2W	
	incf	k,F
	incf	k,F
	incf	k,F
	incf	k,F							; get column # for 4 spaces over for next card.

	movf	mask,W						; now: find out if "held" bit for card is 0. if it is, draw a card-back.
	andwf	held,W
	btfss	STATUS,Z
	goto	rc_backsloopend

	call	rendercards_delay			; timing - the heart of animation. But don't do it if we're not drawing the card!
	btfsc	STATUS,C					; if carry set, stop doing the card-draw delays.
	clrf	carddelayflag				; note that we no longer delay while drawing cards.
										; so, we don't skip drawing card backs or anything, it just happens real fast.
										; may look flickery and awful, in which case DO skip it. check!
	
	movlw	.7							; character 7 is card-back graphic.
	call	LCD_Char					; draw 2 of 'em.
	movlw	.7							
	call	LCD_Char					

rc_backsloopend

	bcf		STATUS,C					; clear carry bit so can shift bits successfully
	rlf		mask,F						; and roll mask.

	decfsz	j,F
	goto	rc_backsloop

rc_fronts
										; ok, now to render the cards' fronts. This looks a lot like the back rendering!
	movlw	.1
	movwf	mask						; set up rolling mask for checking which card fronts to draw.
	movwf	k							; k holds the cursor column we need, which luckily starts at 1.

	movlw	handptr						; but NOW we want to actually render cards, so need ptr into hand data.
	movwf	FSR

	movlw	.5
	movwf	j							; 5 iterations

rc_frontsloop

	movf	k,W							; get new cursor position - put cursor at line 2, column 1 + (4*card#).
	call	LCD_Line2W	
	incf	k,F
	incf	k,F
	incf	k,F
	incf	k,F							; get column # for 4 spaces over for next card.

	movf	mask,W						; now: find out if "held" bit for card is 0. if it is, draw a card-back.
	andwf	held,W
	btfss	STATUS,Z
	goto	rc_frontsloopend
	
										;HERE DRAW THE CARD FRONT!
	call	rendercards_delay			; but first delay.
	btfsc	STATUS,C					; if carry set, stop doing the card-draw delays.
	clrf	carddelayflag				
	movf	INDF,W						; so, get 0..51 card value in W.
	call	render1card					; and draw that pup.

rc_frontsloopend

	incf	FSR,F						; increment pointer into hand data

	bcf		STATUS,C					; clear carry bit so can shift bits successfully
	rlf		mask,F

	decfsz	j,F
	goto	rc_frontsloop

	call	rendercards_delay			; one last delay b/c we don't want everything else to appear simultaneously w/ last card.

	return


; render1card draws the card given in W at the current cursor location.
; trashes p and scratch0.

render1card
	movwf	p							; save off card - for suit
	movwf	scratch0					; and again. - for rank
	bcf		STATUS,C
	rrf		scratch0,F					; shift rank holder twice, to shift off suit.
	bcf		STATUS,C
	rrf		scratch0,F					; shift rank holder twice, to shift off suit.
	movf	scratch0,W
	call	rankchars					; get rank character
	call	LCD_Char					; and render it!

	movf	p,W
	andlw	0x03						; now suit-saveoff & 3 leaves only suit. This should be usable verbatim as suit char.
	call	LCD_Char					; so draw that!	

	return

; rendercards_delay calls the delay-n-stir routine some number of times for appropriate card
; delay. Let's try ca. 1/4s = 12 calls to delay-n-stir at about 1/50s each.
; trashes p.

rendercards_delay

	movf	carddelayflag,W				; check to see if we should just bail.
	btfsc	STATUS,Z
	return								; if delay flag is zero, don't delay! return.

	movlw	.12							; we'll try 12 iterations.
	movwf	p

rcd_loop
	call	DelayAndStir				; wait about a 50th of a second, for debouncing.
	call 	ReadButtons					; ok, then poll the buttons.

	decfsz 	p,F
	goto	rcd_loop

	bcf		STATUS,C					; FOR NOW JUST ALWAYS LEAVE CARRY CLEAR
	return	


; renderscore renders the string for the hand's score, up at the top of the screen, centered.
; DOES NOT CLEAR THE TOP LINE - caller will have to do that for the drawn hand score.
; assumes "score" contains a legal and correct score.

renderscore
	movf	score,W
	call	scorectr					; gets centering column for given score.
	call	LCD_Line1W					; position cursor

										; now to draw the string.
	movf	score,W
	call	scorestrlow
	movwf	StringL

	movf	score,W
	call	scorestrhigh
	movwf	StringH
	call	drawstring

	return


; TABLES RELOCATED TO OCP-TABLES

; renderwin shows (centered?) player's winnings for the hand in line 1. Assumes caller has cleared line 1.

renderwin
	movlw	.5							; KLUD YODE COL 5 - might do fancier centering later
	call	LCD_Line1W					; position cursor

										; now to draw the string.
	movlw	Low str_gamescr2 			; "win: " col 5, draw coins col 10
	movwf	StringL
	movlw	High str_gamescr2
	movwf	StringH
	call	drawstring

	movlw	.10							; KLUD YODE COL 10 - might do fancier centering later
	call	LCD_Line1W					; position cursor
	
	movf	TotalPayoffH,W				; do decimal conversion of winnings amount
	movwf	NumH
	movf	TotalPayoffL,W
	movwf	NumL
	call	Convert

	movf	Thou,W						; ASSUMING TENK OF WINNINGS ALWAYS 0...
	addlw	0x30						; NEED TO WRITE A CENTRALIZED NO-LEADING-ZERO number renderer,
	call	LCD_Char					; with entry points to skip tenk, thou, etc.
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

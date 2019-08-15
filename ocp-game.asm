; ocp-game.asm - software guts of video poker game.
; By Sean Igo for One Chip Video Poker project
; Copyright 2002-2005, Sean Igo.

;--------------------------------------------------------------------------------
;SCORING

scorehand
	clrf	fsflags			;necessary - straightspot may never get called
	call	flushspot		;look for flushes.

					;now for pairs.
	clrf	numpairs
	btfss	fsflags,b_flushflag	;if there was a flush, there can't be any pairs.
					;if I get in a pinch for space, leave this line 
					;out, at the cost of doing useless pair checking.
	call	countpairs		;see how many pairs are in the hand.
	movf	numpairs,f		;moving onto itself sets zero flag
	btfsc	STATUS,Z		;if nonzero, don't look for straights
	call	straightspot		;find any straights.

					;now to analyze and categorize!
					;this is a good application for retlw,
					;since as soon as we spot a royal flush, we
					;can retlw royalflush_index or whatever.
					;so, spot royal. that needs straight + flush +
					;low card = 10 (9).
	btfss	fsflags,b_straightflag
	goto	sh_check4dk

	btfss	fsflags,b_flushflag
	goto	sh_check4dk
					;at this point we know we have a straight flush.
	movf	locard,W
	sublw	.36			;index 9 is value 10 - though remember it's not shifted
					;for the suit, so *4 - check for 36.

	btfsc	STATUS,Z
	retlw	score_royal		;so if z set, royal flush it is! woo

	retlw	score_straightflush	;if locard not 10, still a straightflush woo

sh_check4dk
	movf	numpairs,W
	sublw	.6			;6 pairs means 4 of a kind.
	btfsc	STATUS,Z
	retlw	score_4ofakind		;z set = 4 of a kind!

	movf	numpairs,W
	sublw	.4			;4 pairs is full house.
	btfsc	STATUS,Z
	retlw	score_fullhouse

	btfsc	fsflags,b_flushflag
	retlw	score_flush		;flush flag set? flush!

	btfsc	fsflags,b_straightflag
	retlw	score_straight		;straight flag set? straight!

	movf	numpairs,W
	sublw	.3			;3 pairs = 3 of a kind
	btfsc	STATUS,Z
	retlw	score_3ofakind

	movf	numpairs,W
	sublw	.2			;2 pairs = two pair
	btfsc	STATUS,Z
	retlw	score_twopair
	
	movf	numpairs,F		;zero check
	btfsc	STATUS,Z
	retlw	score_worthless		;if it is 0 pairs, got nothing

	movf	pairrank,W		;last chance: jacks or better?
	btfsc	STATUS,Z		;if 0, aces.
	retlw	score_jacksorbetter
	sublw	.36			;9-pairrank should be negative
					;in theory, carry is clear for neg. result.
					;recall it's shifted up 2 bits, so 36
					;and not 9.
	
					;	btfss	STATUS,C
					;	retlw	score_jacksorbetter	;ha, got a few coins
					;try this instead - if W's hibit set, good!
	andlw	0x80
	btfss	STATUS,Z
	retlw	score_jacksorbetter	;hibit set - good!

	retlw	score_worthless		;worthless hand


;countpairs scans the hand pairwise & compares rank (card value & b'00111100') to see
;if they match. If so, pair count gets incremented.
;pair ordering is like this:
;01 02 03 04 12 13 14 23 24 34
;in decrementy way,
;43 42 41 40 32 31 30 21 20 10 so outer ends nicely & inner ends on 255..
;we'll use k for outer, j for inner
;trashes FSR.

countpairs

	movlw	4			;set up outer loop 
	movwf	k

cp_outlop
	decf	k,W			;get k-1 into j, handy eh
	movwf	j

					;get k's rank, which j must match to make a PAIR...
	movf	k,W
	addlw	handptr
	movwf	FSR
	movf	INDF,W			;snag card k.
	andlw	b'00111100'		;mask off suit
	movwf	temprank

cp_inlop
					;now get j's rank.
	movf	j,W
	addlw	handptr
	movwf	FSR
	movf	INDF,W
	andlw	b'00111100'	
	
	subwf	temprank,W		;compare the ranks.

	btfss	STATUS,Z
	
	goto 	cp_notpair

	incf	numpairs,F		;so if Z is set thar's a par!
					;record pair's rank. This is for spotting
					;jax or better. note that it will get overwritten
					;by subsequent pairs, but we only CARE about this
					;if there is only 1 pair.
	movf	temprank,W
	movwf	pairrank

cp_notpair
	decf	j,F			;j=0 is ok...so, check to see if we
					;decked around to 255.
	btfss	j,7			;check hibit of j.
	goto	cp_inlop		;if clear, loop again
	
	decfsz	k,F
	goto	cp_outlop

					;done! numpairs contains the pair count now.
	return



;straightspot looks for straights. It has to spot both ace-low and ace-high straights.
;the ace is naturally low, so if there are no straights and an ace is the low card,
;check again with ace high. One way to do this is just copy the whole hand into a 
;shadow, check THAT for straights, if ace low & no straights, 

straightspot

					;copy cards to trashable spot - ow
	movf	handptr+0,W
	movwf	handcopyptr+0
	movf	handptr+1,W
	movwf	handcopyptr+1
	movf	handptr+2,W
	movwf	handcopyptr+2
	movf	handptr+3,W
	movwf	handcopyptr+3
	movf	handptr+4,W
	movwf	handcopyptr+4

ss_start
	call	findhilo		;find high and low cards in the hand.

					;ok, this is a bit icky. Say the hand is a 
					;straight - 3,4,5,6,7. we know there are no pairs
					;(call set up thus), so if hicard - locard = 4,
					;it's a straight! BUT since we didn't shift down
					;for the suit, everything is multiplied by 4, so
					;difference has to be 16.
	movf	locard,W
	subwf	hicard,W		;w = f-w = hicard - locard
	sublw	.16			;if difference is magic 16, YAY it's a straight!
	btfss	STATUS,Z
	goto	ss_checkace		;so, if z clear, not 16, check special case ace

	bsf	fsflags,b_straightflag	;it's a straight!
	goto	ss_done

ss_checkace
					;not yet recogged as a straight, but that doesn't
					;mean it isn't. if ace is current low, try ace-high.
					;that is, add 13*4 (=52) to every ace in the list...
					;that makes them of rank 13, just above king (12).
					;then, the same straight check will work.
	movf	locard,F		;is low the ace?
	btfss	STATUS,Z
	goto	ss_done			;if z clear, ace is not the lowcard.

					;ok, massage the aces.
	movlw 	handcopyptr
	movwf	FSR
	movlw	5
	movwf	j
ss_calop

	movf	INDF,W			;snag rank
	andlw	b'00111100'
	btfss	STATUS,Z		
	goto	ss_calnext
	movf	INDF,W			;if 0, it's an ace
	addlw	.52	
	movwf	INDF

ss_calnext
	incf	FSR,F
	decfsz	j,F
	goto	ss_calop


	goto	ss_start		;here's the clever bit: can reuse the above code.
					;findhilo will pick up on the new rank-13 cards, so
					;low CAN'T be 0 (ace, by the test just above), so if
					;there's no straight, that test will fail and it'll
					;just bop to ss_done.


ss_done
					;might put cleanup of some sort here (e.g. restore FSR)
	return

;a pid for straightspot: scans the hand and finds highest & lowest card therein.
;uses j,k. Assumes that the hand starts at handcopyptr.
;Trashes FSR.

findhilo
					;init hicard & locard to first card's rank,
					;it is highest so far...
					;but we're doing a "dec" loop so first card 
					;is #4.
	movf	handcopyptr+4,W
	andlw	b'00111100'		;mask out rank.
	movwf	hicard
	movwf	locard
	movlw	handcopyptr+3		;set up pointer to the rest of the cards
	movwf	FSR
	movlw	4
	movwf	j			;loopctr

fhl_lop
	movf	INDF,W			
	andlw	b'00111100'		;ok - find rank of next card.
	movwf	k			;and stick it in k.

	subwf	hicard,W		;w = f-w, so hicard-k. if result is negative,
					;k is our new hicard!
					;in theory, carry is clear for neg. result.
	btfsc	STATUS,C
	goto	fhl_trylow		;so, if carry set, can't be it
	
	movf	k,W
	movwf	hicard			;new hicard is here!

fhl_trylow
	movf	k,W
	subwf	locard,W		;w = locard-k, so positive means we have a new low.
					;in theory, for positive result, subwf sets
					;carry and clears z.
	btfss	STATUS,C
	goto	fhl_trynext		;so, if carry clear, can't be it
	
	btfsc	STATUS,Z		
	goto	fhl_trynext		;if zero set, can't be it

	movf	k,W
	movwf	locard			;new locard is K!

fhl_trynext
	decf	FSR,F			;point at next card.
	decfsz	j,F
	goto	fhl_lop

	return



;flushspot examines cards 0..4 to see if they have the same suit (lowest order
;2 bits). Sets flushflag if they do, clears if not.

flushspot

	bcf	fsflags,b_flushflag	;pessimist

	movf	card0,W
	andlw	0x03			;isolate suit
	movwf	tempsuit		;and save off - could share an rng byte for this?

	movlw	card1			;point at card 1.
	movwf	FSR
	movlw	4			;and prepare to check 4 cards
	movwf	j			;can prolly get away w/using j

fs_flushlop

	movf	INDF,W
	andlw	0x03			;find suit
	subwf	tempsuit,W
	btfss	STATUS,Z		
	goto	fs_noflush		;if z was clear, current suit != suit of 0, so no flush

	incf	FSR,F			;advance pointer to next card
	decfsz	j,F
	goto	fs_flushlop

	bsf	fsflags,b_flushflag	;set flag, yay

fs_noflush
	return	

;--------------------------------------------------------------------------------
;card dealing widget!

;dealhand just grabs cards 0..9 and clears the held flags.

dealhand
	movlw	0x0A			;10 iterations
	movwf	k
dh_lop
	movf	k,w			;10..1
	sublw	0x0A			;w = 10-w, so 0..9
	call	getnextcard

	decfsz	k,f
	goto	dh_lop

	clrf	held			;clear held flags.

	return

;drawcards scans the held flags and builds the new hand accordingly.
;so, step through and if a given heldflag is 0, pull a new card by means
;of copying from the top 5 cards.

drawcards
	movlw	1
	movwf	mask			;start mask at 0x01, card 0
	clrf	numdrawn		;so far, none have been drawn.
	movlw	5
	movwf	j			;loop counter

dc_loop
					;ok, so see if held & mask = 0.
					;if so, draw the card.
	movf	held,W
	andwf	mask,W
	btfss	STATUS,Z		;if z set, it was zero - so draw
	goto	dc_skipdraw		;z was clear, so 1 - don't draw

					;ok, now to draw a card.
					;the card to draw is card[5+numdrawn]
	movf	numdrawn,W
	addlw	drawptr
	movwf	FSR			;now pointing at next card to draw!
	movf	INDF,W			;new card is in W
	movwf	rawcard			;store it off in rawcard.

	incf	numdrawn,F		;and advance drawn-card count.

	movf	j,W			;get index of victim card 5..1
	sublw	5			;5-w -> w, so 0..4 heh
	addlw	handptr
	movwf	FSR			;now FSR points at card to stomp.
	movf	rawcard,W
	movwf	INDF			;there. Drawn!

dc_skipdraw
					;advance loop.
	bcf	STATUS,C
	rlf	mask,F			;move mask up a bit

	decfsz	j,F
	goto	dc_loop
	
	return

;getnextcard pulls the next random number out of the rng, and stuffs it in the 
;hand array as indexed by w.
;that is, call this with w=3 to set card3 to the next card.
;modeled on the dealhand() function in vpok.cpp.
;preserves FSR but not anything else like status or w.
;MUST be called in order...like, I suppose the only calls will be 0..9 in order,
;to fetch all the cards.

getnextcard
					;first, save off card index.
	movwf	cind
					;save off fsr
	movf	FSR,W
	movwf	fsrsave

gnc_grabrand
					;then, think up our new random #.
	call	rand32
	movf	rand3,W			;get high order byte from random
	movwf	rawcard			;save off in 
	rrf	rawcard,F		;then shift right twice to end up w/high 6 bits
	rrf	rawcard,F
	movlw	0x3F
	andwf	rawcard,F		;mask in case any stray bits got in there.
					;now, if the card value is > 51, try again.
	movlw	0x34			;0x34 = 52
	subwf	rawcard,W		;subtract 52 from rawcard; w = rawcard - 52.
					;so, if result is negative...good, right?
	andlw	0x80
	btfsc	STATUS,Z		;therefore, if w & 0x80 is zero, evil!
	goto	gnc_grabrand

					;got a decent one! find out if it's already in the list.
					;actually can do this. If cind is 0, assume we're ok - 
					;that this function is only ever called with the 
					;indices in order.
	movf	cind,W			;moving cind into W does zero check, right?
	btfsc	STATUS,Z		
	goto	gnc_cardok		;so, if cind IS zero, hop right out. No cards have
					;been dealt before so it can't be a collision.

					;set up loop. only need to check the first cind cards
					;ie if cind is 3, check cards 0,1,2. This is why
					;there's the assumption that this fn is called "in order"
	movwf	j			;assuming drawcards doesn't call this, it uses j

	movlw	handptr
	movwf	FSR			;now FSR points at hand.

gnc_cheklop

	movf	INDF,W			;get card n's value
	subwf	rawcard,W		;compare to rawcard
	btfsc	STATUS,Z
	goto	gnc_grabrand		;ugh - if z is set, they were equal - so back you go

	incf	FSR,F			;point to next card.
	decfsz	j,F
	goto	gnc_cheklop

	
gnc_cardok
	movf	cind,W			;card is ok - store it in hand!
	addlw	handptr
	movwf	FSR
	movf	rawcard,W
	movwf	INDF
					;restore FSR
	movf	fsrsave,W
	movwf	FSR

	return



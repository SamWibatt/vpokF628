; paytable.asm - routines for fetching payoff amount and adding it to bankroll
; By Sean Igo for the One Chip Poker project
; Copyright 2002-2005, Sean Igo.
;
; Based on "9/6" odds:
;	"Full Pay" Jacks or Better
;	Hand 			Payoff	Combinations	Probability Return
;	Royal flush 	800 	493512264 		0.00002476 	0.01980661
;	Straight flush 	50 		2178883296 		0.00010931 	0.00546545
;	Four of a kind 	25 		47093167764 	0.00236255 	0.05906364
;	Full house 		9 		229475482596 	0.01151221 	0.10360987
;	Flush 			6 		219554786160 	0.01101451 	0.06608707
;	Straight 		4 		223837565784 	0.01122937 	0.04491747
;	Three of a kind 3 		1484003070324 	0.07444870 	0.22334610
;	Two pair 		2 		2576946164148 	0.12927890 	0.25855780
;	Pair 			1 		4277372890968 	0.21458503 	0.21458503
;	Nothing	 		0 		10872274993896 	0.54543467 	0
;	Total 			  		19933230517200 	1 			0.99543904  

; call getpayoff to stuff PayoffH:PayoffL with the one-coin payoff amount.
; pass score (0..9) in W.

getpayoff
	call	paydata						; sets PayoffH, returns PayoffL
	movwf	PayoffL						; so we need to store off PayoffL.
	return

; gettotalpayoff stuffs TotalPayoffH:L with bet * PayoffH:L.
; just clears total payoff then adds payoff to it "bet" times.
; trashes j.

gettotalpayoff
	clrf	TotalPayoffH				; start with total payoff zero.
	clrf	TotalPayoffL

	movf	bet,W
	movwf	j							; j = loop counter.
gtp_lop

	movf	PayoffL,W
	addwf	TotalPayoffL,F				; TotalPayoffL += PayoffL
	btfss	STATUS,C					; if carry clear,
	goto	gtp_hibyte					; skip over incrementing high byte.
	incf	TotalPayoffH,F				; otherwise carry the 1.

gtp_hibyte
	movf	PayoffH,W					; now add high bytes.
	addwf	TotalPayoffH,F				; don't worry re: carry, assume total will fit comfortably.

	decfsz	j,F			
	goto	gtp_lop
	return

; addpayoff adds TotalPayoffH:L to CoinsH:L. Clamps at 50,000 = 0xC350. If we assume incoming
; coins value is not more than 50K, and highest possible total payoff added to 50K is < 64K,
; no need to do anything fancy adding to hibyte.

addpayoff
	movf	TotalPayoffL,W
	addwf	CoinsL,F					; CoinsL += TotalPayoffL
	btfss	STATUS,C					; if carry clear,
	goto	ap_hibyte					; skip over incrementing high byte.
	incf	CoinsH,F					; otherwise carry the 1.

ap_hibyte
	movf	TotalPayoffH,W				; now add high bytes.
	addwf	CoinsH,F					; don't worry re: carry, assume total will fit comfortably.

ap_clampEntry							; alternate entry point for clamping! 
										; ok, now make sure total is <= 50,000 (0xC350).
	movf	CoinsH,W		
	sublw	0xC3						; if hibyte > C3, need to clamp. Sublw sets carry if result is 0 or +
	btfss	STATUS,C					; 0xC3 - CoinsH < 0 (carry = 0) if CoinsH > 0xC3; so if carry clear, clamp.
	goto	ap_clamp
	btfss	STATUS,Z					; hibyte may still be equal to 0xc3, if it is we need to check lobyte.
	return								; zero was clear, so result is positive; that means all's well so leave.	

	movf	CoinsL,W					; at this point we know CoinsH == 0xC3, so CoinsL must be <= 0x50 to be ok.
	sublw	0x50
	btfsc	STATUS,C					; carry clear means 0x50 - CoinsL was negative. which means we need to clamp.
	return								; otherwise, CoinsL <= 0x50, so we're ok. Leave.

ap_clamp
	movlw	0xC3						; need to clamp to 50K - 0xC350
	movwf	CoinsH
	movlw	0x50
	movwf	CoinsL
	return

; paytable data is in ocp-tables

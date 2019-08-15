; vpk628epm.asm - routines to read and write internal eeprom.
; by Sean Igo for One Chip Video Poker project
; Copyright 2002-2005, Sean Igo


RestoreCoinsAndSeed
	movlw	0
	call	readIEbyte					; fetch byte 0 - low-order coins byte
	movwf	CoinsL
	movlw	1
	call	readIEbyte					; fetch byte 1 - high-order coins byte
	movwf	CoinsH

	movlw	2
	call	readIEbyte					; fetch byte 2 - lsb of random seed
	movwf	rand0
	movlw	3
	call	readIEbyte					; fetch byte 3 - 2nd to lsb of random seed
	movwf	rand1
	movlw	4
	call	readIEbyte					; fetch byte 4 - 2nd to msb of seed
	movwf	rand2
	movlw	5
	call	readIEbyte					; fetch byte 5 - msb of seed
	movwf	rand3

										; now check to see if coins is 0 or > 50,000. If either of those, reset to initial.
	movf	CoinsH,W		
	sublw	0xC3						; if hibyte > C3, need to clamp. Sublw sets carry if result is 0 or +
	btfss	STATUS,C					; 0xC3 - CoinsH < 0 (carry = 0) if CoinsH > 0xC3; so if carry clear, clamp.
	goto	RCS_clamp
	btfss	STATUS,Z					; hibyte may still be equal to 0xc3, if it is we need to check lobyte.
	goto	RCS_zerocheck				; zero was clear, so result is positive; that means all's well but look for zero.

	movf	CoinsL,W					; at this point we know CoinsH == 0xC3, so CoinsL must be <= 0x50 to be ok.
	sublw	0x50
	btfsc	STATUS,C					; carry clear means 0x50 - CoinsL was negative. which means we need to clamp.
	goto	RCS_zerocheck				; otherwise, CoinsL <= 0x50, so we're ok, check for zero

RCS_clamp
										; REINITIALIZE FROM ZERO COINS! OR FROM ILLEGAL VALUE! FOR NOW GOING WITH
										; FIXED INITIAL STASH, COULD DO SOME CLEVER RANDOM THING & PRINT OUT THAT
										; YOU FOUND THE COINS IN A TURLET OR SOMETHING.
	movlw	High bankroll_init			; fill Coins with 0x01F4 = 500. Actually use bankroll_init
	movwf	CoinsH
	movlw	Low bankroll_init
	movwf	CoinsL
	call	SaveCoins					; and now that it's fixed, save it!
	movf	CoinsL,W					; copy coins to PrevCoinsH:L so they're in sync, otherwise
	movwf	PrevCoinsL					; bet screen will animate from PrevCoins uninitialized junk-value
	movf	CoinsH,W
	movwf	PrevCoinsH			
	return

RCS_zerocheck
	movf	CoinsH,W					; but still need to check for 0.
	btfss	STATUS,Z					
	return								; zero flag clear - hibyte nonzero, so ok.
	movf	CoinsL,W					; hibyte was 0 - check lobyte
	btfss	STATUS,Z				
	return								; zero flag clear for lobyte - coins nonzero, so ok.
	goto	RCS_clamp					; coins was zero - set to initial.


; SaveCoins does that. CoinsL in location 0, CoinsH in location 1.

SaveCoins
	movf	CoinsL,W
	movwf	epdata
	movlw	0
	call	writeIEbyte
	movf	CoinsH,W
	movwf	epdata
	movlw	1
	call	writeIEbyte
	return

; SaveSeed likewise, with seed 0..3 in locations 2..5.

SaveSeed
	movf	rand0,W
	movwf	epdata
	movlw	2
	call	writeIEbyte
	movf	rand1,W
	movwf	epdata
	movlw	3
	call	writeIEbyte
	movf	rand2,W
	movwf	epdata
	movlw	4
	call	writeIEbyte
	movf	rand3,W
	movwf	epdata
	movlw	5
	call	writeIEbyte
	return

; readIEbyte takes address into EEPROM in W, returns byte at that address in W. No sanity check.

readIEbyte
	bsf 	STATUS, RP0 				; need be in Bank 1
	movwf	EEADR						; put address in EEADR
	bsf		EECON1,RD					; begin read process. HW clears RD itself.
	movf 	EEDATA, W 					; EEDATA holds fetched byte - put in W
	bcf	 	STATUS, RP0 				; bop back to Bank 0
	return

writeIEbyte
	bsf 	STATUS, RP0 				; Bank 1
	movwf	EEADR						; store address
	movf	epdata,W					; fetch data to write - note epdata is in shared RAM so being in bank 1 doesn't matter.
	movwf	EEDATA						; and put in eeprom output buffer.
	bsf 	EECON1, WREN 				; Enable write
	bcf 	INTCON, GIE 				; Disable INTs.
	movlw 	0x55 						; Secret magic required thing to write to eeprom begins:
	movwf 	EECON2 						; Write 55h
	movlw 	0xAA 						; magic thing continues!
	movwf 	EECON2 						; Write AAh
	bsf 	EECON1,WR 					; Set WR bit to begin write
	bsf 	INTCON, GIE 				; Enable INTs.
wIblop:									; Wait to finish the write
  	btfsc	EECON1, WR					; watch for WR flag to clear
    goto	wIblop

  	bcf		EECON1, WREN 				; disable write
	bcf 	STATUS, RP0 				; Bank 0
	return


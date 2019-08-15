; lcrng-F628.asm
; by Sean Igo
;
; implements the classic 32-bit linear congruential random number generator (LCRNG) where
; Xn+1 =  (a Xn + c) mod m,     n > 0
; in this case a = 1664525, m = 2^32, c = 1013904223, period = 2^32.
; here the idea is to put the upcoming required variables and constants into your F628 project,
; and just #include this asm file.
;
; required variables:
; rand0 - lowest order byte of current random number (Xn, by above notation.)
; rand1 
; rand2
; rand3 - highest order byte of Xn.
;
; nrnd0 - lowest order byte of scratch buffer used in doing calculation
; nrnd1
; nrnd2
; nrnd3 - highest order byte of scratch buffer
;
; no constants need to be declared - ones used in this module are all harcoded.
;
; nrnd's bytes could conceivably be shared with other things, but they will be
; trashed by any call to rand32.
;
; Approximate cycle timing: assuming 9 for a call to
; shiftnew (incl. call statement) and 20 for addrand, about 422 cycles in the
; worst case - say roughly 400. With 4MHz clock = 1MHz instr clock, that's
; about 400 uS. 

;--------------------------------------------------------------------------------
;main random function rand32

rand32
	clrf	nrnd0
	clrf	nrnd1
	clrf	nrnd2
	clrf	nrnd3			;clear out new-rand buffer
					;here's the big unrolled loop that does the multiply by
					;1664525. Since that, in binary, is
					;1 1001 0110 0110 0000 1101, the idea is this.
					;start with the msb of multiplier and work toward lsb.
					;if the bit is a 1, add the current random value to
					;the accumulator (nrnd). if it's a 0, do nothing.
					;for every bit, shift the accumulator left.
	
	call	addrand			;1 this does nrnd += rand
	call	shiftnew		;  this does nrnd <<= 1
	call	addrand			;1
	call	shiftnew
	call	shiftnew		;0
	call	shiftnew		;0 
	call	addrand			;1 
	call	shiftnew
	call	shiftnew		;0
	call	addrand			;1
	call	shiftnew
	call	addrand			;1
	call	shiftnew
	call	shiftnew		;0
	call	shiftnew		;0
	call	addrand			;1
	call	shiftnew
	call	addrand			;1
	call	shiftnew
	call	shiftnew		;0 
	call	shiftnew		;0 
	call	shiftnew		;0
	call	shiftnew		;0
	call	shiftnew		;0
	call	addrand			;1
	call	shiftnew
	call	addrand			;1
	call	shiftnew
	call	shiftnew		;0
	call	addrand			;1

					;now, trash rand with 1013904223 = 0x3C6EF35F, then
					;addrand will make it so nrnd has the new value.
	movlw	0x5F
	movwf	rand0
	movlw	0xF3
	movwf	rand1
	movlw	0x6E
	movwf	rand2
	movlw	0x3C
	movwf	rand3
	call	addrand

					;then, just copy nrnd back to rand. QED.
	movf	nrnd0,W
	movwf	rand0
	movf	nrnd1,W
	movwf	rand1
	movf	nrnd2,W
	movwf	rand2
	movf	nrnd3,W
	movwf	rand3
	return				

;RNG support------------------------------------------------------------------------------------------


addrand
					;this enacts nrnd += rand.
	movf	rand0,W
	addwf	nrnd0,F

	movf	rand1,W
	btfsc	STATUS,C
	incfsz	rand1,W
	addwf	nrnd1,F

    movf	rand2,W
    btfsc	STATUS,C
    incfsz	rand2,W
    addwf	nrnd2,F

    movf	rand3,W
    btfsc	STATUS,C
    incfsz	rand3,W
    addwf	nrnd3,F
	return



shiftnew
					;enacts nrnd <<= 1
	bcf	STATUS,C
	rlf	nrnd0,F
	rlf	nrnd1,F
	rlf	nrnd2,F
	rlf	nrnd3,F
	return


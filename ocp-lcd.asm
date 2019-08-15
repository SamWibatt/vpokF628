; ocp-lcd.asm - LCD routines specific to One Chip Poker
; By Sean Igo for the One Chip Poker project
; Copyright 2002-2005, Sean Igo.

OCP_CustomChars
										;now would be a good time to define the
										;custom characters! 
										;this goes thus:
										;Set CGRAM addr to $40 (cursor may hop to 2nd line)
	movlw	0x40
	call	LCD_Cmd

										;then just unwind data, 8 bytes per char.

	clrf	j							; index into char data table, below.
	movlw	D'64'						; 64 bytes of stuff, now that there are 8 characters.
	movwf	k 


										; now just step through char table until you get a 0xFF.
occ_lop

	movf	j,W							; index into W

	call	chardata

	call	LCD_Char					; still going - send pixels.

	incf	j,F
	decfsz	k,F
	goto	occ_lop

occ_done
										;set Display Addr (e.g. cmd 0x80)
										;to get back out of define-char
	movlw	0x80
	call	LCD_Cmd


	return



; custom char data tables moved to ocp-tables.

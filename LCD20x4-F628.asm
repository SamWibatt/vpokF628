; LCD ROUTINES-----------------------------------------------------------------------------------------------------------------------
; for standard 20x4 character-based LCD display.
; copied and slightly modified from Nigel Goodwin's tutorial code: www.winpicprog.co.uk
;
; the idea is that you can just jam in the upcoming requisite variables and constants in your main
; program, then #include this .asm, and there you go.
;
; requires the following variables in the main cblock:
;		templcd						;temp store for 4 bit mode
;		templcd2
;
; and these constants:
; LCD_PORT	Equ	PORTA
; LCD_TRIS	Equ	TRISA
; LCD_RS		Equ	0x04			;LCD handshake lines
; LCD_RW		Equ	0x06
; LCD_E		Equ	0x07
;					;lcd cursor positions INCL command flag, so just load one up & call lcd_cmd
; lcdpos_line1		equ	0x80
; lcdpos_line2		equ	0xC0
; lcdpos_line3		equ	0x94
; lcdpos_line4		equ	0xD4
;
; also if you have #define DEBUG somewhere, LCD_Busy will just return, so you don't have to mess
; with input stuff.


;Initialise LCD
LCD_Init	

		call 	LCD_Busy		;wait for LCD to settle

		movlw	0x20			;Set 4 bit mode
		call	LCD_Cmd

		; sean adds: shut off display
		movlw	0x08
		call	LCD_Cmd

		movlw	0x28			;Set display shift
		call	LCD_Cmd

		; sean adds: clear RAM here
		call	LCD_Clr

		movlw	0x06			;Set display character mode
		call	LCD_Cmd

		movlw	0x0c			;Set display on/off and cursor command
		call	LCD_Cmd			;Set cursor off

;sean moved		call	LCD_Clr			;clear display

		retlw	0x00



; command set routine
LCD_Cmd		movwf	templcd
		swapf	templcd,	w	;send upper nibble
		andlw	0x0f			;clear upper 4 bits of W
		movwf	LCD_PORT
		bcf	LCD_PORT, LCD_RS	;RS line to 1
		call	Pulse_e			;Pulse the E line high

		movf	templcd,	w	;send lower nibble
		andlw	0x0f			;clear upper 4 bits of W
		movwf	LCD_PORT
		bcf	LCD_PORT, LCD_RS	;RS line to 1
		call	Pulse_e			;Pulse the E line high
		call 	LCD_Busy
		retlw	0x00

LCD_CharD	addlw	0x30			;add 0x30 to convert to ASCII
LCD_Char	movwf	templcd
		swapf	templcd,	w	;send upper nibble
		andlw	0x0f			;clear upper 4 bits of W
		movwf	LCD_PORT
		bsf	LCD_PORT, LCD_RS	;RS line to 1
		call	Pulse_e			;Pulse the E line high

		movf	templcd,	w	;send lower nibble
		andlw	0x0f			;clear upper 4 bits of W
		movwf	LCD_PORT
		bsf	LCD_PORT, LCD_RS	;RS line to 1
		call	Pulse_e			;Pulse the E line high
		call 	LCD_Busy
		retlw	0x00

LCD_Line1	movlw	lcdpos_line1	;move to 1st row, first column
		call	LCD_Cmd
		retlw	0x00

LCD_Line2	movlw	lcdpos_line2	;move to 2nd row, first column
		call	LCD_Cmd
		retlw	0x00

LCD_Line3	movlw	lcdpos_line3	;move to 3rd row, first column
		call	LCD_Cmd
		retlw	0x00

LCD_Line4	movlw	lcdpos_line4	;move to 4th row, first column
		call	LCD_Cmd
		retlw	0x00

LCD_Line1W	addlw	lcdpos_line1	;move to 1st row, column W
		call	LCD_Cmd
		retlw	0x00

LCD_Line2W	addlw	lcdpos_line2	;move to 2nd row, column W
		call	LCD_Cmd
		retlw	0x00

LCD_Line3W	addlw	lcdpos_line3	;move to 3rd row, column W
		call	LCD_Cmd
		retlw	0x00

LCD_Line4W	addlw	lcdpos_line4	;move to 4th row, column W
		call	LCD_Cmd
		retlw	0x00


LCD_CurOn	movlw	0x0d			;Set display on/off and cursor command
		call	LCD_Cmd
		retlw	0x00

LCD_CurOff	movlw	0x0c			;Set display on/off and cursor command
		call	LCD_Cmd
		retlw	0x00

LCD_Clr		movlw	0x01			;Clear display
		call	LCD_Cmd
		retlw	0x00

Pulse_e		bsf	LCD_PORT, LCD_E
		nop
		nop			;sean adds
		bcf	LCD_PORT, LCD_E
		retlw	0x00

LCD_Busy
	ifdef	DEBUG			;for debug vsn, do nothing.
	return
	endif

		bsf	STATUS,	RP0		;set bank 1
		movlw	0x0f			;set Port for input
		movwf	LCD_TRIS
		bcf	STATUS,	RP0		;set bank 0
		bcf	LCD_PORT, LCD_RS	;set LCD for command mode
		bsf	LCD_PORT, LCD_RW	;setup to read busy flag
		bsf	LCD_PORT, LCD_E
		swapf	LCD_PORT, w		;read upper nibble (busy flag)
		nop		;sean adds
		bcf	LCD_PORT, LCD_E		
		movwf	templcd2 
		nop		;sean adds
		bsf	LCD_PORT, LCD_E		;dummy read of lower nibble
		nop		;sean adds
		nop		;sean adds
		bcf	LCD_PORT, LCD_E
		btfsc	templcd2, 7		;check busy flag, high = busy
		goto	LCD_Busy		;if busy check again
		bcf	LCD_PORT, LCD_RW
		bsf	STATUS,	RP0		;set bank 1
		movlw	0x00			;set Port for output
		movwf	LCD_TRIS
		bcf	STATUS,	RP0		;set bank 0
		return

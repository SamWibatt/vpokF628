; ocp-epminit.asm - EEPROM data init.
; by Sean Igo for One Chip Video Poker project
; Copyright 2002-2005, Sean Igo

ep_orgthumb				;to remember where we were...
		
	org 0x2100							; eeprom address!

epminit
										; first 2 locations: 0 = coins lobyte, 1 = coins hibyte.
	DE	0x0D							; start with D0 0D, lobyte first. - which is an illegal value, reset by code to a good one.
	DE	0xD0
										; next locations are 2..5 = random seed 0..3.
										; For now, let's seed it with a pat royal flush
										; other seeds are available in the boardtest scoredata file.
										; Score 9: seed 0020A836 - held 11111
	DE	0x36	
	DE	0xA8	
	DE	0x20	
	DE	0x00	


	org	ep_orgthumb						;restore compile position so any modules included
										;after this are ok.

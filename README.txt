This source .zip contains the assembly sources for One Chip Video Poker, plus workspace files
for Microchip MPLAB v6.61.

Target processor: PIC 16F628. Will probably work on 16F628A, 16F648, and other similar chips,
but I haven't tested it. Should work with fairly minor modifications on other PICs.

This project is effectively a single big assembly file, though it appears to be split up
into modules. I developed most of it before MPLAB went to a full assemble/link toolchain and
never set up a modern project for it. ocp-main.asm just "include"s the other files. I haven't
tried it with other assemblers.

Wiring instructions are in ocp-main.asm, and a schematic is provided as OCPoker-Schematic1.png.

Gameplay is self-explanatory; there is onscreen prompting, and the buttons' functions are identified in the schematic and wiring instructions.

Files included:

Sources:
ocp-main.asm - this one includes all the others, so you should only need to assemble it.
LCD20x4-F628.asm       
lcrng-F628.asm
ocp-betscreen.asm      
ocp-epm.asm
ocp-epminit.asm
ocp-game.asm
ocp-gamescreen.asm
ocp-holds.asm
ocp-lcd.asm
ocp-paytable.asm
ocp-tables.asm
ocp-text.asm

MPLAB v6.61 project files:
OCPoker.mcp
OCPoker.mcs
OCPoker.mcw

Hex file ready to burn to a 16F628:
ocp-main.HEX

Other:
README.txt
OCPoker-Schematic1.png 


Contents are copyright 2002-2005 by Sean Igo, except sections credited to other people in source comments. Special thanks to Nigel Goodwin at http://www.winpicprog.co.uk/ and contributors at PICList (www.piclist.com).

This project is intended solely for entertainment and personal use. Please write to me at
sgigo@xmission.com if you have a commercial use in mind for it or code based on it.

Permission is given to modify and redistribute this code as long as the original code is also provided and changes are identified.

Except where noted in source code comments, One Chip Video Poker is copyright © 2002-2005 by Sean Igo, All Rights Reserved.  One Chip Video Poker is released with NO WARRANTY.

Any trademarks mentioned here are the property of their owners.  To the author's knowledge no 
trademark or patent infringement exists in this document or in the One Chip Video Poker 
distribution; any such infringement is purely unintentional.


	TITLE 'BANK & MOVE MODULE FOR CP/M3 LINKED BIOS'

	; DEFINE LOGICAL VALUES:
TRUE		EQU	-1
FALSE		EQU	NOT TRUE

	; DETERMINE IF FOR BANK SELECT OR NOT:
BANKED		EQU	FALSE	;<----------------Banked VERSION

MPURR0	EQU	0D2H		;Z80 BOARD RELOCATION PORT
MPURR1	EQU	0D3H		;Z80 BOARD RELOCATION PORT


	; DEFINE PUBLIC LABELS:
	PUBLIC	?MOVE,?XMOVE,?BANK

	; PUBLIC LABELS AND EXTERNALS FOR BANKED SYSTEMS:
	IF	BANKED
	PUBLIC	CURRR0,CURRR1	;CURRENT WINDOW RELOCATION SEGMENTS
	PUBLIC	BANKBUF		;TEMPORARY 128 BYTE BUFFER OTHER ROUTINES
				; MAY USE FOR TRANSIENT PURPOSES
	PUBLIC	WIN$LOW$2BITS	;LOWER 2 BITS FOR EACH RELOCATION REGISTER
	PUBLIC	DOXMOV,XMOV$BANKS	;EXTENDED BANK MOVE VARIABLES

	; EXTERNALLY DEFINED ENTRY POINTS AND LABELS:
	EXTRN	@CBNK
	EXTRN	?BNKSL
	ENDIF

	; INCLUDE Z-80 MACROS:
	MACLIB	Z80

	; LOCATE CODE IN THE COMMON SEGMENT:
	CSEG

	;;;;; ?XMOVE
	; ROUTINE SETS UP AN INTER-BANK MOVE OF 128 BYTES ON THE NEXT CALL
	;  TO ?MOVE:
?XMOVE:
	IF	BANKED
	MVI	A,0FFH		;SET EXTENDED MOVE FLAG
	STA	DOXMOV
	SBCD	XMOV$BANKS	;AND STORE BANKS FOR THE EXTENDED MOVE
	ENDIF
	RET

	;;;;; ?MOVE
	; ROUTINE PERFORMS INTRA-BANK MOVES IF ?XMOVE WAS NOT CALLED PRIOR TO
	;  THIS CALL TO ?MOVE ELSE A 128 BYTE TRANSFER IS CONDUCTED BETWEEN
	;  DIFFERENT BANKS:
?MOVE:
	IF	BANKED
	LDA	DOXMOV		;GET EXTENDED MOVE FLAG
	ORA	A		;IS IT SET ?
	MVI	A,0		;RESET FOR NEXT TIME ANYWAY
	STA	DOXMOV
	JRZ	MOVE$IT

	; HAVE TO IMPLEMENT INTER-BANK MOVE:
	LDA	@CBNK		;REMEMBER CURRENT BANK
	PUSH	PSW
	LDA	XMOV$BANKS	;GET SOURCE BANK
	CALL	?BNKSL		; AND SELECT IT
	PUSH	H		;SAVE DESTINATION ADDRESS
	PUSH	B		;AND THE COUNT
	XCHG			;[HL] = SOURCE
	LXI	D,BANKBUF	;[DE] = LOCAL TEMPORARY BUFFER
	LDIR			;BLOCK MOVE TO TEMP BUFFER
	POP	B		;RESTORE COUNT
	POP	D		;[DE] = ORIGINAL DESTINATION
	PUSH	H		;SAVE NEXT SOURCE ADDRESS
	LXI	H,BANKBUF	;[HL] = SOURCE = TEMP BUFFER
	LDA	XMOV$BANKS+1	;GET DESTINATION BANK
	CALL	?BNKSL		;AND SELECT IT
	LDIR			;BLOCK MOVE FROM TEMP BUFFER TO DESTINATION
	POP	H		;RESTORE NEXT SOURCE
	XCHG			;RETURN SWAP
	POP	PSW		;GET BACK PREVIOUS CURRENT BANK
	JMP	?BNKSL		;SELECT IT AND RETURN

	; ARRIVE HERE FOR INTRA-BANK MEMORY MOVE:
MOVE$IT:
	ENDIF

	XCHG			;WE ARE PASSED SOURCE IN DE AND DEST IN HL
	LDIR			;USE Z80 BLOCK MOVE INSTRUCTION
	XCHG			;NEED NEXT ADDRESSES IN SAME REGS
	RET

	;;;;; ?BANK
	; ROUTINE SWITCHES IN PHYSICAL BANK:
?BANK:
	IF	BANKED
	CPI	2		;BANK 2 OR HIGHER ?
	JRNC	BNK1$SWITCH	;GO DIRECTLY TO CODE TO CALCULATE THE
				; PHYSICAL ADDRESS...
	ORA	A		;ELSE SWAP BANK 0 AND 1 VALUES
	MVI	A,1		;IF BANK 0 MAKE BANK 1
	JRZ	BNK1$SWITCH
	XRA	A		;ELSE IF BANK 1 MAKE BANK 0
	JR	BNK2$SWITCH

	; HERE TO GET MPU-80 SEGMENT # FOR THE BANK WE NEED:
BNK1$SWITCH:
	DCR	A		;NORMALIZE BANK # RELATIVE TO 0
	ADD	A		;X2
	ADD	A		;X4 FOR 16K / WINDOW
	ADD	A		;X8 FOR 32K / BANK
	ADI	10H		;BANKS 1-15 START ABOVE 1ST 64K

	; DO PHYSICAL BANK SWITCHING HERE:
BNK2$SWITCH:
	PUSH	B		;SAVE [BC]
	LBCD	WIN$LOW$2BITS	;GET LOWER 2 BITS FOR EACH RELOCATION REGISTER
	DI			;CRITICAL SECTION -- NO INTERRUPTS HERE
	STA	CURRR0		;SAVE SEGMENT ADDR. OF LOWER WINDOW
	ORA	B		;[A] = WINDOW SEG + LOW 2 BITS
	OUT	MPURR0		;RELOCATE LOWER WINDOW NOW
	ANI	0FCH		;TAKE OUT LOWER 2 BITS
	ADI	4		;BUMP UP SEG ADDR BY 16K FOR UPPER WINDOW
	STA	CURRR1		;SAVE UPPER WINDOW SEGMENT ADDR.
	ORA	C		;[A] = WINDOW SEG + LOW 2 BITS
	OUT	MPURR1		;RELOCATE UPPER WINDOW
;;;;	EI			;CAN REENABLE INTERRUPTS NOW
	POP	B		;RESTORE [BC]
	ENDIF
	RET

	IF	BANKED
DOXMOV:		DB	0	;EXTENDED MOVE FLAG -- IF EQUAL TO FFH THEN
				; NEXT CALL TO ?MOVE WILL BE AN INTER-BANK
				; MOVE.

CURRR0:		DB	10H	;CURRENT LOWER WINDOW RELOCATION REGISTER
				; VALUE
CURRR1:		DB	14H	;CURRENT UPPER WINDOW RELOCATION REGISTER
				; VALUE

WIN$LOW$2BITS:	DB	1	;UPPER WINDOW REGISTER LOW 2 BITS (MAY CONTROL
				; ADDRESSING ABOVE 1 MEGABYTE OR EPROM SELECT)
		DB	1	;LOWER WINDOW REGISTER LOW 2 BITS (MAY CONTROL
				; ADDRESSING ABOVE 1 MEGABYTE OR EPROM SELECT)

XMOV$BANKS:	DS	1	;STORAGE AREA FOR DESTINATION BANK # FOR
				; EXTENDED MOVES
		DS	1	;STORAGE AREA FOR SOURCE BANK # FOR
				; EXTENDED MOVES

BANKBUF:	DS	128	;LOCAL TEMPORARY BUFFER FOR EXTENDED MOVES
	ENDIF


	END

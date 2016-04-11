

; ######################################################
;
;	���� ��� MK AT89C51RC 
;	��� ������ � SRAM 62256 � ��������
;
;
; ZeLDER
; ######################################################







;======================================================
;
;	����������� �����������
;
;	���� 1, �� �� �������� ������� (���������)
;	���� 0, �� ��� ����� �� Proteus
	F_LCD_RELEASE EQU 0



; ++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;						$$$
;				  PORTS from MK
;						$$$
;
;	P0, P2 out to SRAM addr bus
;	P1 out to LCD (8 bit data bus) and SRAM (8 bit data bus)
;
;	P3 out to LCD and RAM (commands)
;	P3.:
;		0 - E (LCD)
;		1 - RW (LCD)
;		2 - 
;		3 - CS (LCD), {CE (RAM) - ���� �� ������ ������}
;		4 - RES (LCD)
;		5 - A0 (LCD)
;		6 - WE (RAM)
;		7 - OE (RAM)
;
;
;						$$$
;				  PORTS from SRAM
;						$$$
;
;		27 (WE) - P3.6 (MK)
;		22 (OE) - P3.7 (MK)
;		20 (CE) - Ground {P3.3 ���� �� ������ ������}
;
; ++++++++++++++++++++++++++++++++++++++++++++++++++++
	INT_BTN EQU P3.2	; in interrupt
	
		

;;;;;;;;;;;;;;;;;;;;;
;; PROG help
;;
;;
;;	R5 - main loop
;;
;;	R0 - data byte for LCD
;;	R1 - commands for LCD
;;	
	
	
	
; ++++++++++++++++++++++++++++++++++++++++++++++++++++
; constants
	MANRUNFRAMES		EQU 0x03
	
	; RAM
	ADDR_GAME_FLAG		EQU 0x40

	

ORG 0x00
	LJMP MAIN
	

;#################################################
; ����������
;#################################################
ORG 03H ;external interrupt 0 (������ ������ �����������)
RETI
ORG 0BH ;timer 0 interrupt
RETI
ORG 13H ;external interrupt 1
RETI
ORG 1BH ;timer 1 interrupt
RETI
ORG 23H ;serial port interrupt
RETI
ORG 25H ;locate beginning of rest of program



;#################################################
ORG 0x30 ;0x0A




;; INIT
; ���������� ���������� (��� ������� �� ����� �������������)
DISINTS: ;set up control registers & ports
	MOV TCON, 	#0x00
	MOV TMOD, 	#0x00
	MOV PSW, 	#0x00 
	MOV IE, 	#0x00 ;disable interrupts
	RET

	
; =====================
;
; ����� �����
;
; =====================
MAIN:
	ACALL DISINTS
	ACALL LCDINIT
	ACALL RAMINIT
	ACALL LOOPRAM
	;ACALL LOOPRAM2

	
	
	
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
LOOPRAM2:
	
	;
	; write to RAM
	MOV R0, #0x01
	MOV R1, #0x00
	MOV A, #0xAA
	ACALL RAMWRITEDO
	MOV R0, #0x01
	MOV R1, #0x01
	MOV A, #0x55
	ACALL RAMWRITEDO
	MOV R0, #0x01
	MOV R1, #0x02
	MOV A, #0xAA
	ACALL RAMWRITEDO
	
	; draw
	; LCD reset addr
	MOV R0, #0xE2
	ACALL LCDWRITE_CODE_L
	MOV R0, #0xB9 ; page 1
	ACALL LCDWRITE_CODE_L
	MOV R0, #FIRSTADDLEFT
	ACALL LCDWRITE_CODE_L
		
	; read
	MOV R4, #0x00
	MOV R3, #3
	_dr_ram_123:
		;
		; read from RAM
		MOV R0, #0x01	; �� ������� � ����� ������� ���� ��������� � ����������
		MOV A, R4
		MOV R1, A
		ACALL RAMREADDO
		; draw
		MOV R0, A
		ACALL LCDWRITE_DATA_L
		; next RAM addr
		INC R4
		DJNZ R3, _dr_ram_123
			
			
	__gogo:
	JMP __gogo
	RET
	
	
	
	
	
	
; ������������ RAM
LOOPRAM:
	ACALL LCDCLEAR

	;
	; write to RAM from Data
	; ������ ������ � ���������� �� ������� ������
	;
	; RAM addr (� ���� ��������� ������� ���� � ����������)
	MOV DPTR, #0x0100
	PUSH DPH
	PUSH DPL
	; Data addr (� ���� ��������� ������� ������ ��� ������)
	MOV DPTR, #DDD_DATA_TXT1
	PUSH DPH
	PUSH DPL
	; count bytes for write to RAM
	MOV R4, #32	
	_writeby_txt:
		; = ������ �� ����� ������� �� ������ (� �������� ������� ���������)
		; --- Data (�� ����� ����� �� ������� ������)
		POP DPL
		POP DPH
		MOV A, #0
		MOVC A, @A+DPTR
		; next addr of Data (��������� ����� �� ������, ���� ���������� � ���������)
		INC DPTR
		MOV R0, DPH
		MOV R1, DPL
		; --- RAM addr (�� ����� ����� �� ������� � ����������)
		POP DPL
		POP DPH
		; write (by smart MK)
		MOVX @DPTR, A
		; next RAM (��������� ����� �� ����������, ���� ���������� � ���������)
		INC DPTR
		MOV R2, DPH
		MOV R3, DPL

		; = ���������� � ���� ����� ������� �� ������ (� �������� ������� ������)
		; ����� �� ����������
		MOV A, R2
		PUSH ACC
		MOV A, R3
		PUSH ACC
		; ����� �� ������
		MOV A, R0
		PUSH ACC
		MOV A, R1
		PUSH ACC
		
		DJNZ R4, _writeby_txt
	; ��������������� ����
	POP DPL
	POP DPH
	POP DPL
	POP DPH
	
	
	;
	; Draw from RAM
	; ��������� ������ �� ������� �� ����������
	;
	_doram2:
		; LCD reset addr
		MOV R0, #0xE2
		ACALL LCDWRITE_CODE_L
		MOV R0, #0xB9 ; page 1
		ACALL LCDWRITE_CODE_L
		MOV R0, #FIRSTADDLEFT
		ACALL LCDWRITE_CODE_L

		MOV R4, #0x00	; RAM addr (������� ������� ���� ������ �� ����������))
		MOV R3, #24		; draw count of bytes
		_dr_ram_12:
			;
			; read from RAM
			;
			MOV DPH, #0x01	; �� ������� � ����� ������� ���� ��������� � ����������
			MOV DPL, R4		; ��� ���������� � �������� ����� ��� ���������� ��������� (�� ��� ����� ������ �����)
			MOVX A, @DPTR
			; draw
			MOV R0, A
			ACALL LCDWRITE_DATA_L
			; next RAM addr
			INC R4
			DJNZ R3, _dr_ram_12

		
	_notdoram2:
		JMP _notdoram2
		
	RET
	
	
	
	
	
	
	
	
	
	
	
	
	
	

;; CORE
$INCLUDE (common.inc)
;; RAM
$INCLUDE (mram.inc)
;; LCD
$INCLUDE (mlcd.inc)
;; DATA
$INCLUDE (mdata.inc)



END


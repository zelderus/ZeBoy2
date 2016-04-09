Skip to content
This repository
Search
Pull requests
Issues
Gist
 @zelderus
 Unwatch 1
  Star 0
  Fork 0 zelderus/ZeBoy2
 Code  Issues 0  Pull requests 0  Wiki  Pulse  Graphs  Settings
Tree: 97fb72f29c Find file Copy pathZeBoy2/src_mk/fastman.asm
97fb72f  3 days ago
@zelderus zelderus reorg
1 contributor
RawBlameHistory     1121 lines (992 sloc)  26.1 KB


; ######################################################
;
;	���� ��� MK AT89C2051 
;	��������������� ���� �� �� � �������������� �������
;
;	������: 1.0
;		-��� ����� ������
;
; ZeLDER
; ######################################################





; ++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;				PORTS
;	
;	P1 out to LCD (8 bit data bus)
;
;	P3 out to LCD (commands)
;	P3.:
;		0 - E
;		1 - RW
;		2 - 
;		3 - CS
;		4 - RES
;		5 - A0
;		7 -
;
; ++++++++++++++++++++++++++++++++++++++++++++++++++++
	LCD_E 	EQU P3.0

	LCD_RW 	EQU P3.1	; -- but not used directy in code
	LCD_CS	EQU P3.3	; -- but not used directy in code
	LCD_RES	EQU P3.4
	LCD_A0 	EQU P3.5	; -- but not used directy in code
	
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
	FIRSTADDLEFT		EQU	0x13
	FIRSTADDRIGHT		EQU	0x00
	MANRUNFRAMES		EQU 0x03
	
	; RAM
	ADDR_GAME_FLAG		EQU 0x40
	ADDR_OFFSET_AIR		EQU 0x41
	ADDR_OFFSET_GRN		EQU 0x42
	ADDR_OFFSET_OBS		EQU 0x43
	ADDR_OFFSET_OBS_FR	EQU 0x44
	ADDR_MAN_FRAME		EQU 0x45
	ADDR_MAN_FLAG		EQU 0x46
	ADDR_MAN_FRAMERUN	EQU 0x47
	ADDR_MAN_CFRUN		EQU 0x48
	ADDR_MAN_OBST		EQU 0x49
	

ORG 0x00
	LJMP MAIN
	

;#################################################
; ����������
;#################################################


ORG 03H ;external interrupt 0 (������ ������ �����������)
	PUSH PSW
	ACALL INT_BUTTON
	POP PSW
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

; button interrupt
INITBUTTONINT:
	SETB EA
	SETB EX0 ;=IE.0	; enable external interrupt 0
	;SETB INT_BTN
	RET
	
	

	
; =====================
;
; ����� �����
;
; =====================
MAIN:
	ACALL DISINTS
	ACALL LCDINIT
	ACALL RESETGAME
	ACALL INITBUTTONINT
	ACALL MAINLOOP
	

RESETGAME:
	MOV R1, #ADDR_GAME_FLAG		; set address
	MOV @R1, #0x00		; write data (GAME FLAG)
	MOV R1, #ADDR_OFFSET_AIR		; set address
	MOV @R1, #0x00		; write data
	MOV R1, #ADDR_OFFSET_GRN		; set address
	MOV @R1, #0x00		; write data
	MOV R1, #ADDR_OFFSET_OBS		; set address
	MOV @R1, #0x00		; write data
	MOV R1, #ADDR_OFFSET_OBS_FR		; set address
	MOV @R1, #0x00		; write data
	MOV R1, #ADDR_MAN_FRAME		; set address
	MOV @R1, #0x00		; write data
	MOV R1, #ADDR_MAN_FLAG		; set address
	MOV @R1, #0x00		; write data
	MOV R1, #ADDR_MAN_FRAMERUN		; set address
	MOV @R1, #0x00		; write data
	MOV R1, #ADDR_MAN_CFRUN		; set address
	MOV @R1, #MANRUNFRAMES		; write data
	MOV R1, #ADDR_MAN_OBST		; set address
	MOV @R1, #0x00		; write data
	RET
	
NEWGAME:
	ACALL RESETGAME
	ACALL LCDCLEAR
	ACALL DRAW_TABLE
	; ����������
	;SETB EX0
	RET
	
	
	
;
; �������� ���� ����
;
MAINLOOP:
	ACALL LCDCLEAR
	ACALL DRAW_TABLE ; static table

	DONO:
		ACALL LCDDRAW
	
		JMP DONO
	RET
	
	
	
	
; =====================
; ������ ������ (������� ��������� ����������)
INT_BUTTON:
	; save
	;PUSH PSW
	PUSH ACC
	
	; �� ������������ ���������� ���
	CLR EX0 ;
	
	ACALL SETBANK1
	; �������
	MOV R1, #ADDR_MAN_FLAG
	MOV A, #0x01	; ���� ������
	MOV @R1, A
	; restore
	ACALL SETBANK0
	POP ACC
	;POP PSW
	RET
	
	
	
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;							;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	   	   LCD DRIVER		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;							;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
; =====================
;
; Helpers
;
; =====================
; �������
DELAYS:	; A = times
	MOV R7, A
	LMXZ:
		MOV R6, #4 ;#230
		LXZ:
			MOV R5, #250
			LMXD:
				MOV R4, #146 ;#230
				LXD:
					NOP
					NOP
					NOP
					NOP
					NOP
					NOP
					DJNZ R4, LXD
				DJNZ R5, LMXD
			DJNZ R6, LXZ
		DJNZ R7, LMXZ
	RET
; ������������ (10e-3)
DELAYMS:	; A = times
	MOV R7, A
	LMX:
		MOV R6, #146 ;#230
		LX:
			NOP
			NOP
			NOP
			NOP
			NOP
			NOP
			DJNZ R6, LX
		DJNZ R7, LMX
	RET
; ������������ (10e-6)
DELAYNS:	; A = times
	MOV R7, A
	LMX3:
		MOV R6, #1 ;#230
		LX3:
			;NOP
			DJNZ R6, LX3
		DJNZ R7, LMX3
	RET
; ����������� (10e-9)
DELAYUS:	; A = times
	MOV R7, A
	LMX2:
		MOV R6, #2 ;#230
		LX2:
			NOP
			NOP
			NOP
			DJNZ R6, LX2
		DJNZ R7, LMX2
	RET

STEPEND:
	MOV P1, #0x00
	RET
; ����� ������ ���������
SETBANK0:
	CLR PSW.3
	CLR PSW.4
	RET
SETBANK1:
	SETB PSW.3
	CLR PSW.4
	RET
SETBANK2:	; ���������� � ���� ������ (� ����������� �����)
	CLR PSW.3
	SETB PSW.4
	RET
SETBANK3:
	SETB PSW.3
	SETB PSW.4
	RET
	
; =====================
;
; Display
;
; =====================

; ----------------------	
; ������������� �������
; ----------------------
LCDINIT:
	; pre wait
	;MOV A, #20
	;ACALL DELAYMS
	;s_mtE(1)
	;s_mtRES(0)
	MOV P3, #0x01 ;#0b00000001 ;(E=1, RW=0, A0=0, CS=0, RES=0)
	;s_delayUs(12.0) #>10
	MOV A, #12
	ACALL DELAYUS
	;s_mtRES(1)
	SETB LCD_RES ;P3.4
	;s_delayMs(2.5)	#>1
	MOV A, #2
	ACALL DELAYMS
	; reset
	MOV R0, #0xE2
	ACALL LCDWRITE_CODE_L
	ACALL LCDWRITE_CODE_R
	; end (reset rmw)
	MOV R0, #0xEE
	ACALL LCDWRITE_CODE_L
	ACALL LCDWRITE_CODE_R
	; static off
	MOV R0, #0xA4
	ACALL LCDWRITE_CODE_L
	ACALL LCDWRITE_CODE_R
	; duty select
	MOV R0, #0xA9
	ACALL LCDWRITE_CODE_L
	ACALL LCDWRITE_CODE_R
	; display start line
	MOV R0, #0xC0
	ACALL LCDWRITE_CODE_L
	ACALL LCDWRITE_CODE_R
	; ADC select
	MOV R0, #0xA1
	ACALL LCDWRITE_CODE_L
	MOV R0, #0xA0			; !!!!!!!!!!1
	ACALL LCDWRITE_CODE_R
	; display on
	MOV R0, #0xAF
	ACALL LCDWRITE_CODE_L
	ACALL LCDWRITE_CODE_R
	; STEP END
	ACALL STEPEND
	RET
; ----------------------	
; ������ ������/������� � �������
; ----------------------
LCDWRITE:  ; R0 = data byte, R1 = cmd
	; set E,RW,A0,CS
	; without fix RES
	MOV P3, R1
	;s_mtData(b)
	MOV P1, R0
	;s_delayNs(40.0)	#>40
	MOV A, #40					; !!!!!!!! TEST !!!!!!
	ACALL DELAYNS
	;s_mtE(0)
	CLR LCD_E
	;s_delayNs(160.0)	#>160
	MOV A, #160
	ACALL DELAYNS
	;s_mtE(1)
	SETB LCD_E
	;s_delayNs(200.0 - 40.0 - 160.0) #2000.0 - 40.0 - 160.0
	;MOV A, #1
	;ACALL DELAYNS
	RET
LCDWRITE_CODE_L:	; R0 = data byte
	MOV R1, #0x1D ;#0b00011101 ;(E=1, RW=0, INT0=1, CS=1, RES=1, A0=0)
	ACALL LCDWRITE
	RET
LCDWRITE_CODE_R:	; R0 = data byte
	MOV R1, #0x15 ;#0b00010101 ;(E=1, RW=0, INT0=1, CS=0, RES=1, A0=0)
	ACALL LCDWRITE
	RET
LCDWRITE_DATA_L:	; R0 = data byte
	MOV R1, #0x3D ;#0b00111101 ;(E=1, RW=0, INT0=1, CS=1, RES=1, A0=1)
	ACALL LCDWRITE
	RET
LCDWRITE_DATA_R:	; R0 = data byte
	MOV R1, #0x35 ;#0b00110101 ;(E=1, RW=0, INT0=1, CS=0, RES=1, A0=1)
	ACALL LCDWRITE
	RET
; ----------------------	
; ������� �������
; ----------------------
LCDCLEAR:
	; reset addr
	;MOV R0, #0xE2
	;ACALL LCDWRITE_CODE_L
	MOV R4, #4	; page cycle
	LCDCLEAR_PAGE:
		; 4 to 0
		MOV A, #4
		SUBB A, R4
		MOV R2, A
		;; LEFT
		MOV A, R2
		ORL A, #0xB8
		MOV R0, A
		ACALL LCDWRITE_CODE_L
		MOV R0, #FIRSTADDLEFT
		ACALL LCDWRITE_CODE_L
		; left draw
		MOV R0, #0x00 	; clear symbol
		MOV R3, #61		; row cycle
		LCDCLEAR_PAGE_LEFT:
			ACALL LCDWRITE_DATA_L
			DJNZ R3, LCDCLEAR_PAGE_LEFT
		;; RIGHT
		MOV A, R2
		ORL A, #0xB8
		MOV R0, A
		ACALL LCDWRITE_CODE_R
		MOV R0, #FIRSTADDRIGHT
		ACALL LCDWRITE_CODE_R
		; right draw
		MOV R0, #0x00 	; clear symbol
		MOV R3, #61		; row cycle
		LCDCLEAR_PAGE_RIGHT:
			ACALL LCDWRITE_DATA_R
			DJNZ R3, LCDCLEAR_PAGE_RIGHT
		DJNZ R4, LCDCLEAR_PAGE
	; STEP END
	ACALL STEPEND
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;							;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	   end of LCD DRIVER	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;							;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
	
	
	
; ----------------------	
; ������ � �������
; ----------------------
LCDDRAW:
	; score
	ACALL DRAW_UPDATE_TABLE
	; air
	MOV DPTR, #DDD_DATA_AIR
	MOV R3, #0xB8
	MOV R4, #ADDR_OFFSET_AIR
	ACALL DRAW_RODR_L
	; ground
	MOV DPTR, #DDD_DATA_GROUND
	MOV R3, #0xBB
	MOV R4, #ADDR_OFFSET_GRN
	ACALL DRAW_RODR_L
	; obstacles
	ACALL DRAW_OBST
	; man
	ACALL DRAW_MAN
	RET


	
; ----------------------	
; ----------------------	
; ----------------------	

;
; ������ ������ ����� ������, ������� (�����)
;
DRAW_TABLE:
	; top
	MOV R3, #0xB8
	ACALL DRAW_TABLE_ROW
	; bottom
	MOV R3, #0xBB
	ACALL DRAW_TABLE_ROW
	RET
	
DRAW_TABLE_ROW: ; R3 = page (0xB8 .. 0xBB)
	MOV R0, #0xE2		; reset addr
	ACALL LCDWRITE_CODE_R
	MOV A, R3
	MOV R0, A ;#0xB8		; page
	ACALL LCDWRITE_CODE_R
	MOV R0, #FIRSTADDRIGHT		; addr
	ACALL LCDWRITE_CODE_R
	; draw
	MOV DPTR, #DDD_DATA_TBLB
	MOV R2, #61
	MOV R3, #0
	_ddro_tbl_stat_1:
		; addr
		MOV A, R3
		MOVC A, @A+DPTR
		; draw
		MOV R0, A
		ACALL LCDWRITE_DATA_R
		; next addr
		INC R3
		DJNZ R2, _ddro_tbl_stat_1
	RET
	
	
	
	
;
; ������ ������ ����� ������, ����
;
DRAW_UPDATE_TABLE:
	
	; TODO: ��� ������ ������� ���� � ������ !!!

	RET
	
	
	

	
	
;
; ��������� ������������ ���� (16) �������� (8x8)
; params:
;	DPTR 	= start data addr (Sprites)
;	R3 		= LCD page (0xB8 .. 0xBB)
;	R4 		= addr of Offset (0x40) (����� �������� ��������)
DRAW_RODR_L:
	MOV R0, #0xE2		; reset addr
	ACALL LCDWRITE_CODE_L
	MOV A, R3
	MOV R0, A		; page
	ACALL LCDWRITE_CODE_L
	MOV R0, #FIRSTADDLEFT		; addr
	ACALL LCDWRITE_CODE_L
	; get frame offset
	MOV A, R4
	MOV R1, A		; set start address
	MOV A, @R1			; read data
	; offset
	;MOV DPTR, #0x600 	; start addrs of Air
	;MOV DPL, A			; set offset
	; draw
	MOV R2, #61
	MOV R3, A	; R3 as offset
	_ddro_ag:
		; reset cycle
		CJNE R3, #15, _ddro_ag_oofs
		MOV R3, #0
		_ddro_ag_oofs:
		; addr
		MOV A, R3
		MOVC A, @A+DPTR
		; draw
		MOV R0, A
		ACALL LCDWRITE_DATA_L
		; next addr
		INC R3
		DJNZ R2, _ddro_ag
	; write offset
	MOV A, R4
	MOV R1, A		; set start address
	MOV A, R3
	MOV @R1, A	; write data
	RET
	
	
;	
; �������� ������������
;	R0, R5
; return: R6 = 1 ���� �� �������� � ��� ���� �����������
OBST_COLLISION:
	CJNE R0, #0x00, _dd_ll_1	; 1. ���� ��� ���� �����������
	MOV R6, #0
	RET
	_dd_collis:
		MOV R6, #1
		RET
	_dd_ll_1:
		CJNE R5, #1, _dd_collis	; 2. � ���� �� �� �������
		MOV R6, #0
	RET
	
;
; ������ ��������
;
DRAW_OBST:

	MOV R0, #0xE2		; reset addr
	ACALL LCDWRITE_CODE_L
	MOV A, R3
	MOV R0, #0xBA		; page 3
	ACALL LCDWRITE_CODE_L
	MOV R0, #FIRSTADDLEFT		; addr
	ACALL LCDWRITE_CODE_L
	; offset
	MOV DPTR, #DDD_DATA_OBST 
	; add frame offset
	MOV R1, #ADDR_OFFSET_OBS_FR
	MOV A, @R1
	; max frames
	CJNE A, #DDL_OBST_ROWS, _ddro_obt_rrf
		MOV A, #0
	_ddro_obt_rrf:
	MOV R4, A	;(R4)
	MOV A, DPL
	; �������� ������ ����� !!!
	ADD A, R4
	MOV DPL, A
	JNB PSW.7, _ddro_obt_jjb	; carry flag (��� ���������� � ������ ������, �� ��� ����� � ��� ����)
		INC DPH
	_ddro_obt_jjb:
	
	; � ������ �� (R5)
	MOV R1, #ADDR_MAN_FLAG
	MOV A, @R1
	MOV R5, A
	
	; ���������� ������� �������� ������������ (R6)
	;MOV R6, #0
	
	JMP _dd_normalgo
	; ���� �� � ������, � ��� ���� �����������
	_dd_gameover:
		ACALL DRAW_GAMEOVER
		RET
			
	_dd_normalgo:
	; draw
	MOV R2, #61
	MOV R3, #0
	_ddro_ag_obt:	; !! ���� ���� ������ ���� ���� ������ � ������ �� ������� (����� ����� ������� �������)
		; addr
		MOV A, R3
		MOVC A, @A+DPTR
		; obstacle byte sprite (R0)
		MOV R0, A


		; ���� �� � ������� ���������, �� ��������� � ��� ������
		; ?? � ���� �� ���, ���� ����� GameOver ����� �� ���� ������� ??
		CJNE R3, #0, _ddro_mm_0
			; �������� ������������
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; ����� �������� ������������
			ACALL SETBANK3
			MOV A, R0
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_0:
		CJNE R3, #1, _ddro_mm_1
			; �������� ������������
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; ����� �������� ������������
			ACALL SETBANK3
			MOV A, R1
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_1:
		CJNE R3, #2, _ddro_mm_2
			; �������� ������������
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; ����� �������� ������������
			ACALL SETBANK3
			MOV A, R2
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_2:
		CJNE R3, #3, _ddro_mm_3
			; �������� ������������
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; ����� �������� ������������
			ACALL SETBANK3
			MOV A, R3
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_3:
		CJNE R3, #4, _ddro_mm_4
			; �������� ������������
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; ����� �������� ������������
			ACALL SETBANK3
			MOV A, R4
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_4:
		CJNE R3, #5, _ddro_mm_5
			; �������� ������������
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; ����� �������� ������������
			ACALL SETBANK3
			MOV A, R5
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_5:
		CJNE R3, #6, _ddro_mm_6
			; �������� ������������
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; ����� �������� ������������
			ACALL SETBANK3
			MOV A, R6
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_6:
		CJNE R3, #7, _ddro_mm_7
			; �������� ������������
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; ����� �������� ������������
			ACALL SETBANK3
			MOV A, R7
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_7:
		
		_ddf_llop:
		;-------------------------
		
		
		; ������ ��� � R0
		ACALL LCDWRITE_DATA_L
		; next addr
		INC R3
		DJNZ R2, _ddro_ag_obt

	; save offset
	MOV R1, #ADDR_OFFSET_OBS_FR
	INC R4 		; next frame
	MOV A, R4
	MOV @R1, A	; write
	RET
	
	
	
;
; ������ Man
;
DRAW_MAN:
	
	MOV R0, #0xE2		; reset addr
	ACALL LCDWRITE_CODE_L
	MOV R0, #0xB9		; page 2
	ACALL LCDWRITE_CODE_L
	MOV R0, #FIRSTADDLEFT		; addr
	ACALL LCDWRITE_CODE_L
	; get frame offset
	MOV R1, #ADDR_MAN_FRAME
	MOV A, @R1
	MOV R5, A
	; next frame
	INC R5		; R5 = frame num
	
	; ���� �������
	;���� ADDR_MAN_FLAG == 1, ADDR_MAN_FRAME++; ���� ��������� ����� �� ����� (ADDR_MAN_FRAME == DDL_MAN_FRAMES), �� ADDR_MAN_FLAG = 0, ADDR_MAN_FRAME = 0
	
	; ���� ��� ������� ������, �� 0 ���� (���� �� ����� ����)
	MOV R1, #ADDR_MAN_FLAG
	MOV A, @R1
	CJNE A, #0, mmm_in_jump
		MOV R5, #0
		JMP _man_run	; �������� ����
	mmm_in_jump:
	
	; ��������� �����
	CJNE R5, #DDL_MAN_FRAMES, ddm_fr
		MOV R5, #0
		; ������������, ���������� ����
		MOV R1, #ADDR_MAN_FLAG
		MOV @R1, #0
		; �������� ���������� �������
		SETB EX0
	ddm_fr:
	
	; ������ ������ ������
	MOV A, R5
	MOV B, #8
	MUL AB
	MOV R4, A	; R4 = frame byte step
	; UP
	; offset
	MOV DPTR, #DDD_DATA_MAN_UP 	; start addrs of Man
	MOV A, DPL
	ADD A, R4	; ������ ����, ��������� � ���� (��������� ����)
	MOV DPL, A
	; draw
	MOV R2, #8
	MOV R3, #0
	_ddro_ag_man:
		; addr
		MOV A, R3
		MOVC A, @A+DPTR
		; draw
		MOV R0, A
		ACALL LCDWRITE_DATA_L
		; next addr
		INC R3
		DJNZ R2, _ddro_ag_man
	; DOWN
	MOV DPTR, #DDD_DATA_MAN_DOWN 	; start addrs of Man
	MOV A, DPL
	ADD A, R4	; ������ ����, ��������� � ���� (��������� ����)
	MOV DPL, A	; �������� ����� ����� ��������
	
	JMP man_down_inbank	; ������������� ����� ����
	
	;
	; �������� ���� (���� �� ���� ������)
	;
	_man_run:
		; DOWN
		; ������� �� ����� ������
		MOV R1, #ADDR_MAN_CFRUN
		MOV A, @R1
		DEC A
		MOV @R1, A	; save pause
		CJNE A, #0, man_run_norres
			; ������ ����
			MOV A, #MANRUNFRAMES	; reset
			MOV @R1, A				; save pause
			;
			MOV R1, #ADDR_MAN_FRAMERUN
			MOV A, @R1
			XRL A, #0x01	; ����� ����� ����
			MOV @R1, A
			JMP man_run_dr
		man_run_norres:	
			; �� ������ ����
			MOV R1, #ADDR_MAN_FRAMERUN
			MOV A, @R1
		man_run_dr:
			MOV B, #8
			MUL AB
			MOV DPTR, #DDD_DATA_MAN_RUN 
			ADD A, DPL
			MOV DPL, A	; �������� ����� ����� ��������
	
	
	
	man_down_inbank:
	; ���������� � �������� ��� 8 ���� ������ ����� ��������� (��� ��������� ���������� ����� � �������� � ���, � �����������)
	; ?? � ����� �� ���, ���� ��� ���������� �� ����������� ����� GameOver ??
	ACALL SETBANK3
	MOV A, #0
	MOVC A, @A+DPTR
	MOV R0, A
	MOV A, #1
	MOVC A, @A+DPTR
	MOV R1, A
	MOV A, #2
	MOVC A, @A+DPTR
	MOV R2, A
	MOV A, #3
	MOVC A, @A+DPTR
	MOV R3, A
	MOV A, #4
	MOVC A, @A+DPTR
	MOV R4, A
	MOV A, #5
	MOVC A, @A+DPTR
	MOV R5, A
	MOV A, #6
	MOVC A, @A+DPTR
	MOV R6, A
	MOV A, #7
	MOVC A, @A+DPTR
	MOV R7, A
	ACALL SETBANK0
	;-------------------------
		
	; save
	MOV R1, #ADDR_MAN_FRAME	
	MOV A, R5
	MOV @R1, A
	RET
	
	

;
; ���������
;
DRAW_GAMEOVER:
	; stop interr
	CLR EX0
	; DRAW GAMEOVER
	ACALL LCDCLEAR
	;============== �����  ==================
	;; LEFT
	MOV R0, #0xE2		; reset addr !!!!
	ACALL LCDWRITE_CODE_L
	MOV R0, #0xBA
	ACALL LCDWRITE_CODE_L
	MOV R0, #FIRSTADDLEFT
	ACALL LCDWRITE_CODE_L
	; draw
	; ����� ����� ����
	MOV R3, #30	; space
	_dr_gmo_f31:
		MOV R0, #0x00
		ACALL LCDWRITE_DATA_L
		DJNZ R3, _dr_gmo_f31
	; �����
	MOV R4, #0
	MOV R3, #31
	_dr_gmo_left:
		MOV DPTR, #DDD_DATA_GMO 
		MOV A, R4
		MOVC A, @A+DPTR
		MOV R0, A
		ACALL LCDWRITE_DATA_L
		INC R4
		DJNZ R3, _dr_gmo_left
	; RIGHT
	;MOV R0, #0xE2		; reset addr
	;ACALL LCDWRITE_CODE_R
	MOV R0, #0xBA
	ACALL LCDWRITE_CODE_R
	MOV R0, #FIRSTADDRIGHT
	ACALL LCDWRITE_CODE_R
	; draw
	; ������ ����� ����
	;MOV R4, #0
	MOV R3, #29
	_dr_gmo_right:
		MOV DPTR, #DDD_DATA_GMO 
		MOV A, R4
		MOVC A, @A+DPTR
		MOV R0, A
		ACALL LCDWRITE_DATA_R
		INC R4
		DJNZ R3, _dr_gmo_right
	;============== ��������� ������ ==================
	; pause
	MOV A, #10
	ACALL DELAYS
	; reset data
	ACALL NEWGAME
	; ����������
	SETB EX0
	RET
	
	


;#################################################
;##############    DATA   ########################
;#################################################

; game over text
DDD_DATA_GMO	EQU 0x3A0
ORG 0x3A0
	DB 0x7E, 0x7E, 0x02, 0x02, 0x7E, 0x7E, 0x00
	DB 0x7E, 0x7E, 0x42, 0x42, 0x7E, 0x7E, 0x00	
	DB 0x02, 0x02, 0x7E, 0x7E, 0x02, 0x02, 0x00	
	DB 0x7E, 0x7E, 0x12, 0x12, 0x1E, 0x1E, 0x00	
	DB 0x70, 0x7C, 0x0A							
	DB 0x0A, 0x7C, 0x70, 0x00					
	DB 0x0E, 0x0E, 0x08, 0x7E, 0x7E, 0x00		
	DB 0x7E, 0x7E, 0x4A, 0x42, 0x00				
	DB 0x7E, 0x7E, 0x08, 0x08, 0x7E, 0x7E, 0x00
	DB 0x7E, 0x7E, 0x42, 0x42, 0x7E, 0x7E, 0x00	
	
;; man 
DDD_DATA_MAN_RUN	EQU 0x3F0
ORG 0x3F0
	DB 0x00, 0x44, 0x4A, 0x3E, 0x0F, 0x1E, 0x24, 0xC0
	DB 0x00, 0x20, 0x3E, 0xEF, 0x3E, 0x04, 0x02, 0x00
	
DDL_MAN_FRAMES		EQU 0x18	; 24 ����� �� �������� ������ (���������� � ����� ������)
DDD_DATA_MAN_DOWN	EQU 0x400	; ������ ����� �� ������	(������ DPL ����� ������ ���� ����� � 0, ����� ����� ���������� ����� � 8 �����)
ORG 0x400
	DB 0x00, 0x04, 0xC2, 0x3C, 0x1F, 0x3C, 0xC2, 0x04
	DB 0x00, 0x42, 0x22, 0x1E, 0x0F, 0x1E, 0x22, 0x42
	DB 0x00, 0x04, 0x02, 0x02, 0x01, 0x01, 0x02, 0x04
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x04, 0x02, 0x02, 0x01, 0x01, 0x02, 0x04
	DB 0x00, 0x42, 0x22, 0x1E, 0x0F, 0x1E, 0x22, 0x42
	DB 0x00, 0x04, 0xC2, 0x3C, 0x1F, 0x3C, 0xC2, 0x04

DDD_DATA_MAN_UP	EQU 0x500		; ������� ����� �� ������ (������ DPL ����� ������ ���� ����� � 0, ����� ����� ���������� ����� � 8 �����)
ORG 0x500
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00
	DB 0x00, 0x20, 0x20, 0xE0, 0xF8, 0xE0, 0x20, 0x20
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x30, 0x22, 0x24, 0x1C, 0x1F, 0x34, 0x22, 0x30
	DB 0x00, 0x20, 0x20, 0xE0, 0xF8, 0xE0, 0x20, 0x20
	DB 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

;; obstacles
; ��� ����� ����������, ����� ������� ID �� �������, �������� ����� ������ � ������ ����� (��� �������)
; ���� �������� ���, ���� ����� ����� �������� (���� ���� ����� ������ � ���� ������)
DDL_OBST_ROWS	EQU 0xF0
DDD_DATA_OBST	EQU 0x675	; � ������� ����������� ������ ���� 8 ��� ������ ���������� �� ���������� ����� �����������
ORG 0x675
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0xF8, 0xF8, 0xFC, 0xFF, 0xFF, 0xFC, 0xF8, 0xF8, 0x00, 0x00
	
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0xE0, 0xF0, 0xB8, 0xB8, 0xB8, 0xB8, 0xF0, 0xE0, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0
	DB 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0xE0, 0xF0, 0xB8, 0xBC, 0xB8, 0xB8, 0xF0, 0xE0, 0x00, 0x00
	
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0xF8, 0xE0, 0xF8, 0xE0, 0xF8, 0xE0
	DB 0xF8, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x98, 0x88, 0x88, 0xFC, 0xFC, 0x88, 0x88, 0x98
	
	; repeat first (��� ��������� ��������)
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	DB 0xF8, 0xF8, 0xFC, 0xFF, 0xFF, 0xFC, 0xF8, 0xF8, 0x00, 0x00
	
;; air
DDD_DATA_AIR	EQU 0x7A1
ORG 0x7A1
	DB 0x08, 0x1C, 0x36, 0x22, 0x20, 0x20, 0x38, 0x0C
	DB 0x04, 0x0E, 0x1A, 0x12, 0x10, 0x18, 0x08, 0x08
;; ground
DDD_DATA_GROUND	EQU 0x7B1
ORG 0x7B1
	DB 0xCF, 0xC9, 0xF9, 0xC9, 0xCF, 0xC9, 0xF9, 0xC9
	DB 0xCF, 0xC9, 0xF9, 0xC9, 0xCF, 0xC9, 0xF9, 0xC9
;; table border (static)
DDD_DATA_TBLB	EQU 0x7C1
ORG 0x7C1
	DB 0xFF, 0xFF, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA
	DB 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA
	DB 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA
	DB 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA
	DB 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA
	DB 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xFF
	DB 0xFF

; last byte	
DATABR:
	DB 0x40



END

Status API Training Shop Blog About
� 2016 GitHub, Inc. Terms Privacy Security Contact Help


; ######################################################
;
;	Драйвер под MK AT89C51RC 
;	для работы с SRAM 62256 и дисплеем
;
;
; ZeLDER
; ######################################################



;======================================================
;
;	определения компилятору
;
;	если 1, то на реальный дисплей (адресация)
;	если 0, то для теста на Proteus
	F_LCD_RELEASE EQU 1



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
;		3 - CS (LCD), {CE (RAM) - если на низком уровне}
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
;		20 (CE) - Ground {P3.3 если на низком уровне}
;
; ++++++++++++++++++++++++++++++++++++++++++++++++++++
	INT_BTN EQU P3.2	; in interrupt
	;%%%%%% LCD
	LCD_E 	EQU P3.0
	LCD_RW 	EQU P3.1	; -- but not used directy in code
	LCD_CS	EQU P3.3	; -- but not used directy in code
	LCD_RES	EQU P3.4
	LCD_A0 	EQU P3.5	; -- but not used directy in code
	;%%%%%% RAM
	RAM_CE	EQU P3.3 ; только как заглушка, для низкого уровня
	RAM_OE	EQU P3.7
	RAM_WE	EQU P3.6
	;RAM_CE	EQU P3.3
	;RAM_OE	EQU P3.7
	;RAM_WE	EQU P3.6

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

	

ORG 0x00
	LJMP MAIN
	

;#################################################
; Прерывания
;#################################################
ORG 03H ;external interrupt 0 (вектор адреса поумолчанию)
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
; выключение прерываний (как правило на время инициализации)
DISINTS: ;set up control registers & ports
	MOV TCON, 	#0x00
	MOV TMOD, 	#0x00
	MOV PSW, 	#0x00 
	MOV IE, 	#0x00 ;disable interrupts
	RET

; button interrupt
INITBUTTONINT:
	;SETB EA
	;SETB EX0 ;=IE.0	; enable external interrupt 0
	RET
	
	

	
; =====================
;
; Точка входа
;
; =====================
MAIN:
	ACALL DISINTS
	ACALL LCDINIT
	ACALL RAMINIT
	ACALL INITBUTTONINT
	ACALL LOOPRAM



	
	
	
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	
	
; тестирование RAM
LOOPRAM:
	ACALL LCDCLEAR

	
	; write to RAM
	;MOV DPH, #0x01
	;MOV DPL, #0x00
	;MOV A, #0xAA
	;MOVX @DPTR, A
	;-
	MOV R0, #0x01
	MOV R1, #0x00
	MOV A, #0xFF
	ACALL RAMWRITEDO
	;-
	MOV R1, #0x01
	MOV A, #0xAA
	ACALL RAMWRITEDO
	;-
	MOV R1, #0x02
	MOV A, #0x55
	ACALL RAMWRITEDO
	;-
	MOV R1, #0x03
	MOV A, #0xAA
	ACALL RAMWRITEDO
	;-
	MOV R1, #0x04
	MOV A, #0x55
	ACALL RAMWRITEDO
	;-
	MOV R1, #0x05
	MOV A, #0xAA
	ACALL RAMWRITEDO
	;-
	MOV R1, #0x06
	MOV A, #0xFF
	ACALL RAMWRITEDO
	
	
	_doram2:
		; reset addr
		MOV R0, #0xE2
		ACALL LCDWRITE_CODE_L
		MOV R0, #0xB9 ; page 1
		ACALL LCDWRITE_CODE_L
		MOV R0, #FIRSTADDLEFT
		ACALL LCDWRITE_CODE_L
		
		; draw preset
		MOV R0, #0xFF
		ACALL LCDWRITE_DATA_L
		MOV R0, #0xAA
		ACALL LCDWRITE_DATA_L
		MOV R0, #0xFF
		ACALL LCDWRITE_DATA_L
		MOV R0, #0x81
		ACALL LCDWRITE_DATA_L
		MOV R0, #0x00
		ACALL LCDWRITE_DATA_L
			
			
		MOV R4, #0x00
		MOV R3, #7	; draw cols
		_dr_ram_12:
		
			MOV A, #0xFF
			
			; read from RAM
			;MOV A, #0x00
			;MOV DPTR, #0x00
			;MOV DPH, #0x01
			;MOVX A, @DPTR
			;-
			MOV R0, #0x01
			MOV A, R4
			MOV R1, A ;#0x00
			ACALL RAMREADDO
			; draw
			MOV R0, A
			ACALL LCDWRITE_DATA_L
		
			INC R4
			DJNZ R3, _dr_ram_12

		
	_notdoram2:
		;JMP _doram2
		JMP _notdoram2
		
	RET
	
	
	
	
	
	
	
	
	
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;							;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	   	   RAM DRIVER		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;							;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;; сюда вынесено для удобства чтения ;;;;
	;%%%%%% RAM (для МК кто работает с external памятью)
	;RAM_OE	EQU P3.7
	;RAM_WE	EQU P3.6
	;%%%%%% RAM (для низкого уровня)
	;RAM_CE	EQU P3.6
	;RAM_OE	EQU P3.3
	;RAM_WE	EQU P3.7
	
RAMINIT:
	; если используется низкий уровень
	;SETB RAM_CE	; standby RAM
	; AUXR.1 = 1
	SETB 08FH
	RET
; остался как пример (обертка, лучше использовать с постфиксом J)
; т.к. МК подобные AT89C51RC при правильном подключении (шина данных, шина адресации и WE=>WR, OE=>RD, CE=>Ground) 
; работают сами через MOVX
RAMWRITE:	; (R0 addr1 (0100H to FFFFH), R1 addr2, A data) out void
	; An access to external data memory locations higher than FFH (i.e. 0100H to FFFFH) will be performed
	; with the MOVX DPTR instructions in the same way as in the standard 80C51
	;MOV DPTR, #0x00
	MOV DPH, R0		; начиная с 0100H to FFFFH
	MOV DPL, R1
	MOVX @DPTR, A		; write
	RET
RAMWRITEJ:	; (DPH addr1 (0100H to FFFFH), DPL addr2, A data) out void
	MOVX @DPTR, A		; write
	RET
; версия на низком уровне (CE(RAM) должен быть подключен к RAM_CE(MK))
RAMWRITEN:	; (R0 addr1, R1 addr2, A data) out void
; TODO
	SETB RAM_WE
	SETB RAM_CE
	MOV P1, A
	MOV P0, R0
	MOV P2, R1
	CLR RAM_CE
	CLR RAM_WE
	NOP
	;CLR RAM_OE
	;CLR RAM_WE
	;CLR RAM_CE
	SETB RAM_WE
	SETB RAM_CE
	RET
; использовать как обертку для отладки (в релизе лучше использовать необходимую)
RAMWRITEDO:
	ACALL RAMWRITE
	;ACALL RAMWRITEN
	RET
	
; остался как пример (обертка, лучше использовать с постфиксом J)
; т.к. МК подобные AT89C51RC при правильном подключении (шина данных, шина адресации и WE=>WR, OE=>RD, CE=>Ground) 
; работают сами через MOVX
RAMREAD:	; (R0 addr1 (0100H to FFFFH), R1 addr2) out (A data)
	; An access to external data memory locations higher than FFH (i.e. 0100H to FFFFH) will be performed
	; with the MOVX DPTR instructions in the same way as in the standard 80C51
	;MOV DPTR, #0x00
	MOV DPH, R0 ;#0x01	; начиная с 0100H to FFFFH
	MOV DPL, R1 ;#0x00
	MOVX A, @DPTR
	RET
RAMREADJ:	; (DPH addr1 (0100H to FFFFH), DPL addr2) out (A data)
	MOVX A, @DPTR
	RET
; версия на низком уровне (CE(RAM) должен быть подключен к RAM_CE(MK))
RAMREADN:	; (R0 addr1, R1 addr2) out (A data)
; TODO
	SETB RAM_WE
	SETB RAM_CE
	SETB RAM_OE
	MOV P0, R0
	MOV P2, R1
	MOV P1, #0x00
	CLR RAM_CE
	CLR RAM_OE
	MOV A, P1
	SETB RAM_CE
	SETB RAM_OE
	RET
; использовать как обертку для отладки (в релизе лучше использовать необходимую)
RAMREADDO:
	ACALL RAMREAD
	;ACALL RAMREADN
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	   end of RAM DRIVER	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	
	
	
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
; секунда
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
; миллисекунда (10e-3)
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
; микросекунда (10e-6)
DELAYNS:	; A = times
	MOV R7, A
	LMX3:
		MOV R6, #1 ;#230
		LX3:
			;NOP
			DJNZ R6, LX3
		DJNZ R7, LMX3
	RET
; наносекунда (10e-9)
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
; смена банков регистров
SETBANK0:
	CLR PSW.3
	CLR PSW.4
	RET
SETBANK1:
	SETB PSW.3
	CLR PSW.4
	RET
SETBANK2:	; странности с этим банком (в прерываниях точно)
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
; Инициализация дисплея
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
	; !!!!! F_LCD_RELEASE - если определен
	IF (F_LCD_RELEASE==1)
	MOV R0, #0xA0
	ENDIF
	ACALL LCDWRITE_CODE_R
	; display on
	MOV R0, #0xAF
	ACALL LCDWRITE_CODE_L
	ACALL LCDWRITE_CODE_R
	; STEP END
	ACALL STEPEND
	RET
; ----------------------	
; Подача данных/команды в дисплей
; ----------------------
LCDWRITE:  ; R0 = data byte, R1 = cmd
	; set E,RW,A0,CS
	; without fix RES
	MOV P3, R1
	;s_mtData(b)
	MOV P1, R0
	;s_delayNs(40.0)	#>40
	MOV A, #40					; !!!
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
; Очистка дисплея
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
	
	
	
	


;#################################################
;##############    DATA   ########################
;#################################################


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




; ######################################################
;
;	Игра под MK AT89C51RC 
;	для работы с SRAM 62256 и дисплеем
;
;	HELP: 	http://zedk.ru/ss/zeboy2/index.html
;	SOURCE:	https://github.com/zelderus/ZeBoy2
;
; ZeLDER
; ######################################################







;======================================================
;
;	определения компилятору
;
;	если 1, то на реальный дисплей (адресация)
;	если 0, то для теста на Proteus
	F_LCD_RELEASE 	EQU 0
;	есди 1, то тест оперативки (test.inc)
	F_RAM_TEST		EQU 1
; 	метод работы с RAM
; 		0 - low level (R0 addr1, R1 addr2)
; 		1 - MK logic 1 (R0 addr1, R1 addr2)
; 		2 - MK logic 2 (DPH addr1, DPL addr2) - сомнительная полезность (меняется интерфейс обертки)
	F_RAM_LEVEL		EQU 2

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
; Прерывания
;#################################################
ORG 03H ;external interrupt 0 (вектор адреса поумолчанию)
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
; выключение прерываний (как правило на время инициализации)
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
; Точка входа
;
; =====================
MAIN:
	ACALL DISINTS
	ACALL LCDINIT
	ACALL RAMINIT
		
	IF (F_RAM_TEST==0)
	ACALL RESETGAME
	ACALL INITBUTTONINT
	ACALL MAINLOOP
	ELSE
	ACALL RAMTEST
	ENDIF

	
	
	
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	




	
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
	; прерывания
	;SETB EX0
	RET
	
	
;
; Основной цикл игры
;
MAINLOOP:
	ACALL LCDCLEAR
	ACALL DRAW_TABLE ; static table

	DONO:
		ACALL LCDDRAW
	
		JMP DONO
	RET
	
	
	
	
; =====================
; нажата кнопка (функция обработка прерывания)
INT_BUTTON:
	; save
	;PUSH PSW
	PUSH ACC
	
	; не обрабатываем прерывание это
	CLR EX0 ;
	
	ACALL SETBANK1
	; прыгаем
	MOV R1, #ADDR_MAN_FLAG
	MOV A, #0x01	; флаг прыжка
	MOV @R1, A
	; restore
	ACALL SETBANK0
	POP ACC
	;POP PSW
	RET
	

	
	
	
	
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
; ----------------------	
; Рисуем в дисплей
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
; рисуем правую часть экрана, статика (рамка)
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
; рисуем правую часть экрана, очки
;
DRAW_UPDATE_TABLE:
	
	; TODO: тут рисуем текущие очки и рекорд !!!

	RET
	
	
	

	
	
;
; Отрисовка циклического ряда (16) спрайтов (8x8)
; params:
;	DPTR 	= start data addr (Sprites)
;	R3 		= LCD page (0xB8 .. 0xBB)
;	R4 		= addr of Offset (0x40) (адрес хранения смещения)
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
; проверка столкновений
;	R0, R5
; return: R6 = 1 если не прыгнули и под нами препятствие
OBST_COLLISION:
	CJNE R0, #0x00, _dd_ll_1	; 1. если тут есть препятствие
	MOV R6, #0
	RET
	_dd_collis:
		MOV R6, #1
		RET
	_dd_ll_1:
		CJNE R5, #1, _dd_collis	; 2. и если мы не прыгали
		MOV R6, #0
	RET
	
;
; рисуем преграды
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
	; сложение больше байта !!!
	ADD A, R4
	MOV DPL, A
	JNB PSW.7, _ddro_obt_jjb	; carry flag (нам достаточно и одного сдвига, не так много у нас сцен)
		INC DPH
	_ddro_obt_jjb:
	
	; в прыжке ли (R5)
	MOV R1, #ADDR_MAN_FLAG
	MOV A, @R1
	MOV R5, A
	
	; сбрасываем регистр проверки столкновений (R6)
	;MOV R6, #0
	
	JMP _dd_normalgo
	; были не в прыжке, и под нами препятствие
	_dd_gameover:
		ACALL DRAW_GAMEOVER
		RET
			
	_dd_normalgo:
	; draw
	MOV R2, #61
	MOV R3, #0
	_ddro_ag_obt:	; !! этот цикл должен быть прям байтик в байтик по размеру (чтобы длины прыжков хватило)
		; addr
		MOV A, R3
		MOVC A, @A+DPTR
		; obstacle byte sprite (R0)
		MOV R0, A


		; если мы в позиции Персонажа, то учитываем и его спрайт
		; ?? а надо ли это, если сразу GameOver когда на этой позиции ??
		CJNE R3, #0, _ddro_mm_0
			; проверка столкновения
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; конец проверки столкновения
			ACALL SETBANK3
			MOV A, R0
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_0:
		CJNE R3, #1, _ddro_mm_1
			; проверка столкновения
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; конец проверки столкновения
			ACALL SETBANK3
			MOV A, R1
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_1:
		CJNE R3, #2, _ddro_mm_2
			; проверка столкновения
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; конец проверки столкновения
			ACALL SETBANK3
			MOV A, R2
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_2:
		CJNE R3, #3, _ddro_mm_3
			; проверка столкновения
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; конец проверки столкновения
			ACALL SETBANK3
			MOV A, R3
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_3:
		CJNE R3, #4, _ddro_mm_4
			; проверка столкновения
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; конец проверки столкновения
			ACALL SETBANK3
			MOV A, R4
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_4:
		CJNE R3, #5, _ddro_mm_5
			; проверка столкновения
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; конец проверки столкновения
			ACALL SETBANK3
			MOV A, R5
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_5:
		CJNE R3, #6, _ddro_mm_6
			; проверка столкновения
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; конец проверки столкновения
			ACALL SETBANK3
			MOV A, R6
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_6:
		CJNE R3, #7, _ddro_mm_7
			; проверка столкновения
			ACALL OBST_COLLISION
			CJNE R6, #0, _dd_gameover
			; конец проверки столкновения
			ACALL SETBANK3
			MOV A, R7
			ACALL SETBANK0
			ORL A, R0
			MOV R0, A
		_ddro_mm_7:
		
		_ddf_llop:
		;-------------------------
		
		
		; рисуем что в R0
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
; рисуем Man
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
	
	; кадр анимции
	;если ADDR_MAN_FLAG == 1, ADDR_MAN_FRAME++; если кончились кадры на полет (ADDR_MAN_FRAME == DDL_MAN_FRAMES), то ADDR_MAN_FLAG = 0, ADDR_MAN_FRAME = 0
	
	; если нет сигнала прыжка, то 0 кадр (идем на ветку бега)
	MOV R1, #ADDR_MAN_FLAG
	MOV A, @R1
	CJNE A, #0, mmm_in_jump
		MOV R5, #0
		JMP _man_run	; анимация бега
	mmm_in_jump:
	
	; кончились кадры
	CJNE R5, #DDL_MAN_FRAMES, ddm_fr
		MOV R5, #0
		; приземлились, сбрасываем флаг
		MOV R1, #ADDR_MAN_FLAG
		MOV @R1, #0
		; включаем прерывание обратно
		SETB EX0
	ddm_fr:
	
	; стопка кадров прыжка
	MOV A, R5
	MOV B, #8
	MUL AB
	MOV R4, A	; R4 = frame byte step
	; UP
	; offset
	MOV DPTR, #DDD_DATA_MAN_UP 	; start addrs of Man
	MOV A, DPL
	ADD A, R4	; кадров мало, адресация с нуля (переносов нету)
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
	ADD A, R4	; кадров мало, адресация с нуля (переносов нету)
	MOV DPL, A	; итоговый адрес кадра анимации
	
	JMP man_down_inbank	; перескакиваем ветку бега
	
	;
	; анимация бега (если не было прыжка)
	;
	_man_run:
		; DOWN
		; задерка на смену кадров
		MOV R1, #ADDR_MAN_CFRUN
		MOV A, @R1
		DEC A
		MOV @R1, A	; save pause
		CJNE A, #0, man_run_norres
			; меняем кадр
			MOV A, #MANRUNFRAMES	; reset
			MOV @R1, A				; save pause
			;
			MOV R1, #ADDR_MAN_FRAMERUN
			MOV A, @R1
			XRL A, #0x01	; смена кадра бега
			MOV @R1, A
			JMP man_run_dr
		man_run_norres:	
			; не меняем кадр
			MOV R1, #ADDR_MAN_FRAMERUN
			MOV A, @R1
		man_run_dr:
			MOV B, #8
			MUL AB
			MOV DPTR, #DDD_DATA_MAN_RUN 
			ADD A, DPL
			MOV DPL, A	; итоговый адрес кадра анимации
	
	
	
	man_down_inbank:
	; запоминаем в регистры все 8 байт нижней части Персонажа (при отрисовки препятсвий учтем и нарисуем и это, и препятствие)
	; ?? а нужно ли это, если при нахождении на препятствии сразу GameOver ??
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
; потрачено
;
DRAW_GAMEOVER:
	; stop interr
	CLR EX0
	; DRAW GAMEOVER
	ACALL LCDCLEAR
	;============== пишем  ==================
	;; LEFT
	MOV R0, #0xE2		; reset addr !!!!
	ACALL LCDWRITE_CODE_L
	MOV R0, #0xBA
	ACALL LCDWRITE_CODE_L
	MOV R0, #FIRSTADDLEFT
	ACALL LCDWRITE_CODE_L
	; draw
	; левую часть букв
	MOV R3, #30	; space
	_dr_gmo_f31:
		MOV R0, #0x00
		ACALL LCDWRITE_DATA_L
		DJNZ R3, _dr_gmo_f31
	; буквы
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
	; правую часть букв
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
	;============== закончили писать ==================
	; pause
	MOV A, #10
	ACALL DELAYS
	; reset data
	ACALL NEWGAME
	; прерывания
	SETB EX0
	RET





;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
;; TEST
IF (F_RAM_TEST==1)
$INCLUDE (test.inc)
ENDIF

	
	
	

;; CORE
$INCLUDE (common.inc)
;; RAM
$INCLUDE (mram.inc)
;; LCD
$INCLUDE (mlcd.inc)
$INCLUDE (video.inc)
;; DATA
$INCLUDE (mdata.inc)



END



;
; for Test
;
; ZeLDER
;



RAMTEST:
	;ACALL ___LOOPRAM
	
	ACALL ___POSTTEST
	;ACALL ___RAMTEST
	
	;ACALL ___LOOPRAM3
	RET
	
	
; тест порта (мигание)
___POSTTEST:
	; led on
	MOV P1, #0xFF
	MOV A, #2
	ACALL DELAYS
	; led off
	MOV P1, #0x00
	MOV A, #2
	ACALL DELAYS
	JMP ___POSTTEST
	RET
; тест оперативки (мигание)
___RAMTEST:
	; write to RAM
	MOV DPTR, #0x0200
	MOV A, #0xAA
	MOVX @DPTR, A
	; view
	___rmtt_lop:
	MOV DPTR, #0x0200
	MOVX A, @DPTR
	; led on
	MOV P1, A
	MOV A, #2
	ACALL DELAYS
	; led off
	MOV P1, #0x00
	MOV A, #2
	ACALL DELAYS
	JMP ___rmtt_lop
	RET
	
	
	
	
___LOOPRAM3:
	ACALL ___RESETZERO
	__gogo44:
		; clear
		ACALL MATRIX_CLEAR
		; update
		ACALL ___UPDATE
		; draw
		ACALL VIDEO_DRAW
	JMP __gogo44
	RET
	
	
	
;
;	Сброс парамтеров в RAM
;
___RESETZERO:
	; var test
	MOV DPTR, #ADDR_VAR_TEST
	MOV A, #0x00
	MOVX @DPTR, A
	; var PosX
	MOV DPTR, #ADDR_VAR_GG_POSX_H
	MOV A, #0x00
	MOVX @DPTR, A
	MOV DPTR, #ADDR_VAR_GG_POSX_L
	MOV A, #0x00
	MOVX @DPTR, A
	RET
	
	
	
	
; максимальное количество позиции на карте (по X)
GG_MAXXPOS	EQU 0x05DC	;1500
	
	
___UPDATE:
	
	
	;--- var PosX ---
	MOV DPTR, #ADDR_VAR_GG_POSX_H
	MOVX A, @DPTR
	MOV R1, A
	MOV DPTR, #ADDR_VAR_GG_POSX_L
	MOVX A, @DPTR
	MOV R2, A
	; next PosX
	ACALL MATH_INC16
	; check (as GG_MAXXPOS)
	CJNE R2, #0xDC, __gg_posx_cmp1
		CJNE R1, #0x05, __gg_posx_cmp1
			MOV R1, #0 
			MOV R2, #0 
	__gg_posx_cmp1:
	; save PosX
	MOV A, R1
	MOV DPTR, #ADDR_VAR_GG_POSX_H
	MOVX @DPTR, A
	MOV A, R2
	MOV DPTR, #ADDR_VAR_GG_POSX_L
	MOVX @DPTR, A
	; to DPTR
	MOV DPH, R1
	MOV DPL, R2
	;--- end of PosX ---
	

	
	
	
	
	; draw 1
	MOV R6, #1
	MOV DPTR, #DDD_SPRITE_OBJ1
	ACALL MATRIX_SPRITE8
	; draw 2
	MOV R6, #14
	MOV DPTR, #DDD_SPRITE_OBJ1+(1*8)
	ACALL MATRIX_SPRITE8
	; draw 3
	MOV R6, #24
	MOV DPTR, #DDD_SPRITE_OBJ1+(2*8)
	ACALL MATRIX_SPRITE8
	
	RET	
	
	
	
	
	
	
	
	
	
	
___UPDATE___old:
	
	; var x
	MOV DPTR, #ADDR_VAR_TEST
	MOVX A, @DPTR
	INC A
	; reset
	CJNE A, #18, ___cjjp
		MOV A, #0 
	___cjjp:
	MOVX @DPTR, A
	MOV R5, A
	
	; draw 1
	MOV R6, #1
	MOV DPTR, #DDD_SPRITE_OBJ1
	ACALL MATRIX_SPRITE8
	; draw 2
	MOV R6, #14
	MOV DPTR, #DDD_SPRITE_OBJ1+(1*8)
	ACALL MATRIX_SPRITE8
	; draw 3
	MOV R6, #24
	MOV DPTR, #DDD_SPRITE_OBJ1+(2*8)
	ACALL MATRIX_SPRITE8
	RET
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
; тестирование RAM
___LOOPRAM:
	;ACALL LCDCLEAR

	;
	; write to RAM from Data
	; запись данных в оперативку из области данных
	;
	; RAM addr (в стек стартовая позиция куда в оперативку)
	MOV DPTR, #0x0100
	PUSH DPH
	PUSH DPL
	; Data addr (в стек стартовая позиция данных для записи)
	MOV DPTR, #DDD_DATA_GMO ;#DDD_DATA_TXT1
	PUSH DPH
	PUSH DPL
	; count bytes for write to RAM
	MOV R4, #32	
	_writeby_txt:
		; = читаем из стека позиции на адреса (в обратном порядке занесения)
		; --- Data (из стека адрес на текущие данные)
		POP DPL
		POP DPH
		MOV A, #0
		MOVC A, @A+DPTR
		; next addr of Data (следующий адрес на данные, пока запоминаем в регистрах)
		INC DPTR
		MOV R0, DPH
		MOV R1, DPL
		; --- RAM addr (из стека адрес на позицию в оперативке)
		POP DPL
		POP DPH
		; write (by smart MK)
		MOVX @DPTR, A
		; next RAM (следующий адрес на оперативку, пока запоминаем в регистрах)
		INC DPTR
		MOV R2, DPH
		MOV R3, DPL

		; = записываем в стек новые позиции на адреса (в обратном порядке чтения)
		; адрес на оперативку
		MOV A, R2
		PUSH ACC
		MOV A, R3
		PUSH ACC
		; адрес на данные
		MOV A, R0
		PUSH ACC
		MOV A, R1
		PUSH ACC
		
		DJNZ R4, _writeby_txt
	; восстанавливаем стек
	POP DPL
	POP DPH
	POP DPL
	POP DPH
	
	
	;
	; Draw from RAM
	; отрисовка данных на дисплей из оперативки
	;
	_doram2:
		; LCD reset addr
		MOV R0, #0xE2
		ACALL LCDWRITE_CODE_L
		MOV R0, #0xB9 ; page 1
		ACALL LCDWRITE_CODE_L
		MOV R0, #FIRSTADDLEFT
		ACALL LCDWRITE_CODE_L

		MOV R4, #0x00	; RAM addr (текущий младший байт адреса на оперативку))
		MOV R3, #24		; draw count of bytes
		_dr_ram_12:
			;
			; read from RAM
			;
			MOV DPH, #0x01	; мы уверены и знаем старший байт адресации в оперативке
			MOV DPL, R4		; нам достаточно и младшего байта для увеличения адресации (не так много данных всего)
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
	
	
	
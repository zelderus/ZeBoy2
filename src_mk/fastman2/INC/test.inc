
;
; for Test
;
; ZeLDER
;



RAMTEST:
	ACALL ___LOOPRAM
	;ACALL ___LOOPRAM2
	RET
	
	

___LOOPRAM2:
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
		MOV R0, #0x01	; мы уверены и знаем старший байт адресации в оперативке
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
	
	
	
	
	
	
; тестирование RAM
___LOOPRAM:
	ACALL LCDCLEAR

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
	
	
	
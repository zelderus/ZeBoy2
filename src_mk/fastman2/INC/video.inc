
; ######################################################
;
; 	Video buffer
;	используется для вывода на дисплей
;	используя SRAM
;
;	Functions:
;		VIDEO_CLEAR
;		VIDEO_DRAW
;		VIDEO_DRAW2
;
;		MATRIX_CLEAR
;		MATRIX_PIXEL		{R0 - x; R1 - y}
;		MATRIX_SPRITE8		{R5 - x; R6 - y; DPTR - addr of sprite (8x8)}
;
;
; ZeLDER
; ######################################################

IFNDEF F_LCD_RELEASE
;	если 1, то на реальный дисплей (адресация)
;	если 0, то для теста на Proteus
	F_LCD_RELEASE 	EQU 1
ENDIF

IFNDEF VIDEO_ADDR
VIDEO_ADDR			EQU 0x0100
ENDIF
VIDEO_ROWS			EQU 61
VIDEO_PAGES			EQU 4
VIDEO_PAGE_SZ		EQU 8
VIDEO_CLRSYMB		EQU 0x00
VIDEO_ADDR_2		EQU VIDEO_ADDR+(VIDEO_ROWS*VIDEO_PAGES)

; Variables
IFNDEF ADDR_VAR_VIDEO_SPRITEX
ADDR_VAR_VIDEO_SPRITEX	EQU 0x0080
ENDIF
	
	
;-------------------------------------
;
; Очистка видео буффера
;
;-------------------------------------
MATRIX_CLEAR:
	; RAM addr
	MOV DPTR, #VIDEO_ADDR
	; count of pages
	MOV R4, #VIDEO_PAGES	
	_mtx_clr_pages:
		; rows
		MOV R5, #VIDEO_ROWS	* 2
		_mtx_clr_rows:
			;
			MOV A, #VIDEO_CLRSYMB
			MOVX @DPTR, A
			INC DPTR
			DJNZ R5, _mtx_clr_rows
		DJNZ R4, _mtx_clr_pages
	RET

	
;-------------------------------------
;
; Очистка буффера и дисплея
;
;-------------------------------------
VIDEO_CLEAR:
	ACALL MATRIX_CLEAR
	ACALL VIDEO_DRAW
	RET

	
	
;-------------------------------------
;
; Отрисовка видео буффера на дисплей
;	
;-------------------------------------

;
; Отрисовка по половине дисплея (сначала левая, потом правая)
;
VIDEO_DRAW:
	; start video buff
	MOV DPTR, #VIDEO_ADDR
	;
	; L
	; count of pages
	MOV R4, #VIDEO_PAGES	
	_mtx_drw_pagesdd:
		; reset addr
		MOV R0, #0xE2
		ACALL LCDWRITE_CODE_L
		; 4 to 0
		MOV A, #4
		SUBB A, R4
		MOV R2, A
		; rows (left)
		MOV A, R2
		ORL A, #0xB8
		MOV R0, A
		ACALL LCDWRITE_CODE_L
		MOV R0, #FIRSTADDLEFT
		ACALL LCDWRITE_CODE_L
		MOV R5, #VIDEO_ROWS
		_mtx_drw_rowsdd:
			; read from RAM
			MOVX A, @DPTR
			; draw
			;MOV R0, A
			ACALL LCDWRITE_DATA_ML
			; next RAM addr
			INC DPTR
			DJNZ R5, _mtx_drw_rowsdd
		; end of Page cicle
		DJNZ R4, _mtx_drw_pagesdd
	;
	; R
	IF (F_LCD_RELEASE==1)
	; start video buff
	MOV DPTR, #VIDEO_ADDR
	; count of pages
	MOV R4, #VIDEO_PAGES	
	_mtx_drw_pages2dd:
		; reset addr
		MOV R0, #0xE2
		ACALL LCDWRITE_CODE_R
		; rows (right)
		; 4 to 0
		MOV A, #4
		SUBB A, R4
		MOV R2, A
		; rows
		MOV A, R2
		ORL A, #0xB8
		MOV R0, A
		ACALL LCDWRITE_CODE_R
		MOV R0, #FIRSTADDRIGHT
		ACALL LCDWRITE_CODE_R
		MOV R5, #VIDEO_ROWS
		_mtx_drw_rows2dd:
			; read from RAM
			MOVX A, @DPTR
			; draw
			;MOV R0, A
			ACALL LCDWRITE_DATA_MR
			; next RAM addr
			INC DPTR
			DJNZ R5, _mtx_drw_rows2dd
		; end of Page cicle
		DJNZ R4, _mtx_drw_pages2dd
	ENDIF
	RET
	
	
	
;
; Отрисовка по страницам (страница слева, страница справа..)
; НЕ ИСПОЛЬЗУЕТСЯ (ОСТАЛСЯ ДЛЯ ПРИМЕРА)
; Массив матрицы лежит деленный по половинам дисплея
;
VIDEO_DRAW2:
	; start video buff
	MOV DPTR, #VIDEO_ADDR
	; count of pages
	MOV R4, #VIDEO_PAGES	
	_mtx_drw_pages:
		; 4 to 0
		MOV A, #4
		SUBB A, R4
		MOV R2, A
		; rows (left)
		MOV A, R2
		ORL A, #0xB8
		MOV R0, A
		ACALL LCDWRITE_CODE_L
		MOV R0, #FIRSTADDLEFT
		ACALL LCDWRITE_CODE_L
		MOV R5, #VIDEO_ROWS
		_mtx_drw_rows:
			; read from RAM
			MOVX A, @DPTR
			; draw
			;MOV R0, A
			ACALL LCDWRITE_DATA_ML
			; next RAM addr
			INC DPTR
			DJNZ R5, _mtx_drw_rows
		; rows (right)
		MOV A, R2
		ORL A, #0xB8
		MOV R0, A
		ACALL LCDWRITE_CODE_R
		MOV R0, #FIRSTADDRIGHT
		ACALL LCDWRITE_CODE_R
		MOV R5, #VIDEO_ROWS
		_mtx_drw_rows2:
			; read from RAM
			MOVX A, @DPTR
			; draw
			IF (F_LCD_RELEASE==1)
			;MOV R0, A
			ACALL LCDWRITE_DATA_MR
			ENDIF
			; next RAM addr
			INC DPTR
			DJNZ R5, _mtx_drw_rows2
		; end of Page cicle
		DJNZ R4, _mtx_drw_pages
	RET
	
	
	
	
	
;-------------------------------------
;
; HELPERS
;
;-------------------------------------
	
	
;-------------------------------------
; Помещение пикселя в буффер
;-------------------------------------
MATRIX_PIXEL: ; R0 - x, R1 - y
	MOV DPTR, #VIDEO_ADDR
	; если в правую часть дисплея, то вторая половина памяти
	MOV A, #VIDEO_ROWS
	CLR PSW.7
	SUBB A, R0
	JNC _mtx_ptpx1
	MOV DPTR, #VIDEO_ADDR_2
	_mtx_ptpx1:
	; вычитаем ряд
	MOV A, R1
	MOV B, #VIDEO_PAGE_SZ
	DIV AB		; (y/8)
	MOV B, #VIDEO_ROWS
	MUL AB ; offset in RAM
	CLR PSW.7
	MOV R3, DPL
	ADDC A, R3
	MOV DPL, A	; slide in RAM
	JNC _mtx_ptpx2
	INC DPH
	_mtx_ptpx2:
	; смещаем на x
	MOV A, R0
	CLR PSW.7
	MOV R3, DPL
	ADDC A, R3
	MOV DPL, A
	JNC _mtx_ptpx3
	INC DPH
	_mtx_ptpx3:
	; draw
	; 1<<(y%8)
	MOV A, R1
	MOV B, #VIDEO_PAGE_SZ
	DIV AB		; (y%8)
	MOV A, B
	; 1<<A
	MOV R3, A
	MOV A, #1
	_mtx_ptpx4:
		RL A
		DJNZ R3, _mtx_ptpx4
	MOV R3, A
	; |=
	MOVX A, @DPTR
	ORL A, R3
	; to RAM
	MOVX @DPTR, A
	RET

;-------------------------------------
;	MATRIX_SPRITE8
;		R5 		- x
;		R6 		- y
;		DPTR 	- addr of sprite (8x8)
;-------------------------------------
MATRIX_SPRITE8: 
	PUSH DPH
	PUSH DPL
	; read sprite
	; rows X (#ADDR_VAR_VIDEO_SPRITEX)
	; var OffsetX
	MOV DPTR, #ADDR_VAR_VIDEO_SPRITEX
	MOV A, #0x00
	MOVX @DPTR, A
	MOV R2, #8
	__drw_smbX:
		; x
		; OffsetX + posX
		MOV DPTR, #ADDR_VAR_VIDEO_SPRITEX
		MOVX A, @DPTR
		ADD A, R5
		MOV R0, A
		; OffsetX = OffsetX+1
		MOVX A, @DPTR
		INC A
		MOVX @DPTR, A
		; y
		MOV A, R6
		MOV R1, A
		; from Sprite data
		POP DPL	
		POP DPH
		MOV A, #0
		MOVC A, @A+DPTR
		INC DPTR
		PUSH DPH
		PUSH DPL
		PUSH ACC
		; draw row (byte)
		MOV R4, #8
		__drw_smbY:
			; bit
			POP ACC
			CLR PSW.7
			RRC A
			PUSH ACC
			;		
			JNC __drw_smbX_f
			ACALL MATRIX_PIXEL	; R0-x; R1-y
			__drw_smbX_f:
			; y++
			INC R1
			;
			DJNZ R4, __drw_smbY
		POP ACC
		DJNZ R2, __drw_smbX
	POP DPL
	POP DPH
	RET
	
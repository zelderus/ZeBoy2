
; ######################################################
;
;	Functions for SRAM
;
;
; using:
;
;	ZeLDER
; ######################################################



;%%%%%% RAM
RAM_CE	EQU P3.3 ; только как заглушка, для низкого уровня
RAM_OE	EQU P3.7
RAM_WE	EQU P3.6


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;
; 						HELP
;
; 	; включение AUXR.1 бита, для включения работы с внешней памятью средставми МК
; SETB 08FH
;
;	; запись в оперативку (0100H to FFFFH)
; MOV DPH, #0x01
; MOV DPL, #0x00
; MOVX @DPTR, A		; write
;
;	; чтение из оперативки
; MOV DPH, #0x01
; MOV DPL, #0x00
; MOVX A, @DPTR		; read
;
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;							;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	   	   RAM DRIVER		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;							;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;; сюда вынесено для удобства чтения ;;;;
	;%%%%%% RAM (для МК кто работает с external памятью)
	;RAM_CE	EQU P3.3 ;(для низкого уровня)
	;RAM_OE	EQU P3.7
	;RAM_WE	EQU P3.6
	
RAMINIT:
	; если используется низкий уровень
	SETB RAM_CE	; standby RAM
	SETB RAM_OE
	SETB RAM_WE
	; AUXR.1 = 1 (высокий уровень)
	;SETB 08FH
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
; эта функцию применять, если МК не умеет работать с 62256
RAMWRITEN:	; (R0 addr1, R1 addr2, A data) out void
; TODO: не протестировано
	MOV P2, R0
	MOV P0, R1
	CLR RAM_CE
	MOV P1, A
	CLR RAM_WE
	NOP	; !!!!
	SETB RAM_WE
	SETB RAM_CE
	RET
; использовать как обертку для отладки (в релизе лучше использовать необходимую)
RAMWRITEDO:
	ACALL RAMWRITE
	;ACALL RAMWRITEN ; low level
	RET
	
; остался как пример (обертка, лучше использовать с постфиксом J)
; т.к. МК подобные AT89C51RC при правильном подключении (шина данных, шина адресации и WE=>WR, OE=>RD, CE=>Ground) 
; работают сами через MOVX
RAMREAD:	; (R0 addr1 (0100H to FFFFH), R1 addr2) out (A data)
	; An access to external data memory locations higher than FFH (i.e. 0100H to FFFFH) will be performed
	; with the MOVX DPTR instructions in the same way as in the standard 80C51
	;MOV DPTR, #0x00
	MOV DPH, R0
	MOV DPL, R1
	MOVX A, @DPTR
	RET
RAMREADJ:	; (DPH addr1 (0100H to FFFFH), DPL addr2) out (A data)
	MOVX A, @DPTR
	RET
; версия на низком уровне (CE(RAM) должен быть подключен к RAM_CE(MK))
; эта функцию применять, если МК не умеет работать с 62256
RAMREADN:	; (R0 addr1, R1 addr2) out (A data)
; TODO: не протестировано
	MOV P2, R0
	MOV P0, R1
	CLR RAM_CE
	CLR RAM_OE
	NOP	; !!!!
	MOV A, P1
	SETB RAM_OE
	SETB RAM_CE
	RET
; использовать как обертку для отладки (в релизе лучше использовать необходимую)
RAMREADDO:
	ACALL RAMREAD
	;ACALL RAMREADN ; low level
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	   end of RAM DRIVER	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


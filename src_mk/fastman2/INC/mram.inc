
; ######################################################
;
;	Functions for SRAM
;
;
; using:
;
;	ZeLDER
; ######################################################

IFNDEF F_RAM_LEVEL
; метод работы с RAM
; 0 - low level (R0 addr1, R1 addr2)
; 1 - MK logic 1 (R0 addr1, R1 addr2)
; 2 - MK logic 2 (DPH addr1, DPL addr2) - сомнительная полезность (меняется интерфейс)
F_RAM_LEVEL		EQU 2
ENDIF

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
	IF (F_RAM_LEVEL==0)
	SETB RAM_CE	; standby RAM
	SETB RAM_OE
	SETB RAM_WE
	ELSE
	; AUXR.1 = 1 (высокий уровень)
	SETB 08FH
	ENDIF
	RET
RAMWRITEM:	; (DPH addr1 (0100H to FFFFH), DPL addr2, A data) out void
	; An access to external data memory locations higher than FFH (i.e. 0100H to FFFFH) will be performed
	; with the MOVX DPTR instructions in the same way as in the standard 80C51
	MOVX @DPTR, A		; write
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
	IF (F_RAM_LEVEL==0)
	ACALL RAMWRITEN ; low level
	ELSEIF (F_RAM_LEVEL==1)
	ACALL RAMWRITE
	ELSEIF (F_RAM_LEVEL==2)
	ACALL RAMWRITEM ; mini
	ENDIF
	RET
	
RAMREADM:	; (DPH addr1 (0100H to FFFFH), DPL addr2) out (A data)
	; An access to external data memory locations higher than FFH (i.e. 0100H to FFFFH) will be performed
	; with the MOVX DPTR instructions in the same way as in the standard 80C51
	MOVX A, @DPTR
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
	IF (F_RAM_LEVEL==0)
	ACALL RAMREADN ; low level
	ELSEIF (F_RAM_LEVEL==1)
	ACALL RAMREAD
	ELSEIF (F_RAM_LEVEL==2)
	ACALL RAMREADM ; mini
	ENDIF
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	   end of RAM DRIVER	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


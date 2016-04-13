
; ######################################################
;
; 	Math functions
;
;		MATH_INC16			{R1,R2}
;		MATH_ADD16			{R1,R2 - x; R3,R4 - y} {R1,R2}
;		MATH_ADD16_DPTR		{DPTR - x; R3,R4 - y} {DPTR}
;
; ZeLDER
; ######################################################



	
	
;-----------------------------------
;	Инкремент 16 бит
;	IN:
;		R1,R2 - x
;	OUT:
;		R1(high),R2(low)
;-----------------------------------
MATH_INC16:
	; low
	MOV A, R2
	ADDC A, #0x01
	MOV R2, A
	; high
	MOV A, R1
	ADDC A, #0x00
	MOV R1, A
	; result R1,R2
	RET
	

;-----------------------------------
;	Сложение 16 бит
;	IN:
;		R1,R2 - x; R3,R4 - y
;	OUT:
;		R1(high),R2(low)
;-----------------------------------
MATH_ADD16:
	; low
	MOV A, R2
	ADDC A, R4
	MOV R2, A
	; high
	MOV A, R1
	ADDC A, R3
	MOV R1, A
	; result R1,R2
	RET
	
	
;-----------------------------------
;	Сложение 16 бит
;	IN:
;		DPTR - x; R3,R4 - y
;	OUT:
;		DPTR
;-----------------------------------
MATH_ADD16_DPTR:
	; low
	MOV A, DPL
	ADDC A, R4
	MOV DPL, A
	; high
	MOV A, DPH
	ADDC A, R3
	MOV DPH, A
	; result DPTR
	RET
	
        ; 8080 assembler code
        .hexfile Collatz.hex
        .binfile Collatz.com
        ; try "hex" for downloading in hex format
        .download bin  
        .objcopy gobjcopy
        .postbuild echo "OK!"
        ;.nodump

	; OS call list
PRINT_B		equ 1
PRINT_MEM	equ 2
READ_B		equ 3
READ_MEM	equ 4
PRINT_STR	equ 5
READ_STR	equ 6
LOAD_EXEC       equ 7
PROCESS_EXIT    equ 8
SET_QUANTUM     equ 9
GTU_OS          equ 3   ; where system call starts

	; Position for stack pointer

	org 3072  ;this code starts
	jmp begin

str1:	dw  ': ',00H ; print colon : 
str2:   dw  ' ', 00H  ; empty space
str3:   dw  00AH, 00H  ; new line

	            
DIV:                ; B and C is the dividend registers, D is divisor,
	MVI E, 9    ; returns C as quotient B as remainder
	MOV A, B    ; for 16 bits, 9 cycle enough to rotate 

DIV0:	MOV B, A    
	MOV A, C
	RAL         ; shifts 1 bit left and take the most significant bit of C 
	MOV C, A    ; and pust to B's least significant bit
	DCR E       ; decrease counter
	JZ DIV2
	MOV A, B
	RAL         ; shifts 1 bit left take the most significant bit of B
	JNC DIV1    ; and puts to C's least significant bit
	SUB D
	JMP DIV0

DIV1:	SUB D       ; checks if divisor less than high-order quotient
	JNC DIV0    ; if not then adds back
	ADD D
	JMP DIV0
	
DIV2:	RAL         
	MOV E, A
	MVI A, 0FFH  
	XRA C
	MOV C, A    ; puts quotient to C 
	MOV A, E
	RAR
	RET

MULT:               ; D is multiplicand C is multiplier
	MVI B, 0	; B and C is result register
	MVI E, 9
MULT0:	MOV A, C
	RAR
	MOV C, A
	DCR E
	JZ DONE
	MOV A, B
	JNC MULT1
	ADD D
MULT1:
	RAR
	MOV B, A
	JMP MULT0
DONE:
	RET
	

collatz:             ; H is N 

	MVI A, 1     ; checks if N == 1, if true then sequence is done
 	CMP H
	JZ DONE2	 
	MVI B, 0
	MOV C, H
	MVI D, 2
	CALL DIV     ; checks if n%2==0, if true then it is even 
	MOV A, B
	CPI 0
	JZ evenNumber
	JMP oddNumber

evenNumber:
	MVI A, PRINT_B
	MOV B, C    ; C is N/2
	MOV H, C     ; L is N/2 now 
	CALL GTU_OS
 	CALL printEmptySpace	
	JMP collatz

oddNumber:
	MOV D, H
	MVI C, 3
	CALL MULT
	MOV B, C
	INR B
	MOV H, B
	MVI A, PRINT_B
	CALL GTU_OS
	CALL printEmptySpace	
	JMP collatz

DONE2:
	CALL printNewLine
	RET


printColon:              ; prints colon (:) to the screen  
	LXI B, str1
	MVI A, PRINT_STR
	CALL GTU_OS
	RET

printEmptySpace:            ; prints empty space to the screen
	LXI B, str2
	MVI A, PRINT_STR
	CALL GTU_OS
	RET

printNewLine:            ; prints new line to the screen
	LXI B, str3
	MVI A, PRINT_STR
	CALL GTU_OS
	RET


begin:
	MVI L, 2	  ; start with 2
loop:
	MOV B, L        
	MVI A, PRINT_B  
	CALL GTU_OS       ; Print number
	CALL printColon
	MOV H, L
        CALL collatz      ; checks if it is prime or not     
	INR L
	MOV A, L
	CPI 26
	JNZ loop          ; if n is smaller than 25 then keep running 
	MVI A, PROCESS_EXIT              ; end program
	CALL GTU_OS



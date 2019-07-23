        ; 8080 assembler code
        .hexfile Factorize.hex
        .binfile Factorize.com
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

	; Position for stack pointer
stack   equ 0F000h

	org 000H
	jmp begin

	; Start of our Operating System
GTU_OS:	PUSH D
	push D
	push H
	push psw
	nop	; This is where we run our OS in C++, see the CPU8080::isSystemCall()
		; function for the detail.
	pop psw
	pop h
	pop d
	pop D
	ret
	; ---------------------------------------------------------------
	; YOU SHOULD NOT CHANGE ANYTHING ABOVE THIS LINE        


str:   dw  ' ', 00H  ; space character

	            
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

factorize:             ; L = N 
	MVI H, 1       ; H is counter
counter:
	MOV A, H       
	CMP L	       ; checks if H == N then print last number and exit
	JZ exit	
	MVI B, 0
	MOV C, L       ; setd B and C dividend and D is divisor
	MOV D, H
	CALL DIV
	MOV A, B
	CPI 0          ; checks if N % i == 0 then prints that i
	JZ print
again:	INR H	
	JMP counter

exit:                  ; prints the last number at L register and exit
	MOV B, L
	MVI A, PRINT_B
	CALL GTU_OS
	RET

print:                ; prints the number at H register
	MOV B, H
	MVI A, PRINT_B
	CALL GTU_OS
	LXI B, str
	MVI A, PRINT_STR
	CALL GTU_OS
	JMP again
		

begin:
	LXI SP,stack 	    ; always initialize the stack pointer
	MVI A, READ_B       ; Read number and save B
	CALL GTU_OS   
	MOV L, B
	CALL factorize     
	hlt                 ; end program




        ; 8080 assembler code
        .hexfile ShowPrimes.hex
        .binfile ShowPrimes.com
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

	org 32768   ; this code starts
	jmp begin

str1:	dw  ' prime',00AH,00H ; null terminated string
str2:   dw  00AH, 00H  ; new line

org 40000
	            
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

  org 32785
isPrime:             ; L = N 
	MVI H, 2     ; H is counter

counter:
	MOV A, H     ; checks if H == N, if true then it is prime number
 	CMP L
	JZ prime	 
	MVI B, 0
	MOV C, L
	MOV D, H
	CALL DIV     ; checks if n%i==0, if true then it is not prime 
	MOV A, B
	CPI 0
	JZ notPrime
	INR H	
	JMP counter

prime:                   ; if n is prime then E =1
	MVI E, 1
	RET

notPrime:                ; if n is not prime then E =0
	MVI E, 0
	RET


printPrime:              ; prints 'prime number' to the screen  
	LXI B, str1
	MVI A, PRINT_STR
	CALL GTU_OS
	JMP return

printNewLine:            ; prints new line to the screen
	LXI B, str2
	MVI A, PRINT_STR
	CALL GTU_OS
	JMP return
		

begin:
	MVI L, 2	  ; start with 2
loop:
	MOV B, L        
	MVI A, PRINT_B  
	CALL GTU_OS       ; Print number
        CALL isPrime      ; checks if it is prime or not
	MOV A, E          ; if E = 1 then prime otherwise not prime
	CPI 1
	JZ printPrime     ; print prime or not prime
	JNZ printNewLine
return: INR L
	MOV A, L
	CPI 255
	JNZ loop          ; if n is smaller than 255 then keep running 
	MVI A, PROCESS_EXIT              ; end program
	CALL GTU_OS



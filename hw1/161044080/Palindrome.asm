        ; 8080 assembler code
        .hexfile Palindrome.hex
        .binfile Palindrome.com
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

str1:   dw  ': Palindrome', 00H
str2:   dw  ': Not Palindrome', 00H 

length:                  ; Finds the lenght of string
	MVI L, 0         ; Address of string at B and C register       
loop:	LDAX B           ; Save the length in L register
	CPI 0
	JZ exitLength    ; checks if str[L] == '\0' then exit
	INR L
	INX B
	JMP loop

exitLength:
	RET

index:                   ; E =index 
	MVI A, 0         ; Return the character at the index, str[index]
loop2:	CMP E            ; Address of string at B and C register
	JZ returnIndex   ; Checks if A == E then return character in that index
	INX B		 ; Increase the address index times
	INR A
	JMP loop2

returnIndex:
	LDAX B
	RET
	

palindrome:           ; Checks that if strig is palindrome or not
	MVI H, 0      ; Address of string at B and C register 
	DCR L         ; H and D register are the counter H = 0, L =length of string
loop3:	MOV E, H
	PUSH B
	CALL index    ; takes the character of str[H] and str [L]  
	POP B            
	MOV D, A
	MOV E, L
	PUSH B
	CALL index
	POP B             ; checks if str[H] == str[L] is true, if not then exit palindrome 
	CMP D
	JNZ exitFalse
	INR H             ; increase H by 1, decrease L by 1 until L == 0 
	DCR L
	MOV A, L 
	CPI 0
	JZ exitTrue
	JMP loop3


	
exitFalse:           ; prints 'not palindrome'
	LXI B, str2
	MVI A, PRINT_STR
	CALL GTU_OS
	RET

exitTrue:           ; prints 'palindrome'
	LXI B, str1
	MVI A, PRINT_STR
	CALL GTU_OS
	RET
	

begin:
	LXI SP,stack 	    ; always initialize the stack pointer	
	MVI A, READ_STR	    ; Read the string and save B C
	CALL GTU_OS
	MVI A, PRINT_STR
	CALL GTU_OS
	PUSH B
	CALL length
	POP B
	CALL palindrome     ; checks the palindrome
	hlt                 ; end program




        ; 8080 assembler code
        .hexfile Sum.hex
        .binfile Sum.com
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

	org 16384  ;this code starts
	jmp begin
	
sum	ds 2 ; will keep the sum

begin:
        mvi c, 20	; init C with 20
	mvi a, 0	; A = 0
loop:
	ADD c		; A = A + C
	DCR c		; --C
	JNZ loop	; goto loop if C!=0
	STA SUM		; SUM = A
	LDA SUM		; A = SUM
			; Now we will call the OS to print the value of sum
	MOV B, A	; B = A
	MVI A, PRINT_B	; store the OS call code to A
	call GTU_OS	; call the OS
	MVI A, PROCESS_EXIT
	call GTU_OS





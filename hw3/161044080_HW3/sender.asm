        ; 8080 assembler code
        .hexfile Sender.hex
        .binfile Sender.com
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
RAND_INT        equ 10
WAIT		equ 11
SIGNAL 		equ 12         
GTU_OS          equ 3   ; where system call starts

	; Position for stack pointer

	org 1024   ;this code starts
	jmp begin

MailBox1:	dw 2003H

checkIndex:
	MOV A, C
	CPI 0
	JNZ setIndex
	ret

setIndex:
	INX D    ; ++DE
	DCR C    ; --C
	JNZ setIndex
	ret

begin:
        MVI H, 3	; init H with 3
loop1:
	DCR H		; --H
	JZ exit	        ; go to exit if H ==0
	MVI L, 200	; L = 200

loop2:	MVI A, RAND_INT	; A = rand()
        CALL GTU_OS	; Now we will call the OS to get random number

	PUSH H	        ; save H L
	LHLD MailBox1   ; get mailbox address
	XCHG            ; change H L to D E
	MOV H, B	; save rand number to H

	MVI A, WAIT     
	MVI B, 1        ; id = 1
	MVI C, 1        ; empty semaphore
	CALL GTU_OS     ; take lock

	CALL checkIndex 

	MOV A, H        ; save rand number to A
	STAX D          ; save number to mailbox

	MVI A, SIGNAL
	MVI B, 1        ; id =1
	MVI C, 2        ; full semaphore
	CALL GTU_OS     ; release lock	

	POP H
	DCR L		; --L
	JZ loop1        ; if L == o go to loop1 
	JMP loop2       ; else go to loop2
	
exit:	MVI A, PROCESS_EXIT
	call GTU_OS



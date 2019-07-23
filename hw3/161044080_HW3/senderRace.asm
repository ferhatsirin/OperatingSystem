	; 8080 assembler code
        .hexfile SenderRace.hex
        .binfile SenderRace.com
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
MailBoxIndex:    dw 2002H

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

loop2:	MVI A, RAND_INT	; A = getRand()
        CALL GTU_OS	; Now we will call the OS to get random number in B

	PUSH H	            ; save H L
	LHLD MailBoxIndex   ; get mailbox index
	XCHG                ; change H L to D E
	LDAX D              ; get index
	MOV C, A            ; save index to C

	LHLD MailBox1   ; get mailbox address
	XCHG            ; save it to D E

	CALL checkIndex ; go to index

	MOV A, B        ; save rand number to A
	STAX D          ; save number to mailbox

	LHLD MailBoxIndex   ; get mailbox index
	XCHG                ; change H L to D E
	LDAX D              ; get index
	INR A               ; increase index by 1  
	STAX D              ; save index

	POP H           ; take H L back

	DCR L		; --L
	JZ loop1        ; if L == o go to loop1 
	JMP loop2       ; else go to loop2
	
exit:	MVI A, PROCESS_EXIT
	call GTU_OS





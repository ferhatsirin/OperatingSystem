        ; 8080 assembler code
        .hexfile Receiver.hex
        .binfile Receiver.com
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
	org 3000H
LocalList:	ds 400H

	org 2048   ;this code starts
	jmp begin

MailBox1:	dw 2003H
ListIndex:      dw 3000H
 
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
loop2:
	PUSH H	        ; take initial index and save to D
	LHLD MailBox1   ; get mailbox address
	XCHG            ; change H L to D E
	POP H
	
	MVI A, WAIT     
	MVI B, 1        ; id = 1
	MVI C, 2        ; full semaphore
	CALL GTU_OS     ; take lock
                        ; critical region starts
	CALL checkIndex
	LDAX D          ; load number from mailbox
	MOV D, A        ; save A to D

	MVI A, SIGNAL
	MVI B, 1        ; id =1
	MVI C, 1        ; empty semaphore
	CALL GTU_OS     ; release lock

	MOV A, D        ; load A again
	PUSH H          ; save H L	
	LHLD ListIndex  
	XCHG            ; change HL DE
	STAX D          ; save A to local list
	INX D
	XCHG            ; change HL DE
	SHLD ListIndex  ; save index
	POP H           ; pop HL back
	
	DCR L		; --L
	JZ loop1        ; if L == o go to loop1 
	JMP loop2       ; else go to loop2
	
exit:	MVI A, PROCESS_EXIT
	call GTU_OS



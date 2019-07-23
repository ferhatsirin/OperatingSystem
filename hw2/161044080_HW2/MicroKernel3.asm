        ; 8080 assembler code
        .hexfile MicroKernel3.hex
        .binfile MicroKernel3.com
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
RANDOM_NUM      equ 10

	; Position for stack pointer

	org 000H
	jmp init

	; Start of our Operating System
GTU_OS:	PUSH D
	push D
	push H
	push psw
	nop	; This is where we run our OS in C++, see the CPU8080::isSystemCall()
		; function for the detail.
	pop psw
	pop H
	pop D
	pop D
	ret
	; ---------------------------------------------------------------
	; YOU SHOULD NOT CHANGE ANYTHING ABOVE THIS LINE        

queueCount:  db 0
prgCount:    db 0
scStack:     dw 60000
initStack    dw 1023

	org 28H    ; this address is reserved for scheduler 

JMP schedular 
JMP exitProcess  

prg1:   dw  'Sum.com', 00H
prg2:   dw  'ShowPrimes.com', 00H 
prg3:   dw  'Collatz.com', 00H


schedular:  DI    ; disable interrupt
	POP H   ; delete rst
save: 
	LHLD 259   ; D and E register
	PUSH H
	LHLD 261    ; H and L register
	PUSH H
	LHLD 267   ; base register
	PUSH H
	LHLD 265   ; pc
	PUSH H
	LHLD 257   ; B and C register
	PUSH H
	LDA 256    ; A register
	MOV B, A
	LDA 269    ; cc register
	MOV C, A
	PUSH B
 	
	LXI H, 00H   ;        
	DAD SP       ; new stack to H L
	XCHG         ; H L to D E
	CALL queue_add_pop     ; save prg stack

load:	   
	SPHL       ; set stack
	POP PSW    ; A and cc register
	POP B      ; B and C register
	POP H      ; pc
	POP D      ; base
	EI         ; enable ınterrupt
	PCHL       ; start process
	

queue_add_pop:        ; D is push value
 	LHLD scStack  ; set scheduler stack
	SPHL 
        LDA queueCount
	CPI 0
	JZ directAdd
	MOV B, A	
rotate:	POP H
	DCX SP
	DCX SP
	PUSH H
	INX SP
	INX SP
	INX SP
	INX SP
	DCR A 
	CPI 0
	JNZ rotate
	PUSH D
add:
        DCX SP
	DCX SP
	INR A
	CMP B
	JNZ add
	INR A
	STA queueCount
	JMP queue_pop
directAdd:
	PUSH D
	INR A
	STA queueCount
	JMP queue_pop

queue_pop:
	DCX D
	DCX D
	PUSH D
	POP B      ; old stack value in B C
	POP H      ; prg stack
	XCHG       ; H L to D E
	LDA queueCount
	DCR A 
	STA queueCount   ; decrease counter 
	LXI H, 00H
	DAD SP
	SHLD scStack
	PUSH B
	POP H
	SPHL    ; set old stack
	XCHG    ; D E to H L
	ret

	org 10EH  ; this area is reserved for interrupt FF - 10E 

exitProcess:
	DI
	LDA prgCount
	DCR A         ;descrease program count
	STA prgCount
	LHLD scStack
	SPHL          ; set stack
	POP D
	LXI H, 00H
	DAD SP
 	SHLD scStack   ; save new stack
        LDA queueCount
	DCR A
	STA queueCount    ;decrease queue count
	XCHG   ;D E to H L	
	JMP load

createProcess:
	LXI H, 00H
	DAD  SP        ; take stack
	SHLD initStack  ;save stack			
	LHLD scStack
	SPHL           ;set scheduler stack
	PUSH B
	LDA queueCount
	INR A
	STA queueCount
	LDA prgCount
	INR A 
	STA prgCount
	LXI H, 00H
	DAD SP 
        SHLD scStack   ; save stack
	LHLD initStack
	SPHL
	ret

init:
	LHLD initStack 	    ; initialize init stack
	SPHL
	MVI A, RANDOM_NUM
	CALL GTU_OS
	MOV A, B
	CPI 1
	JZ runPRG12
	CPI 2
	JZ runPRG23
	JMP runPRG13


runPRG12:
	LXI B, 1024+1011    ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg1
	LXI H, 1024
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 2048+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg2
	LXI H, 2048
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 3072+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg1
	LXI H, 3072
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 4096+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg2
	LXI H, 4096
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 5120+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg1
	LXI H, 5120
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 6144+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg2
	LXI H, 6144
 	CALL GTU_OS
    	EI  ;enable interrupt

	JMP initLoop

runPRG23:
	LXI B, 2048+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg2
	LXI H, 2048
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 3072+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg3
	LXI H, 3072
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 1024+1011    ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg2
	LXI H, 1024
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 4096+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg3
	LXI H, 4096
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 5120+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg2
	LXI H, 5120
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 6144+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg3
	LXI H, 6144
 	CALL GTU_OS
    	EI  ;enable interrupt

	JMP initLoop

runPRG13:
	LXI B, 3072+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg3
	LXI H, 3072
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 1024+1011    ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg1
	LXI H, 1024
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 2048+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg3
	LXI H, 2048
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 4096+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg1
	LXI H, 4096
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 5120+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg3
	LXI H, 5120
 	CALL GTU_OS
    	EI  ;enable interrupt

	LXI B, 6144+1011     ; program stack address
	DI ;disable interrupt
	CALL createProcess	
	MVI A, LOAD_EXEC
	LXI B, prg1
	LXI H, 6144
 	CALL GTU_OS
    	EI  ;enable interrupt	

	JMP initLoop

initLoop:	
	LDA prgCount
	CPI 0
	JZ HLT
	JMP initLoop
	
HLT:	hlt                 ; end program







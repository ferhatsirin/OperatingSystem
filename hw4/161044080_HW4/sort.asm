        ; 8080 assembler code
        .hexfile Sort.hex
        .binfile Sort.com
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

        org  50200   ; list address
List:   ds 4000
	org 60000
ListIndex: dw 50200

	org 49152   ;this code starts
	jmp begin


Sort:                ; start sort algorithm
	CMP B        ; compare array with rand number
	MOV A, B     ; find place to load

sortLoop:	
	MOV B, A    
	MOV A, C
	CMP  B    ; check array numbers 
	MOV H, A    ; and put number to H 
	DCR E       ; decrease counter
	JZ sort
	MOV A, B
	RAL         ; shifts 1 index right
	JNC shift    ; and keep searching array
	SUB D
	JMP sortLoop

shift:	SUB D            ; shift array
	JNC shiftLoop    ; if not then adds back
	ADD D
	JMP shift
	
shiftLoop:	
	RAL         
	MOV E, A
	MVI A, 0FFH  
	XRA C
	MOV C, A     
	MOV A, E
	RAR
	RET


begin:
         MVI H, 21	; init H with 21
loop1:
	DCR H		; --H
	JZ print	        ; go to exit if H ==0
	MVI L, 200	; L = 200

loop2:	MVI A, RAND_INT	; A = rand()
        CALL GTU_OS	; Now we will call the OS to get random number
	
	MOV A, B        ; save rand number to A 
	PUSH H          ; save H L	
	LHLD ListIndex  
	XCHG            ; change HL DE
	STAX D          ; save A to list
	INX D
	XCHG            ; change HL DE
	SHLD ListIndex  ; save index
	POP H           ; pop HL back

	DCR L		; --L
	JZ loop1        ; if L == o go to loop1 
	JMP loop2       ; else go to loop2

      
print:	 MVI H, 21	; init H with 201
printLoop1:
	DCR H		; --H
	JZ exit	        ; go to exit if H ==0
	MVI L, 200	; L = 200

printLoop2:
 
	PUSH H          ; save H L	
	LHLD ListIndex  
	XCHG            ; change HL DE
	LDAX D          ; load number to A
	DCX D
	XCHG            ; change HL DE
	SHLD ListIndex  ; save index
	POP H           ; pop HL back

	MOV B, A        ; save number to b
	MVI A, PRINT_B
	CALL GTU_OS     ; print number

	DCR L		; --L
	JZ printLoop1        ; if L == o go to loop1 
	JMP printLoop2       ; else go to loop2

	
exit:	MVI A, PROCESS_EXIT
	call GTU_OS



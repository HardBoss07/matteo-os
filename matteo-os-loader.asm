    name "loader"
    
; directive to create boot file:
    #make_boot#
    
; boot record loaded at 0000:7c00
ORG 7c00h

; initialize the stack
MOV AX, 07c0h
MOV SS, AX
MOV SP, 03feh

; set data segment
XOR AX, AX
MOV DS, AX

; set default video mode 80x25
MOV AH, 00h
MOV AL, 03h
INT 10h

; print welcome msg
LEA SI, msg
CALL    PRINT_STRING

; load kernel at 0800h:0000h
MOV AH, 02h
MOV AL, 10
MOV CH, 0
MOV CL, 2
MOV DH, 0

MOV BX, 0800h
MOV ES, BX
MOV BX, 0

INT 13h

; integrity check:
CMP     ES:[0000],0E9h
JE      integrity_check_ok

; integrity check error:
LEA     SI, err
CALL    PRINT_STRING

; wait for any input
MOV AH, 0
INT 16h 

; store magic value at 0040h:0072h:
; 0000h = cold boot, 1234h = warm boot
MOV AX, 0040h
MOV DS, AX
MOV W.[0072h], 0000h
JMP 0ffffh:8000h

integrity_check_ok:
    JMP 0800h:0000h
    
; helper method
PRINT_STRING PROC near
    PUSH    AX
    PUSH    SI
    next_char:
            MOV AL, [SI]
            CMP AL, 0
            JZ  printed
            INC SI
            MOV AH, 0eh
            INT 10h
            JMP next_char
    printed:
            POP SI
            POP AX
            RET
PRINT_STRING ENDP

; data section
msg DB "Loading OS...", 0Dh, 0Ah, 0

err DB "invalid data at sector: 2, cylinder: 0, head: 0 - integrity check failed.", 0Dh, 0Ah
    DB "refer to instruction (tut11).", 0Dh, 0Ah
    DB "System will reboot now. Press any key...", 0
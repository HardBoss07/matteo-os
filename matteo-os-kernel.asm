    name "kernel"
    
; make bin
#make_bin#

; load location
#load_segment=0800#
#load_offset=0000#

; initialsation of registers
#AL=0b#
#AH=00#
#BH=00#
#BL=00#
#CH=00#
#DL=00#
#DS=0800#
#ES=0800#
#SI=7c02#
#DI=0000#
#BP=0000#
#CS=0800#
#IP=0000#
#SS=07c0#
#SP=03fe#

; advancing to current macro position
PUTC    MACRO   char
        PUSH    AX
        MOV     AL, char
        MOV     AH, 0eh
        INT     10h
        POP     AX
ENDM

; set current cursor position
GOTOXY  MACRO   col, row
        PUSH    AX
        PUSH    BX
        PUSH    DX
        MOV     AH, 02h
        MOV     DH, row
        MOV     DL, col
        MOV     BH, 0
        INT     10h
        POP     DX
        POP     BX
        POP     AX
ENDM

print MACRO x, y, attrib, sdat
LOCAL s_dcl, skip_dcl, s_dcl_end
    PUSHA
    MOV     DX, CS
    MOV     ES, DX
    MOV     AH, 13h
    MOV     AL, 1
    MOV     BH, 0
    MOV     BL, attrib
    MOV     CX, OFFSET s_dcl_end - OFFSET s_dcl
    MOV     DL, x
    MOV     DH, y
    MOV     BP, OFFSET s_dcl
    INT     10h
    POPA
    JMP skip_dcl
    s_dcl       DB sdat
    s_dcl_end   DB 0
    skip_dcl:
ENDM

; kernel loaded at 0800:0000 by matteo-os-loader
ORG 0000h

JMP START

; data section
msg DB "Welcome to Matteo-OS!", 0

cmd_size        EQU 10
command_buffer  DB  cmd_size DUP("2")
clean_str       DB  cmd_size DUP(" "), 0
promt           DB  ">", 0

; commands
c_help      DB  "help", 0
c_help_tail:
c_clear     DB  "clear", 0
c_clear_tail:

; start
START: 
    ; set data
    PUSH    CS
    POP     DS
    
    ; set screen size
    MOV AH, 00h
    MOV AL, 03h
    INT 10h
    
    ; disable blinking for compatibility
    MOV AX, 1003h
    MOV BX, 0
    INT 10h
    
    ; integrity check
    CMP [0000], 0E9h
    JZ  integrity_check_ok
    MOV AL, 'F'
    MOV AH, 0eh
    INT 10h
    
    ; wait for any key
    MOV AX, 0
    INT 16h
    
    ; reboot
    MOV AX, 0040h
    MOV DS, AX
    MOV W.[0072h], 0000h
    JMP offffh:0000h
    integrity_check_ok:
    NOP
    
    ; clear screen
    CALL CLEAR_SCREEN
   
    ; print message
    LEA SI, msg
    CALL PRINT_STRING
    
    eternal_loop:
        CALL GET_COMMAND PROC near
        CALL PROCESS_CMD
        
        JMP  eternal_loop
        
    ; OS Code
    GET_COMMAND PROC near
        MOV     AX, 40h
        MOV     ES, AX
        MOV     AL, ES:[84h]
        
        GOTOXY  0, AL
        
        ; clear cmd
        LEA     SI, CLEAN_STR
        CALL    PRINT_STRING
        
        ; show promt:
        LEA     SI, promt
        CALL    PRINT_STRING
        
        GOTOXY  0, AL
        
        ; wait for command
        MOV     DX, cmd_size
        LEA     DI, command_buffer
        CALL    GET_STRING
        
        ret
    GET_COMMAND ENDP
    
    ; check command
    PROCESS_CMD PROC near
        PUSH    DS
        POP     ES
        
        CLD
        
        ; compare command buffer with 'help'
        LEA     SI, command_buffer
        MOV     CX, c_help_tail - OFFSET c_help
        LEA     DI, c_help
        REPE    CMPSB
        JE      help_command
        
        ; compare command buffer with 'clear'
        LEA     SI, command_buffer
        MOV     CX, c_clear_tail - OFFSET c_clear
        LEA     DI, c_clear
        REPE    CMPSB
        JE      clear_command
        
        ; ignore empty lines
        CMP     command_buffer, 0
        JS      processed
        
        ; here, command is unkown
        MOV     AL, 1
        CALL    SCROLL_T_AREA
        
        ; set cursor
        MOV     AX, 40h
        MOV     ES, AX
        MOV     AL, ES:[84h]
        DEC     AL
        GOTOXY  0, AL
        
        LEA     SI, unknown
        CALL    PRINT_STRING
        
        LEA     SI, command_buffer
        CALL    PRINT_STRING
        
        MOV     AL, 1
        CALL    SCROLL_T_AREA
        
        JMP     processed
        
        ; 'help' command
        help_command:
            MOV     AL, 9
            CALL    SCROLL_T_AREA
        
            MOV     AX, 40h
            MOV     ES, AX
            MOV     AL, ES:[84h]
            SUB     AL, 9
            GOTOXY  0, AL
        
            ; printing help_msg
            LEA     SI, help_msg
            CALL    PRINT_STRING
        
            MOV     AL, 1
            CALL    SCROLL_T_AREA
        
            JMP     processed
        
        
        ; 'clear' command
        clear_command:
            CALL    CLEAR_SCREEN
            JMP     PROCESSED
        
        processed:
            RET
    PROCESS_CMD ENDP
    
    SCROLL_T_AREA PROC near
        MOV DX, 40h
        MOV ES, DX
        MOV AH, 06h
        MOV BH, 07
        MOV CH, 0
        MOV CL, 0
        MOV DI, 84h
        MOV DH, ES:[DI]
        MOV DH
        MOV DI, 4ah
        MOV DL, ES:[DI]
        DEC DL
        INT 10h
        
        RET
    SCROLL:T:AREA ENDP
    
    GET_STRING PROC near
        PUSH    AX
        PUSH    CX
        PUSH    DI
        PUSH    DX
        
        MOV     CX, 0
        
        CMP     DX, 1
        JBE     empty_buffer
        
        DEC     DX
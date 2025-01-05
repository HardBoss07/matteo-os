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

; kernel loaded at 0800:0000 by matteo-os-loader (not made yet)
       
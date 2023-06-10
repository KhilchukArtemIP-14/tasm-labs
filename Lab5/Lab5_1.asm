PRINT_VALUE MACRO VALUE
    LOCAL m1,m2,m3
    ;making a new line
    MOV DL, 13   
    MOV AH, 02h  
    INT 21h

    MOV DL, 10   
    MOV AH, 02h 
    INT 21h

    MOV bx, VALUE
    or bx,bx 

    jns m1 
    mov al,'-' 
    int 29h 
    neg bx 
m1:
    mov ax,bx 
    xor cx,cx 
    mov bx,10 
m2:
    xor dx,dx 
    div bx 
    add dl,'0' 
    push dx 
    inc cx 
    test ax,ax 
    jnz m2 
m3:
    pop ax 
    int 29h 
    loop m3 
ENDM

STSEG SEGMENT PARA STACK 'STACK'
    DB 256 DUP ('STACK')
STSEG ENDS
DSEG SEGMENT PARA PUBLIC 'DATA'
    inmes DB 7, 0, 7 dup (0) ; variable to store the input number
    prompt DB 'Enter a number [-32734;32767] : $'
    number dw 0
    CR DB 13, '$'
    validation_failed DB 'Wrong input. Ending the execution...$'
DSEG ENDS
CSEG SEGMENT PARA PUBLIC 'CODE'
    EXTRN atoi : FAR
    
MAIN PROC FAR
    ASSUME CS:CSEG, DS:DSEG, SS:STSEG
    MOV AX, DSEG
    MOV DS, AX 

    call read_input
    call validate_input
    call inmes_chars_to_digits
    call inmes_digits_to_number
    call number_sub
    PRINT_VALUE number
    call stop_exec
    
MAIN ENDP

read_input proc

    ; display the prompt
    MOV DX, OFFSET prompt
    MOV AH, 9
    INT 21h
    
    ; read the input
    lea dx, inmes
    MOV ah, 0Ah
    int 21h
    ret

read_input endp


inmes_chars_to_digits PROC
    MOV CL, [inmes+1]
    LEA SI, inmes+2
    
    cmp byte ptr [si],2Dh 
    jne NO_MINUS
    sub CL,1
    inc si
NO_MINUS:
    FOR_LOOP:
    sub byte ptr [si],48
        inc si;
        LOOP FOR_LOOP
    ret
inmes_chars_to_digits ENDP


inmes_digits_to_number PROC

    LEA SI, inmes+2;
    
    mov ax,0
    mov cx,10
    cmp byte ptr[inmes+2], '-'
    jne FOR_LOOP2
    INC SI
FOR_LOOP2:
    MUL CX
    
    ADD AL, [SI]
    INC SI
    
    cmp byte ptr [si],13 
    jne FOR_LOOP2
    
    cmp byte ptr[inmes+2], '-'
    jne TO_NUMBER_END
    neg ax
TO_NUMBER_END:
    mov number,AX
    ret
inmes_digits_to_number ENDP

number_sub proc
    sub number,34
    ret
number_sub endp


stop_exec proc
    MOV AH, 4Ch   
    INT 21h      
stop_exec endp

validate_input proc

    MOV CL, [inmes+1]
    LEA SI, inmes+2
    
    cmp byte ptr [si],2Dh 
    jne FOR_LOOP_VALIDATION
    sub CL,1
    inc si
    
    FOR_LOOP_VALIDATION:
    
    cmp byte ptr [si],48
    JL VALIDATION_FAILURE
    cmp byte ptr [si],57
    JGE VALIDATION_FAILURE
    
    inc si;
    LOOP FOR_LOOP_VALIDATION   
    
    ret
VALIDATION_FAILURE:

    MOV DL, 13   
    MOV AH, 02h  
    INT 21h

    MOV DL, 10   
    MOV AH, 02h  
    INT 21h
    
    MOV DX, OFFSET validation_failed
    MOV AH, 9
    INT 21h
    
    call stop_exec
validate_input endp

CSEG ENDS

END MAIN


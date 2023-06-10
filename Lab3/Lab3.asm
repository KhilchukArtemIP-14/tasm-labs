STSEG SEGMENT PARA STACK 'STACK'
    DB 256 DUP ('STACK')
STSEG ENDS
DSEG SEGMENT PARA PUBLIC 'DATA'
    bufer DB 7, 0, 7 dup (0) 
    prompt DB 'Enter a number: $'
    validation_failed DB 13,10,'Wrong input. Ending the execution...$'
    result_zalishok db ' zalishok $'
    prompt_x db 'Please, enter x $'
    prompt_a db 13,10,'Please, enter a $'
    prompt_b db 13,10,'Please, enter b $'
    prompt_overflow db 13,10,'Overflow has occured! Ending program execution $'
    newline db  13,10,'$'
    a dw 0
    b dw 0
    x dw 0
    chiselnik dw 0
DSEG ENDS
CSEG SEGMENT PARA PUBLIC 'CODE'

MAIN PROC FAR
    ASSUME CS:CSEG, DS:DSEG, SS:STSEG
    MOV AX, DSEG
    MOV DS, AX 
    
    call input_values
    call calculate_function
    call print_result
    call stop_exec
MAIN ENDP

input_values proc

    MOV DX, offset prompt_x
    MOV AH, 9
    INT 21h
    
    call single_read_input
    mov x,AX

    MOV DX,offset prompt_a
    MOV AH, 9
    INT 21h
    
    call single_read_input
    mov a,AX
    
    MOV DX,offset prompt_b
    MOV AH, 9
    INT 21h
    
    call single_read_input
    mov b,AX
    
    ret
    
input_values endp

single_read_input proc
    
    ; read the input
    lea dx, bufer
    MOV ah, 10
    int 21h
    call validate_input
    call bufer_chars_to_digits
    call bufer_digits_to_number
    ret

single_read_input endp


bufer_chars_to_digits PROC
    MOV CL, [bufer+1]
    LEA SI, bufer+2
    
    cmp byte ptr [si],2Dh 
    jne NO_MINUS
    sub CL,1
    inc si
NO_MINUS:
    FOR_LOOP_TO_DIGITS:
        sub byte ptr [si],48
        inc si;
        LOOP FOR_LOOP_TO_DIGITS    ; decrement CX and jump to FOR_LOOP if CX is not zero
    ret
bufer_chars_to_digits ENDP


bufer_digits_to_number PROC
    LEA SI, bufer+2;
    mov ax,0
    mov cx,10
    cmp byte ptr[bufer+2], '-'
    jne FOR_LOOP_TO_NUMBERS
    INC SI
    FOR_LOOP_TO_NUMBERS:
        MUL CX
    
        ADD AL, [SI]
        INC SI
    
        cmp byte ptr [si],13 
        jne FOR_LOOP_TO_NUMBERS
        
    cmp byte ptr[bufer+2], '-'
    jne TO_NUMBER_END
    neg ax
TO_NUMBER_END:
    ret
bufer_digits_to_number ENDP


bx_result_print proc

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
ret
bx_result_print endp


stop_exec proc
    MOV AH, 4Ch   
    INT 21h       
stop_exec endp

validate_input proc

    MOV CL, [bufer+1]
    LEA SI, bufer+2
    
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

    MOV DX, OFFSET validation_failed
    MOV AH, 9
    INT 21h
    
    call stop_exec
validate_input endp

calculate_function proc

    cmp [x],0
    JE x_is_zero
    JS x_less_than_zero

    mov ax, x
    imul x
    JO func_overflow
    imul x
    JO func_overflow
    imul a
    JO func_overflow
    add ax,b
    JO func_overflow
    mov chiselnik, ax
    ret
x_is_zero:
    mov ax,a
    add ax,b
    JO func_overflow
    add ax,b
    JO func_overflow
    
    mov chiselnik, ax
    ret
x_less_than_zero:
    mov ax,a
    imul x
    jo func_overflow
    sub ax,b
    imul x
    jo func_overflow
    mov chiselnik, ax
    ret
func_overflow:
    MOV DX,offset prompt_overflow
    MOV AH, 9
    INT 21h
    
    call stop_exec
calculate_function endp

print_result proc
    MOV DX,offset newline
    MOV AH, 9
    INT 21h
    mov bx,chiselnik
    call bx_result_print
    cmp byte ptr [x], 0
    jg drobom
    ret
drobom:

    MOV DL, '/'
    MOV AH, 02h  
    INT 21h
    
    mov bx,x
    call bx_result_print
    
    MOV DL, '='   
    MOV AH, 02h 
    INT 21h
    
    mov dx,0
    mov ax,chiselnik
    div x
    mov bx,ax
    push dx
    call bx_result_print
    pop dx
    cmp dx,0
    je print_end
    push dx
    MOV DX,offset result_zalishok
    MOV AH, 9
    INT 21h
    pop bx
    call bx_result_print
print_end:
    ret
print_result endp

CSEG ENDS

END MAIN


FIND_SUM_OF_ARRAY MACRO ARRAY_REF,ARRAY_COUNT
    local sum_macro_end,finding_sum_loop,sum_overflow
    mov cx, ARRAY_COUNT
    mov di, ARRAY_REF
    mov ax,0
    mov bx,0
finding_sum_loop:
    mov al,byte ptr[di]
    cbw
    add bx,ax
    jo sum_overflow
    inc di
    loop finding_sum_loop
    JMP sum_macro_end
sum_overflow:
    MOV AH, 09h
    LEA DX, overflow_msg
    INT 21h
    call stop_exec
    sum_macro_end:
ENDM

STSEG SEGMENT PARA STACK 'STACK'
    DB 256 DUP ('STACK')
STSEG ENDS
DSEG SEGMENT PARA PUBLIC 'DATA'
    validation_failed DB 'Wrong input. Ending the execution...$'
    PROMPT_MSG DB 'Enter the size of the array: $'
    msg_ask_for_input DB 0Ah, 0Dh,'Enter the memebers of the array [-128;127]: $'
    msg1 DB 'Enter the size of the array: $'
    msg2 DB 0Ah, 0Dh,'Sum of all elements of array is:$'
    msg3 DB 0Ah, 0Dh, 'Maximum element of array is: $'
    msg4 DB 0Ah, 0Dh, 'The contents of the array before sort are:$'
    msg5 DB 0Ah, 0Dh, 'The contents of the array after sort are:$'
    overflow_msg DB 0Ah, 0Dh, 'Overflow has occured!Stopping the execution...$'
    msg6 DB 0Ah, 0Dh, 'Array dimension cant be zero or negative! Ending program execution...$'
    msg7 DB 0Ah, 0Dh, 'Array member value must be in range [-128;127]! Ending program execution...$'
    newline DB 0Dh, 0Ah,'$'
    bufer DB 7, 0, 7 dup (0) ; variable to store the input number
    ARRAY_SIZE DW ?
    my_array Dw ?
DSEG ENDS
CSEG SEGMENT PARA PUBLIC 'CODE'

MAIN PROC FAR
    ASSUME CS:CSEG, DS:DSEG, SS:STSEG
    MOV AX, DSEG
    MOV DS, AX ; set DS to point to DSEG
    
    call init_array
    
    FIND_SUM_OF_ARRAY my_array, ARRAY_SIZE
    MOV AH, 09h
    LEA DX, msg2
    INT 21h
    call print_bx_from_new_line
    
    call find_max
    MOV AH, 09h
    LEA DX, msg3
    INT 21h
    call print_bl_from_new_line
    
    MOV AH, 09h
    LEA DX, msg4
    INT 21h
    call print_array
    
    call bubble_sort
    MOV AH, 09h
    LEA DX, msg5
    INT 21h
    call print_array
    ; free the memory allocated for the array
    MOV AH, 49h  ; free memory function
    MOV BX, DI
    INT 21h

    MOV AH, 4Ch
    INT 21h
main endp

bubble_sort proc
    mov cx, array_size      
    dec cx                  

    outer_loop:
        mov si, my_array    
        mov dx, cx          
        inner_loop:
            mov al, [si]    
            cmp al, [si+1]  
            jle skip_swap   
            xchg al, [si+1] 
            mov [si], al
        skip_swap:
            inc si       
            dec dx          
            jnz inner_loop  
        loop outer_loop    
    ret
bubble_sort endp


find_max proc
    mov cx, array_size
    mov di,my_array
    mov bl,byte ptr [di]
    inc di
    dec cx
comparison_loop:
    cmp byte ptr [di],bl
    jl comparison_loop_end
    mov bl,byte ptr [di]
    comparison_loop_end:
    inc di
    loop comparison_loop
    ret
find_max endp

print_array proc    
    MOV AH, 09h
    LEA DX, newline
    INT 21h
    
    mov cx, array_size
    mov di,my_array
    mov bx,0
    printing_array_loop:
    push cx
    mov bl,byte ptr [di]
    call print_bl
    inc di
    mov dl, ' '        
    mov ah, 02h       
    int 21h
    pop cx
    loop printing_array_loop
    ret
print_array endp

init_array proc
    
    MOV AH, 09h
    LEA DX, msg1
    INT 21h

    call single_dimension_input
    MOV ARRAY_SIZE,AX
    
    
    MOV AH, 48h 
    MOV BX, ARRAY_SIZE 
    INT 21h
    MOV my_array, AX 
    
    LEA DX, msg_ask_for_input
    MOV AH, 09h
    INT 21h
    
    mov cx, array_size
    mov di,my_array
array_member_input_loop:
    MOV AH, 09h
    LEA DX, newline
    INT 21h
    push cx
    call single_value_input
    mov [di],AX
    pop cx
    inc di
    loop array_member_input_loop
    ret
init_array endp

single_value_input proc
    call single_read_input
    cmp ax,-129
    jle value_validation_error
    cmp ax,128
    jge value_validation_error
    ret
value_validation_error:
    mov ah,09h
    lea dx, msg7
    int 21h
    call stop_exec
single_value_input endp

single_dimension_input proc
    call single_read_input
    cmp ax,0
    jle dimension_validation_error
    ret
dimension_validation_error:
    mov ah,09h
    lea dx, msg6
    int 21h
    call stop_exec
single_dimension_input endp

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
    cmp byte ptr [si],58
    JGE VALIDATION_FAILURE
    
    inc si;
    LOOP FOR_LOOP_VALIDATION
    ret
VALIDATION_FAILURE:

    MOV DL, 13
    MOV AH, 02h
    INT 21h

    MOV DL, 10   ; Line Feed
    MOV AH, 02h
    INT 21h

    ; display the prompt
    MOV DX, OFFSET validation_failed
    MOV AH, 9
    INT 21h
    
    call stop_exec
validate_input endp
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
        LOOP FOR_LOOP_TO_DIGITS
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

stop_exec proc
    MOV AH, 4Ch   
    INT 21h       
stop_exec endp

print_bx proc
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
print_bx endp

print_bx_from_new_line proc
    MOV AH, 09h
    LEA DX, newline
    INT 21h
    call print_bx
    ret
print_bx_from_new_line endp

print_bl proc
    or bl,bl 
    jns m1_bl
    mov al,'-' 
    int 29h 
    neg bl 
m1_bl:
    mov ax,bx 
    xor cx,cx 
    mov bx,10 
m2_bl:
    xor dx,dx 
    div bx 
    add dl,'0' 
    push dx 
    inc cx 
    test ax,ax 
    jnz m2_bl
m3_bl:
    pop ax 
    int 29h 
    loop m3_bl
ret
print_bl endp
print_bl_from_new_line proc
    MOV AH, 09h
    LEA DX, newline
    INT 21h
    call print_bl
    ret
    print_bl_from_new_line endp
CSEG ENDS
END MAIN

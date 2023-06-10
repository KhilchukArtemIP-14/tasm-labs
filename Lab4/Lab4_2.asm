STSEG SEGMENT PARA STACK 'STACK'
    DB 256 DUP ('STACK')
STSEG ENDS
DSEG SEGMENT PARA PUBLIC 'DATA'
    validation_failed DB 'Wrong input. Ending the execution...$'
    PROMPT_MSG DB 'Enter the number of rows of the matrix: $'
    msg_ask_for_input DB 0Dh, 0Ah,'Enter the memebers of the matrix [-128;127]: $'
    msg1 DB 'Enter the count of rows of the matrix: $'
    msg2 DB 0Ah, 0Dh,'Enter the number of columns of the matrix: $'
    msg3 DB 0Ah, 0Dh, 'The contents of the matrix are:$'
    msg4 DB 0Ah, 0Dh, 'Enter the number to look for all occurences of:$'
    msg5 DB 0Ah, 0Dh, 'Search begins:$'
    msg6 DB 0Ah, 0Dh, 'Search has ended$'
    msg7 DB 0Ah, 0Dh, 'Matrix dimension cant be zero or negative! Ending program execution...$'
    msg8 DB 0Ah, 0Dh, 'Resulting matrix:$'
    msg9 DB 0Ah, 0Dh, 'Member value must be in range [-128;127]! Ending program execution...$'
    msg10 DB 0Ah, 0Dh, 'No occurences found!$'
    newline DB 0Dh, 0Ah,'$'
    row_count DW ?
    column_count dw ?
    total_size dw ?
    bufer DB 7, 0, 7 dup (0) ; variable to store the input number
    my_array Dw ?
    check_offset dw ?
    check_value db 1
    found_flag dw 0
DSEG ENDS
CSEG SEGMENT PARA PUBLIC 'CODE'

MAIN PROC FAR
    ASSUME CS:CSEG, DS:DSEG, SS:STSEG
    MOV AX, DSEG
    MOV DS, AX ; set DS to point to DSEG

    call init_matrix

    call print_matrix
    MOV AH, 09h
    LEA DX, msg4
    INT 21h
    
    call single_value_input
    mov check_value,al
    call find_all_occurences
    
    ; free the memory allocated for the array
    MOV AH, 49h  ; free memory function
    MOV BX, my_array
    INT 21h

    MOV AH, 4Ch
    INT 21h
main endp

find_all_occurences proc
    MOV AH, 09h
    LEA DX, msg5
    INT 21h
    
    mov check_offset,0
    mov cx, total_size
    mov si,my_array
occurences_search_loop:

    mov al,check_value
    cmp al,[si]
    jne occurences_search_loop_end
    push cx
    mov found_flag,1
    MOV AH, 09h
    LEA DX, newline
    INT 21h
    mov ax,check_offset
    mov dx,0
    div column_count
    call print_pair_ax_dx
    pop cx
occurences_search_loop_end: 
    inc si
    inc check_offset
    loop occurences_search_loop
    MOV AH, 09h
    LEA DX, msg6
    INT 21h
    cmp found_flag, 1
    je occurence_end
    MOV AH, 09h
    LEA DX, msg10
    INT 21h
occurence_end:
    ret
find_all_occurences endp

print_pair_ax_dx proc
    push dx
    push ax
    mov al,'(' ; ???? ????????, ?? ?????
    int 29h ; ????? '?????'
    pop bx
    call print_bx
    mov al,',' ; ???? ????????, ?? ?????
    int 29h ; ????? '?????'
    pop bx
    call print_bx
    mov al,')' ; ???? ????????, ?? ?????
    int 29h ; ????? '?????'
    ret
print_pair_ax_dx endp

print_matrix proc
    MOV AH, 09h
    LEA DX, msg8
    INT 21h
    mov di,my_array
    mov cx, row_count
print_rows_loop:
    MOV AH, 09h
    LEA DX, newline
    INT 21h
    mov ax, column_count
    push cx
    print_columns_row:
        push ax
        mov bl,byte ptr [di]
        call print_bl
        inc di
        mov dl, ' '        
        mov ah, 02h       
        int 21h
        pop ax
        dec ax
        jnz print_columns_row
    pop cx
    loop print_rows_loop
    ret
    print_matrix endp

init_matrix proc
    ; ask the user for the count of rows
    MOV AH, 09h
    LEA DX, msg1
    INT 21h
    call single_dimension_input
    MOV row_count,AX
    ; ask the user for the count of columns
    MOV AH, 09h
    LEA DX, msg2
    INT 21h
    
    call single_dimension_input
    MOV column_count,AX
    
    mul row_count
    mov total_size,ax
    
    
    MOV AH, 48h  
    MOV BX, total_size 
    INT 21h
    MOV my_array, AX 

    LEA DX, msg_ask_for_input
    MOV AH, 09h
    INT 21h
    
    mov cx, total_size
    mov di,my_array
matrix_member_input_loop:
    MOV AH, 09h
    LEA DX, newline
    INT 21h
    push cx
    call single_value_input
    mov [di],AX
    pop cx
    inc di
    loop matrix_member_input_loop
    ret
init_matrix endp

single_value_input proc
    call single_read_input
    cmp ax,-129
    jle value_validation_error
    cmp ax,128
    jge value_validation_error
    ret
value_validation_error:
    mov ah,09h
    lea dx, msg9
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
    lea dx, msg7
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
    ;NO_MINUS:
    FOR_LOOP_VALIDATION:
    
    cmp byte ptr [si],48
    JL VALIDATION_FAILURE
    cmp byte ptr [si],58
    JGE VALIDATION_FAILURE
    
    inc si;
    LOOP FOR_LOOP_VALIDATION    ; decrement CX and jump to FOR_LOOP if CX is not zero
    ret
VALIDATION_FAILURE:

    MOV DL, 13   ; Carriage Return
    MOV AH, 02h  ; Function code for printing character
    INT 21h

    MOV DL, 10   ; Line Feed
    MOV AH, 02h  ; Function code for printing character
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

stop_exec proc
    MOV AH, 4Ch   ; return to DOS function
    INT 21h       ; interrupt 21h
stop_exec endp

print_bx proc
    or bx,bx ; ???????? ??? ??? bx ?? ?????????? ???????? ? ?????????
    jns m1 ; ???? ?? ????????, ?? ??????? ?? ????? m1
    mov al,'-' ; ???? ????????, ?? ?????
    int 29h ; ????? '?????'
    neg bx ; ??????????? ? ??????? ????????
m1:
    mov ax,bx ; ??????????? ?????? ????? ? ??????? ??
    xor cx,cx ; ??????? ??????????
    mov bx,10 ; ????????? ????? 10 ? bx
m2:
    xor dx,dx ; ??????? ???????? dx
    div bx ; ??????? ?????? ????? ?? 10
    add dl,'0' ; ?? ??????? ??????? ??? ?0?
    push dx ; ???????????
    inc cx ; ?????????? ???????? ??????????
    test ax,ax ; ???????? ? ??? ax ?? ?????????? ???????? ? ????????? ZF
    jnz m2 ; ???? ?? ???? ?? ??????? ?? m2
m3:
    pop ax ; ???????? ???????? ? ????? ? ??????? ax
    int 29h ; ????? ?? ?????
    loop m3 ; ???? ???? cx ?? ???????? ???? ??????? ?? ????? m3
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
    mov al,bl
    cbw
    mov bx,ax
    call print_bx
    ret
print_bl endp

CSEG ENDS
END MAIN


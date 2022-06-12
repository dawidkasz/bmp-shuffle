    section .text
    global shuffleImage
    extern rand


;===============================================================
;shuffleImage: randomly shuffle image
;Arguments:
;   rdi - address of BMPInfo image descriptor
;   rsi - number of rows
;   rdx - number of columns

shuffleImage:
    push rbx
    push r12
    push r13
    push r14

    push rdi
    mov r12d, edx
    xor rax, rax

    xor rdx, rdx
    mov eax, [rdi+28]  ;eax = img_height
    div esi  ;img_height / rows (rect height in pixels)
    mov r13d, eax

    xor edx, edx
    mov eax, [rdi+24]  ;eax = img_width
    div r12d  ;img_width / cols (rect width in pixels)
    mov r14d, eax

    mov ebx, r12d
    imul ebx, esi  ;ecx = rows*cols

chooseRandomRectPair:  ;Fisher–Yates algorithm
    dec ebx

    call rand
    xor edx, edx
    mov ecx, ebx
    inc ecx
    div ecx
    mov ecx, edx  ;0 <= ecx < ebx
    mov eax, ecx

    xor edx, edx
    mov eax, ebx
    div r12d
    mov esi, eax  ;esi=y1
    mov edi, edx  ;edi=x1

    xor edx, edx
    mov eax, ecx
    div r12d
    mov ecx, eax  ;ecx=y2, edx=x2
    mov r8d, eax

    mov r8d, r14d  ;restore img width
    mov r9d, r13d  ;restore img height
    call swapRectangles

    cmp ebx, 0
    jg chooseRandomRectPair
end:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret


;===============================================================
;swapRectangles: Swap two rectangles in place
;Arguments:
;   edi - x1
;   esi - y1
;   edx - x2
;   ecx - y2
;   r8d - rect width
;   r9d - rect height
;   [rbp+16] - [address of BMPInfo image descriptor]
swapRectangles:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    imul edi, r8d  ;x1 (pixels)
    imul esi, r9d  ;y1 (pixels)

    imul edx, r8d  ;x2 (pixels)
    imul ecx, r9d  ;y2 (pixels)

    mov rbx, [rbp+16]
    mov ebx, [rbx+32] ;linebytes

    mov r12d, ebx
    lea eax, [r8d + 2*r8d]  ;eax=3*width (width in bytes)
    sub r12d, eax ;r12d = linebytes - 3*eax (rect width in bytes)

    xor r10, r10
    mov r10d, esi
    imul r10d, ebx  ;r10 = y1 * linebytes (1st rect ptr)

    xor r11, r11
    mov r11d, ecx
    imul r11d, ebx  ;r11 = y2 * linebytes (1st rect ptr)

    mov rbx, [rbp+16]
    mov rbx, [rbx+16]  ;imgData

    add r10, rbx  ;1st rect ptr += imgDataAddress
    add r11, rbx  ;2nd rect ptr += imgDataAddress

    xor rax, rax
    lea rax, [edi + 2*edi]
    add r10, rax  ;r10 += x1 offset in pixels

    xor rax, rax
    lea rax, [edx + 2*edx]
    add r11, rax  ;r11 += x2 offset in pixels

    mov edx, edi
    add edx, r8d  ;x2 + rect_width (dst col counter)

    mov ecx, esi
    add ecx, r9d  ;y2 + rect_height (dst row counter)

    mov r8d, edi  ;col counter
    mov r9d, esi  ;row counter

nextLine:
    mov r8d, edi
nextChar:
    mov al, [r10]  ;swap 1st byte
    mov bl, [r11]
    mov [r11], al
    mov [r10], bl

    mov al, [r10+1]  ;swap 2nd byte
    mov bl, [r11+1]
    mov [r11+1], al
    mov [r10+1], bl

    mov al, [r10+2]  ;swap 3rd byte
    mov bl, [r11+2]
    mov [r11+2], al
    mov [r10+2], bl

    add r10, 3
    add r11, 3

    inc r8d
    cmp r8d, edx
    jl nextChar

    add r10, r12
    add r11, r12

    inc r9d
    cmp r9d, ecx
    jl nextLine

    pop r12
    pop rbx
    pop rbp
    ret

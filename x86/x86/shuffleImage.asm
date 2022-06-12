    section .text
    global shuffleImage
    extern rand


;===============================================================
;shuffleImage: randomly shuffle image
;Arguments:
;   [ebp+8] - address of BMPInfo image descriptor
;   [ebp+12] - number of rows
;   [ebp+16] - number of columns

shuffleImage:
    push ebp
    mov ebp, esp
    push ebx
    push esi

    mov ecx, [ebp+8]
    push ecx  ;BMPInfo

    mov ebx, [ebp+12]
    mov esi, [ebp+16]

    xor edx, edx
    mov eax, [ecx+16]  ;eax = img_height
    div ebx
    push eax  ;img_height / rows (rect height in pixels)

    xor edx, edx
    mov eax, [ecx+12]  ;eax = img_width
    div esi
    push eax  ;img_width / cols (rect width in pixels)

    imul ebx, esi  ;ebx = rows*cols

chooseRandomRectPair:  ;Fisher–Yates algorithm
    dec ebx

    call rand
    xor edx, edx
    mov ecx, ebx
    inc ecx
    div ecx
    mov ecx, edx  ;0 <= ecx < ebx

    xor edx, edx
    mov eax, ecx
    div esi
    push eax  ;eax=y2
    push edx  ;edx=x2,

    xor edx, edx
    mov eax, ebx
    div esi
    push eax  ;eax=y1
    push edx  ;edx=x1,

    call swapRectangles
    add esp, 16

    cmp ebx, 0
    jg chooseRandomRectPair

    add esp, 12
fin_a:
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret


;===============================================================
;swapRectangles: Swap two rectangles in place
;Arguments:
;   [ebp+8] - x1
;   [ebp+12] - y1
;   [ebp+16] - x2
;   [ebp+20] - y2
;   [ebp+24] - rect width
;   [ebp+28] - rect height
;   [ebp+32] - address of BMPInfo image descriptor

swapRectangles:
    push ebp
    mov ebp, esp
    sub esp, 28
    push ebx
    push esi
    push edi

    mov edx, [ebp+8]
    imul edx, [ebp+24]
    mov [ebp-4], edx  ;x1 (pixels)

    mov edx, [ebp+12]
    imul edx, [ebp+28]
    mov [ebp-8], edx  ;y1 (pixels)

    mov edx, [ebp+16]
    imul edx, [ebp+24]
    mov [ebp-12], edx  ;x2 (pixels)

    mov edx, [ebp+20]
    imul edx, [ebp+28]
    mov [ebp-16], edx  ;y2 (pixels)

    mov ecx, [ebp+32]
    mov ebx, [ecx+20]  ;linebytes
    mov ecx, [ecx+8]  ;imgData address

    mov edx, ebx
    mov eax, [ebp+24]
    lea eax, [eax + 2*eax]  ;eax = 3*width (width in bytes)
    sub edx, eax  ;edx = linebytes - rect width in bytes

    mov esi, ebx
    imul esi, [ebp-8]
    add esi, ecx  ;1st rect ptr (y1 * linebytes + im_data_address)

    mov edi, ebx
    imul edi, [ebp-16]
    add edi, ecx  ;2nd rect ptr (y2 * linebytes + im_data_address)

    mov eax, [ebp-4]
    lea eax, [eax + 2*eax]
    add esi, eax  ;esi = 1st rect ptr (+= x1 offset in pixels)

    mov eax, [ebp-12]
    lea eax, [eax + 2*eax]
    add edi, eax  ;edi = 2nd rect ptr (+= x2 offset in pixels)

    mov eax, [ebp-4]
    add eax, [ebp+24]
    mov [ebp-20], eax  ;x1 + rect_width (dst col counter)

    mov eax, [ebp-8]
    add eax, [ebp+28]
    mov [ebp-24], eax  ;y1 + rect_height (dst row counter)

    mov eax, [ebp-8]
    mov [ebp-28], eax  ;save row counter

nextLine:
    mov ecx, [ebp-4]  ;restore col counter
nextChar:
    mov al, [esi]  ;swap 1st byte
    mov bl, [edi]
    mov [edi], al
    mov [esi], bl

    mov al, [esi+1]  ;swap 2nd byte
    mov bl, [edi+1]
    mov [edi+1], al
    mov [esi+1], bl

    mov al, [esi+2]  ;swap 3rd byte
    mov bl, [edi+2]
    mov [edi+2], al
    mov [esi+2], bl

    add esi, 3
    add edi, 3

    inc ecx
    cmp ecx, [ebp-20]
    jl nextChar

    add esi, edx
    add edi, edx

    mov eax, [ebp-28]
    inc eax
    mov [ebp-28], eax
    cmp eax, [ebp-24]
    jl nextLine

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

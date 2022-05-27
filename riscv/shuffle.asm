.eqv ImgInfo_fname	0
.eqv ImgInfo_hdrdat 	4
.eqv ImgInfo_imdat	8
.eqv ImgInfo_width	12
.eqv ImgInfo_height	16
.eqv ImgInfo_lbytes	20

.eqv MAX_IMG_SIZE 	230400	# 320 x 240 x 3 (pixels) 


.eqv BMPHeader_Size 	54
.eqv BMPHeader_width 	18
.eqv BMPHeader_height 	22


.eqv system_OpenFile	1024
.eqv system_ReadFile	63
.eqv system_WriteFile	64
.eqv system_CloseFile	57
.eqv system_Exit0	10
.eqv system_RandRange	42

	.data
imgInfo: 	.space	24  # img descriptor

	.align 2
dummy:		.space	2
bmpHeader:	.space	BMPHeader_Size

	.align 2
imgData: 	.space	MAX_IMG_SIZE

ifname:	.asciz "examples/test3/test3.bmp"  # input file name
ofname: .asciz "result.bmp"  # output file name

.eqv num_of_rows	3
.eqv num_of_columns	4

	.text
main:
	# fill img descriptor
	la 	a0, imgInfo 
	la 	t0, ifname
	sw 	t0, ImgInfo_fname(a0)
	la 	t0, bmpHeader
	sw 	t0, ImgInfo_hdrdat(a0)
	la 	t0, imgData
	sw 	t0, ImgInfo_imdat(a0)
	jal	read_bmp
	bnez 	a0, main_failure

	la	a0, imgInfo
	li	a1, num_of_rows
	li	a2, num_of_columns
	jal 	shuffle_image

	la 	a0, 	imgInfo
	la 	t0, 	ofname
	sw 	t0, 	ImgInfo_fname(a0)
	jal 	save_bmp

main_failure:
	li 	a7, system_Exit0
	ecall


#============================================================================
# read_bmp: reads the content of a bmp file into memory
# arguments:
#	a0 - address of image descriptor structure
#		input filename pointer, header and image buffers should be set
# return value: 
#	a0 - 0 if successful, error code in other cases
read_bmp:
	mv 	t0, a0  # preserve imgInfo structure pointer
	
# open file
	li 	a7, system_OpenFile
    	lw 	a0, ImgInfo_fname(t0)  # file name 
    	li 	a1, 0  # flags: 0-read file
    	ecall
	
	blt 	a0, zero, rb_error
	mv 	t1, a0	# save file handle for the future
	
# read header
	li 	a7, system_ReadFile
	lw 	a1, ImgInfo_hdrdat(t0)
	li 	a2, BMPHeader_Size
	ecall
	
# extract image information from header
	lw 	a0, BMPHeader_width(a1)
	sw 	a0, ImgInfo_width(t0)
	
	# compute line size in bytes - bmp line has to be multiple of 4
	add 	a2, a0, a0
	add 	a0, a2, a0  # pixelbytes = width * 3 
	addi 	a0, a0, 3
	srai 	a0, a0, 2
	slli 	a0, a0, 2  # linebytes = ((pixelbytes + 3) / 4 ) * 4
	sw 	a0, ImgInfo_lbytes(t0)
	
	lw 	a0, BMPHeader_height(a1)
	sw 	a0, ImgInfo_height(t0)

# read image data
	li 	a7, system_ReadFile
	mv 	a0, t1
	lw 	a1, ImgInfo_imdat(t0)
	li 	a2, MAX_IMG_SIZE
	ecall

# close file
	li 	a7, system_CloseFile
	mv 	a0, t1
    	ecall
	
	mv 	a0, zero
	ret
	
rb_error:
	li 	a0, 1  # error opening file	
	ret
	
	
# ============================================================================
# save_bmp: saves bmp file stored in memory to a file
# arguments:
#	a0 - address of ImgInfo structure containing description of the image`
# return value: 
#	a0 - zero if successful, error code in other cases

save_bmp:
	mv 	t0, a0	# preserve imgInfo structure pointer
	
# open file
	li 	a7, system_OpenFile
    	lw 	a0, ImgInfo_fname(t0)  #file name 
    	li 	a1, 1  # flags: 1-write file
    	ecall
	
	blt 	a0, zero, wb_error
	mv 	t1, a0  # save file handle for the future
	
# write header
	li 	a7, system_WriteFile
	lw 	a1, ImgInfo_hdrdat(t0)
	li 	a2, BMPHeader_Size
	ecall
	
# write image data
	li 	a7, system_WriteFile
	mv 	a0, t1
	# compute image size (linebytes * height)
	lw 	a2, ImgInfo_lbytes(t0)
	lw 	a1, ImgInfo_height(t0)
	mul 	a2, a2, a1
	lw 	a1, ImgInfo_imdat(t0)
	ecall

# close file
	li 	a7, system_CloseFile
	mv 	a0, t1
    	ecall
	
	mv 	a0, zero
	ret
	
wb_error:
	li 	a0, 2  # error writing file
	ret


# ============================================================================
# swap_rectangles: swap two rectangles in place
# arguments:
# 	a0 - address of ImgInfo image descriptor
#	a1 - 1st rect x
#	a2 - 1st rect y
#	a3 - 2nd rect x
#	a4 - 2nd rect y
#	a5 - rect width
#	a6 - rect height
# return value: none
swap_rectangles:
	mul 	a1, a1, a5  # pixels: (a1, a2) = (x1, y1), (a3, a4) = (x2, y2)
	mul	a2, a2, a6
	mul	a3, a3, a5
	mul	a4, a4, a6
	
	lw 	t2, ImgInfo_lbytes(a0)
	lw 	t3, ImgInfo_imdat(a0)
		
	add	t4, a5, a5  # t4 = 3*a5
	add	t4, t4, a5
	sub	t4, t2, t4  # t4 = linebytes - 3*a5 (rect width in bytes)
	
	mul	t0, t2, a2  # t0 = y1 * linebytes + im_data_address
	add	t0, t0, t3
	
	mul	t1, t2, a4  # t1 = y2 * linebytes + im_data_address
	add	t1, t1, t3
	
	mv	t5, a1  # save col counter
	
	add	t2, a1, a1  # t2 = 3*x1
	add	t2, t2, a1
	add	t0, t0, t2  # t0 += x1 offset (1st rect pointer)
	
	add	t3, a3, a3  # t3 = 3*x2
	add	t3, t3, a3
	add	t1, t1, t3  # t0 += x2 offset (2nd rect pointer)
	
	add	a5, a1, a5  # a5 = x1 + rect_width (dst col counter)
	add	a6, a2, a6  # a6 = y1 + rect_height (dst row counter)
	
next_line:
	mv	a1, t5  # restore col counter
next_char:	
	lbu	t2, (t0)  # swap 1st byte
	lbu	t3, (t1)
	sb	t2, (t1)
	sb	t3, (t0)
	
	lbu	t2, 1(t0)  # swap 2nd byte
	lbu	t3, 1(t1)
	sb	t2, 1(t1)
	sb	t3, 1(t0)
	
	lbu	t2, 2(t0)  # swap 3rd byte
	lbu	t3, 2(t1)
	sb	t2, 2(t1)
	sb	t3, 2(t0)
	
	addi	t0, t0, 3  # increment 1st rect ptr
	addi	t1, t1 3  # increment 2nd rect ptr
	
	addi	a1, a1, 1  # increment col counter
	bltu	a1, a5, next_char

	add	t0, t0, t4  # move ptrs to next lines in rectangles
	add	t1, t1, t4  # t0/t1 += linebytes - 3*a5 (rect width in bytes)

	addi	a2, a2, 1  # increment row counter
	bltu	a2, a6, next_line

	ret
	

# ============================================================================
# shuffle_image: randomly shuffle image
# arguments:
# 	a0 - address of ImgInfo image descriptor
#	a1 - number of rows
#	a2 - number of columns
# return value: none

shuffle_image:
	addi 	sp, sp, 4
	sw 	ra, (sp)

	mv	s0, a0
	mv	s1, a2
	
	lw 	t0, ImgInfo_width(a0)
	lw	t1, ImgInfo_height(a0)
	
	div	s2, t0, a2  # rect width in pixels
	div	s3, t1, a1  # rect height in pixels
	
	mul	s4, a1, a2  # number of swaps = rows*cols
	
	li	a7, system_RandRange
	
choose_random_rect_pair:  # Fisher–Yates algorithm
	addi	s4, s4, -1  

	mv	a1, zero  # random number in range <0, s4)
	addi	a1, s4, 1
	ecall
			
	divu	a2, s4, s1  # y1
	remu	a1, s4, s1  # x1
	
	divu	a4, a0, s1  # y2
	remu	a3, a0, s1  # x2
	
	mv	a0, s0
	mv	a5, s2
	mv	a6, s3
	jal 	swap_rectangles
	
	bgtz 	s4, choose_random_rect_pair	
	
shuffle_image_fin:	
	lw 	ra, (sp)
	addi	sp, sp, 4
	ret

%include	"stud_io.inc"
global	_start

section	.bss
snum		resb		10		; max:=2^32-1 (need 10 char to store)
n_1		resd		1		; first number
n_2		resd		1		; second number
op		resb		1		; expression operator

section	.text
_start:	

;;;;;;;;;;;;;;;;;;;;;;;;INPUT CYCLE 1;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		xor		ecx, ecx	; number := 0
		xor		esi, esi	; digit_count := 0
		mov 		ebx, 10		; base := 10
input1:		GETCHAR
		cmp		al, '0'
		jb		not_digit1	; if input character is not a digit
		cmp		al, '9'
		ja		not_digit1	; if input character is not a digit
		sub		al, '0'		; character -> digit
		mov		edi, eax	; save a digit
		mov		eax, ecx	; take a look at number
		xor		edx, edx	; clear qword part
		mul		ebx		; mul_number := number * 10
		jc		err_cr		; unsigned overflow
		add		eax, edi	; incr_number := mul_number + digit
		jc		err_cr		; unsigned overflow
		inc		esi		; increase digit counter
		mov		ecx, eax	; save updated number
		jmp		input1		; go to another cycle iteration
		; assume that the number will be stored at ECX register
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

not_digit1:	test		esi, esi	; if the digit count is equal zero
		jz		err_ndata	; 	then there is no input data
		mov		[n_1], ecx	; store the first number

		cmp		al, '-'		; if it is sub 
		jz		good_op		; 	then store it
		cmp		al, '+'		; if it is add
		jz		good_op		; 	then store it
		cmp		al, '*'		; if it is mul
		jz		good_op		; 	then store it
		cmp		al, '/'		; if it is div
		jz		good_op		;	then store it
		jmp		err_op		; if we don`t have this op then error
good_op:	mov		[op], al	; save operator for later use

;;;;;;;;;;;;;;;;;;;;;;;;INPUT CYCLE 2;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		xor		ecx, ecx	; number := 0
		xor		esi, esi	; digit_count := 0
		mov 		ebx, 10		; base := 10
input2:		GETCHAR
		cmp		al, '0'
		jb		not_digit2	; if input character is not a digit
		cmp		al, '9'
		ja		not_digit2	; if input character is not a digit
		sub		al, '0'		; character -> digit
		mov		edi, eax	; save a digit
		mov		eax, ecx	; take a look at number
		xor		edx, edx	; clear qword part
		mul		ebx		; mul_number := number * 10
		jc		err_cr		; unsigned overflow
		add		eax, edi	; incr_number := mul_number + digit
		jc		err_cr		; unsigned overflow
		inc		esi		; increase digit counter
		mov		ecx, eax	; save updated number
		jmp		input2		; go to another cycle iteration
		; assume that the number will be stored at ECX register
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

not_digit2: 	test		esi, esi	; if the digit count is equal zero
		jz		err_ndata	; 	then there is no input data
		mov		[n_2], ecx	; store the first number

		cmp		al, 0xff	; if it is end of file
		jz		good_end	; 	then expression ended good
		cmp		al, 10		; if it is end of line
		jz		good_end	; 	then expression ended good
		jmp		err_end		; if expression ended bad then error
good_end:	cmp		byte [op], '-'	
		jz		op_sub		; if op is minus then sub 
		cmp		byte [op], '+'	; if operator is plus then
		jz		op_add		; if op is plus then add
		cmp		byte [op], '*'	
		jz		op_mul		; if op is multiplication then mul

		mov		bl, al		; save last character in input
		mov		eax, [n_1]	; store first number
		xor		edx, edx	; clear register for mod result
		div		dword [n_2] 	; first number div by second number
		mov		ecx, eax	; take a look at the div result
		mov		al, bl		; take a look at last input character
		jmp		expr_q
op_sub:		mov		ecx, [n_1]	; store first number
		sub		ecx, [n_2]	; first number minus second number
		jc		err_cr		; if overflow then exit with error
		jmp		expr_q
op_add:		mov		ecx, [n_1]	; store first number
		add		ecx, [n_2]	; first number plus second number
		jc		err_cr		; if overflow then exit with error
		jmp		expr_q
op_mul:		mov		bl, al		; save last character in input
		mov		eax, [n_1]	; store first number
		xor		edx, edx	; clear the qword part 
		mul		dword [n_2] 	; first number mulitply second number
		mov		ecx, eax	; take a look at the result
		mov		al, bl		; take a look at last input character
		jc		err_cr		; if overflow then exit with error
expr_q:

;;;;;;;;;;;;;;;;;;;;;;;;OUTPUT CYCLE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		; assume that the number is in ECX register
		mov		ebx, 10		; base := 10
		xor		esi, esi	; digit count := 0
		std				; write number from the back
		mov		edi, snum+9 	; save  adress of last char in snum
output:		mov		eax, ecx	; take a look at number
		xor		edx, edx	; mod part := 0
		div		ebx		; number/base (find div and mod part)
		mov		ecx, eax	; save what left from number
		mov		eax, edx	; take a look at mod part
		add		al, '0'		; digit -> char
		stosb				; write the digit-char in snum
		inc 		esi		; increase count of digits
		test		ecx, ecx	; if ecx = 0 then ZF=1
		jnz		output		; if there is still digits left
		cld				; output the number from the front
		mov		ecx, esi	; take a look at digit count
		mov		esi, edi	; take a look at byte before the snum
		inc		esi		; take a look at first char of snum
						; at the start ecx always not equal 0
write:		lodsb				; read the digit-char from snum
		PUTCHAR		al		; write digit-char
		loop		write		; if for-loop is not finished
		PUTCHAR		10		; add the new line at the end
		FINISH		0		; the program executed correctly

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

err_cr:		cmp		al, 0xff	; if it was no input at all then
		jz		err_cr_q	; 	exit with error
		cmp		al, 10		; if end of the line then
		jz		err_cr_q	;	exit with error
err1_in_cl:	GETCHAR				; read all chars that still in stream
		cmp		al, 0xff	; if end of file than
		jz		err_cr_q	; 	exit with error
		cmp		al, 10		; if end of line than
		jz		err_cr_q 	; 	exit with error
		jmp		err1_in_cl  	; there are still characters in line
err_cr_q:	PRINT		"Error: unsigned overflow"
		PUTCHAR		10		; go to a new line
		FINISH		1		; error code one - unsigned overflow
err_ndata:	cmp		al, 0xff	; if it was no input at all then
		jz		err_ndt_q	; 	exit with error
		cmp		al, 10		; if end of the line then
		jz		err_ndt_q	;	exit with error
err2_in_cl:	GETCHAR				; read all chars that still in stream
		cmp		al, 0xff	; if end of file than
		jz		err_ndt_q	; 	exit with error
		cmp		al, 10		; if end of line than
		jz		err_ndt_q	; 	 exit with error
		jmp		err2_in_cl	; there are still characters in line
err_ndt_q:	PRINT		"Error: the input did not have number"
		PUTCHAR		10		; go to a new line
		FINISH		2		; error code two - no data inserted
err_op:		cmp		al, 0xff	; if there is no operator then
		jz		err_op_q	; 	exit with error
		cmp		al, 10		; if there is no operator then
		jz		err_op_q	; 	exit with error
err3_in_cl: 	GETCHAR				; read all chars that still in stream
		cmp		al, 0xff	; if end of file than
		jz		err_op_q 	; 	exit with error
		cmp		al, 10		; if end of line than
		jz		err_op_q	; 	exit with error
		jmp		err3_in_cl	; there are still characters in line
err_op_q:	PRINT		"Error: the input did not have +,-,*,/ operator"
		PUTCHAR		10		; go to a new line
		FINISH		3		; error code three - no op inserted
err_end:	GETCHAR				; read all chars that still in stream
		cmp		al, 0xff	; if end of file than
		jz		err_end_q	; 	exit with error
		cmp		al, 10		; if end of line than
		jz		err_end_q	; 	exit with error
		jmp		err_end		; there is still characters in stream
err_end_q:	PRINT		"Error: the expression ended not correctly"
		PUTCHAR		10		; go to a new line
		FINISH		4		; error code four - bad end of expr

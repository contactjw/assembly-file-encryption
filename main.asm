;Coded by John West on May 10, 2020
;This program will test out the functions library to show the user of number formatted output
;
;
;Include our external functions library functions
%include "./functions64.inc"
 
SECTION .data
	welcomePrompt	db	"Welcome to my 64 bit Program", 00h
	goodbyePrompt	db	"Program ending, have a great day!", 00h
	
	processPrompt	db	"Copying source file to destination file...please wait", 0ah, 0dh
					db	"I will repeat if the input file is rather large.", 00h
	getKeyPrompt	db	"Please enter a key for encrypting: ", 0h
	
	invalidArgsPrompt	db	"Enter two existing .txt file names as arguments, ie (./main file1.txt file2.txt)", 0h
	inFilePrompt		db	"There was an error opening your input file", 0h
	outFilePrompt		db	"There was an error opening your output file", 0h
	
	bytesEncryptedPrompt	db	"Number of bytes encrypted this loop: ", 0h
	totalBytesPrompt		db	"Total bytes encrypted to file: ", 0h
	
SECTION .bss
	;Start Data for dynamic allocation
	origMemory		resq	1				;What was the starting address of our dynamic memory
	currMemory		resq	1				;Current end of our program memory address
	encryptionData	resq    1				;Holds our address of encrypted data
	;End Data for dynamic allocation
	buffer			resb	0ffffh
		.len		equ		($-buffer)

	numArgs		resq	1					;Hold the number of args from command line
	pathFile	resq	1					;Hold the pathfile from command line
	inputFile	resq	1					;Hold the inputfile from command line
	outputFile	resq	1					;Hold the outputfile from command line
	
	outputFiled	resq	1					;OutputFile Descriptor variable
	inputFiled	resq	1					;InputFile Descriptor variable
	
		
	totalDataLength	resq 1					;Variable to hold bytes read this loop
	totalBytesRead	resq 1					;Variable to hold the total number of bytes read
		
	encryptionKey	resb 255				;Reserve memory for encryption key
		.len		equ ($-encryptionKey)	;Current address - address of user input.
	encryptKeyLength	resq 1				;We will store the length of the user input here
 
SECTION     .text
	global  _start
     
_start:
	nop
	
;-----------------------------------------------------------------------------------------------------------------------------------;
;		WELCOME PROMPT
;-----------------------------------------------------------------------------------------------------------------------------------;
	
	
	push	welcomePrompt
	call	PrintString
	call	Printendl
	call	Printendl
	
	
;-----------------------------------------------------------------------------------------------------------------------------------;
;		READ COMMAND LINE ARGUMENTS INTO VARIABLES
;-----------------------------------------------------------------------------------------------------------------------------------;
	
	
	;Get numArgs ([numArgs] CONTAINS THE VALUE 3)
	pop		rax
	mov		[numArgs], rax
	
	cmp		QWORD [numArgs], 3
	jne		invalidArgs
	
	
	;Get path address ([pathFile] contains the address to the string, pathfile contains a pointer to a pointer)
	pop		rax
	mov		[pathFile], rax
	
	;Get input file address ([inputFile] contains the address to the string, inputFile contains a pointer to a pointer)
	pop		rax
	mov		[inputFile], rax
	
	;Get output file address ([outputFile] contains the address to the string, outputFile contains a pointer to a pointer)
	pop		rax
	mov		[outputFile], rax
	
	
;-----------------------------------------------------------------------------------------------------------------------------------;
;		INPUT FILE PROCESSING
;-----------------------------------------------------------------------------------------------------------------------------------;
	
	
	;Open the input file for reading ---CORRECT
	mov		rax, 2
	mov		rdi, [inputFile]
	mov		rsi, 0h
	mov		rdx, 0h
	syscall
	cmp		rax, 0h				;If it did not open, quit
    jl		inFileError
	;rax will contain the file descriptor
	mov		[inputFiled], rax
	
	
;-----------------------------------------------------------------------------------------------------------------------------------;
;		OUTPUT FILE PROCESSING
;-----------------------------------------------------------------------------------------------------------------------------------;	
	
	
	;Open the output file	--- CORRECT BUT NEED TO CHECK IT ACTS WEIRD WHEN PRINTING NEW LINES
	mov		rax, 2				;THIS IS THE COMMAND TO OPEN AN EXISTING FILE.  THIS IS MY CHOICE INSTEAD OF CREATING A BRAND NEW FILE.  THIS HELPS VALIDATE FILE INPUT
	mov		rdi, [outputFile]
	mov		rsi, 1				;1 IS FOR WRITE ONLY
	mov		rdx, 777o
	syscall
	cmp		rax, 0h				;If eax < 0, file error
    jle		outFileError
	;rax will contain the file descriptor
	mov		[outputFiled], rax
	
	
;-----------------------------------------------------------------------------------------------------------------------------------;
;		GET ENCRYPTION KEY FROM USER
;-----------------------------------------------------------------------------------------------------------------------------------;	
	
	
	mov		rcx, encryptionKey.len					;Move full size of encryptionKey to rcx
	mov 	rsi, 0									;Zero out rsi
	
	Loop3:
		mov BYTE [encryptionKey + rsi], ''			;Clear out any previous data in encryptionKey
		inc rsi										;
	loop Loop3

	push 	getKeyPrompt							;Display getKeyPrompt and get user input
	call 	PrintString								;
	push 	encryptionKey							;
	push 	encryptionKey.len						;
	call 	ReadText								;
	dec 	rax										;Decrement rax to avoid using null terminator in the key
	mov 	[encryptKeyLength], rax					;Move size of input user entered to encryptionKey length
	
	
;-----------------------------------------------------------------------------------------------------------------------------------;
;		DYNAMIC MEMORY ALLOCATION 100% WORKING!!!!!!!
;-----------------------------------------------------------------------------------------------------------------------------------;


	;Begin allocating memory (Get the starting address of our new heap)
	mov		rdi, 0h
	mov		rax, 0ch
	syscall
	;rax will contain the starting memory address
	mov		[origMemory], rax			;The start of our dynamic memory
	mov		[currMemory], rax			;Current memory location
	mov		[encryptionData], rax		;Start of our encryptionData
	
	;Add 0ffffh bytes to our heap
	add		rax, 0ffffh
	mov		rdi, rax
	mov		rax, 0ch
	syscall
	;rax will contain the new heap end
	mov		[currMemory], rax


	;Fill our dynamic memory with the data
	mov	QWORD[totalDataLength], 0ffh
	mov	rcx, [totalDataLength]
	mov	rsi, 0
	
	continueLoop:
		
		;Read the input file into a variable
		mov		rax, 0
		mov		rdi, [inputFiled]
		mov		rsi, [encryptionData]			;We use this notation because encryptionData holds a literal address value
		mov		rdx, buffer.len					;The buffer.len is 0ffffh bytes long
		syscall
		;rax will contain the number of bytes read
		mov		[totalDataLength], rax
		add		[totalBytesRead], rax
		
	    push	QWORD[encryptionData]			;Push argument1 (address of data we are encrypting)
		push	QWORD[totalDataLength]			;Push argument2	(address of number of bytes we are encrypting this loop)
		push	encryptionKey					;Push argument3	(address of the encryption key input)
		push	QWORD[encryptKeyLength]			;Push argument4	(address of the length of the encryption key)
		call	EncryptMe						;Call EncryptMe function
		
		push	bytesEncryptedPrompt			;Display bytes encrypted this loop
		call	PrintString
		push	QWORD[totalDataLength]
		call	Print64bitNumDecimal
		call	Printendl

		;Output to the file  ---DONE
		mov		rdi, [outputFiled]
		mov		rax, 01h
		mov		rsi, [encryptionData]
		mov		rdx, QWORD[totalDataLength]
		syscall
		
		cmp		QWORD[totalDataLength], 0ffffh			;If the data length that was read is equal to 0ffffh, we have more data to read, so loop back
		je		continueLoop
	
	
	
;-----------------------------------------------------------------------------------------------------------------------------------;
;		CLOSE OUR FILES
;-----------------------------------------------------------------------------------------------------------------------------------;
	
	
	;Close the input file
	mov		rax, 03h
	mov		rdi, [inputFiled]
	syscall

	;Close the output file
	mov		rax, 03h
	mov		rdi, [outputFiled]
	syscall
	
	
	;Now display the total number of bytes read to the outputFile
	call	Printendl
	push	totalBytesPrompt
	call	PrintString
	push	QWORD[totalBytesRead]
	call	Print64bitNumDecimal
	
;-----------------------------------------------------------------------------------------------------------------------------------;
;		DEALLOCATE DYNAMIC MEMORY
;-----------------------------------------------------------------------------------------------------------------------------------;


	mov		rax, 0ch
	mov		rdi, [origMemory]
	syscall
	
	jmp		endProgram

;-----------------------------------------------------------------------------------------------------------------------------------;
;		ERROR PROMPTS
;-----------------------------------------------------------------------------------------------------------------------------------;

	;Wrong number of command line args label
	invalidArgs:
		call Printendl
		push invalidArgsPrompt
		call PrintString
		call Printendl
		jmp endProgram
	
	;Error opening input file label
	inFileError:				;Print error if input file did not open successfully
		call Printendl			;
		push inFilePrompt		;
		call PrintString		;
		call Printendl			;
		jmp	endProgram			;
		
	;Error opening output file label
	outFileError:				;Print error if output file did not open successfully
		call Printendl			;
		push outFilePrompt		;
		call PrintString		;
		call Printendl			;
		jmp endProgram			;


;-----------------------------------------------------------------------------------------------------------------------------------;
;		GOODBYE PROMPT
;-----------------------------------------------------------------------------------------------------------------------------------;


	endProgram:
	call	Printendl
	call	Printendl
	push	goodbyePrompt
	call	PrintString
	call	Printendl
	
	nop
;
;Setup the registers for exit and poke the kernel
;Exit: 
Exit:
	mov		rax, 60					;60 = system exit
	mov		rdi, 0					;0 = return code
	syscall							;Poke the kernel


;-----------------------------------------------------------------------------------------------------------------------------------;
;		ENCRYPT ME PROCEDURE
;-----------------------------------------------------------------------------------------------------------------------------------;


EncryptMe:
	push	rbp								;Constructing our Stack Frame
	mov		rbp, rsp						;
	
	call	Printendl
	push	processPrompt					;Display processing message
	call	PrintString						;
	call	Printendl
	
	mov		rax, 0h
	;Get our arguments into proper registers
	mov		rdx, [rbp + 24]					;(ENCRYPTION KEY) Move the starting address of the encryption key into rdx
	mov		r8,  [rbp + 40]					;(ENCRYPTEDDATA) Move the starting address of our data into r8
	
	mov		rcx, [rbp + 32]					;(LENGTH OF DATA)Move number of bytes we are encrypting into rcx
	mov 	rsi, 0							;Zero out rsi
	
	mov		rbx, [rbp + 16]					;(LENGTH OF ENCRYPT KEY)Move the length of the encryption key into rbx
	mov 	rdi, 0							;Zero out rdi
	
	cmp		rbx, 0							;This compare handles if the user enters a blank key
	je		goBack							;
	
	Loop4:
		mov	al, [rdx + rdi]					;Move the encryptionKey char into al ---Keep
		xor BYTE[r8 + rsi], al				;xor the first byte in encryptedData with the encryptionKey	---Keep
		inc rsi								;increment the encrypted string's index
		inc rdi								;increment the key's index
		cmp rbx, rdi						;compare the size of the key with the current index we're at in the string
		je restartKey						;if we're at the end of the key, jump to restartKey:
		jmp nextChar						;if we're not at the end of the key, jump to the next character
		restartKey:
			mov rdi, 0						;reset the index of the key, looping back around to the first char
		nextChar:
	loop Loop4
	
	goBack:									;This handles if the user enters a blank key
	
	mov		rsp, rbp						;Deconstruct our Stack Frame
	pop		rbp								;
ret	32										;Release the 4 variables from the stack


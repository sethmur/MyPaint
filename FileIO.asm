	;===================================================================================================================;
	;	Authors: Erik Olson, Nathan Hoffman, Ruvim Lashchuk, and Seth Murdoch											;	
	;	Date: 2017-12-02																								;
	;																													;
	;	This program takes "inFile.bmp" from its directory and manipulates the RGB values of each pixel in the image.	;
	;		The code isn't dynamic. We hardcoded it to only work with 24-bit bmp file types.							;
	;																													;
	;	Relevant links:																									;
	;		CreateFile:																									;
	;			https://msdn.microsoft.com/en-us/library/windows/desktop/aa363858(v=vs.85).aspx							;
	;		ReadFile:																									;
	;			https://msdn.microsoft.com/en-us/library/windows/desktop/aa365467(v=vs.85).aspx							;
	;		WriteFile:																									;
	;			https://msdn.microsoft.com/en-us/library/windows/desktop/aa365747(v=vs.85).aspx							;
	;		ExitProcess:																								;
	;			https://msdn.microsoft.com/en-us/library/windows/desktop/ms682658(v=vs.85).aspx							;
	;		BMP Format:																									;
	;			http://www.fastgraph.com/help/bmp_header_format.html													;
	;			https://upload.wikimedia.org/wikipedia/commons/c/c4/BMPfileFormat.png									;
	;			http://www.daubnet.com/en/file-format-bmp																;
	;===================================================================================================================;
	
	.486                                    ; create 32 bit code
    .model flat, stdcall                    ; 32 bit memory model
    option casemap :none                    ; case sensitive
 
    include \masm32\include\windows.inc     ; Settup for libraries and includes
    include \masm32\macros\macros.asm       ; MASM support macros

	include \masm32\include\masm32.inc
    include \masm32\include\gdi32.inc
    include \masm32\include\user32.inc
    include \masm32\include\kernel32.inc	; Responsible for windows api
	
	includelib \masm32\lib\masm32.lib
    includelib \masm32\lib\gdi32.lib
    includelib \masm32\lib\user32.lib
    includelib \masm32\lib\kernel32.lib


	;=======================================================================================;
	;		Handling 24bit bmp files														;
	;		Header: 54 bytes																;
	;		Padding: Each row is padded to be a multiple of 4 bytes. Range = 0 to 3 bytes.	;
	;=======================================================================================;

    .data
    	
		hFile				DWORD	?				; holds handle for in file
		hFileOut			DWORD	?				; holds handle for out file
		
		inFile				BYTE	"inFile.bmp", 0
		outFile				BYTE	"outFile.bmp", 0

		readBytes			DWORD	?				; stores how many bytes were read from file
		
		; Temporarily chaning byte value to 3126 BYTEs for 32 x 32 resolution to make debugging more efficient.  
		pixelArray			BYTE	3126 DUP (?)	; Imposing a resolution limit of 1920 x 1080.  6220800 = 1920*1080*3
		pixelArray_Size		DWORD	?				; Dynamic element.  Parsed from bmp header.
		iPixel				BYTE	?, ?, ?			; Individial BRG pixel that will be scaled and stored. Short for "Individual Pixel".
		
		bmpHeader			BYTE	54 DUP (?)		; Standard bmp file header size
		bmpHeader_Size		DWORD	54				; To bypass image header
		
		xPixels				DWORD	?				; Offset of 18 bytes
		yPixels				DWORD	?				; Offset of 22 bytes
		padBytes			DWORD	?				; xPixels % 4
		
		index				DWORD	?				; = (row * xPixel + column) * 3 + row * padding
<<<<<<< master
=======
		sPixel				BYTE	?, ?, ?			; Individial BRG pixel that will be scaled and stored
>>>>>>> master

    .code                       ; Tell MASM where the code starts

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

start:                          ; The CODE entry point to the program

    call main                   ; branch to the "main" procedure

    exit

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

main proc
	xor		eax, eax
	xor		ebx, ebx
	xor		ecx, ecx
	xor		edx, edx


<<<<<<< master
	;=======================================================================;
	;		Using CreateFile to get File handle for our output file			;	
	;=======================================================================;
=======
	;===================================================================;
	;		Using CreateFile to get File handle for our output file		;	
	;===================================================================;
>>>>>>> master
    ; CreateFile(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile)
	invoke	CreateFile, offset outFile, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	mov		hFileOut, EAX	; Move file handle from common register for file to output image



	;===============================================================================;
	;		Using CreateFile to get File handle for the file we will be reading		;
	;===============================================================================;
	; CreateFile(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile)
	invoke	CreateFile, offset inFile, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_READONLY, 0
	mov		hFile, EAX		; Move file handle from common register for file to read image



<<<<<<< master
	;===================================================================================================================;
	;		Reading file data.																							;
	;			Step 1:	parsing file header for file information														;
	;			step 2:	reading the rest of the information separately to store only the pixel content in pixelArray.	;
	;					See fastgraph.com/help/bmp_header_format.html													;
	;===================================================================================================================;
=======
	;===============================================================================================================;
	;  Reading file data.																							;
	;		Step 1:	parsing file header for file information														;
	;		step 2:	reading the rest of the information separately to store only the pixel content in pixelArray.	;
	;				See fastgraph.com/help/bmp_header_format.html													;
	;===============================================================================================================;
>>>>>>> master
	; ReadFile(hFile, lpBuffer, nNumberOfBytesToRead, lpNumberOfBytesToRead, lpOverlapped)
	invoke	ReadFile, hFile, offset bmpHeader, bmpHeader_Size, readBytes, 0
	

	; DWORD PTR call isn't formatted properly.  Should be DWORD PTR bmpHeader[#], but I want to read up on this.  See chapter 5 for more info.
	; DWORD because the width value is stored in four bytes
	; Hexadecimal representation in memory
	mov		eax, DWORD PTR bmpHeader[22]	; +22 corresponds to height in pixels			
	mov		yPixels, eax					; Moving double word in eax into yPixels
	
	mov		eax, DWORD PTR bmpHeader[18]	; +18 corresponds to width in pixels
	mov		xPixels, eax					; Moving double word in eax into yPixels


	; Finding padding of the rows
	xor		edx, edx						; Clearing EDX register to prevent overflow and undesired data.
	; eax currently holds xPixels
	mov		ebx, 4				
	div		ebx								; divide eax(xPixels) by 4	; Integer overflow
	mov		padBytes, edx					; edx holds remainder

	mov		edx, DWORD PTR [bmpHeader + 2]	; +2 corresponds to file size
	sub		edx, bmpHeader_Size				
	mov		pixelArray_Size, edx			; we are only consider the pixel space as file size
    

	; Reading the rest of the file
	; ReadFile(hFile, lpBuffer, nNumberOfBytesToRead, lpNumberOfBytesToRead, lpOverlapped)
	invoke	ReadFile, hFile, offset pixelArray, pixelArray_Size, readBytes, 0
<<<<<<< master



	;===================================================================================;
	;		Writing bmp header to file.  The header's information is preserved.			;
	;				The program only manipulates pixel information.						;
	;===================================================================================;
	; WriteFile(hFile, lpBuffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, lpOverlapped)
	invoke WriteFile, hFileOut, offset bmpHeader, 54, offset hFileOut, 0
	; cmp		eax, 0
	; jz		endRowLoop						; WriteFile returns true for success.  If it fails here there is no reason to continue.
=======
>>>>>>> master



	;===================================================================================;
	;		Looping through the Pixel Array space and manipulating every RGB pixel.		;
	;===================================================================================;
<<<<<<< master
	xor		edx, edx						; RowCounter: Initialiaze to 0
											; Range: 0 to (yPixels - 1)			= Rows
=======
	mov		edx, yPixels					; Count of rows 
	dec		yPixels							; Range is 0 to yPixel - 1
>>>>>>> master


	; RowLoop isn't necessary, but it makes the process more intuitive for an image.  
	; If we wanted to optimize the program we would do away with RowLoop, and have the entire algorithm iterate pixel by pixel
RowLoop:
	xor		ecx, ecx						; ColumnCounter,: Initialize to 0
											; Domain: 0 to xPixel - 1			= Columns

ColumnLoop:
	;=======================================================================================================================;
	;							The file contains bmpHeader at byte position 0 through 53 									;
	;		Index = ( Pixel.Row * Row.Width + Pixel.Column ) * Pixel.Size + Pixel.Row * Row.Padding + bmpHeader_Size		;
	;=======================================================================================================================;
	xor		eax, eax						; Initialize Registers to clear old data
	xor		ebx, ebx
	
	mov		eax, edx						; row
	mul		xPixels							; row * xPixels
	add		eax, ecx						; row * xPixels + ecx
<<<<<<< master
	imul	eax, 3							; (row * xPixels + ecx) * 3			; In 24-bit bmp: Pixel.Size = 3
	mov		ebx, padBytes					; padBytes
	imul	ebx, edx						; padBytes * edx
	add		ebx, bmpHeader_Size-1			; padBytes * edx + 53

	; Complete Index
	add		eax, ebx						; [(row * xPixels + ecx) * 3] + [padBytes * edx + 53]
	mov		index, eax


	;===========================================================;
	;			Retrieving the bit RGB24 values					;
	;				3 Bytes: Red, Green Blue					;
	;		pixelArray starts at bottom left of the image		;
	;	  In sets of three bytes, the color order is: BRG		;
	;===========================================================;
=======
	imul	eax, 3							; (row * xPixels + ecx) * 3
	mov		index, eax						
	mov		eax, padBytes					; padBytes
	imul	eax, edx						; padBytes * edx
	add		index, eax						; (row * xPixels + ecx) * 3 + padBytes * edx

	;===================================================;
	;		Retrieving the bit RGB24 values				;
	;			3 Bytes: Red, Green Blue				;
	;	pixelArray starts at bottom left of the image	;
	;  In sets of three bytes, the color order is: BRG	;
	;				Not operational						;
	;===================================================;
>>>>>>> master
	lea		eax, pixelArray					; load effective address of pixelArray					
	add		eax, index						; move to address of the pixel of interest
	lea		ebx, sPixel

<<<<<<< master
	; Instruction operands must be the same size so we're using lower registers
	mov		bl, BYTE PTR [eax]				; Moving Blue value to ebx		
	mov		iPixel, bl

	mov		bl, BYTE PTR [eax + 1]			; Moving Green value to ebx
	mov		iPixel[1], bl

	mov		bl, BYTE PTR [eax + 2]			; Moving Red value to ebx
	mov		iPixel[2], bl


	;=======================================;
	;		Saving pixel to memory			;
	;			Not operational(?)			;
=======
	; mozx pads unused memory with zeros. We are using 32 bit registers and storing 8-bit values. Not operational
	mov		ebx, BYTE PTR [eax]				; Moving Blue value to ebx		
	mov		sPixel, ebx

	mov		ebx, BYTE PTR [eax + 1]			; Moving Green value to ebx

	mov		ebx, BYTE PTR [eax + 2]			; Moving Red value to ebx
	

	;=======================================;
	;		Saving pixel to memory			;
	;			Not operational				;
>>>>>>> master
	;=======================================;
	mov		eax, offset hFileOut
	add		eax, index
	; WriteFile(hFile, lpBuffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, lpOverlapped)
	invoke WriteFile, hFileOut, offset iPixel, 3, eax, 0

	; increment ColumnCounter
	inc		ecx
	cmp		ecx, xPixels
	jge		ColumnLoop
endColumnLoop:

<<<<<<< master
	inc		edx
	cmp		edx, yPixels
=======
	; Not operational
	; write 13 to file,		0D or 13 is carriage return
	; write 10 to file,		0A or 10 is line feed

	dec		edx
	cmp		edx, 0
>>>>>>> master
	jge		RowLoop

endRowLoop:
	
	mov eax, 0
	invoke ExitProcess, 0
	
	ret
main endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

end start                       ; Tell MASM where the program ends
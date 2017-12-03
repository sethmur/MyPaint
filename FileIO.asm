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


	;===================================================================================;
	;	Handling 24bit bmp files														;
	;	Header: 54 bytes																;
	;	Padding: Each row is padded to be a multiple of 4 bytes. Range = 0 to 3 bytes.	;
	;===================================================================================;

    .data
    	
		hFile				DWORD	?				; holds handle for in file
		hFileOut			DWORD	?				; holds handle for out file
		
		inFile				BYTE	"inFile.bmp", 0
		outFile				BYTE	"outFile.bmp", 0

		readBytes			DWORD	?				; stores how many bytes were read from file
		pixelArray			BYTE	100000 DUP (?)
		pixelArray_Size		DWORD	?
		bmpHeader			BYTE	54 DUP (?)		; Standard bmp file header size
		bmpHeader_Size		DWORD	54				; To bypass image header
		xPixels				DWORD	?				; Offset of 18 bytes
		yPixels				DWORD	?				; Offset of 22 bytes
		padBytes			DWORD	?				; xPixels % 4
		index				DWORD	?				; = (row * xPixel + column) * 3 + row * padding
		sPixel				BYTE	?, ?, ?			; Individial BRG pixel that will be scaled and stored

    .code                       ; Tell MASM where the code starts

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

start:                          ; The CODE entry point to the program

    call main                   ; branch to the "main" procedure

    exit

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

main proc
	xor		eax, eax
	xor		ebx, ebx
	xor		ecx, ecx
	xor		edx, edx


	;===================================================================;
	;		Using CreateFile to get File handle for our output file		;	
	;===================================================================;
    ; CreateFile(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile)
	invoke	CreateFile, offset outFile, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	mov		hFileOut, EAX	; Move file handle from common register for file to output image



	;===============================================================================;
	;		Using CreateFile to get File handle for the file we will be reading		;
	;===============================================================================;
	; CreateFile(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile)
	invoke	CreateFile, offset inFile, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_READONLY, 0
	mov		hFile, EAX		; Move file handle from common register for file to read image



	;===============================================================================================================;
	;  Reading file data.																							;
	;		Step 1:	parsing file header for file information														;
	;		step 2:	reading the rest of the information separately to store only the pixel content in pixelArray.	;
	;				See fastgraph.com/help/bmp_header_format.html													;
	;===============================================================================================================;
	; ReadFile(hFile, lpBuffer, nNumberOfBytesToRead, lpNumberOfBytesToRead, lpOverlapped)
	invoke	ReadFile, hFile, offset bmpHeader, bmpHeader_Size, readBytes, 0
	

	; DWORD PTR call isn't formatted properly.  Should be DWORD PTR bmpHeader[#], but I want to read up on this.  See chapter 5 for more info.
	; DWORD because the width value is stored in four bytes
	mov		edx, DWORD PTR [bmpHeader + 18]	; +18 corresponds to width in pixels
	mov		xPixels, edx					

	mov		edx, DWORD PTR [bmpHeader + 22]	; +22 corresponds to height in pixels
	mov		yPixels, edx										

	; Finding padding of the rows
	; xor edx, edx  Might need this
	mov		eax, xPixels					
	mov		ebx, 4
	div		ebx								; divide eax(xPixels) by 4
	mov		padBytes, edx					; edx holds remainder

	mov		edx, DWORD PTR [bmpHeader + 2]	; +2 corresponds to file size
	sub		edx, bmpHeader_Size				
	mov		pixelArray_Size, edx			; we are only consider the pixel space as file size
    

	; Reading the rest of the file
	; ReadFile(hFile, lpBuffer, nNumberOfBytesToRead, lpNumberOfBytesToRead, lpOverlapped)
	invoke	ReadFile, hFile, offset pixelArray, pixelArray_Size, readBytes, 0



	;===================================================================================;
	;		Looping through the Pixel Array space and manipulating every RGB pixel.		;
	;===================================================================================;
	mov		edx, yPixels					; Count of rows 
	dec		yPixels							; Range is 0 to yPixel - 1


RowLoop:
	xor		ecx, ecx						; Count of Columns, starting at 0 for every iteration of our outer loop

ColumnLoop:
	; Calculating the offset from buffer
	mov		eax, edx						; row
	mul		xPixels							; row * xPixels
	add		eax, ecx						; row * xPixels + ecx
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
	lea		eax, pixelArray					; load effective address of pixelArray					
	add		eax, index						; move to address of the pixel of interest
	lea		ebx, sPixel

	; mozx pads unused memory with zeros. We are using 32 bit registers and storing 8-bit values. Not operational
	mov		ebx, BYTE PTR [eax]				; Moving Blue value to ebx		
	mov		sPixel, ebx

	mov		ebx, BYTE PTR [eax + 1]			; Moving Green value to ebx

	mov		ebx, BYTE PTR [eax + 2]			; Moving Red value to ebx
	

	;=======================================;
	;		Saving pixel to memory			;
	;			Not operational				;
	;=======================================;
	mov		eax, offset hFileOut
	add		eax, index
	; WriteFile(hFile, lpBuffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, lpOverlapped)
	invoke WriteFile, hFileOut, offset sPixel, 3, eax, 0

	; increment oute
	inc		ecx
	cmp		ecx, xPixels
	jl		ColumnLoop
endColumnLoop:

	; Not operational
	; write 13 to file,		0D or 13 is carriage return
	; write 10 to file,		0A or 10 is line feed

	dec		edx
	cmp		edx, 0
	jge		RowLoop

endRowLoop:
	
	mov eax, 0
	invoke ExitProcess, 0
	
	ret
main endp

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

end start                       ; Tell MASM where the program ends

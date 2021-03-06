;Nathan Hoffman	- Product Lead
;Ruvim Lashchuk	- File I/O
;Erik Olson		- Pixel FX
;Seth Murdoch	- Paint Cursor
;CISP 310



.586
.model flat, stdcall
option casemap :none

													;Includes
;INCLUDE io.h										;User I/O tools

include \masm32\include\windows.inc					;Needed to install
include \masm32\include\user32.inc					;Windows tools
include \masm32\include\kernel32.inc 
includelib \masm32\lib\user32.lib 
includelib \masm32\lib\kernel32.lib 

include \masm32\include\gdi32.inc					;Drawing tools
includelib \masm32\lib\gdi32.lib


WinMainCRTStartup proto
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD						;procedure prototypes
getCoord proto :LPARAM
setColor proto


.stack 4096

.data?
hInstance HINSTANCE ?											;handler
CommandLine LPSTR ?												
hitpoint POINT <>												;mouse location
string Word 3 DUP (?)




.data
AppName  db "MyPaint",0											;window name
ClassName db "SimpleWinClass",0									
LeftMouseClick db 0												;0=no click yet
RightMouseClick db 0
eraseColor DWORD 00FFFFFFh										;Sets erase color to white
penColor DWORD 0												;Color of pen intitated as black

redPrompt BYTE "Enter the red value (0-255):",0					;Prompts for changing pen color
greenPrompt	BYTE "Enter the green value (0-255):",0
bluePrompt BYTE "Enter the blue value (0-255):",0


fileName BYTE "snowmen.bmp",0

.code
WinMainCRTStartup PROC												;Setup
	invoke GetModuleHandle, NULL									;places module handle into eax
    mov    hInstance,eax											
    invoke GetCommandLine											
    mov CommandLine,eax												
    invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT		;window
    invoke ExitProcess,eax
WinMainCRTStartup ENDP

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD 
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND													;Local variable declarations

    mov   wc.cbSize,SIZEOF WNDCLASSEX								;Default window size
    mov   wc.style, CS_HREDRAW or CS_VREDRAW						;Sets window to redraw when moved
    mov   wc.lpfnWndProc, OFFSET WndProc							;Defines window's procedure
    mov   wc.cbClsExtra,NULL										;Extra bytes for
    mov   wc.cbWndExtra,NULL										;Extra bytes for window
    push  hInst														;window handle
    pop   wc.hInstance												
    mov   wc.hbrBackground,COLOR_WINDOW+1							;Background color
    mov   wc.lpszMenuName,NULL										;No menu
    mov   wc.lpszClassName,OFFSET ClassName							
    invoke LoadIcon,NULL,IDI_APPLICATION							;Window icon
    mov   wc.hIcon,eax												
    mov   wc.hIconSm,eax											
    invoke LoadCursor,NULL,IDC_ARROW								;Cursor symbol while in window
    mov   wc.hCursor,eax											
    invoke RegisterClassEx, addr wc									
    invoke CreateWindowEx,NULL,ADDR ClassName,ADDR AppName,\		;Creates window
           WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\ 
           CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,NULL,NULL,\ 
           hInst,NULL 
    mov   hwnd,eax													
    invoke ShowWindow, hwnd,SW_SHOWNORMAL							;Displays Window
    invoke UpdateWindow, hwnd										
    .WHILE TRUE														;loop changes message
                invoke GetMessage, ADDR msg,NULL,0,0				;gets message						(https://msdn.microsoft.com/en-us/library/windows/desktop/ms644936(v=vs.85).aspx)
                .BREAK .IF (!eax) 
                invoke DispatchMessage, ADDR msg					;sends message
    .ENDW 
    mov     eax,msg.wParam 
    ret 
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 

    .IF uMsg==WM_DESTROY											;x button
        invoke PostQuitMessage,NULL									;Closes Window

    .ELSEIF uMsg==WM_LBUTTONDOWN									;mouse click

		invoke getCoord, lParam										;Gets mouse coordinates
        mov LeftMouseClick, TRUE									;Left mouse down flag
		;invoke MoveToEx, hdc, hitpoint.x, hitpoint.y, NULL			;Moves drawing marker
        ;invoke InvalidateRect,hWnd,NULL,FALSE				;Prepares area for editing(Dont need. interesting if you want to mess up other windows)
															;hWnd:this window	Null:whole window	False:doesn't clear area first

	.ELSEIF uMsg==WM_RBUTTONDOWN
		invoke getCoord, lParam
		mov RightMouseClick, TRUE

    .ELSEIF uMsg==WM_PAINT											;WM_Paint sends when some area is invalidated
		invoke GetDC, hWnd											;Gets a handle for device context 
		mov    hdc, eax
        .IF LeftMouseClick
			invoke SetPixel, hdc, hitpoint.x, hitpoint.y, penColor	;Sets pixel at x,y to penColor (default back)
        .ELSEIF RightMouseClick
			invoke SetPixel, hdc, hitpoint.x, hitpoint.y, eraseColor;"erases" by setting color to background color
		.ENDIF 
		invoke ReleaseDC, hWnd, hdc

	.ELSEIF uMsg==WM_MOUSEMOVE
		invoke getCoord, lParam
		.if LeftMouseClick					;continues drawing if LMB is still down
			invoke GetDC, hWnd 
			mov    hdc,eax
			invoke SetPixel, hdc, hitpoint.x, hitpoint.y, penColor
			invoke ReleaseDC, hWnd, hdc
		.ELSEIF RightMouseClick				;continues "erasing" if RMB is still down
			invoke GetDC, hWnd
			mov    hdc, eax
			invoke SetPixel, hdc, hitpoint.x, hitpoint.y, eraseColor
			invoke ReleaseDC, hWnd, hdc
		.ENDIF

	
	.ELSEIF uMsg==WM_LBUTTONUP										;cancels drawing on movement
		.IF LeftMouseClick
			mov LeftMouseClick, FALSE
		.ENDIF
	.ELSEIF uMsg==WM_RBUTTONUP										;cancels "erasing" on movement
		.IF RightMouseClick
			mov RightMouseClick, FALSE
		.ENDIF

	.ELSE
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam				
        ret 
    .ENDIF 
	 
    xor    eax,eax 
    ret 
WndProc endp 



getCoord proc lParam:LPARAM										;Gets mouse coordinates
	mov eax,lParam												
	and eax,0FFFFh 
	mov hitpoint.x,eax											;Processes x-coordinates

	mov eax,lParam 
	shr eax,16 
	mov hitpoint.y,eax											;Processes y-coordinates
	ret
getCoord endp


;Need to get io.h working first
setColor proc
	mov penColor, 0												;Clears pen color
																;Color format: 00RRGGBBh


	;input redPrompt, string, 3									;Adds red component
	;atod string
	shl eax, 4
	add penColor, eax

	;input greenPrompt, string, 3								;Adds green component
	;atod string
	shl eax, 2
	add penColor, eax

	;input bluePrompt, string, 3								;Adds blue component
	;atod string
	add penColor, eax

	ret
setColor endp
END


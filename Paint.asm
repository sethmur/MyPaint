;Nathan Hoffman	- Product Lead
;Ruvim Lashchuk	- File I/O
;Erik Olson		- Pixel FX
;Seth Murdoch	- Paint Cursor
;CISP 310



.586
.model flat, stdcall
option casemap :none

																;Includes
;INCLUDE io.h
include \masm32\include\windows.inc								;Needed to install
include \masm32\include\user32.inc 
include \masm32\include\kernel32.inc 
include \masm32\include\gdi32.inc 
includelib \masm32\lib\user32.lib 
includelib \masm32\lib\kernel32.lib 
includelib \masm32\lib\gdi32.lib



WinMain proto :DWORD,:DWORD,:DWORD,:DWORD						;procedure prototypes
getCoord proto :LPARAM



.stack 4096

.data?															;Variable Data
hInstance HINSTANCE ?											;
CommandLine LPSTR ?												;
hitpoint POINT <>												;click location


.data															;Constant Data
AppName  db "MyPaint",0											;window name
ClassName db "SimpleWinClass",0									;
MouseClick db 0													; 0=no click yet

.code
WinMainCRTStartup PROC												;Setup
	invoke GetModuleHandle, NULL									;places module handle into eax
    mov    hInstance,eax											;
    invoke GetCommandLine											;
    mov CommandLine,eax												;
    invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT		;window
    invoke ExitProcess,eax
WinMainCRTStartup ENDP

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD 
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND													;local variable declarations

    mov   wc.cbSize,SIZEOF WNDCLASSEX								;Size
    mov   wc.style, CS_HREDRAW or CS_VREDRAW						;?
    mov   wc.lpfnWndProc, OFFSET WndProc							;?
    mov   wc.cbClsExtra,NULL										;?
    mov   wc.cbWndExtra,NULL										;?
    push  hInst														;?
    pop   wc.hInstance												;?
    mov   wc.hbrBackground,COLOR_WINDOW+1							;background color
    mov   wc.lpszMenuName,NULL										;?
    mov   wc.lpszClassName,OFFSET ClassName							;?
    invoke LoadIcon,NULL,IDI_APPLICATION							;?
    mov   wc.hIcon,eax												;?
    mov   wc.hIconSm,eax											;?
    invoke LoadCursor,NULL,IDC_ARROW								;?
    mov   wc.hCursor,eax											;?
    invoke RegisterClassEx, addr wc									;?
    invoke CreateWindowEx,NULL,ADDR ClassName,ADDR AppName,\		;Creates window
           WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\ 
           CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,NULL,NULL,\ 
           hInst,NULL 
    mov   hwnd,eax													;
    invoke ShowWindow, hwnd,SW_SHOWNORMAL							;Displays Window
    invoke UpdateWindow, hwnd										;
    .WHILE TRUE														;loop changes message
                invoke GetMessage, ADDR msg,NULL,0,0				;gets message (https://docs.microsoft.com/en-us/cpp/mfc/reference/handlers-for-wm-messages)
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
        mov MouseClick,TRUE											;
		invoke MoveToEx, hdc, hitpoint.x, hitpoint.y, NULL			;Moves drawing marker
        ;invoke InvalidateRect,hWnd,NULL,FALSE					;Prepares area for editing(Dont need. interesting if you want to mess up other windows)
																	;hWnd:this window	Null:whole window	False:doesn't clear area first

    .ELSEIF uMsg==WM_PAINT											;WM_Paint sends when some area is invalidated
		invoke GetDC, hWnd
		mov    hdc,eax 

        .IF MouseClick
			invoke SetPixel, hdc, hitpoint.x, hitpoint.y, 0			;sets pixel at x,y to color 0 (black)

        .ENDIF 
		invoke ReleaseDC, hWnd, hdc

	.ELSEIF uMsg==WM_MOUSEMOVE
		.if MouseClick
			invoke GetDC, hWnd 
			mov    hdc,eax
			invoke getCoord, lParam
			invoke SetPixel, hdc, hitpoint.x, hitpoint.y, 0
			invoke ReleaseDC, hWnd, hdc
		.ENDIF
    
	
	.ELSEIF uMsg==WM_LBUTTONUP										;cancels drawing on movement
		.IF MouseClick
			mov MouseClick, FALSE
		.ENDIF


	.ELSE
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam				;
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


END


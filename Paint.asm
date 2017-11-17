;Nathan Hoffman	- Product Lead
;Ruvim Lashchuk	- File I/O
;Erik Olson		- Pixel FX
;Seth Murdoch	- Paint Cursor
;CISP 310



.586
.model flat, stdcall
option casemap :none

WinMain proto :DWORD,:DWORD,:DWORD,:DWORD		

;INCLUDE io.h

include \masm32\include\windows.inc				;Needed to install
include \masm32\include\user32.inc 
include \masm32\include\kernel32.inc 
include \masm32\include\gdi32.inc 
includelib \masm32\lib\user32.lib 
includelib \masm32\lib\kernel32.lib 
includelib \masm32\lib\gdi32.lib



.stack 4096

.data?
hInstance HINSTANCE ?											;
CommandLine LPSTR ?												;
hitpoint POINT <>												;


.data
AppName  db "MyPaint",0											;window name
message  db ".",0												;what will be drawn
ClassName db "SimpleWinClass",0									;
MouseClick db 0													; 0=no click yet

.code
WinMainCRTStartup PROC
	invoke GetModuleHandle, NULL									;?
    mov    hInstance,eax											;?
    invoke GetCommandLine											;?
    mov CommandLine,eax												;?
    invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT		;window
    invoke ExitProcess,eax
WinMainCRTStartup ENDP

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD 
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    mov   wc.cbSize,SIZEOF WNDCLASSEX								;?
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
                invoke GetMessage, ADDR msg,NULL,0,0				;gets mouse input
                .BREAK .IF (!eax) 
                invoke DispatchMessage, ADDR msg					;sends mouse input
    .ENDW 
    mov     eax,msg.wParam 
    ret 
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT

    .IF uMsg==WM_DESTROY											;x button
        invoke PostQuitMessage,NULL									;Closes Window
    .ELSEIF uMsg==WM_LBUTTONDOWN									;Detects mouse click
        mov eax,lParam												
        and eax,0FFFFh 
        mov hitpoint.x,eax											;Processes x-coordinates

        mov eax,lParam 
        shr eax,16 
        mov hitpoint.y,eax											;Processes y-coordinates

        mov MouseClick,TRUE 
        invoke InvalidateRect,hWnd,NULL,FALSE						;prepares area for editing
																	;hWnd:this window	Null:whole window	False:doesn't clear area first
    .ELSEIF uMsg==WM_PAINT 
        invoke BeginPaint,hWnd, ADDR ps 
        mov    hdc,eax 
        .IF MouseClick 
            invoke lstrlen,ADDR message										;
            invoke TextOut,hdc,hitpoint.x,hitpoint.y,ADDR message,eax		;places message at coords
        .ENDIF 
        invoke EndPaint,hWnd, ADDR ps 
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret 
    .ENDIF 
    xor    eax,eax 
    ret 
WndProc endp 

	
	
	
END


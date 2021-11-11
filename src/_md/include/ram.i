; -------------------------------------------------------------------------
; Mega Drive Engine
; By Ralakimus 2021
; -------------------------------------------------------------------------
; RAM definitions
; -------------------------------------------------------------------------

	include	"globalvars.i"

; -------------------------------------------------------------------------
; RAM layout
; -------------------------------------------------------------------------

SYSVARSZ	=	$94
GLOBALVARSZ	EQU	globalVarsEnd-globalVars
LOCALVARSZ	EQU	-(GLOBALVARSZ+SYSVARSZ)&$FFFF

	if LOCALVARSZ<0
		inform	3,"Global variable space is too large by $%h bytes", -__rs
	endif

; -------------------------------------------------------------------------

	rsset	WORKRAM

		rs.b	GLOBALVARSZ		; Global variables space
localVars	rs.b	LOCALVARSZ		; Local variables start
localVarsEnd	rs.b	0			; Local variables end

extInterrupt	rs.b	6			; External interrupt
hInterrupt	rs.b	6			; H-BLANK interrupt
vInterrupt	rs.b	6			; V-BLANK interrupt

consoleVer	rs.b	1			; Console version cache
		RSEVEN

stack		rs.b	$80			; Stack area
stackBase	rs.b	0

	if __rs<WORKRAME
		inform	3,"End of Work RAM layout is behind $%h bytes", -__rs
	elseif __rs>WORKRAME
		inform	3,"End of Work RAM layout is ahead $%h bytes", __rs
	endif

; -------------------------------------------------------------------------

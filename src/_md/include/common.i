; -------------------------------------------------------------------------
; Mega Drive Engine
; By Ralakimus 2021
; -------------------------------------------------------------------------
; Common definitions and macros
; -------------------------------------------------------------------------

; -------------------------------------------------------------------------
; Condition code bits
; -------------------------------------------------------------------------

CCRC		EQU	1			; Carry
CCRV		EQU	2			; Overflow
CCRZ		EQU	4			; Zero
CCRN		EQU	8			; Negative
CCRX		EQU	$10			; Extended

; -------------------------------------------------------------------------
; Align to size boundary
; -------------------------------------------------------------------------
; PARAMETERS:
;	bound - Size boundary
;	value - (OPTIONAL) Value to pad with
; -------------------------------------------------------------------------

ALIGN macro bound, value
	local	pad
pad	=	((\bound)-((*)%(\bound)))%(\bound)
	if narg>1
		dcb.b	pad,\value
	else
		dcb.b	pad,0
	endif
	endm

; -------------------------------------------------------------------------
; Align RS address to even address
; -------------------------------------------------------------------------

RSEVEN macros
	rs.b	__rs&1

; -------------------------------------------------------------------------
; Generate repeated RS structure entries
; -------------------------------------------------------------------------
; PARAMETERS:
;	name  - Entry name base
;	count - Number of entries
;	size  - Size of entry
; -------------------------------------------------------------------------

RSRPT macro name, count, size
	local cnt
cnt	=	0
	rept	\count
\name\\$cnt	rs.\0	\size
cnt		=	cnt+1
	endr
	endm

; -------------------------------------------------------------------------
; Push to stack
; -------------------------------------------------------------------------
; PARAMETERS:
;	src - Source data location
; -------------------------------------------------------------------------

PUSH macros src
	move.\0 \src,-(sp)

; -------------------------------------------------------------------------
; Push multiple registers to stack
; -------------------------------------------------------------------------
; PARAMETERS:
;	src - Source data location
; -------------------------------------------------------------------------

PUSHM macros src
	movem.\0 \src,-(sp)

; -------------------------------------------------------------------------
; Push all registers to stack
; -------------------------------------------------------------------------

PUSHA macros
	movem.l	d0-a6,-(sp)

; -------------------------------------------------------------------------
; Pop from stack
; -------------------------------------------------------------------------
; PARAMETERS:
;	dest - Destination data location
; -------------------------------------------------------------------------

POP macros dest
	move.\0	(sp)+,\dest

; -------------------------------------------------------------------------
; Pop multiple registers from stack
; -------------------------------------------------------------------------
; PARAMETERS:
;	dest - Destination data location
; -------------------------------------------------------------------------

POPM macros dest
	movem.\0 (sp)+,\dest

; -------------------------------------------------------------------------
; Pop all registers from stack
; -------------------------------------------------------------------------

POPA macros
	movem.l	(sp)+,d0-a6

; -------------------------------------------------------------------------
; Disable interrupts
; -------------------------------------------------------------------------

INTOFF macros
	ori.w	#$700,sr

; -------------------------------------------------------------------------
; Enable interrupts
; -------------------------------------------------------------------------

INTON macros
	andi.w	#~$700,sr

; -------------------------------------------------------------------------
; Store string with static size
; -------------------------------------------------------------------------
; PARAMETERS:
;	len - Length of string
;	str - String to store
; -------------------------------------------------------------------------

STRSZ macro len, str
	local	len2, str2
	if strlen(\str)>(\len)
len2		=	\len
str2		SUBSTR	1,\len,\str
	else
len2		= 	strlen(\str)
str2		EQUS	\str
	endif
	dc.b	"\str2"
	dcb.b	\len-len2, " "
	endm

; -------------------------------------------------------------------------
; Store number with static number of digits
; -------------------------------------------------------------------------
; PARAMETERS:
;	digits - Number of digits
;	num    - Number to store
; -------------------------------------------------------------------------

NUMSTR macro digits, num
	local	num2, digits2, mask
num2	=	\num
digits2	=	1
mask	=	10
	while	(num2<>0)&(digits2<(\digits))
num2		=	num2/10
mask		=	mask*10
digits2		=	digits2+1
	endw
num2	=	(\num)%mask
	dcb.b	(\digits)-strlen("\#num2"), "0"
	dc.b	"\#num2"
	endm

; -------------------------------------------------------------------------
; Store month string
; -------------------------------------------------------------------------

MNTHSTR macro month
	local	mthstr
mthstr	SUBSTR	1+((\month)*3), 3+((\month)*3), &
	"JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC"
	dc.b	"\mthstr"
	endm

; -------------------------------------------------------------------------
; Store build date
; -------------------------------------------------------------------------

BUILDDATE macro
	NUMSTR	4, _year+1900
	dc.b	"/"
	NUMSTR	2, _month
	dc.b	"/"
	NUMSTR	2, _day
	dc.b	" "
	NUMSTR	2, _hours
	dc.b	":"
	NUMSTR	2, _minutes
	endm

; -------------------------------------------------------------------------

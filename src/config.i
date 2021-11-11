; -------------------------------------------------------------------------
; Scaling demo
; By Ralakimus 2021
; -------------------------------------------------------------------------
; Configuration
; -------------------------------------------------------------------------

; -------------------------------------------------------------------------
; Assembler options
; -------------------------------------------------------------------------

	opt	op+				; PC relative optimizations
	opt	os+				; Short branch optimizations
	opt	ow+				; Absolute word addressing optimizations
	opt	oz+				; Zero offset optimizations
	opt	oaq+				; ADDQ optimizations
	opt	osq+				; SUBQ optimizations
	opt	omq+				; MOVEQ optimizations

; -------------------------------------------------------------------------
; Flags
; -------------------------------------------------------------------------

; Debug flag
DEBUG		EQU	1

; -------------------------------------------------------------------------
; Information
; -------------------------------------------------------------------------

; Copyright
COPYRIGHT	EQUS	"RALAKEK"
; Game name
GAMENAME	EQUS	"Scaling Demo by Ralakimus"
; I/O support
IOSUPPORT	EQUS	"J"
; Serial number
SERIAL		EQUS	"00000000"
; Revision
REVISION	EQU	0
; External RAM size
EXTRAMS		EQU	0

; -------------------------------------------------------------------------

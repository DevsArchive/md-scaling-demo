; -------------------------------------------------------------------------
; Mega Drive Engine
; By Ralakimus 2021
; -------------------------------------------------------------------------
; Main source file
; -------------------------------------------------------------------------

	include	"config.i"
	include	"_md/include/common.i"
	include	"_md/include/megadrive.i"
	if DEBUG<>0
		include	"_md/include/debugger.i"
	endif
	include	"_md/include/ram.i"

; -------------------------------------------------------------------------
; Vector table
; -------------------------------------------------------------------------

	org	CARTROM

InitBlock:
	dc.l	stackBase			; Stack pointer
	dc.l	.Initialize			; Program start
	if DEBUG<>0
		dc.l	BusError		; Bus error
		dc.l	AddressError		; Address error
		dc.l	IllegalInstr		; Illegal instruction
		dc.l	ZeroDivide		; Division by zero
		dc.l	ChkInstr		; CHK exception
		dc.l	TrapvInstr		; TRAPV exception
		dc.l	PrivilegeViol		; Privilege violation
		dc.l	Trace			; TRACE exception
		dc.l	Line1010Emu		; Line-A emulator
		dc.l	Line1111Emu		; Line-F emulator
	else
		dcb.l	10, .ErrorTrap
	endif

; -------------------------------------------------------------------------

.InitTables:
.PSGRegs:
	dc.b	(((0)<<5)|$90)|15		; PSG1 minimum volume
	dc.b	(((1)<<5)|$90)|15		; PSG2 minimum volume
	dc.b	(((2)<<5)|$90)|15		; PSG3 minimum volume
	dc.b	(((3)<<5)|$90)|15		; PSG4 minimum volume
.PSGRegsEnd:

.VDPRegs:
	dc.b	%00000100			; H-INT off
	dc.b	%00010100			; Display off, V-INT off, DMA on
	dc.b	$C000/$400			; Plane A address
	dc.b	$D000/$400			; Window plane address
	dc.b	$E000/$2000			; Plane B address
	dc.b	$F800/$200			; Sprite table address
	dc.b	0				; Unused
	dc.b	0				; Background color line 0, color 0
	dc.b	0				; Unused
	dc.b	0				; Unused
	dc.b	256-1				; H-INT every 256 scanlines
	dc.b	0				; EXT-INT off, scroll by screen
	dc.b	%10000001			; H40 mode, S/H mode off, no interlace
	dc.b	$FC00/$400			; HScroll table address
	dc.b	0				; Unused
	dc.b	1				; Auto increment 1 (for DMA)
	dc.b	%00000001			; 64x32 tilemap
	dc.b	0				; Window X
	dc.b	0				; Window Y
	dc.b	$FF				; DMA clear length $10000 bytes
	dc.b	$FF
	dc.b	$00				; DMA clear source $0000
	dc.b	$00
	dc.b	$80
.VDPRegsEnd:

	VDPCMD	dc.l,$0000,VRAM,DMA		; VRAM DMA command
	VDPCMD	dc.l,$0000,CRAM,WRITE		; CRAM write command

; -------------------------------------------------------------------------

.Initialize:
	movem.l	.InitAddrs(pc),a0-sp		; Set up address registers
	lea	Z80BUS-Z80RESET(a3),a2		; Z80 reset port

	bra.s	.InitPart2			; Go to part 2

; -------------------------------------------------------------------------

.InitAddrs:
	dc.l	VDPCTRL				; Spurious exception (VDP control port for initialization, a0)
	dc.l	VDPDATA				; IRQ 1 (VDP data port for initialization, a1)
	dc.l	ExtInterrupt			; IRQ 2 (External interrupt)
	dc.l	Z80RESET			; IRQ 3 (Z80 reset port for initialization, a3)
	dc.l	HInterrupt			; IRQ 4 (H-BLANK interrupt)
	dc.l	.InitTables			; IRQ 5 (Initialization tables for initialization, a5)
	dc.l	VInterrupt			; IRQ 6 (V-BLANK interrupt)
	dc.l	IOCTRL1				; IRQ 7 (I/O control port 3 for initialization, sp)

; -------------------------------------------------------------------------

	dc.l	.ErrorTrap			; TRAP 00 exception
	dc.l	.ErrorTrap			; TRAP 01 exception
	dc.l	.ErrorTrap			; TRAP 02 exception
	dc.l	.ErrorTrap			; TRAP 03 exception
	dc.l	.ErrorTrap			; TRAP 04 exception
	dc.l	.ErrorTrap			; TRAP 05 exception
	dc.l	.ErrorTrap			; TRAP 06 exception
	dc.l	.ErrorTrap			; TRAP 07 exception
	dc.l	.ErrorTrap			; TRAP 08 exception
	dc.l	.ErrorTrap			; TRAP 09 exception
	dc.l	.ErrorTrap			; TRAP 10 exception
	dc.l	.ErrorTrap			; TRAP 11 exception
	dc.l	.ErrorTrap			; TRAP 12 exception
	dc.l	.ErrorTrap			; TRAP 13 exception
	dc.l	.ErrorTrap			; TRAP 14 exception
	dc.l	.ErrorTrap			; TRAP 15 exception

; -------------------------------------------------------------------------

.InitPart2:
	lea	CARTROM+$100.w,a4		; Location of "SEGA" string ($100)

	move.b	VERSION-IOCTRL1(sp),d3		; Get console version
	moveq	#$F,d0				; Satisfy TMSS
	and.b	d3,d0
	beq.s	.SkipTMSS
	move.l	(a4),TMSSSEGA-IOCTRL1(sp)

.SkipTMSS:
	move.w	(a0),d0				; Check if the VDP is working

	moveq	#0,d0				; Clear D0, A6, and USP
	movea.l	d0,a6
	move.l	a6,usp
	
	moveq	#.PSGRegsEnd-.PSGRegs-1,d1	; Initialize PSG registers

.InitPSG:
	move.b	(a5)+,PSGCTRL-VDPCTRL(a0)
	dbf	d1,.InitPSG

	moveq	#.VDPRegsEnd-.VDPRegs-1,d1	; Initialize VDP registers
	move.w	#$8000,d2

.InitVDPRegs:
	move.b	(a5)+,d2
	move.w	d2,(a0)
	add.w	a4,d2
	dbf	d1,.InitVDPRegs

	move.w	a4,(a2)				; Stop Z80
	move.w	a4,(a3)				; Cancel Z80 reset

.WaitZ80Stop:
	btst	d0,(a2)				; Wait for Z80 to stop
	bne.s	.WaitZ80Stop

	bra.w	.InitPart3			; Go to part 3

; -------------------------------------------------------------------------
; ROM header
; -------------------------------------------------------------------------

	dc.b	"SEGA MEGA DRIVE "		; Hardware ID

	STRSZ	7, "\COPYRIGHT"			; Copyright
	dc.b	" "
	NUMSTR	4, _year+1900
	dc.b	"."
	MNTHSTR	_month
	
	if DEBUG=0				; Game name
		STRSZ	$30, "\GAMENAME"
		STRSZ	$30, "\GAMENAME"
	else
		STRSZ	$20, "\GAMENAME"
		BUILDDATE
		STRSZ	$20, "\GAMENAME"
		BUILDDATE
	endif

	dc.b	"GM "				; Serial number
	STRSZ	8, "\SERIAL"
	dc.b	"-"
	NUMSTR	2, REVISION

	dc.w	0				; Check sum
	STRSZ	$10, "\IOSUPPORT"		; I/O suuport

	dc.l	CARTROM				; ROM addresses
	dc.l	CARTROME-1
	dc.l	WORKRAM&$FFFFFF			; Work RAM addresses
	dc.l	(WORKRAME-1)&$FFFFFF
	if EXTRAMS=0				; External RAM support
		dcb.b	$C, " "
	else
		dc.b	"RA", $F8, $20
		dc.l	EXTRAM
		dc.l	EXTRAME
	endif
	
	dcb.b	$C, " "				; Modem support

; -------------------------------------------------------------------------
	
.InitPart3:
	move.b	(a5),(sp)+			; Initialize I/O ports
	move.b	(a5),(sp)+
	move.b	(a5),(sp)
	
	move.l	(a5)+,(a0)			; Set VRAM clear command
	move.w	d0,(a1)				; Start VRAM clear
	move.l	(a5)+,d2			; Get CRAM write command

	move.w	#WORKRAMS/4-1,d1		; Clear work RAM

.ClearRAM:
	move.l	d0,-(a6)
	dbf	d1,.ClearRAM

	lea	Z80RAM,a5			; Z80 RAM
	move.b	#$F3,(a5)+			; Write "DI" to Z80 RAM
	move.b	#$C3,(a5)+			; Write "JP $0000" to Z80 RAM
	move.b	d0,(a5)+

	bra.s	.InitPart4			; Go to part 4
	
; -------------------------------------------------------------------------

	STRSZ	$10, "JUE"			; Region support

; -------------------------------------------------------------------------

.InitPart4:
	move.b	d0,(a5)				; Write low byte of "JP $0000" instruction

	move.w	d0,(a3)				; Reset Z80
	move.w	d0,(a2)				; Start Z80
	move.w	a4,(a3)				; Cancel Z80 reset

	move.w	#$8F02,(a0)			; Set VDP auto increment to 2
	move.l	d2,(a0)				; Clear CRAM
	moveq	#PALETTESZ/4-1,d1

.ClearCRAM:
	move.l	d0,(a1)
	dbf	d1,.ClearCRAM

	moveq	#VSCROLLSZ/4-1,d1		; Clear VSRAM
	VDPCMD	move.l,$0000,VSRAM,WRITE,(a0)

.ClearVSRAM:
	move.l	d0,(a1)
	dbf	d1,.ClearVSRAM
	
	move.b	d3,consoleVer.w			; Store console version

	move.w	#$4E73,d1			; Set up interrupts
	move.w	d1,extInterrupt.w
	move.w	d1,hInterrupt.w
	move.w	d1,vInterrupt.w

	lea	CARTROM+$200.w,a2		; Calculate checksum

.CalcChecksum:
	add.w	(a2)+,d0
	cmp.l	CARTROM+$1A4.w,a2
	bcs.s	.CalcChecksum

	cmp.w	CARTROM+$18E.w,d0		; Does it match the checksum in the header?
	beq.s	.ChecksumGood			; If so, loop here forever

	move.l	d2,(a0)				; Make screen red
	move.w	#$E,(a1)

.ErrorTrap:
	stop	#$2700				; Stop here forever

.ChecksumGood:
	move.w	#$8100|%00110100,(a0)		; Enable V-INT

	movea.l	(a6),sp				; Set actual stack pointer
	movem.l	(a6),d0-a6			; Clear registers
	move	#$2700,sr			; Reset status register

	jmp	Main				; Go to main program

; -------------------------------------------------------------------------
; Main program
; -------------------------------------------------------------------------

	include	"main.s"

; -------------------------------------------------------------------------
; Error handler
; -------------------------------------------------------------------------

	if DEBUG<>0
		include	"_md/lib/error.s"
	endif

; -------------------------------------------------------------------------

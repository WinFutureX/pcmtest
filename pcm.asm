; pcm playback test rom
; for sega mega drive
; copyfuck 2019-42069 kelsey boey

vectors:
	dc.l	$0
	dc.l	startup_68k
	rept	24
	dc.l	cpufault
	endr
	dc.l	nullirq	; ext int (l2 irq)
	dc.l	cpufault
	dc.l	nullirq	; vdp hblank (l4 irq)
	dc.l	cpufault
	dc.l	nullirq	; vdp vblank (l6 irq)
	rept	33
	dc.l	cpufault
	endr

; mega drive cartridge header
mdcart:	dc.b	"SEGA MEGA DRIVE "
	dc.b	"(C)KELSEY B 2019"
	dc.b	"YM2612 PCM AUDIO TESTING ROM FOR SEGA MEGA DRIVE"
	dc.b	"YM2612 PCM AUDIO TESTING ROM FOR SEGA MEGA DRIVE"
	dc.b	"TESTPCMROM-000"
	dc.w	$0
	dc.b	"J               "
	dc.l	vectors
	dc.l	romend-1
	dc.l	$FF0000
	dc.l	$FFFFFF
	dc.l	$20202020
	dc.l	$20202020
	dc.l	$20202020
	dc.b	"                                                    "
	dc.b	"JUE             "

; 68k exception handler
cpufault:
	movea.l	$0.l, a7	; reset stack pointer

startup_68k:
	move.w	#$2700, sr	; disable ints
	move.b	$A10001, d0
	andi.b	#$F, d0	; check console revision
	beq.s	initz80
	move.l	$100.w, $A14000	; satisfy tmss

initz80:
	move.w	#$100, $A11100
	move.w	#$100, $A11200

z80wait:
	btst	#$0, $A11100
	bne.s	z80wait
	lea	z80code, a1
	lea	$A00000, a2
	move.w	#z80end-z80code-1,d1

z80loop:
	move.b	(a1)+, (a2)+
	dbf	d1, z80loop
	bra.s	z80end
	
z80code:
	dc.b	$AF		; xor	a
	dc.b	$01, $D9, $1F	; ld	bc, 1fd9h
	dc.b	$11, $27, $00	; ld	de, 0027h
	dc.b	$21, $26, $00	; ld	hl, 0026h
	dc.b	$F9		; ld	sp, hl
	dc.b	$77		; ld	(hl), a
	dc.b	$ED, $B0	; ldir
	dc.b	$DD, $E1	; pop	ix
	dc.b	$FD, $E1	; pop	iy
	dc.b	$ED, $47	; ld	i, a
	dc.b	$ED, $4F	; ld	r, a
	dc.b	$D1		; pop	de
	dc.b	$E1		; pop	hl
	dc.b	$F1		; pop	af
	dc.b	$08		; ex	af, af'
	dc.b	$D9		; exx
	dc.b	$C1		; pop	bc
	dc.b	$D1		; pop	de
	dc.b	$E1		; pop	hl
	dc.b	$F1		; pop	af
	dc.b	$F9		; ld	sp, hl
	dc.b	$F3		; di
	dc.b	$ED, $56	; im1
	dc.b	$36, $E9	; ld	(hl), e9h
	dc.b	$E9		; jp	(hl)

z80end:
	move.w	#$0, $A11100
	move.w	#$0, $A11200

initvdp:
	lea	$C00004, a0
	lea	$C00000, a1
	move.l	#$80048154, (a0)
	move.l	#$82308340, (a0)
	move.l	#$8407856A, (a0)
	move.l	#$86008700, (a0)
	move.l	#$8A008B08, (a0)
	move.l	#$8C898D34, (a0)
	move.l	#$8E008F02, (a0)
	move.l	#$90019200, (a0)
	move.l	#$93009400, (a0)
	move.l	#$95009700, (a0)

clearvram:
	move.l	#$40000000, (a0)
	move.w	#$3FFF, d0
	moveq	#0, d1

clearvramloop:
	move.l	d1, (a1)
	dbf	d0, clearvramloop

clearcram:
	move.l	#$C0000000, (a0)
	move.b	#$3F, d0

clearcramloop:
	move.l	d1, (a1)
	dbf	d0, clearcramloop

silencepsg:
	lea	$C00011, a3
	move.b	#$9F, (a3)	; silence channel 1
	move.b	#$BF, (a3)	; silence channel 2
	move.b	#$DF, (a3)	; silence channel 3
	move.b	#$FF, (a3)	; silence channel 4

clearram:
	moveq	#0, d2
	move.l	d2, a4
	move.w	#$3FFF, d3

clearramloop:
	move.l	d2, -(a4)
	dbra	d3, clearramloop

initjoy:
	move.b	#0, $A10009	; controller port 1
	move.b	#0, $A1000B	; controller port 2
	move.b	#0, $A1000D	; ext port

main:
	move.w	#sndsize, d0	; set repeat count
	lea	snd, a0
	lea	$A04000, a1
	lea	$A04001, a2
	move.w	#$100, $A11100	; get z80 bus
	move.w	#$100, $A11200	; hold z80 reset

setfm:
	move.b	#$2B, (a1)	; select dac enable register
	move.b	#$80, (a2)	; set dac enable
	move.b	#$2A, (a1)	; select dac register

setdelay:
	; note: sample timing is dependent on the value you've set in this subroutine
	moveq	#43, d1

delay:
	dbf	d1, delay	; empty loop - delay sample playback
	nop

playloop:
	move.b	(a0)+, (a2)	; play a sample
	dbf	d0, setdelay	; repeat for unplayed samples
	move.w	#0, $A11100
	move.w	#0, $A11200
	bra.s	*	; if finished, hang

nullirq:
	rte

snd	incbin	"sega.pcm"	; sega sound from sonic 1

sndsize	equ	27000	; size in bytes (decimal, not hex)

romend	end	; end of rom

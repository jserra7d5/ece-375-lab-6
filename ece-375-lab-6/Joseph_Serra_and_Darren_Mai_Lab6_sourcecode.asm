;***********************************************************
;*
;*	This is the skeleton file for Lab 6 of ECE 375
;*
;*	 Authors: Joseph Serra and Darren Mai
;*	   Date: 2/22/2025
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	speedReg = r20

.equ	EngEnR = 5				; right Engine Enable Bit
.equ	EngEnL = 6				; left Engine Enable Bit
.equ	EngDirR = 4				; right Engine Direction Bit
.equ	EngDirL = 7				; left Engine Direction Bit

.equ	IncSpeedBtn = 4
.equ	MaxSpeedBtn = 3
.equ	DecSpeedBtn = 6

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

		; place instructions in interrupt vectors here, if needed

.org	$0008
		rcall	MaxSpeedInt
		reti

.org	$0022	; timer counter 1 interrupt A
		rcall	TIM1_COMPA

.org	$002C 	; timer counter interrupt A




.org	$0056					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr
		ldi		mpr, high(RAMEND)
		out		SPH, mpr

		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low

		sbi  DDRB, PB7
		sbi  DDRB, PB4
		sbi  PORTB, PB7
		sbi  PORTB, PB4

		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		; Configure External Interrupts, if needed
		ldi		mpr, 0b00001000
		sts		EICRA, mpr

		ldi		mpr, (1 << MaxSpeedBtn)
		out		EIMSK, mpr

		; configure 0.5s delay counter0
		sbi		DDRB, PB7
		ldi		mpr, 0
		out		TCCR0A, mpr
		ldi		mpr, 0b00000101
		out		TCCR0B, mpr

		; Configure 16-bit Timer/Counter 1A and 1B
		sbi	DDRB, PB5
		sbi	DDRB, PB6
		ldi	mpr, (1<<COM1A1 | 1 << COM1B1 | 1<<WGM10) ; activating fast PWN mode with toggle
		sts TCCR1A, mpr
		ldi	mpr, (1<<WGM12 | 1<<CS11 | 1<<CS10)
		sts	TCCR1B, mpr

		ldi	mpr, 255
		sts	OCR1AL, mpr
		sts	OCR1BL, mpr

		; Fast PWM, 8-bit mode, no prescaling

		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL) on Port B

		; Set initial speed, display on Port B pins 3:0
		ldi		speedReg, 0 

		; Enable global interrupts (if any are used)
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		; poll Port D pushbuttons (if needed)
		in mpr, PIND
		andi mpr, (1 << IncSpeedBtn | 1 << DecSpeedBtn)

		sbrs mpr, DecSpeedBtn
		rcall DecreaseSpeed

		sbrs mpr, IncSpeedBtn
		rcall IncreaseSpeed

		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

UpdateSpeedVisual:
		ldi mpr, 17
		mul	mpr, speedReg
		ldi mpr, 255
		sub mpr, r0
		sts OCR1AL, mpr
		sts OCR1BL, mpr
		in	mpr, PINB
		andi mpr, 0b11110000
		or	mpr, speedReg
		sbr  mpr, (1 << PB7) | (1 << PB4)
		out	PORTB, mpr
		ret

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
IncreaseSpeed:	; Begin a function with a label
		cpi	speedReg, 15
		breq IncSpeedSkip
		inc	speedReg
		rcall UpdateSpeedVisual
		rcall WAIT
		IncSpeedSkip:
		ret						; End a function with RET

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
MaxSpeedInt:	; Begin a function with a label
		ldi speedReg, 15
		rcall UpdateSpeedVisual
		; If needed, save variables by pushing to the stack

		; Execute the function here

		; Restore any saved variables by popping from stack
		in   mpr, EIFR           ; Read EIFR
		ori  mpr, (1 << INTF3)   ; Clear INTF0
		out  EIFR, mpr           ; Write back
		ret						; End a function with RET

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
DecreaseSpeed:	; Begin a function with a label
		cpi	speedReg, 0
		breq DecSpeedSkip
		dec speedReg
		rcall UpdateSpeedVisual
		rcall WAIT
		DecSpeedSkip:
		ret						; End a function with RET

WAIT:
	ldi	r17, 50	; wait half a second
WAIT_10ms:
	ldi	mpr, 178
	out	TCNT0, mpr
WAIT_LOOP:
	in r18, TIFR0
	andi r18, 0b00000001
	breq WAIT_LOOP
	ldi	r18, 0b00000001
	out TIFR0, r18
	dec r17
	brne WAIT_10ms
	ret

TIM1_COMPA:
	in	mpr, PINB
	sbi PINB, PB5
	reti

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
FUNC:	; Begin a function with a label

		; If needed, save variables by pushing to the stack

		; Execute the function here

		; Restore any saved variables by popping from stack

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program

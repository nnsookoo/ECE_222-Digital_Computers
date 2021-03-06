; This code is based upon InputOutput's from the book:
;  "Embedded Systems: Introduction to ARM Cortex M Microcontrollers"
;  ISBN: 978-1469998749, Jonathan Valvano, copyright (c) 2014
;
; The code provided initializes all 3 ports (A,B,E) with the ECE Shield plugged into the Tiva board
; Port F with the Tiva 3 LEDs (Red, Green, Blue) and two buttons is also initialized
; Then the LEDs on each port are turned off and on with time delays - while the Tiva board R, G, B LEDs are turned on and off
;
; Dec 2017

        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT  Start

; These equates allow one to associate a name with a value to make the code more readable

RED       EQU 0x02		; These are the values (bit locations) for various LEDs on the Tiva (Port F)
BLUE      EQU 0x04
GREEN     EQU 0x08
SW1       EQU 0x10                 ; on the left side of the Tiva board
SW2       EQU 0x01                 ; on the right side of the Tiva board

Start
	BL  Port_Init                  ; initialize input and output pins of Ports A to F
	;MOV R11, #0xf3c0	; initialize the Random Number routine - NEVER WRITE TO R11 after this!! or you break how it works

	;BL 	RandomNum		;ADDED - Branch to RandomNum to generate a random number
	
; each of the Tiva ports is 8 bits wide and connect to wires which can be inputs or outputs

; to read the buttons on port F use the address GPIO_PORTF_DATA_R

; Simple turning on and off of LEDs
; by default (0 is the default output) all 8 LEDs are off (active high) while all 7-segment digits are on (active low)

keep_looping
; turn off 7 port B LEDs on the shielf - the last LED is on Port E
	LDR R3, =GPIO_PORTB + (PORT_B_MASK << 2) ; generate the base address for port B
	MOV R1, #0 ; write out a 0 to turn off the 7 LEDs on port B
	STR R1, [R3, #GPIO_DATA_OFFSET] ; GPIO_DATA_OFFSET is the address offset to get to the DATA part of the port

; The last LED is on port E - so read the value, modify bit 1 as it drives the LED and write it back out - this is called read-modify-write
	LDR R3, =GPIO_PORTE + (PORT_E_MASK << 2) ; generate the base address for port E
	LDR R1, [R3, #GPIO_DATA_OFFSET] ; GPIO_DATA_OFFSET is the address offset to get to the DATA part of the port
	AND R1, #0xFD ; set E1 0 to turn that LED off
	STR R1, [R3, #GPIO_DATA_OFFSET] ; write the data back out
	
	MOV R1, #1000
	BL ShortDelay
	
; turn on 7 port B LEDs
    LDR R3, =GPIO_PORTB + (PORT_B_MASK << 2)		; generate the base address for port B
	MOV R1, #0x0fd		; set lowest 8 bits except for B1 to 1
    STR R1, [R3, #GPIO_DATA_OFFSET]
	
; The last LED is on port E - so read the value, modify the B1 (bit 1) as it drives an LED and write it back out - this is called read-modify-write
    LDR R3, =GPIO_PORTE + (PORT_E_MASK << 2)		; generate the base address for port B
    LDR R1, [R3, #GPIO_DATA_OFFSET]		; GPIO_DATA_OFFSET is the address offset to get to the DATA part of the port
	AND R1, #0xFD		; preserve everything but B1 while B1 gets set to 0
	ORR R1, #0x02		; set B1 - these two lines could be replaced with a single ORR statement
    STR R1, [R3, #GPIO_DATA_OFFSET]		; write the data back out
	
	MOV R1, #1000
	BL ShortDelay
	
	ADD	R5, #1					; increment the counter
	B keep_looping
	
; ShortDelay subroutine - delay for a fixed amount of time
;
; This is a bad piece of code - only use it as an example for what never to do!!
;
; *INSERTED - NAV*
; What do we need to do then?
; Write code for a subroutine which implements a 0.1 millisecond delay.
; I'm guessing you can implement this from Lab1
; How I got the fraction of a second delay? Delay of 500ms was 2750000 -> 1ms = 5500 -> 0.1ms = 550
;
; To confirm the duration of 0.1 millisecond, you can do the following steps:
;	a) Turn one LED on
;	b) Call the subroutine in a loop for 100000 times (#100000 or #0x186A0)
;	c) Turn the LED off
;	d) Run the code and measure the time that the LED stays on. It must be for 100000x0.1 millisecond = 10 seconds
; *END*
;
; Input: R1 - how many times do we loop (multiply) the fixed delay - If R1 = 0 then there is no time delay
; At this point, R1 = #1000
; Output: none
;
; Need to check the value of R1. This controls how much times we multiply the fixed delay. 
; Delay 0.1ms (100us) * R1 times

SHORTDELAYCOUNT             EQU 550      ; fraction of a second delay
										 ; This number was changed from 400 to 550

Delay		; alternate name for this subroutine
ShortDelay
	STMFD		R13!,{R0, R1, R14}		; push the LR or return address
	
delay_outer_loop 
	TEQ			R1, #0
	LDR			R0, = SHORTDELAYCOUNT

delay_loop
	SUBS		R0, R0, #1 ; R0 = R0 - 1 (count = count - 1) and set N, Z, C status bits
	BNE 		delay_loop ; If the counter R0 is not 0, return back to the delay loop
	SUBS		R1, R1, #1 ; Decrement loop counter
	BEQ			exitDelay ; If R1 is 0, don't loop again
	BNE			delay_outer_loop ; If R1 is not 0, loop again

exitDelay
	LDMFD		R13!,{R0, R1, R15}		; pull the LR or return address and return


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;   DO NOT EDIT CODE BELOW THIS LINE
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

;------------RandomNum------------
; R11 holds a 16-bit "random" number via a pseudo-random sequence as per the Linear feedback shift register (Fibonacci) on WikiPedia
; Take as many bits of R11 as you need.
;
; R11 can be read anywhere in the user code but must only be written to by this subroutine
;
; INPUT: R11 - before calling this for the FIRST time R11 must be initialized to a large 16-bit non-zero value
;      if R11 is ever set to 0 then R11 will stay stuck at zero
; OUTPUT: R11 - random number is the lowest 16 bits of R11 which is between 1 and 0xffff
;
RandomNum		STMFD		R13!,{R1, R2, R3, R14}

				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1		; the new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				MOV			R1, #0xFFFF
				AND			R11, R1			; clear the upper 16 bits of R11 as they're not part of the random #
				
				LDMFD		R13!,{R1, R2, R3, R15}


; Tons of initialization to be done in order to use the I/O ports as they're off by default.
;
; Define the addresses and provide functions to initialize everything.

GPIO_PORTF_DIR_R   EQU 0x40025400		; Port F Data Direction Register setting pins as input or output
GPIO_PORTF_DATA_R  EQU 0x400253FC		; address for reading button inputs and writing to LEDs
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_PORTF_AMSEL_R EQU 0x40025528
GPIO_PORTF_PCTL_R  EQU 0x4002552C

;Section 3.1.2 Nested Vector Interrupt Controller

;The Cortex-M4F processor supports interrupts and system exceptions. The processor and the
;Nested Vectored Interrupt Controller (NVIC) prioritize and handle all exceptions. An exception
;changes the normal flow of software control. The processor uses Handler mode to handle all
;exceptions except for reset. See �Exception Entry and Return� on page 108 for more information.
;The NVIC registers control interrupt handling. See �Nested Vectored Interrupt Controller
;(NVIC)� on page 124 for more information.

;Table 3-8 on page 134 details interrupt Set / Clear 
; they allow one to enable individual interrupts and DIS? lets one disable individual interrupt numbers

; Table 2-9 Interrupts on page 104 details interrupt number / bit assignments
; Port F - Bit 30
; Timer 0A Bit 19
; Timer 0B Bit 20
 
;For edge-triggered interrupts, software must clear the interrupt to enable any further interrupts.

; NOTE: The NMI (non-maskable interrupt) is on PF0.  That means that
; the Alternate Function Select, Pull-Up Resistor, Pull-Down Resistor,
; and Digital Enable are all locked for PF0 until a value of 0x4C4F434B
; is written to the Port F GPIO Lock Register.  After Port F is
; unlocked, bit 0 of the Port F GPIO Commit Register must be set to
; allow access to PF0's control registers.  On the LM4F120, the other
; bits of the Port F GPIO Commit Register are hard-wired to 1, meaning
; that the rest of Port F can always be freely re-configured at any
; time.  Requiring this procedure makes it unlikely to accidentally
; re-configure the JTAG and NMI pins as GPIO, which can lock the
; debugger out of the processor and make it permanently unable to be
; debugged or re-programmed.
	
; These are the configuration registers which should not be touched
; Port Base addresses for the legacy (not high-performance) interface to I/O ports
GPIO_PORTA			EQU 0x40004000
GPIO_PORTB			EQU 0x40005000
GPIO_PORTC			EQU 0x40006000
GPIO_PORTD			EQU 0x40007000
GPIO_PORTE			EQU 0x40024000
GPIO_PORTF			EQU 0x40025000

; WARNING outputs PD0 & PD1 are shorted to PB6 and PB7 - one pair MUST BE INPUTS!! - we disable D0, D1

; These are the masks for pins which are outputs, setting a bit to 1 makes the pin an output, 0 is input
PORT_A_MASK			EQU 0xfc	; PA7,6,5,4,3,2 are outputs for 7-segment LEDs
PORT_B_MASK			EQU 0xfd	; PB7,6,5,4,3,2,0 are LEDs
PORT_C_MASK			EQU 0x30	; this breaks programming the CPU - DO NOT ENABLE	
PORT_D_MASK			EQU 0xcc	; PD7,6,3,2  Disable D0, D1 due to short with B6, B7
PORT_E_MASK			EQU 0x37	; PE0,1,2,4,5 are used for 7-segment, LED & speaker
PORT_F_MASK			EQU 0x0e	; PF has LEDs on PF1,2,3 and buttons PF0, PF4 (don't enable buttons as outputs)


; Offsets are from table 10-6 on page 660
GPIO_DATA_OFFSET	EQU 0x000		; Data address is the base address - YOU HAVE TO ADD AN ADDRESS MASK TOO to read or write this!!
GPIO_DIR_OFFSET		EQU 0x400		; Direction register
GPIO_AFSEL_OFFSET EQU 0x420			; Alternate Function SELection
GPIO_PUR_OFFSET   EQU 0x510			; Pull Up Resistors
GPIO_DEN_OFFSET   EQU 0x51C			; Digital ENable
GPIO_LOCK_OFFSET  EQU 0x520
GPIO_CR_OFFSET    EQU 0x524
GPIO_AMSEL_OFFSET EQU 0x528			; Analog Mode SELect
GPIO_PCTL_OFFSET  EQU 0x52C

SYSCTL_HBCTL  EQU   0x400FE06C		; high performance bus control for ports A to F

GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU   0x400FE608		; Register to enable clocks to the I/O port hardware

;------------Port_Init------------
; Initialize GPIO Port F for negative logic switches on PF0 and
; PF4 as the Launchpad is wired.  Weak internal pull-up
; resistors are enabled, and the NMI functionality on PF0 is
; disabled.  Make the RGB LED's pins outputs.
; Input: none
; Output: none
; Modifies: R0, R1, R2, R3
Port_Init
	STMFD		R13!,{R14}		; push the LR or return address

; First enable the clock to the I/O ports, by default the clocks are off to save power
; If a clock is not enabled to a port and you access it - then the processor hard faults
	LDR R1, =SYSCTL_RCGCGPIO_R      ; activate clock for Ports (see page 340)
    LDR R0, [R1]                 
    ORR R0, R0, #0x3F               ; turn on clock to all 6 ports (A to F, bits 0 to 5)
    STR R0, [R1]                  
    NOP
    NOP                             ; allow time for clock to finish
	
; Set all ports to APB bus instead of AHB - this should be unnecessary
;	LDR R1, =SYSCTL_HBCTL
;	LDR R0, [R1]
;	AND R0, #0xFFFFFFE0		; set Ports A thru F to APB (0) and leave the rest at their default
;	STR R0, [R1]

; Page 650, Table 10-1 GPIO Pins with Special Considerations.
; These pins must be left as configured after reset:
;  PA[5:0] (UART0 and SSIO), PB[3:2] (I2C), PC[3:0] (JTAG)

; Initialize the I/O ports A, B, E, F via a common subroutine Port_Init_Individual
; Call Port_Init_Individual with the following paramaters passed:
; R1 is the base port address
; R2 is the output pin mask (which bits are outputs)
; R3 is the input pin mask  (which bits get configured as inputs)

	MOV R3, #0x00				; Select no pins as input (unless it's changed as for port F)
	
; Init Port A, B, E are by default GPIO - set all output pins used to a 1 to enable them
;   and leave all of the other pins as previously configured!
    LDR R1, =GPIO_PORTA
    MOV R2, #PORT_A_MASK            ; enable commit for Port, 1 means allow access
	BL Port_Init_Individual

; Init Port B
    LDR R1, =GPIO_PORTB
    MOV R2, #PORT_B_MASK            ; enable commit for Port, 1 means allow access
	BL Port_Init_Individual

; Init Port C
    LDR R1, =GPIO_PORTC
    MOV R2, #PORT_C_MASK
	;BL Port_Init_Individual		; Do not initialize Port C as it renders the Tiva board unprogramable !

; Init Port D
    LDR R1, =GPIO_PORTD
    MOV R2, #PORT_D_MASK
	BL Port_Init_Individual

; Init Port E
	LDR R1, =GPIO_PORTE
    MOV R2, #PORT_E_MASK			; enable commit for Port, 1 means allow access
	BL Port_Init_Individual

; Init Port F
	LDR R1, =GPIO_PORTF
    MOV R2, #PORT_F_MASK		; enable commit for Port, 1 means allow access
	MOV R3, #0x11				; enable weak pull-up on PF0 and PF4 (buttons)
	BL Port_Init_Individual

	LDMFD		R13!,{R15}		; pull the LR or return address from the stack and return


;------------Port_Init_Individual------------
; Initialize one GPIO Port with select bits as inputs and outputs
; Output: none
; Input: R1, R2, R3
; R1 has to be the port address
; R2 has to hold the mask for output pins
; R3 has to be the mask for input pins
; Modifies: R0

Port_Init_Individual
	STMFD		R13!,{R14}		; push the LR or return address
    LDR R0, =0x4C4F434B             ; unlock GPIO Port F Commit Register
    STR R0, [R1, #GPIO_LOCK_OFFSET]	; 2) unlock the lock register
	ORR R0, R2, R3					; all access to inputs and outputs as masked in R2 and R3
    STR R0, [R1, #GPIO_CR_OFFSET]	; enable commit for Port F
    MOV R0, #0                      ; 0 means analog is off
    STR R0, [R1, #GPIO_AMSEL_OFFSET]	; 3) disable analog functionality
    MOV R0, #0x00000000             ; 0 means configure Port F as GPIO
    STR R0, [R1, #GPIO_PCTL_OFFSET]	; 4) configure as GPIO
    LDR R0, [R1, #GPIO_DIR_OFFSET]	; 5) read default direction register configuration
    ORR R0, R2						; ORR in only the bits we want as outputs
    STR R0, [R1, #GPIO_DIR_OFFSET]	; 5) set direction register
    MOV R0, #0                      ; 0 means disable alternate function 
    STR R0, [R1, #GPIO_AFSEL_OFFSET]	; 6) regular port function
    STR R3, [R1, #GPIO_PUR_OFFSET]	; pull-up resistors for PF4,PF0
    MOV R0, #0xFF                   ; 1 means enable digital I/O
    STR R0, [R1, #GPIO_DEN_OFFSET]
	LDMFD		R13!,{R15}		; pull the LR or return address and return

; Beep the speaker on the ECE Shield using port E4 and E5
; The speaker is conencted to two pins - toggle each end for more volume than a singled ended drive
;
; Before exiting ensure that both wires to the speaker are 0 to prevent it from being heated up
;
; Each beep, sounded or not, is about the same length - 0x300 loops of delay loop
;
; Input: R1 sets the tone - 0 is NO BEEP,
;                           1 is a high pitch beep and larger numbers are lower pitched
; Output: none

SpeakerBeepLength	EQU 0x300			; the length of the speaker beep
	
SpeakerBeep
	STMFD		R13!,{R1-R4, R11, R14}		; push the LR or return address

	MOV R4, #0x30		; This xor'd with the port holding the speaker pins will create a beep
	TEQ R1, #0		; If R1 = 0 then just delay but do not beep
	BNE make_a_sound
	MOV R1, #1		; stick a valid value into R1 as 0 will divide by 0
	MOV R4, #0x0		; setting R4 to 0 will ensure that no beep will sound
make_a_sound
	MOV R3, #SpeakerBeepLength	; how many loops of the beep delay do we do?  Ie how long is the beep
	UDIV R3, R1		; loop the tone R1 / R3 times to ensure a total of 0x100 delays for all tones
	
	LDR R2, =GPIO_PORTE + (PORT_E_MASK << 2)
	LDR R11, [R2, #GPIO_DATA_OFFSET]		; get the initial value - read-modify-write to only change 2 bits
	AND R11, #0xcf							; clear two bits that the speaker is on
	ORR R11, #0x10		; initial speaker output (one side high 0x10, the other low 0x20)
buzz_loop
	BL ShortDelay			; delay
	EOR R11, R4			; xor to toggle the two speaker pins to create a beep
	STR R11, [R2, #GPIO_DATA_OFFSET]
	SUBS R3, #1
	BNE buzz_loop
; now power down the speaker
	LDR R11, [R2, #GPIO_DATA_OFFSET]		; restore the speaker pins to 0V on each side
	AND R11, #0xcf							; clear two bits that the speaker is on
	STR R11, [R2, #GPIO_DATA_OFFSET]

	LDMFD		R13!,{R1-R4, R11, R15}		; pull the LR or return address and return


	ALIGN

Port_Table
	DCD	GPIO_PORTA + (PORT_A_MASK << 2)		; DCD - Define Constant Double Word (32-bits)
	DCD	GPIO_PORTB + (PORT_B_MASK << 2), GPIO_PORTC + (PORT_C_MASK << 2)
	DCD	GPIO_PORTD + (PORT_D_MASK << 2), GPIO_PORTE + (PORT_E_MASK << 2)
	DCD	GPIO_PORTF + (PORT_F_MASK << 2), 0

    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file - nothing after this is assembled

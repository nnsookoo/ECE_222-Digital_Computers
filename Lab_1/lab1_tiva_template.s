; This code is based upon InputOutput.s from the book:
;  "Embedded Systems: Introduction to ARM Cortex M Microcontrollers"
;  ISBN: 978-1469998749, Jonathan Valvano, copyright (c) 2014
;
; Dec 2017
;
; Code completed by : NAVEELA SOOKOO
;
; Basic Tiva I/O is on port F with a particular bit assigned / wired to a light or switch
; 
RED       EQU 0x02		; bit 1
BLUE      EQU 0x04		; bit 2
GREEN     EQU 0x08		; bit 3
SW1       EQU 0x10		; bit 4, on the left side of the Launchpad board
SW2       EQU 0x01		; bit 0, on the right side of the Launchpad board

; Port F data register to write to the LEDs and read the switches
;
GPIO_PORTF_DATA_R  EQU 0x400253FC	; register to write to outputs on the port and read inputs on the port

        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT  Start


SOMEDELAY             EQU 10000      ; faster than 500ms delay at ~16 MHz clock - inaccurate - adjust it to get it right
	;2750000

Start
    BL  PortF_Init                  ; initialize input and output pins of Port F

	MOV R3, #RED				; load in the value to turn the RED led ON, RED LED is bit 1 (counting from 0)
	LDR R1, =GPIO_PORTF_DATA_R ; pointer to Port F data register
    STR R3, [R1]               ; write data to Port F to turn lights on and off

loop1	
	LDR R0, =SOMEDELAY   	       ; R0 is initialized to a value to give a 500ms delay
loop2
    SUBS R0, R0, #1                 ; R0 = R0 - 1 (count = count - 1) and set N, Z, C status bits
	; Note: For SUBs the "s" suffix means to set the status bits, without this the loops would not exit
	
	BNE loop2
	
	EOR R3, R3, #0x02                 ;0x02 XOR 0x02 = 0x00      0x00 XOR 0x02 = 0x02        

;  five or more lines of code are needed to complete the program

; To turn off the LED(s) simply write 0 to the Port F data register
;
; Note the program is much shorter using a toggle function
; If a toggle function is not used then more than 5 lines of code are required.
; Note: a dedicated register to hold GPIO_PORTF_DATA_R can be used to save re-loading it to do the write

   	STR R3, [R1]               ; write data to Port F

; watch out - the LED must be turned on - then a delay used and then it must be turned off and another delay used.
;
; If the delay is too short the LED will look as if it is on constantly and
; if the delay is too long then the user might have to wait hours+ for it to change

	B	loop1
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                                                           ;;;;
;;;;                     ADD R4, R4, R2                        ;;;;
;;;;                                                           ;;;;
;;;;          0000 00 0 0100 0 0100 0100 00000000 0010         ;;;;
;;;;                                                           ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;
;  Setup Code for the Tiva board
;
;   DO NOT EDIT ANYTHING BELOW THIS !
;
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

GPIO_PORTF_DIR_R   EQU 0x40025400	; register to set the direction of each output pin on the port
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_PORTF_AMSEL_R EQU 0x40025528
GPIO_PORTF_PCTL_R  EQU 0x4002552C
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU   0x400FE608

;------------PortF_Init------------
; Initialize GPIO Port F for negative logic switches on PF0 and
; PF4 as the Launchpad is wired.  Weak internal pull-up
; resistors are enabled, and the NMI functionality on PF0 is
; disabled.  Make the RGB LED's pins outputs.
; Input: none
; Output: none
; Modifies: R0, R1, R2
PortF_Init
    LDR R1, =SYSCTL_RCGCGPIO_R      ; 1) activate clock for Port F
    LDR R0, [R1]                 
    ORR R0, R0, #0x20               ; set bit 5 to turn on clock
    STR R0, [R1]                  
    NOP
    NOP                             ; allow time for clock to finish
    LDR R1, =GPIO_PORTF_LOCK_R      ; 2) unlock the lock register
    LDR R0, =0x4C4F434B             ; unlock GPIO Port F Commit Register
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_CR_R        ; enable commit for Port F
    MOV R0, #0xFF                   ; 1 means allow access
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_AMSEL_R     ; 3) disable analog functionality
    MOV R0, #0                      ; 0 means analog is off
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_PCTL_R      ; 4) configure as GPIO
    MOV R0, #0x00000000             ; 0 means configure Port F as GPIO
    STR R0, [R1]                  
    LDR R1, =GPIO_PORTF_DIR_R       ; 5) set direction register
    MOV R0,#0x0E                    ; PF0 and PF7-4 input, PF3-1 output
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_AFSEL_R     ; 6) regular port function
    MOV R0, #0                      ; 0 means disable alternate function 
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_PUR_R       ; pull-up resistors for PF4,PF0
    MOV R0, #0x11                   ; enable weak pull-up on PF0 and PF4
    STR R0, [R1]              
    LDR R1, =GPIO_PORTF_DEN_R       ; 7) enable Port F digital port
    MOV R0, #0xFF                   ; 1 means enable digital I/O
    STR R0, [R1]                   
    BX  LR      

    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file

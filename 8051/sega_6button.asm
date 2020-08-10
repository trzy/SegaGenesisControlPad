;
; Sega 6-button Controller Reader
; Bart Trzynadlowski
; August 9, 2020
;
; Example of how to read out a 6-button Sega Genesis controller. Assemble with
; naken_asm.
;
; The 6-button controller uses an 8-cycle state machine (unlike 3-button
; controllers that only have two states) controlled by toggling the select
; input.
;
; This program reads out the Up button (on cycle 1) and Z button (on cycle 7).
; Two back-to-back readouts are performed and the three values (Up, Z1, Z2) are
; displayed on LEDs. They indicate that Z2 reflects Up rather than the state of
; the Z button. That is, pressing Z lights up only the middle LED while
; pressing Up lights up the first and the third.
;
; This confirms that the 6-button controller's additional buttons (X, Y, Z,
; Mode) are only returned during the first 8-cycle readout. The next 8 cycles
; appear to behave like a 3-button pad. A delay during which the select line is
; not manipulated causes the state machine to reset. Documentation suggests
; this delay should be on the order of 1.5 ms. Here, a hard-coded loop is used.
; The program was tested on an AT89C4051 clocked at 8 MHz.
;

  .8051

  .equ P1_MODE = 0x00       ; all pins output
  .equ P3_MODE = 0x02       ; p3.1 is an input
  .equ LED_STATUS = "p1.7"  ; blinking LED
  .equ LED_UP = "p1.6"      ; LED that indicates controller up state
  .equ LED_Z1 = "p1.5"      ; LED that indicates controller z state, first readout
  .equ LED_Z2 = "p1.4"      ; LED that indicates controller z state, second readout
  .equ PAD_SELECT = "p3.0"  ; controller select signal
  .equ PAD_UP = "p3.1"      ; controller up button
  .equ PAD_Z = "p3.1"       ; controller z button

  .org 0x0000   ; reset vector
  sjmp  main

  .org 0x0003   ; external 0 interrupt vector
  sjmp  dead

  .org 0x000b   ; timer 0 interrupt vector
  sjmp  dead

  .org 0x0013   ; external 1 interrupt veead

  .org 0x001b   ; timer 1 interrupt vector
  sjmp  dead

  .org 0x0023   ; serial interrupt vector
  sjmp  dead

dead:
  sjmp  dead

main:
  mov   ie, #0    ; disable interrupts
  mov   p1, #P1_MODE
  mov   p3, #P3_MODE
  setb  LED_STATUS

main_loop:
  acall read_pad
  acall blink
  acall delay
  sjmp  main_loop

read_pad:
  mov   r0, #1      ; up
  mov   r1, #1      ; z (first attempt)
  mov   r2, #1      ; z (second attempt)
  setb  PAD_SELECT  ; cycle 1
  mov   c, PAD_UP
  jc    no_up       ; up?
  mov   r0, #0
no_up:
  clr   PAD_SELECT  ; cycle 2
  setb  PAD_SELECT  ; cycle 3
  clr   PAD_SELECT  ; cycle 4
  setb  PAD_SELECT  ; cycle 5
  clr   PAD_SELECT  ; cycle 6
  setb  PAD_SELECT  ; cycle 7
  mov   c, PAD_Z
  jc    no_z1       ; z pressed on first readout?
  mov   r1, #0
no_z1:
  clr   PAD_SELECT  ; cycle 8
  setb  PAD_SELECT  ; cycle 1
  clr   PAD_SELECT  ; cycle 2
  setb  PAD_SELECT  ; cycle 3
  clr   PAD_SELECT  ; cycle 4
  setb  PAD_SELECT  ; cycle 5
  clr   PAD_SELECT  ; cycle 6
  setb  PAD_SELECT  ; cycle 7
  mov   c, PAD_Z
  jc    no_z2       ; z pressed on second readout?
  mov   r2, #0
no_z2:
  mov   a, r0
  rrc   a
  mov   LED_UP, c
  mov   a, r1
  rrc   a
  mov   LED_Z1, c
  mov   a, r2
  rrc   a
  mov   LED_Z2, c
  ret

delay:
  mov   r0, #0
  mov   r1, #0
loop:
  mov   a, r0
  add   a, #1
  mov   r0, a
  mov   a, r1
  addc  a, #0
  mov   r1, a
  cjne  r1, #0x0f, loop ; loop until r1:r0 == 0x0f00
  ret

blink:
  cpl   LED_STATUS
  ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	STOPWATCH
;
;;;;;;; Assembler directives ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        list  P=PIC18F4520, F=INHX32, C=160, N=0, ST=OFF, MM=OFF, R=DEC, X=ON
        #include <P18F4520.inc>
        __CONFIG  _CONFIG1H, _OSC_HS_1H  ;HS oscillator
        __CONFIG  _CONFIG2L, _PWRT_ON_2L & _BOREN_ON_2L & _BORV_2_2L  ;Reset
        __CONFIG  _CONFIG2H, _WDT_OFF_2H  ;Watchdog timer disabled
        __CONFIG  _CONFIG3H, _CCP2MX_PORTC_3H  ;CCP2 to RC1 (rather than to RB3)
        __CONFIG  _CONFIG4L, _LVP_OFF_4L & _XINST_OFF_4L  ;RB5 enabled for I/O
        errorlevel -314, -315          ;Ignore lfsr messages

;;;;;;; Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        cblock  0x000                  ;Beginning of Access RAM
       	COUNT                          ;Counter available as local to subroutines
		

		DELAYCOUNTER

		DIGIT:10

		numcount1
		numcount2
		numcount3
		numcount4
		numcount5
		numcount6
		
		value1
		value2
		value3
		value4
		value5
		value6

 		TMR0LCOPY               ;Copy of sixteen-bit Timer0 used by LoopTime
        TMR0HCOPY
        INTCONCOPY              ;Copy of INTCON for LoopTime subroutine

		STATUSSAVE
        WREGSAVE
		PORTASAVE
		PORTDSAVE
		PORTESAVE
		
		endc


;;;;;;; Macro definitions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MOVLF   macro  literal,dest
        movlw  literal
        movwf  dest
        endm


POINT   macro  stringname
        MOVLF  high stringname, TBLPTRH
        MOVLF  low stringname, TBLPTRL
        endm


;;;;;;; Vectors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        org  0x0000                    ;Reset vector
        nop 
        goto  Mainline

        org  0x0008                    ;High priority interrupt vector
        goto HPI                      ;Trap

        org  0x0018                    ;Low priority interrupt vector
        goto LPI                      ;Trap

;;;;;;; Mainline program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;The mainloop will last 10ms, in this 10ms each variable (second1, second10, minunt1, etc.) 
;will each decrease their value by one. the display for that specific digit will be triggered once the
;number for that variable decreases to 0. 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mainline
        rcall  Initial                 ;Initialize everything
        ;LOOP_



MAINLOOP
			
			rcall  DIGITCOUNTER

			rcall LoopTime1		;waits 10ms
		   	btg PORTE,RE2		;to check if the time is indeed what we desire

				incf value1
				decf numcount1
				bnz NUMDELAY1
						MOVLF 10, numcount1
						MOVLF 0x30, value1
						incf value2
						decf numcount2
						bnz NUMDELAY2
								MOVLF 10, numcount2
								MOVLF 0x30, value2
								incf value3
								decf numcount3
								bnz NUMDELAY3
										MOVLF 10, numcount3
										MOVLF 0x30, value3
										incf value4
										decf numcount4
										bnz NUMDELAY4
												MOVLF 6, numcount4
												MOVLF 0x30, value4
												incf value5
												decf numcount5
												bnz NUMDELAY5
														MOVLF 10, numcount5
														MOVLF 0x30, value5
														incf value6
														decf numcount6
														bnz NUMDELAY6
																MOVLF 6, numcount6
																MOVLF 0x30, value6
														NUMDELAY6
												NUMDELAY5
										NUMDELAY4
								NUMDELAY3
						NUMDELAY2
				NUMDELAY1
				

bra	MAINLOOP

PL1

;;;;;;; Initial subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine performs all initializations of variables and registers.

Initial
		MOVLF  B'00011101',ADCON0		;A/D conversion (analog input to port E2)
		MOVLF  B'10001110',ADCON1       ;Enable PORTA & PORTE digital I/O pins
        MOVLF  B'10001101',ADCON2		;right justified

		MOVLF  B'11100001',TRISA        ;Set I/O for PORTA
        MOVLF  B'11011100',TRISB        ;Set I/O for PORTB
        MOVLF  B'11010000',TRISC        ;Set I/0 for PORTC
        MOVLF  B'00001111',TRISD        ;Set I/O for PORTD
        MOVLF  B'00000000',TRISE        ;Set I/O for PORTE
        MOVLF  B'10001000',T0CON        ;Set up Timer0 for a looptime of 10 ms
        MOVLF  B'00010000',PORTA		;Turn off all four LEDs driven from PORTA
		MOVLF  B'00100000',SSPCON1		;Configure 2 reg and output pins of a particular port (PORTC) to set up SPI mode
		MOVLF  B'11000000',SSPSTAT
		MOVLF  B'00000000',PORTB 	 	;Set I/O for PORTB
		MOVLF  B'00001000',PORTD

		MOVLF  B'10000000',RCON		        
		MOVLF  B'11010000',INTCON
		MOVLF  B'11110000',INTCON2 		;bit 7 of this register should be set 1, if 0 then you obtain very weird outputs. This 
										;is due to bit 7 acting as the PORTB pull-up enable bit. What is a pull-up you ask? 
										;From wikipedia:"The pull-up resistor ensures that the wire is at a defined logic level  
										;even if no active devices are connected to it." Thus, when we tried setting the logic 
										;level high or low, it made no difference, only the act of moving the wire made initialized
										;the interrupts. The pull-up kept these ports a logic high and caused weird events. 

		MOVLF  B'10011000',INTCON3		;sets port B2 as high priority and B1 as low priority (B0 is always high priority)

		MOVLF 10, numcount1
		MOVLF 10, numcount2				;this is initialized a certain way but it doesn't matter because the value gets updated in the
		MOVLF 10, numcount3				;mainline routine.
		MOVLF 6, numcount4
		MOVLF 10, numcount5
		MOVLF 6, numcount6

		MOVLF 0x30, value1
		MOVLF 0x30, value2
		MOVLF 0x30, value3
		MOVLF 0x30, value4
		MOVLF 0x30, value5
		MOVLF 0x30, value6

		rcall  InitLCD

        return

;;;;;;; LoopTime subroutines ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Bignum  equ     65536-51250+12+2

LoopTime
        btfss  INTCON,TMR0IF    		;Wait until ten milliseconds are up OR check if bit TMR0IF of INTCON == 1, skip next line if true
        bra  LoopTime
        movff  INTCON,INTCONCOPY  		;Disable all interrupts to CPU
        bcf  INTCON,GIEH
        movff  TMR0L,TMR0LCOPY  		;Read 16-bit counter at this moment
        movff  TMR0H,TMR0HCOPY
        movlw  low  Bignum
        addwf  TMR0LCOPY,F
        movlw  high  Bignum
        addwfc  TMR0HCOPY,F
        movff  TMR0HCOPY,TMR0H
        movff  TMR0LCOPY,TMR0L 			;Write 16-bit counter at this moment
        movf  INTCONCOPY,W      		;Restore GIEH interrupt enable bit
        andlw  B'10000000'
        iorwf  INTCON,F
        bcf  INTCON,TMR0IF     			;Clear Timer0 flag
        return

;;;;;;;; 10ms count ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Bignum1  equ     65536-25000+12+2    	;10ms count

LoopTime1
        btfss  INTCON,TMR0IF    		;Wait until ten milliseconds are up OR check if bit TMR0IF of INTCON == 1, skip next line if true
        bra  LoopTime1
        movff  INTCON,INTCONCOPY  		;Disable all interrupts to CPU
        bcf  INTCON,GIEH
        movff  TMR0L,TMR0LCOPY  		;Read 16-bit counter at this moment
        movff  TMR0H,TMR0HCOPY
        movlw  low  Bignum1
        addwf  TMR0LCOPY,F
        movlw  high  Bignum1
        addwfc  TMR0HCOPY,F
        movff  TMR0HCOPY,TMR0H
        movff  TMR0LCOPY,TMR0L  		;Write 16-bit counter at this moment
        movf  INTCONCOPY,W      		;Restore GIEH interrupt enable bit
        andlw  B'10000000'
        iorwf  INTCON,F
        bcf  INTCON,TMR0IF      		;Clear Timer0 flag
        return

OneSecDelay
		MOVLF 100, DELAYCOUNTER

DELAYLOOP
		rcall LoopTime1
		;btg PORTC, RC4		
		decf DELAYCOUNTER
		bnz DELAYLOOP
		;btg PORTE, RE2			
return

;;;;;;; InitLCD subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Initialize the Optrex 8x2 character LCD.
; First wait for 0.1 second, to get past display's power-on reset time.

InitLCD
        MOVLF  10,COUNT                ;Wait 0.1 second
        ;REPEAT_
L2
          rcall  LoopTime              ;Call LoopTime 10 times
          decf  COUNT,F
        ;UNTIL_  .Z.
        bnz	L2
RL2

        bcf  PORTE,0                   ;RS=0 for command
        POINT  LCDstr                  ;Set up table pointer to initialization string
        tblrd*                         ;Get first byte from string into TABLAT
        ;REPEAT_
L3
          bsf  PORTE,1                 ;Drive E high
          movff  TABLAT,PORTD          ;Send upper nibble
          bcf  PORTE,1                 ;Drive E low so LCD will process input
          rcall  LoopTime              ;Wait ten milliseconds
          bsf  PORTE,1                 ;Drive E high
          swapf  TABLAT,W              ;Swap nibbles
          movwf  PORTD                 ;Send lower nibble
          bcf  PORTE,1                 ;Drive E low so LCD will process input
          rcall  LoopTime              ;Wait ten milliseconds
          tblrd+*                      ;Increment pointer and get next byte
          movf  TABLAT,F               ;Is it zero?
        ;UNTIL_  .Z.
        bnz	L3
RL3
        return

;;;;;;; T40 subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Pause for 40 microseconds  or 40/0.4 = 100 clock cycles.
; Assumes 10/4 = 2.5 MHz internal clock rate.

T40
        movlw  100/3                   ;Each REPEAT loop takes 3 cycles
        movwf  COUNT
        ;REPEAT_
L4
          decf  COUNT,F
        ;UNTIL_  .Z.
        bnz	L4
RL4
        return

;;;;;;;;DisplayC subroutine;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine is called with TBLPTR containing the address of a constant
; display string.  It sends the bytes of the string to the LCD.  The first
; byte sets the cursor position.  The remaining bytes are displayed, beginning
; at that position.
; This subroutine expects a normal one-byte cursor-positioning code, 0xhh, or
; an occasionally used two-byte cursor-positioning code of the form 0x00hh.

DisplayC
        bcf  PORTE,0                   ;Drive RS pin low for cursor-positioning code
        tblrd*                         ;Get byte from string into TABLAT
        movf  TABLAT,F                 ;Check for leading zero byte
        ;IF_  .Z.
        bnz	L5
          tblrd+*                      ;If zero, get next byte
        ;ENDIF_
L5
        ;REPEAT_
L6
          bsf  PORTE,1                 ;Drive E pin high
          movff  TABLAT,PORTD          ;Send upper nibble
          bcf  PORTE,1                 ;Drive E pin low so LCD will accept nibble
          bsf  PORTE,1                 ;Drive E pin high again
          swapf  TABLAT,W              ;Swap nibbles
          movwf  PORTD                 ;Write lower nibble
          bcf  PORTE,1                 ;Drive E pin low so LCD will process byte
          rcall  T40                   ;Wait 40 usec
          bsf  PORTE,0                 ;Drive RS pin high for displayable characters
          tblrd+*                      ;Increment pointer, then get next byte
          movf  TABLAT,F               ;Is it zero?
        ;UNTIL_  .Z.
        bnz	L6
RL6
        return

;;;;;;; DisplayV subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine is called with FSR0 containing the address of a variable
; display string.  It sends the bytes of the string to the LCD.  The first
; byte sets the cursor position.  The remaining bytes are displayed, beginning
; at that position.

DisplayV
        bcf  PORTE,0                   ;Drive RS pin low for cursor positioning code
        ;REPEAT_
L7
          bsf  PORTE,1                 ;Drive E pin high
          movff  INDF0,PORTD           ;Send upper nibble
          bcf  PORTE,1                 ;Drive E pin low so LCD will accept nibble
          bsf  PORTE,1                 ;Drive E pin high again
          swapf  INDF0,W               ;Swap nibbles
          movwf  PORTD                 ;Write lower nibble
          bcf  PORTE,1                 ;Drive E pin low so LCD will process byte
          rcall  T40                   ;Wait 40 usec
          bsf  PORTE,0                 ;Drive RS pin high for displayable characters
          movf  PREINC0,W              ;Increment pointer, then get next byte
        ;UNTIL_  .Z.                   ;Is it zero?
        bnz	L7
RL7
        return

;;;;;;;;CounterDisplay;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DIGITCOUNTER
		
		POINT  STOPWATCH                ;Display "STPWATCH"
       	rcall  DisplayC

		MOVLF 0xc0, DIGIT				;sets the start of the off screen 10 bit LCD display in DIGIT
		MOVLF 0x3a, DIGIT+3				;sets the colon between minutes and seconds
		MOVLF 0x3a, DIGIT+6				;sets a colon between seconds and milliseconds
		MOVLF 0x00, DIGIT+9				;sets the null terminator at the last spot on the LCD screen
	
		movff value1, DIGIT+8			;on first iteration, "0" is put into each digit spot
		movff value2, DIGIT+7
		movff value3, DIGIT+5
		movff value4, DIGIT+4
		movff value5, DIGIT+2
		movff value6, DIGIT+1

		lfsr  0,DIGIT					;This loads the linear feedback shift register 0 with the variable DIGIT. The lfsr loads
		rcall  DisplayV					;an address into one of 3 indirect addressing pointers (FSRO, FSRI, or FSR2) where FSR0
										;is used in the DisplayV subroutine. The reason why we can use FSR0 is because it's only
										;used in the ByteDisplay subroutine which is used in the DISPLAY macro, which actually
										;does not get used at all in our code.

	return

;;;;;;;;;;;;;LowPriorityInterrupt;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LPI
		movff WREG, WREGSAVE
		movff STATUS, STATUSSAVE
	
		LPIloop
			btfsc PORTD, RD3	
			bra LPIloop
		
		movff WREGSAVE, WREG
		movff STATUSSAVE, STATUS
		bcf INTCON3,INT1IF ;clear flag
RETFIE

;;;;;;;;;;;;;HighPriorityInterrupt;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HPI
		POINT screenclear1
		rcall DisplayC
		POINT screenclear2
		rcall DisplayC

		POINT RESET1
		rcall DisplayC
		rcall OneSecDelay
		rcall OneSecDelay

		MOVLF 10, numcount1
		MOVLF 10, numcount2
		MOVLF 10, numcount3
		MOVLF 6, numcount4
		MOVLF 10, numcount5
		MOVLF 6, numcount6

		MOVLF 0x30, value1
		MOVLF 0x30, value2
		MOVLF 0x30, value3
		MOVLF 0x30, value4
		MOVLF 0x30, value5
		MOVLF 0x30, value6

	
	bcf INTCON3,INT2IF ;clear flag
	retfie FAST

;;;;;;; Constant strings ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LCDstr  db  0x33,0x32,0x28,0x01,0x0c,0x06,0x00  ;Initialization string for LCD
STOPWATCH  db  "\x80STPWATCH\x00"         ;Write "STPWATCH" to first line of LCD
RESET1  db  "\x80RESET\x00"         ;Write "RESET" to first line of LCD

screenclear1 db  "\x80        \x00"			;Write "        " to second line of LCD
screenclear2 db  "\xc0        \x00"			;Write "        " to second line of LCD

        end


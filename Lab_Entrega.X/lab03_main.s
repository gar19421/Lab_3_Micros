
;-----------Laboratorio 03 Micros------------ 

; Archivo: lab03_main.S
; Dispositivo: PIC16F887
; Autor: Brandon Garrido 
; Compilador: pic-as (v2.30), MPLABX v5.45
;
; Programa: Utilizacion de timer0
; Hardware: LEDs en el puerto A - Display puerto C
;
; Creado: 16 de febrero, 2021

PROCESSOR 16F887
#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT   ; Oscillator Selection bits (RC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, RC on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
    
;------------------variables-------------------
;PSECT udata_shr ;common memory
;    contador : DS 4 ;1 byte

PSECT resVect, class=CODE, abs, delta=2

;---------------- vector reset --------------------

ORG 00h	    ;posición 0000h para el reset 
resetVec:
    PAGESEL main
    goto main
    
PSECT code, delta=2, abs
ORG 100h    ;posicion para el código

;-----------tabla---------------
 
 tabla: ; tabla de valor de pines encendido para mostrar x valor.
    clrf PCLATH
    bsf PCLATH, 0 ; PCLATH = 01 PCL = 02
    andlw 0x0f ; para solo llegar hasta f
    addwf PCL ;PC = PCLATH + PCL + W
    retlw 00111111B ;0
    retlw 00000110B ;1
    retlw 01011011B ;2
    retlw 01001111B ;3
    retlw 01100110B ;4
    retlw 01101101B ;5
    retlw 01111101B ;6
    retlw 00000111B ;7
    retlw 01111111B ;8
    retlw 01101111B ;9
    retlw 01110111B ;A
    retlw 01111100B ;B
    retlw 00111001B ;C
    retlw 01011110B ;D
    retlw 01111001B ;E
    retlw 01110001B ;F
 
;----------- Configuración -----------------------

main:
    
    call config_io ; configuraciones iniciales de I/0, reloj y TMR0
    call config_reloj
    call config_tmr0 
    
    banksel PORTA ;banco 00

;----------------loop principal--------------------
    
loop:
   movf PORTD, W  ;hacer cero al inicio
   call tabla
   movwf PORTC
    
   btfsc   PORTB, 0 ; verificar que push incremento se presione
   call    cont_1 
   btfsc   PORTB, 1 ; verificar que push decremento se presione
   call    dec_1
   btfss   T0IF
   goto    $-5	     ; ir verificando si algún push está siendo presionado
   call    reiniciar_tmr0
   incf    PORTA    ;  incrementar el contador del tmr0
      
   ;codigo de comparación
   movf PORTA, W
   subwf PORTD, W  ; se le resta al valor del puerto D el valor de A 
   ; se utiliza las banderas de zero y carry para verificar si son iguales
   movlw 10000000B ;positivo (es mayor D)
   btfsc STATUS, 2 ;bit de zero 
   movlw 11111111B ;iguales
   btfss STATUS, 0 ;bit de carry
   movlw 001B ;negativo (es mayor A)
   movwf PORTE ;encender alarma 
   
   ;reinicio del timer
   btfsc PORTE, 0
   clrf PORTA
   
   goto loop	   ;loop forever
   
   
cont_1:		; incrementar contador 1
    btfsc PORTB, 0 ; instrucción para evitar rebote del boton
    goto $-1	   ; al ser un pull down hasta que suelte el boton y cambie
    incf PORTD, F
    movf PORTD, W ; valor del conteo a W
    call tabla ; obtener equivalente en display 
    movwf PORTC ; mostrar display
  return
   
dec_1:		; decrementar contador 1
    btfsc PORTB, 1 ; instrucción para evitar rebote del boton
    goto $-1	   ; al ser un pull down hasta que suelte el boton y cambie
    decf PORTD, F
    movf PORTD, W ; decrementa el valor del puerto y lo mueve a W
    call tabla  ; posteriormente la tabla "traducira" para obtener los valores
		; para a mostrar display 
    movwf PORTC ; encender los pines del display
    
  return
  
 
; configuración de 500ms
; tiempo = (4/250e3)*(12)*(128) = 0.5s
    
config_tmr0:
    banksel TRISA
    bcf T0CS ; reloj interno
    bcf PSA ; prescaler
    bsf PS2 
    bsf PS1 
    bcf PS0 ; PS = 110 (1:128)
    banksel PORTA
    call reiniciar_tmr0
      
    return
    
 reiniciar_tmr0:
    movlw 12 ; valor de n para (256-n)
    movwf TMR0 ; delay inicial TMR0
    bcf T0IF
    
    return
   
config_reloj:
    banksel OSCCON
    bcf IRCF2 ; IRCF = 010 (250kHz) 
    bsf IRCF1
    bcf IRCF0
    bsf SCS ; reloj interno
    
    return
    
config_io:
    banksel ANSEL ;banco 11
    clrf ANSEL
    clrf ANSELH ; habilitar puertos digitales A y B
    
    banksel TRISA ;banco 0
    movlw 11110000B
    movwf TRISA	  ; primeros 4 pines en los puertos A como salidas
    clrf TRISC
    clrf TRISE ; todos los pines de los puertos C y E como salidas
    movlw 11110000B
    movwf TRISD	  ; primeros 4 pines en los puertos D como salidas
    movlw 000011B
    movwf TRISB	  ; primeros 2 pines en los puertos B como entradas
    
    banksel PORTA ; banco 00
    clrf PORTA
    clrf PORTC
    clrf PORTD
    clrf PORTE; se limpian los puertos de salida
    
    return

end
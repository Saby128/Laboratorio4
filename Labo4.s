;Encabezado
; Archivo: Lab4_Contador.s
; Dispositivo: PIC16F887 
; Autor: Saby Andrade
; Copilador: pic-as (v2.30), MPLABX v5.40
;
; Programa: 2 contadores hexadecimales  de 7 segmentos
; Hardware: Leds en el puerto A, Contadores o display en el puerto C y D
;
; Creado: 14 de febrero, 2022
; Última modificación: 19 de febrero, 2022
    
PROCESSOR 16F887

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
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

// config statements should precede project file includes.
#include <xc.inc>
  
;--------------Macros-------------------------;
RESET_tmr0 MACRO
    ;Para un incremento de cada 1000ms, seguir la siguiente fórmula
    ;Tosc=4uS
    ;Prescaler = 256
    ;Fosc = 250kHz
    ;0.1 = 4*0.000004*(256-tmr0)*256
    ;0.1 = 4*0.000004*(256-tmr0)*256
    ;24 = (256-tmr0)
    ;tmr0=178
    banksel PORTD
    movlw 178    ; Es lo que necesita para tener un impremento de 1000ms
    movwf TMR0   ; Carga el valor al TIMER0
    bcf T0IF    ; Se limpia la bandera del overflow que se dio en TIMER0
    ENDM

    
;------------Variables-------------------------;   
UP EQU 7
DOWN EQU 0
 
PSECT udata_bank0; common memory
    Conta_dor0: DS 2; 2 byte  variable que incrementa la cantidad de ciclos en TIMER0
    Conta_dor1: DS 2
    P_ort0: DS 1
    P_ort1: DS 1
    P_ort2: DS 2
    P_ort3: DS 1
    P_ortC1: DS 1
    
PSECT udata_shr ; common memory
 
    _temp_W: DS 1 ; W temporal
    temp_status_: DS 1 ;status temporal
    
    
PSECT resVect, class=CODE, abs, delta=2

;--------------Vector reset-------------------------;
ORG 00h ; posición 0000h para el reset

resetVec:
    PAGESEL main
    goto main

PSECT intVect, class=CODE, abs, delta=2

ORG 04h ; Posición para las interrupciones
 
;----------Configuración de interrupciones-----------------;

PUSH:
    movwf _temp_W   ; guarda los valores anteriores (STATUS Y W) en variables temporales
    swapf STATUS, W
    movwf temp_status_ 
    
    
ISR:
    btfsc T0IF  ; Se revisan las banderas de las interrup y se ejecutan las interrupciones
    call INTERRUP_0
    
    btfsc RBIF
    call INTERRUP_IOCB
       
POP:
    swapf temp_status_,W ;Devolvemos las variables de Status y W
    movwf STATUS
    swapf _temp_W, F
    swapf _temp_W, W
    retfie
    
;---------------Subrutinas de interrupciones-----------
INTERRUP_IOCB:
    banksel PORTA ; Vamos al banco del Puerto A
    btfss PORTB, UP ; verificar si el bit esta en 1
    incf P_ort0 ;Incrementamos en el puerto
    btfss PORTB, DOWN ;verificar si el bit esta en 0
    decf P_ort0 ; Decrece en el puerto0
    movf P_ort0, W
    andlw 00001111B
    movwf PORTA
 
    bcf RBIF
    return

INTERRUP_0:
    RESET_tmr0 ; Llamamos al macro
    incf Conta_dor0 ;Incrementamos en el  contador
    movf Conta_dor0,W
    sublw 50
    btfss ZERO
    goto _return_T0
    clrf Conta_dor0 ;Limpiamos el contador
    incf P_ort1 ; Incrementamos en la variable 
    movf P_ort1,W
    call table ;Llamamos la tabla
    movwf PORTD
    
    movf P_ort1, W
    sublw 10
    btfsc STATUS, 2
    call INCRE ;Llamamos a la subrutina
    
    movf P_ort3,W
    call table ;Llamamos a la tabla
    movwf PORTC
    
    return ;Regresamos
    
INCRE:
    incf P_ort3 ; Incrementamos en el Puerto3
    clrf P_ort1 ;Limpiamos el puerto1
    movf P_ort1,W
    call table ;Llamamos la tabla
    movwf PORTD
    
    movf P_ort3, W
    sublw 6
    btfsc STATUS, 2
    clrf P_ort3
    return

_return_T0:
    return
    
    
PSECT code, delta=2, abs
ORG 100h ; posición para el codigo

table: 
    clrf PCLATH  ; El registro de PCLATH se coloca en 0
    bsf PCLATH, 0 ; El valor del PCLATH adquiere el valor 01
    andlw 0x0f ; Se restringe el valor máximo de la tabla
    addwf PCL ; PC=PCL+PLACTH+W
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
   
main:
    call CONFIG_IO     ; se manda a llamar configuración de los pines
    call CONFIG_WATCH  ;4 Mhz
    call CONFIG_TMR0   ; Configuramos y llamamos el TIMER0
    call CONFIG_ENABLE ; Activamos las interrupciones
    call CONFIG_IOCB   ;Configuramos las interrupciones en el cambio
    
;-----------------Loop principal----------------------;
loop:
    goto loop     ; loop por siempre


;-----------------Sub rutinas----------------------;
CONFIG_IO:
    bsf STATUS, 5 ; banco 11
    bsf STATUS, 6  
    clrf ANSEL    ; Pines digitales
    clrf ANSELH

    
    bsf STATUS, 5 ; banco 01
    bcf STATUS, 6  
    clrf TRISA    ; PORT A como salida
    clrf TRISC    ; PORT C como salida
    clrf TRISD    ; PORT D como salida
    
    bsf TRISB, UP
    bsf TRISB, DOWN
    
    bcf OPTION_REG, 7 ;habilitar pull-ups
    bsf WPUB, UP
    bsf WPUB, DOWN
    
    bcf STATUS, 5 ; banco 00
    bcf STATUS, 6 
    clrf PORTA //Limpiamos puerto A
    clrf PORTC //Limpiamos puerto C
    clrf PORTD //Limpiamos Puerto D
    return

CONFIG_WATCH:
    banksel OSCCON
    ;Oscilador de 4MHz (110)
    bsf IRCF2 ; OSCCON,6  
    bsf IRCF1 ; OSCCON,5
    bcf IRCF0 ; OSCCON,4   
    bsf SCS ; reloj interno
    return

    
    
CONFIG_TMR0:
    banksel TRISD
    bcf T0CS ; reloj interno - tmr0 como contador
    
    
    bcf PSA ; prescaler a timer0
    bsf PS2
    bsf PS1
    bsf PS0 ; PS=111 - 1:256
    RESET_tmr0
    return
    
CONFIG_ENABLE:
    bsf GIE ; INTCON
    bsf T0IE
    bcf RBIE
    
    bsf T0IF
    bcf T0IF
    return
    
    
CONFIG_IOCB:
    banksel TRISA
    bsf IOCB, UP
    bsf IOCB, DOWN
    
    banksel PORTA
    movf PORTB, W   ; al leer termina la condición mismatch
    bcf RBIF
    return
    
END
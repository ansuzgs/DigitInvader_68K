*---------------------------------------------------------------------
* Program    : Digit Invaders
* Written by : Pablo G. y Kevin L.
* Date       : 11-06-2014
* Description: Implementación del famoso juego de la calculadora Casio
*---------------------------------------------------------------------

*****************************************************************************************
*           REGISTROS 
*****************************************************************************************

*A0 VARIABLE
*A1 VARIABLE
*A2 VARIABLE
*A3 VARIABLE/MOSTRAR MENSAJE POR PANTALLA
*A4 VECTOR NUMEROS ALEATORIOS
*A5 TABLA CONVERSION 7SEG
*A6 INDICADOR DEL SEG 7
*A7 STACK POINTER
*D0 VARIABLE
*D1 VARIABLE
*D2 VARIABLE
*D3 VARIABLE
*D4 NUMEROS QUE HAN SALIDO
*D5 NUMERO QUE VA A MOSTRAR
*D6 NUMERO QUE SE VA A DISPARAR
*D7 PRIMER NUMERO MOSTRADO

*****************************************************************************************
*           SUBRUTINAS Y EXCEPCIONES
*****************************************************************************************

*SR INICIALIZAR -> RESETEAR LOS VALORES PERTINENTES
*SR ALEATORIO -> GENERAR NUMEROS ALEATORIOS PARA EL VECTOR
*SR GENERARVECTOR -> GENERAR VECTOR NUM ALEATORIOS
*SR GENERAUFO -> GENERAR UFO EN MULTIPLOS DE 10 PARA LA SUMA DE LOS MATADOS
*SR PRIMNUMVEC -> PRIMER NUMERO DE UN VECTOR
*SR NEXT -> TRANSICIÓN DE UNA RONDA A LA SIGUIENTE
*SR SCORE -> CALCULAR Y MOSTRAR PUNTUACIÓN
*SR MOSTRAR -> MOSTRAR MENSAJE POR LOS 7-SEG
*SR DELAY -> RETARDO PARA MENSAJES MOSTRADOS POR 7-SEG

*EXC TECLADO
*EXC MOSTRARNUMALE

*****************************************************************************************
*           DECLARACION DE LA EXCEPCION
********************************************************************************(TECLADO)
    ORG 25*4
    DC.L TECLADO
    
*************************************************************(MUESTRA NUMEROS ALEATORIOS)
    ORG 26*4
    DC.L MOSTRARNUMALE

*****************************************************************************************
*           PROGRAMA PRINCIPAL
*****************************************************************************************
    ORG $1000
     
LAST7SEG EQU $E0000E

START
        JSR INIRND
        
        MOVE.L #62,D0
        MOVE.L #$0103,D1  ;Activa interrupción teclado al pulsar por nivel 1 
        TRAP #15
        
        MOVE.L #32, D0
        MOVE.B #5, D1     ;Habilita las excepciones
        TRAP #15
        
        MOVE.L #32, D0
        MOVE.B #0, D1     ;Muestra directamente el Hardware
        TRAP #15
        
        MOVE.L #PLAY ,A3     ;Mostrar "Play" por los 7-SEG
        JSR MOSTRAR
        
        MOVE.L #INVDISP ,A3     ;16 Invasores - 30 disparos
        JSR MOSTRAR

 
        MOVE.B #$49, $E00002  ;meter las 3 vidas iniciales
        MOVE.B #1, $6804     ; En $6804 guardamos la ronda
        MOVE.L #0, $680C     ; Inicializamos la puntuación
        MOVE.L #0, $6810     ; Inicializamos suma muertos (para sacar el UFO)
       
RONDALOOP
        
        move    #0,d1        ;Apagar música de fondo
        move    #3,d2
        move    #77,d0
        trap    #15
         
        CMP.B #16, (A0)      ;Comprobamos si se ha completado la ronda
        BEQ NEXT
INI     
        CLR.L D3
        MOVE.B #10, D1        ;Algoritmo de la velocidad de muestreo
        MOVE.B $6804, D3
        SUB.B D3, D1
        MOVE.B D1,D3
        MULU #300, D3 
        
        JSR INICIALIZAR
        MOVE.L #0, D4   ;D4 numeros que han salido
 
        JSR GENERARVECTOR
        MOVE.L #VECTOR, A4
LOOP1: 
        MOVE.L #LAST7SEG, A6
        ADD.L D4,A4
        CLR.L D5 
LOOP2:  
        MOVE.L #$6800, A0  ;Obtenemos y comprobamos el número de muertos almacenado en memoria
        CMP.B #16, (A0)
        BEQ RONDALOOP      ;Si estan todos muertos cambiamos de ronda
        CMP.L #VECTOR,A4   ;¿Están todos?
        BEQ LOOP1
        MOVE.B -(A4),D5 ;Tomamos elementos hacia atrás
        CMP.B #$FF,D5   ; ¿Está ya muerto?
        BEQ LOOP2
        CMP.L #$E00002,A6   ;Comprobamos si los invasores han alcanzado las vidas en tal caso se 
        BEQ VIDAS           ;comprueba en que situación de la partida estamos
        MOVE.B (A5,D5),(A6) ;repartimos los elementos en los visualizadores
        SUB.L #2,A6        ;apunta al display anterior  
        JSR GENERAUFO      
        BRA LOOP2         

VIDAS
        CMP.B #$00,$E00002
        BEQ FIN
        CMP.B #$8 ,$E00002
        BEQ UNAVIDA
        CMP.B #$48 ,$E00002
        BEQ DOSVIDAS
        CMP.B #$49 ,$E00002
        BEQ TRESVIDAS
UNAVIDA
        MOVE.B #$00, $E00002     ;quedaba una vida y ahora ya no quedan
        JMP RONDALOOP
        
DOSVIDAS
        MOVE.B #$8 ,$E00002      ;quedaban dos vidas y ahora sólo queda una
        JMP RONDALOOP
        
TRESVIDAS
        MOVE.B #$48 ,$E00002     ;quedaban tres vidas y ahora quedan dos vidas
        JMP RONDALOOP

FIN
        move    #0,d1        ;Apagar música de fondo
        move    #3,d2
        move    #77,d0
        trap    #15

        MOVE.L #GAMEOVER ,A3
        JSR MOSTRAR

    SIMHALT

************************************************************************************************************
*               SUBRUTINAS
****************************************************************************(Generador de números aleatorios)

	ORG	$3000
ALEATORIO
RANGO   EQU 9  ;indicamos hasta que número se puede generar    
        
OTRO    MOVE.L #RANGO,D0
        JSR LAB_RND   ;Obtiene un valor entre 0-RANGO
        RTS

INIRND                  ;Esta subrutina inicializa la semilla a partir del reloj
        MOVE.L	#8,D0
	    TRAP	#15
	    MOVE.L D1,PRNL   ; En D1 obtenemos las centesimas de segundo desde media noche
        RTS 
	
	
******** ALGORITMO  (Necesita inicializar la semilla, PRNL, con un long, y devuelve en D0 el número pseudoaleatorio 16 bits)
LAB_RND 
        MOVEM.L D1-D3,-(A7) ;guarda registros utilizados

        MOVE.L D0,D1
        ADD.L #1,D1       * calculamos el rango para un valor más (luego lo eliminamos)
        MOVE.L #$FFFF,D0
        DIVU D1,D0        * obtiene el factor de escala rango
        AND.L #$FFFF,D0   * elimina resto
        ADD.L #1,D0       * sumamos 1 al factor de escala para eliminar el posible valor de más
        MOVE.L D0,D3      * pasamos factor de escala a D3   
        
	    MOVE.L	PRNL,D0		* get current seed longword
	    MOVEQ		#$AF-$100,d1		* set EOR value
	    MOVEQ		#19,d2			* do this 19 times
Ninc0
	    ADD.L		d0,d0				* shift left 1 bit
	    BCC.S		Ninc1				* if bit not set skip feedback

	    EOR.B		D1,D0				* do Galois LFSR feedback
Ninc1
	    SUBQ #1,D2
	    BNE 		Ninc0			* loop

	    MOVE.L	D0,PRNL		* save back to seed longword
	
	    SWAP D0		 ;Obtiene la palabra alta
	    AND.L #$FFFF,D0  ;Se queda con esa palabra 0-65535
        
        DIVU D3,D0       ;aplicamos factor de escala   	 
	    AND.L #$FFFF,D0  ;Se queda con el cociente (solo 16 bits)
	    MOVEM.L (A7)+,D1-D3
        RTS
        
        
*****************************************************************************(INICIALIZAR)

INICIALIZAR

        *Cargamos sonido de fondo
        lea     base,a1              
        move    #0,d1               
        move    #74,d0
        trap    #15 
        
        *Reproducimos sonido de fondo
        move    #0,d1            
        move    #0,d2
        move    #77,d0
        trap    #15
        
        MOVE.L #TABLA, A5    
        MOVE.L #0,D6
        MOVE.B #$3F, $E00000
        MOVE.B #$FF,$E00010 
        
        MOVE.L #32, D0
        MOVE.B #6, D1
        MOVE.B #%10000010, D2   ;Habilita la excepcion automatica temporal 2
        ;no metemos nada en D3 porque lo hemos hecho en el algoritmo de velocidad
        TRAP #15

        CLR.B $E00004    ;limpiamos los leds
        CLR.B $E00006
        CLR.B $E00008
        CLR.B $E0000A
        CLR.B $E0000C
        CLR.B $E0000E
        
        MOVE.B #0, $6800  ;Iniciamos numero de muertos
        MOVE.B #0, $6808  ;Inicializamos número de disparos
        
        RTS

*****************************************************************************(NEXT ROUND)   

NEXT
         *Reproducir musica ronda
         move    #2,d1            
         move    #0,d2
         move    #77,d0
         trap    #15
        
         MOVE.B $E00002,-(A7)   ;guardamos en pila las vidas
         MOVE.L #SCORE, A3      ;mostramos la puntuación
         JSR MOSTRAR 
         JSR SCORE1
         MOVE.L #ROUND, A3      ;indicamos que pasamos de ronda
         JSR MOSTRAR
         MOVE.B (A7)+,$E00002   ;recuperamos las vidas de la pila
         ADD.B #1,$6804         ;incrementamos el número de ronda
         JMP INI
         
SCORE1
         CLR.B $E00000     ;limpiamos los leds
         CLR.B $E00002
         CLR.B $E00004
         CLR.B $E00006
         CLR.B $E00008
         CLR.B $E0000A
         CLR.B $E0000C
         CLR.B $E0000E
         
         MOVE.L $680C,D0    ;cargamos la puntuacion de la memoria
         DIVU #10,D0        ;extraemos las unidades y las mostramos por el led 8vo
         SWAP D0
         MOVE.B (A5,D0),$E0000E
         MOVE.W #0,D0
         SWAP D0
         
         CMP.W #0,D0        ;si ya no hay mas que mostrar dejamos los leds apagados y volvemos
         BEQ RETORNO
         DIVU #10,D0        ;extraemos las decenas y las mostramos por el led 7vo
         SWAP D0
         MOVE.B (A5,D0),$E0000C
         MOVE.W #0,D0
         SWAP D0
         
         CMP.W #0,D0       ;idem que las anteriores hasta llegar al 1er led
         BEQ RETORNO
         DIVU #10,D0
         SWAP D0
         MOVE.B (A5,D0),$E0000A
         MOVE.W #0,D0
         SWAP D0
         
         CMP.W #0,D0
         BEQ RETORNO
         DIVU #10,D0
         SWAP D0
         MOVE.B (A5,D0),$E00008
         MOVE.W #0,D0
         SWAP D0
         
         CMP.W #0,D0
         BEQ RETORNO
         DIVU #10,D0
         SWAP D0
         MOVE.B (A5,D0),$E00006
         MOVE.W #0,D0
         SWAP D0
         
         CMP.W #0,D0
         BEQ RETORNO
         DIVU #10,D0
         SWAP D0
         MOVE.B (A5,D0),$E00004
         MOVE.W #0,D0
         SWAP D0
         
         CMP.W #0,D0
         BEQ RETORNO
         DIVU #10,D0
         SWAP D0
         MOVE.B (A5,D0),$E00002
         MOVE.W #0,D0
         SWAP D0
         
         CMP.W #0,D0
         BEQ RETORNO
         DIVU #10,D0
         SWAP D0
         MOVE.B (A5,D0),$E00000
         MOVE.W #0,D0
         SWAP D0
RETORNO     
         JSR DELAY     ;dejamos un tiempo para visualizar la puntuación
         RTS         
    
********************************************************(GENERAR VECTOR NUMEROS ALEATORIOS)
GENERARVECTOR:
        MOVE.L #VECTOR, A1           
        MOVE.B #0, D2    ;contador de cuántos numeros llevamos generados
BUCLE         
        JSR ALEATORIO       ;guarda en D0 el numero aleatorio
        MOVE.B D0, (A1)+    ;genera y mete en el vector 16 numeros (invasores)
        ADD.B #1, D2
        CMP #16, D2
        BEQ VOLVER
        JMP BUCLE
           

VOLVER
        MOVE.B #11,(A1)+   ;Rellanamos de 0s para mostrar los blancos en el último invasor
        MOVE.B #11,(A1)+
        MOVE.B #11,(A1)+
        MOVE.B #11,(A1)+
        MOVE.B #11,(A1)+
        MOVE.B #11,(A1)
           
        MOVE.B #0, D2      
        RTS

**************************************************************************(GENERAR EL UFO)

GENERAUFO
        MOVE.L $6810,D0
        CMP.B #10,(A4,D4)
        BEQ RETURN
        CMP.B #10,D0
        BGT RETURN
        BLT VUELTA
        ADD.B #1, D4
        MOVE.B #10,(A4,D4)
        SUB.B #1, D4
        
RETURN
        SUB.B #10,D0
        MOVE.L D0, $6810
        RTS           
           
********************************************************************(PRIMER NUMERO VECTOR)
PRIMNUMVEC:
        MOVE.B (A4)+, D7    ;busca cual es la posicion del vector que se encuentra
        CMP.L #$FF, D7      ;el primer invasor no muerto (se queda en A4)
        BEQ PRIMNUMVEC
        SUB.L #1, A4
        RTS

********************************************************(MOSTRAR MENSAJES POR LOS DISPLAYS)        
MOSTRAR
    

    MOVE.B (A3)+,$E00000        ;Muestra por los displays el mensaje que tengamos guardado
    MOVE.B (A3)+,$E00002        ;y comience en la dirección guardada en A3  (TAMAÑO .B)
    MOVE.B (A3)+,$E00004
    MOVE.B (A3)+,$E00006
    MOVE.B (A3)+,$E00008
    MOVE.B (A3)+,$E0000A
    MOVE.B (A3)+,$E0000C
    MOVE.B (A3)+,$E0000E    
DELAY
    MOVE.L #23,D0 
    MOVE.L #200,D1   ;Retardo de 2 segundos
    TRAP #15
    
    RTS
   

******************************************************************************************
*           EXCEPCIONES
************************************************************************(EXCEPCIÓN TECLADO)

TECLADO:    ORG    $5000
                  ; first instruction of program

CTRL    EQU $11  ;ver Key Codes en HELP Task 19
ALT     EQU $12 
SPACE   EQU $20


    move.b #19,d0
    move.l #SPACE<<8+CTRL,d1 ;Monitorizamos CTRL y ESPACIO
                             ;Se pueden monitorizar hasta 
                             ;4 teclas a la vez mediante
                             ;CODE4<<24+CODE3<<16+CODE2<<8+CODE1
    trap #15
    
    BTST #0,D1
    BNE CONTROL
    BTST #8,D1
    BNE SPC
    
    *Si no hay ninguna pulsada procede a borrar la información*
    *escribiendo espacios encima del texto existente*
    
    MOVE.L #10<<8+10,D1 ;Coordenada 10,10. Mete $0A0A en D1
    MOVE.L #11,D0       ;Task 11 posiciona el cursor
    TRAP #15
    MOVE.L #14,D0
    MOVE.L #VACIO,A1
    TRAP #15            ;borra si no hay pulsadas
    
    RTE 
 
SPC 
    *************************************
    MOVE.L #20<<8+10,D1 ;coordenada 20,10
    MOVE.L #11,D0
    TRAP #15
    *************************************

    *Cargamos el sonido del laser de disparo
    lea     laser,a1              
    move    #1,d1                
    move    #74,d0
    trap    #15 
    
    MOVE.L A4,-(A7)     ;guardamos el valor de A4 que apunta al principio del vector
    ADD.B #1,$6808      ;incrementamos en 1 el numero de disparos realizados
    JSR RECALENTARARMA  ;comprobamos el estado de la munición
    CMP.B #32,$6808     ;si queda munición seguimos matando sino volvemos
    BLT SIGUEMATANDO
    MOVE.L (A7)+,A4     ;recuperamos el valor de A4 que apunta al principio del vector
    RTE
    
SIGUEMATANDO

    *Reproduce el sonido del disparo (sólo mata si tenemos munición)
    move    #1,d1            
    move    #0,d2
    move    #77,d0
    trap    #15
    
    MOVE.L #VECTOR, A4    
    JSR PRIMNUMVEC       
    CMP.B D6, D7      ;si el numero del objetivo es el mismo que el primero del vector matamos
    BEQ MATAR
    MOVE.L (A7)+,A4
    RTE
    
MATAR:    

    ADD.L D6,$6810       ;Sumamos para calcular el UFO

    MOVE.B #$FF, (A4)    ;Marcamos como muerto
    MOVE.L #$6800, A0    ;En $6800 guardamos el numero de muertos
    ADD.B #1,(A0)          
    MOVE.B $E00000,D0    ;Cogemos el numero objetivo
    
    MOVE.B $E00004,D1    ;comparamos el objetivo con cada display para ver donde esta el que se va a matar
    CMP.B D1,D0 
    BEQ MATAR_4
    
    MOVE.B $E00006,D1
    CMP.B D1,D0
    BEQ MATAR_6

    MOVE.B $E00008,D1
    CMP.B D1,D0
    BEQ MATAR_8
    
    MOVE.B $E0000A,D1
    CMP.B D1,D0
    BEQ MATAR_A
    
    MOVE.B $E0000C,D1
    CMP.B D1,D0
    BEQ MATAR_C

    MOVE.B $E0000E,D1
    CMP.B D1,D0
    BEQ MATAR_E
    
    MOVE.L (A7)+,A4
    RTE

RECALENTARARMA
    CMP.B #33,$6808            ;vemos si ya se ha gastado toda la munición
    BEQ VUELTA
    MOVE.B $6808,D0            ;vemos el numero de disparos
    DIVU.W #4,D0               ;decrementamos un led si el numero de disparos es multipo de 4
    SWAP D0
    CMP.W #0,D0                ;miramos si el resto es 0 para asegurarnos
    BNE VUELTA
    MOVE.B $E00010,D0          
    LSL.L #1,D0                ;desplazamos hacia la izquierda haciendo el efecto de que se apaga un led
    MOVE.B D0,$E00010
    
VUELTA
    RTS   

*************************************(FUNCIONES QUE MATAN)********
       
MATAR_4
    CMP.B #$54 , $E00004        ;vemos si es un ufo para matarlo de formar especial
    JSR MATAUFO
    MOVE.B #$00,$E00004         ;limpiamos el led
    MOVE.L (A7)+,A4             ;recuperamos el valor de A4 guardado antes
    ADD.L #10,$680C             ;incrementamos la puntuación correspondiente
    RTE
    
MATAR_6
    CMP.B #$54, $E00006         ;idem en el led siguiente
    JSR MATAUFO
    MOVE.B #$00,$E00006
    MOVE.L (A7)+,A4
    ADD.L #20,$680C
    RTE
    
MATAR_8
    CMP.B #$54, $E00008
    JSR MATAUFO
    MOVE.B #$00,$E00008
    MOVE.L (A7)+,A4
    ADD.L #30,$680C
    RTE
    
MATAR_A
    CMP.B #$54, $E0000A
    JSR MATAUFO
    MOVE.B #$00,$E0000A
    MOVE.L (A7)+,A4
    ADD.L #40,$680C
    RTE
    
MATAR_C
    CMP.B #$54, $E0000C
    JSR MATAUFO
    MOVE.B #$00,$E0000C
    MOVE.L (A7)+,A4
    ADD.L #50,$680C
    RTE
    
MATAR_E
    CMP.B #$54, $E0000E
    JSR MATAUFO
    MOVE.B #$00,$E0000E
    MOVE.L (A7)+,A4
    ADD.L #60,$680C
    RTE
    
MATAUFO
    BEQ SUMAUFO
VOLVERMATAR    
    RTS
    
SUMAUFO
    ADD.L #300,$680C
    JMP VOLVERMATAR
*********************************************************************    
    
CONTROL

    *************************************
    MOVE.L #10<<8+10,D1 ;coordenada 10,10
    MOVE.L #11,D0
    TRAP #15
    *************************************
    ADD.L #1, D6
    CMP.L #11, D6
    BEQ INICIALIZAD6
    
CONTINUA:
    MOVE.B (A5,D6), $E00000
    RTE

INICIALIZAD6
    MOVE.L #0,D6
    JMP CONTINUA
    
*****************************************************(EXCEPCION MUESTRA NUMEROS ALEATORIOS)
MOSTRARNUMALE
    ADD.L #1, D4     ;incrementamos de uno en uno el numero de invasores que aparecen para ir mostrándolos
    RTE

            ORG $4000
        
TABLA   DC.B $3F DIGITO 0
        DC.B $06 DIGITO 1
        DC.B $5B DIGITO 2
        DC.B $4F DIGITO 3
        DC.B $66 DIGITO 4
        DC.B $6D DIGITO 5
        DC.B $7D DIGITO 6
        DC.B $07 DIGITO 7
        DC.B $7F DIGITO 8
        DC.B $6F DIGITO 9 
        DC.B $54 UFO   10
        DC.B $00 VACIO 11

* Put variables and constants here
VACIO   DC.B '                      ',0   
base    dc.b    'base.wav',0
laser   dc.b    'laser.wav',0

PRNL	DS.L 1          ;Esta variable global sirve para el funcionamiento del algoritmo RANDOM

NUMDIG DC.B 9

PLAY  DC.B $00,$00,$73,$38,$77,$6E,$00,$00,0
GAMEOVER DC.B $7D,$77,$37,$79,$3F,$3E,$79,$50,0
ROUND  DC.B $3E,$73,$00,$50,$5C,$1C,$54,$5E,0 
SCORE DC.B $6D,$39,$3F,$50,$79,$00,$00,$00,0
INVDISP DC.B $00,$00,$00,$06,$7D,$40,$4F,$5B,0   ;_ _ _16-32 

            ORG $6000
VECTOR  DS.B 22
	END START	; last line of source

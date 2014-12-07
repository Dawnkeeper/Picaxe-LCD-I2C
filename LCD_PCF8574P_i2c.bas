' Programm für die Anbindung eines LCD an Picaxe 08M2 über I2C-Modul
' benutzte Hardware: LCD-I2C_Modul  Bestellnr.: 810 145
' 		   LCD TC1602E-01 Bestellnr.: 120 420  bei Pollin
' 		   PICaxe 08M2
'
' erstellt am 28.10.2014
' von: Thomas Stiegler
' schema:
'
'  +---------------------------------------------------------------+
'  |                                                               |
'  | LCD DISPLAY    Hitachi HD44780 Standard                       |
'  |                                                               |
'  | 1   2   3   4   5   6   7   8   9   10  11  12  13  14 15  16 |
'  +-+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+-+
'    |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
'   GND V+  CNT  RS  RW  E   D0  D1  D2  D3  D4  D5  D6  D7  LV+ LGND
'    |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |  
'    =   +5  |   |   |   |                   |   |   |   |
'    |   +-+ |   |   |   |                   |   |   |   |
'    |     < |   |   |   |                   |   |   |   |
'    | 10K ><+   +------------------+        |   |   |   |
'    |     <         +----------+   |        |   |   |   |
'    +-----+             |      |   |        |   |   |   |
'                        |      |   |        |   |   |   |
'                        |      |   |        |   |   |   |
'                        |      |   |        |   |   |   |
'                        |      |   |        |   |   |   |
'     zu Picaxe I2C   BL |      |   |        |   |   |   |   BL=Hintergrundbeleuchtung
'           ^   ^     ^  |      |   |        |   |   |   |
'       +5  |   |     |  +--+   |   |        |   |   |   |
'       |   |   |   | +-+   |   |   |        |   |   |   |
'     +-+---+---+---+---+---+---+---+-+      |   |   |   |
'     | V+ SDA SCD INT  P7  P6  P5  P4|      |   |   |   |
'     |                               |      |   |   |   |
'      D    PCF8574 port expander     |      |   |   |   |
'     |                               |      |   |   |   |
'     | A0  A1  A2  P0  P1  P2  P3 GND|      |   |   |   |
'     +-+---+---+---+---+---+---+---+-+      |   |   |   |
'       |   |   |   |   |   |   |   |        |   |   |   |
'       +---+---+   |   |   |   +------------------------+
'       |           |   |   +------------------------+
'      gnd          |   +------------------------+
'                   +------------------------+
'
'
'
'
'           name - 8574 bit   -     LCD
'          ------  --------       ---------------
    SYMBOL  DB4       = 0         ; LCD Data Line 4 (pin 11)
    SYMBOL  DB5       = 1         ; LCD Data Line 5 (pin 12)
    SYMBOL  DB6       = 2         ; LCD Data Line 6 (pin 13)
    SYMBOL  DB7       = 3         ; LCD Data Line 7 (pin 14)
    SYMBOL  RS        = 4         ; 0 = Command   1 = Data (pin 4)
    Symbol  RW        = 5         ; LCD Pin 5 (0=Daten schreiben 1=Daten lesen)
    SYMBOL  E         = 6         ; 0 = inaktiv      1 = aktive (pin 6) 	->bei Pollin ist P6 mit E verbunden
    Symbol  BL	= 7	 ; Hintergrundbeleuchtung 0=aus 1= an
   
    SYMBOL  Addr8574  = $40       ; das ist 8574 I2C addresse entsprechend der 3 Jumper
                                  ; A2=A1=A0=0 <-> x100 000x
                                 
    SYMBOL  RSCMDmask = %00000000 ; Select Command register
    SYMBOL  RSDATmask = %00010000 ; Select Data register = High P4 on 8574
    SYMBOL  Emask     = %11000000 ; am 8574: BL(7)=on; RS=1; RW(5)=0 für schreiben

    SYMBOL  temp  = b11
    SYMBOL  aByte = b12
    SYMBOL  rsbit = b13
    SYMBOL  index = b14

main:
    GOSUB InitialiseLcd     ; Initialise the LCD

mainloop:   
   
    aByte = $01 'clear
    GOSUB SendCmdByte
   
       
    aByte = 2 * 8 | $40      ; Beispiel für selbstdefinierte Zeichen: Character 2
    GOSUB SendCmdByte
    aByte = %11100 : GOSUB SendDataByte    ; ### 
    aByte = %10010 : GOSUB SendDataByte    ; #  #
    aByte = %10010 : GOSUB SendDataByte    ; #  #
    aByte = %11100 : GOSUB SendDataByte    ; ###
    aByte = %10001 : GOSUB SendDataByte    ; #   #
    aByte = %10000 : GOSUB SendDataByte    ; #
    aByte = %10010 : GOSUB SendDataByte    ; #  #
    aByte = %10010 : GOSUB SendDataByte    ; #  #
   
    aByte = 2                ; ablegen unter: Character 2
    GOSUB SendCmdByte        
   
   ;hier Textausgaben
    for b0 = 0 to 15
        lookup  b0,("I2C-Expander mit"),aByte
        GOSUB SendDataByte
    next b0
   
    aByte = $80 | $40        ; cursor auf Startposition der Zeile 2
    GOSUB SendCmdByte

    wait 1
    for b0 = 0 to 10
        lookup b0,("Picaxe 08M2"),aByte
        GOSUB SendDataByte
    next b0
   
    wait 3

    aByte = $80 | $4D        ; cursor auf Line 2 pos. 13
    GOSUB SendCmdByte
    aByte = 2                ; Display User Defined Character 2
    GOSUB SendDataByte
    wait 9
    aByte = 1
    GOSUB SendCmdByte
   
goto mainloop


'  INITIALIZE LCD
' -----------------------------------------------------------------
'
InitialiseLcd:

    ' initialize I2C
    i2cslave Addr8574, i2cslow, i2cbyte

    for index = 0 TO 5
      read index,aByte
      gosub SendInitCmdByte
    next
   
    ' HD44780 commandos - zum initialisieren 4-bit mode siehe auch http://www.mikrocontroller.net/articles/HD44780
   
    eeprom 0,( $33 )    ; %0011---- %0011----   8-bit / 8-bit
    eeprom 1,( $32 )    ; %0011---- %0010----   8-bit / 4-bit
   
    ' Byte commandoss - zum configurieren des LCD
   
                        ;
                        ; Display Format
                        ; 4bit mode, 2 lines, 5x7
                        ;
                        ;  001LNF00
    eeprom 2,( $28 )    ; %00101000
                        ; L : 0 = 4-bit Mode    1 = 8-bit Mode
                        ; N : 0 = 1 Line        1 = 2 Lines
                        ; F : 0 = 5x7 Pixels    1 = N/A
   
                        ;
                        ; Setup Display
                        ; Display ON, Cursor On, Cursor stehend
                        ;
                        ;  00001DCB
    eeprom 3,( $0E )    ; %00001110
                        ; D : 0 = Display Off   1 = Display On
                        ; C : 0 = Cursor Off    1 = Cursor On
                        ; B : 0 = Cursor steht  1 = Cursor blinkt
   
                        ;
                        ; Setup Cursor/Display
                        ; Inc Cursor Cursor Move
                        ;
                        ;  000001IS
    eeprom 4,( $06 )    ; %00000110 %000001IS   Cursor Move
                        ; I : 0 = Dec Cursor    1 = Inc Cursor
                        ; S : 0 = Cursor Move   1 = Display Shift
   
    eeprom 5,( $01 )    ; Clear Screen
   
return

' SEND INIT CMD BYTE - SEND CMD BYTE - SEND DATA BYTE
' -----------------------------------------------------------------
'
SendInitCmdByte:

    pause 15                        ; 15 ms bei 4MHz

SendCmdByte:

    rsbit = RSCMDmask               ; Senden zum Commandoregister

SendDataByte:

    '
    ' Ausgabe obere 4bit zuerst
    ' via I2C
    '
    temp = aByte /16
    temp = temp | rsbit
    ;debug
    gosub DirectSendCmd
    '
    ' Augabe untere 4bit
    '
    temp = aByte & $0F
    temp= temp | rsbit
    rsbit = RSDATmask               ; Senden zum Datenregister

DirectSendCmd:
    temp = temp xor Emask            ' E=1
    writei2c (temp)                    ' senden zum 8574 via I2C
    temp = temp xor Emask            ' E=0
    writei2c (temp)
return
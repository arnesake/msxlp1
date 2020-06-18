;-------------------------------------------------------------------------------
; Project: MSX_LCD2.zdsp
; Main File: MSX_LCD2.asm
; Date: 7/3/2020 13:47:31
;
; Created with zDevStudio - Z80 Development Studio.
;
;-------------------------------------------------------------------------------
; Ultimas alteracoes:
;
; em 07/03/2020:
;    - criado esse programa
;
;-------------------------------------------------------------------------------
;
                org     0C100H          ;endereco inicial do programa

;-------------------------------------------------------------------------------
; Declara enderecos das rotinas do MSX
;
CHPUT:          equ     00A2H           ;rotina que permite escrever na tela
LPTOUT:         equ     00A5H           ;rotina que permite enviar um char para LPT

;-------------------------------------------------------------------------------
; Declara enderecos das portas do MSX a serem utilizadas aqui
;
LPTDT:          equ     0091H           ;endereco para out na linha de dados para LPT
LPTST:          equ     0090H           ;endereco do strob/busy na linha de dados para LPT
STROBE:         equ     0001H           ;bit para ativar o STROB - bit0
BUSY:           equ     0002H           ;bit para ler o BUSY - bit1

;-------------------------------------------------------------------------------
; Declara constantes
;
CR:             equ     0DH             ;ENTER
LF:             equ     0AH             ;Line Feed
RS_ON:          equ     01H             ;bit de controle RS do LCD
RS_OFF          equ     0FEH            ;bit de controle RS do LCD invertido

;-------------------------------------------------------------------------------
; Declara espaco para vars
;
tamstr          db      0               ;tamanho da string
strlsb:         db      0               ;endereco da string
strmsb:         db      0
cptamstr:       db      0               ;copia do tamanho da string

myout           DB      0               ;var de saida para LPT - dados
mystrb          DB      0               ;var de saida para LPT - controle (STB)

mydata          DB      0               ;var para colocar dados no LCD

mycount1        DB      0               ;vars para contador
mycount2        DB      0

myaux           DB      0               ;var auxiliares
myaux2          DB      0
myaux3          DB      0

;-------------------------------------------------------------------------------
; Le string passada pelo BASIC para ser inserida no LCD
;
                ;push af
                ;push bc
                ;push de
                ;push hl
                ;push ix
                ;push iy

                cp      03H             ;eh string
                ret     nz              ;nao, retorna
                ex      de,hl           ;HL->descritor
                ld      a,(hl)          ;aqui tamanho da str
                ld      bc,tamstr       ;pega end da var
                ld      (bc),a          ;carrega tam. str

                ld      bc,strlsb       ;pega var para end
                inc     hl              ;
                ld      a,(hl)          ;lsb do end da str
                ld      (bc),a          ;carrega end lsb

                ld      bc,strmsb       ;pega var para msb
                inc     hl
                ld      a,(hl)          ;msb do end da str
                ld      (bc),a          ;carrega end msb

;-------------------------------------------------------------------------------
; inicia outras variaveis
;
                ld      hl,mystrb       ;carrega endereco em hl
                ld      a, 01H
                ld      (hl),a          ;guarda zero em myxor

                ld      hl,myout        ;carrega HL com endereco myout
                ld      a, 00H         ;carrega valor
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,mydata       ;carrega end da var
                ld      (hl),a          ;zera var...

                ld      hl,myaux        ;carrega HL com endereco myaux
                ld      (hl),a          ;zera var

                ld      hl,myaux2       ;carrega HL com endereco myaux2
                ld      (hl),a          ;zera var

                ld      hl,myaux3       ;carrega HL com endereco myaux3
                ld      (hl),a          ;zera var

                ld      hl,tamstr       ;copia tamanho da string
                ld      a,(hl)
                ld      hl,cptamstr     ;pega end da var copia
                ld      (hl),a          ;carrega tamanho na copia

;-------------------------------------------------------------------------------
; Subrotina principal
;
main:           call    initLCD         ;configura LCD
                call    clearLCD
                call    sendstr         ;envia string para tela / LCD

;-------------------------------------------------------------------------------
; Retorno para o BASIC
;
                ;pop     iy
                ;pop     ix
                ;pop     hl
                ;pop     de
                ;pop     bc
                ;pop     af

                ret                    ;retorna para o BASIC

;----------------------------------------------------
; subrotina para enviar string para a tela
;
sendstr:        ld      hl,tamstr       ;pega tam string
                ld      b,(hl)          ;b tem o tamanho

                ld      hl,strlsb       ;pega end lsb da str
                ld      e,(hl)
                ld      hl,strmsb       ;pega end msb da str
                ld      d,(hl)          ;DE tem o end da str

                inc     b               ;incrementa tam da str
                call    snd2SPC         ;insere espacos dumies
                call    snd2SPC         ;para evitar problema com o inicio
                                        ;do LCD

sndstrlc:       dec     b               ;decrementa, se zero fim da string
                ret     z               ;retorna se flag ativado

                push    de
                push    bc

                ld      hl,mydata       ;pega o endereco da var para LCD
                ld      a,(de)          ;carrega a com byte da string
                ld      (hl),a          ;carrega em mydata

                cp      '\'             ;compara com barra
                jp      nz,sndcont      ;se nao, continua
                call    CRLFtela        ;envia um CR+LF para a tela
                call    lin2LCD         ;muda para linha 2 do LCD
                jr      fsndstrlc

sndcont:        call    CHPUT           ;imprime na tela
                call    schLCD          ;envia char para LCD

fsndstrlc:      pop     bc
                pop     de
                inc     de              ;incrementa o ponteiro
                jr      sndstrlc        ;continua ate o fim

;-------------------------------------------------------------------------------
; Envia dois caracteres dummies antes de enviar uma string
;
snd2SPC:        push    de
                push    bc
                push    hl

                ld      hl,mydata
                ld      a,' '
                ld      (hl),a
                call    schLCD
                ld      hl,mydata
                ld      a,' '
                ld      (hl),a
                call    schLCD

                pop     hl
                pop     bc
                pop     de

                ret

;-------------------------------------------------------------------------------
; Envia um char para o LCD - usa modo 4 bits
;
schLCD:         ld      hl,mydata       ;pega endereco da var
                ld      a,(hl)          ;pega o conteudo
                and     0F0H            ;limpa a parte menos significativa
                or      RS_ON           ;liga o pino de RS

                ld      hl,myout        ;carrega endereco da var
                ld      (hl),a          ;carrega o conteudo
                call    sndlpt          ;envia dado para a porta
                call    strobe_on       ;liga o pino de strobe - pulsa EN
                call    _10us           ;aguarda
                call    strobe_off      ;desliga o pino de strobe

                ld      hl,mydata       ;volta a pegar o end da var
                ld      a,(hl)          ;pega o conteudo
                sla     a               ;posiciona o LSB no MSB
                sla     a
                sla     a
                sla     a
                and     0F0H            ;limpa o LSB
                or      RS_ON           ;liga o RS

                ld      hl,myout        ;carrega endereco da var
                ld      (hl),a          ;carrega o conteudo
                call    sndlpt          ;envia para porta
                call    strobe_on       ;liga o pino de strobe - pulsa EN
                call    _10us           ;aguarda
                call    strobe_off      ;desliga o pino de strobe

                ret

;-------------------------------------------------------------------------------
; Envia um comando para o LCD - usa modo 4 bits de dados
;
scomLCD:        ld      hl,mydata       ;pega endereco da var
                ld      a,(hl)          ;pega o conteudo
                and     0F0H            ;limpa a parte menos significativa
                and     RS_OFF          ;desliga o pino de RS

                ld      hl,myout        ;carrega endereco da var
                ld      (hl),a          ;carrega o conteudo
                call    sndlpt          ;envia dado para a porta
                call    strobe_on       ;liga o pino de strobe - pulsa EN
                call    _10us           ;aguarda
                call    strobe_off      ;desliga o pino de strobe

                ld      hl,mydata       ;volta a pegar o end da var
                ld      a,(hl)          ;pega o conteudo
                sla     a               ;posiciona o LSB no MSB
                sla     a
                sla     a
                sla     a
                and     0F0H            ;limpa o LSB
                and     RS_OFF          ;liga o RS

                ld      hl,myout        ;carrega endereco da var
                ld      (hl),a          ;carrega o conteudo
                call    sndlpt          ;envia para porta
                call    strobe_on       ;liga o pino de strobe - pulsa EN
                call    _10us           ;aguarda
                call    strobe_off      ;desliga o pino de strobe

                ret

;-------------------------------------------------------------------------------
; Subrotina para configurar/iniciar o LCD  - RS=0 e WR=0
; Le bytes em _initlcd e envia via porta paralela
; Configuracao adotada: modo 4 bits de dados, 2 linhas, caracter 5x7, cursor piscando
;
initLCD:        ld      a,00H           ;sao 5 bytes a enviar, comecando por zero
                ld      hl,myaux3       ;carrega endereco
                ld      (hl),a          ;guarda

initLCDloop:    ld      de,myaux3       ;pega o endereco da var
                ld      b,00H           ;zera a var
                ld      a,(de)          ;pega o conteudo de myaux3
                ld      c,a             ;carrega em c

                ld      hl,_inilcd      ;carrega endereco da var de configuracao
                add     hl,bc           ;posiciona o ponteiro
                ld      a,(hl)          ;pega primeiro byte
                ld      hl,mydata       ;pega endereco da var
                ld      (hl),a          ;coloca valor na var

                call    scomLCD         ;envia o comando para o LCD

                ld      hl,myaux3       ;carrega endereco
                ld      a,(hl)          ;pega conteudo
                inc     a               ;decrementa a
                ld      (hl),a          ;guarda conteudo
                cp      05H             ;compara com final - sao 7 comandos agora
                jp      nz,initLCDloop  ;se nao eh ainda o valor

                ret                     ;detectado fim, retorna!

                ld      hl,mydata       ;coloca na var o char a ser escrito
                ld      a,0C0H          ;pula de linha
                ld      (hl),a

;-------------------------------------------------------------------------------
; Subrotina para mudar para linha 2 do LCD
;
lin2LCD:        push    de              ;salva a pos da string
                push    bc              ;salva o tamanho
                push    hl

                ld      hl,mydata       ;coloca na var o char a ser escrito
                ld      a,0C0H          ;apaga LCD e coloca na coluna 1
                ld      (hl),a
                call    scomLCD         ;muda de linha no LCD

                pop     hl
                pop     bc              ;restaura tamanho
                pop     de              ;restaura pos da string

                ret
;-------------------------------------------------------------------------------
; Subrotina para apagar o LCD
;
clearLCD:       push    de
                push    bc
                push    hl

                ld      hl,mydata       ;coloca na var o char a ser escrito
                ld      a,01H           ;apaga LCD e coloca na coluna 1
                ld      (hl),a
                call    scomLCD         ;muda de linha no LCD

                pop     hl
                pop     bc              ;restaura tamanho
                pop     de              ;restaura pos da string

                ret

;-------------------------------------------------------------------------------
; Subrotina sndlpt - envia dado para LPT
;
sndlpt:         ld      hl,myout        ;carrega endereco da var
                ld      a,(hl)          ;pega o conteudo
                out     (LPTDT),a       ;envia dados para LPT via OUT direto
                ret

;-------------------------------------------------------------------------------
; Subrotina strobe_on - liga pino de strobe
;
strobe_on:      ld      hl,mystrb       ;carrega end da var
                ld      a,01H           ;carrega valor ON
                jr      mystrobe        ;desvia

;-------------------------------------------------------------------------------
; Subrotina strobe_off - desliga pino de strobe
;
strobe_off:     ld      hl,mystrb       ;carrega end da var
                ld      a,00H           ;carrega valor OFF

;-------------------------------------------------------------------------------
; Subrotina mystrobe - liga/desliga pino de strobe
;
mystrobe:       out     (LPTST),a       ;envia dado para pino de STROBE
                ret                     ;retorna

;-------------------------------------------------------------------------------
; Subrotina para enviar um CR+LF para a tela
;
CRLFtela:       push    de
                push    bc
                push    hl

                ld      a,CR
                call    CHPUT
                ld      a,LF
                call    CHPUT

                pop     hl
                pop     bc
                pop     de

                ret
;-------------------------------------------------------------------------------
; Subrotina para aguardar aproximadamente 1us
;
; T = 1/F => T = 1/3,57MHz => T = 0,280us
; NOP consome 4 ciclos; -> 4 x 0,280us = 1.132us;
;
_1us:           nop                     ;nao faz nada, apenas consome tempo
                ret

;-------------------------------------------------------------------------------
; Subrotina para aguardar aproximadamente 5us
;
; T = 1/F => T = 1/3,57MHz => T = 0,280us
; NOP consome 4 ciclos -> 5 x (4x 0,280us) = 5.6us;
;
_5us:           nop                     ;nao faz nada, apenas consome tempo
                nop
                nop
                nop
                nop
                ret

;-------------------------------------------------------------------------------
; Subrotina para aguardar aproximadamente 10us
;
; T = 1/F => T = 1/3,57MHz => T = 0,280us
; NOP consome 4 ciclos -> 9 x (4x 0,280us) = 5.6us;
;
_10us:          nop                     ;nao faz nada, apenas consome tempo
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                ret

;-------------------------------------------------------------------------------
; Subrotina para aguardar aproximadamente 50us
;
; T = 1/F => T = 1/3,57MHz => T = 0,280us
; DEC consome 4 ciclos
; JRNZ consome 12 ciclos
; DEC + JRNZ consomente juntos 16 ciclos
;
; 11 x 16 x 0,280us ~= 49,28us (DEC L + JR NZ loop50us)
;
_50us:          ld      h,0BH           ;carrega H com 11
loop50us:       dec     h               ;decrementa H
                jr      nz,loop50us     ;continua ate ser zero
                ret

;-------------------------------------------------------------------------------
; Subrotina para aguardar aproximadamente 1ms
;
; T = 1/F => T = 1/3,57MHz => T = 0,280us
; DEC consome 4 ciclos
; JRNZ consome 12 ciclos
; DEC + JRNZ consomente juntos 16 ciclos
;
; 40 x 16 x 0,280us ~= 179,2us (DEC L + JR NZ loop1_1ms)
; 5 x 16 x 0,280us ~= 22,4us (DEC H + JR NZ loop1ms)
;
; (179,2us + 22,4us) x 5 = 1.008ms
;
_1ms:           ld      h,05H           ;carrega H com 5
loop1ms:        ld      l,28H           ;carrega L com 40
loop1_1ms:      dec     l               ;decrementa L
                jr      nz,loop1_1ms    ;continua ate ser zero
                dec     h               ;decrementa h
                jr      nz,loop1ms      ;continua ate H ser zero
                ret                     ;retorna para subrotina de chamada
                ;ret

;-------------------------------------------------------------------------------
; Subrotina para aguardar aproximadamente 50ms
;
; T = 1/F => T = 1/3,57MHz => T = 0,280us
; DEC consome 4 ciclos
; JRNZ consome 12 ciclos
; DEC + JRNZ consomente juntos 16 ciclos
;
; 175 x 16 x 0,280us = 784us (DEC L + JR NZ loop_50ms)
; 50 x 16 x 0,280us = 224us (DEC H + JR NZ loop50ms)
;
; (784us + 224us) x 50 = 50.4ms
;
_50ms:          ld      h,032H          ;carrega H com 50
loop50ms:       ld      l,0AFH          ;carrega L com 175
loop_50ms:      dec     l               ;decrementa L
                jr      nz,loop_50ms    ;continua ate ser zero
                dec     h               ;decrementa h
                jr      nz,loop50ms     ;continua ate H ser zero
                ret                     ;retorna para subrotina de chamada

;-------------------------------------------------------------------------------
; Subrotina para aguardar aproximadamente 500ms
;
; T = 1/F => T = 1/3,57MHz => T = 0,280us
; DEC consome 4 ciclos
; JRNZ consome 12 ciclos
; DEC + JRNZ consomente juntos 16 ciclos
;
; 165 x 16 x 0,280us = 739,20us (DEC L + JR NZ loop2_500)
; 50 x 16 x 0,280us = 224us (DEC H + JR NZ loop1_500)
; 10 x 16 x 0,280us = 44,8us (DEC E + JR NZ loop500)
;
; (739,2us + 224us + 44,8us) x 500 ~= 504ms
;
_500ms:         ld      e,0AH           ;carregqa e com 10
loop500:        ld      h,032H          ;carrega h com 50
loop1_500:      ld      l,0A5H          ;carrega l com 165
loop2_500:      dec     l               ;decrementa l
                jr      nz,loop2_500       ;continua ate ser zero
                dec     h               ;decrementa h
                jr      nz,loop1_500       ;recarrega l e faz ate h ser zero
                dec     e               ;decrementa e
                jr      nz,loop500
                ret                     ;retorna para subrotina de chamada

;-------------------------------------------------------------------------------
; Dados para LCD - inicializacao
; comandos para inicializar o LCD - modo 4 bits
_inilcd:        db       02H, 28H, 06H, 0FH, 01H

;-------------------------------------------------------------------------------
; Codigo ASCII para 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F
_BCD            db      30H, 31H, 32H, 33H, 34H, 35H, 36H, 37H, 38H, 39H, 41H, 42H, 43H, 44H, 45H, 46H

;-------------------------------------------------------------------------------
; Fim do programa
;
                end

;-------------------------------------------------------------------------------
; Project: MSX_placa_adapt_teste2.zdsp
; Main File: MSX_placa_adapt_teste2.asm
; Date: 01/08/2019 13:07:00
;
; Created with zDevStudio - Z80 Development Studio.
;
; Desenvolvido por: Eng. Marcio Jose Soares
; Plataforma de testes: MSX Hotbit HB8000 1.1
; Placas extras: MSX_placa_adapt_placa_buffer_II_v0.0
;                Placa_buffer_ii - Saber Eletronica
;
; Proposta: controlar a placa Buffer II ou "LPT Prog (como ficou conhecida essa
; placa quando publiquei o projeto da mesma na revista Saber Eletronica) atraves
; da placa MSX_placa_adapt_placa_buffer_II_v0.0 projetada tambem por mim! ;)
;
; Esse programa visa testar os displays de 7 segmentos presentes na placa LPT_PROG
; Exemplo adotado: mostra nos displays 0 a 9 (uma unica vez, sem loop)
;
;-------------------------------------------------------------------------------
; Ultimas alteracoes:
;
; em 01/08/2019:
;    - criado esse programa
;
; em 02/08/2019:
;    - testado envio para um unico display de 7 segmentos
;
; em 03/08/2019:
;    - alterado programa anterior para que 595 de controle efetue uma
;      varredura apresentando o mesmo valor em todas os displays
;
; em 04/08/2019:
;	 - testado programa na placa com video para comprovar funcionamento
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
LPTST:          equ     0090H           ;endereco do strob na linha de dados para LPT
STROBE:         equ     0001H           ;bit para ativar o STROB - bit0

;-------------------------------------------------------------------------------
; Declara constantes
;
CR:             equ     0DH             ;ENTER
LF:             equ     0AH             ;Line Feed
asciizero       equ     30H             ;valor ASCII para zero
ascii7          equ     39H             ;valor ASCII para 9
tempo1          equ     16H             ;25
tempo2          equ     05H             ;5x25 = 125 vezes!!!

;-------------------------------------------------------------------------------
; Declara espaco para vars
;
valor           DB      0               ;var para saida na tela
myout           DB      0               ;var de saida para LPT - dados
mystrb          DB      0               ;var de saida para LPT - controle (STB)

myser           DB      0               ;var de serializacao para 595
mydata          DB      0               ;var de saida dos dados para 595
myctrl          DB      0               ;var de saida dos controle para 595

my7segpt        DB      0               ;var para gravar o ponteiro da tabela
mymil           DB      0               ;var para guardar milhar
mycent          DB      0               ;var para guardar centena
mydez           DB      0               ;var para guardar dezena
myunid          DB      0               ;var para guardar unidade

mycount1        DB      0               ;vars para contador
mycount2        DB      0

myaux           DB      0               ;var auxiliares
myaux2          DB      0

;-------------------------------------------------------------------------------
; inicia variaveis
;
                ld      hl,mystrb       ;carrega endereco em hl
                ld      a, 01H
                ld      (hl),a          ;guarda zero em myxor

                ld      hl,valor        ;carrega HL com endereco da pos valor
                ld      a, asciizero    ;carrega valor em a
                ld      (hl),a          ;carrega posicao HL com a

                ld      hl,myout        ;carrega HL com endereco myout
                ld      a, 0EH          ;carrega valor - 1110000 - DT, CLK e TRF em 1
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,myser        ;carrega HL com endereco myser
                ld      a, 00H          ;carrega valor
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,mydata       ;carrega HL com endereco mydata
                ld      a, 00H          ;carrega valor
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,myctrl       ;carrega HL com endereco myctrl
                ld      a, 01H          ;carrega valor - inicia sempre em 1
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,my7segpt     ;inicia apontamento da tabela
                ld      a,00H           ;aponta...
                ld      (hl),a          ;guarda

                ld      hl,mycount1     ;inicia contador
                ld      a,tempo1        ;
                ld      (hl),a          ;guarda

                ld      hl,mycount2     ;inicia contador
                ld      a,tempo2        ;
                ld      (hl),a          ;guarda

                ld      hl,myaux        ;carrega HL com endereco myaux
                ld      a, 00h          ;carrega valor
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,myaux2       ;carrega HL com endereco myaux2
                ld      a, 00h          ;carrega valor
                ld      (hl),a          ;carrega posicao de memoria com a

;-------------------------------------------------------------------------------
; Subrotina principal
;
main:           ld      hl,msgini       ;carrega mensagem /inicial
                call    wrmsg           ;escreve mensagem inicial

                call    mystrobe        ;seta pino de strobe para garantir transferencias
                call    sndlpt          ;coloca valor presente em myout na LPT - zera tudo

                ld      hl,msgCRLF      ;carrega CR/LF
                call    wrmsg           ;escreve

                ld      hl,msgsend      ;carrega msg enviando
                call    wrmsg           ;escreve

                call    count_up0to9    ;conta de 0 a 9 no disp de 7 seg!

                ld      hl,myctrl       ;le end
                ld      a, 00H          ;desliga todos os controles
                ld      (hl),a          ;carrega
                call    serlpt

                ld      hl,mydata       ;le end
                ld      (hl),a          ;carrega
                call    serlpt
                call    transp          ;aqui limpou a porta como um todo

                ld      hl,mystrb       ;carrega endereco em hl
                ld      a, 00H
                ld      (hl),a          ;guarda zero em myxor
                call    mystrobe        ;reseta pino de strobe

;-------------------------------------------------------------------------------
; Retorno para o BASIC
;
                ret                     ;retorna para o BASIC

;-------------------------------------------------------------------------------
; Subrotina para enviar de 0 a 9 para os displays de 7 segmentos!
;
count_up0to9:   ld      de,my7segpt     ;pega apontador atual da tabela
                ld      b,00H           ;zera b
                ld      a,(de)
                ld      c,a             ;guarda em bc o apontador

                ld      hl,_7segdata    ;inicia leitura da posicao da tabela
                add     hl,bc           ;em HL agora a nova posicao
                ld      a,(hl)          ;pega o conteudo apontado na tabela
                and     a               ;faz um and
                ret     z               ;se o contudo era zero, retorna - fim da tabela

                ld      hl,mydata       ;pega end da var - dados
                ld      (hl),a          ;transfere o conteudo

                call    sndVDLPT        ;prepara para serializar

                ld      hl,my7segpt     ;pega o endereco do apontador
                inc     (hl)            ;incrementa o conteudo

                ld      hl,valor        ;pega o endereco do valor em ASC a mostrar
                inc     (hl)            ;incrementa

                jr      count_up0to9    ;faz ate chegar a zero!

;-------------------------------------------------------------------------------
; Subrotina para enviar dados para tela e impressora
;
sndVDLPT:       ld      hl,mycount1     ;inicia contador
                ld      a,tempo1        ;
                ld      (hl),a          ;guarda

                ld      hl,mycount2     ;inicia contador
                ld      a,tempo2        ;
                ld      (hl),a          ;guarda

                ld      hl,msgCRLF      ;carrega CR/LF
                call    wrmsg           ;escreve

                ld      hl,valor        ;carrega endereco da var em hl
                ld      a,(hl)          ;pega o conteudo
                call    CHPUT           ;envia char

sndloop:        ld      hl,myctrl       ;carrega endereco da var - controle
                ld      a,(hl)          ;ativa o bit de ctrl na placa lpt prog
                ld      hl,myser        ;carrega end da var de serializacao
                ld      (hl),a          ;carrega dado na var
                call    serlpt          ;serializa bits de controle

                ld      hl,myctrl       ;retorna end da var
                ld      a,(hl)          ;pega o conteudo
                sla     a               ;gira a esquerda
                cp      10H             ;compara
                jr      nz,sndcont      ;se passou, volta valor, senÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â£o continua
                ld      a,01H           ;volta para strob da lpt prog

sndcont:        ld      (hl),a          ;guarda o resultado do ctrl
                ld      hl,mydata       ;pega dado a ser serializado
                ld      a,(hl)          ;carrega o seu conteudo
                ld      hl,myser        ;endereco da var de serializacao
                ld      (hl),a          ;coloca em myser o conteudo de mydata
                call    serlpt          ;serializa e envia para LPT

                call    transp          ;transporta tudo - dados e ctrl!
                call    _1ms            ;aguarda 1ms - com transp serÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â£o 2ms!

                ld      hl,mycount1     ;pega end da var
                dec     (hl)            ;decrementa conteÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Âºdo
                jr      nz,sndloop      ;faz enquanto nao for zero - 100!
                ld      a,tempo1        ;recarrega var
                ld      (hl),a          ;carrega
                ld      hl,mycount2     ;pega end da var
                dec     (hl)            ;decrementa var
                jr      nz,sndloop      ;faz enquanto nao for zero - 5x100 = 500

                ret

;-------------------------------------------------------------------------------
; Subrotina para serializar um byte e enviar via LPT para a placa buffer II
; usando a placa MSX_adapt_placa_buffer_II
; Obs.: Serializacao vai do bit MSB para o LSB!!!
;
serlpt:         ld      b,08H           ;sao 8 bits
                ld      hl,myaux2       ;carrega endereco
                ld      a, b            ;carrega b em a
                ld      (hl), a         ;guarda

slptloop:       ld      hl,myser        ;carrega endereco da var
                ld      a,(hl)          ;pega o conteudo
                and     80H             ;faz and com 80H para testar bit 7
                jr      nz,serbit1      ;se nao eh zero, envia bit 1

serbit0:        ld      hl,myaux        ;carrega endereco
                ld      a,(hl)          ;carrega o resultado de aux
                and     7FH             ;faz um and para limpar o bit de dados
                ld      (hl),a          ;carrega o contecdo de A em aux
                jr      serclk          ;desvia para colocar o clock

serbit1:        ld      hl,myaux        ;carrega endereco
                ld      a,(hl)          ;carrega o resultado de aux
                or      80H             ;faz um or para setar o bit de dados
                ld      (hl),a          ;carrega o conteudo de A em aux

serclk:         ld      hl,myaux        ;volta a carregar o endereco da var
                ld      a,(hl)          ;pega o seu conteudo
                and     0BFH            ;limpa o bit de clock
                ld      (hl),a          ;salva res em myaux - 17/08/2019

                ld      hl,myout        ;carrega endereco da var de transporte
                ld      (hl),a          ;carrega no mesmo o conteudo de A
                call    sndlpt          ;envia para porta
                call    _50us            ;aguarda 50us

                ld      hl,myaux        ;carrega end da var - 17/08/2019
                ld      a,(hl)          ;retorna para A o conteudo de aux
                or      40H             ;seta o pino de clock
                ld      (hl),a          ;salva res em myaux - 17/08/2019

                ld      hl,myout;       ;carrega endereco da var de transporte
                ld      (hl),a          ;carrega no mesmo o conteudo de A
                call    sndlpt          ;envia para porta

                ld      hl,myser        ;carrega o endreco do valor a ser enviado
                ld      a,(hl)          ;pega seu conteudo
                rla                     ;shift a esquerda
                ld      (hl),a          ;guarda resultado do giro

                ld      hl,myaux2       ;carrega endereco
                ld      a,(hl)          ;pega conteudo
                dec     a               ;decrementa a
                jr      nz,serend       ;se nao eh zero ainda, continua
                ret                     ;detectado fim, retorna!

serend:         ld      (hl),a          ;guarda conteudo
                jr      slptloop        ;continua ate ultimo bit

;-------------------------------------------------------------------------------
; Subrotina sndlpt - envia dado para LPT
;
sndlpt:         ld      hl,myout        ;carrega endereco da var
                ld      a,(hl)          ;pega o conteudo
                out     (LPTDT),a       ;envia dados para LPT via OUT direto
                ret

;-------------------------------------------------------------------------------
; Subrotina mystrobe - liga/desliga pino de strobe
;
mystrobe:       ld      hl,mystrb       ;carrega endereco
                ld      a,(hl)          ;pega o conteudo de mystrb
                out     (LPTST),a       ;envia dado para pino de STROBE
                ret

;-------------------------------------------------------------------------------
; Subrotina transp - transporta dados do latch do 595 para a sua saÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â­da
;
transp:         ld      hl,myout        ;pega endereco da var de transporte
                ld      a,(hl)          ;pega seu conteudo
                and     00H             ;lipa tudo
                or      20H             ;liga bit de transporte
                ld      (hl),a          ;carrega conteudo
                call    sndlpt          ;envia para a porta
                call    _1ms
                ld      hl,myout        ;carrega novamente
                ld      a,(hl)          ;carrega o conteudo
                and     00H             ;limpa
                ld      hl,myout        ;carrega novamente
                ld      (hl),a          ;guarda
                call    sndlpt          ;envia
                ret                     ;retorna

;-------------------------------------------------------------------------------
; Subrotina para escrever na tela
;
wrmsg:          ld      a,(hl)          ;carrega no acumulador o conteudo
                and     a               ;faz um AND
                ret     z               ;retorna se flag z estiver setado, senao pula
                call    CHPUT           ;chama rotina para escrever char
                inc     hl              ;incrementa HL (ponteiro)
                jr      wrmsg           ;continua ate o final da string

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
; Mensagens a serem escritas na tela
;
msgini:         db      'TESTE 2 CONTROLE PORTA PARALELA USANDO'   ;texto para primeira linha
                db      CR, LF                                     ;muda linha
                db      'PLACA MSX_ADAPT_PLACA_BUFFER_II E   '     ;texto para segunda linha
                db      CR, LF                                     ;muda linha
                db      'PLACA BUFFER II (LPT PROG SABER)    '     ;texto para terceira linha
                db      CR, LF                                     ;muda linha
                db      'by ARNE ;) - compilador PASMO v0.53'      ;texto para quarta linha
                db      0                                          ;fim da string!

msgsend:        db      'ENVIANDO PARA DISP7SEG -> '
                db      0

msgCRLF:        db      CR
                db      LF
                db      0

_7segdata:      db      0FCH, 60H, 0DAH, 0F2H, 66H, 0B6H, 0BEH, 0E0H, 0FEH, 0E6H, 00H    ;matriz com dados para disp7seg

;-------------------------------------------------------------------------------
; Fim do programa
;
                end

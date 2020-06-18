;-------------------------------------------------------------------------------
; Project: MSX_placa_adapt_teste4 (teste4.zdsp)
; Main File: teste4.asm
; Date: 08/08/2019 10:28:29
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
; Esse programa visa testar as entradas presentes na placa LPT_PROG
; Exemplo adotado: mostra na tela o nr da chave pressionada!
;
;-------------------------------------------------------------------------------
; Ultimas alteracoes:
;
; em 08/08/2019:
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
asciizero       equ     30H             ;valor ASCII para zero

;-------------------------------------------------------------------------------
; Declara espaco para vars
;
valor           DB      0               ;var para saida na tela
myout           DB      0               ;var de saida para LPT - dados
mystrb          DB      0               ;var de saida para LPT - controle (STB)

myser           DB      0               ;var de serializacao para 595
myctrl          DB      0               ;var de saida dos controles para 595
myctrlIN        DB      0               ;var de entrada dos controles para 595
myINbck         DB      0               ;var para guardar backup da entrada

mycount1        DB      0               ;vars para contador
mycount2        DB      0

myaux           DB      0               ;var auxiliares
myaux2          DB      0
myaux3          DB      0

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
                ld      a, 0E2H         ;carrega valor - 11100110 - DT, CLK, TRF, SH_LD_IN em 1
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,myser        ;carrega HL com endereco myser
                ld      a, 00H          ;carrega valor
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,myctrl       ;carrega HL com endereco myctrl
                ld      a, 01H          ;carrega valor - inicia sempre em 1
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,myctrlIN     ;carrega HL com endereco myctrlIN
                ld      a, 01H          ;carrega valor - inicia sempre em 1
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,myINbck      ;carrega HL com endereco myINbck
                ld      a, 01H          ;carrega valor - inicia sempre em 1
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,myaux        ;carrega HL com endereco myaux
                ld      a, 00h          ;carrega valor
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,myaux2       ;carrega HL com endereco myaux2
                ld      a, 00h          ;carrega valor
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,myaux3       ;carrega HL com endereco myaux3
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

                call    zeraLPT         ;zera bits da LPT
                call    serlpt
                call    serlpt
                call    transp          ;aqui limpou a porta como um todo

                call    slacoINs        ;le entradas ate chave 5 ser pressionada

                ld      hl,mystrb       ;carrega endereco em hl
                ;ld      a, 00H
                ld      (hl),00H        ;zera conteudo
                call    mystrobe        ;reseta pino de strobe

;-------------------------------------------------------------------------------
; Retorno para o BASIC
;
                ret                     ;retorna para o BASIC

;-------------------------------------------------------------------------------
; Subrotina de laÃ§o "infinito" que chama leitura das entradas e compara chave
; pressionada... se pressionar S! e S5 juntas, programa retorna ao basic!
;
slacoINs:       call    slptINs         ;chama rotina para ler as entradas
                ld      hl,myctrlIN     ;pega end da var
                ld      a,(hl)          ;coloca em B o que pegou nas entradas
                ld      hl,myINbck      ;pega outro end
                cp      (hl)            ;compara a nova leitura c/ bck
                jr      z,slcINstst     ;se zero, ambas sÃ£o iguais, nÃ£o faz nada

                ld      hl,myctrlIN     ;pega end
                ld      a,(hl)          ;pega conteÃºdo
                ld      hl,myINbck      ;pega novo end
                ld      (hl),a          ;grava bck

                call    msgINdata       ;escreve nova mensagem

slcINstst:      call    _50ms           ;aguarda 50ms - debounce
                ld      hl,myctrlIN     ;pega end da var
                ld      a,(hl)          ;em a o conteudo
                cp      0EH             ;se Ã© 0EH, hora de sair
                jr      nz,slacoINs     ;se nÃ£o Ã©, continua
                ret                     ;sai do laco!

;-------------------------------------------------------------------------------
; Subrotina de leitura das chaves de entradas presentes na placa buffer II
; (placa LPT PROG) usando a placa MSX_adapt_placa_buffer_II
; Obs.: Serializacao vai do MSB para o LSB
;
slptINs:        ld      hl,myctrlIN     ;pega end
                ld      a,00H
                ld      (hl),a          ;zera var!

                ld      b,08H           ;sao 8 bits
                ld      hl,myaux3       ;carrega endereco
                ld      a, b            ;carrega b em a
                ld      (hl), a         ;guarda

                ld      hl,myout        ;carrega o end da var
                ld      a,(hl)          ;pega o conteudo
                and     0FDH            ;zera bit 0 em SH/LD 165
                ld      (hl),a          ;carrega dado no endereco
                call    sndlpt          ;envia para porta
                call    _50us           ;aguarda 50us

                ld      hl,myout        ;carrega end da var
                ld      a,(hl)          ;carrega dado na var
                or      02H             ;liga bit SH/LD no 165
                ld      (hl),a          ;carrega dado no endereco
                call    sndlpt          ;envia para porta

sINsloop:       IN      a,(LPTST)       ;pega o conteudo da entrada
                and     BUSY            ;isola bit 1
                jr      nz,sINsbit1     ;se em 1, bit eh 1

sINsbit0:       ld      hl,myctrlIN     ;pega novamente o endereco
                ld      a,(hl)          ;carrega
                and     0FEH            ;limpa bit 0
                jr      sINssave

sINsbit1:       ld      hl,myctrlIN     ;pega end da var
                ld      a,(hl)          ;pega o conteudo
                or      01H             ;faz bit igual a 1

sINssave:       ld      (hl),a          ;guarda

sINsclk:        ld      hl,myout        ;carrega end da var
                ld      a,(hl)          ;pega conteudo
                or      04H             ;seta bit do clk do 165
                ld      (hl),a          ;guarda
                call    sndlpt          ;envia para porta
                call    _50us           ;aguarda

                ld      hl,myout        ;pega end da var
                ld      a,(hl)          ;pega o conteudo
                and     0FBH            ;limpa bit do clk do 165
                ld      (hl),a          ;carrega valor na var
                call    sndlpt          ;envia para a porta
                call    _50us           ;aguarda 50us

                ld      hl,myaux3       ;carrega endereco
                ld      a,(hl)          ;pega conteudo
                dec     a               ;decrementa a
                jr      z,sINsend       ;se eh zero para

                ld      (hl),a          ;guarda resultado
                ld      hl,myctrlIN     ;pega var com bits de entrada
                rl      (hl)            ;gira conteudo a esquerda para continuar
                jr      sINsloop        ;continua

sINsend:        ret                     ;chegou ao fim, apenas retorne!!!

;-------------------------------------------------------------------------------
; Subrotina para jogar na tela a var caso de captura
;
msgINdata:      ld      b,08H           ;sao 8 bits
                ld      hl,myaux2       ;carrega endereco
                ld      (hl),b          ;guarda

                ld      hl,msgCRLF      ;carrega CR/LF
                call    wrmsg           ;escreve

                ld      hl,msgsend      ;carrega msg coletando
                call    wrmsg           ;escreve

                ld      hl,myctrlIN     ;pega end
                ld      a,(hl)          ;pega o conteÃºdo
                ld      b,a             ;joga para B

msgINdtlc:      and     80H             ;verifica sempre pelo MSB
                jr      nz,msgINbit1    ;se nao eh zero, bit eh 1

msgINbit0:      ld      a,30H           ;bit eh zero
                call    CHPUT           ;envia para tela
                jr      msgINcont       ;desvia

msgINbit1:      ld      a,31H           ;bit eh um
                call    CHPUT           ;envia

msgINcont:      sla     b               ;gira b a esquerda
                ld      hl,myaux2       ;carrega endereco
                ld      a,(hl)          ;pega conteudo
                dec     a               ;decrementa a
                jr      nz,msgIN1more   ;se nao eh zero ainda, continua
                ret                     ;detectado fim, retorna!

msgIN1more      ld      (hl),a          ;guarda conteudo
                ld      a,b             ;carrega a com conteudo de b
                jr      msgINdtlc       ;continua ate ultimo bit

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
                ld      hl,myout        ;carrega endereco da var de transporte
                ld      (hl),a          ;carrega no mesmo o conteudo de A
                call    sndlpt          ;envia para porta
                call    _50us           ;aguarda 50us

                ld      a,(hl)          ;retorna para A o conteudo de aux
                or      40H             ;seta o pino de clock
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
; Subrotina para zerar a porta LPT
zeraLPT:        ld      a, 00H          ;desliga todos os controles e dados
                ld      hl,myser        ;carrega endereÃƒÂ§o da var
                ld      (hl),a          ;carrega
                ret

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
; Subrotina transp - transporta dados do latch do 595 para a sua saÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â­da
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
msgini:         db      'TESTE 4 CONTROLE PORTA PARALELA USANDO'   ;texto para primeira linha
                db      CR, LF                                     ;muda linha
                db      'PLACA MSX_ADAPT_PLACA_BUFFER_II E   '     ;texto para segunda linha
                db      CR, LF                                     ;muda linha
                db      'PLACA BUFFER II (LPT PROG SABER)    '     ;texto para terceira linha
                db      CR, LF                                     ;muda linha
                db      'by ARNE ;) - compilador PASMO v0.53'      ;texto para quarta linha
                db      0                                          ;fim da string!

msgsend:        db      'BYTE COLETADO VIA BUSY -> '
                db      0

msgCRLF:        db      CR
                db      LF
                db      0

_7segdata:      db      0FCH, 60H, 0DAH, 0F2H, 66H, 0B6H, 0BEH, 0E0H, 0FEH, 0E6H, 00H    ;matriz com dados para disp7seg

;-------------------------------------------------------------------------------
; Fim do programa
;
                end

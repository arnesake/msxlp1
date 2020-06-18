;-------------------------------------------------------------------------------
; Project: MSX_placa_adapt_teste3.zdsp
; Main File: MSX_placa_adapt_teste3.asm
; Date: 04/08/2019 13:04:30
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
; Exemplo adotado: mostra nos displays uma contagem de 0000 a 9999!!!
;
;-------------------------------------------------------------------------------
; Ultimas alteracoes:
;
; em 04/08/2019:
;    - criado esse programa
;    - testado programa com sucesso, com video comprovando o funcionamento!!!
;
; em 04/09/2019:
;    - inserido stop para o programa atraves das chaves S1+S5
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
BUSY:           equ     0002H           ;bit para ler o BUSY - bit1

;-------------------------------------------------------------------------------
; Declara constantes
;
CR:             equ     0DH             ;ENTER
LF:             equ     0AH             ;Line Feed
asciizero       equ     30H             ;valor ASCII para zero
ascii7          equ     39H             ;valor ASCII para 9
tempo1          equ     0FH             ;15
tempo2          equ     03H             ;3x15 = 45 vezes!!!

;-------------------------------------------------------------------------------
; Declara espaco para vars
;
valor           DB      0               ;var para saida na tela
myout           DB      0               ;var de saida para LPT - dados
mystrb          DB      0               ;var de saida para LPT - controle (STB)

myser           DB      0               ;var de serializacao para 595
mydataM         DB      0               ;var de saida dos dados para 595 - milhar
mydataC         DB      0               ;var de saida dos dados para 595 - centena
mydataD         DB      0               ;var de saida dos dados para 595 - dezena
mydataU         DB      0               ;var de saida dos dados para 595 - unidade
myctrl          DB      0               ;var de saida dos controle para 595

my7segpt        DB      0               ;var para gravar o ponteiro da tabela
mymil           DB      0               ;var para guardar milhar
mycent          DB      0               ;var para guardar centena
mydez           DB      0               ;var para guardar dezena
myunid          DB      0               ;var para guardar unidade

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
                ld      a, 0EH          ;carrega valor - 1110000 - DT, CLK e TRF em 1
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,myser        ;carrega HL com endereco myser
                ld      a, 00H          ;carrega valor
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,mydataM      ;carrega HL com endereco mydataM
                ld      a, 00H          ;carrega valor
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,mydataC      ;carrega HL com endereco mydataC
                ld      a, 00H          ;carrega valor
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,mydataD      ;carrega HL com endereco mydataD
                ld      a, 00H          ;carrega valor
                ld      (hl),a          ;carrega posicao de memoria com a

                ld      hl,mydataU      ;carrega HL com endereco mydataU
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

                ld      hl,mymil        ;inicia milhar
                ld      a,00H           ;
                ld      (hl),a          ;guarda

                ld      hl,mycent        ;inicia centena
                ld      a,00H           ;
                ld      (hl),a          ;guarda

                ld      hl,mydez        ;inicia dezena
                ld      a,00H           ;
                ld      (hl),a          ;guarda

                ld      hl,myunid       ;inicia unidade
                ld      a,00H           ;
                ld      (hl),a          ;guarda

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

                ld      hl,msgsend      ;carrega msg enviando
                call    wrmsg           ;escreve

                call    c_up0to9999     ;conta de 0000 a 9999 no disp de 7 seg!

                ld      hl,myctrl       ;le end
                ld      a, 00H          ;desliga todos os controles
                ld      (hl),a          ;carrega
                call    serlpt

                ld      hl,mydataU       ;le end
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
; Subrotina para enviar de 0 a 9999 para os displays de 7 segmentos!
;
c_up0to9999:    ld      de,mymil        ;pega end da contagem da milhar
                ld      b,00H           ;zera B
                ld      a,(de)          ;pega o conteudo do end
                ld      c,a             ;guarda em c
                ld      hl,_7segdata    ;pega endereco da tabela
                add     hl,bc           ;soma para pegar a nova posico
                ld      a,(hl)          ;pega o conteudo
                ld      hl,mydataM      ;pega endereco da milhar no 595
                ld      (hl),a          ;coloca seu conteudo

                ld      de,mycent       ;pega end da contagem da centena
                ld      b,00H           ;zera B
                ld      a,(de)          ;pega o conteudo do end
                ld      c,a             ;guarda em c
                ld      hl,_7segdata    ;pega endereco da tabela
                add     hl,bc           ;soma para pegar a nova posico
                ld      a,(hl)          ;pega o conteudo
                ld      hl,mydataC      ;pega endereco da centena no 595
                ld      (hl),a          ;coloca seu conteudo

                ld      de,mydez        ;pega end da contagem da dezena
                ld      b,00H           ;zera B
                ld      a,(de)          ;pega o conteudo do end
                ld      c,a             ;guarda em c
                ld      hl,_7segdata    ;pega endereco da tabela
                add     hl,bc           ;soma para pegar a nova posico
                ld      a,(hl)          ;pega o conteudo
                ld      hl,mydataD      ;pega endereco da dezena no 595
                ld      (hl),a          ;coloca seu conteudo

                ld      de,myunid       ;pega end da contagem da unidade
                ld      b,00H           ;zera B
                ld      a,(de)          ;pega o conteudo do end
                ld      c,a             ;guarda em c
                ld      hl,_7segdata    ;pega endereco da tabela
                add     hl,bc           ;soma para pegar a nova posico
                ld      a,(hl)          ;pega o conteudo
                ld      hl,mydataU      ;pega endereco da dezena no 595
                ld      (hl),a          ;coloca seu conteudo

                call    sndVDLPT        ;chama rotina de envio para video e LPT
                call    slptINs         ;chama rotina de leitura das chaves

                ld      hl,myctrlIN     ;pega end da var
                ld      a,(hl)          ;em a o conteudo
                cp      0EH             ;se ÃƒÆ’Ã‚Â© 0EH, hora de sair
                jr      nz,c_up_cont0   ;se nÃƒÆ’Ã‚Â£o ÃƒÆ’Ã‚Â©, continua
                jr      c_up_cont4      ;finaliza!!!!

c_up_cont0:     ld      hl,myunid       ;pega end
                ld      a,(hl)          ;pega o conteudo
                inc     a               ;incrementa a
                cp      0AH             ;se passou hora de somar na proxima, senao...
                ld      (hl),a          ;guarda conteudo ja que nao chegou no limite
                jr      z,c_up_cont1    ;se passou soma
                jr      c_up0to9999     ;continua fazendo

c_up_cont1:     ld      a,00H           ;retorna unidade a zero
                ld      (hl),a          ;zera no enderero anterior - unidade
                ld      hl,mydez        ;pega end
                ld      a,(hl)          ;pega o conteudo
                inc     a               ;incrementa a
                cp      0AH             ;se passou hora de somar na proxima, senao...
                ld      (hl),a          ;guarda conteudo ja que nao chegou no limite
                jr      z,c_up_cont2    ;se passou soma
                jr      c_up0to9999     ;continua fazendo

c_up_cont2:     ld      a,00H           ;retorna unidade a zero
                ld      (hl),a          ;zera no enderero anterior - unidade
                ld      hl,mycent       ;pega end
                ld      a,(hl)          ;pega o conteudo
                inc     a               ;incrementa a
                cp      0AH             ;se passou hora de somar na proxima, senao...
                ld      (hl),a          ;guarda conteudo ja que nao chegou no limite
                jr      z,c_up_cont3    ;se passou soma
                jr      c_up0to9999     ;continua fazendo

c_up_cont3:     ld      a,00H           ;retorna unidade a zero
                ld      (hl),a          ;zera no enderero anterior - unidade
                ld      hl,mymil        ;pega end
                ld      a,(hl)          ;pega o conteudo
                inc     a               ;incrementa a
                cp      0AH             ;se passou hora de somar na proxima, senao...
                ld      (hl),a          ;guarda conteudo ja que nao chegou no limite
                jr      z,c_up_cont4    ;se passou soma
                jp      c_up0to9999     ;continua fazendo

c_up_cont4:     ret                     ;contagem chegou ao fim!!!

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

                ;ld      hl,my7segpt     ;carrega end do apontador
                ;ld      a,00H           ;zera acumulador
                ;ld      (hl),a          ;zera apontador

                ld      hl,mymil        ;carrega endereco da var em hl - milhar
                ld      a,(hl)          ;pega o conteudo
                add     a,30H           ;converte valor para ASCII
                call    CHPUT           ;envia char

                ld      hl,mycent       ;carrega endereco da var em hl - centena
                ld      a,(hl)          ;pega o conteudo
                add     a,30H           ;converte valor para ASCII
                call    CHPUT           ;envia char

                ld      hl,mydez        ;carrega endereco da var em hl - dezena
                ld      a,(hl)          ;pega o conteudo
                add     a,30H           ;converte valor para ASCII
                call    CHPUT           ;envia char

                ld      hl,myunid       ;carrega endereco da var em hl - unidade
                ld      a,(hl)          ;pega o conteudo
                add     a,30H           ;converte valor para ASCII
                call    CHPUT           ;envia char

sndloop:        ld      a,08H           ;ativa o bit de ctrl para milhar
                ld      hl,myser        ;carrega end da var de serializacao
                ld      (hl),a          ;carrega dado na var
                call    serlpt          ;serializa bits de controle

                ld      hl,mydataM      ;pega dado a ser serializado
                ld      a,(hl)          ;carrega o seu conteudo
                ld      hl,myser        ;endereco da var de serializacao
                ld      (hl),a          ;coloca em myser o conteudo de mydata
                call    serlpt          ;serializa e envia para LPT

                call    transp          ;transporta tudo - dados e ctrl!
                ;call    _1ms            ;aguarda 1ms - com transp serao 2ms!

                ld      a,04H           ;ativa o bit de ctrl para centena
                ld      hl,myser        ;carrega end da var de serializacao
                ld      (hl),a          ;carrega dado na var
                call    serlpt          ;serializa bits de controle

                ld      hl,mydataC      ;pega dado a ser serializado
                ld      a,(hl)          ;carrega o seu conteudo
                ld      hl,myser        ;endereco da var de serializacao
                ld      (hl),a          ;coloca em myser o conteudo de mydata
                call    serlpt          ;serializa e envia para LPT

                call    transp          ;transporta tudo - dados e ctrl!
                ;call    _1ms            ;aguarda 1ms - com transp serao 2ms!

                ld      a,02H           ;ativa o bit de ctrl para dezena
                ld      hl,myser        ;carrega end da var de serializacao
                ld      (hl),a          ;carrega dado na var
                call    serlpt          ;serializa bits de controle

                ld      hl,mydataD      ;pega dado a ser serializado
                ld      a,(hl)          ;carrega o seu conteudo
                ld      hl,myser        ;endereco da var de serializacao
                ld      (hl),a          ;coloca em myser o conteudo de mydata
                call    serlpt          ;serializa e envia para LPT

                call    transp          ;transporta tudo - dados e ctrl!
                ;call    _1ms            ;aguarda 1ms - com transp serao 2ms!

                ld      a,01H           ;ativa o bit de ctrl para unidade
                ld      hl,myser        ;carrega end da var de serializacao
                ld      (hl),a          ;carrega dado na var
                call    serlpt          ;serializa bits de controle

                ld      hl,mydataU      ;pega dado a ser serializado
                ld      a,(hl)          ;carrega o seu conteudo
                ld      hl,myser        ;endereco da var de serializacao
                ld      (hl),a          ;coloca em myser o conteudo de mydata
                call    serlpt          ;serializa e envia para LPT

                call    transp          ;transporta tudo - dados e ctrl!
                ;call    _1ms            ;aguarda 1ms - com transp serao 2ms!

                ld      hl,mycount1     ;pega end da var
                dec     (hl)            ;decrementa conteudo
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
; Subrotina transp - transporta dados do latch do 595 para a sua saida
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
                jr      nz,loop2_500    ;continua ate ser zero
                dec     h               ;decrementa h
                jr      nz,loop1_500    ;recarrega l e faz ate h ser zero
                dec     e               ;decrementa e
                jr      nz,loop500
                ret                     ;retorna para subrotina de chamada

;-------------------------------------------------------------------------------
; Mensagens a serem escritas na tela
;
msgini:         db      'TESTE 3 CONTROLE PORTA PARALELA USANDO'   ;texto para primeira linha
                db      CR, LF                                     ;muda linha
                db      'PLACA MSX_ADAPT_PLACA_BUFFER_II E   '     ;texto para segunda linha
                db      CR, LF                                     ;muda linha
                db      'PLACA BUFFER II (LPT PROG SABER)    '     ;texto para terceira linha
                db      CR, LF                                     ;muda linha
                db      'by ARNE ;) - compilador PASMO v0.53'      ;texto para quarta linha
                db      CR, LF                                     ;muda linha
                db      CR, LF                                     ;muda linha
                db      'PRESSIONE S1+S5 PARA PARAR'               ;avisa como sair
                db      CR, LF                                     ;muda linha
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
                   

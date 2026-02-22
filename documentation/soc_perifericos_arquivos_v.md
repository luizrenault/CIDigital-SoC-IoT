# SoC e Perifericos - Arquivos `.v` e Funcao de Cada Modulo

Documento adicional (sem alterar a documentacao existente) com foco no trabalho atual do SoC integrado em `design/rtl/top/top_teste.v`.

## Diagrama de integracao (visao funcional)

```mermaid
flowchart LR
    CPU["CPU RISC-V\npicorv32_axi"] --> IC12["Interconnect AXI-Lite 1x2\naxi_lite_ic_1x2"]
    IC12 --> RAM["Memoria on-chip\naxi_lite_ram"]
    IC12 --> IC16["Interconnect AXI-Lite 1x6\naxi_lite_interconnect_1x6"]

    IC16 --> GPIO["GPIO\naxilgpio"]
    IC16 --> TIMER["Timer\ntimer"]
    IC16 --> UART["UART Lite\nuart_lite"]
    IC16 --> SPI["SPI Master AXI-Lite\nspi_master_axil"]
    IC16 --> I2C["I2C Master AXI-Lite\ni2c_master_axil"]
    IC16 --> INTC["Controlador de Interrupcoes\naxil_intc"]

    GPIO --> INTC
    TIMER --> INTC
    UART --> INTC
    SPI --> INTC
    I2C --> INTC
    INTC --> CPU
```

## Diagrama de janelas de endereco AXI-Lite

```mermaid
flowchart TD
    ROOT["Janela raiz"] --> MEM["0x0000_0000..0x0001_FFFF\nRegiao de memoria"]
    ROOT --> PER["0x4000_0000..0x4000_FFFF\nRegiao de perifericos"]

    PER --> P0["GPIO\n0x4000_0000"]
    PER --> P1["TIMER\n0x4000_1000"]
    PER --> P2["UART\n0x4000_2000"]
    PER --> P3["SPI\n0x4000_3000"]
    PER --> P4["I2C\n0x4000_4000"]
    PER --> P5["INTC\n0x4000_5000"]
```

Fonte do mapa: `design/rtl/SoC_completo/soc_addr_map.vh`.

## Arquivos `.v` do SoC atual

| Arquivo `.v` | Modulo principal | Descricao funcional |
|---|---|---|
| `design/rtl/top/top_teste.v` | `soc_top_teste_mem_periph` | Top-level do SoC: instancia CPU, interconnects AXI-Lite, RAM e perifericos; agrega IRQs e conecta I/O externos (UART, SPI, I2C, GPIO). |
| `design/rtl/cpu/picorv32.v` | `picorv32`, `picorv32_axi`, etc. | Nucleo PicoRV32 e wrappers de barramento (inclui interface AXI-Lite usada como mestre pelo SoC). |
| `design/rtl/bus/axi_1_2.v` | `axi_lite_ic_1x2` | Decodificador/interconnect AXI-Lite 1 mestre para 2 escravos (separa regiao de memoria e perifericos). |
| `design/rtl/bus/axi_interconect_1_6.v` | `axi_lite_interconnect_1x6` | Interconnect AXI-Lite 1 para 6 perifericos com decode por base/mask e multiplexacao de respostas. |
| `design/rtl/bus/axi_mem.v` | `axi_lite_ram` | RAM mapeada em AXI-Lite com suporte a leitura/escrita por byte strobe e inicializacao opcional via arquivo HEX. |

## Arquivos `.v` dos perifericos (integrados no SoC atual)

| Arquivo `.v` | Modulo principal | Descricao funcional |
|---|---|---|
| `design/rtl/periph/gpio/axilgpio.v` | `axilgpio` | GPIO AXI-Lite com registradores de load/set/clear/toggle, leitura de entradas e geracao de interrupcao por mudanca de pino. |
| `design/rtl/periph/gpio/skidbuffer.v` | `skidbuffer` | Buffer de skid para handshake de canal AXI, usado para manter throughput e evitar perda em backpressure. |
| `design/rtl/periph/timer/timer.v` | `timer` | Timer AXI-Lite de 32 bits com compare, prescaler/postscaler, modo one-shot/autoreload e saida de interrupcao. |
| `design/rtl/periph/timer/timer_defs.v` | (defines) | Constantes de endereco/bitfields do timer usadas para decode de registradores e controle interno. |
| `design/rtl/SoC_completo/UART/uart_lite.v` | `uart_lite` | UART Lite AXI-Lite (TX/RX) com registradores de configuracao/status/dados e linha de interrupcao. |
| `design/rtl/SoC_completo/UART/uart_lite_defs.v` | (defines) | Definicoes de offsets e bits de controle/status da UART Lite. |
| `design/rtl/SoC_completo/SPI/spi_master_axil.v` | `spi_master_axil` | Wrapper AXI-Lite para controle de SPI master por registradores e FIFOs, expondo sinais de IRQ e interface SPI externa. |
| `design/rtl/SoC_completo/SPI/spi_master.v` | `spi_master` | Nucleo SPI master (geracao de clock, shift TX/RX, controle de CS e transferencia serial). |
| `design/rtl/SoC_completo/SPI/axis_fifo.v` | `axis_fifo` | FIFO AXI-Stream usada internamente no subsistema SPI para desacoplamento entre interface de registradores e datapath serial. |
| `design/rtl/SoC_completo/I2C/i2c_master_axil.v` | `i2c_master_axil` | Wrapper AXI-Lite do controlador I2C master com registradores, filas e controle de transacoes via software. |
| `design/rtl/SoC_completo/I2C/i2c_master.v` | `i2c_master` | Motor I2C master de baixo nivel (START/STOP, leitura/escrita de bytes, controle de SCL/SDA, estados de protocolo). |
| `design/rtl/SoC_completo/I2C/i2c_init.v` | `i2c_init` | Sequenciador de inicializacao/configuracao via I2C para execucao automatica de comandos no startup. |
| `design/rtl/SoC_completo/I2C/i2c_single_reg.v` | `i2c_single_reg` | Bloco de registrador AXI-Lite auxiliar para controle/estado no subsistema I2C. |
| `design/rtl/SoC_completo/I2C/axis_fifo.v` | `axis_fifo` | FIFO AXI-Stream usada no caminho de comandos/dados do controlador I2C. |
| `design/rtl/SoC_completo/INTC/axil_intc.v` | `axil_intc` | Controlador de interrupcoes AXI-Lite: mascara/pending por fonte e consolidacao para uma saida global para a CPU. |

## Descricao funcional de cada modulo (`module`)

Escopo: modulos RTL usados no SoC atual (sem testbenches).

| Modulo | Arquivo `.v` | Descricao funcional |
|---|---|---|
| `soc_top_teste_mem_periph` | `design/rtl/top/top_teste.v` | Integracao completa do SoC: conecta CPU, memoria, interconnects, perifericos e roteamento de interrupcoes. |
| `picorv32` | `design/rtl/cpu/picorv32.v` | Core RISC-V RV32I principal (pipeline, decode/execute, acesso a memoria e sinais de interrupcao). |
| `picorv32_regs` | `design/rtl/cpu/picorv32.v` | Banco de registradores do PicoRV32 (x0..x31), separado para variantes de implementacao/otimizacao. |
| `picorv32_pcpi_mul` | `design/rtl/cpu/picorv32.v` | Coprocessador PCPI de multiplicacao iterativa para instrucoes de multiplicacao. |
| `picorv32_pcpi_fast_mul` | `design/rtl/cpu/picorv32.v` | Coprocessador PCPI de multiplicacao com caminho mais rapido (tradeoff de area/desempenho). |
| `picorv32_pcpi_div` | `design/rtl/cpu/picorv32.v` | Coprocessador PCPI para divisao/modulo. |
| `picorv32_axi` | `design/rtl/cpu/picorv32.v` | Wrapper do core com interface AXI (mestre), usado pelo top para acesso ao barramento do SoC. |
| `picorv32_axi_adapter` | `design/rtl/cpu/picorv32.v` | Adaptador entre interface nativa de memoria do core e canal AXI. |
| `picorv32_wb` | `design/rtl/cpu/picorv32.v` | Wrapper alternativo para barramento Wishbone (nao usado no top atual). |
| `axi_lite_ic_1x2` | `design/rtl/bus/axi_1_2.v` | Interconnect AXI-Lite 1x2 para separar trafego entre regiao de memoria e regiao de perifericos. |
| `axi_lite_interconnect_1x6` | `design/rtl/bus/axi_interconect_1_6.v` | Interconnect AXI-Lite 1x6 para decodificar e encaminhar acessos aos 6 perifericos. |
| `axi_lite_ram` | `design/rtl/bus/axi_mem.v` | Memoria RAM mapeada em AXI-Lite com leitura/escrita por bytes e preload opcional de firmware. |
| `axilgpio` | `design/rtl/periph/gpio/axilgpio.v` | Periferico GPIO AXI-Lite com registradores de controle de saida, leitura de entrada e IRQ por evento. |
| `skidbuffer` | `design/rtl/periph/gpio/skidbuffer.v` | Buffer de skid para estabilizar handshake em canais de streaming/AXI sob backpressure. |
| `timer` | `design/rtl/periph/timer/timer.v` | Timer com compare, prescaler/postscaler, autoreload e geracao de interrupcao. |
| `uart_lite` | `design/rtl/SoC_completo/UART/uart_lite.v` | UART Lite com interface AXI-Lite para configuracao, TX/RX de dados e status/IRQ. |
| `spi_master_axil` | `design/rtl/SoC_completo/SPI/spi_master_axil.v` | Interface AXI-Lite de alto nivel para comandar o SPI master e seus FIFOs. |
| `spi_master` | `design/rtl/SoC_completo/SPI/spi_master.v` | Motor SPI de baixo nivel (clock serial, shift register, controle de CS e transferencia). |
| `axis_fifo` | `design/rtl/SoC_completo/SPI/axis_fifo.v` | FIFO AXI-Stream usada no caminho de dados do SPI. |
| `i2c_master_axil` | `design/rtl/SoC_completo/I2C/i2c_master_axil.v` | Interface AXI-Lite para controle do I2C master, filas de comando e estado do barramento. |
| `i2c_master` | `design/rtl/SoC_completo/I2C/i2c_master.v` | Motor I2C master de protocolo (START/STOP, ACK/NACK, leitura/escrita e temporizacao de SCL/SDA). |
| `i2c_init` | `design/rtl/SoC_completo/I2C/i2c_init.v` | Modulo de inicializacao automatica de sequencias I2C na partida. |
| `i2c_single_reg` | `design/rtl/SoC_completo/I2C/i2c_single_reg.v` | Bloco de registrador de apoio para configuracao/status no subsistema I2C. |
| `axis_fifo` | `design/rtl/SoC_completo/I2C/axis_fifo.v` | FIFO AXI-Stream usada no caminho de dados/comandos do I2C. |
| `axil_intc` | `design/rtl/SoC_completo/INTC/axil_intc.v` | Controlador de interrupcoes AXI-Lite com mascara, pending e consolidacao em uma IRQ global da CPU. |

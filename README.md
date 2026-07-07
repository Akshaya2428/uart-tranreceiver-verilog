# UART Project (Verilog)

A complete UART (Universal Asynchronous Receiver/Transmitter) design in
Verilog, including a parameterized baud rate generator, transmitter,
receiver, top-level integration module, and a self-checking testbench
with waveform dumping.

## Features

- Configurable `CLK_FREQ` and `BAUD_RATE` (via parameters)
- Standard 8-N-1 frame format: 1 start bit, 8 data bits (LSB first), 1 stop bit
- 16x oversampled receiver with mid-bit sampling for reliable capture
- 2-flip-flop input synchronizer on the RX line (metastability protection)
- Framing error detection (`rx_err`)
- Self-checking loopback testbench with `$dumpfile` / `$dumpvars` waveform output

## Project Structure

```
uart-project/
├── src/
│   ├── baud_gen.v      # Parameterized clock divider / baud tick generator
│   ├── uart_tx.v       # UART transmitter FSM
│   ├── uart_rx.v       # UART receiver FSM (16x oversampling)
│   └── uart_top.v      # Top-level module wiring baud_gen + tx + rx
├── tb/
│   └── uart_tb.v       # Testbench (internal loopback, 5 test bytes)
├── docs/               # (optional) diagrams, notes, waveform screenshots
├── .gitignore
├── LICENSE
└── README.md
```

## Block Diagram

The diagram below shows how `uart_top` wires two `baud_gen` instances
(one at 1x baud rate for TX, one at 16x baud rate for RX oversampling)
into the `uart_tx` and `uart_rx` modules:

![UART block diagram](docs/block_diagram.svg)

## Module Overview

| Module      | Description                                                        |
|-------------|---------------------------------------------------------------------|
| `baud_gen`  | Divides `clk` down to a single-cycle tick at `BAUD_RATE * OVERSAMPLE` |
| `uart_tx`   | Serializes an 8-bit byte onto `txd` on each baud tick               |
| `uart_rx`   | Deserializes `rxd` into an 8-bit byte, sampling at bit midpoints    |
| `uart_top`  | Instantiates two `baud_gen`s (1x for TX, 16x for RX) + `uart_tx` + `uart_rx` |

## Ports (uart_top)

| Port        | Direction | Width | Description                          |
|-------------|-----------|-------|---------------------------------------|
| `clk`       | input     | 1     | System clock                          |
| `rst_n`     | input     | 1     | Active-low asynchronous reset         |
| `tx_start`  | input     | 1     | Pulse to begin transmitting `tx_data` |
| `tx_data`   | input     | 8     | Byte to transmit                      |
| `txd`       | output    | 1     | Serial transmit line                  |
| `tx_busy`   | output    | 1     | High while a frame is in flight       |
| `tx_done`   | output    | 1     | 1-cycle pulse when TX frame completes |
| `rxd`       | input     | 1     | Serial receive line                   |
| `rx_data`   | output    | 8     | Byte received                         |
| `rx_dv`     | output    | 1     | 1-cycle pulse when `rx_data` is valid |
| `rx_err`    | output    | 1     | High if stop bit was invalid          |

## Waveform

Below is the actual simulation waveform (extracted from `uart_tb.vcd`)
showing the testbench sending byte `0xA5` through the loopback path:

![UART waveform](docs/uart_waveform.svg)

- `tx_start` pulses for one cycle to kick off transmission
- `txd` (looped back to `rxd`) shows the serial frame: start bit (0) → 8 data bits → stop bit (1)
- `tx_busy` stays high for the duration of the frame
- `rx_dv` pulses once the receiver has fully captured the byte
- `rx_data` updates from `0x00` to the received value `0xA5`, matching what was sent

### Captured in EPWave (EDA Playground)

Real waveform capture from running the testbench on EDA Playground with
Icarus Verilog, confirming all 5 test bytes pass with 0 failures
(`pass_count` reaches 5, `fail_count` stays at 0):

![EPWave screenshot](docs/epwave_screenshot.png)

## Simulating Locally (Icarus Verilog)

```bash
iverilog -g2012 -o uart_sim src/baud_gen.v src/uart_tx.v src/uart_rx.v src/uart_top.v tb/uart_tb.v
vvp uart_sim
gtkwave uart_tb.vcd
```

Expected output:
```
PASS[0]: sent=0xa5  received=0xa5  err=0
PASS[1]: sent=0x3c  received=0x3c  err=0
PASS[2]: sent=0xff  received=0xff  err=0
PASS[3]: sent=0x00  received=0x00  err=0
PASS[4]: sent=0x55  received=0x55  err=0
TEST SUMMARY: 5 passed, 0 failed (out of 5)
```

## Simulating on EDA Playground

1. Paste all files from `src/` into the **Design.v** pane.
2. Paste `tb/uart_tb.v` into the **Testbench.v** pane.
3. Select **Icarus Verilog** as the simulator.
4. Check **"Open EPWave after run"**.
5. Click **Run**, then add signals in EPWave from the `uart_tb` hierarchy and
   click "Zoom Full" to view the waveforms.

## Using on Real Hardware

Instantiate `uart_top` with your board's actual clock frequency and desired
baud rate, e.g.:

```verilog
uart_top #(
    .CLK_FREQ (50_000_000),
    .BAUD_RATE(115200)
) uart_inst (
    ...
);
```

## License

MIT License — see [LICENSE](LICENSE).

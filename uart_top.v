// ============================================================
// uart_top.v : Top-level UART (TX + RX + Baud Generators)
// ============================================================
module uart_top #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire       clk,
    input  wire       rst_n,

    // ---- Transmit side ----
    input  wire       tx_start,
    input  wire [7:0]  tx_data,
    output wire        txd,
    output wire        tx_busy,
    output wire        tx_done,

    // ---- Receive side ----
    input  wire        rxd,
    output wire [7:0]  rx_data,
    output wire        rx_dv,
    output wire        rx_err
);

    wire baud_tick_tx;
    wire baud_tick_rx16;

    baud_gen #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .OVERSAMPLE(1)
    ) u_baud_tx (
        .clk   (clk),
        .rst_n (rst_n),
        .tick  (baud_tick_tx)
    );

    baud_gen #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .OVERSAMPLE(16)
    ) u_baud_rx (
        .clk   (clk),
        .rst_n (rst_n),
        .tick  (baud_tick_rx16)
    );

    uart_tx u_tx (
        .clk      (clk),
        .rst_n    (rst_n),
        .baud_tick(baud_tick_tx),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .txd      (txd),
        .tx_busy  (tx_busy),
        .tx_done  (tx_done)
    );

    uart_rx u_rx (
        .clk        (clk),
        .rst_n      (rst_n),
        .baud_tick16(baud_tick_rx16),
        .rxd        (rxd),
        .rx_data    (rx_data),
        .rx_dv      (rx_dv),
        .rx_err     (rx_err)
    );

endmodule

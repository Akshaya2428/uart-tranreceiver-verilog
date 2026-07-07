// ============================================================
// uart_tx.v : UART Transmitter
// Frame format: 1 start bit (0), 8 data bits (LSB first),
//               1 stop bit (1). No parity.
// ============================================================
module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       baud_tick,   // 1 pulse per bit period
    input  wire       tx_start,    // pulse to begin sending tx_data
    input  wire [7:0] tx_data,
    output reg        txd,         // serial output line
    output reg        tx_busy,     // high while a frame is in flight
    output reg        tx_done      // 1-cycle pulse when frame complete
);

    localparam IDLE  = 2'd0,
               START = 2'd1,
               DATA  = 2'd2,
               STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] bit_cnt;
    reg [7:0] tx_shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            txd      <= 1'b1;   // idle line is high (mark)
            tx_busy  <= 1'b0;
            tx_done  <= 1'b0;
            bit_cnt  <= 4'd0;
            tx_shift <= 8'd0;
        end else begin
            tx_done <= 1'b0;

            case (state)
                IDLE: begin
                    txd <= 1'b1;
                    if (tx_start) begin
                        tx_shift <= tx_data;
                        tx_busy  <= 1'b1;
                        txd      <= 1'b0;    // start bit begins immediately
                        state    <= START;
                    end
                end

                START: begin
                    if (baud_tick) begin     // start-bit period elapsed
                        txd     <= tx_shift[0];
                        bit_cnt <= 4'd1;
                        state   <= DATA;
                    end
                end

                DATA: begin
                    if (baud_tick) begin
                        if (bit_cnt == 4'd8) begin
                            txd   <= 1'b1;   // stop bit begins
                            state <= STOP;
                        end else begin
                            txd     <= tx_shift[bit_cnt];
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                end

                STOP: begin
                    if (baud_tick) begin     // stop-bit period elapsed
                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;
                        state   <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

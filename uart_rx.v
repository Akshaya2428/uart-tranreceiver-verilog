// ============================================================
// uart_rx.v : UART Receiver
// Uses a 16x-oversampled baud tick (baud_tick16) so that each
// bit period is sampled at its midpoint for reliable capture.
// Frame format: 1 start bit (0), 8 data bits (LSB first),
//               1 stop bit (1). No parity.
// ============================================================
module uart_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       baud_tick16,  // 16 pulses per bit period
    input  wire       rxd,          // serial input line
    output reg  [7:0] rx_data,      // received byte
    output reg        rx_dv,        // 1-cycle pulse: rx_data valid
    output reg        rx_err        // framing error (bad stop bit)
);

    localparam IDLE  = 2'd0,
               START = 2'd1,
               DATA  = 2'd2,
               STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] sample_cnt;   // 0..15 position within current bit period
    reg [2:0] bit_idx;
    reg [7:0] rx_shift;

    // 2-flip-flop synchronizer to avoid metastability on rxd
    reg rxd_s1, rxd_s2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rxd_s1 <= 1'b1;
            rxd_s2 <= 1'b1;
        end else begin
            rxd_s1 <= rxd;
            rxd_s2 <= rxd_s1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            sample_cnt <= 4'd0;
            bit_idx    <= 3'd0;
            rx_shift   <= 8'd0;
            rx_data    <= 8'd0;
            rx_dv      <= 1'b0;
            rx_err     <= 1'b0;
        end else begin
            rx_dv <= 1'b0;

            case (state)
                IDLE: begin
                    if (rxd_s2 == 1'b0) begin   // possible start bit edge
                        sample_cnt <= 4'd0;
                        state      <= START;
                    end
                end

                START: begin
                    if (baud_tick16) begin
                        sample_cnt <= sample_cnt + 1'b1;
                        if (sample_cnt == 4'd7) begin       // mid of start bit
                            if (rxd_s2 == 1'b0) begin        // confirm real start
                                sample_cnt <= 4'd0;
                                bit_idx    <= 3'd0;
                                state      <= DATA;
                            end else begin
                                state <= IDLE;               // false start / glitch
                            end
                        end
                    end
                end

                DATA: begin
                    if (baud_tick16) begin
                        sample_cnt <= sample_cnt + 1'b1;
                        if (sample_cnt == 4'd7)
                            rx_shift[bit_idx] <= rxd_s2;      // sample mid-bit
                        if (sample_cnt == 4'd15) begin
                            sample_cnt <= 4'd0;
                            if (bit_idx == 3'd7)
                                state <= STOP;
                            else
                                bit_idx <= bit_idx + 1'b1;
                        end
                    end
                end

                STOP: begin
                    if (baud_tick16) begin
                        sample_cnt <= sample_cnt + 1'b1;
                        if (sample_cnt == 4'd15) begin
                            sample_cnt <= 4'd0;
                            rx_data    <= rx_shift;
                            rx_dv      <= 1'b1;
                            rx_err     <= ~rxd_s2;            // stop bit should be 1
                            state      <= IDLE;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

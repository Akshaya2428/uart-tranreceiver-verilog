// ============================================================
// baud_gen.v : Baud Rate Generator
// Divides the system clock down to produce a single-cycle
// "tick" pulse at the desired baud rate (or at OVERSAMPLE x
// the baud rate, used by the receiver for mid-bit sampling).
// ============================================================
module baud_gen #(
    parameter CLK_FREQ   = 50_000_000,  // system clock frequency (Hz)
    parameter BAUD_RATE  = 9600,        // desired UART baud rate
    parameter OVERSAMPLE = 1            // 1 for TX, 16 for RX (oversampling)
)(
    input  wire clk,
    input  wire rst_n,     // active-low async reset
    output reg  tick        // 1-cycle-wide pulse at BAUD_RATE*OVERSAMPLE
);

    localparam integer DIVISOR = CLK_FREQ / (BAUD_RATE * OVERSAMPLE);

    integer count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            tick  <= 1'b0;
        end else if (count == DIVISOR - 1) begin
            count <= 0;
            tick  <= 1'b1;
        end else begin
            count <= count + 1;
            tick  <= 1'b0;
        end
    end

endmodule

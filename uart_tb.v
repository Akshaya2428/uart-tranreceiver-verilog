// ============================================================
// uart_tb.v : Testbench for uart_top (loopback test)
// txd is looped back to rxd internally. Several bytes are
// sent through uart_tx and checked against what uart_rx
// captures. Waveforms are dumped to uart_tb.vcd (viewable in
// GTKWave or similar).
// ============================================================
`timescale 1ns/1ps

module uart_tb;

    // Small CLK_FREQ/BAUD_RATE values keep the simulation short.
    // TX divisor  = CLK_FREQ/BAUD_RATE      = 16000/1000 = 16
    // RX divisor  = CLK_FREQ/(BAUD_RATE*16) = 16000/16000 = 1
    parameter CLK_FREQ  = 16000;
    parameter BAUD_RATE = 1000;

    reg        clk;
    reg        rst_n;
    reg        tx_start;
    reg [7:0]  tx_data;
    wire       txd;
    wire       tx_busy;
    wire       tx_done;

    wire [7:0] rx_data;
    wire       rx_dv;
    wire       rx_err;

    // Loopback: receiver input is driven directly by transmitter output
    wire rxd = txd;

    uart_top #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) DUT (
        .clk      (clk),
        .rst_n    (rst_n),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .txd      (txd),
        .tx_busy  (tx_busy),
        .tx_done  (tx_done),
        .rxd      (rxd),
        .rx_data  (rx_data),
        .rx_dv    (rx_dv),
        .rx_err   (rx_err)
    );

    // Free-running clock
    always #5 clk = ~clk;   // 10ns period

    reg [7:0] test_bytes [0:4];
    integer i;
    integer pass_count, fail_count;

    initial begin
        test_bytes[0] = 8'hA5;
        test_bytes[1] = 8'h3C;
        test_bytes[2] = 8'hFF;
        test_bytes[3] = 8'h00;
        test_bytes[4] = 8'h55;

        clk        = 1'b0;
        rst_n      = 1'b0;
        tx_start   = 1'b0;
        tx_data    = 8'h00;
        pass_count = 0;
        fail_count = 0;

        // ---- Waveform dump ----
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);

        #50 rst_n = 1'b1;
        #20;

        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
            tx_data  = test_bytes[i];
            tx_start = 1'b1;
            @(posedge clk);
            tx_start = 1'b0;

            // wait for received data to become valid
            wait (rx_dv == 1'b1);
            @(posedge clk);

            if (rx_data === test_bytes[i] && rx_err == 1'b0) begin
                $display("PASS[%0d]: sent=0x%02h  received=0x%02h  err=%b",
                          i, test_bytes[i], rx_data, rx_err);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL[%0d]: sent=0x%02h  received=0x%02h  err=%b",
                          i, test_bytes[i], rx_data, rx_err);
                fail_count = fail_count + 1;
            end

            wait (tx_busy == 1'b0);
            #200;
        end

        #200;
        $display("--------------------------------------------------");
        $display("TEST SUMMARY: %0d passed, %0d failed (out of %0d)",
                   pass_count, fail_count, pass_count + fail_count);
        $display("--------------------------------------------------");
        $finish;
    end

    // Safety timeout in case something hangs
    initial begin
        #200000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule

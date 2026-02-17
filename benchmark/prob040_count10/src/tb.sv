`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output reg reset,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);

    task reset_test(input async=0);
        bit arfail, srfail, datafail;

        @(posedge clk);
        @(posedge clk) reset <= 0;
        repeat(3) @(posedge clk);

        @(negedge clk) begin
            datafail = !tb_match;
            reset <= 1;
        end

        @(posedge clk) arfail = !tb_match;

        @(posedge clk) begin
            srfail = !tb_match;
            reset <= 0;
        end

        if (srfail)
            $display("Hint: Your reset doesn't seem to be working.");
        else if (arfail && (async || !datafail))
            $display("Hint: Your reset should be %0s, but doesn't appear to be.",
                     async ? "asynchronous" : "synchronous");
    endtask

    task wavedrom_start(input [511:0] title = "");
    endtask

    task wavedrom_stop;
        #1;
    endtask

    initial begin
        reset <= 1;

        wavedrom_start("Synchronous reset and counting");
        reset_test();

        repeat(12) @(posedge clk);

        wavedrom_stop();
        @(posedge clk);

        repeat(400) @(posedge clk, negedge clk) begin
            reset <= !($random & 31);
        end

        #1 $finish;
    end

endmodule



module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;
        int clocks;
    } stats;

    stats stats1;

    wire [511:0] wavedrom_title;
    wire wavedrom_enable;

    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic reset;
    logic [3:0] q_ref;
    logic [3:0] q_dut;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars();
    end

    wire tb_match;

    stimulus_gen stim1 (
        .clk(clk),
        .reset(reset),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable),
        .tb_match(tb_match)
    );

    RefModule good1 (
        .clk(clk),
        .reset(reset),
        .q(q_ref)
    );

    TopModule top_module1 (
        .clk(clk),
        .reset(reset),
        .q(q_dut)
    );

    assign tb_match = (q_ref === q_dut);

    always @(posedge clk or negedge clk) begin
        stats1.clocks++;

        if (!tb_match) begin
            if (stats1.errors == 0)
                stats1.errortime = $time;
            stats1.errors++;
        end

        if (q_ref !== q_dut) begin
            if (stats1.errors_q == 0)
                stats1.errortime_q = $time;
            stats1.errors_q++;
        end
    end

    final begin
        if (stats1.errors_q)
            $display("Hint: Output 'q' has %0d mismatches. First mismatch occurred at time %0d.",
                     stats1.errors_q, stats1.errortime_q);
        else
            $display("Hint: Output 'q' has no mismatches.");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n",
                 stats1.errors, stats1.clocks);

        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

endmodule

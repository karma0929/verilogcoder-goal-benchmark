`timescale 1 ps / 1 ps
`define OK 12
`define INCORRECT 13

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_done;
        int errortime_done;
        int errors_signature;
        int errortime_signature;
        int errors_dbg_x3;
        int errortime_dbg_x3;
        int errors_dbg_x4;
        int errortime_dbg_x4;
        int errors_dbg_x5;
        int errortime_dbg_x5;
        int errors_dbg_x6;
        int errortime_dbg_x6;
        int errors_dbg_x7;
        int errortime_dbg_x7;
        int errors_dbg_mem2;
        int errortime_dbg_mem2;
        int errors_dbg_mem3;
        int errortime_dbg_mem3;
        int errors_dbg_commit_count;
        int errortime_dbg_commit_count;
        int clocks;
    } stats_t;

    stats_t stats1;

    reg clk = 1'b0;
    reg reset = 1'b1;
    reg checking_enable = 1'b0;

    logic done_ref;
    logic [31:0] signature_ref;
    logic [31:0] dbg_x3_ref;
    logic [31:0] dbg_x4_ref;
    logic [31:0] dbg_x5_ref;
    logic [31:0] dbg_x6_ref;
    logic [31:0] dbg_x7_ref;
    logic [31:0] dbg_mem2_ref;
    logic [31:0] dbg_mem3_ref;
    logic [7:0]  dbg_commit_count_ref;

    logic done_dut;
    logic [31:0] signature_dut;
    logic [31:0] dbg_x3_dut;
    logic [31:0] dbg_x4_dut;
    logic [31:0] dbg_x5_dut;
    logic [31:0] dbg_x6_dut;
    logic [31:0] dbg_x7_dut;
    logic [31:0] dbg_mem2_dut;
    logic [31:0] dbg_mem3_dut;
    logic [7:0]  dbg_commit_count_dut;

    initial forever #5 clk = ~clk;

    initial begin
        stats1 = '0;
        $dumpfile("wave.vcd");
        $dumpvars();
    end

    RefModule good1 (
        .clk(clk),
        .reset(reset),
        .done(done_ref),
        .signature(signature_ref),
        .dbg_x3(dbg_x3_ref),
        .dbg_x4(dbg_x4_ref),
        .dbg_x5(dbg_x5_ref),
        .dbg_x6(dbg_x6_ref),
        .dbg_x7(dbg_x7_ref),
        .dbg_mem2(dbg_mem2_ref),
        .dbg_mem3(dbg_mem3_ref),
        .dbg_commit_count(dbg_commit_count_ref)
    );

    TopModule top_module1 (
        .clk(clk),
        .reset(reset),
        .done(done_dut),
        .signature(signature_dut),
        .dbg_x3(dbg_x3_dut),
        .dbg_x4(dbg_x4_dut),
        .dbg_x5(dbg_x5_dut),
        .dbg_x6(dbg_x6_dut),
        .dbg_x7(dbg_x7_dut),
        .dbg_mem2(dbg_mem2_dut),
        .dbg_mem3(dbg_mem3_dut),
        .dbg_commit_count(dbg_commit_count_dut)
    );

    wire tb_match = checking_enable &&
        (done_ref === done_dut) &&
        (signature_ref === signature_dut) &&
        (dbg_x3_ref === dbg_x3_dut) &&
        (dbg_x4_ref === dbg_x4_dut) &&
        (dbg_x5_ref === dbg_x5_dut) &&
        (dbg_x6_ref === dbg_x6_dut) &&
        (dbg_x7_ref === dbg_x7_dut) &&
        (dbg_mem2_ref === dbg_mem2_dut) &&
        (dbg_mem3_ref === dbg_mem3_dut) &&
        (dbg_commit_count_ref === dbg_commit_count_dut);

    initial begin
        repeat (3) @(posedge clk);
        reset <= 1'b0;
        checking_enable <= 1'b1;
    end

    always @(posedge clk or negedge clk) begin
        if (checking_enable) begin
            stats1.clocks++;

            if (!tb_match) begin
                if (stats1.errors == 0)
                    stats1.errortime = $time;
                stats1.errors++;
            end

            if (done_ref !== done_dut) begin
                if (stats1.errors_done == 0)
                    stats1.errortime_done = $time;
                stats1.errors_done++;
            end

            if (signature_ref !== signature_dut) begin
                if (stats1.errors_signature == 0)
                    stats1.errortime_signature = $time;
                stats1.errors_signature++;
            end

            if (dbg_x3_ref !== dbg_x3_dut) begin
                if (stats1.errors_dbg_x3 == 0)
                    stats1.errortime_dbg_x3 = $time;
                stats1.errors_dbg_x3++;
            end

            if (dbg_x4_ref !== dbg_x4_dut) begin
                if (stats1.errors_dbg_x4 == 0)
                    stats1.errortime_dbg_x4 = $time;
                stats1.errors_dbg_x4++;
            end

            if (dbg_x5_ref !== dbg_x5_dut) begin
                if (stats1.errors_dbg_x5 == 0)
                    stats1.errortime_dbg_x5 = $time;
                stats1.errors_dbg_x5++;
            end

            if (dbg_x6_ref !== dbg_x6_dut) begin
                if (stats1.errors_dbg_x6 == 0)
                    stats1.errortime_dbg_x6 = $time;
                stats1.errors_dbg_x6++;
            end

            if (dbg_x7_ref !== dbg_x7_dut) begin
                if (stats1.errors_dbg_x7 == 0)
                    stats1.errortime_dbg_x7 = $time;
                stats1.errors_dbg_x7++;
            end

            if (dbg_mem2_ref !== dbg_mem2_dut) begin
                if (stats1.errors_dbg_mem2 == 0)
                    stats1.errortime_dbg_mem2 = $time;
                stats1.errors_dbg_mem2++;
            end

            if (dbg_mem3_ref !== dbg_mem3_dut) begin
                if (stats1.errors_dbg_mem3 == 0)
                    stats1.errortime_dbg_mem3 = $time;
                stats1.errors_dbg_mem3++;
            end

            if (dbg_commit_count_ref !== dbg_commit_count_dut) begin
                if (stats1.errors_dbg_commit_count == 0)
                    stats1.errortime_dbg_commit_count = $time;
                stats1.errors_dbg_commit_count++;
            end

            if (done_ref && done_dut) begin
                #1 $finish;
            end
        end
    end

    final begin
        if (stats1.errors_done)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "done", stats1.errors_done, stats1.errortime_done);
        else
            $display("Hint: Output '%s' has no mismatches.", "done");

        if (stats1.errors_signature)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "signature", stats1.errors_signature, stats1.errortime_signature);
        else
            $display("Hint: Output '%s' has no mismatches.", "signature");

        if (stats1.errors_dbg_x3)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_x3", stats1.errors_dbg_x3, stats1.errortime_dbg_x3);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_x3");

        if (stats1.errors_dbg_x4)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_x4", stats1.errors_dbg_x4, stats1.errortime_dbg_x4);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_x4");

        if (stats1.errors_dbg_x5)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_x5", stats1.errors_dbg_x5, stats1.errortime_dbg_x5);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_x5");

        if (stats1.errors_dbg_x6)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_x6", stats1.errors_dbg_x6, stats1.errortime_dbg_x6);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_x6");

        if (stats1.errors_dbg_x7)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_x7", stats1.errors_dbg_x7, stats1.errortime_dbg_x7);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_x7");

        if (stats1.errors_dbg_mem2)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_mem2", stats1.errors_dbg_mem2, stats1.errortime_dbg_mem2);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_mem2");

        if (stats1.errors_dbg_mem3)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_mem3", stats1.errors_dbg_mem3, stats1.errortime_dbg_mem3);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_mem3");

        if (stats1.errors_dbg_commit_count)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_commit_count", stats1.errors_dbg_commit_count, stats1.errortime_dbg_commit_count);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_commit_count");

        $display("Hint: Total mismatched samples is %0d out of %0d samples", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
    end

    initial begin
        #20000;
        $display("TIMEOUT");
        $finish();
    end

endmodule

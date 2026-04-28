module prob200_power_top (
    input  clk,
    input  reset,
    output done,
    output [31:0] signature,
    output [31:0] dbg_x3,
    output [31:0] dbg_x4,
    output [31:0] dbg_x5,
    output [31:0] dbg_x6,
    output [31:0] dbg_x7,
    output [31:0] dbg_mem2,
    output [31:0] dbg_mem3,
    output [7:0]  dbg_commit_count
);
    TopModule dut (
        .clk(clk),
        .reset(reset),
        .done(done),
        .signature(signature),
        .dbg_x3(dbg_x3),
        .dbg_x4(dbg_x4),
        .dbg_x5(dbg_x5),
        .dbg_x6(dbg_x6),
        .dbg_x7(dbg_x7),
        .dbg_mem2(dbg_mem2),
        .dbg_mem3(dbg_mem3),
        .dbg_commit_count(dbg_commit_count)
    );
endmodule

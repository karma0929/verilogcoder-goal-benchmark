module prob105_ref_top (
    input  clk,
    input  load,
    input  [1:0] ena,
    input  [99:0] data,
    output [99:0] q
);
    RefModule dut (
        .clk(clk),
        .load(load),
        .ena(ena),
        .data(data),
        .q(q)
    );
endmodule

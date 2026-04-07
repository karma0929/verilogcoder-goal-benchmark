module prob130_ref_top (
    input  [3:0] a,
    input  [3:0] b,
    input  [3:0] c,
    input  [3:0] d,
    input  [3:0] e,
    output [3:0] q
);
    RefModule dut (
        .a(a), .b(b), .c(c), .d(d), .e(e), .q(q)
    );
endmodule

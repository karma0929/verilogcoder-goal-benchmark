module prob230_ref (
    input wire clk
);
    wire [7:0] done_y;
    wire       done_flag;

    TopModule u_top (
        .clk(clk),
        .reset(1'b0),
        .valid(1'b0),
        .a(8'd0),
        .b(8'd0),
        .op(2'b00),
        .y(done_y),
        .done(done_flag)
    );
endmodule

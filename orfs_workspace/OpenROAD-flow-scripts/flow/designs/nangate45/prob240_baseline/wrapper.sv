module prob240_baseline (
    input  wire        clk,
    output wire        obs_valid,
    output wire [31:0] obs_y,
    output wire [7:0]  obs_tag
);
    wire        done_out_valid;
    wire [31:0] done_out_y;
    wire [7:0]  done_out_tag;

    TopModule u_top (
        .clk(clk),
        .reset(1'b0),
        .in_valid(1'b1),
        .in_a(16'd0),
        .in_b(16'd0),
        .in_mode(2'b00),
        .out_valid(done_out_valid),
        .out_y(done_out_y),
        .out_tag(done_out_tag)
    );

    assign obs_valid = done_out_valid;
    assign obs_y = done_out_y;
    assign obs_tag = done_out_tag;
endmodule

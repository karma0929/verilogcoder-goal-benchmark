module TopModule (
    input  wire       clk,
    input  wire       reset,
    input  wire       valid,
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [1:0] op,
    output wire [7:0] y,
    output wire       done
);
    assign y = 8'h00;
    assign done = 1'b0;
endmodule

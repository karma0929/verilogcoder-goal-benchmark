module TopModule (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] in,
    output logic [7:0] out,
    input  logic       valid,
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [2:0] op,
    output logic [7:0] y,
    output logic       done
);

    // Internal register to hold the input value
    logic [7:0] reg_out;

    // Sequential logic to register the input
    always @(posedge clk) begin
        if (reset) begin
            reg_out <= 0;
        end else begin
            reg_out <= in;
        end
    end

    // Instantiation of external core_impl module
    core_impl core_instance (
        .clk(clk),
        .reset(reset),
        .in(reg_out),
        .out(out),
        .valid(valid),
        .a(a),
        .b(b),
        .op(op),
        .y(y),
        .done(done)
    );

endmodule
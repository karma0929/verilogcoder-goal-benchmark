module TopModule (
    input  logic       clk,
    input  logic       reset,
    input  logic       valid,
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [1:0] op,
    output logic [7:0] y,
    output logic       done
);
    logic [7:0] core_y;

    core_ops u_core_ops (
        .a(a),
        .b(b),
        .op(op),
        .y(core_y)
    );

    always @(posedge clk) begin
        if (reset) begin
            y <= 8'h00;
            done <= 1'b0;
        end else if (valid) begin
            y <= core_y;
            done <= 1'b1;
        end else begin
            y <= y;
            done <= 1'b0;
        end
    end
endmodule

module core_ops (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [1:0] op,
    output logic [7:0] y
);
    always @(*) begin
        case (op)
            2'b00: y = a + b;
            2'b01: y = a ^ b;
            2'b10: y = a & b;
            default: y = a - b;
        endcase
    end
endmodule

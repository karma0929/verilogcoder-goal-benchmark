module TopModule
(
    input  logic       clk,
    input  logic       reset,
    input  logic       valid,
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [2:0] op,
    output logic [7:0] y,
    output logic       done
);

    // Sequential logic for registering the input data
    logic [7:0] reg_a, reg_b;
    logic [2:0] reg_op;
    logic       reg_valid;

    always @(posedge clk) begin
        if (reset) begin
            reg_a <= 0;
            reg_b <= 0;
            reg_op <= 0;
            reg_valid <= 0;
            done <= 0;
        end else begin
            reg_a <= a;
            reg_b <= b;
            reg_op <= op;
            reg_valid <= valid;
        end
    end

    // Combinational logic to process the operation
    always @(*) begin
        if (reg_valid) begin
            case (reg_op)
                3'b000: y = reg_a + reg_b;
                3'b001: y = reg_a - reg_b;
                3'b010: y = reg_a & reg_b;
                3'b011: y = reg_a | reg_b;
                3'b100: y = reg_a ^ reg_b;
                default: y = 0; // Ensure default case is correctly handled
            endcase
            done = 1;
        end else begin
            y = 0;
            done = 0;
        end
    end

endmodule

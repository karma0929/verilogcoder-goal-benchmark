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

    // Define a register to hold the input values and operation
    logic [7:0] reg_a, reg_b;
    logic [2:0] reg_op;
    logic       reg_valid;

    // Sequential logic for registering the input signals
    always @(posedge clk) begin
        if (reset) begin
            reg_a <= 0;
            reg_b <= 0;
            reg_op <= 0;
            reg_valid <= 0;
        end else begin
            reg_a <= a;
            reg_b <= b;
            reg_op <= op;
            reg_valid <= valid;
        end
    end

    // Combinational logic to perform operation based on op code
    always @(*) begin
        case (reg_op)
            3'b000: y = reg_a + reg_b;  // Addition
            3'b001: y = reg_a - reg_b;  // Subtraction
            3'b010: y = reg_a & reg_b;  // AND
            3'b011: y = reg_a | reg_b;  // OR
            3'b100: y = reg_a ^ reg_b;  // XOR
            3'b101: y = (reg_a << 1) | (reg_a >> 7); // Rotate left
            3'b110: y = (reg_a >> 1) | (reg_a << 7); // Rotate right
            default: y = 8'h00;         // Default case for undefined operations
        endcase
    end

    // Control signal for done
    assign done = reg_valid;

endmodule
module TopModule
(
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

    // Sequential logic for registering the input signal
    logic [7:0] reg_out;

    always @(posedge clk) begin
        if (reset) begin
            reg_out <= 0;
        end else begin
            reg_out <= in;
        end
    end

    // Combinational logic to increment the registered value
    always @(*) begin
        out = reg_out + 1;
    end

    // Operation logic based on op
    always @(*) begin
        case (op)
            3'b000: y = a + b; // Addition
            3'b001: y = a - b; // Subtraction
            3'b010: y = a & b; // Bitwise AND
            3'b011: y = a | b; // Bitwise OR
            3'b100: y = a << 1; // Rotate left
            3'b101: y = a >> 1; // Rotate right
            default: y = 8'bx; // Undefined operation
        endcase
    end

    // Done signal logic
    assign done = valid;

endmodule
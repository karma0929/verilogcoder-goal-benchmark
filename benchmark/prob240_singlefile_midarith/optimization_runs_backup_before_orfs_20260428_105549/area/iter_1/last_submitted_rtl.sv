module TopModule
(
    input  logic       clk,
    input  logic       reset,
    input  logic       in_valid,
    input  logic [7:0] in_a,
    input  logic [7:0] in_b,
    input  logic [2:0] in_mode,
    output logic       out_valid,
    output logic [7:0] out_y,
    output logic [2:0] out_tag
);

    logic [7:0] registered_in;

    always @(posedge clk) begin
        if (reset) begin
            registered_in <= 0;
            out_valid <= 0;
            out_y <= 0;  // Ensure out_y is reset to 0
        end else if (in_valid) begin
            registered_in <= in_a;
            out_valid <= 1;
        end
    end

    // Update out_y only when out_valid is high
    always @(*) begin
        if (out_valid) begin
            case (in_mode)
                3'b000: out_y = registered_in + in_b;  // Add operation
                3'b001: out_y = registered_in - in_b;  // Subtract operation
                3'b010: out_y = registered_in & in_b;  // AND operation
                3'b011: out_y = registered_in | in_b;  // OR operation
                3'b100: out_y = registered_in ^ in_b;  // XOR operation
                default: out_y = registered_in + 1;    // Default increment
            endcase
        end
        out_tag = in_mode;
    end

endmodule

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
    output logic [7:0] out_tag
);

    // Registers to store inputs and outputs
    logic [7:0] reg_in_a, reg_in_b;
    logic [2:0] reg_in_mode;
    logic       reg_in_valid;

    // Register outputs to maintain state
    logic [7:0] reg_out_y, reg_out_tag;
    logic       reg_out_valid;

    // Capture inputs on the rising edge of the clock
    always @(posedge clk) begin
        if (reset) begin
            reg_in_a <= 8'b0;
            reg_in_b <= 8'b0;
            reg_in_mode <= 3'b0;
            reg_in_valid <= 1'b0;
            reg_out_valid <= 1'b0;
            reg_out_y <= 8'b0;
            reg_out_tag <= 8'b0;
        end else begin
            reg_in_a <= in_a;
            reg_in_b <= in_b;
            reg_in_mode <= in_mode;
            reg_in_valid <= in_valid;
        end
    end

    // Combinational logic to process inputs and generate outputs
    always @(*) begin
        if (reg_in_valid) begin
            case (reg_in_mode)
                3'b000: begin
                    reg_out_y = reg_in_a + reg_in_b;
                    reg_out_tag = 8'hAA;
                end
                3'b001: begin
                    reg_out_y = reg_in_a - reg_in_b;
                    reg_out_tag = 8'hBB;
                end
                3'b010: begin
                    reg_out_y = reg_in_a & reg_in_b; // Added bitwise AND operation
                    reg_out_tag = 8'hCC; // New tag for this operation
                end
                default: begin
                    reg_out_y = 8'b0;
                    reg_out_tag = 8'h00;
                end
            endcase
            reg_out_valid = 1'b1;
        end else begin
            reg_out_valid = 1'b0;
            reg_out_y = 8'b0;
            reg_out_tag = 8'b0;
        end
    end

    // Assign outputs
    assign out_valid = reg_out_valid;
    assign out_y = reg_out_y;
    assign out_tag = reg_out_tag;

endmodule

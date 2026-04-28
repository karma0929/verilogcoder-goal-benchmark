module TopModule (
    input  logic        clk,
    input  logic        reset,
    input  logic        in_valid,
    input  logic [15:0] in_a,
    input  logic [15:0] in_b,
    input  logic [1:0]  in_mode,
    output logic        out_valid,
    output logic [31:0] out_y,
    output logic [7:0]  out_tag
);

    logic [15:0] reg_in_a;
    logic [15:0] reg_in_b;
    logic reg_out_valid;
    logic [7:0] reg_out_tag;
    logic last_in_valid; // Register to track the last state of in_valid

    always @(posedge clk) begin
        if (reset) begin
            reg_in_a <= 16'd0;
            reg_in_b <= 16'd0;
            reg_out_valid <= 1'b0;
            reg_out_tag <= 8'd0;
            last_in_valid <= 1'b0;
        end else begin
            if (in_valid) begin
                reg_in_a <= in_a;
                reg_in_b <= in_b;
            }
            reg_out_valid <= in_valid;
            if (in_valid && !last_in_valid) begin
                reg_out_tag <= reg_out_tag + 1; // Increment out_tag only on rising edge of in_valid
            end
            last_in_valid <= in_valid; // Update the last_in_valid register
        end
    end

    assign out_valid = reg_out_valid;
    assign out_tag = reg_out_tag;

    always @(*) begin
        case (in_mode)
            2'b00: out_y = {16'd0, reg_in_a} + {16'd0, reg_in_b};
            2'b01: out_y = {16'd0, reg_in_a} * {16'd0, reg_in_b};
            2'b10: out_y = {16'd0, reg_in_a} ^ {16'd0, reg_in_b};
            2'b11: out_y = ({16'd0, reg_in_a} << 1) + ({16'd0, reg_in_b} << 2);
            default: out_y = 32'd0;
        endcase
    end

endmodule

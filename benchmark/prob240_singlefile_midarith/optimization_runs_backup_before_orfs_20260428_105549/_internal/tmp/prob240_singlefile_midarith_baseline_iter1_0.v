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
    // Internal signals for registered inputs and outputs
    logic [15:0] reg_in_a, reg_in_b;
    logic [1:0]  reg_in_mode;
    logic        reg_in_valid;
    logic [7:0]  reg_out_tag;
    logic        last_in_valid; // To detect rising edge of in_valid

    // Registering inputs and handling reg_out_tag increment on rising edge of in_valid
    always @(posedge clk) begin
        if (reset) begin
            reg_in_a <= 16'd0;
            reg_in_b <= 16'd0;
            reg_in_mode <= 2'd0;
            reg_in_valid <= 1'b0;
            reg_out_tag <= 8'd0;
            last_in_valid <= 1'b0;
        end else begin
            reg_in_a <= in_a;
            reg_in_b <= in_b;
            reg_in_mode <= in_mode;
            reg_in_valid <= in_valid;
            if (in_valid && !last_in_valid) // Only increment on rising edge
                reg_out_tag <= (reg_out_tag == 8'hFF) ? 8'd0 : reg_out_tag + 1; // Prevent overflow
            last_in_valid <= in_valid;
        end
    end

    // Output logic
    always @(posedge clk) begin
        if (reset) begin
            out_valid <= 1'b0;
            out_y <= 32'd0;
            out_tag <= 8'd0;
        end else begin
            out_valid <= reg_in_valid;
            out_tag <= reg_out_tag;
            case (reg_in_mode)
                2'b00: out_y <= {16'd0, reg_in_a} + {16'd0, reg_in_b};
                2'b01: out_y <= {16'd0, reg_in_a} * {16'd0, reg_in_b};
                2'b10: out_y <= {16'd0, reg_in_a} ^ {16'd0, reg_in_b};
                2'b11: out_y <= ({16'd0, reg_in_a} << 1) + ({16'd0, reg_in_b} << 2);
                default: out_y <= 32'd0;
            endcase
        end
    end
endmodule
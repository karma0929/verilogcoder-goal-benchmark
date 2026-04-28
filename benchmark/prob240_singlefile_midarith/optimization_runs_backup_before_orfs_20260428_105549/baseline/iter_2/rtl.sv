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

    // Internal register for output valid signal
    always @(posedge clk) begin
        if (reset)
            out_valid <= 1'b0;
        else
            out_valid <= in_valid;
    end

    // Register for out_tag that increments by 1 for every accepted input
    logic [7:0] next_out_tag;
    always @(posedge clk) begin
        if (reset)
            out_tag <= 8'd0;
        else if (in_valid)
            out_tag <= next_out_tag;
    end

    always @(*) begin
        if (in_valid)
            next_out_tag = out_tag + 1;
        else
            next_out_tag = out_tag;
    end

    // Register for out_y to store the result of the computation
    always @(posedge clk) begin
        if (in_valid) begin
            case (in_mode)
                2'b00: out_y <= {16'd0, in_a} + {16'd0, in_b};  // Zero-extended add
                2'b01: out_y <= {16'd0, in_a} * {16'd0, in_b};  // Zero-extended multiply
                2'b10: out_y <= {16'd0, in_a} ^ {16'd0, in_b};  // Zero-extended xor
                2'b11: out_y <= ({16'd0, in_a} << 1) + ({16'd0, in_b} << 2);  // Weighted sum
            endcase
        end
    end

endmodule

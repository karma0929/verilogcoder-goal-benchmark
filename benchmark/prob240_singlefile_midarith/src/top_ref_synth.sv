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
    logic        valid_q;
    logic [15:0] a_q;
    logic [15:0] b_q;
    logic [1:0]  mode_q;
    logic [7:0]  tag_q;
    logic [7:0]  next_tag;

    function automatic [31:0] compute_fn(
        input [15:0] a,
        input [15:0] b,
        input [1:0]  mode
    );
        begin
            case (mode)
                2'b00: compute_fn = {16'd0, a} + {16'd0, b};
                2'b01: compute_fn = {16'd0, a} * {16'd0, b};
                2'b10: compute_fn = {16'd0, a} ^ {16'd0, b};
                default: compute_fn = ({16'd0, a} << 1) + ({16'd0, b} << 2);
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            valid_q   <= 1'b0;
            a_q       <= 16'd0;
            b_q       <= 16'd0;
            mode_q    <= 2'd0;
            tag_q     <= 8'd0;
            next_tag  <= 8'd0;
            out_valid <= 1'b0;
            out_y     <= 32'd0;
            out_tag   <= 8'd0;
        end else begin
            out_valid <= valid_q;
            if (valid_q) begin
                out_y   <= compute_fn(a_q, b_q, mode_q);
                out_tag <= tag_q;
            end

            valid_q <= in_valid;
            a_q     <= in_a;
            b_q     <= in_b;
            mode_q  <= in_mode;
            if (in_valid) begin
                tag_q    <= next_tag;
                next_tag <= next_tag + 8'd1;
            end
        end
    end
endmodule

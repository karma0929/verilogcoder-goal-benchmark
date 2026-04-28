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
    logic [15:0] s1_a;
    logic [15:0] s1_b;
    logic [1:0]  s1_mode;
    logic [7:0]  s1_tag;
    logic [31:0] core_y;
    logic        stage2_valid;
    logic [7:0]  issue_tag;

    compute_core u_compute_core (
        .a(s1_a),
        .b(s1_b),
        .mode(s1_mode),
        .y(core_y)
    );

    control_fsm u_control_fsm (
        .clk(clk),
        .reset(reset),
        .in_valid(in_valid),
        .stage2_valid(stage2_valid),
        .issue_tag(issue_tag)
    );

    always_ff @(posedge clk) begin
        if (reset) begin
            s1_a <= 16'd0;
            s1_b <= 16'd0;
            s1_mode <= 2'b00;
            s1_tag <= 8'd0;
            out_valid <= 1'b0;
            out_y <= 32'd0;
            out_tag <= 8'd0;
        end else begin
            if (in_valid) begin
                s1_a <= in_a;
                s1_b <= in_b;
                s1_mode <= in_mode;
                s1_tag <= issue_tag;
            end
            out_valid <= stage2_valid;
            if (stage2_valid) begin
                out_y <= core_y;
                out_tag <= s1_tag;
            end
        end
    end
endmodule

module compute_core (
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic [1:0]  mode,
    output logic [31:0] y
);
    always_comb begin
        case (mode)
            2'b00: y = {16'd0, a} + {16'd0, b};
            2'b01: y = {16'd0, a} * {16'd0, b};
            2'b10: y = {16'd0, a} ^ {16'd0, b};
            default: y = ({16'd0, a} << 1) + ({16'd0, b} << 2);
        endcase
    end
endmodule

module control_fsm (
    input  logic       clk,
    input  logic       reset,
    input  logic       in_valid,
    output logic       stage2_valid,
    output logic [7:0] issue_tag
);
    logic [7:0] tag_counter;
    logic       valid_d;

    always_ff @(posedge clk) begin
        if (reset) begin
            tag_counter <= 8'd0;
            valid_d <= 1'b0;
        end else begin
            valid_d <= in_valid;
            if (in_valid) begin
                tag_counter <= tag_counter + 8'd1;
            end
        end
    end

    always_comb begin
        issue_tag = tag_counter;
        stage2_valid = valid_d;
    end
endmodule

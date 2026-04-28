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

module TopModule
(
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

  logic [7:0] tag_counter;
  logic [31:0] compute_result;

  always @(posedge clk) begin
    if ( reset ) begin
      tag_counter <= 8'd0;
    end else begin
      if ( in_valid ) begin
        tag_counter <= tag_counter + 8'd1;
      end
    end
  end

  always @(*) begin
    compute_result = 32'd0;
    case ( in_mode )
      2'b00: compute_result = {16'd0, in_a} + {16'd0, in_b};
      2'b01: compute_result = {16'd0, in_a} * {16'd0, in_b};
      2'b10: compute_result = {16'd0, in_a} ^ {16'd0, in_b};
      2'b11: compute_result = ({16'd0, in_a} << 1) + ({16'd0, in_b} << 2);
    endcase
  end

  always @(posedge clk) begin
    if ( reset ) begin
      out_y <= 32'd0;
    end else begin
      out_y <= compute_result;
    end
  end

endmodule
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

  logic [31:0] operand_a;
  logic [31:0] operand_b;
  logic [31:0] adder_left;
  logic [31:0] adder_right;
  logic [31:0] shared_adder_result;
  logic [31:0] multiply_result;
  logic [31:0] xor_result;
  logic [31:0] selected_result;
  logic [7:0]  tag_counter;

  assign operand_a             = {16'd0, in_a};
  assign operand_b             = {16'd0, in_b};
  assign adder_left            = (in_mode == 2'b11) ? (operand_a << 1) : operand_a;
  assign adder_right           = (in_mode == 2'b11) ? (operand_b << 2) : operand_b;
  assign shared_adder_result   = adder_left + adder_right;
  assign multiply_result       = (in_mode == 2'b01) ? (operand_a * operand_b) : 32'd0;
  assign xor_result            = (in_mode == 2'b10) ? (operand_a ^ operand_b) : 32'd0;
  assign selected_result       = (in_mode == 2'b01) ? multiply_result :
                                 (in_mode == 2'b10) ? xor_result :
                                                       shared_adder_result;

  always @(posedge clk) begin
    if (reset) begin
      tag_counter <= 8'd0;
    end else begin
      if (in_valid) begin
        tag_counter <= tag_counter + 8'd1;
      end
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      out_y <= 32'd0;
    end else begin
      out_y <= selected_result;
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      out_tag <= 8'd0;
    end else begin
      if (in_valid) begin
        out_tag <= tag_counter;
      end
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      out_valid <= 1'b0;
    end else begin
      out_valid <= in_valid;
    end
  end

endmodule

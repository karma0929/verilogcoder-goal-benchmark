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

  localparam MODE_ADD  = 2'b00;
  localparam MODE_MUL  = 2'b01;
  localparam MODE_XOR  = 2'b10;
  localparam MODE_WSUM = 2'b11;

  logic [7:0]  tag_counter;

  logic [31:0] a_zext;
  logic [31:0] b_zext;
  logic [31:0] add_y;
  logic [31:0] mul_y;
  logic [31:0] xor_y;
  logic [31:0] wsum_y;
  logic [31:0] y_next;

  assign a_zext = {16'd0, in_a};
  assign b_zext = {16'd0, in_b};

  assign add_y  = a_zext + b_zext;
  assign mul_y  = a_zext * b_zext;
  assign xor_y  = a_zext ^ b_zext;
  assign wsum_y = (a_zext << 1) + (b_zext << 2);

  always @(*) begin
    y_next = 32'd0;
    case (in_mode)
      MODE_ADD: begin
        y_next = add_y;
      end
      MODE_MUL: begin
        y_next = mul_y;
      end
      MODE_XOR: begin
        y_next = xor_y;
      end
      MODE_WSUM: begin
        y_next = wsum_y;
      end
      default: begin
        y_next = 32'd0;
      end
    endcase
  end

  always @(posedge clk) begin
    if (reset) begin
      tag_counter <= 8'd0;
    end else begin
      if (in_valid) begin
        tag_counter <= tag_counter + 8'd1;
      end else begin
        tag_counter <= tag_counter;
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

  always @(posedge clk) begin
    if (reset) begin
      out_tag <= 8'd0;
    end else begin
      if (in_valid) begin
        out_tag <= tag_counter;
      end else begin
        out_tag <= out_tag;
      end
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      out_y <= 32'd0;
    end else begin
      if (in_valid) begin
        out_y <= y_next;
      end else begin
        out_y <= 32'd0;
      end
    end
  end

endmodule

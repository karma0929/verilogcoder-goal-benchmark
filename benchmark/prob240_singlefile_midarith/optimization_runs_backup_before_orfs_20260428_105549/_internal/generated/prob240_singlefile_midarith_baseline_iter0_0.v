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

  logic [7:0]  issue_tag;
  logic [31:0] a_ext;
  logic [31:0] b_ext;
  logic [31:0] y_comb;

  assign a_ext = {16'd0, in_a};
  assign b_ext = {16'd0, in_b};

  always @(*) begin
    y_comb = 32'd0;
    case ( in_mode )
      2'b00: begin
        y_comb = a_ext + b_ext;
      end
      2'b01: begin
        y_comb = a_ext * b_ext;
      end
      2'b10: begin
        y_comb = a_ext ^ b_ext;
      end
      2'b11: begin
        y_comb = (a_ext << 1) + (b_ext << 2);
      end
      default: begin
        y_comb = 32'd0;
      end
    endcase
  end

  always @(posedge clk) begin
    if ( reset ) begin
      issue_tag <= 8'd0;
      out_valid <= 1'b0;
      out_y     <= 32'd0;
      out_tag   <= 8'd0;
    end else begin
      out_valid <= in_valid;

      if ( in_valid ) begin
        out_y     <= y_comb;
        out_tag   <= issue_tag;
        issue_tag <= issue_tag + 8'd1;
      end else begin
        out_y     <= out_y;
        out_tag   <= out_tag;
        issue_tag <= issue_tag;
      end
    end
  end

endmodule
module TopModule
(
  input  logic       clk,
  input  logic       reset,
  input  logic       in_valid,
  input  logic [7:0] in_a,
  input  logic [7:0] in_b,
  input  logic [2:0] in_mode,
  output logic       out_valid,
  output logic [7:0] out_y,
  output logic [7:0] out_tag
);

  // Register to store the 8-bit inputs
  logic [7:0] reg_a, reg_b;
  logic [2:0] reg_mode;
  logic       reg_valid;

  always @(posedge clk) begin
    if (reset) begin
      reg_a <= 8'b0;
      reg_b <= 8'b0;
      reg_mode <= 3'b0;
      reg_valid <= 1'b0;
    end else begin
      reg_a <= in_a;
      reg_b <= in_b;
      reg_mode <= in_mode;
      reg_valid <= in_valid;
    end
  end

  // Combinational logic to process inputs based on mode
  always @(*) begin
    if (reg_valid) begin
      case (reg_mode)
        3'b000: out_y = reg_a + reg_b;
        3'b001: out_y = reg_a - reg_b;
        3'b010: out_y = reg_a & reg_b;
        3'b011: out_y = reg_a | reg_b;
        3'b100: out_y = reg_a ^ reg_b;
        3'b101: out_y = {reg_a[6:0], reg_a[7]}; // Rotate left
        3'b110: out_y = {reg_a[0], reg_a[7:1]}; // Rotate right
        default: out_y = 8'b0;
      endcase
      out_tag = reg_a ^ reg_b;  // Changed to XOR of reg_a and reg_b for a different functionality
    end else begin
      out_y = 8'b0;
      out_tag = 8'b0;
    end
    out_valid = reg_valid;
  end

endmodule

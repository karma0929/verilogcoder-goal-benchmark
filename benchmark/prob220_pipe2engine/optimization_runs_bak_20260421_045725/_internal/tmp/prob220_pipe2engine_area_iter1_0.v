module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic in_valid,
    input  logic [31:0] in_a,
    input  logic [31:0] in_b,
    input  logic [2:0] in_mode,
    output logic out_valid,
    output logic [31:0] out_y,
    output logic [7:0] out_tag
);
    control_fsm fsm(
        .clk(clk),
        .reset(reset),
        .in(in_valid),
        .out(out_valid)
    );

    compute_core core(
        .clk(clk),
        .reset(reset),
        .in_a(in_a),
        .in_b(in_b),
        .in_mode(in_mode),
        .out_y(out_y),
        .out_tag(out_tag)
    );
endmodule

module control_fsm(
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic out
);

  // State definitions
  localparam STATE_A = 2'b00;
  localparam STATE_B = 2'b01;
  localparam STATE_C = 2'b10;

  // State register
  logic [1:0] state;
  logic [1:0] next_state;

  // State transition logic
  always @(posedge clk) begin
    if (reset)
      state <= STATE_A;
    else
      state <= next_state;
  end

  // Next state logic
  always @(*) begin
    case (state)
      STATE_A: next_state = in ? STATE_B : STATE_A;
      STATE_B: next_state = in ? STATE_C : STATE_A;
      STATE_C: next_state = in ? STATE_C : STATE_A;
    endcase
  end

  // Output logic
  always @(*) begin
    out = (state == STATE_C);
  end

endmodule

module compute_core(
    input  logic clk,
    input  logic reset,
    input  logic [31:0] in_a,
    input  logic [31:0] in_b,
    input  logic [2:0] in_mode,
    output logic [31:0] out_y,
    output logic [7:0] out_tag
);
    always @(*) begin
        case (in_mode)
            3'b000: out_y = in_a + in_b; // Addition
            3'b001: out_y = in_a - in_b; // Subtraction
            3'b010: out_y = in_a & in_b; // Bitwise AND
            3'b011: out_y = in_a | in_b; // Bitwise OR
            3'b100: out_y = in_a ^ in_b; // Bitwise XOR
            default: out_y = in_a + in_b; // Default to addition
        endcase
        out_tag = {5'b0, in_mode}; // Tagging with operation mode
    end
endmodule
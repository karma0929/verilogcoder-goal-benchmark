`timescale 1ns/1ps

module tb;
    logic        clk;
    logic        reset;
    logic        in_valid;
    logic [15:0] in_a;
    logic [15:0] in_b;
    logic [1:0]  in_mode;
    logic        out_valid;
    logic [31:0] out_y;
    logic [7:0]  out_tag;

    integer mismatches;
    integer samples;
    integer expected_count;
    integer received_count;
    logic [31:0] expected_y [0:31];
    logic [7:0]  expected_tag [0:31];
    logic [7:0]  next_issue_tag;

    TopModule dut (
        .clk(clk),
        .reset(reset),
        .in_valid(in_valid),
        .in_a(in_a),
        .in_b(in_b),
        .in_mode(in_mode),
        .out_valid(out_valid),
        .out_y(out_y),
        .out_tag(out_tag)
    );

    function automatic [31:0] ref_compute(
        input [15:0] a,
        input [15:0] b,
        input [1:0]  mode
    );
        begin
            case (mode)
                2'b00: ref_compute = {16'd0, a} + {16'd0, b};
                2'b01: ref_compute = {16'd0, a} * {16'd0, b};
                2'b10: ref_compute = {16'd0, a} ^ {16'd0, b};
                default: ref_compute = ({16'd0, a} << 1) + ({16'd0, b} << 2);
            endcase
        end
    endfunction

    task automatic drive_one(
        input logic        v,
        input logic [15:0] a,
        input logic [15:0] b,
        input logic [1:0]  mode
    );
        begin
            @(negedge clk);
            in_valid <= v;
            in_a <= a;
            in_b <= b;
            in_mode <= mode;
            if (v) begin
                expected_y[expected_count] = ref_compute(a, b, mode);
                expected_tag[expected_count] = next_issue_tag;
                expected_count = expected_count + 1;
                next_issue_tag = next_issue_tag + 8'd1;
            end
        end
    endtask

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (reset) begin
            samples = 0;
            received_count = 0;
        end else begin
            samples = samples + 1;
            if (out_valid) begin
                if (received_count >= expected_count) begin
                    mismatches = mismatches + 1;
                    $display("Mismatch: unexpected output transaction y=%0d tag=%0d", out_y, out_tag);
                end else begin
                    if (out_y !== expected_y[received_count] || out_tag !== expected_tag[received_count]) begin
                        mismatches = mismatches + 1;
                        $display("Mismatch: idx=%0d exp_y=%0d got_y=%0d exp_tag=%0d got_tag=%0d",
                                 received_count, expected_y[received_count], out_y, expected_tag[received_count], out_tag);
                    end
                end
                received_count = received_count + 1;
            end
        end
    end

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        in_valid = 1'b0;
        in_a = 16'd0;
        in_b = 16'd0;
        in_mode = 2'b00;
        mismatches = 0;
        samples = 0;
        expected_count = 0;
        received_count = 0;
        next_issue_tag = 8'd0;
        $dumpfile("wave.vcd");
        $dumpvars(0, tb);

        repeat (3) @(posedge clk);
        @(negedge clk);
        reset <= 1'b0;

        drive_one(1'b1, 16'd3,  16'd4,  2'b00);
        drive_one(1'b1, 16'd9,  16'd2,  2'b01);
        drive_one(1'b0, 16'd0,  16'd0,  2'b00);
        drive_one(1'b1, 16'd5,  16'd7,  2'b10);
        drive_one(1'b1, 16'd8,  16'd3,  2'b11);
        drive_one(1'b0, 16'd0,  16'd0,  2'b00);
        drive_one(1'b1, 16'd16, 16'd1,  2'b00);
        drive_one(1'b0, 16'd0,  16'd0,  2'b00);
        drive_one(1'b0, 16'd0,  16'd0,  2'b00);
        drive_one(1'b0, 16'd0,  16'd0,  2'b00);

        repeat (4) @(posedge clk);
        if (received_count !== expected_count) begin
            mismatches = mismatches + (expected_count - received_count);
            $display("Mismatch: received_count=%0d expected_count=%0d", received_count, expected_count);
        end
        $display("Mismatches: %0d", mismatches);
        $display("Hint: Total mismatched samples is %0d out of %0d samples", mismatches, samples);
        $finish;
    end
endmodule

module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic in_valid,
    input  logic [31:0] in_a,
    input  logic [31:0] in_b,
    input  logic [1:0] in_mode,
    output logic out_valid,
    output logic [31:0] out_y,
    output logic [3:0] out_tag
);

    // Wires to connect modules
    logic [1:0] state_next;

    // Instantiate the control FSM
    control_fsm fsm (
        .clk(clk),
        .reset(reset),
        .in_valid(in_valid),
        .in_a(in_a),
        .in_b(in_b),
        .in_mode(in_mode),
        .state_next(state_next),
        .out_valid(out_valid),
        .out_y(out_y),
        .out_tag(out_tag)
    );

endmodule

module compute_core (
    input  logic clk,
    input  logic reset,
    input  logic in_valid,
    input  logic [31:0] in_a,
    input  logic [31:0] in_b,
    input  logic [1:0] in_mode,
    output logic out_valid,
    output logic [31:0] out_y,
    output logic [3:0] out_tag
);

    // Local parameters for state definition
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;

    // State register
    logic [1:0] state;
    logic [1:0] state_next;

    // Sequential logic to handle state transitions
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_A;
        end else begin
            state <= state_next;
        end
    end

    // Combinational logic for next state logic
    always @(*) begin
        case (state)
            STATE_A: state_next = in_valid ? STATE_B : STATE_A;
            STATE_B: state_next = in_valid ? STATE_C : STATE_A;
            STATE_C: state_next = in_valid ? STATE_C : STATE_A;
        endcase
    end

    // Combinational logic for output
    always @(*) begin
        out_valid = (state == STATE_C);
    end

endmodule

module control_fsm (
    input  logic clk,
    input  logic reset,
    input  logic in_valid,
    input  logic [31:0] in_a,
    input  logic [31:0] in_b,
    input  logic [1:0] in_mode,
    output logic [1:0] state_next,
    output logic out_valid,
    output logic [31:0] out_y,
    output logic [3:0] out_tag
);

    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;

    logic [1:0] state;

    // Initialization and reset
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= STATE_A;
            out_valid <= 1'b0;
            out_y <= 32'b0;
            out_tag <= 4'b0;
        end else begin
            state <= state_next;
        end
    end

    // Combinational logic for next state and output
    always @(*) begin
        case (state)
            STATE_A: begin
                state_next = in_valid ? STATE_B : STATE_A;
                out_valid = 1'b0;
                out_y = 32'b0;  // Ensure defined output
                out_tag = 4'b0; // Ensure defined output
            end
            STATE_B: begin
                state_next = in_valid ? STATE_C : STATE_A;
                out_valid = 1'b0;
                out_y = 32'b0;  // Ensure defined output
                out_tag = 4'b0; // Ensure defined output
            end
            STATE_C: begin
                state_next = in_valid ? STATE_C : STATE_A;
                out_valid = 1'b1;
                out_y = in_a + in_b; // Example computation
                out_tag = in_mode;  // Example tag assignment
            end
            default: begin
                state_next = STATE_A;
                out_valid = 1'b0;
                out_y = 32'b0;
                out_tag = 4'b0;
            end
        endcase
    end

endmodule
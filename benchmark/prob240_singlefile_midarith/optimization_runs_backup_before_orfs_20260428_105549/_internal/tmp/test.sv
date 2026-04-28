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
    integer expected_count;
    integer received_count;
    logic [31:0] expected_y [0:63];
    logic [7:0]  expected_tag [0:63];
    logic [7:0]  next_issue_tag;
    logic        first_mismatch_reported;

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
            in_a     <= a;
            in_b     <= b;
            in_mode  <= mode;
            if (v) begin
                expected_y[expected_count]   = ref_compute(a, b, mode);
                expected_tag[expected_count] = next_issue_tag;
                expected_count = expected_count + 1;
                next_issue_tag = next_issue_tag + 8'd1;
            end
        end
    endtask

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!reset && out_valid) begin
            if (received_count >= expected_count) begin
                mismatches = mismatches + 1;
                if (!first_mismatch_reported) begin
                    $display("First mismatch occurred at time %0t.", $time);
                    $display("Output 'out_valid' mismatched.");
                    first_mismatch_reported = 1'b1;
                end
            end else begin
                if (out_y !== expected_y[received_count]) begin
                    mismatches = mismatches + 1;
                    if (!first_mismatch_reported) begin
                        $display("First mismatch occurred at time %0t.", $time);
                        $display("Output 'out_y' mismatched.");
                        first_mismatch_reported = 1'b1;
                    end
                end
                if (out_tag !== expected_tag[received_count]) begin
                    mismatches = mismatches + 1;
                    if (!first_mismatch_reported) begin
                        $display("First mismatch occurred at time %0t.", $time);
                        $display("Output 'out_tag' mismatched.");
                        first_mismatch_reported = 1'b1;
                    end
                end
            end
            received_count = received_count + 1;
        end
    end

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        in_valid = 1'b0;
        in_a = 16'd0;
        in_b = 16'd0;
        in_mode = 2'd0;
        mismatches = 0;
        expected_count = 0;
        received_count = 0;
        next_issue_tag = 8'd0;
        first_mismatch_reported = 1'b0;

        $dumpfile("wave.vcd");
        $dumpvars(0, tb);

        repeat (3) @(posedge clk);
        reset <= 1'b0;

        drive_one(1'b1, 16'd3,  16'd9,  2'b00);
        drive_one(1'b0, 16'd0,  16'd0,  2'b00);
        drive_one(1'b1, 16'd7,  16'd5,  2'b10);
        drive_one(1'b1, 16'd12, 16'd4,  2'b01);
        drive_one(1'b0, 16'd0,  16'd0,  2'b00);
        drive_one(1'b1, 16'd15, 16'd2,  2'b11);
        drive_one(1'b1, 16'd21, 16'd8,  2'b00);
        drive_one(1'b0, 16'd0,  16'd0,  2'b00);
        drive_one(1'b1, 16'd1,  16'd1,  2'b01);
        drive_one(1'b1, 16'd9,  16'd6,  2'b11);
        drive_one(1'b0, 16'd0,  16'd0,  2'b00);

        repeat (8) @(posedge clk);
        in_valid <= 1'b0;

        if (received_count != expected_count) begin
            mismatches = mismatches + 1;
            if (!first_mismatch_reported) begin
                $display("First mismatch occurred at time %0t.", $time);
                $display("Output 'out_valid' mismatched.");
                first_mismatch_reported = 1'b1;
            end
        end

        if (mismatches == 0) begin
            $display("PASS");
        end else begin
            $display("Mismatches: %0d", mismatches);
        end
        $finish;
    end
endmodule

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

  always @(posedge clk) begin
    if (reset) begin
      tag_counter <= 8'd0;
    end else if (in_valid) begin
      tag_counter <= tag_counter + 8'd1;
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
    end else if (in_valid) begin
      out_tag <= tag_counter;
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      out_y <= 32'd0;
    end else if (in_valid) begin
      case (in_mode)
        2'b00: begin
          out_y <= {16'd0, in_a} + {16'd0, in_b};
        end
        2'b01: begin
          out_y <= {16'd0, in_a} * {16'd0, in_b};
        end
        2'b10: begin
          out_y <= {16'd0, in_a} ^ {16'd0, in_b};
        end
        2'b11: begin
          out_y <= ({16'd0, in_a} << 1) + ({16'd0, in_b} << 2);
        end
        default: begin
          out_y <= 32'd0;
        end
      endcase
    end
  end

endmodule
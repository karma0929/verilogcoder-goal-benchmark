`timescale 1ns/1ps

module tb;
    logic       clk;
    logic       reset;
    logic       in_valid;
    logic [7:0] in;
    logic       out_valid;
    logic [7:0] out;

    integer mismatches;
    logic       exp_valid;
    logic [7:0] exp_in;
    logic       first_mismatch_reported;

    TopModule dut (
        .clk(clk),
        .reset(reset),
        .in_valid(in_valid),
        .in(in),
        .out_valid(out_valid),
        .out(out)
    );

    task automatic drive_one(
        input logic       v,
        input logic [7:0] d
    );
        begin
            @(negedge clk);
            in_valid <= v;
            in <= d;
        end
    endtask

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (reset) begin
            exp_valid <= 1'b0;
            exp_in <= 8'd0;
        end else begin
            if (out_valid !== exp_valid) begin
                mismatches = mismatches + 1;
                if (!first_mismatch_reported) begin
                    $display("First mismatch occurred at time %0t.", $time);
                    $display("Output 'out_valid' mismatched.");
                    first_mismatch_reported = 1'b1;
                end
            end
            if (exp_valid && out !== (exp_in + 8'd1)) begin
                mismatches = mismatches + 1;
                if (!first_mismatch_reported) begin
                    $display("First mismatch occurred at time %0t.", $time);
                    $display("Output 'out' mismatched.");
                    first_mismatch_reported = 1'b1;
                end
            end
            exp_valid <= in_valid;
            exp_in <= in;
        end
    end

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        in_valid = 1'b0;
        in = 8'd0;
        mismatches = 0;
        exp_valid = 1'b0;
        exp_in = 8'd0;
        first_mismatch_reported = 1'b0;
        $dumpfile("wave.vcd");
        $dumpvars(0, tb);

        repeat (2) @(posedge clk);
        reset <= 1'b0;

        drive_one(1'b1, 8'd0);
        drive_one(1'b0, 8'd99);
        drive_one(1'b1, 8'd7);
        drive_one(1'b1, 8'd8);
        drive_one(1'b0, 8'd3);
        drive_one(1'b1, 8'd255);
        drive_one(1'b0, 8'd1);
        drive_one(1'b1, 8'd42);
        drive_one(1'b0, 8'd0);

        repeat (3) @(posedge clk);

        if (mismatches == 0) begin
            $display("PASS");
        end
        $display("Mismatches: %0d", mismatches);
        $finish;
    end
endmodule

module TopModule
(
  input  logic       clk,
  input  logic       reset,
  input  logic       in_valid,
  input  logic [7:0] in,
  output logic       out_valid,
  output logic [7:0] out
);

  always @(posedge clk) begin
    if (reset) begin
      out_valid <= 1'b0;
    end else begin
      out_valid <= in_valid;
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      out <= 8'd0;
    end else begin
      if (in_valid) begin
        out <= in + 8'd1;
      end else begin
        out <= 8'd0;
      end
    end
  end

endmodule
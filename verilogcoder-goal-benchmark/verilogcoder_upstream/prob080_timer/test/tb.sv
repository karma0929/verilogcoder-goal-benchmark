`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
  input clk,
  output logic load,
  output logic [9:0] data,
  output reg[511:0] wavedrom_title,
  output reg wavedrom_enable
);

  task wavedrom_start(input[511:0] title = "");
  endtask

  task wavedrom_stop;
    #1;
  endtask

  initial begin
    load <= 0;
    data <= 10'd0;

    @(negedge clk);
    wavedrom_start();

    @(posedge clk) begin load <= 1; data <= 10'd5; end
    @(posedge clk) begin load <= 0; data <= 10'd0; end
    repeat(8) @(posedge clk);

    @(posedge clk) begin load <= 1; data <= 10'd1; end
    @(posedge clk) begin load <= 0; data <= 10'd0; end
    repeat(4) @(posedge clk);

    @(negedge clk);
    wavedrom_stop();

    repeat(400) @(posedge clk) begin
      load <= $random;
      data <= $random;
    end

    $finish;
  end

endmodule

module tb();

  typedef struct packed {
    int errors;
    int errortime;
    int errors_tc;
    int errortime_tc;
    int clocks;
  } stats;

  stats stats1;

  wire[511:0] wavedrom_title;
  wire wavedrom_enable;
  int wavedrom_hide_after_time;

  reg clk=0;
  initial forever
    #5 clk = ~clk;

  logic load;
  logic [9:0] data;

  logic tc_ref;
  logic tc_dut;

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars();
  end

  wire tb_match;
  wire tb_mismatch = ~tb_match;

  stimulus_gen stim1 (
    .clk,
    .wavedrom_title,
    .wavedrom_enable,
    .load,
    .data
  );

  RefModule good1 (
    .clk,
    .load,
    .data,
    .tc(tc_ref)
  );

  TopModule top_module1 (
    .clk,
    .load,
    .data,
    .tc(tc_dut)
  );

  final begin
    if (stats1.errors_tc) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "tc", stats1.errors_tc, stats1.errortime_tc);
    else $display("Hint: Output '%s' has no mismatches.", "tc");

    $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
    $display("Simulation finished at %0d ps", $time);
    $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
  end

  assign tb_match = ( { tc_ref } === ( { tc_ref } ^ { tc_dut } ^ { tc_ref } ) );

  always @(posedge clk, negedge clk) begin
    stats1.clocks++;
    if (!tb_match) begin
      if (stats1.errors == 0) stats1.errortime = $time;
      stats1.errors++;
    end
    if (tc_ref !== ( tc_ref ^ tc_dut ^ tc_ref ))
    begin
      if (stats1.errors_tc == 0) stats1.errortime_tc = $time;
      stats1.errors_tc = stats1.errors_tc + 1'b1;
    end
  end

  initial begin
    #1000000
    $display("TIMEOUT");
    $finish();
  end

endmodule

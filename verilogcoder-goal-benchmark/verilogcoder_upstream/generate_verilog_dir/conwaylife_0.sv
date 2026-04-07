`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	input tb_match,
	input [255:0] q_ref,
	input [255:0] q_dut,
	output reg load,
	output reg[255:0] data
);

	logic errored = 0;
	int blinker_cycle = 0;

	initial begin
		data <= 3'h7;			// Simple blinker, period 2
		load <= 1;
		@(posedge clk);
		load <= 0;
		data <= 4'hx;
		errored = 0;
		blinker_cycle = 0;
		repeat(5) @(posedge clk) begin
			blinker_cycle++;
			if (!tb_match) begin
				if (!errored) begin
					errored = 1;
					$display("Hint: The first test case is a blinker (initial state = 256'h7). First mismatch occurred at cycle %0d.\nHint:", blinker_cycle);
				end
			end
			
			if (errored) begin
				$display ("Hint: Cycle %0d:         Your game state       Reference game state", blinker_cycle);
				for (int i=15;i>=0;i--) begin
					$display("Hint:   q[%3d:%3d]     %016b      %016b", i*16+15, i*16, q_dut [ i*16 +: 16 ], q_ref[ i*16 +: 16 ]);
				end
				$display("Hint:\nHint:\n");
			end
		end


		data <= 48'h000200010007;	// Glider, Traveling diagonal down-right.
		load <= 1;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		load <= 0;
		data <= 4'hx;
		errored = 0;
		blinker_cycle = 0;
		repeat(100) @(posedge clk) begin
			blinker_cycle++;
			if (!tb_match) begin
				if (!errored) begin
					errored = 1;
					$display("Hint: The second test case is a glider (initial state = 256'h000200010007). First mismatch occurred at cycle %0d.\nHint:", blinker_cycle);
				end
			end
			
			if (errored && blinker_cycle < 20) begin
				$display ("Hint: Cycle %0d:         Your game state       Reference game state", blinker_cycle);
				for (int i=15;i>=0;i--) begin
					$display("Hint:   q[%3d:%3d]     %016b      %016b", i*16+15, i*16, q_dut [ i*16 +: 16 ], q_ref[ i*16 +: 16 ]);
				end
				$display("Hint:\nHint:\n");
			end
		end


		data <= 48'h0040001000ce;			// Acorn
		load <= 1;
		@(posedge clk);
		load <= 0;
		repeat(2000) @(posedge clk);

		
		data <= {$random,$random,$random,$random,$random,$random,$random,$random};		// Some random test cases.
		load <= 1;
		@(posedge clk);
		load <= 0;
		repeat(200) @(posedge clk);

		data <= {$random,$random,$random,$random,$random,$random,$random,$random}&		// Random with more zeros.
				{$random,$random,$random,$random,$random,$random,$random,$random}&
				{$random,$random,$random,$random,$random,$random,$random,$random}&
				{$random,$random,$random,$random,$random,$random,$random,$random};
		load <= 1;
		@(posedge clk);
		load <= 0;
		repeat(200) @(posedge clk);


		#1 $finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_q;
		int errortime_q;

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
	logic [255:0] data;
	logic [255:0] q_ref;
	logic [255:0] q_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars();
	end


	wire tb_match;		// Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.load,
		.data );
	RefModule good1 (
		.clk,
		.load,
		.data,
		.q(q_ref) );
		
	TopModule top_module1 (
		.clk,
		.load,
		.data,
		.q(q_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	

	
	final begin
		if (stats1.errors_q) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "q", stats1.errors_q, stats1.errortime_q);
		else $display("Hint: Output '%s' has no mismatches.", "q");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
	// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
	// the sensitivity list of the @(strobe) process, which isn't implemented.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
		begin if (stats1.errors_q == 0) stats1.errortime_q = $time;
			stats1.errors_q = stats1.errors_q+1'b1; end

	end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule



module RefModule (
  input clk,
  input load,
  input [255:0] data,
  output reg [255:0] q
);

  logic [323:0] q_pad;
  always@(*) begin
    for (int i=0;i<16;i++)
      q_pad[18*(i+1)+1 +: 16] = q[16*i +: 16];
    q_pad[1 +: 16] = q[16*15 +: 16];
    q_pad[18*17+1 +: 16] = q[0 +: 16];

    for (int i=0; i<18; i++) begin
      q_pad[i*18] = q_pad[i*18+16];
      q_pad[i*18+17] = q_pad[i*18+1];
    end
  end

  always @(posedge clk) begin
    for (int i=0;i<16;i++)
    for (int j=0;j<16;j++) begin
      q[i*16+j] <=
        ((q_pad[(i+1)*18+j+1 -1+18] + q_pad[(i+1)*18+j+1 +18] + q_pad[(i+1)*18+j+1 +1+18] +
        q_pad[(i+1)*18+j+1 -1]                                + q_pad[(i+1)*18+j+1+1] +
        q_pad[(i+1)*18+j+1 -1-18]   + q_pad[(i+1)*18+j+1 -18] + q_pad[(i+1)*18+j+1 +1-18]) & 3'h7 | q[i*16+j]) == 3'h3;
    end

    if (load)
      q <= data;

  end

endmodule


module TopModule (
    input  logic        clk,
    input  logic        load,
    input  logic [255:0] data,
    output logic [255:0] q
);

    logic [255:0] next_state;

    always @(*) begin
        integer i, j;
        integer left, right, top, bottom;
        integer idx_tl, idx_tm, idx_tr, idx_ml, idx_mr, idx_bl, idx_bm, idx_br, idx_center;
        integer alive_neighbors;

        for (i = 0; i < 16; i++) begin
            for (j = 0; j < 16; j++) begin
                // Calculate indices considering toroidal wrap-around
                left = (j == 0) ? 15 : j - 1;
                right = (j == 15) ? 0 : j + 1;
                top = (i == 0) ? 15 : i - 1;
                bottom = (i == 15) ? 0 : i + 1;

                // Calculate linear index for neighbors
                idx_tl = top * 16 + left;    // top-left
                idx_tm = top * 16 + j;       // top-middle
                idx_tr = top * 16 + right;   // top-right
                idx_ml = i * 16 + left;      // middle-left
                idx_mr = i * 16 + right;     // middle-right
                idx_bl = bottom * 16 + left; // bottom-left
                idx_bm = bottom * 16 + j;    // bottom-middle
                idx_br = bottom * 16 + right;// bottom-right
                idx_center = i * 16 + j;     // center

                // Count alive neighbors
                alive_neighbors = q[idx_tl] + q[idx_tm] + q[idx_tr] +
                                  q[idx_ml] + q[idx_mr] +
                                  q[idx_bl] + q[idx_bm] + q[idx_br];

                // Game of Life rules
                if (alive_neighbors == 2) begin
                    next_state[idx_center] = q[idx_center]; // Keep current state
                end else if (alive_neighbors == 3) begin
                    next_state[idx_center] = 1;            // Become alive
                end else begin
                    next_state[idx_center] = 0;            // Become dead
                end
            end
        end
    end

    always @(posedge clk) begin
        if (load) begin
            q <= data;
        end else begin
            q <= next_state;
        end
    end

endmodule
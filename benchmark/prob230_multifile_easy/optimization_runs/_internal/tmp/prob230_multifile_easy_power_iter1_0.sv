`timescale 1ns/1ps

module tb;
    logic clk;
    logic reset;
    logic valid;
    logic [7:0] a;
    logic [7:0] b;
    logic [1:0] op;
    logic [7:0] y;
    logic done;

    integer mismatches;
    integer checks;

    TopModule dut (
        .clk(clk),
        .reset(reset),
        .valid(valid),
        .a(a),
        .b(b),
        .op(op),
        .y(y),
        .done(done)
    );

    function automatic [7:0] expected_core(
        input [7:0] a_i,
        input [7:0] b_i,
        input [1:0] op_i
    );
        begin
            case (op_i)
                2'b00: expected_core = a_i + b_i;
                2'b01: expected_core = a_i ^ b_i;
                2'b10: expected_core = a_i & b_i;
                default: expected_core = a_i - b_i;
            endcase
        end
    endfunction

    task automatic run_one(
        input [7:0] a_i,
        input [7:0] b_i,
        input [1:0] op_i
    );
        reg [7:0] expected;
        begin
            expected = expected_core(a_i, b_i, op_i);
            a <= a_i;
            b <= b_i;
            op <= op_i;
            valid <= 1'b1;
            @(posedge clk);
            #1;
            checks = checks + 1;
            if (done !== 1'b1 || y !== expected) begin
                mismatches = mismatches + 1;
                $display("Mismatch when valid=1: op=%0b a=%0d b=%0d got_y=%0d exp_y=%0d done=%0b",
                         op_i, a_i, b_i, y, expected, done);
            end

            valid <= 1'b0;
            @(posedge clk);
            #1;
            checks = checks + 1;
            if (done !== 1'b0) begin
                mismatches = mismatches + 1;
                $display("Mismatch when valid=0: done should be 0, got %0b", done);
            end
        end
    endtask

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        valid = 1'b0;
        a = 8'h00;
        b = 8'h00;
        op = 2'b00;
        mismatches = 0;
        checks = 0;
        $dumpfile("wave.vcd");
        $dumpvars(0, tb);

        repeat (2) @(posedge clk);
        reset <= 1'b0;
        @(posedge clk);
        #1;
        checks = checks + 1;
        if (done !== 1'b0 || y !== 8'h00) begin
            mismatches = mismatches + 1;
            $display("Mismatch after reset release: y=%0d done=%0b", y, done);
        end

        run_one(8'd3, 8'd4, 2'b00);
        run_one(8'd15, 8'd5, 2'b01);
        run_one(8'd12, 8'd10, 2'b10);
        run_one(8'd22, 8'd9, 2'b11);
        run_one(8'd255, 8'd1, 2'b00);
        run_one(8'd0, 8'd0, 2'b01);

        $display("Mismatches: %0d", mismatches);
        $display("Hint: Total mismatched samples is %0d out of %0d samples", mismatches, checks);
        $finish;
    end
endmodule

module TopModule
(
    input  logic       clk,
    input  logic       reset,
    input  logic       valid,
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [3:0] op,
    output logic [7:0] y,
    output logic       done
);

    // Sequential logic to hold results and done signal
    logic [7:0] result;
    logic       result_valid;

    always @(posedge clk) begin
        if (reset) begin
            result <= 0;
            result_valid <= 0;
        end else if (valid) begin
            case (op)
                4'h0: result <= a + b;
                4'h1: result <= a - b;
                4'hA: result <= a & b; // Corrected operation for op=10
                4'hB: result <= a | b; // Corrected operation for op=11
                default: result <= a + b; // Default operation
            endcase
            result_valid <= 1;
        end else begin
            result_valid <= 0;
        end
    end

    // Output assignment
    assign y = result;
    assign done = result_valid;

endmodule
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
    input  logic [2:0] op,
    output logic [7:0] y,
    output logic       done
);

    // Define a register to hold the input values and operation
    logic [7:0] reg_a, reg_b;
    logic [2:0] reg_op;
    logic       reg_valid;

    // Sequential logic for registering the input signals
    always @(posedge clk) begin
        if (reset) begin
            reg_a <= 0;
            reg_b <= 0;
            reg_op <= 0;
            reg_valid <= 0;
        end else begin
            reg_a <= a;
            reg_b <= b;
            reg_op <= op;
            reg_valid <= valid;
        end
    end

    // Combinational logic to perform operation based on op code
    always @(*) begin
        case (reg_op)
            3'b000: y = reg_a + reg_b;  // Addition
            3'b001: y = reg_a - reg_b;  // Subtraction
            3'b010: y = reg_a & reg_b;  // AND
            3'b011: y = reg_a | reg_b;  // OR
            3'b100: y = reg_a ^ reg_b;  // XOR
            3'b101: y = (reg_a << 1) | (reg_a >> 7); // Rotate left
            3'b110: y = (reg_a >> 1) | (reg_a << 7); // Rotate right
            default: y = 8'h00;         // Default case for undefined operations
        endcase
    end

    // Control signal for done
    assign done = reg_valid;

endmodule
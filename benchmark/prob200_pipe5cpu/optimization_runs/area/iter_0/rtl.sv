module TopModule (
    input  logic clk,
    input  logic reset,
    output logic done,
    output logic [31:0] signature,
    output logic [31:0] dbg_x3,
    output logic [31:0] dbg_x4,
    output logic [31:0] dbg_x5,
    output logic [31:0] dbg_x6,
    output logic [31:0] dbg_x7,
    output logic [31:0] dbg_mem2,
    output logic [31:0] dbg_mem3,
    output logic [7:0] dbg_commit_count
);
    // Internal signals and registers
    logic [31:0] pc; // Program Counter
    logic [31:0] instruction; // Current instruction fetched from ROM
    logic [3:0] opcode;
    logic [2:0] rd, rs1, rs2;
    logic [15:0] immediate;
    logic [31:0] regfile [0:7]; // Register file
    logic [31:0] alu_result; // Result from ALU
    logic [31:0] branch_target; // Calculated branch target
    logic branch_taken; // Flag for branch taken
    logic [31:0] dmem[15:0]; // Data memory
    logic [31:0] mem_data; // Data read from memory
    logic [7:0] commit_count; // Local commit count
    logic halt_committed; // Indicates if HALT has been committed

    // Program Counter (PC) logic
    always_ff @(posedge clk) begin
        if (reset)
            pc <= 0;
        else if (!halt_committed && !branch_taken)
            pc <= branch_taken ? branch_target : pc + 1; // Increment PC every cycle unless halted or a branch is taken
    end

    // Instruction ROM
    always_comb begin
        case (pc)
            0: instruction = {4'h6, 3'd1, 3'd0, 3'd0, 3'b000, 16'sd5};  // ADDI x1, x0, 5
            1: instruction = {4'h6, 3'd2, 3'd0, 3'd0, 3'b000, 16'sd9};  // ADDI x2, x0, 9
            2: instruction = {4'h1, 3'd3, 3'd1, 3'd2, 3'b000, 16'sd0};  // ADD x3, x1, x2
            3: instruction = {4'h8, 3'd3, 3'd0, 3'd0, 3'b000, 16'sd2};  // SW x3, 2(x0)
            4: instruction = {4'h7, 3'd4, 3'd0, 3'd0, 3'b000, 16'sd2};  // LW x4, 2(x0)
            5: instruction = {4'h6, 3'd5, 3'd4, 3'd0, 3'b000, 16'sd3};  // ADDI x5, x4, 3
            6: instruction = {4'h2, 3'd6, 3'd5, 3'd1, 3'b000, 16'sd0};  // SUB x6, x5, x1
            7: instruction = {4'h5, 3'd7, 3'd6, 3'd2, 3'b000, 16'sd0};  // XOR x7, x6, x2
            8: instruction = {4'h9, 3'd7, 3'd1, 3'd0, 3'b000, 16'sh2}; // BEQ x7, x1, +2
            9: instruction = {4'h6, 3'd3, 3'd0, 3'd0, 3'b000, 16'sd0};  // ADDI x3, x0, 0
            10: instruction = {4'h3, 3'd3, 3'd7, 3'd2, 3'b000, 16'sd0}; // AND x3, x7, x2
            11: instruction = {4'h4, 3'd4, 3'd3, 3'd6, 3'b000, 16'sd0}; // OR x4, x3, x6
            12: instruction = {4'h8, 3'd4, 3'd0, 3'd0, 3'b000, 16'sd3}; // SW x4, 3(x0)
            13: instruction = {4'h7, 3'd5, 3'd0, 3'd0, 3'b000, 16'sd3}; // LW x5, 3(x0)
            14: instruction = {4'h1, 3'd6, 3'd5, 3'd3, 3'b000, 16'sd0}; // ADD x6, x5, x3
            15: instruction = {4'hf, 3'd0, 3'd0, 3'd0, 3'b000, 16'sd0}; // HALT
            default: instruction = 32'h00000000; // NOP
        endcase
    end

    // Instruction Decode (ID) Stage
    always_ff @(posedge clk) begin
        if (reset) begin
            opcode <= 4'b0;
            rd <= 3'b0;
            rs1 <= 3'b0;
            rs2 <= 3'b0;
            immediate <= 16'b0;
        end else begin
            opcode <= instruction[31:28];
            rd <= instruction[27:25];
            rs1 <= instruction[24:22];
            rs2 <= instruction[21:19];
            immediate <= instruction[15:0];
        end
    end

    // Execution (EX) Stage
    always_comb begin
        alu_result = 0;
        branch_target = 0;
        branch_taken = 0;
        case (opcode)
            4'h1: alu_result = regfile[rs1] + regfile[rs2]; // ADD
            4'h2: alu_result = regfile[rs1] - regfile[rs2]; // SUB
            4'h3: alu_result = regfile[rs1] & regfile[rs2]; // AND
            4'h4: alu_result = regfile[rs1] | regfile[rs2]; // OR
            4'h5: alu_result = regfile[rs1] ^ regfile[rs2]; // XOR
            4'h6: alu_result = regfile[rs1] + immediate;    // ADDI
            4'h9: begin // BEQ
                branch_target = pc + immediate;
                branch_taken = (regfile[rs1] == regfile[rs2]);
            end
            4'hf: begin // HALT
                halt_committed = 1; // Set halt_committed when HALT is executed
            end
        endcase
    end

    // Memory Access (MEM) Stage
    always_ff @(posedge clk) begin
        if (reset) begin
            dmem[0] <= 32'd3;
            dmem[1] <= 32'd7;
            dmem[2] <= 32'd0;
            dmem[3] <= 32'd0;
            // Initialize remaining memory locations to 0
            dmem[4] <= 32'd0; dmem[5] <= 32'd0; dmem[6] <= 32'd0; dmem[7] <= 32'd0;
            dmem[8] <= 32'd0; dmem[9] <= 32'd0; dmem[10] <= 32'd0; dmem[11] <= 32'd0;
            dmem[12] <= 32'd0; dmem[13] <= 32'd0; dmem[14] <= 32'd0; dmem[15] <= 32'd0;
        end else begin
            case (opcode)
                4'h7: mem_data <= dmem[alu_result[3:0]]; // LW
                4'h8: dmem[alu_result[3:0]] <= regfile[rs1]; // SW
            endcase
        end
    end

    // Write-Back (WB) Stage
    always_ff @(posedge clk) begin
        if (reset) begin
            regfile[1] <= 0;
            regfile[2] <= 0;
            regfile[3] <= 0;
            regfile[4] <= 0;
            regfile[5] <= 0;
            regfile[6] <= 0;
            regfile[7] <= 0;
            commit_count <= 0;
            halt_committed <= 0; // Reset halt_committed on reset
            done <= 0; // Reset done on reset
        end else if (opcode != 4'h0 && opcode != 4'hf && opcode != 4'h8) begin
            if (opcode == 4'h7) // LW
                regfile[rd] <= mem_data;
            else // All other operations except SW and HALT
                regfile[rd] <= alu_result;

            commit_count <= commit_count + 1;
        end else if (opcode == 4'hf) begin
            done <= halt_committed; // Set done high when HALT is committed
        end
    end

    // Debug outputs and signature calculation
    assign dbg_x3 = regfile[3];
    assign dbg_x4 = regfile[4];
    assign dbg_x5 = regfile[5];
    assign dbg_x6 = regfile[6];
    assign dbg_x7 = regfile[7];
    assign dbg_mem2 = dmem[2];
    assign dbg_mem3 = dmem[3];
    assign dbg_commit_count = commit_count;
    assign signature = dbg_x3 ^ (dbg_x4 << 1) ^ (dbg_x5 << 2) ^ (dbg_x6 << 3) ^ (dbg_x7 << 4) ^ (dbg_mem2 << 5) ^ (dbg_mem3 << 6) ^ {24'b0, dbg_commit_count};

endmodule

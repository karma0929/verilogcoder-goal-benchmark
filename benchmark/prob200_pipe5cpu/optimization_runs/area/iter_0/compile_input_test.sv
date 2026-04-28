`timescale 1 ps / 1 ps
`define OK 12
`define INCORRECT 13

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_done;
        int errortime_done;
        int errors_signature;
        int errortime_signature;
        int errors_dbg_x3;
        int errortime_dbg_x3;
        int errors_dbg_x4;
        int errortime_dbg_x4;
        int errors_dbg_x5;
        int errortime_dbg_x5;
        int errors_dbg_x6;
        int errortime_dbg_x6;
        int errors_dbg_x7;
        int errortime_dbg_x7;
        int errors_dbg_mem2;
        int errortime_dbg_mem2;
        int errors_dbg_mem3;
        int errortime_dbg_mem3;
        int errors_dbg_commit_count;
        int errortime_dbg_commit_count;
        int clocks;
    } stats_t;

    stats_t stats1;

    reg clk = 1'b0;
    reg reset = 1'b1;
    reg checking_enable = 1'b0;

    logic done_ref;
    logic [31:0] signature_ref;
    logic [31:0] dbg_x3_ref;
    logic [31:0] dbg_x4_ref;
    logic [31:0] dbg_x5_ref;
    logic [31:0] dbg_x6_ref;
    logic [31:0] dbg_x7_ref;
    logic [31:0] dbg_mem2_ref;
    logic [31:0] dbg_mem3_ref;
    logic [7:0]  dbg_commit_count_ref;

    logic done_dut;
    logic [31:0] signature_dut;
    logic [31:0] dbg_x3_dut;
    logic [31:0] dbg_x4_dut;
    logic [31:0] dbg_x5_dut;
    logic [31:0] dbg_x6_dut;
    logic [31:0] dbg_x7_dut;
    logic [31:0] dbg_mem2_dut;
    logic [31:0] dbg_mem3_dut;
    logic [7:0]  dbg_commit_count_dut;

    initial forever #5 clk = ~clk;

    initial begin
        stats1 = '0;
        $dumpfile("wave.vcd");
        $dumpvars();
    end

    RefModule good1 (
        .clk(clk),
        .reset(reset),
        .done(done_ref),
        .signature(signature_ref),
        .dbg_x3(dbg_x3_ref),
        .dbg_x4(dbg_x4_ref),
        .dbg_x5(dbg_x5_ref),
        .dbg_x6(dbg_x6_ref),
        .dbg_x7(dbg_x7_ref),
        .dbg_mem2(dbg_mem2_ref),
        .dbg_mem3(dbg_mem3_ref),
        .dbg_commit_count(dbg_commit_count_ref)
    );

    TopModule top_module1 (
        .clk(clk),
        .reset(reset),
        .done(done_dut),
        .signature(signature_dut),
        .dbg_x3(dbg_x3_dut),
        .dbg_x4(dbg_x4_dut),
        .dbg_x5(dbg_x5_dut),
        .dbg_x6(dbg_x6_dut),
        .dbg_x7(dbg_x7_dut),
        .dbg_mem2(dbg_mem2_dut),
        .dbg_mem3(dbg_mem3_dut),
        .dbg_commit_count(dbg_commit_count_dut)
    );

    wire tb_match = checking_enable &&
        (done_ref === done_dut) &&
        (signature_ref === signature_dut) &&
        (dbg_x3_ref === dbg_x3_dut) &&
        (dbg_x4_ref === dbg_x4_dut) &&
        (dbg_x5_ref === dbg_x5_dut) &&
        (dbg_x6_ref === dbg_x6_dut) &&
        (dbg_x7_ref === dbg_x7_dut) &&
        (dbg_mem2_ref === dbg_mem2_dut) &&
        (dbg_mem3_ref === dbg_mem3_dut) &&
        (dbg_commit_count_ref === dbg_commit_count_dut);

    initial begin
        repeat (3) @(posedge clk);
        reset <= 1'b0;
        checking_enable <= 1'b1;
    end

    always @(posedge clk or negedge clk) begin
        if (checking_enable) begin
            stats1.clocks++;

            if (!tb_match) begin
                if (stats1.errors == 0)
                    stats1.errortime = $time;
                stats1.errors++;
            end

            if (done_ref !== done_dut) begin
                if (stats1.errors_done == 0)
                    stats1.errortime_done = $time;
                stats1.errors_done++;
            end

            if (signature_ref !== signature_dut) begin
                if (stats1.errors_signature == 0)
                    stats1.errortime_signature = $time;
                stats1.errors_signature++;
            end

            if (dbg_x3_ref !== dbg_x3_dut) begin
                if (stats1.errors_dbg_x3 == 0)
                    stats1.errortime_dbg_x3 = $time;
                stats1.errors_dbg_x3++;
            end

            if (dbg_x4_ref !== dbg_x4_dut) begin
                if (stats1.errors_dbg_x4 == 0)
                    stats1.errortime_dbg_x4 = $time;
                stats1.errors_dbg_x4++;
            end

            if (dbg_x5_ref !== dbg_x5_dut) begin
                if (stats1.errors_dbg_x5 == 0)
                    stats1.errortime_dbg_x5 = $time;
                stats1.errors_dbg_x5++;
            end

            if (dbg_x6_ref !== dbg_x6_dut) begin
                if (stats1.errors_dbg_x6 == 0)
                    stats1.errortime_dbg_x6 = $time;
                stats1.errors_dbg_x6++;
            end

            if (dbg_x7_ref !== dbg_x7_dut) begin
                if (stats1.errors_dbg_x7 == 0)
                    stats1.errortime_dbg_x7 = $time;
                stats1.errors_dbg_x7++;
            end

            if (dbg_mem2_ref !== dbg_mem2_dut) begin
                if (stats1.errors_dbg_mem2 == 0)
                    stats1.errortime_dbg_mem2 = $time;
                stats1.errors_dbg_mem2++;
            end

            if (dbg_mem3_ref !== dbg_mem3_dut) begin
                if (stats1.errors_dbg_mem3 == 0)
                    stats1.errortime_dbg_mem3 = $time;
                stats1.errors_dbg_mem3++;
            end

            if (dbg_commit_count_ref !== dbg_commit_count_dut) begin
                if (stats1.errors_dbg_commit_count == 0)
                    stats1.errortime_dbg_commit_count = $time;
                stats1.errors_dbg_commit_count++;
            end

            if (done_ref && done_dut) begin
                #1 $finish;
            end
        end
    end

    final begin
        if (stats1.errors_done)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "done", stats1.errors_done, stats1.errortime_done);
        else
            $display("Hint: Output '%s' has no mismatches.", "done");

        if (stats1.errors_signature)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "signature", stats1.errors_signature, stats1.errortime_signature);
        else
            $display("Hint: Output '%s' has no mismatches.", "signature");

        if (stats1.errors_dbg_x3)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_x3", stats1.errors_dbg_x3, stats1.errortime_dbg_x3);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_x3");

        if (stats1.errors_dbg_x4)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_x4", stats1.errors_dbg_x4, stats1.errortime_dbg_x4);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_x4");

        if (stats1.errors_dbg_x5)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_x5", stats1.errors_dbg_x5, stats1.errortime_dbg_x5);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_x5");

        if (stats1.errors_dbg_x6)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_x6", stats1.errors_dbg_x6, stats1.errortime_dbg_x6);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_x6");

        if (stats1.errors_dbg_x7)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_x7", stats1.errors_dbg_x7, stats1.errortime_dbg_x7);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_x7");

        if (stats1.errors_dbg_mem2)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_mem2", stats1.errors_dbg_mem2, stats1.errortime_dbg_mem2);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_mem2");

        if (stats1.errors_dbg_mem3)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_mem3", stats1.errors_dbg_mem3, stats1.errortime_dbg_mem3);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_mem3");

        if (stats1.errors_dbg_commit_count)
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "dbg_commit_count", stats1.errors_dbg_commit_count, stats1.errortime_dbg_commit_count);
        else
            $display("Hint: Output '%s' has no mismatches.", "dbg_commit_count");

        $display("Hint: Total mismatched samples is %0d out of %0d samples", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
    end

    initial begin
        #20000;
        $display("TIMEOUT");
        $finish();
    end

endmodule

module RefModule (
    input  logic        clk,
    input  logic        reset,
    output logic        done,
    output logic [31:0] signature,
    output logic [31:0] dbg_x3,
    output logic [31:0] dbg_x4,
    output logic [31:0] dbg_x5,
    output logic [31:0] dbg_x6,
    output logic [31:0] dbg_x7,
    output logic [31:0] dbg_mem2,
    output logic [31:0] dbg_mem3,
    output logic [7:0]  dbg_commit_count
);

    localparam [3:0] OP_NOP  = 4'h0;
    localparam [3:0] OP_ADD  = 4'h1;
    localparam [3:0] OP_SUB  = 4'h2;
    localparam [3:0] OP_AND  = 4'h3;
    localparam [3:0] OP_OR   = 4'h4;
    localparam [3:0] OP_XOR  = 4'h5;
    localparam [3:0] OP_ADDI = 4'h6;
    localparam [3:0] OP_LW   = 4'h7;
    localparam [3:0] OP_SW   = 4'h8;
    localparam [3:0] OP_BEQ  = 4'h9;
    localparam [3:0] OP_HALT = 4'hf;

    logic [31:0] regs [0:7];
    logic [31:0] dmem [0:15];
    integer idx;

    logic [7:0] pc;
    logic       id_valid;
    logic [7:0] id_pc;
    logic [31:0] id_instr;

    logic       ex_valid;
    logic [7:0] ex_pc;
    logic [3:0] ex_opcode;
    logic [2:0] ex_rd;
    logic [2:0] ex_rs1;
    logic [2:0] ex_rs2;
    logic [31:0] ex_imm;
    logic [31:0] ex_rs1_val;
    logic [31:0] ex_rs2_val;
    logic       ex_we;
    logic       ex_mem_read;
    logic       ex_mem_write;
    logic       ex_branch;
    logic       ex_halt;

    logic       mem_valid;
    logic [7:0] mem_pc;
    logic [2:0] mem_rd;
    logic [31:0] mem_alu_result;
    logic [31:0] mem_store_data;
    logic       mem_we;
    logic       mem_mem_read;
    logic       mem_mem_write;
    logic       mem_halt;

    logic       wb_valid;
    logic [7:0] wb_pc;
    logic [2:0] wb_rd;
    logic [31:0] wb_result;
    logic       wb_we;
    logic       wb_halt;

    logic [3:0] id_opcode;
    logic [2:0] id_rd;
    logic [2:0] id_rs1;
    logic [2:0] id_rs2;
    logic [31:0] id_imm;

    logic [31:0] mem_forward_result;
    logic [31:0] forward_a;
    logic [31:0] forward_b;
    logic [31:0] ex_result;
    logic [31:0] ex_store_data_next;
    logic        branch_taken;
    logic [31:0] branch_target;
    logic        load_use_hazard;
    logic [1:0]  commit_inc;
    logic [7:0]  commit_count;

    function automatic [31:0] sext16(input [15:0] imm);
        sext16 = {{16{imm[15]}}, imm};
    endfunction

    function automatic [31:0] enc_r(
        input [3:0] opc,
        input [2:0] rd,
        input [2:0] rs1,
        input [2:0] rs2
    );
        enc_r = {opc, rd, rs1, rs2, 3'b000, 16'h0000};
    endfunction

    function automatic [31:0] enc_i(
        input [3:0] opc,
        input [2:0] rd,
        input [2:0] rs1,
        input [15:0] imm
    );
        enc_i = {opc, rd, rs1, 3'b000, 3'b000, imm};
    endfunction

    function automatic [31:0] enc_s(
        input [3:0] opc,
        input [2:0] rs1,
        input [2:0] rs2,
        input [15:0] imm
    );
        enc_s = {opc, 3'b000, rs1, rs2, 3'b000, imm};
    endfunction

    function automatic [31:0] enc_b(
        input [3:0] opc,
        input [2:0] rs1,
        input [2:0] rs2,
        input [15:0] imm
    );
        enc_b = {opc, 3'b000, rs1, rs2, 3'b000, imm};
    endfunction

    function automatic [31:0] enc_halt;
        enc_halt = {OP_HALT, 28'h0};
    endfunction

    function automatic [31:0] rom_word(input [7:0] pc_index);
        case (pc_index)
            8'd0:  rom_word = enc_i(OP_ADDI, 3'd1, 3'd0, 16'd5);
            8'd1:  rom_word = enc_i(OP_ADDI, 3'd2, 3'd0, 16'd9);
            8'd2:  rom_word = enc_r(OP_ADD,  3'd3, 3'd1, 3'd2);
            8'd3:  rom_word = enc_s(OP_SW,   3'd0, 3'd3, 16'd2);
            8'd4:  rom_word = enc_i(OP_LW,   3'd4, 3'd0, 16'd2);
            8'd5:  rom_word = enc_i(OP_ADDI, 3'd5, 3'd4, 16'd3);
            8'd6:  rom_word = enc_r(OP_SUB,  3'd6, 3'd5, 3'd1);
            8'd7:  rom_word = enc_r(OP_XOR,  3'd7, 3'd6, 3'd2);
            8'd8:  rom_word = enc_b(OP_BEQ,  3'd7, 3'd1, 16'd2);
            8'd9:  rom_word = enc_i(OP_ADDI, 3'd3, 3'd0, 16'd0);
            8'd10: rom_word = enc_r(OP_AND,  3'd3, 3'd7, 3'd2);
            8'd11: rom_word = enc_r(OP_OR,   3'd4, 3'd3, 3'd6);
            8'd12: rom_word = enc_s(OP_SW,   3'd0, 3'd4, 16'd3);
            8'd13: rom_word = enc_i(OP_LW,   3'd5, 3'd0, 16'd3);
            8'd14: rom_word = enc_r(OP_ADD,  3'd6, 3'd5, 3'd3);
            8'd15: rom_word = enc_halt();
            default: rom_word = enc_halt();
        endcase
    endfunction

    function automatic logic instr_uses_rs1(input [3:0] opcode);
        case (opcode)
            OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_ADDI, OP_LW, OP_SW, OP_BEQ: instr_uses_rs1 = 1'b1;
            default: instr_uses_rs1 = 1'b0;
        endcase
    endfunction

    function automatic logic instr_uses_rs2(input [3:0] opcode);
        case (opcode)
            OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_SW, OP_BEQ: instr_uses_rs2 = 1'b1;
            default: instr_uses_rs2 = 1'b0;
        endcase
    endfunction

    function automatic logic instr_writes_rd(input [3:0] opcode);
        case (opcode)
            OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_ADDI, OP_LW: instr_writes_rd = 1'b1;
            default: instr_writes_rd = 1'b0;
        endcase
    endfunction

    assign id_opcode = id_instr[31:28];
    assign id_rd     = id_instr[27:25];
    assign id_rs1    = id_instr[24:22];
    assign id_rs2    = id_instr[21:19];
    assign id_imm    = sext16(id_instr[15:0]);

    assign mem_forward_result = mem_mem_read ? dmem[mem_alu_result[3:0]] : mem_alu_result;

    always @(*) begin
        forward_a = ex_rs1_val;
        if (ex_rs1 != 3'd0 && mem_valid && mem_we && mem_rd == ex_rs1)
            forward_a = mem_forward_result;
        else if (ex_rs1 != 3'd0 && wb_valid && wb_we && wb_rd == ex_rs1)
            forward_a = wb_result;
    end

    always @(*) begin
        forward_b = ex_rs2_val;
        if (ex_rs2 != 3'd0 && mem_valid && mem_we && mem_rd == ex_rs2)
            forward_b = mem_forward_result;
        else if (ex_rs2 != 3'd0 && wb_valid && wb_we && wb_rd == ex_rs2)
            forward_b = wb_result;
    end

    always @(*) begin
        ex_result = 32'd0;
        case (ex_opcode)
            OP_ADD:  ex_result = forward_a + forward_b;
            OP_SUB:  ex_result = forward_a - forward_b;
            OP_AND:  ex_result = forward_a & forward_b;
            OP_OR:   ex_result = forward_a | forward_b;
            OP_XOR:  ex_result = forward_a ^ forward_b;
            OP_ADDI: ex_result = forward_a + ex_imm;
            OP_LW:   ex_result = forward_a + ex_imm;
            OP_SW:   ex_result = forward_a + ex_imm;
            default: ex_result = 32'd0;
        endcase
    end

    assign ex_store_data_next = forward_b;
    assign branch_taken = ex_valid && ex_branch && (forward_a == forward_b);
    assign branch_target = {{24{1'b0}}, ex_pc} + ex_imm;

    assign load_use_hazard =
        id_valid &&
        ex_valid &&
        ex_mem_read &&
        (ex_rd != 3'd0) &&
        (
            (instr_uses_rs1(id_opcode) && (id_rs1 == ex_rd)) ||
            (instr_uses_rs2(id_opcode) && (id_rs2 == ex_rd))
        );

    assign commit_inc =
        ((wb_valid && wb_we && (wb_rd != 3'd0)) ? 2'd1 : 2'd0) +
        ((mem_valid && mem_mem_write) ? 2'd1 : 2'd0);

    assign dbg_x3 = regs[3];
    assign dbg_x4 = regs[4];
    assign dbg_x5 = regs[5];
    assign dbg_x6 = regs[6];
    assign dbg_x7 = regs[7];
    assign dbg_mem2 = dmem[2];
    assign dbg_mem3 = dmem[3];
    assign dbg_commit_count = commit_count;
    assign signature =
        dbg_x3 ^
        (dbg_x4 << 1) ^
        (dbg_x5 << 2) ^
        (dbg_x6 << 3) ^
        (dbg_x7 << 4) ^
        (dbg_mem2 << 5) ^
        (dbg_mem3 << 6) ^
        {24'b0, dbg_commit_count};

    always @(posedge clk) begin
        if (reset) begin
            done <= 1'b0;
            pc <= 8'd0;
            id_valid <= 1'b0;
            id_pc <= 8'd0;
            id_instr <= 32'd0;
            ex_valid <= 1'b0;
            ex_pc <= 8'd0;
            ex_opcode <= OP_NOP;
            ex_rd <= 3'd0;
            ex_rs1 <= 3'd0;
            ex_rs2 <= 3'd0;
            ex_imm <= 32'd0;
            ex_rs1_val <= 32'd0;
            ex_rs2_val <= 32'd0;
            ex_we <= 1'b0;
            ex_mem_read <= 1'b0;
            ex_mem_write <= 1'b0;
            ex_branch <= 1'b0;
            ex_halt <= 1'b0;
            mem_valid <= 1'b0;
            mem_pc <= 8'd0;
            mem_rd <= 3'd0;
            mem_alu_result <= 32'd0;
            mem_store_data <= 32'd0;
            mem_we <= 1'b0;
            mem_mem_read <= 1'b0;
            mem_mem_write <= 1'b0;
            mem_halt <= 1'b0;
            wb_valid <= 1'b0;
            wb_pc <= 8'd0;
            wb_rd <= 3'd0;
            wb_result <= 32'd0;
            wb_we <= 1'b0;
            wb_halt <= 1'b0;
            commit_count <= 8'd0;

            for (idx = 0; idx < 8; idx = idx + 1)
                regs[idx] <= 32'd0;

            for (idx = 0; idx < 16; idx = idx + 1)
                dmem[idx] <= 32'd0;

            dmem[0] <= 32'd3;
            dmem[1] <= 32'd7;
            dmem[2] <= 32'd0;
            dmem[3] <= 32'd0;
        end else if (!done) begin
            if (mem_valid && mem_mem_write)
                dmem[mem_alu_result[3:0]] <= mem_store_data;

            if (wb_valid && wb_we && (wb_rd != 3'd0))
                regs[wb_rd] <= wb_result;

            commit_count <= commit_count + {{6{1'b0}}, commit_inc};

            if (wb_valid && wb_halt)
                done <= 1'b1;

            wb_valid <= mem_valid;
            wb_pc <= mem_pc;
            wb_rd <= mem_rd;
            wb_result <= mem_mem_read ? dmem[mem_alu_result[3:0]] : mem_alu_result;
            wb_we <= mem_we;
            wb_halt <= mem_halt;

            mem_valid <= ex_valid;
            mem_pc <= ex_pc;
            mem_rd <= ex_rd;
            mem_alu_result <= ex_result;
            mem_store_data <= ex_store_data_next;
            mem_we <= ex_we;
            mem_mem_read <= ex_mem_read;
            mem_mem_write <= ex_mem_write;
            mem_halt <= ex_halt;

            if (branch_taken) begin
                ex_valid <= 1'b0;
                ex_pc <= 8'd0;
                ex_opcode <= OP_NOP;
                ex_rd <= 3'd0;
                ex_rs1 <= 3'd0;
                ex_rs2 <= 3'd0;
                ex_imm <= 32'd0;
                ex_rs1_val <= 32'd0;
                ex_rs2_val <= 32'd0;
                ex_we <= 1'b0;
                ex_mem_read <= 1'b0;
                ex_mem_write <= 1'b0;
                ex_branch <= 1'b0;
                ex_halt <= 1'b0;

                id_valid <= 1'b0;
                id_pc <= 8'd0;
                id_instr <= 32'd0;
                pc <= branch_target[7:0];
            end else if (load_use_hazard) begin
                ex_valid <= 1'b0;
                ex_pc <= 8'd0;
                ex_opcode <= OP_NOP;
                ex_rd <= 3'd0;
                ex_rs1 <= 3'd0;
                ex_rs2 <= 3'd0;
                ex_imm <= 32'd0;
                ex_rs1_val <= 32'd0;
                ex_rs2_val <= 32'd0;
                ex_we <= 1'b0;
                ex_mem_read <= 1'b0;
                ex_mem_write <= 1'b0;
                ex_branch <= 1'b0;
                ex_halt <= 1'b0;
            end else begin
                ex_valid <= id_valid;
                ex_pc <= id_pc;
                ex_opcode <= id_opcode;
                ex_rd <= id_rd;
                ex_rs1 <= id_rs1;
                ex_rs2 <= id_rs2;
                ex_imm <= id_imm;
                ex_rs1_val <= (id_rs1 == 3'd0) ? 32'd0 : regs[id_rs1];
                ex_rs2_val <= (id_rs2 == 3'd0) ? 32'd0 : regs[id_rs2];
                ex_we <= instr_writes_rd(id_opcode);
                ex_mem_read <= (id_opcode == OP_LW);
                ex_mem_write <= (id_opcode == OP_SW);
                ex_branch <= (id_opcode == OP_BEQ);
                ex_halt <= (id_opcode == OP_HALT);

                id_valid <= 1'b1;
                id_pc <= pc;
                id_instr <= rom_word(pc);
                pc <= pc + 8'd1;
            end
        end
    end

endmodule

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
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

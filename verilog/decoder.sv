
// `timescale 1ns/100ps


  // Decode an instruction: given instruction bits IR produce the
  // appropriate datapath control signals.
  //
  // This is a *combinational* module (basically a PLA).
  //
module decoder(

	//input [31:0] inst,
	//input valid_inst_in,  // ignore inst when low, outputs will
	                      // reflect noop (except valid_inst)
	//see sys_defs.svh for definition
	input INST_PC inst_PC_i,

    output DECODE_PACKET decode_packet_o
);
	ALU_OPA_SELECT opa_select;
	ALU_OPB_SELECT opb_select;
	ALU_FUNC alu_func;
    DEST_REG_SEL dest_reg_sel;
	logic rd_mem;
	logic wr_mem;
	logic cond_branch;
	logic uncond_branch;
	logic csr_op;
	logic halt;     
	logic illegal;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [31:0] PC;
    logic [31:0] NPC;
    logic [31:0] extra_slot_a;
    logic [31:0] extra_slot_b;
	always_comb begin
		// default control values:
		// - valid instructions must override these defaults as necessary.
		//	 opa_select, opb_select, and alu_func should be set explicitly.
		// - invalid instructions should clear valid_inst.
		// - These defaults are equivalent to a noop
		// * see sys_defs.vh for the constants used here
		opa_select = OPA_IS_RS1;
		opb_select = OPB_IS_RS2;
		alu_func = ALU_ADD;
		dest_reg_sel = DEST_NONE;
		csr_op = `FALSE;
		rd_mem = `FALSE;
		wr_mem = `FALSE;
		cond_branch = `FALSE;
		uncond_branch = `FALSE;
		halt = `FALSE;
		illegal = `FALSE;
        rs1 = inst_PC_i.inst[19:15];
        rs2 = inst_PC_i.inst[24:20];
        PC = inst_PC_i.PC;
        NPC = inst_PC_i.NPC;
        casez (inst_PC_i.inst)
            `RV32_NOOP: begin
                dest_reg_sel   = DEST_NONE;
            end 
            `RV32_LUI: begin
                dest_reg_sel   = DEST_RD;
                opa_select = OPA_IS_ZERO;
                opb_select = OPB_IS_U_IMM;
            end
            `RV32_AUIPC: begin
                dest_reg_sel   = DEST_RD;
                opa_select = OPA_IS_PC;
                opb_select = OPB_IS_U_IMM;
            end
            `RV32_JAL: begin
                dest_reg_sel      = DEST_RD;
                opa_select    = OPA_IS_PC;
                opb_select    = OPB_IS_J_IMM;
                uncond_branch = `TRUE;
            end
            `RV32_JALR: begin
                dest_reg_sel      = DEST_RD;
                opa_select    = OPA_IS_RS1;
                opb_select    = OPB_IS_I_IMM;
                uncond_branch = `TRUE;
            end
            `RV32_BEQ, `RV32_BNE, `RV32_BLT, `RV32_BGE,
            `RV32_BLTU, `RV32_BGEU: begin
                opa_select  = OPA_IS_PC;
                opb_select  = OPB_IS_B_IMM;
                cond_branch = `TRUE;
            end
            `RV32_LB, `RV32_LH, `RV32_LW,
            `RV32_LBU, `RV32_LHU: begin
                dest_reg_sel   = DEST_RD;
                opb_select = OPB_IS_I_IMM;
                rd_mem     = `TRUE;
            end
            `RV32_SB, `RV32_SH, `RV32_SW: begin
                opb_select = OPB_IS_S_IMM;
                wr_mem     = `TRUE;
            end
            `RV32_ADDI: begin
                dest_reg_sel   = DEST_RD;
                opb_select = OPB_IS_I_IMM;
            end
            `RV32_SLTI: begin
                dest_reg_sel   = DEST_RD;
                opb_select = OPB_IS_I_IMM;
                alu_func   = ALU_SLT;
            end
            `RV32_SLTIU: begin
                dest_reg_sel   = DEST_RD;
                opb_select = OPB_IS_I_IMM;
                alu_func   = ALU_SLTU;
            end
            `RV32_ANDI: begin
                dest_reg_sel   = DEST_RD;
                opb_select = OPB_IS_I_IMM;
                alu_func   = ALU_AND;
            end
            `RV32_ORI: begin
                dest_reg_sel   = DEST_RD;
                opb_select = OPB_IS_I_IMM;
                alu_func   = ALU_OR;
            end
            `RV32_XORI: begin
                dest_reg_sel   = DEST_RD;
                opb_select = OPB_IS_I_IMM;
                alu_func   = ALU_XOR;
            end
            `RV32_SLLI: begin
                dest_reg_sel   = DEST_RD;
                opb_select = OPB_IS_I_IMM;
                alu_func   = ALU_SLL;
            end
            `RV32_SRLI: begin
                dest_reg_sel   = DEST_RD;
                opb_select = OPB_IS_I_IMM;
                alu_func   = ALU_SRL;
            end
            `RV32_SRAI: begin
                dest_reg_sel   = DEST_RD;
                opb_select = OPB_IS_I_IMM;
                alu_func   = ALU_SRA;
            end
            `RV32_ADD: begin
                dest_reg_sel   = DEST_RD;
            end
            `RV32_SUB: begin
                dest_reg_sel   = DEST_RD;
                alu_func   = ALU_SUB;
            end
            `RV32_SLT: begin
                dest_reg_sel   = DEST_RD;
                alu_func   = ALU_SLT;
            end
            `RV32_SLTU: begin
                dest_reg_sel   = DEST_RD;
                alu_func   = ALU_SLTU;
            end
            `RV32_AND: begin
                dest_reg_sel   = DEST_RD;
                alu_func   = ALU_AND;
            end
            `RV32_OR: begin
                dest_reg_sel   = DEST_RD;
                alu_func   = ALU_OR;
            end
            `RV32_XOR: begin
                dest_reg_sel   = DEST_RD;
                alu_func   = ALU_XOR;
            end
            `RV32_SLL: begin
                dest_reg_sel   = DEST_RD;
                alu_func   = ALU_SLL;
            end
            `RV32_SRL: begin
                dest_reg_sel   = DEST_RD;
                alu_func   = ALU_SRL;
            end
            `RV32_SRA: begin
                dest_reg_sel   = DEST_RD;
                alu_func   = ALU_SRA;
            end
            `RV32_MUL: begin
                dest_reg_sel   = DEST_RD;
                alu_func   = ALU_MUL;
            end
            `RV32_MULH: begin
                dest_reg_sel   = DEST_RD;
                alu_func   = ALU_MULH;
            end
            `RV32_MULHSU: begin
                dest_reg_sel   = DEST_RD;
                alu_func   = ALU_MULHSU;
            end
            `RV32_MULHU: begin
                dest_reg_sel   = DEST_RD;
                alu_func   = ALU_MULHU;
            end
            `RV32_CSRRW, `RV32_CSRRS, `RV32_CSRRC: begin
                csr_op = `TRUE;
            end
            `WFI: begin
                halt = `TRUE;
            end
            default: illegal = `TRUE;

        endcase // casez (inst)


    case(opa_select)
        OPA_IS_RS1:  extra_slot_a = 0;
        OPA_IS_NPC:  extra_slot_a = NPC;
        OPA_IS_PC:   extra_slot_a = PC;
        OPA_IS_ZERO: extra_slot_a = 0;
    endcase
    case(opb_select)
        OPB_IS_RS2:   extra_slot_b = 0;
        OPB_IS_I_IMM: extra_slot_b = `RV32_signext_Iimm(inst_PC_i.inst);
        OPB_IS_S_IMM: extra_slot_b = `RV32_signext_Simm(inst_PC_i.inst);
        OPB_IS_B_IMM: extra_slot_b = `RV32_signext_Bimm(inst_PC_i.inst);
        OPB_IS_U_IMM: extra_slot_b = `RV32_signext_Uimm(inst_PC_i.inst);
        OPB_IS_J_IMM: extra_slot_b = `RV32_signext_Jimm(inst_PC_i.inst);
    endcase

    decode_packet_o.rs1 = rs1;
    decode_packet_o.rs2 = rs2;
    decode_packet_o.dest_reg = inst_PC_i.inst.r.rd;

    decode_packet_o.decode_noreg_packet.opcode = inst_PC_i.inst[6:0];
    decode_packet_o.decode_noreg_packet.opa_select = opa_select;
    decode_packet_o.decode_noreg_packet.opb_select = opb_select;
    decode_packet_o.decode_noreg_packet.alu_opcode = alu_func;
    decode_packet_o.decode_noreg_packet.dest_reg_sel = dest_reg_sel;
    decode_packet_o.decode_noreg_packet.rd_mem = rd_mem;
    decode_packet_o.decode_noreg_packet.wr_mem = wr_mem;
    decode_packet_o.decode_noreg_packet.cond_branch = cond_branch;
    decode_packet_o.decode_noreg_packet.uncond_branch = uncond_branch;
    decode_packet_o.decode_noreg_packet.csr_op = csr_op;
    decode_packet_o.decode_noreg_packet.halt     = halt;
    decode_packet_o.decode_noreg_packet.illegal = illegal;
    decode_packet_o.decode_noreg_packet.extra_slot_a = extra_slot_a;
    decode_packet_o.decode_noreg_packet.extra_slot_b = extra_slot_b;
    decode_packet_o.decode_noreg_packet.rs1 = rs1;
    decode_packet_o.decode_noreg_packet.rs2 = rs2;
    decode_packet_o.decode_noreg_packet.mem_funct = inst_PC_i.inst.s.funct3;
    decode_packet_o.decode_noreg_packet.funct7 = inst_PC_i.inst.r.funct7;
    
    //blu_code
    decode_packet_o.decode_noreg_packet.blu_opcode = inst_PC_i.inst.b.funct3;
    //PC
    decode_packet_o.decode_noreg_packet.PC = inst_PC_i.PC;
    //NPC
    decode_packet_o.decode_noreg_packet.NPC = inst_PC_i.NPC;

	end // always
endmodule // decoder
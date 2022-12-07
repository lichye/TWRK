`ifndef __ALU_SV__
`define __ALU_SV__

// `timescale 1ns/100ps

module alu(
    input clk,
    input reset,

	//input RS_FU_PACKET FU_packet_i,
	input [`XLEN-1:0] opa,
	input [`XLEN-1:0] opb,
	input ALU_FUNC     func,
	input logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_i,
    input execute_en_i,
	input complete_en_i,
	input DEST_REG_SEL dest_reg_sel_i,

	input logic [1:0] branch_recover_i,


	output logic ready_o,
	output logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_o,
	output DEST_REG_SEL dest_reg_sel_o,
	output logic regfile_wr_en_o,
	output logic [`XLEN-1:0] result_o,
    output logic done_o
);
	wire signed [`XLEN-1:0] signed_opa, signed_opb;
	wire signed [2*`XLEN-1:0] signed_mul, mixed_mul;
	wire        [2*`XLEN-1:0] unsigned_mul;

	logic [`XLEN-1:0] result_reg;
	logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_reg;
	DEST_REG_SEL dest_reg_sel_reg;
	logic ready_reg;
	logic done_reg;

	assign signed_opa = opa;
	assign signed_opb = opb;
	assign signed_mul = signed_opa * signed_opb;
	assign unsigned_mul = opa * opb;
	assign mixed_mul = signed_opa * opb;


	assign regfile_wr_en_o = complete_en_i & dest_reg_sel_o == DEST_RD;

	always_comb begin
		ready_o = ready_reg;
		done_o = done_reg;
		dest_reg_sel_o = dest_reg_sel_reg;
		dest_reg_o = dest_reg_reg;
		if(branch_recover_i[0] == 1'b1) begin
			ready_o = 1'b1;
			done_o = 1'b0;
		end else begin
			if(complete_en_i) begin
				done_o = 1'b0;
				ready_o = 1'b1;
			end
			if(execute_en_i) begin
				done_o = 1'b1; // ALU execution takes 1 cycle
				ready_o = 1'b0;
				dest_reg_o = dest_reg_i;
				dest_reg_sel_o = dest_reg_sel_i;
			end
		end
	end

	always_comb begin
		result_o = result_reg;
		if(execute_en_i) begin
			case (func)
				ALU_ADD:      result_o = opa + opb;
				ALU_SUB:      result_o = opa - opb;
				ALU_AND:      result_o = opa & opb;
				ALU_SLT:      result_o = signed_opa < signed_opb;
				ALU_SLTU:     result_o = opa < opb;
				ALU_OR:       result_o = opa | opb;
				ALU_XOR:      result_o = opa ^ opb;
				ALU_SRL:      result_o = opa >> opb[4:0];
				ALU_SLL:      result_o = opa << opb[4:0];
				ALU_SRA:      result_o = signed_opa >>> opb[4:0]; // arithmetic from logical shift
				ALU_MUL:      result_o = signed_mul[`XLEN-1:0];
				ALU_MULH:     result_o = signed_mul[2*`XLEN-1:`XLEN];
				ALU_MULHSU:   result_o = mixed_mul[2*`XLEN-1:`XLEN];
				ALU_MULHU:    result_o = unsigned_mul[2*`XLEN-1:`XLEN];

				default:      result_o = `XLEN'hfacebeec;  // here to prevent latches
			endcase
		end
	end

    always_ff @(posedge clk) begin
        if(reset) begin
            done_reg <= 1'b0;
			ready_reg <= 1'b1;
			dest_reg_reg <= 0;
			dest_reg_sel_reg <= DEST_NONE;
			result_reg <= 0;
        end else begin
			done_reg <= done_o;
			ready_reg <= ready_o;
			dest_reg_sel_reg <= dest_reg_sel_o;
			dest_reg_reg <= dest_reg_o;
			result_reg <= result_o;
		end
    end
endmodule // alu

`endif
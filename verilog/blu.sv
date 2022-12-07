`ifndef __BLU_SV__
`define __BLU_SV__

// `timescale 1ns/100ps


module blu(
    input clk,
    input reset,

	input [`XLEN-1:0] opa,
	input [`XLEN-1:0] opb,
	input [`XLEN-1:0] rs1,
	input [`XLEN-1:0] rs2,
	input [1:0] prediction,
	input [1:0][`XLEN-1:0] prediction_address,

	input logic [1:0] [$clog2(`PREG_NUMBER)-1:0] dispatch_reg_i,
	input logic [1:0] dispatch_branch_i,
	input logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_i,
	input DEST_REG_SEL dest_reg_sel_i,
	input logic [2:0] func_br,
	input logic [`XLEN-1:0] NPC_i,
	input logic [`XLEN-1:0] PC_i,
	input logic [6:0] inst_opcode,
	input execute_en_i,

	input complete_en_i,

	input logic [1:0] branch_recover_i,

	input logic [1:0] branch_retire_en_i,
	input logic [1:0] [$clog2(`PREG_NUMBER)-1:0] branch_retire_dest_reg_i,

	output logic ready_o,

	output logic [`XLEN-1:0] result_o, // complete
	output logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_o,
	output logic  regfile_wr_en_o,

	output BRANCH_RECOVER_OUT [1:0] branch_recover_packet_o,

	// output logic br_cond_o,
    output logic done_o
);

	DEST_REG_SEL dest_reg_sel_o;
	logic brcond_result;

	
	logic next_br_cond;
	logic [`XLEN-1:0] next_br_target;
	BRANCH_BUFFER_ENTRY [`BRANCH_BUFFER_SIZE - 1 : 0] branch_buffer;
	BRANCH_BUFFER_ENTRY [`BRANCH_BUFFER_SIZE - 1 : 0] next_branch_buffer;

	logic [`XLEN-1:0] result_reg;
	logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_reg;
	DEST_REG_SEL dest_reg_sel_reg;
	logic ready_reg;
	logic done_reg;

	assign regfile_wr_en_o = complete_en_i & dest_reg_sel_o == DEST_RD;

	brcond brcond (
		.rs1(rs1), 
		.rs2(rs2),
		.func(func_br), // inst bits to determine check
		.cond(brcond_result)
	);
	
	always_comb begin
		ready_o = ready_reg;
		done_o = done_reg;
		dest_reg_sel_o = dest_reg_sel_reg;
		dest_reg_o = dest_reg_reg;
		result_o = result_reg;
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
				result_o = PC_i + 32'h4;
			end
		end
	end
		
	always_comb begin
		next_br_cond = 0;
		next_br_target = 0;
		if(execute_en_i) begin
			case(inst_opcode)
				7'b1101111: begin// J jump
					next_br_target = opa + opb;
					next_br_cond = 1'b1;
				end
				7'b1100111: begin // I jump
					next_br_target = opa + opb;
					next_br_cond = 1'b1;	
				end
				7'b1100011: begin //cond branch
					next_br_target = opa + opb;
					next_br_cond = brcond_result;
				end
			endcase		


		end
	end
	
	logic debug1;
	logic debug2;
	logic [31:0] debug3;
	integer i;
	integer j;
	integer output_index;
	logic [4:0] head;
	logic [4:0] tail;
	logic [4:0] next_head;
	logic [4:0] next_tail;
	logic [1:0] packet_found;
	always_comb begin
		next_head = head;
		next_tail = tail;
		next_branch_buffer = branch_buffer;
		branch_recover_packet_o = 0;
		i = 0;
		j = 0;
		output_index = 0;
		packet_found = 1'b0;

		for(output_index = 1'b0; output_index < 2'h2; output_index = output_index + 1'b1) begin
			if(branch_retire_en_i[output_index]) begin
				assert(branch_buffer[head + packet_found].valid == 1'b1);
				branch_recover_packet_o[output_index].br_cond = branch_buffer[head + packet_found].br_cond;
				branch_recover_packet_o[output_index].br_target = branch_buffer[head + packet_found].br_target;
				next_branch_buffer[head + packet_found].valid = 1'b0;
				next_head = head + packet_found + 1'b1;
				packet_found = packet_found + 1'b1;
			end
		end

		//write
		if(branch_recover_i[0]) begin
			next_branch_buffer = 0;
			next_head = 0;
			next_tail = 0;
		end else begin
			// look up in the buffer
			if(execute_en_i) begin
				for(i = 0; i < `BRANCH_BUFFER_SIZE; i++) begin
					if(branch_buffer[i].dest_tag == dest_reg_i && next_branch_buffer[i].valid) begin
						case(branch_buffer[i].prediction)
							1'b0: begin
								if(next_br_cond) begin
									next_branch_buffer[i].br_cond = 1'b1;
									next_branch_buffer[i].br_target = next_br_target;
								end else begin
									next_branch_buffer[i].br_cond = 1'b0;
									next_branch_buffer[i].br_target = 0;
								end
							end
							1'b1: begin
								if(next_br_cond) begin
									if(next_br_target == branch_buffer[i].prediction_address) begin
										next_branch_buffer[i].br_cond = 0;
										next_branch_buffer[i].br_target = 0;
									end else begin
										next_branch_buffer[i].br_cond = 1'b1;
										next_branch_buffer[i].br_target = next_br_target;
									end
								end else begin
									next_branch_buffer[i].br_cond = 1'b1;
									next_branch_buffer[i].br_target = PC_i + 32'h4;
								end
							end
						endcase
						break;
					end
				end
			end

			// dispatch allocate
			if(dispatch_branch_i[0]) begin
				next_branch_buffer[tail].valid = 1'b1;
				next_branch_buffer[tail].dest_tag = dispatch_reg_i[0];
				next_branch_buffer[tail].prediction = prediction[0];
				next_branch_buffer[tail].prediction_address = prediction_address[0];
				next_tail = tail + 1'b1;
			end
			if(dispatch_branch_i[1]) begin
				next_branch_buffer[tail + dispatch_branch_i[0]].valid = 1'b1;
				next_branch_buffer[tail + dispatch_branch_i[0]].dest_tag = dispatch_reg_i[1];
				next_branch_buffer[tail + dispatch_branch_i[0]].prediction = prediction[1];
				next_branch_buffer[tail + dispatch_branch_i[0]].prediction_address = prediction_address[1];
				next_tail = tail + dispatch_branch_i[0] + 1'b1;
			end
		end

	end
	
    always_ff @(posedge clk) begin
        if(reset) begin
            done_reg <= 1'b0;
			ready_reg <= 1'b1;
			dest_reg_reg <= 0;
			dest_reg_sel_reg <= DEST_NONE;
			result_reg <= 0;
			branch_buffer <= 0;
			head <= 0;
			tail <= 0;
        end else begin
			head <= next_head;
			tail <= next_tail;
			done_reg <= done_o;
			ready_reg <= ready_o;
			dest_reg_sel_reg <= dest_reg_sel_o;
			dest_reg_reg <= dest_reg_o;
			result_reg <= result_o;
			branch_buffer <= next_branch_buffer;
		end
    end
endmodule // alu


module brcond(// Inputs
	input [`XLEN-1:0] rs1,    // Value to check against condition
	input [`XLEN-1:0] rs2,
	input  [2:0] func,  // Specifies which condition to check

	output logic cond    // 0/1 condition result (False/True)
);

	logic signed [`XLEN-1:0] signed_rs1, signed_rs2;
	assign signed_rs1 = rs1;
	assign signed_rs2 = rs2;
	always_comb begin
		cond = 0;
		case (func)
			3'b000: cond = signed_rs1 == signed_rs2;  // BEQ
			3'b001: cond = signed_rs1 != signed_rs2;  // BNE
			3'b100: cond = signed_rs1 < signed_rs2;   // BLT
			3'b101: cond = signed_rs1 >= signed_rs2;  // BGE
			3'b110: cond = rs1 < rs2;                 // BLTU
			3'b111: cond = rs1 >= rs2;                // BGEU
		endcase
	end
	
endmodule // brcond

`endif
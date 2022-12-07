`ifndef __RS_SV__
`define __RS_SV__

// `timescale 1ns/100ps

module rs(
	`ifdef DEBUG
	output RS_ENTRY [`RS_LENGTH-1 : 0] entries_debug,
	`endif

	input logic clk,
	input logic reset,

	input logic [1:0]                                                     dispatch_en_i,
    input logic [`SUPERSCALE_WIDTH - 1 :0] [$clog2(`PREG_NUMBER) - 1 : 0] dest_tag_i,     // Dispatch: from Freelist
    input logic [`SUPERSCALE_WIDTH - 1 :0] [$clog2(`PREG_NUMBER) - 1 : 0] source_tag_1_i, // Dispatch: from Maptable
    input logic [`SUPERSCALE_WIDTH - 1 : 0]                               ready_1_i,      // Dispatch: from Maptable
    input logic [`SUPERSCALE_WIDTH - 1 :0] [$clog2(`PREG_NUMBER) - 1 : 0] source_tag_2_i, // Dispatch: from Maptable
    input logic [`SUPERSCALE_WIDTH - 1 : 0]                               ready_2_i,      // Dispatch: from Maptbale
	input DECODE_NOREG_PACKET [`SUPERSCALE_WIDTH - 1 :0]                  RS_decode_noreg_packet,

	input logic [1:0]                                                     branch_recover_i, //enable for branch
    input logic [`SUPERSCALE_WIDTH - 1 : 0] [$clog2(`PREG_NUMBER)-1 : 0]  CDB_i,//WB: from CDB
	input logic [1:0]                                                     CDB_en_i,

    input logic [`FU_NUMBER-1:0]                                          fu_ready_i, //issue: from ALU

	output STRUCTURE_FULL                                                   RS_full_o,  // To control
	output logic [`RS_LENGTH-1 : 0]                                       execute_en_o, // Issue: To FU
	output RS_FU_PACKET [`SUPERSCALE_WIDTH - 1: 0]                        FU_packet_o,   // Issue: To FU
	output logic [`FU_NUMBER-1:0]                                         FU_select_en_o,
	output logic [`FU_NUMBER-1:0]                                         FU_select_RS_port_o
);
	integer i;
    integer j;
	integer k;
	integer issue_break;

	RS_ENTRY [`RS_LENGTH-1 : 0] entries;
	RS_ENTRY [`RS_LENGTH-1 : 0] next_entries;
	
	`ifdef DEBUG
	assign entries_debug = next_entries;
	`endif

	//issue
	logic [`RS_LENGTH-1 : 0]                 next_execute_en_o;
	RS_FU_PACKET [`SUPERSCALE_WIDTH - 1 : 0] next_fu_packet_o;
	logic [`FU_NUMBER-1:0]                   next_FU_select_en;
	logic [`FU_NUMBER-1:0]                   next_FU_select_RS_port;
	logic [`FU_NUMBER-1:0]                   FU_map;
	logic [`FU_NUMBER-1:0]                   FU_available;
	logic [`FU_NUMBER-1:0]                   fu_useful;
	//counter
	integer count;

	//check valid_tag for reg1 and reg2 
	always_comb begin
		
		next_fu_packet_o = 0;
		next_execute_en_o = 0;

		next_entries = entries;

		next_FU_select_en = 0;
		next_FU_select_RS_port = 0;

		FU_map = 0;
		if(branch_recover_i[0]) begin
			next_entries = {0, 0, 0, 0}; // hardcoded for RS number
		end else begin
			// Complete: check CDB 
			for(i = 0; i < `SUPERSCALE_WIDTH; i++) begin
				if(CDB_en_i[i]) begin
					for(j = 0; j < `RS_LENGTH; j++) begin
						if(next_entries[j].RS_valid) begin
							if(next_entries[j].fu_packet.source_tag_1 == CDB_i[i]) begin
								next_entries[j].tag_1_ready = 1'b1; 				
							end
							if(next_entries[j].fu_packet.source_tag_2 == CDB_i[i]) begin
								next_entries[j].tag_2_ready = 1'b1; 				
							end 
						end
					end	
				end	
			end
		
			// Issue: issue logic
			FU_available = 5'b11111;
			issue_break = 0;
			FU_available = fu_ready_i;
			j = 0;	
			for(k = 0; k < `RS_LENGTH && issue_break < 2; k++) begin
				if(next_entries[k].RS_valid) begin
					// check if issue
					case(next_entries[k].fu_packet.decode_noreg_packet.opcode)
						// `RV32_OP: begin
						// 	if(next_entries[k].fu_packet.decode_noreg_packet.funct7 == 7'h1 && 0) begin
						// 		FU_map = `FU_NUMBER'b10000;
						// 	end
						// 	else begin
						// 		FU_map = `FU_NUMBER'b00011;
						// 	end
						// end	
						`RV32_LOAD, `RV32_STORE: 				   FU_map = `FU_NUMBER'b01000;
						`RV32_BRANCH, `RV32_JALR_OP, `RV32_JAL_OP: FU_map = `FU_NUMBER'b00100;
						default:                                   FU_map = `FU_NUMBER'b00011;
					endcase
					fu_useful = FU_map & FU_available;
					if(next_entries[k].tag_1_ready && next_entries[k].tag_2_ready && fu_useful > 0) begin						
						next_entries[k].RS_valid       = 1'b0;                      // clear entry					
						next_execute_en_o[issue_break] = 1'b1;                      // enable issue
						next_fu_packet_o[issue_break]  = next_entries[k].fu_packet;
						issue_break = issue_break + 1;
						for(i = 0; i < `FU_NUMBER; i++) begin
							if(fu_useful[i]) begin
								next_FU_select_en[i]      = 1'b1;
								next_FU_select_RS_port[i] = j;    // from which rs port 
								FU_available[i] = 1'b0;
								j = j + 1'b1;
								break;
							end
						end
					end	
				end
						
			end



			count = 0;
			for(k = 0; k < `RS_LENGTH; k++) begin
				if(!next_entries[k].RS_valid) begin
					count = count + 1;
				end
			end
			RS_full_o = count == 0 ? FULL : count == 1? ONE_LEFT : MORE_LEFT;
			// Dispatch
			j = 0;
			if(dispatch_en_i[0]) begin 
				for(k = 0; k < `RS_LENGTH && j < 1 + dispatch_en_i[1]; k++) begin
					if(!next_entries[k].RS_valid) begin
						next_entries[k].RS_valid = 1'b1;
						next_entries[k].tag_1_ready = ready_1_i[j];
						next_entries[k].tag_2_ready = ready_2_i[j];
						next_entries[k].fu_packet.source_tag_1 = source_tag_1_i[j];
						next_entries[k].fu_packet.source_tag_2 = source_tag_2_i[j];
						next_entries[k].fu_packet.dest_tag     = dest_tag_i[j];
						next_entries[k].fu_packet.decode_noreg_packet = RS_decode_noreg_packet[j];//fix
						j = j + 1;
					end
				end
			end
		end
	end


	//seq logic
	always_ff @( posedge clk ) begin
		if(reset) begin
			entries             <= {0, 0, 0, 0};
			execute_en_o        <= 0;
			FU_packet_o         <= {0, 0};
			FU_select_en_o      <= 0;
			FU_select_RS_port_o <= 0;
		end
		else begin
			entries             <= next_entries;
			execute_en_o        <= next_execute_en_o;
			FU_packet_o         <= next_fu_packet_o;
			FU_select_en_o      <= next_FU_select_en;
			FU_select_RS_port_o <= next_FU_select_RS_port;
		end	
	end
endmodule

`endif //__RS_SV__






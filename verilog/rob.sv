`ifndef __ROB_SV__
`define __ROB_SV__

// `timescale 1ns/100ps

module rob(

	`ifdef DEBUG
	output logic [$clog2(`ROB_SIZE)-1:0] head_debug,
	output logic [$clog2(`ROB_SIZE)-1:0] tail_debug,
    output logic [$clog2(`ROB_SIZE)-1:0] next_head_debug,
	output ROB_ENTRY [`ROB_SIZE-1:0] entries_debug,
	output logic [`ROB_SIZE-1:0] completed_debug,

	`endif

	input clk,
	input reset,
	input [1:0] dispatch_en_i,                                    // D, control signal of dispatch
	input logic [1:0] [$clog2(`ARCHREG_NUMBER)-1: 0] arch_old_i,  // D, dest arch reg
	input [1:0][$clog2(`PREG_NUMBER)-1:0] preg_tag_old_i,   // D, old tag of dest physical register, from Map Table
	input ROB_RETIRE_PACKET [1:0] retire_packet_i,
	input [1:0][$clog2(`PREG_NUMBER)-1:0] freeReg_i,        // D, renamed tag, from Freelist
	input [1:0][$clog2(`PREG_NUMBER)-1: 0] CDB_i,           // C, from CDB
	input [1:0] CDB_en_i,

	input [1:0] branch_recover_i,                            // C


	output logic [1:0][$clog2(`PREG_NUMBER)-1:0] T_o,       // R, tag updated in tail, to Arch Table       
    output logic [1:0][$clog2(`PREG_NUMBER)-1:0] T_old_o,   // R, retired tag, to Free List
	output logic [1:0][$clog2(`ARCHREG_NUMBER)-1: 0] arch_old_o,
	output logic [1:0]retire_en_o,                          // R, to Arch Table and FL
	output STRUCTURE_FULL ROB_full_o,
	output ROB_RETIRE_PACKET  [1:0] retire_packet_o
);
	ROB_ENTRY [`ROB_SIZE-1:0] entries;
	ROB_ENTRY [`ROB_SIZE-1:0] next_entries;
	logic [`ROB_SIZE-1:0] completed;
	logic [`ROB_SIZE-1:0] next_completed;
	logic [$clog2(`ROB_SIZE)-1:0] head;
	logic [$clog2(`ROB_SIZE)-1:0] next_head;
	logic [$clog2(`ROB_SIZE)-1:0] tail;
	logic [$clog2(`ROB_SIZE)-1:0] next_tail;

    logic [1:0][$clog2(`PREG_NUMBER)-1:0] next_T_o;       // R, tag updated in tail, to Arch Table       
    logic [1:0][$clog2(`PREG_NUMBER)-1:0] next_T_old_o;   // R, retired tag, to Free List
    logic [1:0] next_retire_en_o;                          // R, to Arch Table and FL
	logic [1:0][$clog2(`ARCHREG_NUMBER)-1: 0] next_arch_old_o;
	ROB_RETIRE_PACKET  [1:0] next_retire_packet_o;


	integer i;
	integer k;
    logic [$clog2(`ROB_SIZE)-1:0] loop_index;
	logic [$clog2(`ROB_SIZE)-1:0] loop_index_2;
	
	`ifdef DEBUG
	assign head_debug = head;
	assign tail_debug = tail;
    assign next_head_debug = next_head; // wtf why ??????????????????????????????????????? need this to pass synthesis
	assign completed_debug = next_completed;
	assign entries_debug = next_entries;
	`endif
	
	// full signal
	always_comb begin
        ROB_full_o = ILLEGAL;
		if(entries[head].valid) begin // when there is an entry at the head
			if(tail == head) ROB_full_o = FULL;
			else if (tail + 5'h1 == head) ROB_full_o = ONE_LEFT;
			else ROB_full_o = MORE_LEFT;
		end else begin // or there is nothing in the RoB
			ROB_full_o = MORE_LEFT;
		end
	end

	always_comb begin
		next_head = head;
        next_entries = entries;
        next_T_o = T_o;
        next_T_old_o = T_old_o;
        next_retire_en_o = 0;
		next_arch_old_o = arch_old_o;
		next_retire_packet_o = retire_packet_o;
		next_tail = tail;
		next_completed = completed;
	

		if(branch_recover_i[0]) begin // if any inst recover, clear everything
			next_completed = 0;
			next_entries = 0;
			next_tail = next_head;
		end else begin
			// Update complete bits according to CDB input
			for(i=0; i<`ROB_SIZE; i++) begin
				for(k = 0; k < 2 & CDB_en_i[k]; k++) begin
					if(entries[i].T == CDB_i[k] && entries[i].valid) 
						next_completed[i] = `TRUE;
				end
			end

			for (loop_index = 5'h0; loop_index < 5'h2; loop_index = loop_index + 1'b1) begin
				if(next_completed[head + loop_index]) begin
					// update head pointer
					next_head  = head + 1 + loop_index;
					// clear valid bit
					next_entries[head + loop_index].valid = 1'b0;
					// output
					next_T_o[loop_index] = entries[head + loop_index].T;
					next_T_old_o[loop_index]  = entries[head + loop_index].T_old;
					next_arch_old_o[loop_index] = entries[head + loop_index].arch_old;
					next_retire_packet_o[loop_index] = entries[head + loop_index].retire_packet;
					// enable retire 
					next_retire_en_o[loop_index] = 1'b1;
				end else break; // do not retire the second one if the first one is not retired
			end
			next_retire_en_o[1] = next_retire_packet_o[0].halt? 0 : next_retire_en_o[1];


			if(dispatch_en_i[0]) begin // if dispatch, update entry at tail, update tail
				for (loop_index_2 = 0; loop_index_2 < 5'h2; loop_index_2 = loop_index_2 + 1'b1) begin
					if(!(dispatch_en_i[1] == 0 & loop_index_2 == 1) & (ROB_full_o != FULL) & !(ROB_full_o == ONE_LEFT & dispatch_en_i[1] == 1'b1)) begin
						next_entries[tail + loop_index_2].valid = `TRUE;
						next_entries[tail + loop_index_2].T     = freeReg_i[loop_index_2];
						next_entries[tail + loop_index_2].T_old = preg_tag_old_i[loop_index_2];
						next_entries[tail + loop_index_2].arch_old = arch_old_i[loop_index_2];
						next_entries[tail + loop_index_2].retire_packet = retire_packet_i[loop_index_2];
						next_tail = tail + 1'b1 + loop_index_2;
					end
				end
			end
		end
    end    
	
    logic [1:0] p;
    //reset and change entries, head and tail
	always_ff @(posedge clk) begin
		if (reset) begin
			head <= `SD 0;
			tail <= `SD 0;
			entries <=  `SD 0;
			completed <= `SD `ROB_SIZE'h0;

            T_o <= `SD 0;
            T_old_o <= `SD 0;
			retire_en_o <= `SD 0;
			arch_old_o <= 0;
			retire_packet_o <= 0;
		end else begin
			//retire
            head <= `SD next_head;
            tail <= `SD next_tail;
            entries <= `SD next_entries;
            completed <= `SD next_completed;

            for (p = 2'b0; p < 2'h2; p = p + 1'b1) begin
                if(next_completed[head + p]) begin
                    // clear completed flag
                    completed[head + p] <= `SD 1'b0;
                end else break;
            end

            T_o <= `SD next_T_o;
            T_old_o <= `SD next_T_old_o;
            retire_en_o <= `SD next_retire_en_o;
			arch_old_o <= next_arch_old_o;
			retire_packet_o <= next_retire_packet_o;
		end
	end


endmodule

`endif //__ROB_SV__

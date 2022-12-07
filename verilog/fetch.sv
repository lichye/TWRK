// `ifndef __FETCH_SV__
// `define __FETCH_SV__
module fetch(
	`ifdef DEBUG
	output [`XLEN-1:0] PC,
	`endif
	 
	input                    clk,              // system clock
	input                    reset,              // system reset

	input                    take_branch_i,      // taken-branch signal
	input  [`XLEN-1:0]       branch_target_pc_i, // target pc: use if take_branch is TRUE

	input logic [1:0] 		 PC_increment_i,       //

	input  [63:0]            Imem2proc_data,     // Data coming back from instruction-memory
	input logic              Icache_valid_i,

	output logic [`XLEN-1:0]    proc2Imem_addr,     // Address sent to Instruction memory
	output logic                read_valid_o,

	output STRUCTURE_FULL fetch_buffer_empty_o,

	output INST_PC [1:0]        inst_PC_o                // Output data packet from IF going to ID, see sys_defs for signal information 
);

	INST [`FETCH_BUFFER_SIZE-1:0] fetch_buffer;
	logic [$clog2(`FETCH_BUFFER_SIZE)-1:0] read_ptr;
	logic [$clog2(`FETCH_BUFFER_SIZE)-1:0] write_ptr;
	logic [$clog2(`FETCH_BUFFER_SIZE)-1:0] next_read_ptr;
	logic [$clog2(`FETCH_BUFFER_SIZE)-1:0] next_write_ptr;

	logic [`XLEN-1:0] PC_reg;             // PC we are currently fetching
	logic [`XLEN-1:0] PC_plus_4;
	logic [`XLEN-1:0] next_PC;
	logic [`XLEN-1:0] addr_buffer;
	logic [`XLEN-1:0] next_addr_buffer;
	logic [`XLEN-1:0] prefetch;
	logic [`XLEN-1:0] prefetch_buffer;
	
	logic wait_for_resp;
	logic next_wait_for_resp;

	logic need_more_inst;

	logic jump_flag;

	assign inst_PC_o[0].inst = fetch_buffer[read_ptr];
	assign inst_PC_o[1].inst = fetch_buffer[read_ptr + 1'b1];
	assign inst_PC_o[0].PC = PC_reg;
	assign inst_PC_o[1].PC = PC_reg + 32'h4;
	assign inst_PC_o[0].NPC = PC_reg + 32'h4;
	assign inst_PC_o[1].NPC = PC_reg + 32'h8;


	// assign PC_plus_4 = jump_flag ? PC_reg : PC_reg + 32'h4; // align

	// align with 8 byte boundary
	// when pc points to the middle of 8 byte block, the address should be aligned to the next 8 byte

	always_comb begin
		need_more_inst = 1'b0;
		if(read_ptr == write_ptr || read_ptr == write_ptr + 1'b1) begin
			fetch_buffer_empty_o = FULL;
			need_more_inst = 1'b1;
		end else if (read_ptr + 1'b1 == write_ptr) begin
			fetch_buffer_empty_o = ONE_LEFT;
			need_more_inst = 1'b1;
		end else if (read_ptr + 4'd13 == write_ptr || read_ptr + 4'd14 == write_ptr) begin // stop prefetch, TODO, weird bug when upper limit is around 11 with rv32_fib_long
			fetch_buffer_empty_o = MORE_LEFT;
			need_more_inst = 1'b0;			
		end else begin
			fetch_buffer_empty_o = MORE_LEFT;
			need_more_inst = 1'b1; // toggle prefetch
		end
	end

	always_comb begin
		next_read_ptr = read_ptr;
		next_write_ptr = write_ptr;
		next_wait_for_resp = wait_for_resp;
		read_valid_o = 1'b0;
		next_PC = PC_reg;

		// pipeline read
		next_read_ptr = take_branch_i ? write_ptr + branch_target_pc_i[2]: read_ptr + PC_increment_i[0] + PC_increment_i[1];

		// request memory
		if(take_branch_i || (need_more_inst && !wait_for_resp)) begin
			read_valid_o = 1'b1;
			next_wait_for_resp = 1'b1;
		end


		next_PC =  take_branch_i ? branch_target_pc_i : PC_reg + (PC_increment_i[0] + PC_increment_i[1]) * 4;
		prefetch = take_branch_i ? {branch_target_pc_i[`XLEN-1:3], 3'b0} : prefetch_buffer + need_more_inst * 32'h8; // align with write ptr

		if(take_branch_i) begin
			proc2Imem_addr = {next_PC[`XLEN-1:3], 3'b0};
		end else begin
			if(read_valid_o) begin
				proc2Imem_addr = {prefetch_buffer[`XLEN-1:3], 3'b0};
			end else begin
				proc2Imem_addr = addr_buffer;
			end
		end

	end

	always_ff @(posedge clk) begin
        if(reset) begin
			read_ptr <= 0;
			write_ptr <= 0;
			wait_for_resp <= 1'b0;
			PC_reg <= 0;
			jump_flag <= 0;
			addr_buffer <= 0;
			prefetch_buffer <= 0;
		end else begin
			read_ptr <= next_read_ptr;
			PC_reg <= next_PC;
			wait_for_resp <= Icache_valid_i ? 1'b0 : next_wait_for_resp;
			jump_flag <= 0;
			
			if(read_valid_o) addr_buffer <= proc2Imem_addr;

			if(take_branch_i && branch_target_pc_i[2] == 1'b1) jump_flag <= 1'b1;

			if(Icache_valid_i && next_wait_for_resp && !take_branch_i) begin
				prefetch_buffer <= prefetch;
				write_ptr <= write_ptr + 2'h2;
				fetch_buffer[write_ptr] <= Imem2proc_data[31:0];
				fetch_buffer[write_ptr + 1'b1] <= Imem2proc_data[63:32];
			end
			if(take_branch_i) begin
				prefetch_buffer <= prefetch;
			end
		end
	end
endmodule
// `endif
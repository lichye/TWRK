// `timescale 1ns/100ps
`define CACHE_LINES 32
`define CACHE_LINE_BITS $clog2(`CACHE_LINES)

// Visual debugger functions import
// import "DPI-C" function void next_cycle();
// import "DPI-C" function void print_ROB_NC();
// import "DPI-C" function void print_ROB_ENTRY(int valid,int T,int T_old,int complete,int);
// import "DPI-C" function void print_ROB_HEAD_TAIL(int head,int tail);
// import "DPI-C" function void print_MT_NC();
// import "DPI-C" function void print_MT_ENTRY(int num,int entry,int ready);
// import "DPI-C" function void print_CDB(int,int,int,int);
// import "DPI-C" function void print_RS_NC();
// import "DPI-C" function void print_RS_ENTRY(int,int,int,int,int,int,int,int,int,int,int,int);
// import "DPI-C" function void print_AT_NC();
// import "DPI-C" function void print_AT_ENTRY(int,int);
// import "DPI-C" function void print_Fetch_NC();
// import "DPI-C" function void print_Fecth_ENTRY(int,int,int,int,int);
// import "DPI-C" function void print_FU_NC();
// import "DPI-C" function void print_FU_ENTRY(int,int,int,int,int,int,int);
// import "DPI-C" function void print_FL_NC();
// import "DPI-C" function void print_FL_ENTRY(int,int);
// import "DPI-C" function void print_PP_NC();
// import "DPI-C" function void print_PP_ENTRY(int,int,int,int);
// import "DPI-C" function void print_RETIRE_NC();
// import "DPI-C" function void print_RETIRE_ENTRY(int,int,int,int,int);
// import "DPI-C" function void print_PR_NC();
// import "DPI-C" function void print_PR_ENTRY(int,int);

module testbench;
	logic        clk;
	logic        reset;
	
// pipeline to memory
	logic  [3:0] proc_mem2proc_response;
	logic [63:0] proc_mem2proc_data;
	logic  [3:0] proc_mem2proc_tag;
	
	logic [1:0]  proc_proc2mem_command;
	logic [`XLEN-1:0] proc_proc2mem_addr;
	logic [63:0] proc_proc2mem_data;

	logic  [3:0] proc_Dmem2proc_response;
	logic [63:0] proc_Dmem2proc_data;
	logic  [3:0] proc_Dmem2proc_tag;
	
	logic [1:0]  proc_proc2Dmem_command;
	logic [`XLEN-1:0] proc_proc2Dmem_addr;
	logic [63:0] proc_proc2Dmem_data;
	MEM_SIZE proc_proc2Dmem_size;
	

// memory
	logic [1:0]  mem_proc2mem_command;
	logic [`XLEN-1:0] mem_proc2mem_addr;
	logic [63:0] mem_proc2mem_data;
	logic  [3:0] mem_mem2proc_response;
	logic [63:0] mem_mem2proc_data;
	logic  [3:0] mem_mem2proc_tag;
	MEM_SIZE mem_proc2mem_size;

	logic [1:0]       Dmem_proc2Dmem_command;
	logic [`XLEN-1:0] Dmem_proc2Dmem_addr;
	logic [63:0]      Dmem_proc2Dmem_data;
	MEM_SIZE           Dmem_proc2Dmem_size;

	logic  [3:0]     Dmem_Dmem2proc_response;
	logic [63:0]     Dmem_Dmem2proc_data;
	logic  [3:0]     Dmem_Dmem2proc_tag;



// debug
	`ifdef DEBUG
		DEBUG_SIGNAL debug_signal;
	`endif

	// memory hierarchy connection
		assign proc_mem2proc_response = mem_mem2proc_response;
		assign proc_mem2proc_data = mem_mem2proc_data;
		assign proc_mem2proc_tag = mem_mem2proc_tag;
	// Pipeline -> memory
		assign mem_proc2mem_command = proc_proc2mem_command;
		assign mem_proc2mem_addr = proc_proc2mem_addr;
		assign mem_proc2mem_data = proc_proc2mem_data;

	// Instantiate the Pipeline
	pipeline core(
	//debug signal
		`ifdef DEBUG
		.debug_signal		(debug_signal),
		`endif	
		
		.clk               (clk),
		.reset             (reset),
	// Memory to pipeline
		.mem2proc_response(proc_mem2proc_response),
		.mem2proc_data(proc_mem2proc_data),
		.mem2proc_tag(proc_mem2proc_tag),
	// Pipeline -> memory
		.proc2mem_command(proc_proc2mem_command),
		.proc2mem_addr(proc_proc2mem_addr),
		.proc2mem_data(proc_proc2mem_data),

		.halt              (halt)
	);
	
	
	// Instantiate the Data Memory
	mem memory (
		.clk               (clk),
	// Pipeline input
		.proc2mem_command  (mem_proc2mem_command),
		.proc2mem_addr     (mem_proc2mem_addr),
		.proc2mem_data     (mem_proc2mem_data),
		`ifndef CACHE_MODE
		.proc2mem_size     (mem_proc2mem_size),
		`endif
	// Output -> pipeline
		.mem2proc_response (mem_mem2proc_response),
		.mem2proc_data     (mem_mem2proc_data),
		.mem2proc_tag      (mem_mem2proc_tag)
	);

	logic[31:0] clock_count;
	logic[31:0] instr_count;

	
	// Generate system clock
	always begin
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clk = ~clk;
	end

	integer i;
	always_ff @(posedge clk) begin
		if(reset) begin
			i = 0;
		end
		// $display("%d",i);
		if(i == 5000000) begin
			$display("Timeout!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
			$finish;
		end
		i = i + 1;
	end

	task show_clk_count;
		real cpi;
		begin
			cpi = (clock_count + 1.0) / instr_count;
			$display("@@  %0d cycles / %0d instrs = %f CPI\n@@",
			          clock_count+1, instr_count, cpi);
			$display("@@  %4.2f ns total time to execute\n@@\n",
			          clock_count*`VERILOG_CLOCK_PERIOD);
		end
	endtask  // task show_clk_count 

	task show_mem_with_decimal;
		input [31:0] start_addr;
		input [31:0] end_addr;
			//mem buffer
		logic [63:0]   data_buffer  [`MEM_64BIT_LINES - 1:0];
		logic [$clog2(`LSQ_SIZE)-1:0] loop_index;
		logic [7:0] current_tag;
		logic [4:0] current_index;
		int showing_data;
		LSQ_ENTRY now_entry;
		logic [`CACHE_LINES-1:0] [63:0]  cache_data_buffer;
		logic [`CACHE_LINES-1:0] [12 - `CACHE_LINE_BITS:0]  cache_tags_buffer;
	 	logic [`CACHE_LINES-1:0] cache_valids_buffer;
    	logic [`CACHE_LINES-1:0] cache_dirty_buffer;
		EXAMPLE_CACHE_BLOCK d;
		begin
			$display("@@@");
			showing_data=0;
			for(int i=0; i<`MEM_64BIT_LINES; i=i+1) begin
				data_buffer[i] = memory.unified_memory[i];
			end

			for(int k=start_addr;k<=end_addr; k=k+1) begin
				if(debug_signal.dcache_valids[k[4:0]] && debug_signal.dcache_tags[k[4:0]] == k[15:5]) begin
					data_buffer[k] = debug_signal.dcache_data[k[4:0]];
				end
			end

			cache_data_buffer = debug_signal.dcache_data;
			cache_tags_buffer = debug_signal.dcache_tags;
			cache_valids_buffer = debug_signal.dcache_valids;

			for(loop_index = 5'b0; loop_index + 1'b1 < `LSQ_SIZE; loop_index = loop_index + 1'b1) begin
				if(loop_index < debug_signal.LSQ_debug_next_head - debug_signal.LSQ_debug_next_retire_ptr) begin
					now_entry = debug_signal.LSQ_debug_lsq_entry[loop_index + debug_signal.LSQ_debug_next_retire_ptr];
					if(now_entry.opcode == `RV32_STORE) begin
						{current_tag, current_index} = now_entry.address[15:3];
						d.half_level = cache_data_buffer[current_index];
						d.word_level = cache_data_buffer[current_index];
						d.byte_level = cache_data_buffer[current_index];
						case (now_entry.mem_funct[1:0]) 
							BYTE: begin
								d.byte_level[now_entry.address[2:0]] =  now_entry.data[7:0];
								cache_data_buffer[current_index] = d.byte_level;
							end
							HALF: begin
								d.half_level[now_entry.address[2:1]] =  now_entry.data[15:0];
								cache_data_buffer[current_index] = d.half_level;
							end
							WORD: begin
								d.word_level[now_entry.address[2]] =  now_entry.data[31:0];
								cache_data_buffer[current_index] = d.word_level;
							end
							default: begin
								assert(1==0);
							end
						endcase
						cache_valids_buffer[current_index] = 1;
						cache_tags_buffer[current_index] = current_tag;
					end
				end
			end

			for(int k=start_addr;k<=end_addr; k=k+1) begin
				if(cache_valids_buffer[k[4:0]] && cache_tags_buffer[k[4:0]] == k[15:5]) begin
					data_buffer[k] = cache_data_buffer[k[4:0]];
				end
			end		

			for(int k=start_addr;k<=end_addr; k=k+1)
				if (data_buffer[k] != 0) begin
					$display("@@@ mem[%5d] = %x : %0d", k*8, data_buffer[k], 
				                                            data_buffer[k]);
					showing_data=1;
				end else if(showing_data!=0) begin
					$display("@@@");
					showing_data=0;
				end
			$display("@@@");
		end
	endtask  // task show_mem_with_decimal

	integer wb_fileno;
	integer time_fileno;
	initial begin
		// $dumpvars;
	
		clk = 1'b0;
		reset = 1'b0;
		// wb_fileno = $fopen("writeback.out");
		// time_fileno = $fopen("time.out");
		
		// Pulse the reset signal
		$display("@@\n@@\n@@  %t  Asserting System reset......", $realtime);
		reset = 1'b1;
		@(posedge clk);
		@(posedge clk);
		
		$readmemh("program.mem", memory.unified_memory);
		
		@(posedge clk);
		@(posedge clk);
		`SD;
		// This reset is at an odd time to avoid the pos & neg clock edges
		
		reset = 1'b0;
		$display("@@  %t  Deasserting System reset......\n@@\n@@", $realtime);
	end

	integer rs_cnt;
	integer mt_cnt;
	integer rob_cnt;
	integer at_cnt;
	integer fl_cnt;
	integer fr_cnt;
	logic halt_before;
    always @(posedge clk) begin
         if(reset) begin
	 		$display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
	 		         $realtime);
			clock_count <= 0;
			instr_count <= 0;
			halt_before <= 0;
         end else begin
			//  if(debug_signal.pipeline_commit[0]) begin
			// 	 if(debug_signal.pipeline_commit_data[0] >= 0 && debug_signal.pipeline_commit_reg[0] != `ZERO_REG) begin
			// 		 $fdisplay(wb_fileno, "PC=%x, REG[%d]=%x",
			// 			debug_signal.pipeline_commit_PC[0],
			// 			//0,
			// 			debug_signal.pipeline_commit_reg[0],
			// 			debug_signal.pipeline_commit_data[0]);
			// 		$fdisplay(time_fileno, "PC=%x, REG[%d]=%x %t",
			// 			debug_signal.pipeline_commit_PC[0],
			// 			//0,
			// 			debug_signal.pipeline_commit_reg[0],
			// 			debug_signal.pipeline_commit_data[0], $realtime);
			// 	 end else begin
			// 		 $fdisplay(wb_fileno, "PC=%x, ---", debug_signal.pipeline_commit_PC[0]);
			// 		 $fdisplay(time_fileno, "PC=%x, ---", debug_signal.pipeline_commit_PC[0]);
			// 	 end				 
			//  end
			 
			//  if(debug_signal.pipeline_commit[1]) begin
			// 	 if(debug_signal.pipeline_commit_data[1]  >= 0  && debug_signal.pipeline_commit_reg[1] != `ZERO_REG) begin
			// 		 $fdisplay(wb_fileno, "PC=%x, REG[%d]=%x",
			// 			debug_signal.pipeline_commit_PC[1],
			// 			//0,
			// 			debug_signal.pipeline_commit_reg[1],
			// 			debug_signal.pipeline_commit_data[1]);
			// 		$fdisplay(time_fileno, "PC=%x, REG[%d]=%x %t",
			// 			debug_signal.pipeline_commit_PC[1],
			// 			//0,
			// 			debug_signal.pipeline_commit_reg[1],
			// 			debug_signal.pipeline_commit_data[1], $realtime);
			// 	 end else begin
			// 		 $fdisplay(wb_fileno, "PC=%x, ---", debug_signal.pipeline_commit_PC[1]);
			// 		 $fdisplay(time_fileno, "PC=%x, ---", debug_signal.pipeline_commit_PC[0]);
			// 	 end
			//  end
			 clock_count <= halt_before ? clock_count : clock_count + 1;
			 instr_count <= halt_before ? instr_count : instr_count + debug_signal.pipeline_commit[0] + debug_signal.pipeline_commit[1];

			if(halt) begin
				halt_before <= 1;				
				$display("@@@ Unified Memory contents hex on left, decimal on right: ");
				show_mem_with_decimal(0,`MEM_64BIT_LINES - 1);

				$display("@@  %t : System halted\n@@", $realtime);
				$display("@@@ System halted on WFI instruction");
				$display("@@@\n@@");

				show_clk_count;

				// $fclose(wb_fileno);
				// $fclose(time_fileno);
				$finish;
			end	

		// //if you want to turn out visual debugger change this to 0
		// `ifdef VDEBUG
        //     next_cycle();
 		// 	print_RS_NC();
        //      for(rs_cnt=0;rs_cnt<`RS_LENGTH;rs_cnt++) begin
        //          print_RS_ENTRY(
        //                         debug_signal.RS_entries_debug[rs_cnt].RS_valid,
        //                         debug_signal.RS_entries_debug[rs_cnt].fu_packet.dest_tag,
        //                         debug_signal.RS_entries_debug[rs_cnt].fu_packet.source_tag_1,
        //                         debug_signal.RS_entries_debug[rs_cnt].tag_1_ready,
        //                         debug_signal.RS_entries_debug[rs_cnt].fu_packet.source_tag_2,
        //                         debug_signal.RS_entries_debug[rs_cnt].tag_2_ready,
		// 						debug_signal.RS_entries_debug[rs_cnt].fu_packet.decode_noreg_packet.alu_opcode,
		// 						debug_signal.RS_entries_debug[rs_cnt].fu_packet.decode_noreg_packet.rd_mem,
		// 						debug_signal.RS_entries_debug[rs_cnt].fu_packet.decode_noreg_packet.wr_mem,
		// 						debug_signal.RS_entries_debug[rs_cnt].fu_packet.decode_noreg_packet.cond_branch,
		// 						debug_signal.RS_entries_debug[rs_cnt].fu_packet.decode_noreg_packet.uncond_branch,
		// 						debug_signal.RS_entries_debug[rs_cnt].fu_packet.decode_noreg_packet.halt);
        //      end
		//  	print_CDB(debug_signal.CDB_en_debug[0],debug_signal.CDB_o_debug[0],debug_signal.CDB_en_debug[1],debug_signal.CDB_o_debug[1]);
		//  	print_MT_NC();
		//  	for(int mt_cnt=0;mt_cnt<`ARCHREG_NUMBER;mt_cnt++) begin
        //          print_MT_ENTRY(mt_cnt,debug_signal.MT_map_table_entry_Debug[mt_cnt],debug_signal.MT_map_table_ready_Debug[mt_cnt]);
        //      end
		//  	print_ROB_NC();
        //      print_ROB_HEAD_TAIL(debug_signal.ROB_head_debug,debug_signal.ROB_tail_debug);
        //      for(rob_cnt=0;rob_cnt<`ROB_SIZE;rob_cnt++) begin
        //          print_ROB_ENTRY(debug_signal.ROB_entries_debug[rob_cnt].valid,
        //                          debug_signal.ROB_entries_debug[rob_cnt].T,
        //                          debug_signal.ROB_entries_debug[rob_cnt].T_old,
        //                          debug_signal.ROB_completed_debug[rob_cnt],
		//  						debug_signal.ROB_entries_debug[rob_cnt].arch_old
		//  						);
        //      end
        //      print_AT_NC();
        //      for(at_cnt=0;at_cnt<`ARCHREG_NUMBER;at_cnt++) begin
        //          print_AT_ENTRY(at_cnt,debug_signal.arch_table_entry_debug[at_cnt]);
        //      end
			
		// 	print_Fetch_NC();
		// 	print_Fecth_ENTRY(debug_signal.Fetch_debug[0].inst,debug_signal.Fetch_debug[0].inst.r.rd,debug_signal.Fetch_debug[0].inst.r.rs1,debug_signal.Fetch_debug[0].inst.r.rs2,debug_signal.Fetch_debug[0].PC);
		// 	print_Fecth_ENTRY(debug_signal.Fetch_debug[1].inst,debug_signal.Fetch_debug[1].inst.r.rd,debug_signal.Fetch_debug[1].inst.r.rs1,debug_signal.Fetch_debug[1].inst.r.rs2,debug_signal.Fetch_debug[1].PC);
			
		// 	print_FU_NC();
		// 	print_FU_ENTRY(debug_signal.ALU_0_func_debug,debug_signal.ALU_0_dest_reg_i_debug,debug_signal.ALU_0_opa_debug,debug_signal.ALU_0_opb_debug,debug_signal.ALU_0_dest_reg_o_debug,debug_signal.ALU_0_result_o_debug,ALU_0_done_debug);
		// 	print_FU_ENTRY(debug_signal.ALU_1_func_debug,debug_signal.ALU_1_dest_reg_i_debug,debug_signal.ALU_1_opa_debug,debug_signal.ALU_1_opb_debug,debug_signal.ALU_1_dest_reg_o_debug,debug_signal.ALU_1_result_o_debug,ALU_1_done_debug);

		// 	print_FL_NC();
		// 	for(fl_cnt=0;fl_cnt<`FREELIST_SIZE;fl_cnt++)	begin
		// 		print_FL_ENTRY(debug_signal.FL_entries_debug[fl_cnt],debug_signal.FL_valid_debug[fl_cnt]);
		// 	end

		// 	print_PP_NC();
		// 	print_PP_ENTRY(debug_signal.dispatch_en_debug,debug_signal.ex_en_debug,debug_signal.complete_debug,debug_signal.retire_en_debug);

		// 	print_RETIRE_NC();
		// 	print_RETIRE_ENTRY(debug_signal.retire_wr_mem_debug[0],
		// 					debug_signal.retire_rd_mem_debug[0],
		//  					debug_signal.retire_cond_branch_debug[0],
		//  					debug_signal.retire_uncond_branch_debug[0],
		//  					debug_signal.retire_halt_debug[0]);
		//  	print_RETIRE_ENTRY(debug_signal.retire_wr_mem_debug[1],
		//  					debug_signal.retire_rd_mem_debug[1],
		//  					debug_signal.retire_cond_branch_debug[1],
		//  					debug_signal.retire_uncond_branch_debug[1],
		//  					debug_signal.retire_halt_debug[1]);
		// 	print_PR_NC();
		// 	for(fr_cnt=0;fr_cnt<`PREG_NUMBER;fr_cnt++) begin
		// 		print_PR_ENTRY(fr_cnt,debug_signal.value_RF[fr_cnt]);
		// 	end
		// `endif
	 	end  
     end

endmodule  // module testbench

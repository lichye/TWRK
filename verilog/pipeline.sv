`ifndef __PIPELINE_SV__
`define __PIPELINE_SV__

// `timescale 1ns/100ps

module pipeline (
	`ifdef DEBUG
	output DEBUG_SIGNAL debug_signal,
	`endif

	input                    clk,               // System clock
	input                    reset,             // System reset

// memory
	input logic  [3:0] mem2proc_response,
	input logic [63:0] mem2proc_data,
	input logic  [3:0] mem2proc_tag,
	
	output logic [1:0]  proc2mem_command,
	output logic [`XLEN-1:0] proc2mem_addr,
	output logic [63:0] proc2mem_data,



// Testbench
	output logic halt
);

/*----------------------------------Internal Signal Declaration----------------------------------*/
// Fetch
	logic             IF_take_branch_i;
	logic [`XLEN-1:0] IF_branch_target_pc_i;
	logic [1:0]       IF_PC_increment_i;
	logic [63:0]      IF_Imem2proc_data;
	logic             IF_Icache_valid_i;

	logic             IF_read_valid_o;
	logic [`XLEN-1:0] IF_proc2Imem_addr;

	STRUCTURE_FULL IF_fetch_buffer_empty_o;
	INST_PC [1:0]     IF_inst_PC_o;

//Branch Target Buffer
    logic [1:0] [`XLEN-1:0] BTB_fetch_pc_i;
    logic [1:0]             BTB_branch_recover_i;
    logic [`XLEN-1:0]       BTB_recover_addr_i;
    logic [`XLEN-1:0]       BTB_recover_branch_pc_i;

    logic [1:0]             BTB_fetch_branch_en_i;
	logic [1:0] [`XLEN-1:0] BTB_retire_PC_i;

    logic [1:0] [`XLEN-1:0] BTB_predict_addr_o;
    logic [1:0]             BTB_predict_en_o;
	logic [1:0] BTB_branch_retire_i;

// Decoder
	INST_PC       D0_inst_PC_i;
	DECODE_PACKET D0_decode_packet_o;
	INST_PC       D1_inst_PC_i;
	DECODE_PACKET D1_decode_packet_o;
	
// Reorder Buffer

	logic [1:0]                               ROB_dispatch_en_i;
	logic [1:0][$clog2(`PREG_NUMBER)-1:0]     ROB_preg_tag_old_i;
	logic [1:0] [$clog2(`ARCHREG_NUMBER)-1:0] ROB_arch_old_i;
	logic [1:0][$clog2(`PREG_NUMBER)-1:0]     ROB_freeReg_i;
	logic [1:0][$clog2(`PREG_NUMBER)-1:0]     ROB_CDB_i;
	logic [1:0]                               ROB_CDB_en_i;
	logic [1:0]                               ROB_branch_recover_i;
	ROB_RETIRE_PACKET [1:0]                   ROB_retire_packet_i;
	
	logic [1:0] [$clog2(`ARCHREG_NUMBER)-1: 0] ROB_arch_old_o;
	logic [1:0][$clog2(`PREG_NUMBER)-1:0]      ROB_T_o;
	logic [1:0][$clog2(`PREG_NUMBER)-1:0]      ROB_T_old_o;
	logic [1:0]                                ROB_retire_en_o;
	STRUCTURE_FULL                             ROB_full_o;
	ROB_RETIRE_PACKET [1:0]                    ROB_retire_packet_o;

// Map Table

	logic [`TABLE_READ-1:0][$clog2(`ARCHREG_NUMBER)-1:0]     MT_arch_reg_i;
	logic [`TABLE_WRITE-1:0][$clog2(`ARCHREG_NUMBER)-1:0]    MT_arch_reg_dest_i;
	logic [`TABLE_WRITE-1:0][$clog2(`PREG_NUMBER)-1: 0]      MT_arch_reg_dest_new_tag_i;
	logic [`TABLE_WRITE-1:0]                                 MT_new_tag_write_en_i;
	DEST_REG_SEL [1:0]                                       MT_dest_reg_sel_i;

	logic [`CDB_SIZE-1:0][$clog2(`PREG_NUMBER)-1:0]          MT_CDB_i;
	logic [`CDB_SIZE-1:0]                                    MT_CDB_en_i;
	logic                                                    MT_branch_recover_i;
	logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] MT_arch_table_recover_i;

	logic [`TABLE_READ-1:0][$clog2(`PREG_NUMBER)-1: 0]       MT_preg_tag_o;
	logic [`TABLE_READ-1:0]                                  MT_preg_ready_o;
	logic [`TABLE_WRITE-1:0][$clog2(`PREG_NUMBER)-1: 0]      MT_preg_tag_old_o;

// Architecture Table
	logic [`TABLE_WRITE-1:0][$clog2(`ARCHREG_NUMBER)-1:0]      AT_retire_arch_reg_i;
	logic [`TABLE_WRITE-1:0]                                   AT_retire_en_i;
	logic [`TABLE_WRITE-1:0][$clog2(`PREG_NUMBER)-1: 0]        AT_new_tag_i;
	logic [1:0]                                                AT_branch_recover_i;
	DEST_REG_SEL [1:0]                                       AT_dest_reg_sel_i;

	logic [`TABLE_WRITE-1:0] [$clog2(`PREG_NUMBER)-1: 0]       AT_tag_o;
	logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] AT_arch_table_recover_o;

// Freelist

	logic [1:0]                                           FL_dispatch_en_i;
	logic [1:0]                                           FL_branch_recover_in;
	logic [`FREELIST_SIZE-1:0] [$clog2(`PREG_NUMBER)-1:0] FL_checkpoint_freelist;
	logic [1:0][$clog2(`PREG_NUMBER)-1:0]                 FL_retire_tag_in;
	logic [1:0]                                           FL_retire_en_in;

	logic [1:0][$clog2(`PREG_NUMBER)-1:0]                 FL_free_reg_out;
	logic [1:0]                                           FL_free_reg_en_o;
	STRUCTURE_FULL                                        FL_free_list_empty;
	logic [1:0]                                           FL_dispatch_branch_i;
	logic [1:0]                                           FL_retire_branch_i;


// Reservation Station
 	logic [1:0]                                                     RS_dispatch_en_i;
    logic [`SUPERSCALE_WIDTH - 1 :0] [$clog2(`PREG_NUMBER) - 1 : 0] RS_dest_tag_i;     // Dispatch: from Freelist
    logic [`SUPERSCALE_WIDTH - 1 :0] [$clog2(`PREG_NUMBER) - 1 : 0] RS_source_tag_1_i; // Dispatch: from Maptable
    logic [`SUPERSCALE_WIDTH - 1 : 0]                               RS_ready_1_i;      // Dispatch: from Maptable
    logic [`SUPERSCALE_WIDTH - 1 :0] [$clog2(`PREG_NUMBER) - 1 : 0] RS_source_tag_2_i; // Dispatch: from Maptable
    logic [`SUPERSCALE_WIDTH - 1 : 0]                               RS_ready_2_i;     // Dispatch: from Maptbale
    DECODE_NOREG_PACKET [`SUPERSCALE_WIDTH - 1 :0]                        RS_decode_noreg_packet;

    logic [1:0]                                                     RS_branch_recover_i; //enable for branch
    logic [`SUPERSCALE_WIDTH - 1 : 0] [$clog2(`PREG_NUMBER)-1 : 0]  RS_CDB_i;//WB: from CDB
    logic [1:0]                                                     RS_CDB_en_i;

    logic [`FU_NUMBER-1:0]                                          RS_fu_ready_i; //issue: from ALU

    STRUCTURE_FULL                                                     RS_full_o;  // To control
    logic [`RS_LENGTH-1 : 0]                                        RS_execute_en_o; // Issue: To FU
    RS_FU_PACKET [1 : 0]                                            RS_FU_packet_o;   
    logic [`FU_NUMBER-1:0]                                          RS_FU_select_en_o;
	logic [`FU_NUMBER-1:0]                                          RS_FU_select_RS_port_o;


// Function Unit
	// ALU_0
	logic [`XLEN-1:0]                ALU_0_opa;
	logic [`XLEN-1:0]                ALU_0_opb;
	ALU_FUNC                         ALU_0_func;
	logic [$clog2(`PREG_NUMBER)-1:0] ALU_0_dest_reg_i;
	logic                            ALU_0_execute_en_i;
	logic                            ALU_0_complete_en_i;

	logic 			                 ALU_0_ready_o;
	logic [$clog2(`PREG_NUMBER)-1:0] ALU_0_dest_reg_o;
	logic                            ALU_0_regfile_wr_en_o;
	logic [`XLEN-1:0]                ALU_0_result_o;
	logic                            ALU_0_done_o;
	DEST_REG_SEL	                 ALU_0_dest_reg_sel_i;

	// ALU_1
	logic [`XLEN-1:0]                ALU_1_opa;
	logic [`XLEN-1:0]                ALU_1_opb;
	ALU_FUNC                         ALU_1_func;
	logic [$clog2(`PREG_NUMBER)-1:0] ALU_1_dest_reg_i;
	logic                            ALU_1_execute_en_i;
	logic                            ALU_1_complete_en_i;
	DEST_REG_SEL                     ALU_1_dest_reg_sel_i;

	logic                            ALU_1_ready_o;
	logic [$clog2(`PREG_NUMBER)-1:0] ALU_1_dest_reg_o;
	logic                            ALU_1_regfile_wr_en_o;
	logic [`XLEN-1:0]                ALU_1_result_o;
	logic                            ALU_1_done_o;
	logic [1:0]                      ALU_0_branch_recover_i;
	logic [1:0]                      ALU_1_branch_recover_i;

	//BLU
	logic [`XLEN-1:0]                BLU_opa;
	logic [`XLEN-1:0]                BLU_opb;
	logic [`XLEN-1:0]                BLU_rs1;
	logic [`XLEN-1:0]                BLU_rs2;
	logic [1:0]                      BLU_prediction;
	logic [1:0] [`XLEN-1:0]          BLU_prediction_address;
	logic [1:0] [$clog2(`PREG_NUMBER)-1:0] BLU_dispatch_reg_i;
	logic [1:0]                            BLU_dispatch_branch_i;
	logic [$clog2(`PREG_NUMBER)-1:0] BLU_dest_reg_i;
	DEST_REG_SEL                     BLU_dest_reg_sel_i;
	logic                            BLU_regfile_wr_en_o;
	logic [2:0]                      BLU_func_br;
	logic [`XLEN-1:0]                BLU_NPC_i;
	logic [`XLEN-1:0]                BLU_PC_i;
	logic [6:0]                      BLU_inst_opcode;
	logic                            BLU_execute_en_i;
	logic [1:0]                      BLU_branch_recover_i;

	logic                            BLU_complete_en_i;

	logic [1:0]                            BLU_branch_retire_en_i;
	logic [1:0] [$clog2(`PREG_NUMBER)-1:0] BLU_branch_retire_dest_reg_i;

	logic                                  BLU_ready_o;

	logic [`XLEN-1:0]                BLU_result_o; // complete
	logic [$clog2(`PREG_NUMBER)-1:0] BLU_dest_reg_o;
	DEST_REG_SEL                     BLU_dest_reg_sel_o;

	BRANCH_RECOVER_OUT [1:0]         BLU_branch_recover_packet_o;

	// output logic br_cond_o,
    logic                            BLU_done_o;


// Physical Register File
	logic [$clog2(`PREG_NUMBER)-1:0]  RF_rda_idx;
	logic [$clog2(`PREG_NUMBER)-1:0]  RF_rdb_idx;
	logic [$clog2(`PREG_NUMBER)-1:0]  RF_rdc_idx;
	logic [$clog2(`PREG_NUMBER)-1:0]  RF_rdd_idx;
	logic [$clog2(`PREG_NUMBER)-1:0]  RF_wra_idx;
	logic [$clog2(`PREG_NUMBER)-1:0]  RF_wrb_idx;
	logic [`XLEN-1:0]                 RF_wra_data;
	logic [`XLEN-1:0]                 RF_wrb_data;
	logic                             RF_wra_en;
	logic                             RF_wrb_en;

	logic [`XLEN-1:0]                 RF_rda_out;
	logic [`XLEN-1:0]                 RF_rdb_out;
	logic [`XLEN-1:0]                 RF_rdc_out;
	logic [`XLEN-1:0]                 RF_rdd_out;

//CDB
    logic [`FU_NUMBER-1: 0]                             CDB_FU_complete_i;
    logic [`FU_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] CDB_completed_tag_i;

	logic [`FU_NUMBER-1: 0]                                   CDB_FU_complete_en_o;
    logic [`SUPERSCALE_WIDTH-1:0]                             CDB_en_o;
    logic [`SUPERSCALE_WIDTH-1:0] [$clog2(`PREG_NUMBER)-1: 0] CDB_o;

// icache
    logic [3:0]       icache_Imem2proc_response;
    logic [63:0]      icache_Imem2proc_data;
    logic [3:0]       icache_Imem2proc_tag;

	logic [1:0]       icache_proc2Imem_command;
    logic [`XLEN-1:0] icache_proc2Imem_addr;
	logic             icache_proc2Imem_request;

    logic [`XLEN-1:0] icache_proc2Icache_addr;
    logic             icache_read_valid;

    logic             icache_Icache_valid_out;
    logic [63:0]      icache_Icache_data_out;


// dcache
    logic [3:0]       dcache_Dmem2proc_response;
    logic [63:0]      dcache_Dmem2proc_data;
    logic [3:0]       dcache_Dmem2proc_tag;

	logic [1:0]       dcache_proc2Dmem_command;
    logic [`XLEN-1:0] dcache_proc2Dmem_addr;
    logic [63:0]      dcache_proc2Dmem_data;
    logic             dcache_proc2Dmem_request;

    logic [`XLEN-1:0] dcache_proc2Dcache_addr;
    logic [`XLEN-1:0] dcache_proc2Dcache_data;
    logic [1:0]       dcache_proc2Dcache_size;
    logic [1:0]       dcache_proc2Dcache_rd_wr;
    logic [1:0]       dcache_proc2Dcache_command;

    logic             dcache_Dcache_valid_out;
	logic [31:0]      dcache_Dcache_data_out;
		

// arbiter
	logic         arbiter_i_pmem_request;
    logic [1:0]   arbiter_i_pmem_command;
    logic [31:0]  arbiter_i_pmem_address;

    logic [3:0]   arbiter_i_pmem_tag;
    logic [3:0]   arbiter_i_pmem_response;
    logic [63:0]  arbiter_i_pmem_rdata;

	logic         arbiter_d_pmem_request;
    logic [1:0]   arbiter_d_pmem_command;
    logic [31:0]  arbiter_d_pmem_address;
    logic [63:0]  arbiter_d_pmem_wdata;

    logic [3:0]   arbiter_d_pmem_tag;
    logic [3:0]   arbiter_d_pmem_response;
    logic [63:0]  arbiter_d_pmem_rdata;

    logic [63:0]  arbiter_mem2proc_rdata;
    logic [3:0]   arbiter_mem2proc_response;
    logic [3:0]   arbiter_mem2proc_tag;

    logic [1:0]   arbiter_proc2mem_command;
    logic [31:0]  arbiter_proc2mem_address;
    logic [63:0]  arbiter_proc2mem_wdata;

//LSQ
    logic [1:0]                      LSQ_dispatch_mem_en_i;
	logic [1:0] [2:0]                LSQ_mem_funct;

    logic                            LSQ_execute_en_i;
    logic [1:0] [6:0]                LSQ_opcode_dispatch_i;
	logic [1:0] [$clog2(`PREG_NUMBER)-1:0] LSQ_dispatch_dest_reg_i;
    logic [`XLEN-1:0]                LSQ_opa;//EX from register file
	logic [`XLEN-1:0]                LSQ_opb;//EX from imm
    logic [`XLEN-1:0]                LSQ_rs2_value_i;//Ex from register fi
	logic [$clog2(`PREG_NUMBER)-1:0] LSQ_dest_reg_i;

    logic [1:0]                      LSQ_retire_mem_en_i;
    logic [1:0]                      LSQ_branch_recover_i;

	logic                            LSQ_complete_en_i;


    STRUCTURE_FULL                   LSQ_lsq_full;

	logic                            LSQ_regfile_wr_en_o;

	logic                            LSQ_mem_valid_i;
    logic [31:0]                LSQ_mem_data_i;
    logic [3:0]                      LSQ_mem_response_i;
    logic [3:0]                      LSQ_mem_tag_i;

    logic [`XLEN-1:0]                LSQ_mem_address_o;
    logic [1:0]                      LSQ_mem_command_o;
    logic [31:0]                LSQ_mem_wdata_o;
    MEM_SIZE                     LSQ_mem_size_o;
	logic [1:0]                      LSQ_mem_rd_wr_o;

    logic                            LSQ_ready_o;

    logic [$clog2(`PREG_NUMBER)-1:0] LSQ_dest_reg_o;
	logic [`XLEN-1:0]                LSQ_result_o;
    logic                            LSQ_done_o;

	//debug
	logic [1:0] [31:0] LSQ_debug_store_data;
	logic [1:0] [31:0] LSQ_debug_store_address;
	logic [$clog2(`LSQ_SIZE)-1:0] LSQ_debug_next_head;
 	logic [$clog2(`LSQ_SIZE)-1:0] LSQ_debug_next_retire_ptr;
	LSQ_ENTRY [`LSQ_SIZE-1:0] LSQ_debug_lsq_entry;

	//mult

	logic [`XLEN-1:0] MULT_opa;
	logic [`XLEN-1:0] MULT_opb;
	ALU_FUNC MULT_func;
	logic [$clog2(`PREG_NUMBER)-1:0] MULT_dest_reg_i;

	logic MULT_execute_en_i;
	logic MULT_complete_en_i;
	logic MULT_branch_recover_i;
	
	logic MULT_done;
	logic MULT_ready_o;
	logic [$clog2(`PREG_NUMBER)-1:0] MULT_dest_reg_o;
	logic [`XLEN-1:0] MULT_result_o;
	logic MULT_regfile_wr_en_o;
	logic MULT_done_o;

// Control


	fetch fetch(
		.clk                (clk),
		.reset              (reset),

		.take_branch_i      (IF_take_branch_i),
		.branch_target_pc_i (IF_branch_target_pc_i),
		.PC_increment_i     (IF_PC_increment_i),
		.Imem2proc_data     (IF_Imem2proc_data),
		.Icache_valid_i     (IF_Icache_valid_i),

		.read_valid_o         (IF_read_valid_o),
		.fetch_buffer_empty_o (IF_fetch_buffer_empty_o),

		.proc2Imem_addr     (IF_proc2Imem_addr),
		.inst_PC_o          (IF_inst_PC_o)
	);

     btb btb(
        .clk(clk),
        .reset(reset),

		.fetch_pc_i(BTB_fetch_pc_i),
		.branch_recover_i(BTB_branch_recover_i),
		.recover_addr_i(BTB_recover_addr_i),
		.recover_branch_pc_i(BTB_recover_branch_pc_i),
		.fetch_branch_en_i(BTB_fetch_branch_en_i),
		.branch_retire_i(BTB_branch_retire_i),
		.retire_PC_i(BTB_retire_PC_i),

		.predict_addr_o(BTB_predict_addr_o),
		.predict_en_o(BTB_predict_en_o)
     );

	decoder decoder_0(
		.inst_PC_i       (D0_inst_PC_i),
		.decode_packet_o (D0_decode_packet_o)    
	);


	decoder decoder_1(
		.inst_PC_i       (D1_inst_PC_i),
		.decode_packet_o (D1_decode_packet_o)

	);
	
// Reorder Buffer
	rob rob (
		`ifdef DEBUG
		.head_debug            (debug_signal.ROB_head_debug),
		.tail_debug            (debug_signal.ROB_tail_debug),
		.next_head_debug       (debug_signal.ROB_next_head_debug),
		.entries_debug         (debug_signal.ROB_entries_debug),
		.completed_debug	   (debug_signal.ROB_completed_debug),
		`endif

		.clk                   (clk),
		.reset                 (reset),

		.dispatch_en_i         (ROB_dispatch_en_i),         // D, control signal of dispatch
		.preg_tag_old_i        (ROB_preg_tag_old_i),        // D, old tag of dest physical register, from Map Table
		.arch_old_i            (ROB_arch_old_i),
		.freeReg_i             (ROB_freeReg_i),             // D, renamed tag, from Freelist
		.CDB_i                 (ROB_CDB_i),                 // C, from CDB
		.CDB_en_i              (ROB_CDB_en_i),              // C, from CDB
		.branch_recover_i      (ROB_branch_recover_i), // C
		.retire_packet_i       (ROB_retire_packet_i),

		.T_o                   (ROB_T_o),                   // R, tag updated in tail, to Arch Table       
		.T_old_o               (ROB_T_old_o),               // R, retired tag, to Free List
		.arch_old_o            (ROB_arch_old_o),
		.retire_en_o           (ROB_retire_en_o),           // R, to Arch Table and FL
		.ROB_full_o            (ROB_full_o),
		.retire_packet_o               (ROB_retire_packet_o)
	);
	
// Map Table
	map_table map_table(
		`ifdef DEBUG
		.map_table_entry_Debug   (debug_signal.MT_map_table_entry_Debug),
		.map_table_ready_Debug   (debug_signal.MT_map_table_ready_Debug),
		`endif

		.clk                     (clk),
		.reset                   (reset),

		.arch_reg_i              (MT_arch_reg_i),              // D, physical register source 1, from ROB
		.arch_reg_dest_i         (MT_arch_reg_dest_i),         // D, physical register destination, from ROB
		.arch_reg_dest_new_tag_i (MT_arch_reg_dest_new_tag_i), // D, new allocated tag, from Free List
		.new_tag_write_en_i      (MT_new_tag_write_en_i),      // D, enable writing new tag, from Free List
		.dest_reg_sel_i          (MT_dest_reg_sel_i),

		.CDB_i                   (MT_CDB_i),                 // C, CDB broadcsat in Complete, from CDB
		.CDB_en_i                (MT_CDB_en_i),              // C, CDB broadcsat in Complete, from CDB
		.branch_recover_i        (MT_branch_recover_i),      // C, from branch result
		.arch_table_recover_i    (MT_arch_table_recover_i),  // C, from Arch Table

		.preg_tag_o              (MT_preg_tag_o),            // D, tag of register source 1, to RS
		.preg_tag_old_o          (MT_preg_tag_old_o),        // D, old tag of output register to ROB
		.preg_ready_o            (MT_preg_ready_o)           // D, ready bit of register source 1, to RS
	);
	
// Architecture Table
	arch_table arch_table(
		`ifdef DEBUG
		.arch_table_entry_debug(debug_signal.arch_table_entry_debug),
		`endif

		.clk                  (clk),
		.reset                (reset),
		
		.retire_arch_reg_i    (AT_retire_arch_reg_i),   // R, retired physical reg index, from ROB
		.retire_en_i          (AT_retire_en_i),         // R, retire enable, from ROB
		.new_tag_i            (AT_new_tag_i),           // R, tag of retired physical reg, from ROB
		.branch_recover_i     (AT_branch_recover_i),
		.dest_reg_sel_i       (AT_dest_reg_sel_i),

		.arch_table_recover_o (AT_arch_table_recover_o) // C, content of the whole Arch Table, to Map Table
	);

// Freelist
	freelist freelist(
		`ifdef DEBUG
		.head_debug          (debug_signal.FL_head_debug),
		.tail_debug          (debug_signal.FL_tail_debug),
		.tail_plus_one_debug (debug_signal.FL_tail_plus_one_debug),
		.entries_debug		 (debug_signal.FL_entries_debug),
		.valid_debug		 (debug_signal.FL_valid_debug),
		`endif

		.clk                 (clk),
		.reset               (reset),

		.dispatch_en_in      (FL_dispatch_en_i),      // D, request new physical reg, from control
		.branch_recover_in   (FL_branch_recover_in),   // C, mispredcited branch, from branch
		.dispatch_branch_i	(FL_dispatch_branch_i),
		                 
		.retire_tag_in       (FL_retire_tag_in),       // R, retired physical reg, from ROB
		.retire_en_in        (FL_retire_en_in),        // R, fron control
		.retire_branch_i     (FL_retire_branch_i),

		.free_reg_out        (FL_free_reg_out),        // D, allocated physical reg, to ROB, MT, RS
		.free_reg_en_o       (FL_free_reg_en_o),       // D
		.free_list_empty     (FL_free_list_empty)      // D, to control
	);

// Reservation Station
	rs rs(
		.entries_debug			(debug_signal.RS_entries_debug),
		.clk                	(clk),
		.reset               	(reset),
		.dispatch_en_i		    (RS_dispatch_en_i),
		.dest_tag_i				(RS_dest_tag_i),
		.source_tag_1_i			(RS_source_tag_1_i),
		.ready_1_i				(RS_ready_1_i),
		.source_tag_2_i			(RS_source_tag_2_i),
		.ready_2_i				(RS_ready_2_i),
		.RS_decode_noreg_packet (RS_decode_noreg_packet),

		.branch_recover_i		(RS_branch_recover_i),
		.CDB_i					(RS_CDB_i),
		.CDB_en_i			    (RS_CDB_en_i),

		.fu_ready_i				(RS_fu_ready_i),

		.RS_full_o				(RS_full_o),
		.execute_en_o		    (RS_execute_en_o),
		.FU_packet_o		    (RS_FU_packet_o),
		.FU_select_en_o		    (RS_FU_select_en_o),
		.FU_select_RS_port_o    (RS_FU_select_RS_port_o)
		);
// Function Unit ALU
	alu alu_0(
		.clk          (clk),
		.reset        (reset),

		.opa              (ALU_0_opa),
		.opb              (ALU_0_opb),
		.func             (ALU_0_func),
		.dest_reg_i	      (ALU_0_dest_reg_i),
		.execute_en_i     (ALU_0_execute_en_i),
		.complete_en_i    (ALU_0_complete_en_i),
		.dest_reg_sel_i   (ALU_0_dest_reg_sel_i),
		.branch_recover_i (ALU_0_branch_recover_i),

		.ready_o          (ALU_0_ready_o),
		.dest_reg_o	      (ALU_0_dest_reg_o),
		.result_o         (ALU_0_result_o),
		.regfile_wr_en_o  (ALU_0_regfile_wr_en_o),
		.done_o           (ALU_0_done_o)
	);
	
	alu alu_1(
		.clk          (clk),
		.reset        (reset),

		.opa              (ALU_1_opa),
		.opb              (ALU_1_opb),
		.func             (ALU_1_func),
		.dest_reg_i	      (ALU_1_dest_reg_i),
		.execute_en_i     (ALU_1_execute_en_i),
		.complete_en_i    (ALU_1_complete_en_i),
		.dest_reg_sel_i   (ALU_1_dest_reg_sel_i),
		.branch_recover_i (ALU_1_branch_recover_i),
		
		.ready_o         (ALU_1_ready_o),
		.dest_reg_o	     (ALU_1_dest_reg_o),
		.result_o        (ALU_1_result_o),
		.regfile_wr_en_o (ALU_1_regfile_wr_en_o),
		.done_o          (ALU_1_done_o)
	);

// BLU
	blu blu(
		.clk				(clk),
		.reset				(reset),

		.opa				(BLU_opa),
		.opb				(BLU_opb),
		.rs1                (BLU_rs1),
		.rs2				(BLU_rs2),
		.prediction_address (BLU_prediction_address),
		.prediction         (BLU_prediction),
		.dispatch_reg_i     (BLU_dispatch_reg_i),
		.dispatch_branch_i  (BLU_dispatch_branch_i),
		.dest_reg_i			(BLU_dest_reg_i),
		.dest_reg_sel_i		(BLU_dest_reg_sel_i),
		.func_br			(BLU_func_br),
		.NPC_i				(BLU_NPC_i),
		.PC_i				(BLU_PC_i),
		.inst_opcode		(BLU_inst_opcode),
		.execute_en_i		(BLU_execute_en_i),
		.branch_recover_i   (BLU_branch_recover_i),

		.complete_en_i		(BLU_complete_en_i),

		.branch_retire_en_i	      (BLU_branch_retire_en_i),
		.branch_retire_dest_reg_i (BLU_branch_retire_dest_reg_i),

		.ready_o                  (BLU_ready_o),

		.result_o			(BLU_result_o), // complet(BLU_result_o, // complet),
		.dest_reg_o			(BLU_dest_reg_o),
		.regfile_wr_en_o    (BLU_regfile_wr_en_o),

		.branch_recover_packet_o (BLU_branch_recover_packet_o),
		.done_o				     (BLU_done_o)
	);

	//LSQ
	lsq lsq(
		.reset(reset),
		.clk(clk),

		.dispatch_mem_en_i  (LSQ_dispatch_mem_en_i),
		.mem_funct_i        (LSQ_mem_funct),

		.execute_en_i       (LSQ_execute_en_i),
		.opcode_dispatch_i  (LSQ_opcode_dispatch_i),
		.dispatch_dest_reg_i(LSQ_dispatch_dest_reg_i),
		.opa              	(LSQ_opa),
		.opb              	(LSQ_opb),
		.rs2_value_i        (LSQ_rs2_value_i),
		.dest_reg_i         (LSQ_dest_reg_i),


		.retire_mem_en_i    (LSQ_retire_mem_en_i),
		.branch_recover_i   (LSQ_branch_recover_i),

		.complete_en_i      (LSQ_complete_en_i),

		.halt               (halt),

		.lsq_full           (LSQ_lsq_full),
		.regfile_wr_en_o    (LSQ_regfile_wr_en_o),

		.ready_o            (LSQ_ready_o),

		.dest_reg_o         (LSQ_dest_reg_o),
		.result_o           (LSQ_result_o),
		.done_o             (LSQ_done_o),

		.mem_valid_i        (LSQ_mem_valid_i),
		.mem_data_i         (LSQ_mem_data_i),
		.mem_response_i     (LSQ_mem_response_i),
		.mem_tag_i          (LSQ_mem_tag_i),

		.mem_address_o      (LSQ_mem_address_o),
		.mem_command_o      (LSQ_mem_command_o),
		.mem_wdata_o        (LSQ_mem_wdata_o),
		.mem_size_o         (LSQ_mem_size_o),
		.mem_rd_wr_o        (LSQ_mem_rd_wr_o),

		.debug_store_data   (LSQ_debug_store_data),
		.debug_store_address(LSQ_debug_store_address),
		`ifdef DEBUG
		.debug_next_head         (debug_signal.LSQ_debug_next_head),
		.debug_next_retire_ptr   (debug_signal.LSQ_debug_next_retire_ptr),
		.debug_lsq_entry		 (debug_signal.LSQ_debug_lsq_entry)	
		`endif
	);

	//mult

	mult mult(
		.clk(clk),
		.reset(reset),
		
		.opa(MULT_opa),
		.opb(MULT_opb),
		.func(MULT_func),
		.dest_reg_i(MULT_dest_reg_i),
		.execute_en_i(MULT_execute_en_i),
		.complete_en_i(MULT_complete_en_i),
		.branch_recover_i(MULT_branch_recover_i),
		
		.ready_o(MULT_ready_o),
		.dest_reg_o(MULT_dest_reg_o),
		.result_o(MULT_result_o),
		.regfile_wr_en_o(MULT_regfile_wr_en_o),
		.done_o(MULT_done_o)
	);


	regfile regfile(
		.clk      (clk),
		.reset    (reset),

		.value_RF (debug_signal.value_RF),

		.rda_idx  (RF_rda_idx),
		.rdb_idx  (RF_rdb_idx),
		.rdc_idx  (RF_rdc_idx),
		.rdd_idx  (RF_rdd_idx),
		.wra_idx  (RF_wra_idx),
		.wrb_idx  (RF_wrb_idx),
		.wra_data (RF_wra_data),
		.wrb_data (RF_wrb_data),
		.wra_en   (RF_wra_en),
		.wrb_en   (RF_wrb_en),

		.rda_out  (RF_rda_out),
		.rdb_out  (RF_rdb_out),
		.rdc_out  (RF_rdc_out),
		.rdd_out  (RF_rdd_out)
	);

// CDB
	CDB CDB(

		.clk(clk),
		.reset(reset),

		.FU_complete_i(CDB_FU_complete_i),
		.completed_tag_i(CDB_completed_tag_i),

		.FU_complete_en_o(CDB_FU_complete_en_o),
		.CDB_en_o(CDB_en_o),
		.CDB_o(CDB_o)
	);

	icache icache(
		.clk                (clk),
		.reset              (reset),

		.Imem2proc_response (icache_Imem2proc_response),
		.Imem2proc_data     (icache_Imem2proc_data),
		.Imem2proc_tag      (icache_Imem2proc_tag),
		.proc2Icache_addr   (icache_proc2Icache_addr),
		.read_valid         (icache_read_valid),
		.proc2Imem_request  (icache_proc2Imem_request),

		.Icache_valid_out   (icache_Icache_valid_out),
		.proc2Imem_command  (icache_proc2Imem_command),
		.proc2Imem_addr     (icache_proc2Imem_addr),
		.Icache_data_out    (icache_Icache_data_out)
	);

	dcache dcache(
		`ifdef DEBUG
		.data   (debug_signal.dcache_data),
		.tags   (debug_signal.dcache_tags),
		.valids (debug_signal.dcache_valids),
		.dirty  (debug_signal.dcache_dirty),
		`endif
		
		.clk                (clk),
		.reset              (reset),

		.proc2Dcache_addr    (dcache_proc2Dcache_addr),
		.proc2Dcache_data    (dcache_proc2Dcache_data),
		.proc2Dcache_size    (dcache_proc2Dcache_size),
		.proc2Dcache_rd_wr   (dcache_proc2Dcache_rd_wr),
		.proc2Dcache_command (dcache_proc2Dcache_command),

		.Dcache_valid_out    (dcache_Dcache_valid_out),
		.Dcache_data_out     (dcache_Dcache_data_out),

		.proc2Dmem_command   (dcache_proc2Dmem_command),
		.proc2Dmem_addr      (dcache_proc2Dmem_addr),
		.proc2Dmem_data      (dcache_proc2Dmem_data),
		.proc2Dmem_request   (dcache_proc2Dmem_request),

		.Dmem2proc_response  (dcache_Dmem2proc_response),
		.Dmem2proc_data      (dcache_Dmem2proc_data),
		.Dmem2proc_tag       (dcache_Dmem2proc_tag)
	);

	arbiter arbiter(
    .clk               (clk),
    .reset             (reset),
 
	.i_pmem_request    (arbiter_i_pmem_request),
    .i_pmem_command    (arbiter_i_pmem_command),
    .i_pmem_address    (arbiter_i_pmem_address),
    .i_pmem_tag        (arbiter_i_pmem_tag),
    .i_pmem_response   (arbiter_i_pmem_response),
    .i_pmem_rdata      (arbiter_i_pmem_rdata),

	.d_pmem_request    (arbiter_d_pmem_request),
    .d_pmem_command    (arbiter_d_pmem_command),
    .d_pmem_address    (arbiter_d_pmem_address),
    .d_pmem_wdata      (arbiter_d_pmem_wdata),
    .d_pmem_tag        (arbiter_d_pmem_tag),
    .d_pmem_response   (arbiter_d_pmem_response),
    .d_pmem_rdata      (arbiter_d_pmem_rdata),

    .mem2proc_rdata    (arbiter_mem2proc_rdata),
    .mem2proc_response (arbiter_mem2proc_response),
    .mem2proc_tag      (arbiter_mem2proc_tag),
    .proc2mem_command  (arbiter_proc2mem_command),
    .proc2mem_address  (arbiter_proc2mem_address),
    .proc2mem_wdata    (arbiter_proc2mem_wdata)
	);

	logic halt_before;

	// Pipeline internal
	// All control signal: [0] stands for presence and [1] stands for the number, except the branch recover
	logic [1:0] dispatch_en;
	logic [1:0] dispatch_branch_i;

	RS_FU_PACKET ALU_0_packet;
	RS_FU_PACKET ALU_1_packet;
	RS_FU_PACKET BLU_packet;
	RS_FU_PACKET LSQ_packet;
	RS_FU_PACKET MULT_packet;

	logic [1:0] retire_branch;
	logic [1:0] branch_recover; // [0] stands for if inst 0 recover and [1] stands for if inst 1 recover

	integer k;
	integer m;
	integer p;
	integer q;
	/*------------------------------------------------Control------------------------------------------------*/

	/*-----------------------------Memory Bus-----------------------------*/

	/*-----------------------------Fetch-----------------------------*/
	assign IF_take_branch_i      = branch_recover[0] || (BTB_predict_en_o[0] & dispatch_en[0]) || (BTB_predict_en_o[1] & dispatch_en[1]);
	assign BTB_branch_recover_i  = branch_recover;
	assign BTB_fetch_branch_en_i[0] = D0_decode_packet_o.decode_noreg_packet.cond_branch || D0_decode_packet_o.decode_noreg_packet.uncond_branch;
	assign BTB_fetch_branch_en_i[1] = D1_decode_packet_o.decode_noreg_packet.cond_branch || D1_decode_packet_o.decode_noreg_packet.uncond_branch;


	/*-----------------------------Dispatch-----------------------------*/

	// Structure hazard detection
	always_comb begin
		dispatch_en = 2'b00;
		if(ROB_full_o == FULL || RS_full_o == FULL || FL_free_list_empty == FULL || IF_fetch_buffer_empty_o == FULL) begin
			dispatch_en = 2'b00;
		end
		else if(ROB_full_o == ONE_LEFT || RS_full_o == ONE_LEFT || FL_free_list_empty == ONE_LEFT || IF_fetch_buffer_empty_o == ONE_LEFT) begin
			dispatch_en = 2'b01;
		end
		else begin
			if(BTB_predict_en_o[0]) begin
				dispatch_en = 2'b01;
			end else begin
				dispatch_en = 2'b11;
			end
		end
		IF_PC_increment_i = dispatch_en;
	end

	// dispatch control
	assign ROB_dispatch_en_i = dispatch_en;
	assign FL_dispatch_en_i = dispatch_en;
	assign RS_dispatch_en_i = dispatch_en; 
	assign MT_new_tag_write_en_i = dispatch_en;

	//lsq dispatch 
	assign LSQ_dispatch_mem_en_i[0] = dispatch_en[0] && (D0_decode_packet_o.decode_noreg_packet.wr_mem || D0_decode_packet_o.decode_noreg_packet.rd_mem);
	assign LSQ_dispatch_mem_en_i[1] = dispatch_en[1] && (D1_decode_packet_o.decode_noreg_packet.wr_mem || D1_decode_packet_o.decode_noreg_packet.rd_mem);

	// When a inst is dispatched, check if it is a branch inst (for BLU buffer); 0 stands for if inst 0 is branch, 1 stands for if inst 1 is branch 
	assign dispatch_branch_i[0] = dispatch_en[0] & (D0_decode_packet_o.decode_noreg_packet.cond_branch || D0_decode_packet_o.decode_noreg_packet.uncond_branch);
	assign dispatch_branch_i[1] = dispatch_en == 2'b11 & (D1_decode_packet_o.decode_noreg_packet.cond_branch || D1_decode_packet_o.decode_noreg_packet.uncond_branch);
	
	assign FL_dispatch_branch_i = dispatch_branch_i;
	assign BLU_dispatch_branch_i = dispatch_branch_i;

	`ifdef VDEBUG
	assign debug_signal.dispatch_en_debug = dispatch_en[0]|dispatch_en[1];
	`endif
	/*-----------------------------Issue-----------------------------*/
	// FU to RS - fu ready, hardcoded FU position
	assign RS_fu_ready_i = {MULT_ready_o, LSQ_ready_o, BLU_ready_o, ALU_1_ready_o, ALU_0_ready_o};
	// RS to FU - FU enable
	assign ALU_0_execute_en_i = RS_FU_select_en_o[0];
	assign ALU_1_execute_en_i = RS_FU_select_en_o[1];
	assign BLU_execute_en_i =  RS_FU_select_en_o[2];
	assign LSQ_execute_en_i = RS_FU_select_en_o[3];
	assign MULT_execute_en_i = RS_FU_select_en_o[4];

	 `ifdef VDEBUG
	 assign ex_en = RS_FU_select_en_o[0] | RS_FU_select_en_o[1];
	 `endif

	/*-----------------------------Complete-----------------------------*/
	// FU to CDB, hardcoded FU position
	assign CDB_FU_complete_i = {MULT_done_o, LSQ_done_o, BLU_done_o, ALU_1_done_o, ALU_0_done_o};
	// CDB enable
	assign MT_CDB_en_i = CDB_en_o;
	assign ROB_CDB_en_i = CDB_en_o;
	assign RS_CDB_en_i = CDB_en_o;

	`ifdef VDEBUG
	 assign completed_debug = CDB_en_o[0] | CDB_en_o[1];
	`endif

	// CDB to FU, complete received by CDB, hardcoded FU position
	assign ALU_0_complete_en_i = CDB_FU_complete_en_o[0];
	assign ALU_1_complete_en_i = CDB_FU_complete_en_o[1];
	assign BLU_complete_en_i = CDB_FU_complete_en_o[2];
	assign LSQ_complete_en_i = CDB_FU_complete_en_o[3];
	assign MULT_complete_en_i = CDB_FU_complete_en_o[4];

	// Completed FU
	always_comb begin
		RF_wra_en = 0;
		RF_wrb_en = 0;
		RF_wra_idx = 0;
		RF_wrb_idx = 0;
		RF_wra_data = 0;
		RF_wrb_data = 0;
		k = 0;
		m = 0;
		for(k = 0; k < `FU_NUMBER && (m < 2); k++) begin // find two completed FU
			if(CDB_FU_complete_en_o[k]) begin
				case(k)
					4: begin
						if(m == 0) begin
							RF_wra_en = MULT_regfile_wr_en_o;
							RF_wra_idx = CDB_completed_tag_i[4];
							RF_wra_data = MULT_result_o;
						end
						else begin
							RF_wrb_en = MULT_regfile_wr_en_o;
							RF_wrb_idx = CDB_completed_tag_i[4];
							RF_wrb_data = MULT_result_o;
						end
					end

					3: begin
						if(m==0) begin
							RF_wra_en = LSQ_regfile_wr_en_o;
							RF_wra_idx = CDB_completed_tag_i[3];
							RF_wra_data = LSQ_result_o;	
						end
						else begin
							RF_wrb_en = LSQ_regfile_wr_en_o;
							RF_wrb_idx = CDB_completed_tag_i[3];
							RF_wrb_data = LSQ_result_o;	
						end
					end

					2: begin                             // which FU is enabled
						if(m == 0) begin                 // the enabled FU should be connected to first pair or second
							RF_wra_en = BLU_regfile_wr_en_o;
							RF_wra_idx = CDB_completed_tag_i[2];
							RF_wra_data = BLU_result_o;
						end
						else begin
							RF_wrb_en = BLU_regfile_wr_en_o;
							RF_wrb_idx = CDB_completed_tag_i[2];
							RF_wrb_data = BLU_result_o;
						end
					end

					1: begin
						if(m == 0) begin
							RF_wra_en = ALU_1_regfile_wr_en_o;
							RF_wra_idx = CDB_completed_tag_i[1];
							RF_wra_data = ALU_1_result_o;
						end
						else begin
							RF_wrb_en = ALU_1_regfile_wr_en_o;
							RF_wrb_idx = CDB_completed_tag_i[1];
							RF_wrb_data = ALU_1_result_o;
						end
					end

					0: begin
						if(m == 0) begin
							RF_wra_en = ALU_0_regfile_wr_en_o;
							RF_wra_idx = CDB_completed_tag_i[0];
							RF_wra_data = ALU_0_result_o;
						end
						else begin
							RF_wrb_en = ALU_0_regfile_wr_en_o;
							RF_wrb_idx = CDB_completed_tag_i[0];
							RF_wrb_data = ALU_0_result_o;
						end
					end

					default: begin
						RF_wra_en = 0;
						RF_wrb_en = 0;
						RF_wra_idx = 32'bx;
						RF_wrb_idx = 32'bx;
					end

				endcase
				m = m + 1;
			end
		end
	end

	`ifdef VDEBUG
	assign debug_signal.ALU_0_dest_reg_o_debug = ALU_0_dest_reg_o;
	assign debug_signal.ALU_1_dest_reg_o_debug = ALU_1_dest_reg_o;
	assign debug_signal.ALU_0_result_o_debug = ALU_0_result_o;
	assign debug_signal.ALU_1_result_o_debug = ALU_1_result_o;
	assign debug_signal.ALU_0_done_debug = ALU_0_done_o;
	assign debug_signal.ALU_1_done_debug = ALU_1_done_o;
	`endif

	logic [1:0] freelist_retire_branch;
	logic [1:0] blu_retire_branch;
	/*-----------------------------Retire-----------------------------*/
	// BLU cares about the position of the retiring branch; [0]: if inst 0 is branch [1]: if inst 1 is branch
	assign blu_retire_branch[0] = (ROB_retire_en_o[0] & (ROB_retire_packet_o[0].cond_branch || ROB_retire_packet_o[0].uncond_branch));
	assign blu_retire_branch[1] = (ROB_retire_en_o[1] & (ROB_retire_packet_o[1].cond_branch || ROB_retire_packet_o[1].uncond_branch));
	
	// FL only cares about the number of retired branch; [0]: presence [1]: number
	assign freelist_retire_branch[0] = (ROB_retire_en_o[0] & (ROB_retire_packet_o[0].cond_branch || ROB_retire_packet_o[0].uncond_branch)) || (ROB_retire_en_o[1] & (ROB_retire_packet_o[1].cond_branch || ROB_retire_packet_o[1].uncond_branch));
	assign freelist_retire_branch[1] = (ROB_retire_en_o[0] & (ROB_retire_packet_o[0].cond_branch || ROB_retire_packet_o[0].uncond_branch)) && (ROB_retire_en_o[1] & (ROB_retire_packet_o[1].cond_branch || ROB_retire_packet_o[1].uncond_branch));
	
	assign BTB_branch_retire_i = blu_retire_branch;
	// The sequence of BLU_packet aligns with the input dest_reg
	always_comb begin
		branch_recover = 2'b00;
		IF_branch_target_pc_i = 0;
		case(ROB_retire_en_o)
			2'b00: begin
				branch_recover = 2'b00;

			end
			2'b01: begin
				branch_recover[0] = (ROB_retire_packet_o[0].cond_branch || ROB_retire_packet_o[0].uncond_branch) & BLU_branch_recover_packet_o[0].br_cond;
				branch_recover[1] = 1'b0;
				IF_branch_target_pc_i = BLU_branch_recover_packet_o[0].br_target;
			end
			2'b11: begin
				case(freelist_retire_branch)
					2'b00: begin
					end
					2'b01: begin
						if(ROB_retire_packet_o[0].cond_branch || ROB_retire_packet_o[0].uncond_branch) begin
							if(BLU_branch_recover_packet_o[0].br_cond) begin
								branch_recover = 2'b01;
								IF_branch_target_pc_i = BLU_branch_recover_packet_o[0].br_target;
							end
						end else
						if(ROB_retire_packet_o[1].cond_branch || ROB_retire_packet_o[1].uncond_branch) begin
							if(BLU_branch_recover_packet_o[1].br_cond) begin
								branch_recover = 2'b11;
								IF_branch_target_pc_i = BLU_branch_recover_packet_o[1].br_target;
							end
						end
					end
					2'b11: begin
						if(!BLU_branch_recover_packet_o[0].br_cond && BLU_branch_recover_packet_o[1].br_cond) begin
							branch_recover = 2'b11;
							IF_branch_target_pc_i = BLU_branch_recover_packet_o[1].br_target;
						end else if (BLU_branch_recover_packet_o[0].br_cond && !BLU_branch_recover_packet_o[1].br_cond) begin
							branch_recover = 2'b01;
							IF_branch_target_pc_i = BLU_branch_recover_packet_o[0].br_target;
						end else if (!BLU_branch_recover_packet_o[0].br_cond && !BLU_branch_recover_packet_o[1].br_cond) begin
							branch_recover = 2'b00;
						end else if (BLU_branch_recover_packet_o[0].br_cond && BLU_branch_recover_packet_o[1].br_cond) begin
							branch_recover = 2'b01;
							IF_branch_target_pc_i = BLU_branch_recover_packet_o[0].br_target;
						end
					end
				endcase
			end
		endcase

		if(!branch_recover[0]) begin
			if(BTB_predict_en_o[0]) begin
				IF_branch_target_pc_i = BTB_predict_addr_o[0];
			end else if(BTB_predict_en_o[1]) begin
				IF_branch_target_pc_i = BTB_predict_addr_o[1];
			end
		end
	end

	// branch recover: [0]: presence, [1]: When present, 0 if inst 0 recover, 1 if inst 1 recover 
	assign RS_branch_recover_i    = branch_recover;
	assign FL_branch_recover_in   = branch_recover;
	assign ALU_0_branch_recover_i = branch_recover;
	assign ALU_1_branch_recover_i = branch_recover;
	assign BLU_branch_recover_i   = branch_recover;
	assign ROB_branch_recover_i   = branch_recover;
	assign MT_branch_recover_i    = branch_recover[0]; // only cares about if there is any recover
	assign AT_branch_recover_i    = branch_recover;
	assign LSQ_branch_recover_i   = branch_recover;
	assign MULT_branch_recover_i  = branch_recover[0];

	assign BLU_branch_retire_en_i = blu_retire_branch;
	assign FL_retire_branch_i = freelist_retire_branch;

	assign FL_retire_en_in = ROB_retire_en_o;
	assign AT_retire_en_i = ROB_retire_en_o;
	
	// retire mem for lsq, [0]: if inst 0 is mem, [1]: if inst 1 is mem and previous not recover
	assign LSQ_retire_mem_en_i[0] = ROB_retire_en_o[0] && (ROB_retire_packet_o[0].wr_mem || ROB_retire_packet_o[0].rd_mem) && !halt_before;
	assign LSQ_retire_mem_en_i[1] = ROB_retire_en_o[1] && (ROB_retire_packet_o[1].wr_mem || ROB_retire_packet_o[1].rd_mem) && (!branch_recover == 2'b01) && !halt && !halt_before;

	assign halt = !(branch_recover == 2'b01) & ((ROB_retire_packet_o[0].halt & ROB_retire_en_o[0]) | (ROB_retire_packet_o[1].halt & ROB_retire_en_o == 2'b11)); // for test

	`ifdef VDEBUG
	assign debug_signal.retire_en_debug = ROB_retire_en_o[0] | ROB_retire_en_o[1];
	assign debug_signal.retire_wr_mem_debug[0]=ROB_retire_packet_o[0].wr_mem;
	assign debug_signal.retire_rd_mem_debug[0]=ROB_retire_packet_o[0].rd_mem;
	assign debug_signal.retire_cond_branch_debug[0]=ROB_retire_packet_o[0].cond_branch;
	assign debug_signal.retire_uncond_branch_debug[0]=ROB_retire_packet_o[0].uncond_branch;
	assign debug_signal.retire_halt_debug[0]=ROB_retire_packet_o[0].halt;

	assign debug_signal.retire_wr_mem_debug[1]=ROB_retire_packet_o[1].wr_mem;
	assign debug_signal.retire_rd_mem_debug[1]=ROB_retire_packet_o[1].rd_mem;
	assign debug_signal.retire_cond_branch_debug[1]=ROB_retire_packet_o[1].cond_branch;
	assign debug_signal.retire_uncond_branch_debug[1]=ROB_retire_packet_o[1].uncond_branch;
	assign debug_signal.retire_halt_debug[1]=ROB_retire_packet_o[1].halt;
	`endif		

	/*------------------------------------------------Data path------------------------------------------------*/

	/*-----------------------------Fetch-----------------------------*/

	`ifdef VDEBUG
		assign debug_signal.proc2Imem_addr_debug = IF_proc2Imem_addr;
	`endif

	assign BTB_fetch_pc_i = {IF_inst_PC_o[1].PC, IF_inst_PC_o[0].PC};
	assign BTB_recover_addr_i = IF_branch_target_pc_i;
	assign BTB_recover_branch_pc_i = branch_recover[1] ? ROB_retire_packet_o[1].PC : ROB_retire_packet_o[0].PC;
	assign BTB_retire_PC_i[0] = ROB_retire_packet_o[0].PC;
	assign BTB_retire_PC_i[1] = ROB_retire_packet_o[1].PC;

	assign BLU_prediction = BTB_predict_en_o;
	assign BLU_prediction_address = BTB_predict_addr_o;

	/*-----------------------------Decode-----------------------------*/
	assign D0_inst_PC_i = IF_inst_PC_o[0];
	assign D1_inst_PC_i = IF_inst_PC_o[1];
	
	 `ifdef VDEBUG
	 assign debug_signal.Fetch_debug = IF_inst_PC_o;
	 `endif
	/*-----------------------------Dispatch-----------------------------*/
	// Map table read
	assign MT_arch_reg_i[0] = D0_decode_packet_o.rs1; // map table input from decoder
	assign MT_arch_reg_i[1] = D0_decode_packet_o.rs2;
	assign MT_arch_reg_i[2] = D1_decode_packet_o.rs1;
	assign MT_arch_reg_i[3] = D1_decode_packet_o.rs2;
	
	assign MT_arch_reg_dest_i[0] = D0_decode_packet_o.dest_reg;
	assign MT_arch_reg_dest_i[1] = D1_decode_packet_o.dest_reg;
	
	assign MT_dest_reg_sel_i[0] = D0_decode_packet_o.decode_noreg_packet.dest_reg_sel;
	assign MT_dest_reg_sel_i[1] = D1_decode_packet_o.decode_noreg_packet.dest_reg_sel;

	// Map table new tag from freelist
	assign MT_arch_reg_dest_new_tag_i = FL_free_reg_out;
	
	// Decode to ROB
	// if an inst does not have dest reg, the assigned free reg will be redirected to old tag so that it can be released to freelist as soon as this inst retires
	assign ROB_preg_tag_old_i[0] = D0_decode_packet_o.decode_noreg_packet.dest_reg_sel == DEST_RD ? MT_preg_tag_old_o[0] : FL_free_reg_out[0];   
	assign ROB_preg_tag_old_i[1] = D1_decode_packet_o.decode_noreg_packet.dest_reg_sel == DEST_RD ? MT_preg_tag_old_o[1] : FL_free_reg_out[1];  

	assign ROB_freeReg_i = FL_free_reg_out;                                              // new tag from freelist
	assign ROB_arch_old_i = {D1_decode_packet_o.dest_reg, D0_decode_packet_o.dest_reg};  // arch reg, will be used in retire

	always_comb begin
		ROB_retire_packet_i[0].rd_mem        =  D0_decode_packet_o.decode_noreg_packet.rd_mem;
		ROB_retire_packet_i[0].wr_mem        =  D0_decode_packet_o.decode_noreg_packet.wr_mem;
		ROB_retire_packet_i[0].cond_branch   =  D0_decode_packet_o.decode_noreg_packet.cond_branch;
		ROB_retire_packet_i[0].uncond_branch =  D0_decode_packet_o.decode_noreg_packet.uncond_branch;
		ROB_retire_packet_i[0].csr_op        =  D0_decode_packet_o.decode_noreg_packet.csr_op;
		ROB_retire_packet_i[0].halt          =  D0_decode_packet_o.decode_noreg_packet.halt;
		ROB_retire_packet_i[0].illegal       =  D0_decode_packet_o.decode_noreg_packet.illegal;
		ROB_retire_packet_i[0].dest_reg_sel  = D0_decode_packet_o.decode_noreg_packet.dest_reg_sel;
		`ifdef DEBUG
		ROB_retire_packet_i[0].PC            =  D0_decode_packet_o.decode_noreg_packet.PC;
		`endif

		ROB_retire_packet_i[1].rd_mem        =  D1_decode_packet_o.decode_noreg_packet.rd_mem;
		ROB_retire_packet_i[1].wr_mem        =  D1_decode_packet_o.decode_noreg_packet.wr_mem;
		ROB_retire_packet_i[1].cond_branch   =  D1_decode_packet_o.decode_noreg_packet.cond_branch;
		ROB_retire_packet_i[1].uncond_branch =  D1_decode_packet_o.decode_noreg_packet.uncond_branch;
		ROB_retire_packet_i[1].csr_op        =  D1_decode_packet_o.decode_noreg_packet.csr_op;
		ROB_retire_packet_i[1].halt          =  D1_decode_packet_o.decode_noreg_packet.halt;
		ROB_retire_packet_i[1].illegal       =  D1_decode_packet_o.decode_noreg_packet.illegal;
		ROB_retire_packet_i[1].dest_reg_sel  =  D1_decode_packet_o.decode_noreg_packet.dest_reg_sel;
		`ifdef DEBUG
		ROB_retire_packet_i[1].PC            =  D1_decode_packet_o.decode_noreg_packet.PC;
		`endif
	end

	// Decode to RS
	assign RS_source_tag_1_i[0] = MT_preg_tag_o[0];    // source tags from MT
	assign RS_source_tag_2_i[0] = MT_preg_tag_o[1];
	assign RS_dest_tag_i[0]     = FL_free_reg_out[0];  // new dest tag from freelist

	assign RS_source_tag_1_i[1] = MT_preg_tag_o[2];
	assign RS_source_tag_2_i[1] = MT_preg_tag_o[3];
	assign RS_dest_tag_i[1]     = FL_free_reg_out[1];

	assign RS_decode_noreg_packet[0] = D0_decode_packet_o.decode_noreg_packet;
	assign RS_decode_noreg_packet[1] = D1_decode_packet_o.decode_noreg_packet;

	// Map table ready to rs
	// if an inst is not a branch (only branch use rs1 rs2 instead of opa nd opb?) and does not use rs1 or rs2 value , the corresponding ready bit is 1
	assign RS_ready_1_i[0] = (D0_decode_packet_o.decode_noreg_packet.cond_branch || D0_decode_packet_o.decode_noreg_packet.wr_mem) ? MT_preg_ready_o[0] : D0_decode_packet_o.decode_noreg_packet.opa_select != OPA_IS_RS1 ? 1'b1 : MT_preg_ready_o[0];
	assign RS_ready_2_i[0] = (D0_decode_packet_o.decode_noreg_packet.cond_branch || D0_decode_packet_o.decode_noreg_packet.wr_mem) ? MT_preg_ready_o[1] : D0_decode_packet_o.decode_noreg_packet.opb_select != OPB_IS_RS2 ? 1'b1 : MT_preg_ready_o[1];

	assign RS_ready_1_i[1] = (D1_decode_packet_o.decode_noreg_packet.cond_branch || D1_decode_packet_o.decode_noreg_packet.wr_mem) ? MT_preg_ready_o[2] : D1_decode_packet_o.decode_noreg_packet.opa_select != OPA_IS_RS1 ? 1'b1 : MT_preg_ready_o[2];
	assign RS_ready_2_i[1] = (D1_decode_packet_o.decode_noreg_packet.cond_branch || D1_decode_packet_o.decode_noreg_packet.wr_mem) ? MT_preg_ready_o[3] : D1_decode_packet_o.decode_noreg_packet.opb_select != OPB_IS_RS2 ? 1'b1 : MT_preg_ready_o[3];

	assign LSQ_opcode_dispatch_i[0] = D0_decode_packet_o.decode_noreg_packet.opcode;
	assign LSQ_opcode_dispatch_i[1] = D1_decode_packet_o.decode_noreg_packet.opcode;
	assign LSQ_dispatch_dest_reg_i[0] = FL_free_reg_out[0];
	assign LSQ_dispatch_dest_reg_i[1] = FL_free_reg_out[1];
	assign LSQ_mem_funct[0] = D0_decode_packet_o.decode_noreg_packet.mem_funct;
	assign LSQ_mem_funct[1] = D1_decode_packet_o.decode_noreg_packet.mem_funct;

	assign BLU_dispatch_reg_i[0] = FL_free_reg_out[0];
	assign BLU_dispatch_reg_i[1] = FL_free_reg_out[1];


	/*-----------------------------Issue-----------------------------*/
	// RS to FU 
	assign ALU_0_packet = RS_FU_packet_o[RS_FU_select_RS_port_o[0]];
	assign ALU_1_packet = RS_FU_packet_o[RS_FU_select_RS_port_o[1]];
	assign BLU_packet   = RS_FU_packet_o[RS_FU_select_RS_port_o[2]];
	assign LSQ_packet  	= RS_FU_packet_o[RS_FU_select_RS_port_o[3]];
	assign MULT_packet  = RS_FU_packet_o[RS_FU_select_RS_port_o[4]];


	logic [`XLEN-1:0] ALU_0_value_a;
	logic [`XLEN-1:0] ALU_0_value_b;
	logic [`XLEN-1:0] ALU_1_value_a;
	logic [`XLEN-1:0] ALU_1_value_b;
	logic [`XLEN-1:0] BLU_value_a;
	logic [`XLEN-1:0] BLU_value_b;
	logic [`XLEN-1:0] LSQ_value_a;
	logic [`XLEN-1:0] LSQ_value_b;
	logic [`XLEN-1:0] MULT_value_a;
	logic [`XLEN-1:0] MULT_value_b;

	// FU read map table
	always_comb begin
		RF_rda_idx = 32'bz;
		RF_rdb_idx = 32'bz;
		RF_rdc_idx = 32'bz;
		RF_rdd_idx = 32'bz;
		q = 0;
		BLU_value_a = 32'h0;
		BLU_value_b = 32'h0;
		LSQ_value_a = 32'h0;
		LSQ_value_b = 32'h0;
		ALU_1_value_a = 32'h0;
		ALU_1_value_b = 32'h0;
		ALU_0_value_a = 32'h0;
		ALU_0_value_b = 32'h0;
		MULT_value_a  = 32'h0;
		MULT_value_b  = 32'h0;
		

		for(p = 0; p < `FU_NUMBER && (q < 2); p++) begin
			if(RS_FU_select_en_o[p]) begin
				case(p)

					4: begin
						if(q == 0) begin
							RF_rda_idx  = MULT_packet.source_tag_1;
							RF_rdb_idx  = MULT_packet.source_tag_2;
							MULT_value_a = MULT_packet.decode_noreg_packet.rs1 == `ZERO_REG ? 0 : RF_rda_out;
							MULT_value_b = MULT_packet.decode_noreg_packet.rs2 == `ZERO_REG ? 0 : RF_rdb_out;
						end
						else begin
							RF_rdc_idx  = MULT_packet.source_tag_1;
							RF_rdd_idx  = MULT_packet.source_tag_2;
							MULT_value_a = MULT_packet.decode_noreg_packet.rs1 == `ZERO_REG ? 0 : RF_rdc_out;
							MULT_value_b = MULT_packet.decode_noreg_packet.rs2 == `ZERO_REG ? 0 : RF_rdd_out;
						end
					end
					
					3: begin
						if(q == 0) begin
							RF_rda_idx  = LSQ_packet.source_tag_1;
							RF_rdb_idx  = LSQ_packet.source_tag_2;
							LSQ_value_a = LSQ_packet.decode_noreg_packet.rs1 == `ZERO_REG ? 0 : RF_rda_out;
							LSQ_value_b = LSQ_packet.decode_noreg_packet.rs2 == `ZERO_REG ? 0 : RF_rdb_out;
						end
						else begin
							RF_rdc_idx  = LSQ_packet.source_tag_1;
							RF_rdd_idx  = LSQ_packet.source_tag_2;
							LSQ_value_a = LSQ_packet.decode_noreg_packet.rs1 == `ZERO_REG ? 0 : RF_rdc_out;
							LSQ_value_b = LSQ_packet.decode_noreg_packet.rs2 == `ZERO_REG ? 0 : RF_rdd_out;
						end
					end

					2: begin
						if(q == 0) begin
							RF_rda_idx  = BLU_packet.source_tag_1;
							RF_rdb_idx  = BLU_packet.source_tag_2;
							BLU_value_a = BLU_packet.decode_noreg_packet.rs1 == `ZERO_REG ? 0 : RF_rda_out; // Zero reg is zero
							BLU_value_b = BLU_packet.decode_noreg_packet.rs2 == `ZERO_REG ? 0 : RF_rdb_out; 
						end
						else begin
							RF_rdc_idx  = BLU_packet.source_tag_1;
							RF_rdd_idx  = BLU_packet.source_tag_2;
							BLU_value_a = BLU_packet.decode_noreg_packet.rs1 == `ZERO_REG ? 0 : RF_rdc_out;
							BLU_value_b = BLU_packet.decode_noreg_packet.rs2 == `ZERO_REG ? 0 : RF_rdd_out; 
						end


					end

					1: begin
						if(q == 0) begin
							RF_rda_idx = ALU_1_packet.source_tag_1;
							RF_rdb_idx = ALU_1_packet.source_tag_2;
							ALU_1_value_a = ALU_1_packet.decode_noreg_packet.rs1 == `ZERO_REG ? 0 : RF_rda_out;
							ALU_1_value_b = ALU_1_packet.decode_noreg_packet.rs2 == `ZERO_REG ? 0 : RF_rdb_out;
						end
						else begin
							RF_rdc_idx = ALU_1_packet.source_tag_1;
							RF_rdd_idx = ALU_1_packet.source_tag_2;
							ALU_1_value_a = ALU_1_packet.decode_noreg_packet.rs1 == `ZERO_REG ? 0 : RF_rdc_out;
							ALU_1_value_b = ALU_1_packet.decode_noreg_packet.rs2 == `ZERO_REG ? 0 : RF_rdd_out;
						end
					end

					0: begin
						if(q == 0) begin
							RF_rda_idx = ALU_0_packet.source_tag_1;
							RF_rdb_idx = ALU_0_packet.source_tag_2;
							ALU_0_value_a = ALU_0_packet.decode_noreg_packet.rs1 == `ZERO_REG ? 0 : RF_rda_out;
							ALU_0_value_b = ALU_0_packet.decode_noreg_packet.rs2 == `ZERO_REG ? 0 :  RF_rdb_out;

						end
						else begin
							RF_rdc_idx = ALU_0_packet.source_tag_1;
							RF_rdd_idx = ALU_0_packet.source_tag_2;
							ALU_0_value_a = ALU_0_packet.decode_noreg_packet.rs1 == `ZERO_REG ? 0 : RF_rdc_out;
							ALU_0_value_b = ALU_0_packet.decode_noreg_packet.rs2 == `ZERO_REG ? 0 : RF_rdd_out;
						end
					end

					default: begin
						RF_rda_idx = 32'bx;
						RF_rdb_idx = 32'bx;
						RF_rdc_idx = 32'bx;
						RF_rdd_idx = 32'bx;
					end
				endcase
				q = q + 1;
			end


		end
	end

	// ALU_0 
	always_comb begin

		case(ALU_0_packet.decode_noreg_packet.opa_select)
			OPA_IS_RS1 : ALU_0_opa = ALU_0_value_a;
			OPA_IS_NPC : ALU_0_opa = ALU_0_packet.decode_noreg_packet.extra_slot_a;
			OPA_IS_PC  : ALU_0_opa = ALU_0_packet.decode_noreg_packet.extra_slot_a;
			OPA_IS_ZERO: ALU_0_opa = 0;
		endcase
		
		case(ALU_0_packet.decode_noreg_packet.opb_select)
			OPB_IS_RS2  : ALU_0_opb = ALU_0_value_b;
			OPB_IS_I_IMM: ALU_0_opb = ALU_0_packet.decode_noreg_packet.extra_slot_b;
			OPB_IS_S_IMM: ALU_0_opb = ALU_0_packet.decode_noreg_packet.extra_slot_b;
			OPB_IS_B_IMM: ALU_0_opb = ALU_0_packet.decode_noreg_packet.extra_slot_b;
			OPB_IS_U_IMM: ALU_0_opb = ALU_0_packet.decode_noreg_packet.extra_slot_b;
			OPB_IS_J_IMM: ALU_0_opb = ALU_0_packet.decode_noreg_packet.extra_slot_b;
		endcase
		
		ALU_0_func           = ALU_0_packet.decode_noreg_packet.alu_opcode;
		ALU_0_dest_reg_i     = ALU_0_packet.dest_tag;
		ALU_0_dest_reg_sel_i = ALU_0_packet.decode_noreg_packet.dest_reg_sel;

		`ifdef DEBUG
		debug_signal.ALU_0_dest_reg_i_debug = ALU_0_dest_reg_i;
		debug_signal.ALU_0_func_debug       = ALU_0_func;
		debug_signal.ALU_0_opa_debug        = ALU_0_opa;
		debug_signal.ALU_0_opb_debug        = ALU_0_opb;
		`endif

	end

	// ALU_1
	always_comb begin

		case(ALU_1_packet.decode_noreg_packet.opa_select)
			OPA_IS_RS1 : ALU_1_opa = ALU_1_value_a;
			OPA_IS_NPC : ALU_1_opa = ALU_1_packet.decode_noreg_packet.extra_slot_a;
			OPA_IS_PC  : ALU_1_opa = ALU_1_packet.decode_noreg_packet.extra_slot_a;
			OPA_IS_ZERO: ALU_1_opa = 0;
		endcase

		case(ALU_1_packet.decode_noreg_packet.opb_select)
			OPB_IS_RS2  : ALU_1_opb = ALU_1_value_b;
			OPB_IS_I_IMM: ALU_1_opb = ALU_1_packet.decode_noreg_packet.extra_slot_b;
			OPB_IS_S_IMM: ALU_1_opb = ALU_1_packet.decode_noreg_packet.extra_slot_b;
			OPB_IS_B_IMM: ALU_1_opb = ALU_1_packet.decode_noreg_packet.extra_slot_b;
			OPB_IS_U_IMM: ALU_1_opb = ALU_1_packet.decode_noreg_packet.extra_slot_b;
			OPB_IS_J_IMM: ALU_1_opb = ALU_1_packet.decode_noreg_packet.extra_slot_b;
		endcase
		
		ALU_1_func           = ALU_1_packet.decode_noreg_packet.alu_opcode;
		ALU_1_dest_reg_i     = ALU_1_packet.dest_tag;
		ALU_1_dest_reg_sel_i = ALU_1_packet.decode_noreg_packet.dest_reg_sel;

		`ifdef DEBUG
		debug_signal.ALU_1_dest_reg_i_debug = ALU_1_dest_reg_i;
		debug_signal.ALU_1_func_debug       = ALU_1_func;
		debug_signal.ALU_1_opa_debug        = ALU_1_opa;
		debug_signal.ALU_1_opb_debug        = ALU_1_opb;
		`endif
	end

	//BLU
	always_comb begin
		case(BLU_packet.decode_noreg_packet.opa_select)
				OPA_IS_RS1 : BLU_opa = BLU_value_a;
				OPA_IS_NPC : BLU_opa = BLU_packet.decode_noreg_packet.extra_slot_a;
				OPA_IS_PC  : BLU_opa = BLU_packet.decode_noreg_packet.extra_slot_a;
				OPA_IS_ZERO: BLU_opa = 0;
			endcase

		case(BLU_packet.decode_noreg_packet.opb_select)
				OPB_IS_RS2  : BLU_opb = BLU_value_b;
				OPB_IS_I_IMM: BLU_opb = BLU_packet.decode_noreg_packet.extra_slot_b;
				OPB_IS_S_IMM: BLU_opb = BLU_packet.decode_noreg_packet.extra_slot_b;
				OPB_IS_B_IMM: BLU_opb = BLU_packet.decode_noreg_packet.extra_slot_b;
				OPB_IS_U_IMM: BLU_opb = BLU_packet.decode_noreg_packet.extra_slot_b;
				OPB_IS_J_IMM: BLU_opb = BLU_packet.decode_noreg_packet.extra_slot_b;
		endcase
			
		BLU_rs1            = BLU_value_a;
		BLU_rs2            = BLU_value_b;
		BLU_dest_reg_sel_i = BLU_packet.decode_noreg_packet.dest_reg_sel;
		BLU_dest_reg_i     = BLU_packet.dest_tag;
		BLU_NPC_i          = BLU_packet.decode_noreg_packet.NPC;
		BLU_PC_i           = BLU_packet.decode_noreg_packet.PC;
		BLU_inst_opcode    = BLU_packet.decode_noreg_packet.opcode;
		BLU_func_br        = BLU_packet.decode_noreg_packet.blu_opcode;
		BLU_branch_retire_dest_reg_i = ROB_T_o;
	end

	//LSQ
	always_comb begin
		case(LSQ_packet.decode_noreg_packet.opa_select)
				OPA_IS_RS1 : LSQ_opa = LSQ_value_a;
				OPA_IS_NPC : LSQ_opa = LSQ_packet.decode_noreg_packet.extra_slot_a;
				OPA_IS_PC  : LSQ_opa = LSQ_packet.decode_noreg_packet.extra_slot_a;
				OPA_IS_ZERO: LSQ_opa = 0;
			endcase

		case(LSQ_packet.decode_noreg_packet.opb_select)
				OPB_IS_RS2  : LSQ_opb = LSQ_value_b;
				OPB_IS_I_IMM: LSQ_opb = LSQ_packet.decode_noreg_packet.extra_slot_b;
				OPB_IS_S_IMM: LSQ_opb = LSQ_packet.decode_noreg_packet.extra_slot_b;
				OPB_IS_B_IMM: LSQ_opb = LSQ_packet.decode_noreg_packet.extra_slot_b;
				OPB_IS_U_IMM: LSQ_opb = LSQ_packet.decode_noreg_packet.extra_slot_b;
				OPB_IS_J_IMM: LSQ_opb = LSQ_packet.decode_noreg_packet.extra_slot_b;
		endcase
			LSQ_rs2_value_i = LSQ_value_b;
			LSQ_dest_reg_i  = LSQ_packet.dest_tag;
			

	end

	//Mult
	always_comb begin
		case(MULT_packet.decode_noreg_packet.opa_select)
			OPA_IS_RS1 : MULT_opa = MULT_value_a;
			OPA_IS_NPC : MULT_opa = MULT_packet.decode_noreg_packet.extra_slot_a;
			OPA_IS_PC  : MULT_opa = MULT_packet.decode_noreg_packet.extra_slot_a;
			OPA_IS_ZERO: MULT_opa = 0;
		endcase

		case(MULT_packet.decode_noreg_packet.opb_select)
			OPB_IS_RS2  : MULT_opb = MULT_value_b;
			OPB_IS_I_IMM: MULT_opb = MULT_packet.decode_noreg_packet.extra_slot_b;
			OPB_IS_S_IMM: MULT_opb = MULT_packet.decode_noreg_packet.extra_slot_b;
			OPB_IS_B_IMM: MULT_opb = MULT_packet.decode_noreg_packet.extra_slot_b;
			OPB_IS_U_IMM: MULT_opb = MULT_packet.decode_noreg_packet.extra_slot_b;
			OPB_IS_J_IMM: MULT_opb = MULT_packet.decode_noreg_packet.extra_slot_b;
		endcase
		MULT_dest_reg_i = MULT_packet.dest_tag;
		MULT_func       = MULT_packet.decode_noreg_packet.alu_opcode;
	
	
	end

	/*-----------------------------Complete-----------------------------*/
	// hardcoded FU position
	assign CDB_completed_tag_i = {MULT_dest_reg_o, LSQ_dest_reg_o, BLU_dest_reg_o, ALU_1_dest_reg_o, ALU_0_dest_reg_o};

	assign ROB_CDB_i = CDB_o;
	assign RS_CDB_i  = CDB_o;
	assign MT_CDB_i  = CDB_o;
	
	`ifdef DEBUG
	assign debug_signal.CDB_o_debug = CDB_o;
	assign debug_signal.CDB_en_debug = CDB_en_o;
	`endif

	/*-----------------------------Retire-----------------------------*/
	assign FL_retire_tag_in = ROB_T_old_o;

	assign AT_retire_arch_reg_i = ROB_arch_old_o;
	assign AT_new_tag_i         = ROB_T_o;
	assign AT_dest_reg_sel_i[0] = ROB_retire_packet_o[0].dest_reg_sel;
	assign AT_dest_reg_sel_i[1] = ROB_retire_packet_o[1].dest_reg_sel;
	
	assign MT_arch_table_recover_i = AT_arch_table_recover_o;

/*------------------------------------------------Memory------------------------------------------------*/

	// LSQ <-> Dcache
	assign LSQ_mem_data_i = dcache_Dcache_data_out;
	assign LSQ_mem_valid_i = dcache_Dcache_valid_out;
	
	assign dcache_proc2Dcache_addr = LSQ_mem_address_o;
	assign dcache_proc2Dcache_command = LSQ_mem_command_o;
	assign dcache_proc2Dcache_data = LSQ_mem_wdata_o;
	assign dcache_proc2Dcache_size = LSQ_mem_size_o;
	assign dcache_proc2Dcache_rd_wr = LSQ_mem_rd_wr_o;

	// Dcache <-> arbiter
	assign dcache_Dmem2proc_data     = arbiter_d_pmem_rdata;
	assign dcache_Dmem2proc_response = arbiter_d_pmem_response;
	assign dcache_Dmem2proc_tag      = arbiter_d_pmem_tag;

	assign arbiter_d_pmem_command = dcache_proc2Dmem_command;
	assign arbiter_d_pmem_address = dcache_proc2Dmem_addr;
	assign arbiter_d_pmem_wdata   = dcache_proc2Dmem_data;
	assign arbiter_d_pmem_request = dcache_proc2Dmem_request;

	// Icache <-> fetch
	assign icache_proc2Icache_addr = IF_proc2Imem_addr;
	assign icache_read_valid = IF_read_valid_o;

	assign IF_Icache_valid_i = icache_Icache_valid_out;
	assign IF_Imem2proc_data = icache_Icache_data_out;

	// Icache <-> arbiter
	assign icache_Imem2proc_response = arbiter_i_pmem_response;
	assign icache_Imem2proc_data = arbiter_i_pmem_rdata;
	assign icache_Imem2proc_tag = arbiter_i_pmem_tag;

	assign arbiter_i_pmem_command = icache_proc2Imem_command;
	assign arbiter_i_pmem_address = icache_proc2Imem_addr;
	assign arbiter_i_pmem_request = icache_proc2Imem_request;

	// Arbiter <-> mem
	assign arbiter_mem2proc_rdata = mem2proc_data;
    assign arbiter_mem2proc_response = mem2proc_response;
    assign arbiter_mem2proc_tag = mem2proc_tag;

	assign proc2mem_command = arbiter_proc2mem_command;
	assign proc2mem_addr = arbiter_proc2mem_address;
	assign proc2mem_data = arbiter_proc2mem_wdata;



/*------------------------------------------------Testbench------------------------------------------------*/
	assign debug_signal.pipeline_commit[0] = ROB_retire_en_o[0] && ~ROB_retire_packet_o[0].illegal;
	assign debug_signal.pipeline_commit[1] = ((ROB_retire_packet_o[0].halt & ROB_retire_en_o[0] | branch_recover == 2'b01) ? 1'b0 : ROB_retire_en_o[1]) && ~ROB_retire_packet_o[1].illegal;

	assign debug_signal.pipeline_commit_data[0] = ROB_retire_en_o[0]? (ROB_retire_packet_o[0].wr_mem ? LSQ_debug_store_data[0] : debug_signal.value_RF[ROB_T_o[0]]): 32'bz;
	assign debug_signal.pipeline_commit_reg[0] =  ROB_retire_en_o[0]? ROB_retire_packet_o[0].wr_mem ? 1'b1 : ROB_retire_packet_o[0].dest_reg_sel == DEST_RD ? ROB_arch_old_o[0] : `ZERO_REG : 32'bz;

	assign debug_signal.pipeline_commit_data[1] = ROB_retire_en_o[1]? (ROB_retire_packet_o[1].wr_mem ? LSQ_debug_store_data[1] : debug_signal.value_RF[ROB_T_o[1]]): 32'bz;
	assign debug_signal.pipeline_commit_reg[1] =  ROB_retire_en_o[1]? ROB_retire_packet_o[1].wr_mem ? 1'b1 : ROB_retire_packet_o[1].dest_reg_sel == DEST_RD ? ROB_arch_old_o[1] : `ZERO_REG : 32'bz;

	assign debug_signal.pipeline_commit_PC[0] = ROB_retire_en_o[0]? ROB_retire_packet_o[0].PC : 32'bz;
	assign debug_signal.pipeline_commit_PC[1] = ROB_retire_en_o[1]? ROB_retire_packet_o[1].PC : 32'bz;

	always_ff @(posedge clk) begin
        if(reset) begin
			halt_before <= 0;
		end else begin
			halt_before <= halt_before ? 1'b1 : halt;
		end
	end
endmodule // pipeline
`endif // __PIPELINE_V__

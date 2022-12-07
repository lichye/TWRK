/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  sys_defs.vh                                         //
//                                                                     //
//  Description :  This file has the macro-defines for macros used in  //
//                 the pipeline design.                                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`ifndef __SYS_DEFS_VH__
`define __SYS_DEFS_VH__

/* Synthesis testing definition, used in DUT module instantiation */

`ifdef  SYNTH_TEST
`define DUT(mod) mod``_svsim
`else
`define DUT(mod) mod
`endif

// actually, you might have to change this if you change VERILOG_CLOCK_PERIOD
// JK you don't ^^^
//
`define SD #0

/*------------------------------------Debug use------------------------------------*/
`define DEBUG 1
// `define VDEBUG 0
`define CHECK(val_1, val_2) assert(val_1 == val_2) else begin $display("Assertion Error: The input value is %h, instead of %h", val_1, val_2); error=1; end
`define NEXT_CYCLE @(negedge clk)

/*------------------------------------Module Parameters------------------------------------*/
`define PREG_NUMBER `ARCHREG_NUMBER + `ROB_SIZE // number of physical registers = architecture registers + ROB size
`define ARCHREG_NUMBER 32 // depends on ISA
`define ROB_SIZE 32 // design choice
`define RS_LENGTH 4 // design choice
`define FREELIST_SIZE `ROB_SIZE // size of free list = ROB size
`define FU_NUMBER 5
`define BRANCH_BUFFER_SIZE 32
`define FETCH_BUFFER_SIZE 16

`define SUPERSCALE_WIDTH 2
`define CDB_SIZE `SUPERSCALE_WIDTH
`define TABLE_SIZE `ARCHREG_NUMBER
`define TABLE_READ `SUPERSCALE_WIDTH*2
`define TABLE_WRITE `SUPERSCALE_WIDTH
`define LSQ_SIZE 32
`define BTB_SIZE 4

/*------------------------------------Misc.------------------------------------*/
//
// useful boolean single-bit definitions
//
`define TRUE 1
`define FALSE 0
 `define LW 0
 `define SW 1
//////////////////////////////////////////////
//
// Memory/testbench attribute definitions
//
//////////////////////////////////////////////

`define XLEN 32
`define CACHE_MODE //removes the byte-level interface from the memory mode, DO NOT MODIFY!
`define NUM_MEM_TAGS           15

`define MEM_SIZE_IN_BYTES      (64*1024)
`define MEM_64BIT_LINES        (`MEM_SIZE_IN_BYTES/8)

//you can change the clock period to whatever, 10 is just fine
`define VERILOG_CLOCK_PERIOD   24.0
`define SYNTH_CLOCK_PERIOD     24.0 // Clock period for synth and memory latency

`define MEM_LATENCY_IN_CYCLES (100.0/`SYNTH_CLOCK_PERIOD+0.49999)
// `define MEM_LATENCY_IN_CYCLES 4 // for early stage dev use
 
// the 0.49999 is to force ceiling(100/period).  The default behavior for
// float to integer conversion is rounding to nearest

typedef union packed {
    logic [7:0][7:0]  byte_level;
    logic [3:0][15:0] half_level;
    logic [1:0][31:0] word_level;
} EXAMPLE_CACHE_BLOCK;

typedef union packed {
    logic [3:0][7:0]  byte_level;
    logic [1:0][15:0] half_level;
    logic [31:0] word_level;
} BUFFER;

//
// Memory bus commands control signals
//
typedef enum logic [1:0] {
	BUS_NONE     = 2'h0,
	BUS_LOAD     = 2'h1,
	BUS_STORE    = 2'h2
} BUS_COMMAND;


typedef enum logic [1:0] {
	BYTE = 2'h0,
	HALF = 2'h1,
	WORD = 2'h2,
	DOUBLE = 2'h3
} MEM_SIZE;

//////////////////////////////////////////////
// Exception codes
// This mostly follows the RISC-V Privileged spec
// except a few add-ons for our infrastructure
// The majority of them won't be used, but it's
// good to know what they are
//////////////////////////////////////////////

typedef enum logic [3:0] {
	INST_ADDR_MISALIGN  = 4'h0,
	INST_ACCESS_FAULT   = 4'h1,
	ILLEGAL_INST        = 4'h2,
	BREAKPOINT          = 4'h3,
	LOAD_ADDR_MISALIGN  = 4'h4,
	LOAD_ACCESS_FAULT   = 4'h5,
	STORE_ADDR_MISALIGN = 4'h6,
	STORE_ACCESS_FAULT  = 4'h7,
	ECALL_U_MODE        = 4'h8,
	ECALL_S_MODE        = 4'h9,
	NO_ERROR            = 4'ha, //a reserved code that we modified for our purpose
	ECALL_M_MODE        = 4'hb,
	INST_PAGE_FAULT     = 4'hc,
	LOAD_PAGE_FAULT     = 4'hd,
	HALTED_ON_WFI       = 4'he, //another reserved code that we used
	STORE_PAGE_FAULT    = 4'hf
} EXCEPTION_CODE;


//////////////////////////////////////////////
//
// Datapath control signals
//
//////////////////////////////////////////////

//
// ALU opA input mux selects
//
typedef enum logic [1:0] {
	OPA_IS_RS1  = 2'h0,
	OPA_IS_NPC  = 2'h1,
	OPA_IS_PC   = 2'h2,
	OPA_IS_ZERO = 2'h3
} ALU_OPA_SELECT;

//
// ALU opB input mux selects
//
typedef enum logic [3:0] {
	OPB_IS_RS2    = 4'h0,
	OPB_IS_I_IMM  = 4'h1,
	OPB_IS_S_IMM  = 4'h2,
	OPB_IS_B_IMM  = 4'h3,
	OPB_IS_U_IMM  = 4'h4,
	OPB_IS_J_IMM  = 4'h5
} ALU_OPB_SELECT;

//
// Destination register select
//
typedef enum logic [1:0] {
	DEST_RD = 2'h0,
	DEST_NONE  = 2'h1
} DEST_REG_SEL;

//
// ALU function code input
// probably want to leave these alone
//
typedef enum logic [4:0] {
	ALU_ADD     = 5'h00,
	ALU_SUB     = 5'h01,
	ALU_SLT     = 5'h02,
	ALU_SLTU    = 5'h03,
	ALU_AND     = 5'h04,
	ALU_OR      = 5'h05,
	ALU_XOR     = 5'h06,
	ALU_SLL     = 5'h07,
	ALU_SRL     = 5'h08,
	ALU_SRA     = 5'h09,
	ALU_MUL     = 5'h0a,
	ALU_MULH    = 5'h0b,
	ALU_MULHSU  = 5'h0c,
	ALU_MULHU   = 5'h0d,
	ALU_DIV     = 5'h0e,
	ALU_DIVU    = 5'h0f,
	ALU_REM     = 5'h10,
	ALU_REMU    = 5'h11
} ALU_FUNC;

typedef enum logic [3:0] {
	LSQ_LB		= 4'h0,
	LSQ_LH		= 4'h1,
	LSQ_LW		= 4'h2,
	LSQ_LBU		= 4'h3,
	LSQ_LHU		= 4'h4,
	LSQ_SB		= 4'h5,
	LSQ_SH		= 4'h6,
	LSQ_SW		= 4'h7
} LSQ_FUNC;

//Structure full signal
typedef enum logic [1:0] {
	MORE_LEFT = 2'h0,
	ONE_LEFT  = 2'h1,
	FULL      = 2'h2,
	ILLEGAL = 2'h3
} STRUCTURE_FULL;

/*--------------------------------------RISCV ISA SPEC--------------------------------------*/
//
// Basic NOP instruction.  Allows pipline registers to clearly be reset with
// an instruction that does nothing instead of Zero which is really an ADDI x0, x0, 0
//
`define NOP 32'h00000013

// the RISCV register file zero register, any read of this register always
// returns a zero value, and any write to this register is thrown away
//
`define ZERO_REG 5'd0


typedef union packed {
	logic [31:0] inst;
	struct packed {
		logic [6:0] funct7;
		logic [4:0] rs2;
		logic [4:0] rs1;
		logic [2:0] funct3;
		logic [4:0] rd;
		logic [6:0] opcode;
	} r; //register to register instructions
	struct packed {
		logic [11:0] imm;
		logic [4:0]  rs1; //base
		logic [2:0]  funct3;
		logic [4:0]  rd;  //dest
		logic [6:0]  opcode;
	} i; //immediate or load instructions
	struct packed {
		logic [6:0] off; //offset[11:5] for calculating address
		logic [4:0] rs2; //source
		logic [4:0] rs1; //base
		logic [2:0] funct3;
		logic [4:0] set; //offset[4:0] for calculating address
		logic [6:0] opcode;
	} s; //store instructions
	struct packed {
		logic       of; //offset[12]
		logic [5:0] s;   //offset[10:5]
		logic [4:0] rs2;//source 2
		logic [4:0] rs1;//source 1
		logic [2:0] funct3;
		logic [3:0] et; //offset[4:1]
		logic       f;  //offset[11]
		logic [6:0] opcode;
	} b; //branch instructions
	struct packed {
		logic [19:0] imm;
		logic [4:0]  rd;
		logic [6:0]  opcode;
	} u; //upper immediate instructions
	struct packed {
		logic       of; //offset[20]
		logic [9:0] et; //offset[10:1]
		logic       s;  //offset[11]
		logic [7:0] f;	//offset[19:12]
		logic [4:0] rd; //dest
		logic [6:0] opcode;
	} j;  //jump instructions
`ifdef ATOMIC_EXT
	struct packed {
		logic [4:0] funct5;
		logic       aq;
		logic       rl;
		logic [4:0] rs2;
		logic [4:0] rs1;
		logic [2:0] funct3;
		logic [4:0] rd;
		logic [6:0] opcode;
	} a; //atomic instructions
`endif
`ifdef SYSTEM_EXT
	struct packed {
		logic [11:0] csr;
		logic [4:0]  rs1;
		logic [2:0]  funct3;
		logic [4:0]  rd;
		logic [6:0]  opcode;
	} sys; //system call instructions
`endif
} INST; //instruction typedef, this should cover all types of instructionsW


/*--------------------------------------Module Data Structures--------------------------------------*/
typedef struct packed {
	INST inst;
	logic [31:0] PC;
	logic [31:0] NPC;

} INST_PC;

typedef struct packed {
	logic rd_mem;
	logic wr_mem;
	logic cond_branch;
	logic uncond_branch;
	logic csr_op;
	logic halt;
	logic illegal;
	DEST_REG_SEL dest_reg_sel;
	`ifdef DEBUG
	logic [31:0] PC;
	`endif
} ROB_RETIRE_PACKET;

typedef struct packed {
	logic	valid;
	logic [$clog2(`PREG_NUMBER)-1: 0] T;
	logic [$clog2(`PREG_NUMBER)-1: 0] T_old;
	logic [$clog2(`ARCHREG_NUMBER)-1: 0] arch_old;
	ROB_RETIRE_PACKET retire_packet;
}ROB_ENTRY;

typedef struct packed {
	logic [6:0] opcode;
	ALU_OPA_SELECT opa_select;
	ALU_OPB_SELECT opb_select;
	ALU_FUNC alu_opcode;
	logic rd_mem;
	logic wr_mem;
	logic cond_branch;
	logic uncond_branch;
	logic csr_op;
	logic halt;     
	logic illegal;
	DEST_REG_SEL dest_reg_sel;
	logic [31:0] extra_slot_a;
	logic [31:0] extra_slot_b;
	logic [2:0] blu_opcode;
	logic [31:0] PC;
	logic [31:0] NPC;
	logic [4:0] rs1; // fix
    logic [4:0] rs2;
	logic [2:0] mem_funct;
	logic [6:0] funct7;
} DECODE_NOREG_PACKET;

typedef struct packed {
	logic [4:0] rs1;
    logic [4:0] rs2;
	logic [4:0] dest_reg;
	DECODE_NOREG_PACKET decode_noreg_packet;
} DECODE_PACKET;


typedef struct packed {
	logic [$clog2(`PREG_NUMBER)-1: 0] source_tag_1;
	logic [$clog2(`PREG_NUMBER)-1: 0] source_tag_2;
	logic [$clog2(`PREG_NUMBER)-1: 0] dest_tag;
	DECODE_NOREG_PACKET decode_noreg_packet;
} RS_FU_PACKET;

typedef struct packed {
	logic tag_1_ready;
	logic tag_2_ready;
	RS_FU_PACKET fu_packet;
	logic RS_valid;
} RS_ENTRY;

typedef struct packed{
	logic br_cond;
	logic valid;
	logic [31:0] br_target;
	logic [$clog2(`PREG_NUMBER)-1:0] dest_tag;
	logic [1:0] prediction;
	logic [31:0] prediction_address;
} BRANCH_BUFFER_ENTRY;

typedef struct packed{
	logic br_cond;
	logic [31:0] br_target;
} BRANCH_RECOVER_OUT;

typedef struct packed{
	logic [31:0] pc;
	logic br_cond;
	logic [31:0] br_target;
} BRANCH_RECOVER_IN;

typedef struct packed{
	logic [1:0] predictor;
	logic [31:0] target;
} BTB_ENTRY;


typedef struct packed{
	logic [6:0] opcode;
	logic [`XLEN-1:0] address;
	logic [`XLEN-1:0] data;
	logic [$clog2(`PREG_NUMBER)-1: 0] dest_tag;
	logic issued_before;
	logic completed;
	logic [2:0] mem_funct;
	logic valid;
	logic [$clog2(`PREG_NUMBER)-1: 0] dependent_tag;
} LSQ_ENTRY;

typedef struct packed{
	logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] MT_entry;
	logic [`ARCHREG_NUMBER-1: 0] MT_ready;

	logic [$clog2(`FREELIST_SIZE)-1:0] FL_head;
	logic [$clog2(`FREELIST_SIZE)-1:0] FL_tail;
	logic [`FREELIST_SIZE-1:0] [$clog2(`PREG_NUMBER)-1:0] FL_entries;
	logic [`FREELIST_SIZE-1:0] FL_valid;

	logic [$clog2(`ROB_SIZE)-1:0] ROB_tail; 
	logic [$clog2(`LSQ_SIZE)-1:0] LSQ_tail;
}branch_stack_entry;

typedef struct packed{
	INST_PC [1:0]						  Fetch_debug;
	logic [`XLEN-1:0] 					  proc2Imem_addr_debug;
	
	logic [$clog2(`ROB_SIZE)-1:0]          ROB_head_debug;
	logic [$clog2(`ROB_SIZE)-1:0]          ROB_tail_debug;
    logic [$clog2(`ROB_SIZE)-1:0]          ROB_next_head_debug;
	ROB_ENTRY [`ROB_SIZE-1:0]              ROB_entries_debug;
	logic [`ROB_SIZE-1:0] 				  ROB_completed_debug;

	RS_ENTRY [`RS_LENGTH-1 : 0] RS_entries_debug;

	logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0]    MT_map_table_entry_Debug;
	logic [`ARCHREG_NUMBER-1: 0]                                MT_map_table_ready_Debug;
	
	logic [$clog2(`FREELIST_SIZE)-1:0]                    FL_head_debug;
	logic [$clog2(`FREELIST_SIZE)-1:0]                    FL_tail_debug;
	logic [$clog2(`FREELIST_SIZE)-1:0]                    FL_tail_plus_one_debug;
	logic [`FREELIST_SIZE-1:0] [$clog2(`PREG_NUMBER)-1:0] FL_entries_debug;
    logic [`FREELIST_SIZE-1:0]                            FL_valid_debug;

	logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] arch_table_entry_debug;
	
	logic [`SUPERSCALE_WIDTH-1:0]                             CDB_en_debug;
    logic [`SUPERSCALE_WIDTH-1:0] [$clog2(`PREG_NUMBER)-1: 0] CDB_o_debug;

	logic [`XLEN-1:0]                ALU_0_opa_debug;
	logic [`XLEN-1:0]                ALU_0_opb_debug;
	ALU_FUNC                         ALU_0_func_debug;
	logic [$clog2(`PREG_NUMBER)-1:0] ALU_0_dest_reg_i_debug;
	logic [$clog2(`PREG_NUMBER)-1:0] ALU_0_dest_reg_o_debug;
	logic [`XLEN-1:0]                ALU_0_result_o_debug;
    logic                            ALU_0_done_debug;

	logic [`XLEN-1:0]                ALU_1_opa_debug;
	logic [`XLEN-1:0]                ALU_1_opb_debug;
	ALU_FUNC                         ALU_1_func_debug;
	logic [$clog2(`PREG_NUMBER)-1:0] ALU_1_dest_reg_i_debug;
	logic [$clog2(`PREG_NUMBER)-1:0] ALU_1_dest_reg_o_debug;
	logic [`XLEN-1:0]                ALU_1_result_o_debug;
    logic                            ALU_1_done_debug;

	logic [`PREG_NUMBER-1:0] [`XLEN-1:0] value_RF;

	logic dispatch_en_debug;
	logic ex_en_debug;
	logic complete_debug;
	logic retire_en_debug;

	logic [`SUPERSCALE_WIDTH-1:0]                                pipeline_commit;
	logic [`SUPERSCALE_WIDTH-1:0] [$clog2(`ARCHREG_NUMBER)-1: 0] pipeline_commit_reg;
	logic [`SUPERSCALE_WIDTH-1:0] [`XLEN-1:0]                    pipeline_commit_data;
	logic [`SUPERSCALE_WIDTH-1:0] [`XLEN-1:0]                    pipeline_commit_PC;
	
	logic [1:0] retire_wr_mem_debug;
	logic [1:0] retire_rd_mem_debug;
	logic [1:0] retire_cond_branch_debug;
	logic [1:0] retire_uncond_branch_debug;
	logic [1:0] retire_halt_debug;

	logic [31:0] [63:0]                     dcache_data;
    logic [31:0] [7:0]  dcache_tags;
    logic [31:0]                            dcache_valids;
    logic [31:0]                            dcache_dirty;
	
	logic [$clog2(`LSQ_SIZE)-1:0] 		LSQ_debug_next_head;
 	logic [$clog2(`LSQ_SIZE)-1:0] 		LSQ_debug_next_retire_ptr;
	LSQ_ENTRY [`LSQ_SIZE-1:0] 			LSQ_debug_lsq_entry;
}DEBUG_SIGNAL;

`endif // __SYS_DEFS_VH__

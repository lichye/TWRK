

// `timescale 1ns/100ps

module fetch_testbench;
    logic error;
    logic clk;
    logic reset;              
	logic take_branch_i;      
	logic [`XLEN-1:0] branch_target_pc_i;
    logic [`XLEN-1:0] PC; 

	logic [1:0] PC_increment_i;       
	logic [63:0] Imem2proc_data;  

	logic [`XLEN-1:0] proc2Imem_addr;     
    INST_PC [1:0]        inst_PC_o;             

    fetch fetch(
        .clk(clk),
        .reset(reset),
        .take_branch_i    (take_branch_i    ),
        .branch_target_pc_i(branch_target_pc_i),
        .PC_increment_i      (PC_increment_i),
        .Imem2proc_data(Imem2proc_data),
        .PC (PC),

        .proc2Imem_addr    (proc2Imem_addr),
        .inst_PC_o(inst_PC_o)
    );


    // clock generation
    always begin
		#(10/2.0);
		clk = ~clk;
	end
    
    integer i;

    initial 
    begin
        clk = 1'b0;
        reset = 1'b0;
        take_branch_i = 0;
        branch_target_pc_i = 0;
        PC_increment_i = 0;
        Imem2proc_data = 0;
        `NEXT_CYCLE; 
        reset = 1'b1;
        `NEXT_CYCLE;
        reset = 1'b0;
        Imem2proc_data = {32'd4, 32'd0};
        // fetch the first two instructions
        /*
        +----+------+
        | PC | inst_PC_o |
        +----+------+ <--- PC, to_mem_addr
        | 0  | 0    |
        +----+------+
        | 4  | 4    |
        +----+------+
        | 8  | 8    |
        +----+------+
        | 12 | 12   |
        +----+------+
        | 16 | 16   |
        +----+------+
        | 20 | 20   |
        +----+------+
        | 24 | 24   |
        +----+------+
        | 28 | 28   |
        +----+------+
        | 32 | 32   |
        +----+------+
        */
        #1;
        `CHECK(inst_PC_o[0].inst, 0);
        `CHECK(inst_PC_o[1].inst, 4);
        `CHECK(proc2Imem_addr, 0);

        PC_increment_i = 2'b11;
        `NEXT_CYCLE;
        Imem2proc_data = {32'd12, 32'd8};
        // fetch the next two instruction
        /*
        +----+------+
        | PC | inst_PC_o |
        +----+------+
        | 0  | 0    |
        +----+------+
        | 4  | 4    |
        +----+------+ <--- PC. to_mem_addr
        | 8  | 8    |
        +----+------+
        | 12 | 12   |
        +----+------+
        | 16 | 16   |
        +----+------+
        | 20 | 20   |
        +----+------+
        | 24 | 24   |
        +----+------+
        | 28 | 28   |
        +----+------+
        | 32 | 32   |
        +----+------+
        */
        #1;
        `CHECK(inst_PC_o[0].inst, 8);
        `CHECK(inst_PC_o[1].inst, 12);
        `CHECK(proc2Imem_addr, 8);
        `CHECK(PC, 8);

        PC_increment_i = 2'b01;
        `NEXT_CYCLE;
        Imem2proc_data = {32'd20, 32'd16};
        // dispatch one, should fetch the second one of prev 8 byte and first of last 8 byte
        /*
        +----+------+
        | PC | inst_PC_o |
        +----+------+
        | 0  | 0    |
        +----+------+
        | 4  | 4    |
        +----+------+
        | 8  | 8    |
        +----+------+ <--- PC
        | 12 | 12   |
        +----+------+ <--- to_mem_addr
        | 16 | 16   |
        +----+------+
        | 20 | 20   |
        +----+------+
        | 24 | 24   |
        +----+------+
        | 28 | 28   |
        +----+------+
        | 32 | 32   |
        +----+------+
        */
        #1;
        `CHECK(inst_PC_o[0].inst, 12);
        `CHECK(inst_PC_o[1].inst, 16);
        `CHECK(proc2Imem_addr, 16);
        `CHECK(PC, 12);

        PC_increment_i = 2'b01;
        `NEXT_CYCLE;
        Imem2proc_data = {32'd20, 32'd16};
        // dispatch one again, both instructions come from the same 8 byte block
        /*
        +----+------+
        | PC | inst_PC_o |
        +----+------+
        | 0  | 0    |
        +----+------+
        | 4  | 4    |
        +----+------+
        | 8  | 8    |
        +----+------+
        | 12 | 12   |
        +----+------+ <--- PC, to_mem_addr
        | 16 | 16   |
        +----+------+
        | 20 | 20   |
        +----+------+
        | 24 | 24   |
        +----+------+
        | 28 | 28   |
        +----+------+
        | 32 | 32   |
        +----+------+
        */
        #1;
        `CHECK(inst_PC_o[0].inst, 16);
        `CHECK(inst_PC_o[1].inst, 20);
        `CHECK(proc2Imem_addr, 16);
        `CHECK(PC, 16);

        PC_increment_i = 2'b01;
        `NEXT_CYCLE;
        Imem2proc_data = {32'd28, 32'd24};
        // dispatch one again, should fetch the second one of prev 8 byte and first of last 8 byte
        /*
        +----+------+
        | PC | inst_PC_o |
        +----+------+
        | 0  | 0    |
        +----+------+
        | 4  | 4    |
        +----+------+
        | 8  | 8    |
        +----+------+
        | 12 | 12   |
        +----+------+ 
        | 16 | 16   |
        +----+------+ <--- PC
        | 20 | 20   |
        +----+------+ <--- to_mem_addr
        | 24 | 24   |
        +----+------+
        | 28 | 28   |
        +----+------+
        | 32 | 32   |
        +----+------+
        */
        #1;
        `CHECK(inst_PC_o[0].inst, 20);
        `CHECK(inst_PC_o[1].inst, 24);
        `CHECK(proc2Imem_addr, 24);
        `CHECK(PC, 20);

        PC_increment_i = 2'b11;
        `NEXT_CYCLE;
        Imem2proc_data = {32'd36, 32'd32};
        // dispatch two, should fetch the second one of prev 8 byte and first of last 8 byte
        /*
        +----+------+
        | PC | inst_PC_o |
        +----+------+
        | 0  | 0    |
        +----+------+
        | 4  | 4    |
        +----+------+
        | 8  | 8    |
        +----+------+
        | 12 | 12   |
        +----+------+ 
        | 16 | 16   |
        +----+------+
        | 20 | 20   |
        +----+------+
        | 24 | 24   |
        +----+------+ <--- PC
        | 28 | 28   |
        +----+------+ <--- to_mem_addr
        | 32 | 32   |
        +----+------+
        | 36 | 36   |
        +----+------+
        */
        #1;
        `CHECK(inst_PC_o[0].inst, 28);
        `CHECK(inst_PC_o[1].inst, 32);
        `CHECK(proc2Imem_addr, 32);
        `CHECK(PC, 28);
        
        $finish;
    end

endmodule

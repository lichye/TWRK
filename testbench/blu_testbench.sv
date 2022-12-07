/*
Modulename: map_table_testbench.sv

Description: Testcases for map table

TODO:
I find my problem in how to deal with the test_bench
*/


module rs_testbench;
    logic clk;
    logic reset;

  	logic [`XLEN-1:0] opa;
	logic [`XLEN-1:0] opb;
	logic [`XLEN-1:0] rs2;
	logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_i;
	DEST_REG_SEL dest_reg_sel_i;
	logic [2:0] func_br;
	logic [`XLEN-1:0] NPC_i;
	logic [`XLEN-1:0] PC_i;
	logic [6:0] inst_opcode;
	logic execute_en_i;
	logic complete_en_i;
	logic [1:0] branch_retire_en_i;
	logic [1:0] [$clog2(`PREG_NUMBER)-1:0] branch_retire_dest_reg_i;
	logic  ready_o;
	logic  [`XLEN-1:0] result_o; // complet;
	logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_o;
	DEST_REG_SEL dest_reg_sel_o;
	BRANCH_RECOVER_OUT [1:0] branch_recover_o;

	// output logic br_cond_o,
    logic done_o;

 




    logic error;

    blu blu(
		.clk(clk),
		.reset(reset),

		.opa(opa),
		.opb(opb),
		.rs2(rs2),
		.dest_reg_i(dest_reg_i),
		.dest_reg_sel_i(dest_reg_sel_i),
		.func_br(func_br),
		.NPC_i(NPC_i),
		.PC_i(PC_i),
		.inst_opcode(inst_opcode),
		.execute_en_i(execute_en_i),

		.complete_en_i(complete_en_i),
		
		.branch_retire_en_i(branch_retire_en_i),
		.branch_retire_dest_reg_i(branch_retire_dest_reg_i),
		
		.ready_o(ready_o),
		
		.result_o(result_o), // complete
		.dest_reg_o(dest_reg_o),
		.dest_reg_sel_o(dest_reg_sel_o),

		.branch_recover_o(branch_recover_o),

		// output logic br_cond_o,
		.done_o(done_o)
    );

    // clk generation
    always begin
		#(10/2.0);
		clk = ~clk;
	end

    
    initial begin
    opa = 0;
	opb = 0;
	rs2 = 0;
	dest_reg_i = 0;
	dest_reg_sel_i = 0;
	func_br = 0;
	NPC_i = 0;
	PC_i = 0;
	inst_opcode = 0;
	execute_en_i = 0;
	complete_en_i = 0;
	branch_retire_en_i = 0;
	branch_retire_dest_reg_i[0] = 0;
	branch_retire_dest_reg_i[0] = 0;
    error = 1'b0;
    clk = 1'b0;
    reset = 1'b1;
    `NEXT_CYCLE;//10
    reset = 1'b0;
    `NEXT_CYCLE;

	opa = 32'h2;
	opb = 32'h1;
	rs2 = 32'h3;
	dest_reg_i = 7'h5;
	dest_reg_sel_i = 1'b1;
	func_br = 3'b001;
	NPC_i = 32'h8;
	PC_i = 32'h4;
	inst_opcode = 7'b1100011;
	execute_en_i = 1'b1;
	complete_en_i = 1'b0;
	branch_retire_en_i = 2'b00;
	branch_retire_dest_reg_i[0] = 7'h5;
	branch_retire_dest_reg_i[0] = 7'h6;	
	
	//testcase1 test J jump
    `NEXT_CYCLE;
	execute_en_i = 0;
	`CHECK(done_o, 1);
	`CHECK(ready_o, 0);
    `NEXT_CYCLE;//20
	`CHECK(ready_o, 0);
    `NEXT_CYCLE;
	`CHECK(ready_o, 0);
    `NEXT_CYCLE;
	complete_en_i = 1;
    `NEXT_CYCLE;
	complete_en_i = 0;
	`CHECK(result_o, 5);
	`CHECK(dest_reg_o, 5);
	`CHECK(dest_reg_sel_o, 1);
    `NEXT_CYCLE;
	`CHECK(ready_o, 1);
    `NEXT_CYCLE;
	branch_retire_en_i = 2'b01;
	branch_retire_dest_reg_i = 5;
	#1;
	`CHECK(branch_recover_o[0].br_cond, 1);
	`CHECK(branch_recover_o[0].br_target, 5);
    `NEXT_CYCLE;
        if(!error) begin
            $display("\033[32m PASSED \033[0m");
            $display("\033[32m No Error Occurred \033[0m");
        end
        $finish;
    end
endmodule

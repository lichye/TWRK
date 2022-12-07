module alu_testbench();
    logic clk;
    logic reset;
    logic error;
	logic [`XLEN-1:0] opa;
	logic [`XLEN-1:0] opb;
	ALU_FUNC     func;
	logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_i;
    logic execute_en_i;
	logic complete_en_i;
	DEST_REG_SEL dest_reg_sel_i;

    logic [1:0] branch_recover_i;

	logic ready_o;
	logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_o;
    DEST_REG_SEL dest_reg_sel_o;
	logic regfile_wr_en_o;
	logic [`XLEN-1:0] result_o;
    logic done_o;
    logic branch_enable_i;

    alu alu(.*);

    always begin
		#(10/2.0);
		clk = ~clk;
	end

    integer i;

    initial begin
        clk = 0;
        reset = 0;
        branch_recover_i = 0;
        `NEXT_CYCLE;
        reset = 1'b1;
        `NEXT_CYCLE;
        reset = 1'b0;
        `NEXT_CYCLE;
        execute_en_i = 1;
        opa = 1;
        opb = 7;
        func = ALU_ADD;
        dest_reg_i = 5;
        dest_reg_sel_i = 0;
        #1;
        `CHECK(ready_o, 0);
        `NEXT_CYCLE;
        execute_en_i = 0;
        `CHECK(done_o, 1);
        `CHECK(result_o, 8);
        `NEXT_CYCLE;
        `CHECK(done_o, 1);
        `NEXT_CYCLE;
        `CHECK(done_o, 1);
        `NEXT_CYCLE;
        `CHECK(done_o, 1);
        `NEXT_CYCLE;
        `CHECK(done_o, 1);
        complete_en_i = 1;
        #1;
        `CHECK(ready_o, 1);
        `NEXT_CYCLE;
        `CHECK(ready_o, 1);
        `CHECK(done_o, 0);
        $finish;

    end

endmodule
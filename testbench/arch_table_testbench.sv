`define PREG_NUMBER 64
`define ARCHREG_NUMBER 32
`define NEXT_CYCLE @(negedge clk)

module arch_table_testbench;
    logic clk;
    logic reset;
    logic [`TABLE_WRITE:0] [$clog2(`ARCHREG_NUMBER)-1:0] retire_arch_reg_i;
    logic [`TABLE_WRITE:0] retire_en_i;
    logic [`TABLE_WRITE:0] [$clog2(`PREG_NUMBER)-1: 0] new_tag_i;
    logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] arch_table_recover_o;

    arch_table at(
        .clk(clk),
        .reset(reset),
        .retire_arch_reg_i(retire_arch_reg_i),
        .retire_en_i(retire_en_i),
        .new_tag_i(new_tag_i),
        .arch_table_recover_o(arch_table_recover_o)
    );

    // clock generation
    always begin
		#(10/2.0);
		clk = ~clk;
	end

    initial begin
        clk = 1'b0;
		reset = 1'b0;
        `NEXT_CYCLE;
        reset = 1'b1;
        `NEXT_CYCLE;
        reset = 1'b0;
        `NEXT_CYCLE;

        $finish;
    end
endmodule

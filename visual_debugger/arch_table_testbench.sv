`define NEXT_CYCLE @(negedge clk)

import "DPI-C" function void next_cycle();
import "DPI-C" function void print_AT_NC();
import "DPI-C" function void print_AT_ENTRY(int,int);

module arch_table_testbench;
    logic clk;
    logic reset;
    logic [`TABLE_WRITE:0] [$clog2(`ARCHREG_NUMBER)-1:0] retire_arch_reg_i;
    logic [`TABLE_WRITE:0] retire_en_i;
    logic [`TABLE_WRITE:0] [$clog2(`PREG_NUMBER)-1: 0] new_tag_i;
    logic [`TABLE_WRITE:0] [$clog2(`PREG_NUMBER)-1: 0] tag_o;
    logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] arch_table_recover_o;
    
    logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] arch_table_entry_debug;

    arch_table at(
        .clk(clk),
        .reset(reset),
        .retire_arch_reg_i(retire_arch_reg_i),
        .tag_o(tag_o),
        .retire_en_i(retire_en_i),
        .new_tag_i(new_tag_i),
        .arch_table_recover_o(arch_table_recover_o),
        .arch_table_entry_debug(arch_table_entry_debug)
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
        retire_en_i[0] = 1'b1;
        retire_arch_reg_i[0] = 7'h1;
        new_tag_i[0] = 7'h33;
        `NEXT_CYCLE;
        `NEXT_CYCLE;
        `NEXT_CYCLE;
        `NEXT_CYCLE;
        $finish;
    end

    integer pp;
    always @(negedge clk) begin
         if(reset) begin
	 		$display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
	 		         $realtime);
         end else begin
             next_cycle();
             print_AT_NC();
            for(pp=0;pp<`ARCHREG_NUMBER;pp++) begin
                print_AT_ENTRY(pp,arch_table_entry_debug[pp]);
            end
	 	end  
     end

endmodule

/*
Modulename: map_table_testbench.sv

Description: Testcases for map table

TODO:
*/
// import "DPI-C" function void print_New_Cloke();
// import "DPI-C" function void print_Map_table(int level,int entry,int ready);

// `timescale 1ns/100ps

module map_table_testbench;
    logic clk;
    logic reset;
    //debug signal
    logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] map_table_entry_Debug; // ARCHREG_NUMBER entries, each entry is $clog2(PREG_NUMBER) bits
    logic [`ARCHREG_NUMBER-1: 0] map_table_ready_Debug; // ARCHREG_NUMBER entries, each is 1 bit



    //read sign
    logic [`TABLE_READ-1:0][$clog2(`ARCHREG_NUMBER)-1:0] arch_reg_i;


    // write tag
    logic [`TABLE_WRITE-1:0][$clog2(`ARCHREG_NUMBER)-1:0] arch_reg_dest_i;
    logic [`TABLE_WRITE-1:0][$clog2(`PREG_NUMBER)-1: 0] arch_reg_dest_new_tag_i;
    logic [`TABLE_WRITE-1:0]new_tag_write_en_i;

    // wirte ready
    logic [`CDB_SIZE-1:0][$clog2(`PREG_NUMBER)-1:0] CDB_i;
    logic [`CDB_SIZE-1:0] CDB_en_i;

    // branch
    logic branch_recover_i;
    logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] arch_table_recover_i;


    //read output
    logic [`TABLE_READ-1:0][$clog2(`PREG_NUMBER)-1: 0] preg_tag_o;
    logic [`TABLE_READ-1:0] preg_ready_o;

    logic [`TABLE_WRITE-1:0] [$clog2(`PREG_NUMBER)-1: 0] preg_tag_old_o;

    integer i;

    logic error;

    map_table mt(
        .map_table_entry_Debug(map_table_entry_Debug),
        .map_table_ready_Debug(map_table_ready_Debug),
        .clk(clk),
        .reset(reset),
        .arch_reg_i(arch_reg_i),
        .arch_reg_dest_i(arch_reg_dest_i),
        .arch_reg_dest_new_tag_i(arch_reg_dest_new_tag_i),
        .new_tag_write_en_i(new_tag_write_en_i),
        .CDB_i(CDB_i),
        .CDB_en_i(CDB_en_i),
        .branch_recover_i(branch_recover_i),
        .arch_table_recover_i(arch_table_recover_i),
        .preg_tag_o(preg_tag_o),
        .preg_ready_o(preg_ready_o),
        .preg_tag_old_o(preg_tag_old_o)        
    );

    // clock generation
    always begin
		#(10/2.0);
		clk = ~clk;
	end
    //to make this test easy, we suppose there is 8 arch register
    initial begin
        clk = 1'b0;
		reset = 1'b0;
        arch_reg_i = 0;
        arch_reg_dest_i = 0;
        arch_reg_dest_new_tag_i = 0;
        new_tag_write_en_i = 0;
        CDB_i = 0;
        CDB_en_i = 0;
        branch_recover_i = 0;
        arch_table_recover_i = 0;

        `NEXT_CYCLE;
        reset = 1'b1;
        `NEXT_CYCLE;  
        reset = 1'b0;





        `NEXT_CYCLE
        //when new the map should be like
        // AR PR ready
        // 0   0  1
        // 1   1  1
        // 2   2  1
        // 3   3  1
        // 4   4  1
        // 5   5  1
        // 6   6  1
        // 7   7  1
        
        // read r4 and r1
        arch_reg_i[0] = 3'h1;//this is 7
        arch_reg_i[1] = 3'h3;
        arch_reg_i[2] = 3'h2;//this is 7
        arch_reg_i[3] = 3'h5;
        
        //write PR#8 to r0;
        arch_reg_dest_i[0] = 3'h2;
        arch_reg_dest_new_tag_i[0] = 6'h8;
        new_tag_write_en_i[0] = 1'b1;

        //write PR#9 to r7
        arch_reg_dest_i[1] = 3'h7;
        arch_reg_dest_new_tag_i[1] = 6'h9;
        new_tag_write_en_i[1] = 1'b1;
        #1;
        `CHECK(preg_tag_o[0] , 6'h1);
        `CHECK(preg_tag_o[1] , 6'h3);
        `CHECK(preg_tag_o[2] , 6'h8);
        `CHECK(preg_tag_o[3] , 6'h5);
        `CHECK(preg_ready_o[0] , 1'b1);
        `CHECK(preg_ready_o[1] , 1'b1);
        `CHECK(preg_ready_o[2] , 1'b0);
        `CHECK(preg_ready_o[3] , 1'b1);
        `CHECK(preg_tag_old_o[0], 2);
        `CHECK(preg_tag_old_o[1], 7);

        $finish;

        `NEXT_CYCLE;

        // AR PR  Ready
        // 0   8  0
        // 1   1  1
        // 2   2  1
        // 3   3  1
        // 4   4  1
        // 5   5  1
        // 6   6  1
        // 7   9  0  <-PR#9+
        
        // read r0 r7
        arch_reg_i[0] = 3'h0;
        arch_reg_i[1] = 3'h7;


        //CDB_i write back PR#9 to ready
        CDB_i[0] = 6'h9;
        CDB_en_i[0] = 1'b1;

        //write PR#10 to r2;
        arch_reg_dest_i[0] = 3'h2;
        arch_reg_dest_new_tag_i[0] = 6'ha;
        new_tag_write_en_i[0] = 1'b1;

        //write PR#11 to r5
        arch_reg_dest_i[1] = 3'h5;
        arch_reg_dest_new_tag_i[1] = 6'h11;
        new_tag_write_en_i[1] = 1'b1;

        #1
        `CHECK(preg_tag_o[0] , 6'h8);
        `CHECK(preg_tag_o[1] , 6'h9);
        `CHECK(preg_ready_o[0] , 1'b0);
        `CHECK(preg_ready_o[1] , 1'b1);

        `NEXT_CYCLE

        // AR PR  Ready
        // 0   8  0
        // 1   1  1
        // 2   a  0
        // 3   3  1
        // 4   4  1
        // 5   b  0
        // 6   6  1
        // 7   9  1

        //read r2 r7
        arch_reg_i[0] = 3'h2;
        arch_reg_i[1] = 3'h7;

         #1
        `CHECK(preg_tag_o[0] , 6'ha);
        `CHECK(preg_tag_o[1] , 6'h9);
        `CHECK(preg_ready_o[0] , 1'b0);
        `CHECK(preg_ready_o[1] , 1'b1);

        `NEXT_CYCLE
        $finish;
    end
    integer j;

    //  always @(negedge clk) begin
    //     if(reset) begin
	// 		$display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
	// 		         $realtime);
    //     end else begin
    //         print_New_Cloke();
    //         for(int j=0;j<`ARCHREG_NUMBER;j++) begin
    //             print_Map_table(j,map_table_entry_Debug[j],map_table_ready_Debug[j]);
    //         end
            
	// 	end  // if(reset)
    // end

endmodule
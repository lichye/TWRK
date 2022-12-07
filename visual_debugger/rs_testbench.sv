/*
Modulename: map_table_testbench.sv

Description: Testcases for map table

TODO:
I find my problem in how to deal with the test_bench
*/
import "DPI-C" function void next_cycle();
import "DPI-C" function void print_RS_NC();
import "DPI-C" function void print_RS_ENTRY(int,int,int,int,int,int,int);

module rs_testbench;
    logic clk;
    logic reset;
    logic dispatch_enable_i;
    logic writeback_enable_i;
    logic issue_enable_i;
    logic branch_enable_i;

    logic width_i;//superscale width
    INST [`SUPERSCALE_WIDTH - 1 : 0] inst_input_i;//Dispatch: from ROB
    logic [`SUPERSCALE_WIDTH - 1 : 0] [$clog2(`PREG_NUMBER)-1: 0] Physical_dest_register_input_i;//Dispatch: from Freelist
    logic [`SUPERSCALE_WIDTH - 1 : 0] [$clog2(`PREG_NUMBER)-1: 0] Physical_tag1_register_input_i;//Dispatch: from Maptable
    logic [`SUPERSCALE_WIDTH - 1 : 0] Physical_tag1_valid_input_i; //Dispatch: from Maptable
    logic [`SUPERSCALE_WIDTH - 1 : 0] [$clog2(`PREG_NUMBER)-1: 0] Physical_tag2_register_input_i;//Dispatch: from Maptable
    logic [`SUPERSCALE_WIDTH - 1 : 0] Physical_tag2_valid_input_i; //Dispatch: from Maptbale
    logic [`SUPERSCALE_WIDTH - 1 : 0] [$clog2(`PREG_NUMBER)-1: 0] CDB_i;//WB: from CDB
    logic fu_i;//issue: from ALU
    RS_ENTRY rs_entries_debug [`RS_LENGTH];

    logic RS_full_o;//To ROB, FreeList, Map_table
    logic [`RS_LENGTH-1 : 0] legal_issue_o; //Issue: To RSF, this is a valid instruction
    INST [`SUPERSCALE_WIDTH - 1 : 0] instruction_output_o; //Ex: To FU
    logic [`SUPERSCALE_WIDTH - 1 : 0] [$clog2(`PREG_NUMBER)-1: 0] Physical_dest_register_output_o;//Ex: To Ex
    logic [`SUPERSCALE_WIDTH - 1 : 0] [$clog2(`PREG_NUMBER)-1: 0] Physical_tag1_register_output_o;//Issue: To PRF
    logic [`SUPERSCALE_WIDTH - 1 : 0] [$clog2(`PREG_NUMBER)-1: 0] Physical_tag2_register_output_o;//Issue: To PRF


    logic error;

    rs rs(
    .clk(clk),
    .reset(reset),
    .dispatch_enable_i(dispatch_enable_i),
    .writeback_enable_i(writeback_enable_i),
    .issue_enable_i(issue_enable_i),
    .width_i(width_i),
    .inst_input_i(inst_input_i),
    .branch_enable_i(branch_enable_i),
    .Physical_dest_register_input_i(Physical_dest_register_input_i),
    .Physical_tag1_register_input_i(Physical_tag1_register_input_i),
    .Physical_tag1_valid_input_i(Physical_tag1_valid_input_i), //Dispatch: from Maptable
    .Physical_tag2_register_input_i(Physical_tag2_register_input_i),//Dispatch: from Maptable
    .Physical_tag2_valid_input_i(Physical_tag2_valid_input_i), //Dispatch: from Maptbale
    .CDB_i(CDB_i),//WB: from CDB
    .fu_i(fu_i),//issue: from ALU


    .RS_full_o(RS_full_o),//To ROB, FreeList, Map_table
    .legal_issue_o(legal_issue_o), //Issue: To RSF, this is a valid instruction
    .instruction_output_o(instruction_output_o), //Ex: To FU
    .Physical_dest_register_output_o(Physical_dest_register_output_o),//Ex: To Ex
    .Physical_tag1_register_output_o(Physical_tag1_register_output_o),//Issue: To PRF
    .Physical_tag2_register_output_o(Physical_tag2_register_output_o),//Issue: To PRF
    .rs_entries_debug(rs_entries_debug)
    );

    // clk generation
    always begin
		#(10/2.0);
		clk = ~clk;
	end

    always @(error) begin
        if(error) begin
            $display("\033[31m Error Occurred \033[0m");
            $finish;
        end
    end
    
    initial begin
    fu_i = 1'b1;
    branch_enable_i = 0;
    Physical_dest_register_input_i = 0;
    Physical_tag1_register_input_i = 0;
    Physical_tag2_register_input_i = 0;
    CDB_i = 0;
    fu_i = 1;
    Physical_tag1_valid_input_i = 0;
    Physical_tag2_valid_input_i = 0;
    inst_input_i = {0,0};
    dispatch_enable_i =  0;
	issue_enable_i =  0;
	writeback_enable_i =  0;
	width_i = 1'b1;
    error = 1'b0;
    clk = 1'b0;
	reset = 1'b1;
    `NEXT_CYCLE//10
    reset = 1'b0;

    //testcase1: test for both ready rega and regb
    `NEXT_CYCLE//20	
	dispatch_enable_i = 1'b1;
    writeback_enable_i = 1;
    issue_enable_i = 1;
    //instruction_input = 32'b1;
    Physical_dest_register_input_i[0] = 7'h1;
    Physical_tag1_register_input_i[0] = 7'h2;
    Physical_tag2_register_input_i[0] = 7'h3;
    Physical_tag1_valid_input_i[0] = 1'b1;
    Physical_tag2_valid_input_i[0] = 1'b1;
	inst_input_i[0] = 2'b01;
	Physical_dest_register_input_i[1] = 7'h4;
    Physical_tag1_register_input_i[1] = 7'h5;
    Physical_tag2_register_input_i[1] = 7'h6;
    Physical_tag1_valid_input_i[1] = 1'b1;
    Physical_tag2_valid_input_i[1] = 1'b1;
	inst_input_i[1] = 2'b11;
    `NEXT_CYCLE
    dispatch_enable_i = 1'b1;
    Physical_dest_register_input_i[0] = 7'h4;
    Physical_tag1_register_input_i[0] = 7'h5;
    Physical_tag2_register_input_i[0] = 7'h6;
    Physical_tag1_valid_input_i[0] = 1'b1;
    Physical_tag2_valid_input_i[0] = 1'b1;
	inst_input_i[0] = 2'b01;
	Physical_dest_register_input_i[1] = 7'h1;
    Physical_tag1_register_input_i[1] = 7'h2;
    Physical_tag2_register_input_i[1] = 7'h3;
    Physical_tag1_valid_input_i[1] = 1'b1;
    Physical_tag2_valid_input_i[1] = 1'b1;
	inst_input_i[1] = 2'b11;
    //then the table is like this:
    /*
        Table now
        inst dest tag1 tag2
        1 1    1    2+   3+
        2 11   4    5+   6+
        3 -    -    -    -
        4 -    -    -    - 
        */   
	`NEXT_CYCLE//40
    dispatch_enable_i = 1'b1;
    Physical_dest_register_input_i[0] = 7'h1;
    Physical_tag1_register_input_i[0] = 7'h2;
    Physical_tag2_register_input_i[0] = 7'h3;
    Physical_tag1_valid_input_i[0] = 1'b1;
    Physical_tag2_valid_input_i[0] = 1'b1;
	inst_input_i[0] = 2'b01;
	Physical_dest_register_input_i[1] = 7'h4;
    Physical_tag1_register_input_i[1] = 7'h5;
    Physical_tag2_register_input_i[1] = 7'h6;
    Physical_tag1_valid_input_i[1] = 1'b1;
    Physical_tag2_valid_input_i[1] = 1'b1;
    //then the table is like this:
    /*
        Table now
        inst dest tag1 tag2
        1 -    -    -    -     
        2 -    -    -    -     
        3 1    4    5+   6+
        4 11   1    2+   3+ 
        */
    `CHECK(legal_issue_o[0], 1'h1);
    `CHECK(legal_issue_o[1], 1'h1);
    `CHECK(Physical_dest_register_output_o[0], 7'h1);
    `CHECK(Physical_dest_register_output_o[1], 7'h4);
	`NEXT_CYCLE//50
    dispatch_enable_i = 1'b1;
    Physical_dest_register_input_i[0] = 7'h4;
    Physical_tag1_register_input_i[0] = 7'h5;
    Physical_tag2_register_input_i[0] = 7'h6;
    Physical_tag1_valid_input_i[0] = 1'b1;
    Physical_tag2_valid_input_i[0] = 1'b1;
	inst_input_i[0] = 2'b01;
	Physical_dest_register_input_i[1] = 7'h1;
    Physical_tag1_register_input_i[1] = 7'h2;
    Physical_tag2_register_input_i[1] = 7'h3;
    Physical_tag1_valid_input_i[1] = 1'b1;
    Physical_tag2_valid_input_i[1] = 1'b1;
	inst_input_i[1] = 2'b11;
    //then the table is like this:
    /*
        Table now
        inst dest tag1 tag2
        1 1    1    2+   3+
        2 11   4    5+   6+
        3 -    -    -    -
        4 -    -    -    - 
        */ 
    `CHECK(legal_issue_o[2], 1'h1);
    `CHECK(legal_issue_o[3], 1'h1);
    `CHECK(Physical_dest_register_output_o[0], 7'h4);
    `CHECK(Physical_dest_register_output_o[1], 7'h1);
	`NEXT_CYCLE//60
     Physical_dest_register_input_i[0] = 7'h1;
    Physical_tag1_register_input_i[0] = 7'h2;
    Physical_tag2_register_input_i[0] = 7'h3;
    Physical_tag1_valid_input_i[0] = 1'b1;
    Physical_tag2_valid_input_i[0] = 1'b1;
	inst_input_i[0] = 2'b01;
	Physical_dest_register_input_i[1] = 7'h4;
    Physical_tag1_register_input_i[1] = 7'h5;
    Physical_tag2_register_input_i[1] = 7'h6;
    Physical_tag1_valid_input_i[1] = 1'b1;
    Physical_tag2_valid_input_i[1] = 1'b1;
    //then the table is like this:
    /*
        Table now
        inst dest tag1 tag2
        1 -    -    -    -     
        2 -    -    -    -     
        3 1    4    5+   6+
        4 11   1    2+   3+ 
        */
    `CHECK(legal_issue_o[0], 1'h1);
    `CHECK(legal_issue_o[1], 1'h1);
    `CHECK(Physical_dest_register_output_o[0], 7'h1);
    `CHECK(Physical_dest_register_output_o[1], 7'h4);    
	`NEXT_CYCLE//70
    dispatch_enable_i = 1'b1;
    Physical_dest_register_input_i[0] = 7'h4;
    Physical_tag1_register_input_i[0] = 7'h5;
    Physical_tag2_register_input_i[0] = 7'h6;
    Physical_tag1_valid_input_i[0] = 1'b1;
    Physical_tag2_valid_input_i[0] = 1'b1;
	inst_input_i[0] = 2'b01;
	Physical_dest_register_input_i[1] = 7'h1;
    Physical_tag1_register_input_i[1] = 7'h2;
    Physical_tag2_register_input_i[1] = 7'h3;
    Physical_tag1_valid_input_i[1] = 1'b1;
    Physical_tag2_valid_input_i[1] = 1'b1;
	inst_input_i[1] = 2'b11;
	//then the table is like this:
    /*
        Table now
        inst dest tag1 tag2
        1 1    1    2+   3+
        2 11   4    5+   6+
        3 -    -    -    -
        4 -    -    -    - 
        */ 
    `CHECK(legal_issue_o[2], 1'h1);
    `CHECK(legal_issue_o[3], 1'h1);
    `CHECK(Physical_dest_register_output_o[0], 7'h4);
    `CHECK(Physical_dest_register_output_o[1], 7'h1);
	`NEXT_CYCLE//80
    dispatch_enable_i = 1'b0;
    //then the table is like this:
    /*
        Table now
        inst dest tag1 tag2
        1 -    -    -    -     
        2 -    -    -    -     
        3 1    4    5+   6+
        4 11   1    2+   3+ 
        */
    `CHECK(legal_issue_o[0], 1'h1);
    `CHECK(legal_issue_o[1], 1'h1);
    `CHECK(Physical_dest_register_output_o[0], 7'h1);
    `CHECK(Physical_dest_register_output_o[1], 7'h4); 
	`NEXT_CYCLE//90
    //then the table is like this:
    /*
        Table now
        inst dest tag1 tag2
        1 1    1    2+   3+
        2 11   4    5+   6+
        3 -    -    -    -
        4 -    -    -    - 
        */
    `CHECK(legal_issue_o[2], 1'h1);
    `CHECK(legal_issue_o[3], 1'h1);
    `CHECK(Physical_dest_register_output_o[0], 7'h4);
    `CHECK(Physical_dest_register_output_o[1], 7'h1);
    `NEXT_CYCLE//100
    //then the table is like this:
    /*
        Table now
        inst dest tag1 tag2
        1 -    -    -    -
        2 -    -    -    -
        3 -    -    -    -
        4 -    -    -    - 
        */
    `CHECK(Physical_dest_register_output_o[0], 7'h4);
    `CHECK(Physical_dest_register_output_o[1], 7'h1); 
	`NEXT_CYCLE//110
    `CHECK(Physical_dest_register_output_o[0], 7'h4);
    `CHECK(Physical_dest_register_output_o[1], 7'h1);
    `NEXT_CYCLE//120
    `NEXT_CYCLE//130

    //testcase 2: test for cbd for each rega and regb
    dispatch_enable_i = 1'b1;
    Physical_dest_register_input_i[0] = 7'h4;
    Physical_tag1_register_input_i[0] = 7'h5;
    Physical_tag2_register_input_i[0] = 7'h6;
    Physical_tag1_valid_input_i[0] = 1'b1;
    Physical_tag2_valid_input_i[0] = 1'b1;
	inst_input_i[0] = 2'b01;
	Physical_dest_register_input_i[1] = 7'h1;
    Physical_tag1_register_input_i[1] = 7'h2;
    Physical_tag2_register_input_i[1] = 7'h3;
    Physical_tag1_valid_input_i[1] = 1'b1;
    Physical_tag2_valid_input_i[1] = 1'b1;
	inst_input_i[1] = 2'b11;
    `NEXT_CYCLE//140
    Physical_dest_register_input_i[0] = 7'h11;
    Physical_tag1_register_input_i[0] = 7'h4;
    Physical_tag2_register_input_i[0] = 7'h1;
    Physical_tag1_valid_input_i[0] = 1'b0;
    Physical_tag2_valid_input_i[0] = 1'b0;
	inst_input_i[0] = 2'b01;
	Physical_dest_register_input_i[1] = 7'h12;
    Physical_tag1_register_input_i[1] = 7'h4;
    Physical_tag2_register_input_i[1] = 7'h1;
    Physical_tag1_valid_input_i[1] = 1'b0;
    Physical_tag2_valid_input_i[1] = 1'b0;
	inst_input_i[1] = 2'b11;
    CDB_i[0] = 7'h1;
    CDB_i[1] = 7'h4;
    //then the table is like this:
    /*
        Table now
        inst dest tag1 tag2
        1 11   4    5+   6+
        2 1    1    2+   3+
        3 -    -    -    -
        4 -    -    -    - 
        */
    `CHECK(legal_issue_o[2], 1'h0);
    `CHECK(legal_issue_o[3], 1'h0);
    `NEXT_CYCLE//150
    //then the table is like this:
    /*
        Table now
        inst dest tag1 tag2
        1 -    -    -    -     
        2 -    -    -    -     
        3 1    11   4+   1+
        4 11   12   1+   4+ 
        */
    `CHECK(legal_issue_o[1], 1'h1);
    `CHECK(legal_issue_o[0], 1'h1);
    `CHECK(Physical_dest_register_output_o[0], 7'h4);
    `CHECK(Physical_dest_register_output_o[1], 7'h1);
    `NEXT_CYCLE
    `CHECK(legal_issue_o[2], 1'h1);
    `CHECK(legal_issue_o[3], 1'h1);
    `CHECK(Physical_dest_register_output_o[0], 7'h11);
    `CHECK(Physical_dest_register_output_o[1], 7'h12);
    `NEXT_CYCLE
    `NEXT_CYCLE
    //testcase3: for full
    Physical_dest_register_input_i[0] = 7'h11;
    Physical_tag1_register_input_i[0] = 7'h4;
    Physical_tag2_register_input_i[0] = 7'h1;
    Physical_tag1_valid_input_i[0] = 1'b0;
    Physical_tag2_valid_input_i[0] = 1'b0;
	inst_input_i[0] = 2'b01;
	Physical_dest_register_input_i[1] = 7'h12;
    Physical_tag1_register_input_i[1] = 7'h4;
    Physical_tag2_register_input_i[1] = 7'h1;
    Physical_tag1_valid_input_i[1] = 1'b0;
    Physical_tag2_valid_input_i[1] = 1'b0;
	inst_input_i[1] = 2'b11;
    CDB_i[0] = 7'h0;
    CDB_i[1] = 7'h0;
    `NEXT_CYCLE
    Physical_dest_register_input_i[0] = 7'h11;
    Physical_tag1_register_input_i[0] = 7'h4;
    Physical_tag2_register_input_i[0] = 7'h1;
    Physical_tag1_valid_input_i[0] = 1'b0;
    Physical_tag2_valid_input_i[0] = 1'b0;
	inst_input_i[0] = 2'b01;
	Physical_dest_register_input_i[1] = 7'h12;
    Physical_tag1_register_input_i[1] = 7'h4;
    Physical_tag2_register_input_i[1] = 7'h1;
    Physical_tag1_valid_input_i[1] = 1'b0;
    Physical_tag2_valid_input_i[1] = 1'b0;
	inst_input_i[1] = 2'b11;
    `NEXT_CYCLE
    dispatch_enable_i = 1'b0;
    `CHECK(RS_full_o, 1'h1);
    `NEXT_CYCLE
    `NEXT_CYCLE
    `NEXT_CYCLE
    //testcase5: use CDB_i to make data become ready 
    CDB_i[0] = 7'h1;
    CDB_i[1] = 7'h4;
    `NEXT_CYCLE
    `CHECK(legal_issue_o[1], 1'h1);
    `CHECK(legal_issue_o[0], 1'h1);
    `CHECK(Physical_dest_register_output_o[0], 7'h11);
    `CHECK(Physical_dest_register_output_o[1], 7'h12);
    `NEXT_CYCLE
    `CHECK(legal_issue_o[2], 1'h1);
    `CHECK(legal_issue_o[3], 1'h1);
    `CHECK(Physical_dest_register_output_o[0], 7'h11);
    `CHECK(Physical_dest_register_output_o[1], 7'h12);
    `NEXT_CYCLE
    `NEXT_CYCLE
    `NEXT_CYCLE
    //testcase5: for branch
    dispatch_enable_i = 1'b1;
    Physical_dest_register_input_i[0] = 7'h11;
    Physical_tag1_register_input_i[0] = 7'h4;
    Physical_tag2_register_input_i[0] = 7'h1;
    Physical_tag1_valid_input_i[0] = 1'b0;
    Physical_tag2_valid_input_i[0] = 1'b0;
	inst_input_i[0] = 2'b01;
	Physical_dest_register_input_i[1] = 7'h12;
    Physical_tag1_register_input_i[1] = 7'h4;
    Physical_tag2_register_input_i[1] = 7'h1;
    Physical_tag1_valid_input_i[1] = 1'b0;
    Physical_tag2_valid_input_i[1] = 1'b0;
	inst_input_i[1] = 2'b11;
    CDB_i[0] = 7'h0;
    CDB_i[1] = 7'h0;
    `NEXT_CYCLE
    Physical_dest_register_input_i[0] = 7'h11;
    Physical_tag1_register_input_i[0] = 7'h4;
    Physical_tag2_register_input_i[0] = 7'h1;
    Physical_tag1_valid_input_i[0] = 1'b0;
    Physical_tag2_valid_input_i[0] = 1'b0;
	inst_input_i[0] = 2'b01;
	Physical_dest_register_input_i[1] = 7'h12;
    Physical_tag1_register_input_i[1] = 7'h4;
    Physical_tag2_register_input_i[1] = 7'h1;
    Physical_tag1_valid_input_i[1] = 1'b0;
    Physical_tag2_valid_input_i[1] = 1'b0;
	inst_input_i[1] = 2'b11;
    `NEXT_CYCLE
    dispatch_enable_i = 1'b0;
    `CHECK(RS_full_o, 1'h1);
    `NEXT_CYCLE
    `NEXT_CYCLE
    branch_enable_i = 1;
    `NEXT_CYCLE
    `CHECK(RS_full_o, 7'h0);
    `NEXT_CYCLE
    `NEXT_CYCLE
    `NEXT_CYCLE
        $display("\033[32m PASSED \033[0m");
        $display("\033[32m No Error Occurred \033[0m");
        $finish;
    end

    integer pp;
    always @(negedge clk) begin
         if(reset) begin
	 		$display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
	 		         $realtime);
         end else begin
             next_cycle();
             print_RS_NC();
            for(pp=0;pp<`RS_LENGTH;pp++) begin
                print_RS_ENTRY(
                                rs_entries_debug[pp].RS_valid,
                                rs_entries_debug[pp].inst,
                                rs_entries_debug[pp].physical_dest_tag,
                                rs_entries_debug[pp].physical_tag1,
                                rs_entries_debug[pp].physical_tag1_valid,
                                rs_entries_debug[pp].physical_tag2,
                                rs_entries_debug[pp].physical_tag2_valid);
            end
	 	end  
     end
endmodule

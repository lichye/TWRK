/*
Modulename: map_table_testbench.sv

Description: Testcases for map table

TODO:
I find my problem in how to deal with the test_bench
*/


module rs_testbench;
    logic clk;
    logic reset;

    logic [1:0]                                                     dispatch_en_i;
    logic [`SUPERSCALE_WIDTH - 1 :0] [$clog2(`PREG_NUMBER) - 1 : 0] dest_tag_i;     // Dispatch: from Freelist
    logic [`SUPERSCALE_WIDTH - 1 :0] [$clog2(`PREG_NUMBER) - 1 : 0] source_tag_1_i; // Dispatch: from Maptable
    logic [`SUPERSCALE_WIDTH - 1 : 0]                               ready_1_i;      // Dispatch: from Maptable
    logic [`SUPERSCALE_WIDTH - 1 :0] [$clog2(`PREG_NUMBER) - 1 : 0] source_tag_2_i; // Dispatch: from Maptable
    logic [`SUPERSCALE_WIDTH - 1 : 0]                               ready_2_i;     // Dispatch: from Maptbale
    DECODE_PACKET [`SUPERSCALE_WIDTH - 1 :0]                        RS_decode_noreg_packet;

    logic [1:0]                                                          branch_recover_i; //enable for branch
    logic [`SUPERSCALE_WIDTH - 1 : 0] [$clog2(`PREG_NUMBER)-1 : 0]  CDB_i;//WB: from CDB
    logic [1:0]                                                     CDB_en_i;

    logic [`FU_NUMBER-1:0]                                          fu_ready_i; //issue: from ALU

    logic [1:0]                                                    RS_full_o;  // To control
    logic [`RS_LENGTH-1 : 0]                                       execute_en_o; // Issue: To FU
    RS_FU_PACKET [`SUPERSCALE_WIDTH - 1 : 0]                       FU_packet_o;   // Issue: To FU
    logic [`FU_NUMBER-1:0]                                         FU_select_o;

 




    logic error;

    rs rs(
    .clk(clk),
    .reset(reset),
    .dispatch_en_i(dispatch_en_i),
    .dest_tag_i(dest_tag_i),
    .source_tag_1_i(source_tag_1_i),
    .ready_1_i(ready_1_i),
    .source_tag_2_i(source_tag_2_i),
    .ready_2_i(ready_2_i),
    .RS_decode_noreg_packet(RS_decode_noreg_packet),
    .branch_recover_i(branch_recover_i),
    .CDB_i(CDB_i),
    .CDB_en_i(CDB_en_i),
    .fu_ready_i(fu_ready_i),
    .RS_full_o(RS_full_o),
    .execute_en_o(execute_en_o),
    .FU_packet_o(FU_packet_o),
    .FU_select_o(FU_select_o)
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
    branch_recover_i = 0;
    dest_tag_i = 0;
    RS_decode_noreg_packet = 0;
    source_tag_1_i = 0;
    ready_2_i = 0;
    CDB_i = 0;
    ready_1_i = 0;
    source_tag_2_i = 0;
    fu_ready_i = 0;
    dispatch_en_i =  0;
	CDB_en_i =  0;
    error = 1'b0;
    clk = 1'b0;
	reset = 1'b1;
    `NEXT_CYCLE;//10
    reset = 1'b0;
    `NEXT_CYCLE;//20
    //testcase1: test for both ready rega and regb
    dispatch_en_i = 2'b11;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h4;
    source_tag_1_i[0] = 7'h4;
    source_tag_2_i[0] = 7'h3;
    source_tag_1_i[1] = 7'h2;
    source_tag_2_i[1] = 7'h1;
    ready_2_i[0] = 1'b1;
    ready_1_i[0] = 1'b1;
    ready_2_i[1] = 1'b1;
    ready_1_i[1] = 1'b1;
    fu_ready_i = 2'b11;

    `NEXT_CYCLE;//30
    //then the table is like this:
    /*
        Table now
        packet dest tag1 tag2
        1 0    1    4+   3+
        2 0    4    2+   1+
        3 -    -    -    -
        4 -    -    -    - 
        */   
    `CHECK(RS_full_o, MORE_LEFT);
    `CHECK(execute_en_o, 2'b00);
    `CHECK(FU_packet_o[0], 0);

    dispatch_en_i = 2'b11;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h6;
    source_tag_1_i[0] = 7'h8;
    source_tag_2_i[0] = 7'h7;
    source_tag_1_i[1] = 7'h6;
    source_tag_2_i[1] = 7'h5;
    ready_2_i[0] = 1'b1;
    ready_1_i[0] = 1'b1;
    ready_2_i[1] = 1'b1;
    ready_1_i[1] = 1'b1;
    fu_ready_i = 2'b11;
    
    `NEXT_CYCLE;//40
    //then the table is like this:
    /*
        Table now
        packet dest tag1 tag2
        1 0    1    8+   7+
        2 0    6    6+   5+
        3 -    -    -    - 
        4 -    -    -    - 
        */
    `CHECK(RS_full_o, MORE_LEFT);
    `CHECK(FU_packet_o[0].source_tag_1, 7'h4);
    `CHECK(execute_en_o, 2'b11);

    dispatch_en_i = 2'b11;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h4;
    source_tag_1_i[0] = 7'h4;
    source_tag_2_i[0] = 7'h3;
    source_tag_1_i[1] = 7'h2;
    source_tag_2_i[1] = 7'h1;
    ready_2_i[0] = 1'b1;
    ready_1_i[0] = 1'b1;
    ready_2_i[1] = 1'b1;
    ready_1_i[1] = 1'b1;
    fu_ready_i = 2'b11;
     
    `NEXT_CYCLE;
     //then the table is like this:
    /*
        Table now
        packet dest tag1 tag2
        1 0    1    4+   3+
        2 0    4    2+   1+
        3 -    -    -    -
        4 -    -    -    - 
        */ 
    `CHECK(RS_full_o, MORE_LEFT);
    `CHECK(FU_packet_o[0].source_tag_1, 7'h8);
    `CHECK(FU_packet_o[1].source_tag_1, 7'h6);
    `CHECK(execute_en_o, 2'b11);

   

    dispatch_en_i = 2'b11;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h6;
    source_tag_1_i[0] = 7'h8;
    source_tag_2_i[0] = 7'h7;
    source_tag_1_i[1] = 7'h6;
    source_tag_2_i[1] = 7'h5;
    ready_2_i[0] = 1'b1;
    ready_1_i[0] = 1'b1;
    ready_2_i[1] = 1'b1;
    ready_1_i[1] = 1'b1;
    fu_ready_i = 2'b11;
    
    `NEXT_CYCLE;
    //then the table is like this:
        /*
            Table now
            packet dest tag1 tag2
            1 0    1    8+   7+
            2 0    6    6+   5+
            3 -    -    -    -
            4 -    -    -    -
            */
    `CHECK(RS_full_o, MORE_LEFT);
    `CHECK(FU_packet_o[0].source_tag_1, 7'h4);
    `CHECK(execute_en_o, 2'b11);

    dispatch_en_i = 2'b11;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h4;
    source_tag_1_i[0] = 7'h4;
    source_tag_2_i[0] = 7'h3;
    source_tag_1_i[1] = 7'h2;
    source_tag_2_i[1] = 7'h1;
    ready_2_i[0] = 1'b1;
    ready_1_i[0] = 1'b1;
    ready_2_i[1] = 1'b1;
    ready_1_i[1] = 1'b1;
    fu_ready_i = 2'b11;
     
    `NEXT_CYCLE;
    //then the table is like this:
    /*
        Table now
        packet dest tag1 tag2
        1 0    1    4+   3+
        2 0    4    2+   1+
        3 -    -    -    -
        4 -    -    -    - 
        */
    `CHECK(RS_full_o, MORE_LEFT);
    `CHECK(FU_packet_o[0].source_tag_1, 7'h8);
    `CHECK(FU_packet_o[1].source_tag_1, 7'h6);
    `CHECK(FU_packet_o[0].source_tag_2, 7'h7);
    `CHECK(FU_packet_o[1].source_tag_2, 7'h5);
    `CHECK(execute_en_o, 2'b11);

    dispatch_en_i = 2'b11;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h6;
    source_tag_1_i[0] = 7'h8;
    source_tag_2_i[0] = 7'h7;
    source_tag_1_i[1] = 7'h6;
    source_tag_2_i[1] = 7'h5;
    ready_2_i[0] = 1'b1;
    ready_1_i[0] = 1'b1;
    ready_2_i[1] = 1'b1;
    ready_1_i[1] = 1'b1;
    fu_ready_i = 2'b11;
    `NEXT_CYCLE;
    dispatch_en_i = 2'b00;
    //then the table is like this:
    /*
        Table now
        packet dest tag1 tag2
        1 0    1    4+   3+
        2 0    4    2+   1+
        3 -    -    -    -
        4 -    -    -    - 
        */
    `CHECK(RS_full_o, MORE_LEFT);
    `CHECK(FU_packet_o[0].source_tag_1, 7'h4);
    `CHECK(FU_packet_o[1].source_tag_1, 7'h2);
    `CHECK(FU_packet_o[0].source_tag_2, 7'h3);
    `CHECK(FU_packet_o[1].source_tag_2, 7'h1);
    `CHECK(execute_en_o, 2'b11);
    `NEXT_CYCLE;
    `CHECK(execute_en_o, 2'b11);
    `NEXT_CYCLE;
    `CHECK(execute_en_o, 2'b00);
    `NEXT_CYCLE;
    `CHECK(execute_en_o, 2'b00);
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `CHECK(RS_full_o, MORE_LEFT);
    //testcase1: table full
    dispatch_en_i = 2'b11;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h4;
    source_tag_1_i[0] = 7'h4;
    source_tag_2_i[0] = 7'h3;
    source_tag_1_i[1] = 7'h2;
    source_tag_2_i[1] = 7'h1;
    ready_2_i[0] = 1'b0;
    ready_1_i[0] = 1'b1;
    ready_2_i[1] = 1'b1;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    

    `NEXT_CYCLE;
    `CHECK(execute_en_o, 2'b00);
    `CHECK(FU_packet_o[0].source_tag_1, 7'h0);
    `CHECK(FU_packet_o[1].source_tag_1, 7'h0);
    `CHECK(FU_packet_o[0].source_tag_2, 7'h0);
    `CHECK(FU_packet_o[1].source_tag_2, 7'h0);
    //then the table is like this:
    /*
        Table now
        packet dest tag1 tag2
        1 0    1    4    3
        2 0    4    2    1
        3 -    -    -    -
        4 -    -    -    - 
        */
    dispatch_en_i = 2'b11;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h6;
    source_tag_1_i[0] = 7'h8;
    source_tag_2_i[0] = 7'h7;
    source_tag_1_i[1] = 7'h6;
    source_tag_2_i[1] = 7'h5;
    ready_2_i[0] = 1'b0;
    ready_1_i[0] = 1'b1;
    ready_2_i[1] = 1'b1;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    
    `NEXT_CYCLE;
    dispatch_en_i = 2'b00;
    `CHECK(FU_packet_o[0].source_tag_1, 7'h0);
    `CHECK(FU_packet_o[1].source_tag_1, 7'h0);
    `CHECK(FU_packet_o[0].source_tag_2, 7'h0);
    `CHECK(FU_packet_o[1].source_tag_2, 7'h0);
    //then the table is like this:
    /*
        Table now
        packet dest tag1 tag2
        1 0    1    4    3
        2 0    4    2    1
        3 0    1    8    7
        4 0    6    6    5
        */
    `CHECK(RS_full_o, FULL);
    `NEXT_CYCLE;
     CDB_en_i = 2'b11;//clean full step1
     CDB_i[0] = 7'h7;
     CDB_i[1] = 7'h6;
    `NEXT_CYCLE;
    `CHECK(execute_en_o, 2'b11);
     CDB_en_i = 2'b11;//clean full step2
     CDB_i[0] = 7'h2;
     CDB_i[1] = 7'h3;
    `NEXT_CYCLE;
    `CHECK(execute_en_o, 2'b11);//test full clean last excute
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `CHECK(execute_en_o, 2'b00);//no execute
    `NEXT_CYCLE;



    //testcase1: test for CDB
    //1 : 1 CDB
    dispatch_en_i = 2'b11;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h4;

    source_tag_1_i[0] = 7'h4;
    ready_1_i[0] = 1'b1;
    source_tag_2_i[0] = 7'h3;
    ready_2_i[0] = 1'b0;

    source_tag_1_i[1] = 7'h2;
    ready_1_i[1] = 1'b0;
    source_tag_2_i[1] = 7'h1;
    ready_2_i[1] = 1'b1;
    
    fu_ready_i = 2'b11;
    CDB_i[0] = 0;
    CDB_i[1] = 0;
    `NEXT_CYCLE;
    `CHECK(execute_en_o, 2'b00);
    //then the table is like this:
    /*
        Table now
        packet dest tag1 tag2
        1 0    1    4    3
        2 0    4    2    1
        3 -    -    -    -
        4 -    -    -    - 
        */

    dispatch_en_i = 2'b00;
    CDB_en_i = 2'b11;
    fu_ready_i = 2'b11;
    CDB_i[0] = 7'h2;
    CDB_i[1] = 7'h3;
    `NEXT_CYCLE;
    `CHECK(execute_en_o, 2'b11);
    `CHECK(RS_full_o, MORE_LEFT);
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;

    
    //testcase3: CDB for seq    
    //then the table is like this:
    /*
        Table now
        packet dest tag1 tag2
        1 0     -    -    -
        2 0     -    -    -
        3 0     -    -    -
        4 0     -    -    -
        */
    `NEXT_CYCLE;
    //test entries now
    `CHECK(RS_full_o, MORE_LEFT);
    `CHECK(execute_en_o, 2'b00);
    `CHECK(FU_packet_o[0].source_tag_1, 7'h0);
    //start case 3
    dispatch_en_i = 2'b11;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h4;
    source_tag_1_i[0] = 7'h4;
    source_tag_2_i[0] = 7'h3;
    source_tag_1_i[1] = 7'h2;
    source_tag_2_i[1] = 7'h1;
    ready_2_i[0] = 1'b1;
    ready_1_i[0] = 1'b0;
    ready_2_i[1] = 1'b1;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    CDB_i[0] = 0;
    CDB_i[1] = 0;
    
    `NEXT_CYCLE;
    //`CHECK(execute_en_o, 2'b00);
    dispatch_en_i = 2'b11;
    CDB_en_i = 2'b11;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h6;
    source_tag_1_i[0] = 7'h8;
    source_tag_2_i[0] = 7'h7;
    source_tag_1_i[1] = 7'h6;
    source_tag_2_i[1] = 7'h5;
    ready_2_i[0] = 1'b1;
    ready_1_i[0] = 1'b0;
    ready_2_i[1] = 1'b1;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    CDB_i[0] = 7'h4;
    CDB_i[1] = 7'h2;
    `CHECK(execute_en_o, 2'b00);
    `CHECK(RS_full_o, MORE_LEFT);
    `NEXT_CYCLE;
    
    dispatch_en_i = 2'b11;
    CDB_en_i = 2'b11;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h4;
    source_tag_1_i[0] = 7'h4;
    source_tag_2_i[0] = 7'h3;
    source_tag_1_i[1] = 7'h2;
    source_tag_2_i[1] = 7'h1;
    ready_2_i[0] = 1'b1;
    ready_1_i[0] = 1'b0;
    ready_2_i[1] = 1'b1;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    CDB_i[0] = 8;
    CDB_i[1] = 6;
    `CHECK(RS_full_o, MORE_LEFT);
    `CHECK(execute_en_o, 2'b11);
    `NEXT_CYCLE;
    //`CHECK(execute_en_o, 2'b00);
    dispatch_en_i = 2'b11;
    CDB_en_i = 2'b11;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h6;
    source_tag_1_i[0] = 7'h8;
    source_tag_2_i[0] = 7'h7;
    source_tag_1_i[1] = 7'h6;
    source_tag_2_i[1] = 7'h5;
    ready_2_i[0] = 1'b1;
    ready_1_i[0] = 1'b0;
    ready_2_i[1] = 1'b1;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    CDB_i[0] = 4;
    CDB_i[1] = 2;
    `CHECK(RS_full_o, MORE_LEFT);
    `CHECK(execute_en_o, 2'b11);
    `NEXT_CYCLE;
    dispatch_en_i = 2'b00;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h4;
    source_tag_1_i[0] = 7'h4;
    source_tag_2_i[0] = 7'h3;
    source_tag_1_i[1] = 7'h2;
    source_tag_2_i[1] = 7'h1;
    ready_2_i[0] = 1'b0;
    ready_1_i[0] = 1'b0;
    ready_2_i[1] = 1'b0;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    CDB_i[0] = 0;
    CDB_i[1] = 0;
    `CHECK(RS_full_o, MORE_LEFT);
    `CHECK(execute_en_o, 2'b11);
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    //test4: single dispatch
    dispatch_en_i = 2'b01;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h4;
    source_tag_1_i[0] = 7'h4;
    source_tag_2_i[0] = 7'h3;
    source_tag_1_i[1] = 7'h2;
    source_tag_2_i[1] = 7'h1;
    ready_2_i[0] = 1'b0;
    ready_1_i[0] = 1'b0;
    ready_2_i[1] = 1'b0;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    CDB_i[0] = 0;
    CDB_i[1] = 0;
    `NEXT_CYCLE;
    dispatch_en_i = 2'b01;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h6;
    source_tag_1_i[0] = 7'h2;
    source_tag_2_i[0] = 7'h1;
    source_tag_1_i[1] = 7'h6;
    source_tag_2_i[1] = 7'h5;
    ready_2_i[0] = 1'b0;
    ready_1_i[0] = 1'b0;
    ready_2_i[1] = 1'b0;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    CDB_i[0] = 4;
    CDB_i[1] = 2;
    `NEXT_CYCLE;
    dispatch_en_i = 2'b01;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h4;
    source_tag_1_i[0] = 7'h8;
    source_tag_2_i[0] = 7'h7;
    source_tag_1_i[1] = 7'h1;
    source_tag_2_i[1] = 7'h1;
    ready_2_i[0] = 1'b0;
    ready_1_i[0] = 1'b0;
    ready_2_i[1] = 1'b0;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    CDB_i[0] = 0;
    CDB_i[1] = 0;
    `NEXT_CYCLE;
    dispatch_en_i = 2'b01;
    CDB_en_i = 2'b00;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h6;
    source_tag_1_i[0] = 7'h6;
    source_tag_2_i[0] = 7'h5;
    source_tag_1_i[1] = 7'h5;
    source_tag_2_i[1] = 7'h5;
    ready_2_i[0] = 1'b0;
    ready_1_i[0] = 1'b0;
    ready_2_i[1] = 1'b0;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    CDB_i[0] = 4;
    CDB_i[1] = 2;
    `NEXT_CYCLE;
    `CHECK(RS_full_o, FULL);
     //then the table is like this:
    /*
        Table now
        packet dest tag1 tag2
        1 0    1    4    3
        2 0    4    2    1
        3 0    1    8    7
        4 0    6    6    5
        */
    dispatch_en_i = 2'b00;
    CDB_en_i = 2'b11;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h4;
    source_tag_1_i[0] = 7'h4;
    source_tag_2_i[0] = 7'h3;
    source_tag_1_i[1] = 7'h2;
    source_tag_2_i[1] = 7'h1;
    ready_2_i[0] = 1'b0;
    ready_1_i[0] = 1'b0;
    ready_2_i[1] = 1'b0;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    CDB_i[0] = 3;
    CDB_i[1] = 4;
    `NEXT_CYCLE;
    dispatch_en_i = 2'b00;
    CDB_en_i = 2'b11;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h6;
    source_tag_1_i[0] = 7'h1;
    source_tag_2_i[0] = 7'h7;
    source_tag_1_i[1] = 7'h1;
    source_tag_2_i[1] = 7'h5;
    ready_2_i[0] = 1'b0;
    ready_1_i[0] = 1'b0;
    ready_2_i[1] = 1'b0;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    CDB_i[0] = 8;
    CDB_i[1] = 7;
    `CHECK(RS_full_o, ONE_LEFT);
    `CHECK(execute_en_o, 2'b01);

    `NEXT_CYCLE;
    dispatch_en_i = 2'b00;
    CDB_en_i = 2'b11;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h6;
    source_tag_1_i[0] = 7'h8;
    source_tag_2_i[0] = 7'h7;
    source_tag_1_i[1] = 7'h6;
    source_tag_2_i[1] = 7'h5;
    ready_2_i[0] = 1'b0;
    ready_1_i[0] = 1'b0;
    ready_2_i[1] = 1'b0;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    CDB_i[0] = 1;
    CDB_i[1] = 2;
    `CHECK(RS_full_o, MORE_LEFT);
    `CHECK(execute_en_o, 2'b01);

    `NEXT_CYCLE;
    dispatch_en_i = 2'b00;
    CDB_en_i = 2'b11;
    dest_tag_i[0] = 7'h1;
    dest_tag_i[1] = 7'h6;
    source_tag_1_i[0] = 7'h8;
    source_tag_2_i[0] = 7'h7;
    source_tag_1_i[1] = 7'h6;
    source_tag_2_i[1] = 7'h5;
    ready_2_i[0] = 1'b0;
    ready_1_i[0] = 1'b0;
    ready_2_i[1] = 1'b0;
    ready_1_i[1] = 1'b0;
    fu_ready_i = 2'b11;
    CDB_i[0] = 5;
    CDB_i[1] = 6;
    `CHECK(RS_full_o, MORE_LEFT);
    `CHECK(execute_en_o, 2'b01);
    `NEXT_CYCLE;
    `CHECK(RS_full_o, MORE_LEFT);
    `CHECK(execute_en_o, 2'b01);
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
    `NEXT_CYCLE;
        if(!error) begin
            $display("\033[32m PASSED \033[0m");
            $display("\033[32m No Error Occurred \033[0m");
        end
        $finish;
    end
endmodule

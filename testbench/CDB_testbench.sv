module CDB_testbench;
    logic clk;
    logic reset;
    logic error;
    logic [`FU_NUMBER-1: 0] FU_complete_i;
    logic [`FU_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] completed_tag_i;

    logic [`FU_NUMBER-1: 0] FU_complete_en_o;
    logic [1:0] CDB_en_o;
    logic [1:0] [$clog2(`PREG_NUMBER)-1: 0] CDB_o;


    // clock generation
    always begin
		#(10/2.0);
		clk = ~clk;
	end

    CDB CDB(
        .clk(clk),
        .reset(reset),
        .FU_complete_i(FU_complete_i),
        .completed_tag_i(completed_tag_i),
        .FU_complete_en_o(FU_complete_en_o),
        .CDB_en_o(CDB_en_o),
        .CDB_o(CDB_o)
    );

    initial begin
        clk = 0;
        FU_complete_i = 0;
        completed_tag_i = 0;
        `NEXT_CYCLE;
        FU_complete_i = 2'b11;
        completed_tag_i[0] = 5'd8;
        completed_tag_i[1] = 5'd12;
        #1;
        `CHECK(CDB_en_o, 2'b11);
        `CHECK(CDB_o[0], 5'd8);
        `CHECK(CDB_o[1], 5'd12);
        `CHECK(FU_complete_en_o, 2'b11);
        #1;
        FU_complete_i = 2'b00;
        completed_tag_i[0] = 5'd8;
        completed_tag_i[1] = 5'd12;
        #1;
        `CHECK(CDB_en_o, 2'b00);
        `CHECK(CDB_o[0], 5'd0);
        `CHECK(CDB_o[1], 5'd0);
        `CHECK(FU_complete_en_o, 2'b00);

        // First completed will go to the first CDB output
        FU_complete_i = 2'b10;
        completed_tag_i[0] = 5'd9;
        completed_tag_i[1] = 5'd16;
        #1;
        `CHECK(CDB_en_o, 2'b01);
        `CHECK(CDB_o[0], 5'd16);
        `CHECK(CDB_o[1], 5'd0);
        `CHECK(FU_complete_en_o, 2'b10);

        FU_complete_i = 2'b01;
        completed_tag_i[0] = 5'd4;
        completed_tag_i[1] = 5'd11;
        #1;
        `CHECK(CDB_en_o, 2'b01);
        `CHECK(CDB_o[0], 5'd4);
        `CHECK(CDB_o[1], 5'd0);
        `CHECK(FU_complete_en_o, 2'b01);

        $finish;
        
    end
endmodule
`define NEXT_CYCLE @(negedge clk)

// import "DPI-C" function void print_ROB(int head);
// `timescale 1ns/100ps
module rob_testbench();
    logic error;
    logic clk;
	logic reset;

	logic [1:0] dispatch_en_i;
    logic [1:0][$clog2(`ARCHREG_NUMBER)-1: 0] arch_old_i;
	logic [1:0] [$clog2(`PREG_NUMBER)-1:0]  preg_tag_old_i; //from maptable
    ROB_RETIRE_PACKET [1:0] retire_packet_i; 
	logic [1:0] [$clog2(`PREG_NUMBER)-1:0]  freeReg_i; //from Freelist
	logic [1:0] [$clog2(`PREG_NUMBER)-1: 0]  CDB_i; //WB: from CDB
    logic [1:0] CDB_en_i;

    logic [1:0] branch_recover_i;
    
    logic  [1:0][$clog2(`ARCHREG_NUMBER)-1: 0] arch_old_o;
    logic [1:0] [$clog2(`PREG_NUMBER)-1:0]  T_o;   //To Arch. Map       
    logic [1:0] [$clog2(`PREG_NUMBER)-1:0]  T_old_o; // Free Lists
	logic [1:0] retire_en_o; // To AM and FL
	logic [1:0] ROB_full_o; // To PL
    ROB_ENTRY [`ROB_SIZE-1:0] retire_packet_o;

    `ifdef DEBUG
	logic [$clog2(`ROB_SIZE)-1:0] head_debug;
	logic [$clog2(`ROB_SIZE)-1:0] tail_debug;
    logic [$clog2(`ROB_SIZE)-1:0] next_head_debug;
	`endif
    rob rob(
        
        .clk(clk),
	    .reset(reset),
        .dispatch_en_i(dispatch_en_i),
        .arch_old_i(arch_old_i),
        .preg_tag_old_i(preg_tag_old_i),
        .retire_packet_i(retire_packet_i),
        .freeReg_i(freeReg_i),
        .CDB_i(CDB_i),
        .CDB_en_i(CDB_en_i),

        .branch_recover_i(branch_recover_i),

        .T_o(T_o),
        .T_old_o(T_old_o),
        .arch_old_o(arch_old_o),
        .retire_en_o(retire_en_o),
        .ROB_full_o(ROB_full_o),
        .head_debug(head_debug),
        .tail_debug(tail_debug),
        .next_head_debug(next_head_debug) 
    );

    // clock generation
    always begin
		#(10/2.0);
		clk = ~clk;
	end

    integer i;

    initial begin
        error = 0;
        clk = 1'b0;
        reset = 1'b0;
	    dispatch_en_i[0] = 0;
	    dispatch_en_i[1] = 0;
	    preg_tag_old_i = 0;
        retire_packet_i = 0;
        freeReg_i = 0;
        i=0;
	    CDB_i = 0;
        CDB_en_i = 0;
	    branch_recover_i = 0;
        `NEXT_CYCLE;
        reset = 1'b1;
        `NEXT_CYCLE;
        reset = 1'b0;
        `NEXT_CYCLE;
        dispatch_en_i[0] = 1'b1;
        dispatch_en_i[1] = 1'b1;
        preg_tag_old_i[0] = 6'd1;
        preg_tag_old_i[1] = 6'd2;
        arch_old_i[0] = 6'd0;
        arch_old_i[1] = 6'd1;
        freeReg_i[0] = 6'd32;
        freeReg_i[1] = 6'd33;
        `NEXT_CYCLE;
        `CHECK(head_debug, 0);
        `CHECK(tail_debug, 2);
        CDB_i[0] = 6'd32;
        CDB_en_i[0] = 1'b1;
        dispatch_en_i[0] = 1'b0;
        /*
        Allocate two instructions. CDB broadcast. Retire one.
        +---+----+------+---+
        |   | T  | Told | C |
        +---+----+------+---+
        |   | 32 | 1    | 1 |
        +---+----+------+---+
        | h | 33 | 2    | 0 |
        +---+----+------+---+
        | t |    |      |   |
        +---+----+------+---+
        |   |    |      |   |
        +---+----+------+---+
        |   |    |      |   |
        +---+----+------+---+
        |   |    |      |   |
        +---+----+------+---+
        |   |    |      |   |
        +---+----+------+---+
        */
        `NEXT_CYCLE;
        `CHECK(T_o[0], 6'd32);
        `CHECK(T_old_o[0], 6'd1);
        `CHECK(arch_old_o[0], 0);
        `CHECK(retire_en_o[0], 1'b1);
        `CHECK(retire_en_o[1], 1'b0);
        `CHECK(head_debug, 1);
        `CHECK(tail_debug, 2);
        `NEXT_CYCLE;
        `CHECK(retire_en_o[0], 1'b0);

        for (i = 0; i < 2; i = i + 1) begin
            `NEXT_CYCLE;
            dispatch_en_i[0] = 1'b1;
            dispatch_en_i[1] = 1'b1;
            preg_tag_old_i[0] = 3 + i*2;
            preg_tag_old_i[1] = 4 + i*2;
            arch_old_i[0] = 2 + i*2;
            arch_old_i[1] = 3 + i*2;
            freeReg_i[0] = 6'd34 + i*2;
            freeReg_i[1] = 6'd35 + i*2;
        end
        /*
        Allocate 4 instructions in sequence.
        +---+----+------+---+
        |   | T  | Told | C |
        +---+----+------+---+
        |   | 32 | 1    | 1 |
        +---+----+------+---+
        | h | 33 | 2    |   |
        +---+----+------+---+
        |   | 34 | 3    |   |
        +---+----+------+---+
        |   | 35 | 4    |   |
        +---+----+------+---+
        |   | 36 | 5    |   |
        +---+----+------+---+
        |   | 37 | 6    |   |
        +---+----+------+---+
        | t |    |      |   |
        +---+----+------+---+
        */
        `NEXT_CYCLE;
        `CHECK(head_debug, 1);
        `CHECK(tail_debug, 6);

        CDB_i[0] = 6'd33;
        CDB_i[1] = 6'd34;
        CDB_en_i[0] = 1'b1;
        CDB_en_i[1] = 1'b1;
        dispatch_en_i[0] = 1'b0;
        /*
        Retire two instructions at once
        +---+----+------+---+
        |   | T  | Told | C |
        +---+----+------+---+
        |   | 32 | 1    | 1 |
        +---+----+------+---+
        |   | 33 | 2    |   |
        +---+----+------+---+
        |   | 34 | 3    |   |
        +---+----+------+---+
        | h | 35 | 4    |   |
        +---+----+------+---+
        |   | 36 | 5    |   |
        +---+----+------+---+
        |   | 37 | 6    |   |
        +---+----+------+---+
        | t |    |      |   |
        +---+----+------+---+
        */
        `NEXT_CYCLE;
        CDB_en_i = 0;
        `CHECK(T_o[0], 6'd33);
        `CHECK(T_old_o[0], 6'd2);
        `CHECK(arch_old_o[0], 1);
        `CHECK(retire_en_o[0], 1'b1);

        `CHECK(T_o[1], 6'd34);
        `CHECK(arch_old_o[1], 2);
        `CHECK(T_old_o[1], 6'd3);
        `CHECK(retire_en_o[1], 1'b1);
        `CHECK(head_debug, 3);
        `CHECK(tail_debug, 6);
        `NEXT_CYCLE;
        `CHECK(ROB_full_o, MORE_LEFT);

        CDB_i[0] = 6'd36;
        CDB_i[1] = 6'd37;
        CDB_en_i[0] = 1'b1;
        CDB_en_i[1] = 1'b1;
        dispatch_en_i[0] = 1'b0;
        /*
        Set ready for two instructins after head
        +---+----+------+---+
        |   | T  | Told | C |
        +---+----+------+---+
        |   | 32 | 1    | 1 |
        +---+----+------+---+
        |   | 33 | 2    |   |
        +---+----+------+---+
        |   | 34 | 3    |   |
        +---+----+------+---+
        | h | 35 | 4    |   |
        +---+----+------+---+
        |   | 36 | 5    | 1 |
        +---+----+------+---+
        |   | 37 | 6    | 1 |
        +---+----+------+---+
        | t |    |      |   |
        +---+----+------+---+
        */
        `NEXT_CYCLE;
        CDB_en_i = 0;
        `CHECK(retire_en_o[0], 1'b0);
        `CHECK(retire_en_o[1], 1'b0);
        `CHECK(head_debug, 3);
        `CHECK(tail_debug, 6);

        `NEXT_CYCLE;
        CDB_i[0] = 6'd35;
        CDB_en_i[0] = 1'b1;
        CDB_en_i[1] = 1'b0;
        
        dispatch_en_i[0] = 1'b0;
        /*
        Set head ready. Trigger three retire in a row
        +----+----+------+---+
        |    | T  | Told | C |
        +----+----+------+---+
        |    | 32 | 1    | 1 |
        +----+----+------+---+
        |    | 33 | 2    |   |
        +----+----+------+---+
        |    | 34 | 3    |   |
        +----+----+------+---+
        |    | 35 | 4    | 1 |
        +----+----+------+---+
        |    | 36 | 5    | 1 |
        +----+----+------+---+
        |    | 37 | 6    | 1 |
        +----+----+------+---+
        | ht |    |      |   |
        +----+----+------+---+
        */
        `CHECK(retire_en_o[0], 1'b0);
        `CHECK(retire_en_o[1], 1'b0);
        `NEXT_CYCLE;
        CDB_en_i[0] = 1'b0;
        CDB_en_i[1] = 1'b0;
        `CHECK(T_o[0], 6'd35);
        `CHECK(arch_old_o[0], 3);
        `CHECK(T_old_o[0], 6'd4);
        `CHECK(retire_en_o[0], 1'b1);
        `CHECK(T_o[1], 6'd36);
        `CHECK(arch_old_o[1], 4);
        `CHECK(T_old_o[1], 6'd5);
        `CHECK(retire_en_o[1], 1'b1);
        `CHECK(head_debug, 5);
        `CHECK(tail_debug, 6);
        `NEXT_CYCLE;
        `CHECK(T_o[0], 6'd37);
        `CHECK(arch_old_o[0], 5);
        `CHECK(T_old_o[0], 6'd6);
        `CHECK(retire_en_o[0], 1'b1);
        `CHECK(retire_en_o[1], 1'b0);
        `CHECK(head_debug, 6);
        `CHECK(tail_debug, 6);
		`CHECK(ROB_full_o, MORE_LEFT);

        for (i = 0; i < 50; i = i + 1) begin
            `NEXT_CYCLE;
            dispatch_en_i[0] = 1'b1;
            dispatch_en_i[1] = (ROB_full_o == ONE_LEFT)?1'b0:1'b1;
            preg_tag_old_i[0] = i*2;
            preg_tag_old_i[1] = 1 + i*2;
            arch_old_i[0] = i*2;
            arch_old_i[1] = 1+i*2;
            freeReg_i[0] = 32 + i*2;
            freeReg_i[1] = 33 + i*2;
        end
        /*
        Allocate until RoB full. Extra will not be accepted.
        +----+----+------+---+
        |    | T  | Told | C |
        +----+----+------+---+
        |    |    |      |   |
        +----+----+------+---+
        |    |    |      |   |
        +----+----+------+---+
        |    |    |      |   |
        +----+----+------+---+
        |    |    |      |   |
        +----+----+------+---+
        |    |    |      |   |
        +----+----+------+---+
        |    |    |      |   |
        +----+----+------+---+
        |ht  | 32 | 0    |   |
        +----+----+------+---+
        */
        `CHECK(ROB_full_o, FULL);
        `CHECK(head_debug, 6);
        `CHECK(tail_debug, 6);


        dispatch_en_i[0] = 0;
        for(i = 0; i < 16; i++) begin
            CDB_i[0] = 32 + i*2;
            CDB_i[1] = 33 + i*2;
            CDB_en_i[0] = 1'b1;
            CDB_en_i[1] = 1'b1;
            `NEXT_CYCLE;
            `CHECK(T_o[0], 32 + i*2);
            `CHECK(arch_old_o[0], i*2);
            `CHECK(T_old_o[0], i*2);
            `CHECK(retire_en_o[0], 1'b1);
            `CHECK(T_o[1], 33 + i*2);
            `CHECK(arch_old_o[1], 1 + i*2);
            `CHECK(T_old_o[1], 1 + i*2);
            `CHECK(retire_en_o[1], 1'b1);
            `CHECK(head_debug, (8 + i*2)%32);
            `CHECK(tail_debug, 6);
            CDB_en_i[0] = 1'b0;
            CDB_en_i[1] = 1'b0;
        end
        
        for (i = 0; i < 5; i = i + 1) begin
            `NEXT_CYCLE;
            dispatch_en_i[0] = 1'b1;
            dispatch_en_i[1] = 1'b0;
            preg_tag_old_i[0] = i*2;
            preg_tag_old_i[1] = 1 + i*2;
            freeReg_i[0] = 32 + i*2;
            freeReg_i[1] = 33 + i*2;
            arch_old_i[0] = i*2;
            arch_old_i[1] = 1+i*2;
        end
        branch_recover_i[0] = 1'b1;
        `NEXT_CYCLE;
        `CHECK(head_debug, 6);
        `CHECK(tail_debug, 6);
        `CHECK(ROB_full_o, MORE_LEFT);

        if(error) $display("failed");
        else    $display("passed");
        
        $finish;

    end
    
    // always @(negedge clk) begin
    //     if(reset) begin
	// 		$display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
	// 		         $realtime);
    //     end else begin
    //         print_ROB(head_debug);
	// 	end  // if(reset)
    // end


endmodule
	

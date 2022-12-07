`define NEXT_CYCLE @(negedge clk)

module rob_testbench();
    logic clk;
	logic reset;
	logic dispatch_en_i;
    logic dispatch_size_i;
	logic [$clog2(`PREG_NUMBER)-1:0] preg_tag_old_i [2]; //from maptable
	logic [$clog2(`PREG_NUMBER)-1:0] freeReg_i [2]; //from Freelist
	logic [$clog2(`PREG_NUMBER)-1: 0] CDB_i [2]; //WB: from CDB
    logic branch_mispredicted_i;

    logic [$clog2(`PREG_NUMBER)-1:0] T_o [2];   //To Arch. Map       
    logic [$clog2(`PREG_NUMBER)-1:0] T_old_o [2]; // Free Lists
	logic retire_en_o [2]; // To AM and FL
	STRUCTURE_FULL ROB_full_o; // To PL

    `ifdef DEBUG
	logic [$clog2(`ROB_SIZE)-1:0] head_debug;
	logic [$clog2(`ROB_SIZE)-1:0] tail_debug;
	`endif

    rob rob(.*);

    // clock generation
    always begin
		#(10/2.0);
		clk = ~clk;
	end

    integer i;

    initial begin
        clk = 1'b0;
        reset = 1'b0;
        `NEXT_CYCLE;
        reset = 1'b1;
        `NEXT_CYCLE;
        reset = 1'b0;
        `NEXT_CYCLE;
        dispatch_en_i = 1'b1;
        dispatch_size_i = 1'b1;
        preg_tag_old_i[0] = 6'h1;
        preg_tag_old_i[1] = 6'h2;
        freeReg_i[0] = 6'h32;
        freeReg_i[1] = 6'h33;
        `NEXT_CYCLE;
        `CHECK(head_debug, 0);
        `CHECK(tail_debug, 2);
        CDB_i[0] = 6'h32;
        dispatch_en_i = 1'b0;
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
        `CHECK(T_o[0], 6'h32);
        `CHECK(T_old_o[0], 6'h1);
        `CHECK(retire_en_o[0], 1'b1);
        `CHECK(retire_en_o[1], 1'b0);
        `CHECK(head_debug, 1);
        `CHECK(tail_debug, 2);
        `NEXT_CYCLE;
        `CHECK(retire_en_o[0], 1'b0);

        for (i = 0; i < 2; i = i + 1) begin
            `NEXT_CYCLE;
            dispatch_en_i = 1'b1;
            dispatch_size_i = 1'b1;
            preg_tag_old_i[0] = 3 + i*2;
            preg_tag_old_i[1] = 4 + i*2;
            freeReg_i[0] = 6'h34 + i*2;
            freeReg_i[1] = 6'h35 + i*2;
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

        CDB_i[0] = 6'h33;
        CDB_i[1] = 6'h34;
        dispatch_en_i = 1'b0;
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
        `CHECK(T_o[0], 6'h33);
        `CHECK(T_old_o[0], 6'h2);
        `CHECK(retire_en_o[0], 1'b1);
        `CHECK(T_o[1], 6'h34);
        `CHECK(T_old_o[1], 6'h3);
        `CHECK(retire_en_o[1], 1'b1);
        `CHECK(head_debug, 3);
        `CHECK(tail_debug, 6);
        `NEXT_CYCLE;

        CDB_i[0] = 6'h36;
        CDB_i[1] = 6'h37;
        dispatch_en_i = 1'b0;
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
        `CHECK(retire_en_o[0], 1'b0);
        `CHECK(retire_en_o[1], 1'b0);
        `CHECK(head_debug, 3);
        `CHECK(tail_debug, 6);

        `NEXT_CYCLE;
        CDB_i[0] = 6'h35;
        dispatch_en_i = 1'b0;
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
        `CHECK(T_o[0], 6'h35);
        `CHECK(T_old_o[0], 6'h4);
        `CHECK(retire_en_o[0], 1'b1);
        `CHECK(T_o[1], 6'h36);
        `CHECK(T_old_o[1], 6'h5);
        `CHECK(retire_en_o[1], 1'b1);
        `CHECK(head_debug, 5);
        `CHECK(tail_debug, 6);
        `NEXT_CYCLE;
        `CHECK(T_o[0], 6'h37);
        `CHECK(T_old_o[0], 6'h6);
        `CHECK(retire_en_o[0], 1'b1);
        `CHECK(retire_en_o[1], 1'b0);
        `CHECK(head_debug, 6);
        `CHECK(tail_debug, 6);

        for (i = 0; i < 50; i = i + 1) begin
            `NEXT_CYCLE;
            dispatch_en_i = 1'b1;
            dispatch_size_i = (ROB_full_o == ONE_LEFT)?1'b0:1'b1;
            preg_tag_old_i[0] = i*2;
            preg_tag_old_i[1] = 1 + i*2;
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


        dispatch_en_i = 0;
        for(i = 0; i < 16; i++) begin
            CDB_i[0] = 32 + i*2;
            CDB_i[1] = 33 + i*2;
            `NEXT_CYCLE;
            `CHECK(T_o[0], 32 + i*2);
            `CHECK(T_old_o[0], i*2);
            `CHECK(retire_en_o[0], 1'b1);
            `CHECK(T_o[1], 33 + i*2);
            `CHECK(T_old_o[1], 1 + i*2);
            `CHECK(retire_en_o[1], 1'b1);
            `CHECK(head_debug, (8 + i*2)%32);
            `CHECK(tail_debug, 6);
        end
        
        for (i = 0; i < 5; i = i + 1) begin
            `NEXT_CYCLE;
            dispatch_en_i = 1'b1;
            dispatch_size_i = 1'b0;
            preg_tag_old_i[0] = i*2;
            preg_tag_old_i[1] = 1 + i*2;
            freeReg_i[0] = 32 + i*2;
            freeReg_i[1] = 33 + i*2;
        end
        branch_mispredicted_i = 1'b1;
        `NEXT_CYCLE;
        `CHECK(head_debug, 6);
        `CHECK(tail_debug, 7);
        $finish;


    end
endmodule
	
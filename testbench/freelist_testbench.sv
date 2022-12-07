//overwrite parameter
// `define FREELIST_SIZE 8
// `define PREG_NUMBER 16
// `define ARCHREG_NUMBER 8

module testbench;
    logic error;
    logic clk;
    logic reset;
    logic [1:0] dispatch_en_in;
    // logic [$clog2(`FREELIST_SIZE)-1:0] rewind_head;
    // logic rewind_enable;
    logic [1:0] branch_recover_in;
    logic [$clog2(`FREELIST_SIZE)-1:0] branch_head_in;
    logic [1:0] [$clog2(`PREG_NUMBER)-1:0] retire_tag_in;
    logic [`FREELIST_SIZE-1:0] [$clog2(`PREG_NUMBER)-1:0] checkpoint_freelist;
    logic [1:0] dispatch_branch_i;
    logic [1:0] retire_en_in;
    logic [1:0] retire_branch_i;

    logic [1:0] [$clog2(`PREG_NUMBER)-1:0] free_reg_out;
    logic [1:0] free_reg_en_o;
    logic [$clog2(`FREELIST_SIZE)-1:0] branch_head_output;
    STRUCTURE_FULL free_list_empty;

    `ifdef DEBUG
	logic [$clog2(`FREELIST_SIZE)-1:0] head_debug;
	logic [$clog2(`FREELIST_SIZE)-1:0] tail_debug;
    logic [$clog2(`FREELIST_SIZE)-1:0] tail_plus_one_debug;
    logic [`FREELIST_SIZE-1:0] [$clog2(`PREG_NUMBER)-1:0] entries_debug;
    logic [`FREELIST_SIZE-1:0] valid_debug;
	`endif

    freelist freelist(
        .clk(clk),
        .reset(reset),
        .dispatch_en_in(dispatch_en_in),
        .branch_recover_in(branch_recover_in),
        .dispatch_branch_i(dispatch_branch_i),
        .retire_branch_i(retire_branch_i),
        .retire_tag_in(retire_tag_in),
        .checkpoint_freelist(checkpoint_freelist),
        .retire_en_in(retire_en_in),
        .free_reg_out(free_reg_out),
        .free_reg_en_o(free_reg_en_o),
        .branch_head_output(branch_head_output),
        .free_list_empty(free_list_empty),
        .head_debug(head_debug),
        .tail_debug(tail_debug),
        .tail_plus_one_debug(tail_plus_one_debug)
    );

    // clock generation
    always begin
		#(10/2.0);
		clk = ~clk;
	end
    
    integer i;

    initial 
    begin
        clk = 1'b0;
        reset = 1'b0;
        dispatch_branch_i = 0;
        dispatch_en_in = 0;
        branch_recover_in = 0;
        branch_head_in = 0;
        retire_branch_i = 0;
        retire_tag_in = 0;
        checkpoint_freelist= 0;
        retire_en_in = 0;
        `NEXT_CYCLE; 
        reset = 1'b1;
        `NEXT_CYCLE;

        reset = 1'b0;
        /*
        +---+----+
        |   | T  |
        +---+----+
        | h | 8  |
        +---+----+
        |   | 9  |
        +---+----+
        |   | 10 |
        +---+----+
        |   | 11 |
        +---+----+
        |   | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        | t | 15 |
        +---+----+
        */
        `CHECK(head_debug, 0);
        `CHECK(tail_debug, 7);
        `CHECK(free_list_empty, MORE_LEFT);
        // Request two
        dispatch_en_in = 2'b11;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |   | 8  |
        +---+----+
        |   | 9  |
        +---+----+
        | h | 10 |
        +---+----+
        |   | 11 |
        +---+----+
        |   | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        | t | 15 |
        +---+----+
        */        
        `CHECK(free_reg_out[0], 8);
        `CHECK(free_reg_out[1], 9);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 1);
        `NEXT_CYCLE;
        `CHECK(head_debug, 2);
        `CHECK(tail_debug, 7);
        `CHECK(free_list_empty, MORE_LEFT);

        // Request one
        dispatch_en_in = 2'b01;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |   | 8  |
        +---+----+
        |   | 9  |
        +---+----+
        |   | 10 |
        +---+----+
        | h | 11 |
        +---+----+
        |   | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        | t | 15 |
        +---+----+
        */
        `CHECK(free_reg_out[0], 10);
        `CHECK(free_reg_out[1], 0);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 0);
        `NEXT_CYCLE;
        `CHECK(head_debug, 3);
        `CHECK(tail_debug, 7);
        `CHECK(free_list_empty, MORE_LEFT);

        // Request one (will not use this)
        dispatch_en_in = 2'b10;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |   | 8  |
        +---+----+
        |   | 9  |
        +---+----+
        |   | 10 |
        +---+----+
        |   | 11 |
        +---+----+
        | h | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        | t | 15 |
        +---+----+
        */
        `CHECK(free_reg_out[0], 0);
        `CHECK(free_reg_out[1], 11);
        `CHECK(free_reg_en_o[0], 0);
        `CHECK(free_reg_en_o[1], 1);
        `NEXT_CYCLE;
        `CHECK(head_debug, 4);
        `CHECK(tail_debug, 7);
        `CHECK(free_list_empty, MORE_LEFT);

        // Request two, only one left
        dispatch_en_in = 2'b11;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |   | 8  |
        +---+----+
        |   | 9  |
        +---+----+
        |   | 10 |
        +---+----+
        |   | 11 |
        +---+----+
        |   | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        | h | 14 |
        +---+----+
        | t | 15 |
        +---+----+
        */
        `CHECK(free_reg_out[0], 12);
        `CHECK(free_reg_out[1], 13);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 1);
        `NEXT_CYCLE;
        `CHECK(head_debug, 6);
        `CHECK(tail_debug, 7);
        `CHECK(free_list_empty, MORE_LEFT); // (Fixed) if no valid used, this will be one left

        // Request two, now empty
        dispatch_en_in = 2'b11;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        | h | 8  |
        +---+----+
        |   | 9  |
        +---+----+
        |   | 10 |
        +---+----+
        |   | 11 |
        +---+----+
        |   | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        |  t| 15 |
        +---+----+
        */
        `CHECK(free_reg_out[0], 14);
        `CHECK(free_reg_out[1], 15);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 1);
        `NEXT_CYCLE;
        `CHECK(head_debug, 0);
        `CHECK(tail_debug, 7);
        `CHECK(free_list_empty, FULL);

        // Retire two, request 0
        dispatch_en_in = 2'b00;
        retire_en_in = 2'b11;
        retire_tag_in[0] = 0;
        retire_tag_in[1] = 1;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |  h| 0  |
        +---+----+
        | t | 1  |
        +---+----+
        |   | 10 |
        +---+----+
        |   | 11 |
        +---+----+
        |   | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        |   | 15 | <- This is where performance is lost if full is wrong
        +---+----+
        */
        `CHECK(free_reg_out[0], 0);
        `CHECK(free_reg_out[1], 0);
        `CHECK(free_reg_en_o[0], 0);
        `CHECK(free_reg_en_o[1], 0);
        `NEXT_CYCLE;
        retire_en_in = 2'b0;
        `CHECK(head_debug, 0);
        `CHECK(tail_debug, 1);
        `CHECK(free_list_empty, MORE_LEFT);
        `NEXT_CYCLE;

        // Request two, empty again
        dispatch_en_in = 2'b11;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |   | 0  |
        +---+----+
        |  t| 1  |
        +---+----+
        | h | 10 |
        +---+----+
        |   | 11 |
        +---+----+
        |   | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        |   | 0  |
        +---+----+
        */
        `CHECK(free_reg_out[0], 0);
        `CHECK(free_reg_out[1], 1);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 1);
        `NEXT_CYCLE;
        `CHECK(head_debug, 2);
        `CHECK(tail_debug, 1);
        `CHECK(free_list_empty, FULL);

        // Retire two, request two, forward to request
        dispatch_en_in = 2'b11;
        retire_en_in = 2'b11;
        retire_tag_in[0] = 2;
        retire_tag_in[1] = 3;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |   | 0  |
        +---+----+
        |   | 1  |
        +---+----+
        |   | 2  |
        +---+----+
        | t | 3  |
        +---+----+
        | h | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        |   | 0  |
        +---+----+
        */
        `CHECK(free_reg_out[0], 2);
        `CHECK(free_reg_out[1], 3);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 1);
        `NEXT_CYCLE;
        dispatch_en_in = 2'b0;
        retire_en_in = 2'b0;
        #1;
        `CHECK(head_debug, 4);
        `CHECK(tail_debug, 3);
        `CHECK(free_list_empty, FULL);                                         

        // Retire one, request one, forward to request
        dispatch_en_in = 2'b01;
        retire_en_in = 2'b01;
        retire_tag_in[0] = 4;
        retire_tag_in[1] = 0;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |   | 0  |
        +---+----+
        |   | 1  |
        +---+----+
        |   | 2  |
        +---+----+
        |   | 3  |
        +---+----+
        | t | 4  |
        +---+----+
        | h | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        |   | 0  |
        +---+----+
        */
        `CHECK(free_reg_out[0], 4);
        `CHECK(free_reg_out[1], 0);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 0);
        `NEXT_CYCLE;
        dispatch_en_in = 2'b0;
        retire_en_in = 2'b0;
        #1;
        `CHECK(head_debug, 5);
        `CHECK(tail_debug, 4);
        `CHECK(free_list_empty, FULL);

        // Retire two, request one, forward to request
        dispatch_en_in = 2'b01;
        retire_en_in = 2'b11;
        retire_tag_in[0] = 5;
        retire_tag_in[1] = 6;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |   | 0  |
        +---+----+
        |   | 1  |
        +---+----+
        |   | 2  |
        +---+----+
        |   | 3  |
        +---+----+
        |   | 4  |
        +---+----+
        |   | 5  |
        +---+----+
        | ht| 6  |
        +---+----+
        |   | 0  |
        +---+----+
        */
        `CHECK(free_reg_out[0], 5);
        `CHECK(free_reg_out[1], 0);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 0);
        `NEXT_CYCLE;
        dispatch_en_in = 2'b0;
        retire_en_in = 2'b0;
        #1;
        `CHECK(head_debug, 6);
        `CHECK(tail_debug, 6);
        `CHECK(free_list_empty, ONE_LEFT);

        // Retire one, request two, forward to request, empty
        dispatch_en_in = 2'b11;
        retire_en_in = 2'b01;
        retire_tag_in[0] = 7;
        retire_tag_in[1] = 0;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        | h | 0  |
        +---+----+
        |   | 1  |
        +---+----+
        |   | 2  |
        +---+----+
        |   | 3  |
        +---+----+
        |   | 4  |
        +---+----+
        |   | 5  |
        +---+----+
        |   | 6  |
        +---+----+
        | t | 7  |
        +---+----+
        */
        `CHECK(free_reg_out[0], 6);
        `CHECK(free_reg_out[1], 7);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 1);
        `NEXT_CYCLE;
        dispatch_en_in = 2'b0;
        retire_en_in = 2'b0;
        #1;
        `CHECK(head_debug, 0);
        `CHECK(tail_debug, 7);
        `CHECK(free_list_empty, FULL);

        // Continuous retire
        dispatch_en_in = 2'b0;
        retire_en_in = 2'b11;
        for(i = 0; i < 4; i++) begin
            retire_tag_in[0] = 7 - 2*i;
            retire_tag_in[1] = 6 - 2*i;
            `NEXT_CYCLE;
        end
        retire_en_in = 2'b0;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        | h | 7  |
        +---+----+
        |   | 6  |
        +---+----+
        |   | 5  |
        +---+----+
        |   | 4  |
        +---+----+
        |   | 3  |
        +---+----+
        |   | 2  |
        +---+----+
        |   | 1  |
        +---+----+
        | t | 0  |
        +---+----+
        */
        `CHECK(head_debug, 0);
        `CHECK(tail_debug, 7);
        `CHECK(free_list_empty, MORE_LEFT);

        // continuous dispatch
        dispatch_en_in = 2'b11;
        retire_en_in = 2'b0;
        for(i = 0; i < 8; i++) begin
            #1;
            if(i < 4) begin
		        `CHECK(free_reg_out[0], 7 - 2*i)
		        `CHECK(free_reg_out[1], 6 - 2*i);
		        `CHECK(free_reg_en_o[0], 1);
		        `CHECK(free_reg_en_o[1], 1);
				`CHECK(free_list_empty, MORE_LEFT);
			end            
            `NEXT_CYCLE;
        end
        `CHECK(free_list_empty, FULL);


        //add test
         `NEXT_CYCLE; 
        reset = 1'b1;
        `NEXT_CYCLE;
        reset = 1'b0;
        dispatch_en_in = 2'b11;
        branch_head_in = 0;
        dispatch_branch_i[0] = 1'b1;
        dispatch_branch_i[1] = 1'b1;
        retire_branch_i = 0;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |   | 8  |
        +---+----+
        |   | 9  |
        +---+----+
        | h | 10 |
        +---+----+
        |   | 11 |
        +---+----+
        |   | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        | t | 15 |
        +---+----+
        */        
        `CHECK(free_reg_out[0], 8);
        `CHECK(free_reg_out[1], 9);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 1);
        `NEXT_CYCLE;
        `CHECK(head_debug, 2);
        `CHECK(tail_debug, 7);
        `CHECK(free_list_empty, MORE_LEFT);

        // Request one
        dispatch_en_in = 2'b01;
        dispatch_branch_i[0] = 1'b1;
        dispatch_branch_i[1] = 1'b0;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |   | 8  |
        +---+----+
        |   | 9  |
        +---+----+
        |   | 10 |
        +---+----+
        | h | 11 |
        +---+----+
        |   | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        | t | 15 |
        +---+----+
        */
        `CHECK(free_reg_out[0], 10);
        `CHECK(free_reg_out[1], 0);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 0);
        `NEXT_CYCLE;
        `CHECK(head_debug, 3);
        `CHECK(tail_debug, 7);
        `CHECK(free_list_empty, MORE_LEFT);

        // Request one (will not use this)
        dispatch_en_in = 2'b01;
        dispatch_branch_i[0] = 1'b1;
        dispatch_branch_i[1] = 1'b0;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |   | 8  |
        +---+----+
        |   | 9  |
        +---+----+
        |   | 10 |
        +---+----+
        |   | 11 |
        +---+----+
        | h | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        | t | 15 |
        +---+----+
        */
        `CHECK(free_reg_out[0], 11);
        `CHECK(free_reg_out[1], 0);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 0);
        `NEXT_CYCLE;
        `CHECK(head_debug, 4);
        `CHECK(tail_debug, 7);
        `CHECK(free_list_empty, MORE_LEFT);

        // Request two, only one left
        dispatch_en_in = 2'b11;
        dispatch_branch_i[0] = 1'b1;
        dispatch_branch_i[1] = 1'b1;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |   | 8  |
        +---+----+
        |   | 9  |
        +---+----+
        |   | 10 |
        +---+----+
        |   | 11 |
        +---+----+
        |   | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        | h | 14 |
        +---+----+
        | t | 15 |
        +---+----+
        */
        `CHECK(free_reg_out[0], 12);
        `CHECK(free_reg_out[1], 13);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 1);
        `NEXT_CYCLE;
        `CHECK(head_debug, 6);
        `CHECK(tail_debug, 7);
        `CHECK(free_list_empty, MORE_LEFT); // (Fixed) if no valid used, this will be one left

        // Request two, now empty
        dispatch_en_in = 2'b11;
        dispatch_branch_i[0] = 1'b1;
        dispatch_branch_i[1] = 1'b1;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        | h | 8  |
        +---+----+
        |   | 9  |
        +---+----+
        |   | 10 |
        +---+----+
        |   | 11 |
        +---+----+
        |   | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        |  t| 15 |
        +---+----+
        */
        `CHECK(free_reg_out[0], 14);
        `CHECK(free_reg_out[1], 15);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 1);
        `NEXT_CYCLE;
        `CHECK(head_debug, 0);
        `CHECK(tail_debug, 7);
        `CHECK(free_list_empty, FULL);

        // Retire two, request 0
        dispatch_en_in = 2'b00;
        retire_en_in = 2'b11;
        retire_branch_i[0] = 1'b0;
        retire_branch_i[1] = 1'b0;
        branch_recover_in[0] = 1'b0;
        branch_recover_in[1] = 1'b0;
        dispatch_branch_i[0] = 1'b0;
        dispatch_branch_i[1] = 1'b0;
        retire_tag_in[0] = 0;
        retire_tag_in[1] = 1;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |  h| 0  |
        +---+----+
        | t | 1  |
        +---+----+
        |   | 10 |
        +---+----+
        |   | 11 |
        +---+----+
        |   | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        |   | 15 | <- This is where performance is lost if full is wrong
        +---+----+
        */
        `CHECK(free_reg_out[0], 0);
        `CHECK(free_reg_out[1], 0);
        `CHECK(free_reg_en_o[0], 0);
        `CHECK(free_reg_en_o[1], 0);
        `NEXT_CYCLE;
        
        `CHECK(head_debug, 1);
        `CHECK(tail_debug, 0);
        `CHECK(free_list_empty, MORE_LEFT);
        dispatch_en_in = 2'b00;
        retire_en_in = 2'b11;
        retire_branch_i[0] = 1'b1;
        retire_branch_i[1] = 1'b1;
        branch_recover_in[0] = 1'b1;
        branch_recover_in[1] = 1'b1;
        dispatch_branch_i[0] = 1'b0;
        dispatch_branch_i[1] = 1'b0;
        retire_tag_in[0] = 0;
        retire_tag_in[1] = 1;
        retire_en_in = 2'b11;
        `CHECK(free_reg_out[0], 0);
        `CHECK(free_reg_out[1], 0);
        `CHECK(free_reg_en_o[0], 0);
        `CHECK(free_reg_en_o[1], 0);
        `NEXT_CYCLE;
        `CHECK(head_debug, 3);
        `CHECK(tail_debug, 2);
        `CHECK(free_list_empty, MORE_LEFT);

        // Request two, empty again
        dispatch_en_in = 2'b11;//retire 1 branch 1 dispatch 0 dispatch branch 0
        retire_en_in = 2'b00;
        retire_branch_i[0] = 1'b0;
        retire_branch_i[1] = 1'b0;
        branch_recover_in[0] = 1'b0;
        branch_recover_in[1] = 1'b0;
        dispatch_branch_i[0] = 1'b0;
        dispatch_branch_i[1] = 1'b0;
        retire_tag_in[0] = 0;
        retire_tag_in[1] = 1;
        #1;
        /*
        +---+----+
        |   | T  |
        +---+----+
        |   | 0  |
        +---+----+
        |  t| 1  |
        +---+----+
        | h | 10 |
        +---+----+
        |   | 11 |
        +---+----+
        |   | 12 |
        +---+----+
        |   | 13 |
        +---+----+
        |   | 14 |
        +---+----+
        |   | 0  |
        +---+----+
        */
        `CHECK(free_reg_out[0], 0);
        `CHECK(free_reg_out[1], 0);
        `CHECK(free_reg_en_o[0], 1);
        `CHECK(free_reg_en_o[1], 1);
        `NEXT_CYCLE;
        `CHECK(head_debug, 5);
        `CHECK(tail_debug, 3);
        `CHECK(free_list_empty, 0);

        $finish;
     end // initial
endmodule


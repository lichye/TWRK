// //overwrite parameter for debug use
//  `define FREELIST_SIZE 8
//  `define PREG_NUMBER 16
//  `define ARCHREG_NUMBER 8

`ifndef __FREELIST_SV__
`define __FREELIST_SV__

// `timescale 1ns/100ps

module freelist(

    `ifdef DEBUG
	output logic [$clog2(`FREELIST_SIZE)-1:0] head_debug,
	output logic [$clog2(`FREELIST_SIZE)-1:0] tail_debug,
    output logic [$clog2(`FREELIST_SIZE)-1:0] tail_plus_one_debug,
    output logic [`FREELIST_SIZE-1:0] [$clog2(`PREG_NUMBER)-1:0] entries_debug,
    output logic [`FREELIST_SIZE-1:0] valid_debug,
	`endif

    input clk,
    input reset,
    input [1:0] dispatch_en_in,                                                // D, request new physical reg
    input logic [1:0] dispatch_branch_i,

    input [1:0] branch_recover_in,                                                   // C, mispredcited branch
    input [1:0][$clog2(`PREG_NUMBER)-1:0] retire_tag_in,                       // R, retired physical reg
    input [1:0] retire_en_in,                                                  // R
    input [1:0] retire_branch_i,

    output logic [1:0][$clog2(`PREG_NUMBER)-1:0] free_reg_out,                 // D, allcated physical reg
    output logic [1:0] free_reg_en_o,                                          // D
    output STRUCTURE_FULL free_list_empty
);


    // internal signal
    logic [$clog2(`FREELIST_SIZE)-1:0] head;
    logic [$clog2(`FREELIST_SIZE)-1:0] next_head;
    logic [$clog2(`FREELIST_SIZE)-1:0] tail;
    logic [$clog2(`FREELIST_SIZE)-1:0] next_tail;
    logic [`FREELIST_SIZE-1:0] [$clog2(`PREG_NUMBER)-1:0] entries;
    logic [`FREELIST_SIZE-1:0] [$clog2(`PREG_NUMBER)-1:0] next_entries;
    logic [`FREELIST_SIZE-1:0] valid;
    logic [`FREELIST_SIZE-1:0] next_valid;

    logic [$clog2(`BRANCH_BUFFER_SIZE)-1: 0] branch_head;
    logic [$clog2(`BRANCH_BUFFER_SIZE)-1: 0] next_branch_head;
    logic [$clog2(`BRANCH_BUFFER_SIZE)-1: 0] branch_tail;
    logic [$clog2(`BRANCH_BUFFER_SIZE)-1: 0] next_branch_tail;

    logic [`BRANCH_BUFFER_SIZE-1:0] [$clog2(`BRANCH_BUFFER_SIZE)-1: 0] branch_entries;
    logic [`BRANCH_BUFFER_SIZE-1:0] [$clog2(`BRANCH_BUFFER_SIZE)-1: 0] next_branch_entries;
    logic [`BRANCH_BUFFER_SIZE-1:0] branch_valid;
    logic [`BRANCH_BUFFER_SIZE-1:0] next_branch_valid;

    logic [$clog2(`BRANCH_BUFFER_SIZE)-1: 0] freelist_branch_head_in;

    integer branch_counter;
    


    `ifdef DEBUG
	assign head_debug = head;
	assign tail_debug = tail;
    assign tail_plus_one_debug = tail + 1;
    assign entries_debug = entries;
    assign valid_debug = valid;
	`endif

    // Full signal, for dispatch stage
    always_comb begin
        free_list_empty = ILLEGAL;
        if(valid[head]) begin                              // when there is at least one valid entry
            if (head == tail) begin
                if(retire_en_in == 2'h3 || retire_en_in == 2'h1 || retire_en_in == 2'h2) free_list_empty = MORE_LEFT;
                else if(retire_en_in == 0) free_list_empty = ONE_LEFT;
            end else free_list_empty = MORE_LEFT;              // otherwise there are more
        end else begin
            if(head == tail + 1'b1) begin // already empty
                if(retire_en_in == 2'h3)                               free_list_empty = MORE_LEFT;
                else if (retire_en_in == 2'h1 || retire_en_in == 2'h2) free_list_empty = ONE_LEFT;
                else if(retire_en_in == 0)                             free_list_empty = FULL;
            end else free_list_empty = FULL;            
        end
    end

    integer k;
	always_comb begin
        // always assign value to every variable in the beginning of combnational logic
		free_reg_out = 0;
        free_reg_en_o = 0;
		next_entries = entries;
		next_head = head;
		next_tail = tail;
        next_valid = valid;
        k = 0;
        branch_counter = 0;
        // allocate retired reg in Retire
        case(retire_en_in)
            2'b00: begin
                next_entries[tail] = entries[tail];
            end
        
            2'b01: begin
				next_entries[tail+1'b1] = retire_tag_in[0]; // pointer points to the last valid, so update the one after it
                next_tail = tail + 1'b1;
                next_valid[tail+1'b1] = 1'b1;
				if(branch_recover_in[0] == 1'b1) begin      // if there is recover
                    next_head = freelist_branch_head_in;
					next_valid = 32'b0 - 1'b1;
                    next_tail = next_head - 2'b1;
                end
            end
            
            2'b10: begin
                next_entries[tail+1'b1] = retire_tag_in[1];
                next_tail = tail + 1'b1;
                next_valid[tail+1'b1] = 1'b1;
            end	

            2'b11: begin
				if(branch_recover_in == 2'b00) begin
					next_entries[tail+1'b1]   = retire_tag_in[0];
               	 	next_entries[tail+2'h2] = retire_tag_in[1];
               	 	next_tail = tail + 2'h2;
               		next_valid[tail+1'b1] = 1'b1;
               		next_valid[tail+2'h2] = 1'b1;
				end 
				else if(branch_recover_in == 2'b01) begin 
					next_entries[tail+1'b1] = retire_tag_in[0];
                    next_tail = tail + 2'h1;
					next_valid = 32'b0 - 1'b1;
					next_head = freelist_branch_head_in;
					next_tail = next_head - 2'b1;
				end
				else if(branch_recover_in == 2'b11) begin
					next_entries[tail+1'b1] = retire_tag_in[0];
					next_entries[tail+2'h2] = retire_tag_in[1];
                    next_tail = tail + 2'h2;
					next_head = freelist_branch_head_in;					
					next_tail = next_head - 2'b1;
					next_valid = 32'b0 - 1'b1;	
				end
            end

        endcase

        

        // give free reg in Dispatch
        // retire will always assert [0] first and then [1]
        if(branch_recover_in[0] == 1'b0) begin
            case(dispatch_en_in)		
                2'b00 : begin
                    free_reg_out[0] = `ZERO_REG;		
                    free_reg_out[1] = `ZERO_REG;
                    free_reg_en_o[0] = 1'b0;
                    free_reg_en_o[1] = 1'b0;
                    next_head = head;
                end
                
                2'b01: begin
                    case(free_list_empty)

                        FULL: begin
                            free_reg_out[0] = `ZERO_REG;		
                            free_reg_out[1] = `ZERO_REG;
                            free_reg_en_o[0] = 1'b0;
                            free_reg_en_o[1] = 1'b0;
                            next_valid[head] = 1'b0;
                            next_head = head;                            
                        end

                        ONE_LEFT: begin
                            free_reg_out[0] = valid[head]?entries[head]:retire_tag_in[0]; // if there is a valid, use the entry, else forward		
                            free_reg_out[1] = `ZERO_REG;
                            free_reg_en_o[0] = 1'b1;
                            free_reg_en_o[1] = 1'b0;
                            next_valid[head] = 1'b0;
                            next_head = head + 1'b1;
                        end

                        MORE_LEFT: begin
                            free_reg_out[0] = valid[head]?entries[head]:retire_tag_in[0]; // if there is a valid, use the entry, else forward	
                            free_reg_out[1] = `ZERO_REG;
                            free_reg_en_o[0] = 1'b1;
                            free_reg_en_o[1] = 1'b0;
                            next_valid[head] = 1'b0;
                            next_head = head + 1'b1;
                        end
                    endcase
                end

                2'b10: begin
                    case(free_list_empty)

                        FULL: begin
                            free_reg_out[0] = `ZERO_REG;		
                            free_reg_out[1] = `ZERO_REG;
                            free_reg_en_o[0] = 1'b0;
                            free_reg_en_o[1] = 1'b0;
                            next_head = head;                            
                        end

                        ONE_LEFT: begin
                            free_reg_out[0] = `ZERO_REG; 		
                            free_reg_out[1] = valid[head]?entries[head]:retire_tag_in[0]; // if there is a valid, use the entry, else forward
                            free_reg_en_o[0] = 1'b0;
                            free_reg_en_o[1] = 1'b1;
                            next_valid[head] = 1'b0;
                            next_head = head + 1'b1;
                        end

                        MORE_LEFT: begin
                            free_reg_out[0] = `ZERO_REG;		
                            free_reg_out[1] = valid[head]?entries[head]:retire_tag_in[0]; // if there is a valid, use the entry, else forward
                            free_reg_en_o[0] = 1'b0;
                            free_reg_en_o[1] = 1'b1;
                            next_valid[head] = 1'b0;
                            next_head = head + 1'b1;
                        end
                    endcase                    
                end
                
                2'b11: begin
                    case(free_list_empty)

                        FULL: begin
                            free_reg_out[0] = `ZERO_REG;		
                            free_reg_out[1] = `ZERO_REG;
                            free_reg_en_o[0] = 1'b0;
                            free_reg_en_o[1] = 1'b0;
                            next_head = head;                            
                        end

                        ONE_LEFT: begin // this case won't happen cause the full signal will be examined in the outside control first. It will not request two if there is only one left
                            free_reg_out[0] = valid[head]?entries[head]:retire_tag_in[0]; // if there is a valid, use the entry, else forward		
                            free_reg_out[1] = `ZERO_REG;
                            free_reg_en_o[0] = 1'b1;
                            free_reg_en_o[1] = 1'b0;
                            next_valid[head] = 1'b0;
                            next_head = head + 1'b1;
                        end

                        MORE_LEFT: begin
                            if(valid[head]) begin                           // if there is at least one entry
                                free_reg_out[0] = entries[head];                // use the entry for 0
                                if(valid[head+1'b1]) begin                  // if there are two entries
                                    free_reg_out[1] = entries[head+1'b1];       // use the entries
                                end else begin
                                    free_reg_out[1] = retire_tag_in[0];     // or use the forward for 1
                                end
                            end else begin
                                free_reg_out[0] = retire_tag_in[0];         // if empty, use two forward
                                free_reg_out[1] = retire_tag_in[1];
                            end
                            free_reg_en_o[0] = 1'b1;
                            free_reg_en_o[1] = 1'b1;
                            next_valid[head] = 1'b0;
                            next_valid[head + 1'b1] = 1'b0;
                            next_head = head + 2'h2;
                        end
                    endcase                      
                end
            endcase
        end

	end

    // branch head buffer
    always_comb begin
        next_branch_head = branch_head;
        next_branch_tail = branch_tail;
        next_branch_entries = branch_entries;
        next_branch_valid = branch_valid;
        freelist_branch_head_in = 0;
        
        if(retire_branch_i[0]) begin                                            // if the retired inst is branch
            if(branch_recover_in[0] == 0) begin                                 // if no recover, retire according to retire_branch[1]
                next_branch_valid[next_branch_head] = 1'b0;
                next_branch_valid[next_branch_head + retire_branch_i[1]] = 1'b0;
                next_branch_head = next_branch_head + 1'b1 + retire_branch_i[1];
            end
            else if(branch_recover_in[1] == 0) begin  // if first inst recover, align tail and head (clear all)
                freelist_branch_head_in = next_branch_entries[next_branch_head];
                next_branch_valid = 0;
                next_branch_head = 0;
                next_branch_tail = next_branch_head;
            end
            else if(branch_recover_in[1] == 1) begin // if second inst recover, align tail and head (clear all)
                 freelist_branch_head_in = next_branch_entries[next_branch_head + 1'b1];
                 next_branch_valid = 0;
                 next_branch_head = 0;
                 next_branch_tail = next_branch_head;
            end
        end

        if(dispatch_branch_i[0] && branch_recover_in[0] == 1'b0) begin // if the dispatched inst is branch and no recover
            next_branch_entries[next_branch_tail] = head + dispatch_en_in[0];
            next_branch_valid[next_branch_tail] = 1'b1;
            next_branch_tail = next_branch_tail + 1'b1;
        end

        if(dispatch_branch_i[1] && branch_recover_in[0] == 1'b0) begin
            next_branch_entries[next_branch_tail + dispatch_branch_i[0]] = head + 2'b10;
            next_branch_valid[next_branch_tail + dispatch_branch_i[0]] = 1'b1;
            next_branch_tail = next_branch_tail + 1'b1 + dispatch_branch_i[0];
        end
    end
    



    integer i;
    always_ff@(posedge clk) begin
        if(reset) begin
            head <= `SD 0;
            tail <= `SD `FREELIST_SIZE-1;
            for(i = 0; i < `FREELIST_SIZE; i++) begin
                entries[i] <= `SD (i + `ARCHREG_NUMBER);
            end
            valid <= `FREELIST_SIZE'hffffffff;
            branch_head <= 0;
            branch_tail <= 0;
            branch_entries <= 0;
            branch_valid <= 0;
        end else begin
            head <= next_head;     
            tail <= next_tail;
            entries <= next_entries;
            valid <= next_valid;
            branch_head <= next_branch_head;
            branch_tail <= next_branch_tail;
            branch_entries <= next_branch_entries;
            branch_valid <= next_branch_valid;
        end
    end
endmodule

`endif //__FREELIST_SV__

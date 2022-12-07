module lsq(
    input logic clk,
    input logic reset,
    
    input logic [1:0] dispatch_mem_en_i,

    input logic execute_en_i,
    input logic [1:0] [6:0] opcode_dispatch_i,
    input logic [1:0] [$clog2(`PREG_NUMBER)-1:0] dispatch_dest_reg_i,
    input logic [`XLEN-1:0] opa,
	input logic [`XLEN-1:0] opb,
    input logic [`XLEN-1:0] rs2_value_i,
	input logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_i,
    input logic [1:0] [2:0] mem_funct_i,

    input logic [1:0] retire_mem_en_i,
    input [1:0] branch_recover_i,

    input logic complete_en_i,


    input logic [3:0] mem_response_i,
    input logic [3:0] mem_tag_i,


    input logic mem_valid_i,
    input logic [31:0] mem_data_i,

    input halt,

    output logic [`XLEN-1:0] mem_address_o,
    output logic [1:0] mem_command_o,
    output logic [31:0] mem_wdata_o,
    output MEM_SIZE mem_size_o,
    output logic [1:0] mem_rd_wr_o,

    output logic ready_o,
    output STRUCTURE_FULL lsq_full,

    output logic regfile_wr_en_o,

    output logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_o,
	output logic [`XLEN-1:0] result_o,
    output logic done_o,

    output logic [1:0] [31:0] debug_store_data,
    output logic [1:0] [31:0] debug_store_address,

    //debug for mem
    output logic [$clog2(`LSQ_SIZE)-1:0] debug_next_head,
    output logic [$clog2(`LSQ_SIZE)-1:0] debug_next_retire_ptr,
    output LSQ_ENTRY [`LSQ_SIZE-1:0] debug_lsq_entry
);
    // logic [$clog2(`LSQ_SIZE)-1:0] lsq_entry_valid;

    logic [$clog2(`LSQ_SIZE)-1:0] head;
    logic [$clog2(`LSQ_SIZE)-1:0] next_head;
    logic [$clog2(`LSQ_SIZE)-1:0] tail;
    logic [$clog2(`LSQ_SIZE)-1:0] next_tail;
    logic [$clog2(`LSQ_SIZE)-1:0] retire_ptr;
    logic [$clog2(`LSQ_SIZE)-1:0] next_retire_ptr;

    logic first_cycle_in_execute_stage;
    logic next_first_cycle_in_execute_stage;
    logic first_cycle_in_retire_stage;
    logic next_first_cycle_in_retire_stage;

    enum logic [2:0] {IDLE, EX, RETIRE, WAIT_MEM, COMPLETE} state, next_state;

    LSQ_ENTRY [`LSQ_SIZE-1:0] lsq_entry;
    LSQ_ENTRY [`LSQ_SIZE-1:0] next_lsq_entry;

    logic halt_before;


    logic [3:0] current_mem_tag;
    logic [3:0] next_current_mem_tag;
    logic [$clog2(`LSQ_SIZE)-1:0] ex_lsq_index;
    logic [$clog2(`LSQ_SIZE)-1:0] next_ex_lsq_index;

    logic [$clog2(`LSQ_SIZE)-1:0] tag_loop;
    logic [$clog2(`LSQ_SIZE)-1:0] ex_loop;
    logic [$clog2(`LSQ_SIZE)-1:0] ex_loop_2;
    logic [$clog2(`LSQ_SIZE)-1:0] complete_loop;
    logic [$clog2(`LSQ_SIZE)-1:0] complete_loop_2;

    logic [$clog2(`LSQ_SIZE)-1:0] loop_break_1;
    logic [$clog2(`LSQ_SIZE)-1:0] loop_break_2;
    logic [$clog2(`LSQ_SIZE)-1:0] loop_break_3;
    logic [$clog2(`LSQ_SIZE)-1:0] loop_break_4;
    
    logic dependent_store;
    logic same_address_store;

    BUFFER forward_buffer;
    logic [3:0] four_byte_valid;

    assign debug_next_head = next_head;
    assign debug_next_retire_ptr = retire_ptr;
    assign debug_lsq_entry = lsq_entry;

    always_comb begin
        case(retire_mem_en_i)
            2'b00: begin
                debug_store_data[0] = 0;
                debug_store_data[1] = 0;
            end
            2'b01: begin
                debug_store_data[0] = lsq_entry[head].data;
                debug_store_data[1] = 0;
            end
            2'b11: begin
                debug_store_data[0] = lsq_entry[head].data;
                debug_store_data[1] = lsq_entry[head + 1'b1].data;
            end
            2'b10: begin
                debug_store_data[0] = 0;
                debug_store_data[1] = lsq_entry[head].data;
            end
        endcase
    end
    assign debug_store_address[0] = lsq_entry[head].address;
    assign debug_store_address[1] = lsq_entry[head + 1'b1].address;

    // state transition
    always_comb begin
        dependent_store = 1'b0;
        same_address_store = 1'b0;
        next_state = state;
        next_first_cycle_in_execute_stage = 1'b0;
        next_first_cycle_in_retire_stage = 1'b0;

        case(state)
            IDLE: begin
                if(branch_recover_i[0]) begin
                    next_state = IDLE;
                end else begin

                    if(execute_en_i || (lsq_entry[head].issued_before && (!lsq_entry[head].completed)) &&(lsq_entry[head].opcode == `RV32_LOAD)) begin // head is previously issued but not completed load (not issued store before)
                        next_first_cycle_in_execute_stage = 1'b1;
                        next_state = EX;
                    end
                    else if(retire_ptr != head || retire_mem_en_i[0] || retire_mem_en_i[1]) begin
                        next_first_cycle_in_retire_stage = 1'b1;
                        next_state = RETIRE;
                    end
                end

            end

            EX: begin
                if(branch_recover_i[0]) begin
                    next_state = IDLE;
                end else begin
                    dependent_store = 1'b0;
                    same_address_store = 1'b0;
                    if(lsq_entry[ex_lsq_index].opcode == `RV32_LOAD) begin // if new load, find if there is not issued store before
                        for(ex_loop = 5'b0; ex_loop + 1'b1 < `LSQ_SIZE; ex_loop = ex_loop + 5'b1) begin
                            if(ex_loop <= ex_lsq_index - retire_ptr) begin
                                if(lsq_entry[ex_loop + retire_ptr].opcode == `RV32_STORE) begin
                                    if(!lsq_entry[ex_loop + retire_ptr].issued_before) begin
                                        dependent_store = 1'b1;
                                        same_address_store = 1'b0;
                                    end
                                end
                            end
                        end
                        
                        if(four_byte_valid != 0) begin
                            case(lsq_entry[ex_lsq_index].mem_funct[1:0])
                                BYTE: begin
                                    if(lsq_entry[ex_lsq_index].mem_funct[2]) begin // unsigned
                                        if(four_byte_valid[lsq_entry[ex_lsq_index].address[1:0]]) begin
                                            same_address_store = 1'b1;
                                        end else begin
                                            dependent_store = 1'b1;
                                            same_address_store = 1'b0;
                                        end                            
                                    end else begin // signed
                                        if(four_byte_valid[lsq_entry[ex_lsq_index].address[1:0]]) begin
                                            same_address_store = 1'b1;
                                        end else begin
                                            dependent_store = 1'b1;
                                            same_address_store = 1'b0;                                    
                                        end
                                    end
                                end

                                HALF: begin
                                    if(lsq_entry[ex_lsq_index].mem_funct[2]) begin // unsigned
                                        if(lsq_entry[ex_lsq_index].address[1]) begin
                                            if(four_byte_valid[3] && four_byte_valid[2]) begin
                                                same_address_store = 1'b1;
                                            end else begin
                                                dependent_store = 1'b1;
                                                same_address_store = 1'b0;
                                            end
                                        end else begin
                                            if(four_byte_valid[0] && four_byte_valid[1]) begin
                                                same_address_store = 1'b1;
                                            end else begin
                                                dependent_store = 1'b1;
                                                same_address_store = 1'b0;
                                            end
                                        end
                                    end else begin // signed
                                        if(lsq_entry[ex_lsq_index].address[1]) begin
                                            if(four_byte_valid[3] && four_byte_valid[2]) begin
                                                same_address_store = 1'b1;
                                            end else begin
                                                dependent_store = 1'b1;
                                                same_address_store = 1'b0;
                                            end
                                        end else begin
                                            if(four_byte_valid[0] && four_byte_valid[1]) begin
                                                same_address_store = 1'b1;
                                            end else begin
                                                dependent_store = 1'b1;
                                                same_address_store = 1'b0;                                            
                                            end
                                        end
                                    end
                                end

                                WORD: begin
                                    if(four_byte_valid == 4'b1111) begin
                                        same_address_store = 1'b1;
                                    end else begin
                                        dependent_store = 1'b1;
                                        same_address_store = 1'b0;                                            
                                    end
                                end
                            endcase
                        end
                        

                        if(dependent_store) begin
                            if(retire_ptr != head || retire_mem_en_i[0] || retire_mem_en_i[1]) begin
                                next_first_cycle_in_retire_stage = 1'b1;
                                next_state = RETIRE;
                            end else begin
                                next_state = IDLE;
                            end
                        end else if(same_address_store) begin
                            next_state = COMPLETE;
                        end else begin
                            if(mem_address_o >= `MEM_SIZE_IN_BYTES) begin
                                next_state = IDLE;
                            end
                            if(mem_valid_i) begin
                                next_state = COMPLETE;
                            end                
                        end
                    end else begin
                        next_state = COMPLETE;
                    end
                end            
            end

            RETIRE : begin
                    if(lsq_entry[retire_ptr].opcode == `RV32_STORE) begin // if store, wait for mem resp
                        if(!mem_valid_i) begin
                            next_state = RETIRE;
                        end else if(retire_ptr + 1'b1 != head || retire_mem_en_i[0] || retire_mem_en_i[1]) begin
                            next_first_cycle_in_retire_stage = 1'b1;
                            next_state = RETIRE;
                        end else begin
                            next_state = IDLE;
                        end
                    end
                    else if(lsq_entry[retire_ptr].opcode == `RV32_LOAD) begin // if load, nothing to do
                        if(retire_ptr +1'b1 != head || retire_mem_en_i[0] || retire_mem_en_i[1]) begin
                            next_first_cycle_in_retire_stage = 1'b1;
                            next_state = RETIRE;
                        end
                        else begin
                            next_state = IDLE;
                        end
                    end
            end

            WAIT_MEM : begin
                assert(1==0);
                if(branch_recover_i[0]) begin
                    next_state = IDLE;
                end else begin
                    if(mem_tag_i == current_mem_tag) begin // to complete if transaction ends
                        next_state = COMPLETE;
                    end
                end
            end

            COMPLETE: begin
                if(branch_recover_i[0]) begin
                    next_state = IDLE;
                end else begin
                    if(complete_en_i) begin
                        next_state = IDLE;
                        if(retire_ptr != head || retire_mem_en_i[0] || retire_mem_en_i[1]) begin // direct to retire
                            next_first_cycle_in_retire_stage = 1'b1;
                            next_state = RETIRE;
                        end else begin // if store completed, check if there is a dependent load
                            if(lsq_entry[ex_lsq_index].opcode == `RV32_STORE) begin
                                for(complete_loop = 1'b0; complete_loop + 1'b1 < `LSQ_SIZE; complete_loop = complete_loop + 1'b1) begin
                                    if(complete_loop <= tail - ex_lsq_index)begin
                                        if(lsq_entry[complete_loop + ex_lsq_index].dependent_tag == lsq_entry[ex_lsq_index].dest_tag && lsq_entry[complete_loop + ex_lsq_index].opcode == `RV32_LOAD && lsq_entry[complete_loop + ex_lsq_index].issued_before && !lsq_entry[complete_loop + ex_lsq_index].completed) begin
                                            next_first_cycle_in_execute_stage = 1'b1;
                                            next_state = EX;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        endcase
    end

    // state internal update
    always_comb begin
        //initial
        next_head = head;
        next_lsq_entry = lsq_entry;
        next_tail = tail;
        next_ex_lsq_index = ex_lsq_index;
        next_retire_ptr = retire_ptr;
        next_current_mem_tag = current_mem_tag;
        forward_buffer = 0;
        four_byte_valid = 0;

        next_head = head + retire_mem_en_i[0] + retire_mem_en_i[1]; // retire from pipeline

        if(branch_recover_i[0]) begin
            next_tail = next_head;
            next_lsq_entry[next_tail].issued_before = 1'b0;
            next_lsq_entry[next_tail].completed = 1'b0;
            next_lsq_entry[next_tail].dependent_tag = 0;
        end
        else begin

            // dispatch
            if(dispatch_mem_en_i[0]) begin
                next_lsq_entry[tail].opcode = opcode_dispatch_i[0];
                next_lsq_entry[tail].dest_tag = dispatch_dest_reg_i[0];
                next_lsq_entry[tail].mem_funct = mem_funct_i[0];
                next_lsq_entry[tail].issued_before = 1'b0;
                next_lsq_entry[tail].completed = 1'b0;
                next_lsq_entry[tail].dependent_tag = 0;
                next_tail = tail + 1'b1;

                next_lsq_entry[tail + 1'b1].opcode = 0;
                next_lsq_entry[tail + 1'b1].dest_tag = 0;
                next_lsq_entry[tail + 1'b1].mem_funct = 0;
                next_lsq_entry[tail + 1'b1].issued_before = 1'b0;
                next_lsq_entry[tail + 1'b1].completed = 1'b0;
                next_lsq_entry[tail + 1'b1].dependent_tag = 0;
            end

            if(dispatch_mem_en_i[1]) begin
                next_lsq_entry[tail + dispatch_mem_en_i[0]].opcode = opcode_dispatch_i[1];
                next_lsq_entry[tail + dispatch_mem_en_i[0]].dest_tag = dispatch_dest_reg_i[1];
                next_lsq_entry[tail + dispatch_mem_en_i[0]].mem_funct = mem_funct_i[1];
                next_lsq_entry[tail + dispatch_mem_en_i[0]].issued_before = 1'b0;
                next_lsq_entry[tail + dispatch_mem_en_i[0]].completed = 1'b0;
                next_lsq_entry[tail + dispatch_mem_en_i[0]].dependent_tag = 0;
                next_tail = tail + dispatch_mem_en_i[0] + 1'b1;

                next_lsq_entry[tail + 1'b1 + dispatch_mem_en_i[0]].opcode = 0;
                next_lsq_entry[tail + 1'b1 + dispatch_mem_en_i[0]].dest_tag = 0;
                next_lsq_entry[tail + 1'b1 + dispatch_mem_en_i[0]].mem_funct = 0;
                next_lsq_entry[tail + 1'b1 + dispatch_mem_en_i[0]].issued_before = 1'b0;
                next_lsq_entry[tail + 1'b1 + dispatch_mem_en_i[0]].completed = 1'b0;
                next_lsq_entry[tail + 1'b1 + dispatch_mem_en_i[0]].dependent_tag = 0;
            end
        end

        case(state)
            IDLE: begin
                if(!branch_recover_i[0]) begin
                    if(execute_en_i) begin
                        loop_break_4 = tail - head;
                        for(tag_loop = 5'b0; tag_loop + 1'b1 < `LSQ_SIZE; tag_loop = tag_loop + 5'b1) begin // find data from RS to LSQ ENTRY
                            if(tag_loop < tail - head) begin
                                if(next_lsq_entry[tag_loop + head].dest_tag == dest_reg_i) begin
                                    next_lsq_entry[tag_loop + head].address = opa + opb;
                                    next_lsq_entry[tag_loop + head].data = lsq_entry[tag_loop + head].opcode == `RV32_STORE ? rs2_value_i : 0;
                                    next_ex_lsq_index = tag_loop + head;
                                end
                            end
                        end                    
                    end else if(lsq_entry[head].issued_before && (!lsq_entry[head].completed) &&(lsq_entry[head].opcode == `RV32_LOAD)) begin
                        next_ex_lsq_index = head;
                    end
                end else begin
                    next_lsq_entry[tail].completed = 1'b0;
                    next_lsq_entry[tail].issued_before = 1'b0;
                end
            end

            EX: begin
                if(branch_recover_i[0]) begin
                    next_lsq_entry[ex_lsq_index].issued_before = 1'b0;
                    next_lsq_entry[ex_lsq_index].completed = 1'b0;
                end else begin
                    next_lsq_entry[ex_lsq_index].issued_before = 1'b1;
                    if((lsq_entry[ex_lsq_index].opcode == `RV32_LOAD)) begin // forward address match data (including retired but not back to mem yet)
                        four_byte_valid = 4'b0000;
                        forward_buffer = 0;
                        for(ex_loop_2 = 5'b0; ex_loop_2 +1'b1 < `LSQ_SIZE; ex_loop_2 = ex_loop_2 + 5'b1) begin
                            if(ex_loop_2 <= ex_lsq_index - retire_ptr) begin
                                if(lsq_entry[ex_loop_2 + retire_ptr].opcode == `RV32_STORE) begin
                                    if(lsq_entry[ex_loop_2 + retire_ptr].issued_before) begin
                                        if(lsq_entry[ex_loop_2 + retire_ptr].address[15:2] == lsq_entry[ex_lsq_index].address[15:2]) begin // if there is address match, forward; TODO: multiple match with diff offset          
                                            case(lsq_entry[ex_loop_2 + retire_ptr].mem_funct[1:0])
                                                BYTE: begin
                                                    four_byte_valid[lsq_entry[ex_loop_2 + retire_ptr].address[1:0]] = 1'b1;
                                                    forward_buffer.byte_level[lsq_entry[ex_loop_2 + retire_ptr].address[1:0]] = lsq_entry[ex_loop_2 + retire_ptr].data;
                                                end
                                                HALF: begin
                                                    if(lsq_entry[ex_loop_2 + retire_ptr].address[1]) begin
                                                        four_byte_valid[2] = 1'b1;
                                                        four_byte_valid[3] = 1'b1;
                                                        forward_buffer.half_level[1] = lsq_entry[ex_loop_2 + retire_ptr].data;
                                                    end else begin
                                                        four_byte_valid[0] = 1'b1;
                                                        four_byte_valid[1] = 1'b1;
                                                        forward_buffer.half_level[0] = lsq_entry[ex_loop_2 + retire_ptr].data;
                                                    end
                                                end
                                                WORD: begin
                                                    four_byte_valid = 4'b1111;
                                                    forward_buffer.word_level = lsq_entry[ex_loop_2 + retire_ptr].data;
                                                end
                                            endcase
                                        end 
                                    end else begin
                                        four_byte_valid = 4'b0000;
                                        forward_buffer = 0;
                                        next_lsq_entry[ex_lsq_index].dependent_tag = lsq_entry[ex_loop_2 + retire_ptr].dest_tag;
                                    end
                                end
                            end
                        end
                    end

                    if(same_address_store && !dependent_store) begin
                        case(lsq_entry[ex_lsq_index].mem_funct[1:0])
                            BYTE: begin
                                if(lsq_entry[ex_lsq_index].mem_funct[2]) begin // unsigned
                                    if(four_byte_valid[lsq_entry[ex_lsq_index].address[1:0]]) begin
                                        next_lsq_entry[ex_lsq_index].data = forward_buffer.byte_level[lsq_entry[ex_lsq_index].address[1:0]];
                                    end                            
                                end else begin // signed
                                    if(four_byte_valid[lsq_entry[ex_lsq_index].address[1:0]]) begin
                                        next_lsq_entry[ex_lsq_index].data = {{24{forward_buffer.byte_level[lsq_entry[ex_lsq_index].address[1:0]][7]}}, forward_buffer.byte_level[lsq_entry[ex_lsq_index].address[1:0]][7:0]};
                                    end
                                end
                            end

                            HALF: begin
                                if(lsq_entry[ex_lsq_index].mem_funct[2]) begin // unsigned
                                    if(lsq_entry[ex_lsq_index].address[1]) begin
                                        if(four_byte_valid[3] && four_byte_valid[2]) begin
                                            next_lsq_entry[ex_lsq_index].data = forward_buffer.half_level[1];
                                        end
                                    end else begin
                                        if(four_byte_valid[0] && four_byte_valid[1]) begin
                                            next_lsq_entry[ex_lsq_index].data = forward_buffer.half_level[0];
                                        end
                                    end
                                end else begin // signed
                                    if(lsq_entry[ex_lsq_index].address[1]) begin
                                        if(four_byte_valid[3] && four_byte_valid[2]) begin
                                            next_lsq_entry[ex_lsq_index].data = {{16{forward_buffer.half_level[1][15]}}, forward_buffer.half_level[1][15:0]};
                                        end
                                    end else begin
                                        if(four_byte_valid[0] && four_byte_valid[1]) begin
                                            next_lsq_entry[ex_lsq_index].data = {{16{forward_buffer.half_level[0][15]}}, forward_buffer.half_level[0][15:0]};
                                        end
                                    end
                                end
                            end

                            WORD: begin
                                if(four_byte_valid == 4'b1111) begin
                                    next_lsq_entry[ex_lsq_index].data = forward_buffer.word_level;
                                end
                            end
                        endcase
                    end
                    
                    if(!same_address_store && !dependent_store && lsq_entry[ex_lsq_index].opcode == `RV32_LOAD) begin // if load is in progress
                        if(mem_valid_i) begin
                            case(lsq_entry[ex_lsq_index].mem_funct)
                                3'b010, 3'b100, 3'b101: begin // no sign ext
                                    next_lsq_entry[ex_lsq_index].data = mem_data_i;
                                end
                                3'b000: begin // LB
                                    next_lsq_entry[ex_lsq_index].data = {{24{mem_data_i[7]}}, mem_data_i[7:0]};
                                end
                                3'b001: begin // LH
                                    next_lsq_entry[ex_lsq_index].data = {{16{mem_data_i[15]}}, mem_data_i[15:0]};
                                end
                            endcase
                            next_current_mem_tag = 0;
                        end
                    end
                end
            end

            COMPLETE: begin
                if(branch_recover_i[0]) begin
                    next_lsq_entry[ex_lsq_index].issued_before = 1'b0;
                    next_lsq_entry[ex_lsq_index].completed = 1'b0;
                end else begin
                    next_lsq_entry[ex_lsq_index].completed = 1'b1;
                    if(!(retire_ptr != head || retire_mem_en_i[0] || retire_mem_en_i[1])) begin
                        if(complete_en_i) begin
                            if(lsq_entry[ex_lsq_index].opcode == `RV32_STORE) begin
                                for(complete_loop_2 = 1'b0; complete_loop_2 + 1'b1 < `LSQ_SIZE; complete_loop_2 = complete_loop_2 + 1'b1) begin
                                    if(complete_loop_2 <= tail - ex_lsq_index)begin
                                        if(lsq_entry[complete_loop_2 + ex_lsq_index].dependent_tag == lsq_entry[ex_lsq_index].dest_tag && lsq_entry[complete_loop_2 + ex_lsq_index].opcode == `RV32_LOAD && lsq_entry[complete_loop_2 + ex_lsq_index].issued_before && !lsq_entry[complete_loop_2 + ex_lsq_index].completed) begin
                                            next_ex_lsq_index = complete_loop_2 + ex_lsq_index;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            RETIRE: begin
                if(lsq_entry[retire_ptr].opcode == `RV32_STORE) begin
                    if(mem_valid_i) begin
                        next_retire_ptr = retire_ptr + 1'b1;
                        next_lsq_entry[retire_ptr].completed = 1'b0;
                        next_lsq_entry[retire_ptr].issued_before = 1'b0;
                    end
                end else begin
                        next_retire_ptr = retire_ptr + 1'b1;
                        next_lsq_entry[retire_ptr].completed = 1'b0;
                        next_lsq_entry[retire_ptr].issued_before = 1'b0;                  
                end
            end

            WAIT_MEM: begin
                assert(1==0);
                if(branch_recover_i[0]) begin
                    next_lsq_entry[ex_lsq_index].issued_before = 1'b0;
                    next_current_mem_tag = 0;
                end else begin
                    if(current_mem_tag == mem_tag_i) begin
                        case(next_lsq_entry[ex_lsq_index].mem_funct)
                            3'b010, 3'b100, 3'b101: begin // no sign ext
                                next_lsq_entry[ex_lsq_index].data = mem_data_i;
                            end
                            3'b000: begin // LB
                                next_lsq_entry[ex_lsq_index].data = {{24{mem_data_i[7]}}, mem_data_i[7:0]};
                            end
                            3'b001: begin // LH
                                next_lsq_entry[ex_lsq_index].data = {{16{mem_data_i[15]}}, mem_data_i[15:0]};
                            end
                        endcase
                        next_current_mem_tag = 0;
                    end
                end
            end

        endcase
    end

    // output
    always_comb begin
        ready_o = 1'b0;
        done_o = 1'b0;
        regfile_wr_en_o = 1'b0;
        result_o = 0;
        mem_command_o = BUS_NONE;
        mem_address_o = 0;
        mem_wdata_o = 0;
        dest_reg_o = 0;
        mem_rd_wr_o = BUS_NONE;

        

        case(state)
            IDLE: begin
                if(next_state == IDLE) begin // TODO only ready in idle
                    ready_o = 1'b1;
                end
            end

            EX: begin
                if(lsq_entry[ex_lsq_index].opcode == `RV32_LOAD) begin
                    if(!same_address_store && !dependent_store) begin // if load is in progress
                        mem_address_o = lsq_entry[ex_lsq_index].address;
                        mem_size_o =    lsq_entry[ex_lsq_index].mem_funct;
                        mem_rd_wr_o = BUS_LOAD;
                        if(mem_address_o >= `MEM_SIZE_IN_BYTES) begin
                             mem_command_o = BUS_NONE;
                        end else 
                        if(first_cycle_in_execute_stage) begin
                            mem_command_o = BUS_LOAD;
                        end
                    end
                end
            end

            COMPLETE: begin
                result_o = lsq_entry[ex_lsq_index].data;
                dest_reg_o = lsq_entry[ex_lsq_index].dest_tag;
                
                if(next_state == COMPLETE) begin
                    done_o = 1'b1;
                end else begin
                    if(lsq_entry[ex_lsq_index].opcode == `RV32_LOAD) begin
                        regfile_wr_en_o = 1'b1;
                    end
                end
            end

            RETIRE: begin
                if(lsq_entry[retire_ptr].opcode == `RV32_LOAD) begin
                    mem_command_o = BUS_NONE;
                end else if (lsq_entry[retire_ptr].opcode == `RV32_STORE) begin
                    if(first_cycle_in_retire_stage) begin
                        mem_command_o = BUS_STORE;
                    end
                    mem_size_o = lsq_entry[retire_ptr].mem_funct;
                    mem_address_o = lsq_entry[retire_ptr].address;
                    mem_wdata_o = lsq_entry[retire_ptr].data;
                    mem_rd_wr_o = BUS_STORE;          
                end
            end

            WAIT_MEM: begin
                
            end
        endcase
    end


    always_ff @(posedge clk) begin
        if(reset) begin
            state <= IDLE;
            head <= 0;
            tail <= 0;
            retire_ptr <= 0;
            current_mem_tag <= 0;
            lsq_entry <= 0;
            ex_lsq_index <= 0;
            first_cycle_in_execute_stage <= 0;
            first_cycle_in_retire_stage <= 0;
            halt_before <= 0;
        end
        else begin
            halt_before <= halt_before ? 1'b1 : halt;
            first_cycle_in_execute_stage <= next_first_cycle_in_execute_stage;
            first_cycle_in_retire_stage <= next_first_cycle_in_retire_stage;  
            state <= next_state;
            head <=  next_head;
            tail <= next_tail;
            retire_ptr <= next_retire_ptr;
            current_mem_tag <=  next_current_mem_tag;
            lsq_entry <=  next_lsq_entry;
            ex_lsq_index <=  next_ex_lsq_index;
        end
    end


endmodule








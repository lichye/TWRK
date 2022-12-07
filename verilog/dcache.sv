`define CACHE_LINES 32
`define CACHE_LINE_BITS $clog2(`CACHE_LINES)

module dcache(
    `ifdef DEBUG
    output logic [`CACHE_LINES-1:0] [63:0]                     data,
    output logic [`CACHE_LINES-1:0] [12 - `CACHE_LINE_BITS:0]  tags,
    output logic [`CACHE_LINES-1:0]                            valids,
    output logic [`CACHE_LINES-1:0]                            dirty,
	`endif
    input clk,
    input reset,
    //from mem to cache
    input [3:0]  Dmem2proc_response,
    input [63:0] Dmem2proc_data,
    input [3:0]  Dmem2proc_tag,
    
    //from pipeline to cache
    input [`XLEN-1:0] proc2Dcache_addr,
    input [`XLEN-1:0] proc2Dcache_data,
    input logic [1:0] proc2Dcache_size,
    input logic [1:0] proc2Dcache_rd_wr,
    input logic [1:0] proc2Dcache_command,

    //from cache to mem
    output logic [1:0]       proc2Dmem_command,
    output logic [`XLEN-1:0] proc2Dmem_addr,
    output logic [63:0]      proc2Dmem_data,
    output logic             proc2Dmem_request,

    //from cache to pipeline
    output logic Dcache_valid_out,           // when this is high
    output logic [31:0] Dcache_data_out // value is memory[proc2Icache_addr]
    );

    logic [`CACHE_LINE_BITS - 1:0] current_index, last_index;//5 bits
    logic [12 - `CACHE_LINE_BITS:0] current_tag, last_tag;//one byte

    logic [3:0] current_mem_tag;
    logic miss_outstanding;
    
    logic data_write_enable;
    logic update_mem_tag;
    logic unanswered_miss;

    logic read_evict;
    logic to_be_read_evicted;
    logic write_evict;
    logic to_be_write_evicted;

    //Cache memory
    logic [`CACHE_LINES-1:0] [63:0]                     data;
    logic [`CACHE_LINES-1:0] [12 - `CACHE_LINE_BITS:0]  tags;
    logic [`CACHE_LINES-1:0]                            valids;
    logic [`CACHE_LINES-1:0]                            dirty;
    EXAMPLE_CACHE_BLOCK c;
    EXAMPLE_CACHE_BLOCK d;
    logic read_valid;
    logic write_valid;

    logic [`XLEN-1:0] addr_buffer;
    logic [`XLEN-1:0] next_addr_buffer;
    logic [2:0] current_offset;

    assign read_valid = proc2Dcache_command == BUS_LOAD;
    assign write_valid = proc2Dcache_command == BUS_STORE;

    assign {current_tag, current_index} = (read_valid || write_valid) ? proc2Dcache_addr[15:3] : addr_buffer[15:3];
    assign current_offset = (read_valid || write_valid) ? proc2Dcache_addr[2:0] : addr_buffer[2:0];

    assign data_write_enable = (current_mem_tag == Dmem2proc_tag) && (current_mem_tag != 0) && (!read_valid && !write_valid); //tag 0 is invalid
    assign update_mem_tag = write_valid || read_valid || miss_outstanding || data_write_enable;

    assign unanswered_miss =  (read_valid || write_valid) ? !Dcache_valid_out :
                                       write_evict || read_evict || (miss_outstanding && (Dmem2proc_response == 0)); //response 0 means not accepted

    // triggered by read miss and dirty, reset by response
    assign to_be_read_evicted = read_valid ? !Dcache_valid_out & dirty[current_index] : read_evict && Dmem2proc_response == 0;
    // triggered by write miss and dirty, reset by response
    assign to_be_write_evicted = write_valid ? !Dcache_valid_out & dirty[current_index] : write_evict && Dmem2proc_response == 0;

    assign next_addr_buffer = (read_valid || write_valid) ? proc2Dcache_addr : 32'h0;
    
    always_comb begin
        proc2Dmem_command = BUS_NONE;        
        if( (read_evict && !read_valid && !write_valid) || (write_evict && !write_valid && !read_valid)) begin // evict
            proc2Dmem_command = BUS_STORE;
        end 
        else if(miss_outstanding && !read_valid && !write_valid) begin
            proc2Dmem_command = BUS_LOAD;
        end
    end

    assign proc2Dmem_addr  = (read_evict || write_evict) ? {{16{1'b0}},tags[current_index], current_index, 3'b0} : {addr_buffer[31:3],3'b0};
    assign proc2Dmem_data = data[current_index];

    always_comb begin
        c.half_level = data[current_index];
        c.word_level = data[current_index];
        c.byte_level = data[current_index];
        case (proc2Dcache_size) 
            BYTE: begin
                Dcache_data_out = {24'b0, c.byte_level[current_offset[2:0]]};
            end
            HALF: begin
                // assert(proc2Dcache_addr[0] == 0);

                Dcache_data_out = {16'b0, c.half_level[current_offset[2:1]]};
            end
            WORD: begin
                // assert(proc2Dcache_addr[1:0] == 0);
                Dcache_data_out = c.word_level[current_offset[2]];

            end
            default: begin
            end
		endcase
    end

    assign Dcache_valid_out = valids[current_index] && (tags[current_index] == current_tag);

    // synopsys sync_set_reset "reset"
    always_ff @(posedge clk) begin
        if(reset) begin
            last_index       <= -1;   // These are -1 to get ball rolling when
            last_tag         <= -1;   // reset goes low because addr "changes"
            current_mem_tag  <= 0;
            miss_outstanding <= 0;
            read_evict <= 0;
            write_evict <= 0;
            data <= 0;
            tags <= 0;
            valids <= 0;  
            dirty <= 0;
            addr_buffer <= 0;
        end else begin
            if(read_valid || write_valid) begin
                addr_buffer <= next_addr_buffer;
            end
            if(proc2Dcache_addr == 32'hf704 && proc2Dcache_command == BUS_STORE) begin
                $display("Write: %x, %t \n", proc2Dcache_data, $realtime);
            end
            if(current_index == 5'b00000 && current_tag != 8'b11110111 && proc2Dcache_command == BUS_STORE) begin
                $display("Other: %x, %t \n", proc2Dcache_data, $realtime);
            end
            if(proc2Dcache_addr == 32'hf704 && Dcache_valid_out) begin
                $display("Read: %x, %t \n", Dcache_data_out, $realtime);
            end
            if(proc2Dmem_addr == 32'hf700 && proc2Dmem_command == BUS_STORE) begin
                $display("Evict: %x, %t \n", proc2Dmem_data, $realtime);
            end
            last_index              <= current_index;
            last_tag                <= current_tag;
            miss_outstanding        <= unanswered_miss;
            read_evict              <= to_be_read_evicted;
            write_evict              <= to_be_write_evicted;

            if( (read_evict || write_evict) && Dmem2proc_response != 0) begin  // update after evict
                dirty[current_index] <= 1'b0;                                  // clear dirty when the evict is done
                valids[current_index] <= 1'b0;
            end


            if(update_mem_tag)
                current_mem_tag     <= Dmem2proc_response;

            if(data_write_enable) begin
                data[current_index]     <= Dmem2proc_data;
                tags[current_index]     <= current_tag;
                valids[current_index]   <= 1;
            end

            if(write_valid && Dcache_valid_out) begin // write hit
                d.half_level = data[current_index];
                d.word_level = data[current_index];
                d.byte_level = data[current_index];
                case (proc2Dcache_size) 
                    BYTE: begin
                        d.byte_level[current_offset[2:0]] = proc2Dcache_data[7:0];
                        data[current_index] <= d.byte_level;
                    end
                    HALF: begin
                        d.half_level[current_offset[2:1]] = proc2Dcache_data[15:0];
                        data[current_index] <= d.half_level;
                    end
                    WORD: begin
                        d.word_level[current_offset[2]] = proc2Dcache_data[31:0];
                        data[current_index] <= d.word_level;
                    end
                    default: begin
                        // assert(1==0);
                    end
                endcase
                valids[current_index]   <= 1;
                dirty[current_index]    <= 1;
                tags[current_index]     <= current_tag;
            end

            if(proc2Dcache_rd_wr == BUS_STORE && data_write_enable) begin // write allocate
                d.half_level = Dmem2proc_data;
                d.word_level = Dmem2proc_data;
                d.byte_level = Dmem2proc_data;
                case (proc2Dcache_size) 
                    BYTE: begin
                        d.byte_level[current_offset[2:0]] = proc2Dcache_data[7:0];
                        data[current_index] <= d.byte_level;
                    end
                    HALF: begin
                        d.half_level[current_offset[2:1]] = proc2Dcache_data[15:0];
                        data[current_index] <= d.half_level;
                    end
                    WORD: begin
                        d.word_level[current_offset[2]] = proc2Dcache_data[31:0];
                        data[current_index] <= d.word_level;
                    end
                    default: begin
                        assert(1==0);
                    end
                endcase
                valids[current_index]   <= 1;
                dirty[current_index]    <= 1;
                tags[current_index]     <= current_tag;
            end

        end
    end

endmodule
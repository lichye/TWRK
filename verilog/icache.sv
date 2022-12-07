`define CACHE_LINES 32
`define CACHE_LINE_BITS $clog2(`CACHE_LINES)
`define ASSOCIATIVITY 4

module icache(
    input clk,
    input reset,
    //from mem
    input [3:0]  Imem2proc_response,
    input [63:0] Imem2proc_data,
    input [3:0]  Imem2proc_tag,
    
    //from pipeline
    input [`XLEN-1:0] proc2Icache_addr,
    input             read_valid,//by fetch

    //to pipeline
    output logic Icache_valid_out,      // when this is high
    output logic [63:0] Icache_data_out, // value is memory[proc2Icache_addr]
    

    // to mem
    output logic [1:0] proc2Imem_command,
    output logic [`XLEN-1:0] proc2Imem_addr,
    output logic proc2Imem_request
    );

    logic [`CACHE_LINE_BITS - 1:0] current_index, last_index;//5 bits
    logic [12 - `CACHE_LINE_BITS:0] current_tag, last_tag;//one byte
    logic [$clog2(`ASSOCIATIVITY)-1:0] current_assoc;

    logic [3:0] current_mem_tag;
    logic miss_outstanding;
    
    logic data_write_enable;
    logic update_mem_tag;
    logic unanswered_miss;

    //Cache memory
    logic [`ASSOCIATIVITY-1:0] [`CACHE_LINES-1:0] [63:0]                     data;
    logic [`ASSOCIATIVITY-1:0] [`CACHE_LINES-1:0] [12 - `CACHE_LINE_BITS:0]  tags;
    logic [`ASSOCIATIVITY-1:0] [`CACHE_LINES-1:0]                            valids;
    logic [`CACHE_LINES-1:0] [2:0]                                            lru;

    //assign current_assoc = 0;
    assign proc2Imem_request = 1'b1;

    assign {current_tag, current_index} = proc2Icache_addr[15:3];

    assign data_write_enable = (current_mem_tag == Imem2proc_tag) && (current_mem_tag != 0) && (!read_valid);//tag 0 is invalid
    assign update_mem_tag = read_valid || miss_outstanding || data_write_enable;

    assign unanswered_miss =  read_valid ? !Icache_valid_out :
                                        miss_outstanding && (Imem2proc_response == 0);//response 0 means not accepted

    assign proc2Imem_addr    = {proc2Icache_addr[31:3],3'b0};
    assign proc2Imem_command = (miss_outstanding && !read_valid) ?  BUS_LOAD : BUS_NONE;


    assign Icache_data_out = data[current_assoc][current_index];

    integer i;
    always_comb begin // find assoc
        current_assoc = 0;

        for(i = 0; i < `ASSOCIATIVITY; i++) begin // find hit
            if(valids[i][current_index] && (tags[i][current_index] == current_tag)) begin
                current_assoc = i;
            end
        end

        if(miss_outstanding) begin // if miss, find lru
            current_assoc[1] = !lru[current_index][0];
            current_assoc[0] = !lru[current_index][1'b1 + !lru[current_index][0]];
        end
    end

    assign Icache_valid_out = valids[current_assoc][current_index] && (tags[current_assoc][current_index] == current_tag);

    // synopsys sync_set_reset "reset"
    always_ff @(posedge clk) begin
        if(reset) begin
            last_index       <= `SD -1;   // These are -1 to get ball rolling when
            last_tag         <= `SD -1;   // reset goes low because addr "changes"
            current_mem_tag  <= `SD 0;
            miss_outstanding <= `SD 0;
            data <= 0;
            tags <= 0;
            valids <= `SD 0;
            lru <= `SD 0;  
        end else begin
            last_index              <= `SD current_index;
            last_tag                <= `SD current_tag;
            miss_outstanding        <= `SD unanswered_miss;

            if(update_mem_tag)
                current_mem_tag     <= `SD Imem2proc_response;

            if(read_valid && Icache_valid_out) begin // update LRU when read hit
                lru[current_index]                     <= {lru[current_index][0] == 1'b0 ? !lru[current_index][2] : lru[current_index][2], lru[current_index][0] == 1'b1 ? !lru[current_index][1] : lru[current_index][1], lru[current_index][0] ? 1'b0 : 1'b1};
            end

            if(data_write_enable) begin
                data[current_assoc][current_index]     <= `SD Imem2proc_data;
                tags[current_assoc][current_index]     <= `SD current_tag;
                valids[current_assoc][current_index]   <= `SD 1;
                lru[current_index]                     <= {lru[current_index][0] == 1'b0 ? !lru[current_index][2] : lru[current_index][2], lru[current_index][0] == 1'b1 ? !lru[current_index][1] : lru[current_index][1], lru[current_index][0] ? 1'b0 : 1'b1};
            end
        end
    end

endmodule
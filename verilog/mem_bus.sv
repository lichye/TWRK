module arbiter (
    input clk,
    input reset,
    // from/to icache
    input logic [1:0]  i_pmem_command,
    input logic [31:0] i_pmem_address,
    input logic        i_pmem_request,

    output logic [3:0]  i_pmem_tag,
    output logic [3:0]  i_pmem_response,
    output logic [63:0] i_pmem_rdata,

  // from/to dcache
    input logic [1:0]  d_pmem_command,
    input logic [31:0] d_pmem_address,
    input logic [63:0] d_pmem_wdata,
    input logic        d_pmem_request,

    output logic [3:0]  d_pmem_tag,
    output logic [3:0]  d_pmem_response,
    output logic [63:0] d_pmem_rdata,

    // from/to mem
    input logic [63:0] mem2proc_rdata,
    input logic [3:0]  mem2proc_response,
    input logic [3:0]  mem2proc_tag,

    output logic [1:0] proc2mem_command,
    output logic [31:0] proc2mem_address,
    output logic [63:0] proc2mem_wdata
);

/*************************** Interal Signals ***************************/


/******************************* States ********************************/
enum int unsigned {
    /* List of states */
    start, i_mem_op_wait_resp, i_mem_op_wait_tag, d_mem_op_load_wait_resp, d_mem_op_load_wait_tag, d_mem_op_store_wait_resp
} state, next_state;


/************************** State Transitions **************************/
    always_comb begin
    /* Next state information and conditions (if any)
        * for transitioning between states */	
        next_state = state;


        case(state)
            start : begin
                if(i_pmem_command == BUS_LOAD) begin
                    next_state = i_mem_op_wait_resp;
                end
                else if(d_pmem_command == BUS_LOAD) begin
                    next_state = d_mem_op_load_wait_resp;
                end
                else if(d_pmem_command == BUS_STORE) begin
                    next_state = d_mem_op_store_wait_resp;
                end else begin
                    next_state = start;
                end
            end

            i_mem_op_wait_resp: begin
                if(mem2proc_response == 0) begin
                    if(i_pmem_command == BUS_NONE) begin
                        next_state = start;
                    end
                end else begin
                    next_state = i_mem_op_wait_tag;
                end
            end

            i_mem_op_wait_tag: begin
                if(mem2proc_tag != 0) begin
                    next_state = start;
                end
            end

            d_mem_op_load_wait_resp: begin
                if(mem2proc_response == 0) begin
                    if(d_pmem_command == BUS_NONE) begin
                        next_state = start;
                    end
                end else begin
                    next_state = d_mem_op_load_wait_tag;
                end
            end

            d_mem_op_load_wait_tag: begin
                if(mem2proc_tag != 0) begin
                    next_state = start;
                end
            end

            d_mem_op_store_wait_resp: begin
                if(mem2proc_response == 0) begin
                    if(d_pmem_command == BUS_NONE) begin
                        next_state = start;
                    end
                end else begin
                    next_state = start;
                end
            end

            default: next_state = start;
        endcase
    end


/************************** State Actions **************************/
always_comb begin: state_action
    // defaults
    i_pmem_tag = 0;
    i_pmem_response = 0;
    i_pmem_rdata = 0;

    d_pmem_tag = 0;
    d_pmem_response = 0;
    d_pmem_rdata = 0;

    proc2mem_command = BUS_NONE;
    proc2mem_address = 0;
    proc2mem_wdata = 0;
    
	
    case(state)
        start:;

        i_mem_op_wait_resp: begin
            proc2mem_command = i_pmem_command;
            proc2mem_address = i_pmem_address;
            i_pmem_response = mem2proc_response;
        end

         i_mem_op_wait_tag: begin
            i_pmem_tag = mem2proc_tag;
            i_pmem_rdata =  mem2proc_rdata;
        end

        d_mem_op_load_wait_resp, d_mem_op_store_wait_resp: begin
            proc2mem_command = d_pmem_command;
            proc2mem_address = d_pmem_address;
            proc2mem_wdata = d_pmem_wdata;
            d_pmem_response = mem2proc_response;
        end

        d_mem_op_load_wait_tag: begin
            d_pmem_tag = mem2proc_tag;
            d_pmem_rdata =  mem2proc_rdata;
        end


    endcase
end


    always_ff @(posedge clk) begin
        if(reset) begin
            state <= start;
        end
        else begin
            state <= next_state;
        end
    end


endmodule
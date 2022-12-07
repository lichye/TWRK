module btb(
    input clk,
    input reset,

    input logic  [1:0] [`XLEN-1:0] fetch_pc_i, // pc address of current fetched inst

    input logic [1:0] branch_recover_i,        // if there is a branch recovery in retire stage
    input logic [`XLEN-1:0] recover_addr_i,    // the target addr that will be recoverd to
    input logic [`XLEN-1:0] recover_branch_pc_i,           // pc address of the recovering branch

    input logic [1:0] branch_retire_i,
    input logic [1:0] [`XLEN-1:0] retire_PC_i,

    input [1:0] fetch_branch_en_i,             // if incoming inst is branch

    output logic [1:0] [`XLEN-1:0] predict_addr_o,
    output logic [1:0]             predict_en_o
);

    integer i;
    integer j;

    BTB_ENTRY [`BTB_SIZE-1:0] btb_buffer, next_btb_buffer;

    logic [$clog2(`BTB_SIZE)-1:0] index;
    logic [$clog2(`BTB_SIZE)-1:0] wr_index;


    always_comb begin
        index = 0;
        predict_en_o = 2'b00;
        predict_addr_o = 0;

        for(i = 0; i < 2'h2; i = i + 1'b1) begin                                // predict two fetched inst, output two prediction

            index = fetch_pc_i[i][9:5];

            if(fetch_branch_en_i[i]) begin
                predict_en_o[i] = btb_buffer[index].predictor > 2'h1 ? 1'b1 : 1'b0;
               //  predict_en_o[i] = 1'b0;
                predict_addr_o[i] = predict_en_o[i] ? btb_buffer[index].target : fetch_pc_i[i] + 32'h4;
            end

        end
    end

    always_comb begin
        next_btb_buffer = btb_buffer;

        wr_index = recover_branch_pc_i[9:5];

        if(branch_recover_i[0]) begin                                           // if recover, find corresponding entry and then update. One is sufficient cuz there is only one branch recovery per cycle.
            case(btb_buffer[wr_index].predictor)
            2'h0: begin
                next_btb_buffer[wr_index].predictor = 2'h1;
            end

            2'h1: begin
                next_btb_buffer[wr_index].predictor = 2'h2;
                next_btb_buffer[wr_index].target = recover_addr_i;
            end

            2'h2: begin
                next_btb_buffer[wr_index].predictor = 2'h1;
            end

            2'h3: begin
                next_btb_buffer[wr_index].predictor = 2'h2;
            end
            endcase
        end else begin
            for(j = 0; j < 2'h2; j = j + 1'b1) begin                                // predict two fetched inst, output two prediction
                if(branch_retire_i[j]) begin

                    case(btb_buffer[retire_PC_i[j][9:5]].predictor)
                        2'h0: begin
                            next_btb_buffer[retire_PC_i[j][9:5]].predictor = 2'h0;
                        end

                        2'h1: begin
                            next_btb_buffer[retire_PC_i[j][9:5]].predictor = 2'h0;
                        end

                        2'h2: begin
                            next_btb_buffer[retire_PC_i[j][9:5]].predictor = 2'h3;
                        end

                        2'h3: begin
                            next_btb_buffer[retire_PC_i[j][9:5]].predictor = 2'h3;

                        end
                    endcase
                end
            end
        end

    end


    always_ff @(posedge clk) begin
        if(reset)begin
            btb_buffer <= 0;

            for(int k = 0; k < 32; k++) begin
                btb_buffer[k].predictor <= 1'b1;
                btb_buffer[k].target <= 0;
            end
        end else begin
            btb_buffer <= `SD next_btb_buffer;
        end
    end  

endmodule

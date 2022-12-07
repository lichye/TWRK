
module CDB(
    input clk,
    input reset,

    input logic [`FU_NUMBER-1: 0] FU_complete_i,
    input logic [`FU_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] completed_tag_i,


    output logic [`FU_NUMBER-1: 0] FU_complete_en_o,
    output logic [`SUPERSCALE_WIDTH-1:0] CDB_en_o,
    output logic [`SUPERSCALE_WIDTH-1:0] [$clog2(`PREG_NUMBER)-1: 0] CDB_o

);
    integer i;
    integer j;

    logic [`FU_NUMBER-1: 0] next_FU_complete_en;
    logic [`SUPERSCALE_WIDTH-1:0] next_CDB_en;
    logic [`SUPERSCALE_WIDTH-1:0] [$clog2(`PREG_NUMBER)-1: 0] next_CDB;

    always_comb begin

        next_CDB_en = 0;
        next_CDB = 0;
        j = 0;
        next_FU_complete_en = 0;
        for(i = 0; i < `FU_NUMBER & j < 2'h2; i++) begin // find at most two completed FU; carry and value and send back signal
            if(FU_complete_i[i]) begin
                next_CDB_en[j] = 1'b1;
                next_CDB[j] = completed_tag_i[i];
                next_FU_complete_en[i] = 1'b1;
                j = j + 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if(reset) begin
            CDB_en_o <= 0;
            CDB_o <= 0;
            FU_complete_en_o <= 0;
        end else begin
            CDB_en_o <= next_CDB_en;
            CDB_o <= next_CDB;
            FU_complete_en_o <= next_FU_complete_en;
        end
    end

endmodule
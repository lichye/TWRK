`ifndef __ARCH_TABLE_SV__
`define __ARCH_TABLE_SV__

module arch_table(
    `ifdef DEBUG
    output logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] arch_table_entry_debug,
    `endif
    input clk,
    input reset,
    input [`TABLE_WRITE-1:0][$clog2(`ARCHREG_NUMBER)-1:0] retire_arch_reg_i,               // R, retired physical reg index, from ROB
    input [`TABLE_WRITE-1:0] retire_en_i,                                                  // R, retire enable, from ROB
    input [`TABLE_WRITE-1:0][$clog2(`PREG_NUMBER)-1: 0] new_tag_i,                         // R, tag of retired physical reg, from ROB
    input logic [1:0] branch_recover_i,
    input DEST_REG_SEL [1:0] dest_reg_sel_i,
    output logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] arch_table_recover_o // C, content of the whole Arch Table, to Map Table
);

    logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] arch_table_entry;
    logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] next_arch_table_entry;

    `ifdef DEBUG
    assign arch_table_entry_debug = arch_table_entry;
    `endif

    int k;

    assign arch_table_recover_o = next_arch_table_entry;

    integer j;
    always_comb begin
        next_arch_table_entry = arch_table_entry;
        for(j=0;j<`TABLE_WRITE;j++)   begin
            if (retire_en_i[j]) begin
                if(!(j == 1 && branch_recover_i == 2'b01)) begin // if the first retiring inst recover, the second one will not be retired
                    next_arch_table_entry[retire_arch_reg_i[j]] = dest_reg_sel_i[j] == DEST_RD ? new_tag_i[j] : arch_table_entry[retire_arch_reg_i[j]]; // if the inst does not have dest reg, arch table should not be updated
                end
            end
        end // retire_en_i
    end

    // internal update
    integer i; // loop index
    always_ff @ (posedge clk) begin
        if (reset) begin
            for (i = 0; i < `ARCHREG_NUMBER; i = i + 1) begin
                arch_table_entry[i] <= i;
            end // for
        end else begin // reset
            arch_table_entry <= next_arch_table_entry;
        end // else reset
    end // posedge clk

endmodule
`endif // __ARCH_TABLE_SV__
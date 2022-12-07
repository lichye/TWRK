`ifndef __MAP_TABLE_SV__
`define __MAP_TABLE_SV__

// `timescale 1ns/100ps

module map_table(
    `ifdef DEBUG
	output logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] map_table_entry_Debug, // ARCHREG_NUMBER entries, each entry is $clog2(PREG_NUMBER) bits
    output logic [`ARCHREG_NUMBER-1: 0] map_table_ready_Debug,                             // ARCHREG_NUMBER entries, each is 1 bit
	`endif
    input clk,
    input reset,
    input [`TABLE_READ-1:0][$clog2(`ARCHREG_NUMBER)-1:0] arch_reg_i,               // D, physical register source 1, from ROB
                                                                             
    input [`TABLE_WRITE-1:0][$clog2(`ARCHREG_NUMBER)-1:0] arch_reg_dest_i,         // D, physical register destination, from ROB
    input [`TABLE_WRITE-1:0][$clog2(`PREG_NUMBER)-1: 0] arch_reg_dest_new_tag_i,   // D, new allocated tag, from Free List
    input [`TABLE_WRITE-1:0] new_tag_write_en_i,                                   // D, enable writing new tag, from Free List
    input DEST_REG_SEL [1:0] dest_reg_sel_i,
                                                                             
    input [`CDB_SIZE-1:0][$clog2(`PREG_NUMBER)-1:0] CDB_i,                           // C, CDB broadcsat in Complete, from CDB
    input [`CDB_SIZE-1:0] CDB_en_i,                                          // C, CDB broadcsat in Complete, from CDB
                                                                             
    input branch_recover_i,                                                        // C, from branch result
    input [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] arch_table_recover_i, // C, from Arch Table
                                                                             
    output logic [`TABLE_READ-1:0][$clog2(`PREG_NUMBER)-1: 0] preg_tag_o,          // D, tag of register source 1, to RS
    output logic [`TABLE_READ-1:0] preg_ready_o,                                   // D, ready bit of register source 1, to RS
                                                                             
    output logic [`TABLE_WRITE-1:0][$clog2(`PREG_NUMBER)-1: 0] preg_tag_old_o      // D, old tag of output register to ROB

);
    logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] map_table_entry;       // ARCHREG_NUMBER entries, each entry is $clog2(PREG_NUMBER) bits
    logic [`ARCHREG_NUMBER-1: 0] map_table_ready;                                   // ARCHREG_NUMBER entries, each is 1 bit
    logic [`ARCHREG_NUMBER-1: 0] [$clog2(`PREG_NUMBER)-1: 0] next_map_table_entry;       // ARCHREG_NUMBER entries, each entry is $clog2(PREG_NUMBER) bits
    logic [`ARCHREG_NUMBER-1: 0] next_map_table_ready;                                   // ARCHREG_NUMBER entries, each is 1 bit

    `ifdef DEBUG
        assign map_table_entry_Debug = next_map_table_entry;
        assign map_table_ready_Debug = next_map_table_ready;
    `endif


    always_comb begin
        next_map_table_entry = map_table_entry;
        next_map_table_ready = map_table_ready;

        if (branch_recover_i) begin
            for (int k = 0; k < `ARCHREG_NUMBER; k = k + 1) begin
                next_map_table_entry[k] = arch_table_recover_i[k];
                next_map_table_ready[k] = 1'b1;
            end // for
        end else begin

            // Complete CDB broadcast
            for(int c = 0; c < `TABLE_SIZE; c++) begin
                for(int d = 0;d < `CDB_SIZE; d++) begin
                    if(CDB_en_i[d] & next_map_table_entry[c] == CDB_i[d])
                        next_map_table_ready[c] = 1'b1;
                end
            end

            
            preg_tag_o[0] = next_map_table_entry[arch_reg_i[0]];
            preg_tag_o[1] = next_map_table_entry[arch_reg_i[1]];

            preg_ready_o[0] = arch_reg_i[0] == `ZERO_REG ? 1'b1 : next_map_table_ready[arch_reg_i[0]];
            preg_ready_o[1] = arch_reg_i[1] == `ZERO_REG ? 1'b1 :next_map_table_ready[arch_reg_i[1]];

            if(dest_reg_sel_i[0] == DEST_RD) begin // if the inst does not have a dest reg
                preg_tag_o[2] = arch_reg_i[2] == arch_reg_dest_i[0] ? arch_reg_dest_new_tag_i[0] : next_map_table_entry[arch_reg_i[2]]; // and the source registers of sencond inst equals to the first one, the new tag is forwarded to the second
                preg_tag_o[3] = arch_reg_i[3] == arch_reg_dest_i[0] ? arch_reg_dest_new_tag_i[0] : next_map_table_entry[arch_reg_i[3]];

                preg_ready_o[2] = arch_reg_i[2] == `ZERO_REG ? 1'b1 : arch_reg_i[2] == arch_reg_dest_i[0] ? 1'b0 : next_map_table_ready[arch_reg_i[2]]; // if forwarded, ready is 0
                preg_ready_o[3] = arch_reg_i[3] == `ZERO_REG ? 1'b1 : arch_reg_i[3] == arch_reg_dest_i[0] ? 1'b0 : next_map_table_ready[arch_reg_i[3]];

                preg_tag_old_o[0] = map_table_entry[arch_reg_dest_i[0]];
                preg_tag_old_o[1] = arch_reg_dest_i[1] == arch_reg_dest_i[0] ? arch_reg_dest_new_tag_i[0] : map_table_entry[arch_reg_dest_i[1]]; // if forwarded, the old tag of inst 2 is the new tag of inst 1
            end
            else begin
                preg_tag_o[2] = next_map_table_entry[arch_reg_i[2]];
                preg_tag_o[3] = next_map_table_entry[arch_reg_i[3]];

                preg_ready_o[2] = arch_reg_i[2] == `ZERO_REG ? 1'b1 : next_map_table_ready[arch_reg_i[2]];
                preg_ready_o[3] = arch_reg_i[3] == `ZERO_REG ? 1'b1 : next_map_table_ready[arch_reg_i[3]];

                preg_tag_old_o[0] = map_table_entry[arch_reg_dest_i[0]];
                preg_tag_old_o[1] = map_table_entry[arch_reg_dest_i[1]];                  
            end


            // Dispatch
            for(int i = 0; i < `TABLE_WRITE; i++) begin
                if (new_tag_write_en_i[i]) begin
                    next_map_table_entry[arch_reg_dest_i[i]] = dest_reg_sel_i[i] == DEST_RD ? arch_reg_dest_new_tag_i[i] : map_table_entry[arch_reg_dest_i[i]]; // if an inst does not have dest reg, map table should not be updated
                    next_map_table_ready[arch_reg_dest_i[i]] = dest_reg_sel_i[i] == DEST_RD ? 1'b0 : map_table_ready[arch_reg_dest_i[i]]; // incoming entry is not ready in default
                end
            end // new_tag_write_en_i
        end


    end

    always_ff @(posedge clk) begin
        if(reset) begin
            for (int j = 0; j < `ARCHREG_NUMBER; j = j + 1) begin
                map_table_entry[j] <= j;
                map_table_ready[j] <= 1'b1;
            end // for
        end else begin
            map_table_entry <= next_map_table_entry;
            map_table_ready <= next_map_table_ready;
        end
    end

endmodule // map_table 

`endif // __MAP_TABLE_SV__

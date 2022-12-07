module lsq_testbench;
    logic clk;
    logic reset;
    logic error;

        
    logic [1:0]                      LSQ_dispatch_mem_en_i;
	logic [1:0] [2:0]                LSQ_mem_funct;

    logic                            LSQ_execute_en_i;
    logic [1:0] [6:0]                LSQ_opcode_dispatch_i;
	logic [1:0] [$clog2(`PREG_NUMBER)-1:0] LSQ_dispatch_dest_reg_i;
    logic [`XLEN-1:0]                LSQ_opa;//EX from register file
	logic [`XLEN-1:0]                LSQ_opb;//EX from imm
    logic [`XLEN-1:0]                LSQ_rs2_value_i;//Ex from register fi
	logic [$clog2(`PREG_NUMBER)-1:0] LSQ_dest_reg_i;

    logic [1:0]                      LSQ_retire_mem_en_i;
    logic [1:0]                      LSQ_branch_recover_i;

	logic                            LSQ_complete_en_i;


    STRUCTURE_FULL                   LSQ_lsq_full;

	logic                            LSQ_regfile_wr_en_o;

	logic                            LSQ_mem_valid_i;
    logic [63:0]                LSQ_mem_data_i;
    logic [3:0]                      LSQ_mem_response_i;
    logic [3:0]                      LSQ_mem_tag_i;

    logic [`XLEN-1:0]                LSQ_mem_address_o;
    logic [1:0]                      LSQ_mem_command_o;
    logic [63:0]                LSQ_mem_wdata_o;
    logic [2:0]                      LSQ_mem_size_o;

    logic                            LSQ_ready_o;

    logic [$clog2(`PREG_NUMBER)-1:0] LSQ_dest_reg_o;
	logic [`XLEN-1:0]                LSQ_result_o;
    logic                            LSQ_done_o;

    lsq lsq(
		.reset(reset),
		.clk(clk),

		.dispatch_mem_en_i  (LSQ_dispatch_mem_en_i),
		.mem_funct_i        (LSQ_mem_funct),

		.execute_en_i       (LSQ_execute_en_i),
		.opcode_dispatch_i  (LSQ_opcode_dispatch_i),
		.dispatch_dest_reg_i(LSQ_dispatch_dest_reg_i),
		.opa              	(LSQ_opa),
		.opb              	(LSQ_opb),
		.rs2_value_i        (LSQ_rs2_value_i),
		.dest_reg_i         (LSQ_dest_reg_i),


		.retire_mem_en_i    (LSQ_retire_mem_en_i),
		.branch_recover_i   (LSQ_branch_recover_i),

		.complete_en_i      (LSQ_complete_en_i),

		.lsq_full           (LSQ_lsq_full),
		.regfile_wr_en_o    (LSQ_regfile_wr_en_o),

		.ready_o            (LSQ_ready_o),

		.dest_reg_o         (LSQ_dest_reg_o),
		.result_o           (LSQ_result_o),
		.done_o             (LSQ_done_o),

		.mem_valid_i        (LSQ_mem_valid_i),
		.mem_data_i         (LSQ_mem_data_i),
		.mem_response_i     (LSQ_mem_response_i),
		.mem_tag_i          (LSQ_mem_tag_i),

		.mem_address_o      (LSQ_mem_address_o),
		.mem_command_o      (LSQ_mem_command_o),
		.mem_wdata_o        (LSQ_mem_wdata_o),
		.mem_size_o         (LSQ_mem_size_o),

		.debug_store_data   (LSQ_debug_store_data),
		.debug_store_address(LSQ_debug_store_address)
	);

    // clk generation
    always begin
		#(10/2.0);
		clk = ~clk;
	end

    initial begin
        clk = 1'b0;
        reset = 1;
        error = 0;
        `NEXT_CYCLE;
        reset = 0;
        

        `NEXT_CYCLE;
        if(!error) begin
            $display("\033[32m PASSED \033[0m");
            $display("\033[32m No Error Occurred \033[0m");
        end
        $finish;
    end

endmodule
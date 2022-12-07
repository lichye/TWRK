module regfile_testbench();

	logic clk;
	logic reset;
	logic [4 :0] rda_idx, rdb_idx, rdc_idx, rdd_idx, wra_idx, wrb_idx;
	logic [31:0] wra_data, wrb_data;
	logic wra_en, wrb_en;

	logic [`XLEN-1:0] rda_out, rdb_out, rdc_out, rdd_out;

	regfile rf(
		.clk(clk),
		.reset(reset),
		.rda_idx(rda_idx),
		.rdb_idx(rdb_idx),
		.rdc_idx(rdc_idx),
		.rdd_idx(rdd_idx),
		.wra_idx(wra_idx),
		.wrb_idx(wrb_idx),
		.wra_data(wra_data),
		.wrb_data(wrb_data),
		.wra_en(wra_en),
		.wrb_en(wrb_en),
		
		.rda_out(rda_out),
		.rdb_out(rdb_out),
		.rdc_out(rdc_out),
		.rdd_out(rdd_out)
	);

	always begin
		#(10/2.0);
		clk = ~clk;
	end
	
	initial begin

		clk = 0;
		reset = 0;
		`NEXT_CYCLE;
		reset = 1;
		`NEXT_CYCLE;
		reset = 0;
		rda_idx = 0;
		rdb_idx = 0;
		rdc_idx = 0;
		rdd_idx = 0;
		wra_idx = 0;
		wrb_idx = 0;
		wra_en = 1;
		wrb_en = 1;

		for (int i = 0; i < 32; i = i+2) begin
			wra_idx = i;
			wrb_idx = i + 1;
			
			wra_data = i;
			wrb_data = i + 1;

			@(negedge clk);
		end

		for(int i = 0; i < 32; i = i +4) begin
			rda_idx = i;
			rdb_idx = i + 1;
			rdc_idx = i + 2;
			rdd_idx = i + 3;

			@(negedge clk);

			if(rda_out != i) 
				$display("Fail");
				$finish;
			if(rdb_out != i+1)
				$display("Fail");
				$finish;
			if(rdc_out != i+2)
				$display("Fail");
				$finish;
			if(rdd_out != i+3) begin
				if(!(rdd_out == 0 && rdd_idx == `ZERO_REG))
					$display("Fail");
					$finish;
			end
		end
	end
endmodule
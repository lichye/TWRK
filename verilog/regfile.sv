`ifndef __REGFILE_V__
`define __REGFILE_V__

// `timescale 1ns/100ps

module regfile(
	`ifdef DEBUG
	output [`PREG_NUMBER-1:0] [`XLEN-1:0] value_RF,
	`endif
	
	input clk,
	input reset,

	input [$clog2(`PREG_NUMBER)-1:0] rda_idx, rdb_idx, rdc_idx, rdd_idx, wra_idx, wrb_idx,    // read/write index
	input [`XLEN-1:0] wra_data, wrb_data,           // write data
	input wra_en, wrb_en,

	output logic [`XLEN-1:0] rda_out, rdb_out, rdc_out, rdd_out   // read data
        
);
  
	logic    [`PREG_NUMBER-1:0] [`XLEN-1:0] registers;   // 32, 64-bit Registers

	wire   [`XLEN-1:0] rda_reg = registers[rda_idx];
	wire   [`XLEN-1:0] rdb_reg = registers[rdb_idx];
	wire   [`XLEN-1:0] rdc_reg = registers[rdc_idx];
	wire   [`XLEN-1:0] rdd_reg = registers[rdd_idx];

	assign value_RF = registers;
	//
	// Read port A
	//
	always_comb begin
		if (wra_en && (wra_idx == rda_idx))
			rda_out = wra_data;  // internal forwarding
		else if (wrb_en && (wrb_idx == rda_idx))
			rda_out = wrb_data;
		else
			rda_out = rda_reg;
	end
	//
	// Read port B
	//
	always_comb begin
		if (wra_en && (wra_idx == rdb_idx))
			rdb_out = wra_data;  // internal forwarding
		else if (wrb_en && (wrb_idx == rdb_idx))
			rdb_out = wrb_data;
		else
			rdb_out = rdb_reg;
	end
	//
	// Read port C
	//
	always_comb begin
		if (wra_en && (wra_idx == rdc_idx))
			rdc_out = wra_data;  // internal forwarding
		else if (wrb_en && (wrb_idx == rdc_idx))
			rdc_out = wrb_data;
		else
			rdc_out = rdc_reg;
	end
	//
	// Read port D
	//
	always_comb begin
		if (wra_en && (wra_idx == rdd_idx))
			rdd_out = wra_data;
		else if (wrb_en && (wrb_idx == rdd_idx))
			rdd_out = wrb_data;
		else
			rdd_out = rdd_reg;
	end
	//
	// Write port
	//
	always_ff @(posedge clk) begin
		if(reset) begin
			registers <= 0;
		end else begin
			if (wra_en) begin
				registers[wra_idx] <= `SD wra_data;
			end

			if (wrb_en) begin
				registers[wrb_idx] <= `SD wrb_data;
			end
		end
	end

endmodule // regfile
`endif //__REGFILE_V__

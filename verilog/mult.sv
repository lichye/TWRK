`ifndef __MULT_SV__
`define __MULT_SV__

module mult(
	input clk,
	input reset, 
	input [`XLEN - 1 : 0] opa,
	input [`XLEN - 1 : 0] opb,
	input ALU_FUNC func,
	input logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_i,
    input execute_en_i,
    input complete_en_i,
    input branch_recover_i,

	output logic ready_o,
	output logic done_o,
	output logic regfile_wr_en_o,
	output logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_o,
	output logic [`XLEN-1:0] result_o
);

	logic [1:0] sign_in;
	logic [`XLEN-1:0] mcand_in, mplier_in;
	logic start_in;
	logic [(2* `XLEN)-1:0] product_out;
	logic done_out;
	logic reset_in;

	logic ready_reg;
	logic [$clog2(`PREG_NUMBER)-1:0] dest_reg_reg;
	logic [`XLEN-1:0] result_reg;
	logic done_reg;
	ALU_FUNC mult_funct_reg;

	ALU_FUNC mult_funct;


	//input
	assign mcand_in = opa;
	assign mplier_in = opb;


	//generate sign signal
	always_comb begin
		sign_in = 2'b00;
		if(execute_en_i) begin
			case(mult_funct)
				ALU_MUL:      sign_in = 2'b11;
				ALU_MULH:     sign_in = 2'b11;
				ALU_MULHSU:   sign_in = 2'b01;
				ALU_MULHU:    sign_in = 2'b00;
			endcase
		end
	end

	//contral logic
	always_comb begin
        start_in = 1'b0;
        regfile_wr_en_o = 0;
        reset_in = 0;
		ready_o = ready_reg;
		reset_in = reset;
		done_o = done_out || done_reg;
        dest_reg_o = dest_reg_reg;
		mult_funct = mult_funct_reg;
		if(branch_recover_i == 1'b1) begin
			ready_o = 1'b1;
			done_o = 1'b0;
            reset_in = 1'b1;
		end else begin
			if(complete_en_i) begin
				done_o = 1'b0;
				ready_o = 1'b1;
                reset_in = 1'b1;
                regfile_wr_en_o = 1'b1;
			end
			if(execute_en_i) begin
                start_in = 1'b1;
				ready_o = 1'b0;
				dest_reg_o = dest_reg_i;
				mult_funct = func;
			end
		end
	end

	//output
	always_comb begin
		result_o = result_reg;
		if(done_out == 1'b1) begin
			case (mult_funct)
				ALU_MUL:      result_o = product_out[`XLEN-1:0];
				ALU_MULH:     result_o = product_out[2*`XLEN-1:`XLEN];
				ALU_MULHSU:   result_o = product_out[2*`XLEN-1:`XLEN];
				ALU_MULHU:    result_o = product_out[2*`XLEN-1:`XLEN];

				default:      result_o = `XLEN'hfacebeec;  // here to prevent latches
        	endcase
		end
	end

    always_ff @(posedge clk) begin
        if(reset) begin
			ready_reg <= 1'b1;
			dest_reg_reg <= 0;
			result_reg <= 0;
			done_reg <= 0;
			mult_funct_reg <= 0;
        end else begin
			ready_reg <= ready_o;
			dest_reg_reg <= dest_reg_o;
			result_reg <= result_o;
			done_reg <= done_o;
			mult_funct_reg <= mult_funct;
		end
    end

	mult_in mult_in(
		.clk(clk),
		.reset(reset_in),

		.mcand(mcand_in),
		.start(start_in),
		.mplier(mplier_in),
		.sign(sign_in),

		.product(product_out),
		.done(done_out)
	);







endmodule


module mult_in #(parameter XLEN = 32, parameter NUM_STAGE = 4) (
					input clk, reset,
					input start,
					input [1:0] sign,
					input [XLEN-1:0] mcand, mplier,
					
					output [(2*XLEN)-1:0] product,
					output done
				);
		logic [(2*XLEN)-1:0] mcand_out, mplier_out, mcand_in, mplier_in;
		logic [NUM_STAGE:0][2*XLEN-1:0] internal_mcands, internal_mpliers;
		logic [NUM_STAGE:0][2*XLEN-1:0] internal_products;
		logic [NUM_STAGE:0] internal_dones;
	
		assign mcand_in  = sign[0] ? {{XLEN{mcand[XLEN-1]}}, mcand}   : {{XLEN{1'b0}}, mcand} ;
		assign mplier_in = sign[1] ? {{XLEN{mplier[XLEN-1]}}, mplier} : {{XLEN{1'b0}}, mplier};
	
		assign internal_mcands[0]   = mcand_in;
		assign internal_mpliers[0]  = mplier_in;
		assign internal_products[0] = 'h0;
		assign internal_dones[0]    = start;
	
		assign done    = internal_dones[NUM_STAGE];
		assign product = internal_products[NUM_STAGE];
	
		genvar i;
		for (i = 0; i < NUM_STAGE; ++i) begin : mstage
			mult_stage #(.XLEN(XLEN), .NUM_STAGE(NUM_STAGE)) ms (
				.clk(clk),
				.reset(reset),
				.product_in(internal_products[i]),
				.mplier_in(internal_mpliers[i]),
				.mcand_in(internal_mcands[i]),
				.start(internal_dones[i]),
				.product_out(internal_products[i+1]),
				.mplier_out(internal_mpliers[i+1]),
				.mcand_out(internal_mcands[i+1]),
				.done(internal_dones[i+1])
			);
		end
	endmodule
	
	module mult_stage #(parameter XLEN = 32, parameter NUM_STAGE = 4) (
						input clk, reset, start,
						input [(2*XLEN)-1:0] mplier_in, mcand_in,
						input [(2*XLEN)-1:0] product_in,
	
						output logic done,
						output logic [(2*XLEN)-1:0] mplier_out, mcand_out,
						output logic [(2*XLEN)-1:0] product_out
					);
	
		parameter NUM_BITS = (2*XLEN)/NUM_STAGE;
	
		logic [(2*XLEN)-1:0] prod_in_reg, partial_prod, next_partial_product, partial_prod_unsigned;
		logic [(2*XLEN)-1:0] next_mplier, next_mcand;
	
		assign product_out = prod_in_reg + partial_prod;
	
		assign next_partial_product = mplier_in[(NUM_BITS-1):0] * mcand_in;
	
		assign next_mplier = {{(NUM_BITS){1'b0}},mplier_in[2*XLEN-1:(NUM_BITS)]};
		assign next_mcand  = {mcand_in[(2*XLEN-1-NUM_BITS):0],{(NUM_BITS){1'b0}}};
	
		//synopsys sync_set_reset "reset"
		always_ff @(posedge clk) begin
			prod_in_reg      <= product_in;
			partial_prod     <= next_partial_product;
			mplier_out       <= next_mplier;
			mcand_out        <= next_mcand;
		end
	
		// synopsys sync_set_reset "reset"
		always_ff @(posedge clk) begin
			if(reset) begin
				done     <= 1'b0;
			end else begin
				done     <= start;
			end
		end
	
	endmodule
`endif //__MULT_SV__
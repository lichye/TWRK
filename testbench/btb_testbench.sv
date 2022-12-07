module btb_testbench;
    logic clk;
    logic reset;

    logic branchPredict_en;

     logic [`XLEN-1:0] PC;
    logic branchRecover_en;
     logic predictedAddress;
     logic predictedIfTaken;
     logic error;

     btb btb(
        .clk(clk),
     .reset(reset),

     .branchPredict_en(branchPredict_en),

       .PC(PC),
      .branchRecover_en(branchRecover_en),

      .predictedAddress(predictedAddress),
      .predictedIfTaken(predictedIfTaken)
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
        branchPredict_en=0;
        `NEXT_CYCLE;
        reset = 0;
        PC = 32'd4;
        

        `NEXT_CYCLE;
        if(!error) begin
            $display("\033[32m PASSED \033[0m");
            $display("\033[32m No Error Occurred \033[0m");
        end
        $finish;
    end

endmodule
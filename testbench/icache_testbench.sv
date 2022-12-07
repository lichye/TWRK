module icache_testbench;
    logic clk;
    logic reset;
    logic [3:0]  Imem2proc_response;
    logic [63:0] Imem2proc_data;
    logic [3:0]  Imem2proc_tag;
    logic [`XLEN-1:0] proc2Icache_addr;
    logic read_valid;
    logic Icache_valid_out;
    logic [1:0] proc2Imem_command;
    logic [`XLEN-1:0] proc2Imem_addr;
    logic [63:0] Icache_data_out;
    logic error;
    
    icache icache(
        .clk(clk),
        .reset(reset),
        .Imem2proc_response(Imem2proc_response),
        .Imem2proc_data(Imem2proc_data),
        .Imem2proc_tag(Imem2proc_tag),
        .proc2Icache_addr(proc2Icache_addr),
        .read_valid(read_valid),
        .Icache_valid_out(Icache_valid_out),
        .proc2Imem_command(proc2Imem_command),
        .proc2Imem_addr(proc2Imem_addr),
        .Icache_data_out(Icache_data_out)
    );

        // clk generation
    always begin
		#(10/2.0);
		clk = ~clk;
	end

    always @(error) begin
        if(error) begin
            $display("\033[31m Error Occurred \033[0m");
            $finish;
        end
    end
    
    initial begin
        clk = 1'b0;
        reset = 1'b1;
        Imem2proc_response = 0;
        Imem2proc_data = 0;
        Imem2proc_tag = 0;
            
            //from pipeline
        proc2Icache_addr = 0;
        read_valid = 0;//by fetch
        $finish;
    end
endmodule
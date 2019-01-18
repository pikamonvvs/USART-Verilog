module USART_Controller # (
	parameter CLK_FREQ = 100000000,
    parameter BAUD_RATE = 921600,
	parameter DATA_BIT = 8
	)	(
	input clk,
	input reset,
	output tx,
	input rx,
	// input [7:0] data_to_send,
	input tx_en,
	input rx_en,
	output tx_response;
	output rx_response;
	);

	wire [7:0] data;
	wire tx_en;
	wire rx_en;

	USART_Tx # (
		.CLK_FREQ(CLK_FREQ),
		.BAUD_RATE(BAUD_RATE),
		.DATA_BIT(DATA_BIT)
	) _USART_Tx (
		.clk(clk),
		.reset(reset),
		.tx(tx),
		.data(data_to_send),
		.tx_request(tx_en),
		.tx_response(tx_response)
	);

	USART_Rx # (
		.CLK_FREQ(CLK_FREQ),
		.BAUD_RATE(BAUD_RATE),
		.DATA_BIT(DATA_BIT)
	) _USART_Rx (
		.clk(clk),
		.reset(reset),
		.rx(rx),
		.data(data)
		.rx_request(rx_en),
		.rx_response(rx_response)
	);

endmodule

module USART_Rx # (
	parameter CLK_FREQ = 100000000,
    parameter BAUD_RATE = 921600,
	parameter DATA_BIT = 8
	)	(
	input clk,
	input reset,
	input rx,
	output [7:0] data,
	input rx_request,
	output reg rx_response
	);

	localparam CLKS_TO_SEND = CLK_FREQ / BAUD_RATE;
	localparam CLKS_TO_RECV = CLKS_TO_SEND / 2;

	reg [11:0] rx_clk_count;
	reg [3:0] rx_bit_count;
	reg [7:0] rx_bit;
	reg [7:0] rx_data;
	reg rx_state;
	reg rx_enable;

    initial
    begin
		rx_clk_count = 0;
		rx_bit_count = 0;
		rx_data = 0;
		rx_bit = 0;
		rx_state = 0;
		rx_enable = 0;
		rx_response = 0;
    end

    always @ (rx_request)
    begin
        if (rx_request)
        begin
            rx_enable = 1;
			rx_response = 0;
        end
    end

	always @ (posedge clk)
	begin
		if (reset)
		begin
    		rx_clk_count = 0;
    		rx_bit_count = 0;
    		rx_data = 0;
    		rx_bit = 0;
    		rx_state = 0;
    		rx_enable = 0;
    		rx_response = 0;
		end
		else
		begin
			if (rx_enable && rx_state == 0 && rx == 0)
			begin
				rx_state = 1;
				rx_bit_count = 0;
				rx_clk_count = 0;
			end
			else if (rx_enable && rx_state == 1)
			begin
				if (rx_bit_count == 0 && rx_clk_count == CLKS_TO_RECV)
				begin
					rx_bit_count = 1;
					rx_clk_count = 0;
				end
				else if (rx_bit_count <= DATA_BIT && rx_clk_count == CLKS_TO_SEND)
				begin
					rx_bit[rx_bit_count-1] = rx;
					rx_bit_count = rx_bit_count + 1;
					rx_clk_count = 0;
				end
				else if (rx_bit_count == 9 && rx_clk_count == CLKS_TO_SEND && rx == 1)
				begin
					rx_state = 0;
					rx_clk_count = 0;
					rx_bit_count = 0;
					rx_data = rx_bit;
					rx_enable = 0;
					rx_response = 1;
				end
				else if (rx_bit_count == 9 && rx_clk_count == CLKS_TO_SEND && rx != 1)
				begin
					rx_state = 0;
					rx_clk_count = 0;
					rx_bit_count = 0;
					rx_bit = 0;
					rx_enable = 0;
					rx_response = 1;
				end

				rx_clk_count = rx_clk_count + 1;
			end
		end
	end

	assign data = rx_data;

endmodule

module Testbench_USART_Rx (
	);

	reg clk;
	reg reset;
	wire rx;
	reg [7:0] data;
	reg rx_request;
	wire rx_response;

	USART_Rx _USART_Rx (clk, reset, rx, data, rx_request, rx_response);

	initial
	begin
		clk = 0;
		reset = 0;
		rx_request = 0;
		forever
		begin
			clk = ~clk; #1;
		end
	end

	initial
	begin
		data = 8'h0a; rx_request = 1; #10000;
		$finish;
	end

    always @ (rx)
    begin
        $monitor("rx = %d", rx);
    end

endmodule


module USART_Tx # (
	parameter CLK_FREQ = 100000000,
    parameter BAUD_RATE = 921600,
	parameter DATA_BIT = 8
	)	(
	input clk,
	input reset,
	output tx,
	input [7:0] data,
	input tx_request,
	output reg tx_response
	);

    localparam CLKS_TO_SEND = CLK_FREQ / BAUD_RATE;
	localparam CLKS_TO_RECV = CLKS_TO_SEND / 2;

	reg [11:0] tx_clk_count;
	reg [3:0] tx_bit_count;
	reg [7:0] tx_data;
	reg tx_bit;
	reg tx_enable;

    initial
    begin
		tx_clk_count = 0;
		tx_bit_count = 0;
		tx_data = 0;
		tx_bit = 1;
		tx_enable = 0;
		tx_response = 0;
    end
    
    always @ (data or tx_request)
    begin
        if (tx_request)
        begin
            tx_enable = 1;
			tx_response = 0;
        end
    end

	always @ (posedge clk)
	begin
		if (reset)
		begin
			tx_clk_count = 0;
			tx_bit_count = 0;
			tx_data = 0;
			tx_bit = 1;
			tx_enable = 0;
			tx_response = 0;
		end
		else
		begin
			if (tx_enable && tx_clk_count == CLKS_TO_SEND)
			begin
				if (tx_bit_count == 0)
				begin
					tx_bit = 1;
					tx_data = data;
					tx_bit_count = tx_bit_count + 1;
				end
				else if (tx_bit_count == 1)
				begin
					tx_bit = 0;
					tx_bit_count = tx_bit_count + 1;
				end
				else if (2 <= tx_bit_count && tx_bit_count <= DATA_BIT + 1)
				begin
					tx_bit = tx_data[tx_bit_count-2];
					tx_bit_count = tx_bit_count + 1;
				end
				else
				begin
					tx_bit = 1;
					tx_bit_count = 0;
					tx_enable = 0;
					tx_response = 1;
				end
				tx_clk_count = 0;
			end
			tx_clk_count = tx_clk_count + 1;
		end
	end

	assign tx = tx_bit;

endmodule

module Testbench_USART_Tx (
	);

	reg clk;
	reg reset;
	wire tx;
	reg [7:0] data;
	reg tx_request;
	wire tx_response;

	USART_Tx _USART_Tx (clk, reset, tx, data, tx_request, tx_response);

	initial
	begin
		clk = 0;
		reset = 0;
		tx_request = 0;
		forever
		begin
			clk = ~clk; #1;
		end
	end

	initial
	begin
		data = 8'h0a; tx_request = 1; #10000;
		$finish;
	end

    always @ (tx)
    begin
        $monitor("tx = %d", tx);
    end

endmodule

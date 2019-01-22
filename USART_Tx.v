`ifndef __USART_TX_V__
`define __USART_TX_V__

module USART_Controller_tb (
	);
	reg clk;
	reg reset;
	wire tx;
	reg rx;

	USART_Controller unit1(clk, reset, tx, rx);

	initial
	begin
		clk <= 1'b0;
		reset <= 1'b0;
		rx <= 1'b1;
		forever
		begin
			#1 clk = ~clk;
		end
	end

	initial
	begin
		rx <= 1'b1; #434;
		rx <= 1'b0; #868;
		rx <= 1'b0; #868;
		rx <= 1'b1; #868;
		rx <= 1'b0; #868;
		rx <= 1'b1; #868;
		rx <= 1'b0; #868;
		rx <= 1'b0; #868;
		rx <= 1'b0; #868;
		rx <= 1'b0; #868;
		rx <= 1'b1; #868;
		#10000;
		$finish;
	end

endmodule

module USART_Controller # (
	parameter CLK_FREQ = 100000000,
	parameter BAUD_RATE = 115200,
	parameter DATA_BIT = 8
	)  (
	input clk,
	input reset,
	output tx,
	input rx
	);

	wire [7:0] _data;
	wire enable;

	USART_Tx # (
		.CLK_FREQ(CLK_FREQ),
		.BAUD_RATE(BAUD_RATE),
		.DATA_BIT(DATA_BIT)
	) _USART_Tx (
		.clk(clk),
		.reset(reset),
		.tx(tx),
		._data(_data),
		.enable(enable)
	);

	USART_Rx # (
		.CLK_FREQ(CLK_FREQ),
		.BAUD_RATE(BAUD_RATE),
		.DATA_BIT(DATA_BIT)
	) _USART_Rx (
		.clk(clk),
		.reset(reset),
		.rx(rx),
		._data(_data),
		.enable(enable)
	);

endmodule

module USART_Tx # (
	parameter CLK_FREQ = 100000000,
	parameter BAUD_RATE = 115200,
	parameter DATA_BIT = 8
	)   (
	input clk,
	input reset,
	output tx,
	input [7:0] _data,
	input enable
	);

	localparam CLKS_FOR_SEND = CLK_FREQ / BAUD_RATE;

	reg [7:0] data;
	reg [7:0] tx_data;
	reg [3:0] tx_bit_count;
	reg [11:0] tx_clk_count;
	reg tx_bit;
	reg tx_en;

	initial
	begin
		data <= 0;
		tx_data <= 0;
		tx_bit_count <= 0;
		tx_clk_count <= 0;
		tx_bit <= 1'b0;
		tx_en <= 1'b0;
	end

	always @ (posedge clk)
	begin
		if (reset)
		begin
			tx_data = 0;
			tx_bit_count = 0;
			tx_clk_count = 0;
			tx_bit = 1'b0;
		end
		else
		begin
			if (tx_en != enable)
			begin
				if (tx_clk_count == CLKS_FOR_SEND)
				begin
					if (tx_bit_count == 0)
					begin
						tx_bit = 1;
						tx_bit_count = 1;
						tx_data = data;
					end
					else if (tx_bit_count == 1)
					begin
						tx_bit = 0;
						tx_bit_count = 2;
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
						tx_en = tx_en + 1;
					end
					tx_clk_count = 0;
				end
				tx_clk_count = tx_clk_count + 1;
			end
		end
	end

	assign tx = tx_bit;

	always @ (_data)
	begin
		data <= _data;
	end

endmodule


module USART_Rx # (
	parameter CLK_FREQ = 100000000,
	parameter BAUD_RATE = 115200,
	parameter DATA_BIT = 8
	)   (
	input clk,
	input reset,
	input rx,
	output [7:0] _data,
	output enable
	);

	localparam CLKS_FOR_SEND = CLK_FREQ / BAUD_RATE;
	localparam CLKS_FOR_RECV = CLKS_FOR_SEND / 2;

	reg [7:0] data;
	reg [7:0] rx_data;
	reg [3:0] rx_bit_count;
	reg [11:0] rx_clk_count;
	reg rx_state;
	reg rx_en;

	initial
	begin
		data <= 0;
		rx_data <= 0;
		rx_bit_count <= 0;
		rx_clk_count <= 0;
		rx_state <= 1'b0;
		rx_en <= 1'b0;
	end

	always @ (posedge clk)
	begin
		if (reset)
		begin
			rx_data = 0;
			rx_bit_count = 0;
			rx_clk_count = 0;
			rx_state = 1'b0;
		end
		else
		begin
			if (rx_state == 0 && rx == 0)
			begin
				rx_state = 1;
				rx_bit_count = 0;
				rx_clk_count = 0;
			end
			else if (rx_state == 1)
			begin
				if(rx_bit_count == 0 && rx_clk_count == CLKS_FOR_RECV)
				begin
					rx_bit_count = 1;
					rx_clk_count = 0;
				end
				else if(1 <= rx_bit_count && rx_bit_count <= DATA_BIT && rx_clk_count == CLKS_FOR_SEND)
				begin
					rx_data[rx_bit_count-1] = rx;
					rx_bit_count = rx_bit_count + 1;
					rx_clk_count = 0;
				end
				else if(rx_bit_count > DATA_BIT && rx_clk_count == CLKS_FOR_SEND && rx == 1)
				begin
					rx_state = 0;
					rx_clk_count = 0;
					rx_bit_count = 0;
					rx_en = rx_en + 1;
					data = rx_data;
				end
				else if(rx_bit_count > DATA_BIT && rx_clk_count == CLKS_FOR_SEND && rx != 1)
				begin
					rx_state = 0;
					rx_clk_count = 0;
					rx_bit_count = 0;
					rx_data = 8'b00000000;
				end
				rx_clk_count = rx_clk_count + 1;
			end
		end
	end

	assign enable = rx_en;
	assign _data = data;

endmodule

`endif /*__USART_TX_V__*/

`ifndef __USART_TX_V__
`define __USART_TX_V__

module USART_Tx # (
	parameter CLK_FREQ = 100000000,
	parameter BAUD_RATE = 115200,
	parameter DATA_BITS = 8,
	parameter STOP_BITS = 1
	)   (
	input clk,
	input reset,
	output tx,
	input [DATA_BITS-1:0] _data,
	input enable,
	output reg response
	);

	localparam CLKS_FOR_SEND = CLK_FREQ / BAUD_RATE;

	reg [DATA_BITS-1:0] data;
	reg [DATA_BITS-1:0] tx_data;
	reg [$clog2(DATA_BITS):0] tx_bit_count;
	reg [$clog2(CLKS_FOR_SEND)-1:0] tx_clk_count;
	reg tx_bit;
	reg tx_en;

	initial
	begin
		data <= 0;
		tx_data <= 0;
		tx_bit_count <= 0;
		tx_clk_count <= 0;
		tx_bit <= 0;
		tx_en <= 0;
		response <= 0;
	end

	always @ (posedge clk)
	begin
		if (reset)
		begin
			tx_data = 0;
			tx_bit_count = 0;
			tx_clk_count = 0;
			tx_bit = 0;
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
					else if (2 <= tx_bit_count && tx_bit_count <= DATA_BITS + 1)
					begin
						tx_bit = tx_data[tx_bit_count-2];
						tx_bit_count = tx_bit_count + 1;
					end
					else if (DATA_BITS + 2 <= tx_bit_count && tx_bit_count < DATA_BITS + STOP_BITS + 1)
					begin
						tx_bit = 1;
						tx_bit_count = tx_bit_count + 1;
					end
					else
					begin
						tx_bit = 1;
						tx_bit_count = 0;
						tx_en = tx_en + 1;
						response = 1;
					end
					tx_clk_count = 0;
				end
				tx_clk_count = tx_clk_count + 1;
			end
		end
	end

	always @ (negedge clk)
	begin
		if (response)
		begin
			response = 0;
		end
	end

	assign tx = tx_bit;

	always @ (_data)
	begin
		data <= _data;
	end

endmodule

`endif /*__USART_TX_V__*/

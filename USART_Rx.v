`ifndef __USART_RX_V__
`define __USART_RX_V__

module USART_Rx # (
	parameter CLK_FREQ = 100000000,
	parameter BAUD_RATE = 115200,
	parameter DATA_BITS = 8,
	parameter STOP_BITS = 1
	)   (
	input clk,
	input reset,
	input rx,
	output [DATA_BITS-1:0] _data,
	output enable,
	output reg response
	);

	localparam CLKS_FOR_SEND = CLK_FREQ / BAUD_RATE;
	localparam CLKS_FOR_RECV = CLKS_FOR_SEND / 2;

	reg [DATA_BITS-1:0] data;
	reg [DATA_BITS-1:0] rx_data;
	reg [$clog2(DATA_BITS):0] rx_bit_count;
	reg [$clog2(CLKS_FOR_SEND)-1:0] rx_clk_count;
	reg rx_state;
	reg rx_en;

	initial
	begin
		data <= 0;
		rx_data <= 0;
		rx_bit_count <= 0;
		rx_clk_count <= 0;
		rx_state <= 0;
		rx_en <= 0;
		response <= 0;
	end

	always @ (posedge clk)
	begin
		if (reset)
		begin
			rx_data = 0;
			rx_bit_count = 0;
			rx_clk_count = 0;
			rx_state = 0;
		end
		else
		begin
			response = 0;
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
				else if(1 <= rx_bit_count && rx_bit_count <= DATA_BITS && rx_clk_count == CLKS_FOR_SEND)
				begin
					rx_data[rx_bit_count-1] = rx;
					rx_bit_count = rx_bit_count + 1;
					rx_clk_count = 0;
				end
				else if(rx_bit_count > DATA_BITS && rx_clk_count == CLKS_FOR_SEND && rx == 1)
				begin
					rx_state = 0;
					rx_clk_count = 0;
					rx_bit_count = 0;
					rx_en = rx_en + 1;
					data = rx_data;
					response = 1;
				end
				else if(rx_bit_count > DATA_BITS && rx_clk_count == CLKS_FOR_SEND && rx != 1)
				begin
					rx_state = 0;
					rx_clk_count = 0;
					rx_bit_count = 0;
					rx_data = 0;
				end
				rx_clk_count = rx_clk_count + 1;
			end
		end
	end

	assign enable = rx_en;
	assign _data = data;

endmodule

`endif /*__USART_RX_V__*/

`ifndef __USART_RX_V__
`define __USART_RX_V__

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

`endif /*__USART_RX_V__*/

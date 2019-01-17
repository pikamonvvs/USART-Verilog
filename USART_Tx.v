`ifndef __USART_TX_V__ // 미완성
`define __USART_TX_V__

module USART_Tx # (
    parameter CLK_FREQ = 100000000, // 100MHz
    parameter BAUD_RATE = 115200, // 115200
    parameter CLKS_TO_SEND = CLK_FREQ / BAUD_RATE; // 1비트를 전송하기 위해 기다려야 하는 클럭 수
	parameter CLKS_TO_RECV = CLKS_TO_SEND / 2,
	parameter DATA_BIT = 8,
	parameter NUM_OF_BUFS = 16
	)	(
	input clk,
	input reset,
	output tx
	)

	localparam CLK_PER_BIT = CLK_FREQ / BAUD_RATE;
	localparam CLOCKS_WAIT_FOR_RECEIVE = CLOCKS_PER_BIT / 2,

	reg [11:0] tx_clk_count; // clock count-  tx_clk_count는 
	reg [3:0] tx_bit_count; // 쓰기 시작할 때 0~9까지 이동한다.
	reg [7:0] tx_data; //  count=0 때 데이터를 data_buffer에서 가져옴
	reg tx_bit; // 써야 하는 비트, tx_data에서 한 비트씩 가져옴

	reg [3:0] data_buffer_index_tx;
	reg [3:0] data_buffer_index_rx;
	reg [7:0] data_buffer[0:NUM_OF_BUFS];

	assign tx = tx_bit;

	// Transmitter Process at every rising edge of the clock
	always @ (posedge clk)
	begin
		if (reset)
		begin
			tx_clk_count = 0;
			tx_bit_count = 0;
			tx_bit = 1; // set idle
			data_buffer_index_tx = 0; // data index
		end
		else begin
			// transmit data until the index became the same with the base index
			if (data_buffer_index_tx != data_buffer_index_rx) // rx index는 다 받고 나면 +1돼서 빈 버퍼를 가리킬 거고, tx index는 rx index보다 낮으면 지금거를 보내고 위로 올라갈 거임.
			begin
				if (tx_clk_count == CLKS_TO_SEND)
				begin
					if (tx_bit_count == 0) // to be stable
					begin
						tx_bit = 1; // idle bit
						tx_bit_count = 1;
						tx_data = data_buffer[data_buffer_index_tx];
					end
					else if (tx_bit_count == 1)
					begin
						tx_bit = 0; // start bit
						tx_bit_count = 2;
					end
					else if (tx_bit_count < DATA_BIT + 2)
					begin
						tx_bit = tx_data[tx_bit_count-2]; // data bits
						tx_bit_count = tx_bit_count + 1;
					end
					else
					begin
						tx_bit = 1; // stop bit
						data_buffer_index_tx = data_buffer_index_tx + 1; // if the index exceeds its maximum, it becomes 0. 다 보내면 +1.
						tx_bit_count = 0;
					end
					tx_clk_count = 0; // reset clock count
				end

				tx_clk_count = tx_clk_count + 1; // increase clock count
			end
		end
	end

endmodule

`endif /*__USART_TX_V__*/
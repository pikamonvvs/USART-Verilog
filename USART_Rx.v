module USART_Rx # (
    parameter CLK_FREQ = 100000000, // 100MHz
    parameter BAUD_RATE = 115200, // 115200
	parameter DATA_BIT = 8
	)	(
	);

	reg clk;
	reg reset;
	reg rx;

    localparam CLKS_TO_RECV = CLK_FREQ / BAUD_RATE / 2,
	reg [11:0] rx_clk_count;
	reg [3:0] rx_bit_count;
	reg [7:0] rx_data;
	reg rx_state;
	
	initial
	begin
		clk = 1'b0;
		reset = 1'b0;
		forever
		begin
			clk = ~clk;
		end
	end
	
	initial
	begin
		rx = 1'b0;
		rx = 1'b0;
		rx = 1'b1;
		rx = 1'b0;
		rx = 1'b1;
		rx = 1'b0;
		rx = 1'b1;
		rx = 1'b0;
		rx = 1'b1;
		rx = 1'b1;
	end
	
	// Receiver Processs at every rising edge of the clock
	always @ (posedge clk)
	begin
		if (reset)
		begin
			rx_clk_count = 0;
			rx_bit_count = 0;
			rx_state = 0;
		end
		else
		begin
			// if not receive mode and start bit is detected
			if (rx_state == 0 && rx == 0)
			begin
				rx_state = 1; // enter receive mode
				rx_bit_count = 0;
				rx_clk_count = 0;
			end
			// if receive mode
			else if (rx_state == 1)
			begin
				if (rx_bit_count == 0 && rx_clk_count == CLKS_TO_RECV)
				begin
					rx_bit_count = 1;
					rx_clk_count = 0;
				end
				else if (rx_bit_count <= DATA_BIT && rx_clk_count == CLKS_TO_SEND)
				begin
					rx_data[rx_bit_count-1] = rx;
					rx_bit_count = rx_bit_count + 1;
					rx_clk_count = 0;
				end
				// stop receiving
				else if (rx_bit_count == 9 && rx_clk_count == CLKS_TO_SEND && rx == 1) // data bit는 다 읽었고 rx=1로 stop bit를 받으면? 데이터를 버퍼에 넣고 정리 정돈
				begin
					rx_state = 0;
					rx_clk_count = 0;
					rx_bit_count = 0;
				end
				// if stop bit is not received, clear the received data
				else if (rx_bit_count == 9 && rx_clk_count == CLKS_TO_SEND && rx != 1) // 반대로 stop bit가 안들어왔으면? 방금 받은 데이터는 폐기
				begin
					rx_state = 0;
					rx_clk_count = 0;
					rx_bit_count = 0;
					rx_data = 8'b00000000; // invalidate
				end

				rx_clk_count = rx_clk_count + 1;
			end
		end

	end
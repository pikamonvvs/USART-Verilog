`ifndef __USART_CONTROLLER_V__
`define __USART_CONTROLLER_V__

`include "USART_Tx.v"
`include "USART_Rx.v"

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

	wire [7:0] tx_data;
	wire [7:0] rx_data;
	wire tx_enable;
	wire rx_enable;

	USART_Tx # (
		.CLK_FREQ(CLK_FREQ),
		.BAUD_RATE(BAUD_RATE),
		.DATA_BIT(DATA_BIT)
	) _USART_Tx (
		.clk(clk),
		.reset(reset),
		.tx(tx),
		._data(tx_data),
		.enable(tx_enable)
	);

	USART_Rx # (
		.CLK_FREQ(CLK_FREQ),
		.BAUD_RATE(BAUD_RATE),
		.DATA_BIT(DATA_BIT)
	) _USART_Rx (
		.clk(clk),
		.reset(reset),
		.rx(rx),
		._data(rx_data),
		.enable(rx_enable)
	);

	// setting for loopback
	assign tx_data = rx_data;
	assign tx_enable = rx_enable;

endmodule

`endif /*__USART_CONTROLLER_V__*/

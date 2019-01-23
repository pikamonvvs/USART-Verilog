`include "USART_Controller.v"

module USART_Controller_tb (
	);
	reg clk;
	reg reset;
	wire tx;
	reg rx;
	wire tx_response;
	wire rx_response;

	USART_Controller unit1(clk, reset, tx, rx, tx_response, rx_response);

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
		rx <= 1'b1; #868; // I don't know whether this is correct...
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

	always @ (*)
	begin
		$monitor("tx = %b", tx);
	end

endmodule

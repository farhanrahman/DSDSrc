module BLUR(CCD_FIFO_WRCLK, iSW, P1RedOut, P1GreenOut, P1BlueOut, CCD_FIFO_WE, CCD_FIFO_IN);

input			CCD_FIFO_WRCLK;
input	[29:0]	CCD_FIFO_IN;
input			CCD_FIFO_WE;

input	[17:0]	iSW;

output [10:0] P1RedOut;
output [10:0] P1GreenOut;
output [10:0] P1BlueOut;

reg[10:0] P1Red,P2Red,P3Red,P4Red,P5Red,P6Red,P7Red,P8Red,P9Red;
reg[10:0] P1Blue,P2Blue,P3Blue,P4Blue,P5Blue,P6Blue,P7Blue,P8Blue,P9Blue;
reg[10:0] P1Green,P2Green,P3Green,P4Green,P5Green,P6Green,P7Green,P8Green,P9Green;

/*reg[29:0] P1Red_s;
reg[29:0] P1Blue_s;
reg[29:0] P1Green_s;*/

wire [29:0] fifoRed1_output; 
wire [29:0] fifoRed2_output;

wire [29:0] fifoGreen1_output; 
wire [29:0] fifoGreen2_output;

wire [29:0] fifoBlue1_output; 
wire [29:0] fifoBlue2_output;		
	
screen_fifo fifoRed1(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P7Red),//P3),
	.shiftout(fifoRed1_output),
	.clken(CCD_FIFO_WE),
	.taps());
	
screen_fifo fifoRed2(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P4Red),//P6),
	.shiftout(fifoRed2_output),
	.clken(CCD_FIFO_WE),
	.taps());
	

screen_fifo fifoGreen1(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P7Green),//P3),
	.shiftout(fifoGreen1_output),
	.clken(CCD_FIFO_WE),
	.taps());
	
screen_fifo fifoGreen2(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P4Green),//P6),
	.shiftout(fifoGreen2_output),
	.clken(CCD_FIFO_WE),
	.taps());
	
screen_fifo fifoBlue1(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P7Blue),//P3),
	.shiftout(fifoBlue1_output),
	.clken(CCD_FIFO_WE),	
	.taps());
	
screen_fifo fifoBlue2(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P4Blue),//P6),
	.shiftout(fifoBlue2_output),
	.clken(CCD_FIFO_WE),
	.taps());

always@(posedge CCD_FIFO_WRCLK)
begin
	P9Red <= CCD_FIFO_IN[29:20];
	P9Green <= CCD_FIFO_IN[19:10];
	P9Blue <= CCD_FIFO_IN[9:0];
	
	P8Red <= P9Red;
	P8Green <= P9Green;
	P8Blue <= P9Blue;
	
	P7Red <= P8Red;
	P7Green <= P8Green;
	P7Blue <= P8Blue;
	
	P6Red <= fifoRed1_output;
	P6Green <= fifoGreen1_output;	
	P6Blue <= fifoBlue1_output;	
	
	P5Red <= P6Red;
	P5Green <= P6Green;
	P5Blue <= P6Blue;

	P4Red <= P5Red;
	P4Green <= P5Green;
	P4Blue <= P5Blue;
	
	P3Red <= fifoRed2_output;
	P3Green <= fifoGreen2_output;
	P3Blue <= fifoBlue2_output;
	
	P2Red <= P3Red;
	P2Green <= P3Green;
	P2Blue <= P3Blue;
	
	
	if(iSW[16] == 1)
	begin
		P1Red <= (P1Red + P2Red + P3Red + P4Red + P5Red + P6Red + P7Red + P8Red + P9Red)/9;
		P1Green <= (P1Green + P2Green + P3Green + P4Green + P5Green + P6Green + P7Green + P8Green + P9Green)/9;
		P1Blue <= (P1Blue + P2Blue + P3Blue + P4Blue + P5Blue + P6Blue + P7Blue + P8Blue + P9Blue)/9;
	end
	else
	begin
		P1Red <= P2Red;
		P1Green <= P2Green;	
		P1Blue <= P2Blue;		
	end
end

/*always@(posedge CCD_FIFO_WRCLK)
begin
	P1Red_s <= P1Red;
	P1Green_s <= P1Green;
	P1Blue_s <= P1Blue;
end	*/

assign P1RedOut = P1Red;
assign P1BlueOut = P1Blue;
assign P1GreenOut = P1Green;

endmodule

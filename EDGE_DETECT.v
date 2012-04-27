module EDGE_DETECT(CCD_FIFO_WRCLK, iSW, edgeDetectSumOutput, CCD_FIFO_WE, P1Red, P1Green, P1Blue);

input	CCD_FIFO_WRCLK;
input	CCD_FIFO_WE;
input	[17:0]	iSW;

output [29:0] edgeDetectSumOutput; //sum of maskX + sum of maskY convolution
reg	[29:0] edgeDetectSum; //sum of maskX + sum of maskY convolution

input[10:0] P1Red;
input[10:0] P1Blue;
input[10:0] P1Green;

reg signed [29:0] maskEdgeX [8:0];
reg signed [29:0] maskEdgeY [8:0];


reg signed [29:0] SumTopRowX;
reg signed [29:0] SumMidRowX;
reg signed [29:0] SumBotRowX;

reg signed [29:0] SumTopRowY;
reg signed [29:0] SumMidRowY;
reg signed [29:0] SumBotRowY;

reg [9:0] RGBSum;

reg signed [31:0] SumX;
reg signed [31:0] SumY;

initial
begin
	maskEdgeX[0] = -1;
	maskEdgeX[1] =  0;
	maskEdgeX[2] =	1;
	maskEdgeX[3] = -2;
	maskEdgeX[4] =	0;
	maskEdgeX[5] = 	2;
	maskEdgeX[6] = -1;
	maskEdgeX[7] = 	0;
	maskEdgeX[8] = 	1;
	
	maskEdgeY[0] = 	1;
	maskEdgeY[1] = 	2;
	maskEdgeY[2] =	1;
	maskEdgeY[3] = 	0;
	maskEdgeY[4] =	0;
	maskEdgeY[5] =	0; 
	maskEdgeY[6] = -1;
	maskEdgeY[7] = -2;
	maskEdgeY[8] = -1;
	
end               

reg[29:0] P1,P2,P3,P4,P5,P6,P7,P8,P9;

wire [29:0] EFIFO1_output; 
wire [29:0] EFIFO2_output;
wire [29:0] EFIFO1_input; 
wire [29:0] EFIFO2_input;

screen_fifo EFIFO1(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P7),//P3),
	.shiftout(EFIFO1_output),
	.clken(CCD_FIFO_WE),
	.taps());
	
screen_fifo EFIFO2(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P4),//P6),
	.shiftout(EFIFO2_output),
	.clken(CCD_FIFO_WE),
	.taps());

	
always@(posedge CCD_FIFO_WRCLK)
begin
	if(iSW[17] == 1)
	begin
		RGBSum = (P1Red + P1Green + P1Blue)/3;
		P9[9:0]   <= RGBSum;
		P9[19:10] <= RGBSum;
		P9[29:20] <= RGBSum;
	end
	else
	begin
		P9[9:0]   <= P1Blue;
		P9[19:10] <= P1Green;
		P9[29:20] <= P1Red;
	end
	//RGBSum <= (CCD_FIFO_IN[9:0] + CCD_FIFO_IN[19:10] + CCD_FIFO_IN[29:20])/3;
	//RGBSum <= (P1Red_s + P1Blue_s + P1Green_s)/3;	
	P8 <= P9;
	P7 <= P8;
	P6 <= EFIFO1_output;
	P5 <= P6;
	P4 <= P5;
	P3 <= EFIFO2_output;
	P2 <= P3;
	P1 <= P2; 	

	SumTopRowX <= maskEdgeX[0]*P9 + maskEdgeX[1]*P8 + maskEdgeX[2]*P7;
	SumMidRowX <= maskEdgeX[3]*P6 + maskEdgeX[4]*P5 + maskEdgeX[5]*P4;
	SumBotRowX <= maskEdgeX[6]*P3 + maskEdgeX[7]*P2 + maskEdgeX[8]*P1;
	
	SumTopRowY <= maskEdgeY[0]*P9 + maskEdgeY[1]*P8 + maskEdgeY[2]*P7;
	SumMidRowY <= maskEdgeY[3]*P6 + maskEdgeY[4]*P5 + maskEdgeY[5]*P4;
	SumBotRowY <= maskEdgeY[6]*P3 + maskEdgeY[7]*P2 + maskEdgeY[8]*P1;
	
	SumX <= SumTopRowX + SumMidRowX + SumBotRowX;
	
	SumY <= SumTopRowY + SumMidRowY + SumBotRowY;
	
	if(iSW[17] == 1)
	begin
		edgeDetectSum = (($signed(SumX) < 0 ? -$signed(SumX) : SumX) + ($signed(SumY) < 0 ? -$signed(SumY) : SumY));
		
		/*if(edgeDetectSum > 30'd1073741823)
		begin
			edgeDetectSum = 1073741824;
		end*/
			
	end
	else
	begin
		edgeDetectSum = P1;
	end
	
end

assign edgeDetectSumOutput = edgeDetectSum;

endmodule

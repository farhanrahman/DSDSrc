

// DSD Coursework
// SRAM Controller module for DE2-70 FPGA board
// LTM Version


module SRAM_Controller(
		//	HOST Side
        CLK,
        RESET_N,
		iSW,
		//	Input FIFO
		CCD_FIFO_WRCLK,
		CCD_FIFO_IN,
		CCD_FIFO_WE,
		CCD_FIFO_FULL,
		//	Output FIFO
		DISP_FIFO_RDCLK,
		DISP_FIFO_OUT,
		DISP_FIFO_RD,
		DISP_FIFO_EMPTY,
		//	SRAM Side
		ioSRAM_DATA,
		SRAM_ADDRESS,
		SRAM_ADSC_N,
		SRAM_ADSP_N,
		SRAM_ADV_N,
		SRAM_BE_N,
		SRAM_CE1_N,
		SRAM_CE2,
		SRAM_CE3_N,
		SRAM_CLK,
		SRAM_GW_N,
		SRAM_OE_N,
		SRAM_WE_N
        );

		//	HOST Side
input			CLK;
input			RESET_N;
input	[17:0]	iSW;
		//	Input FIFO
input			CCD_FIFO_WRCLK;
input	[29:0]	CCD_FIFO_IN;
input			CCD_FIFO_WE;
output			CCD_FIFO_FULL;
		//	Output FIFO
input			DISP_FIFO_RDCLK;
output	[23:0]	DISP_FIFO_OUT;
input			DISP_FIFO_RD;
output			DISP_FIFO_EMPTY;
		//	SRAM Side
inout	[31:0]	ioSRAM_DATA;
output	[18:0]	SRAM_ADDRESS;
output			SRAM_ADSC_N;
output			SRAM_ADSP_N;
output			SRAM_ADV_N;
output	[3:0]	SRAM_BE_N;
output			SRAM_CE1_N;
output			SRAM_CE2;
output			SRAM_CE3_N;
output			SRAM_CLK;
output			SRAM_GW_N;
output			SRAM_OE_N;
output			SRAM_WE_N;



	

//-----------------------------------------------------------------------------------------------------//
//	Signals

reg		[3:0]	STATE;			//State number of state machine

wire			CCD_FIFO_RD;	//Read signal for input FIFO
wire	[29:0]	CCD_FIFO_OUT;	//Data output from input FIFO
wire	[9:0]	CCD_FIFO_USED;	//Number of words in CCD FIFO
wire			CCD_FIFO_EMPTY,DISP_FIFO_FULL;
wire			DISP_FIFO_WE;	//Write signal for output FIFO
wire	[23:0]	DISP_FIFO_IN;	//Data input for output FIFO
wire	[9:0]	DISP_FIFO_USED; //Number of words in output FIFO
wire	[7:0]	DISP_RED,DISP_GREEN,DISP_BLUE; //RGB Display data

wire	[31:0]	SRAM_DATA;		//Output register for SRAM write
reg		[18:0]	SRAM_ADDRESS;	//SRAM address
wire			SRAM_WE_N;		//SRAM write enable
wire			SRAM_OE_N;		//SRAM read
wire			SRAM_ADSC_N;	//These signals are not properly explained in the datasheet
wire			SRAM_ADSP_N;	//Some sort of operation initialisation

assign 	SRAM_ADV_N = 0;			// These SRAM control signals are always fixed
assign 	SRAM_BE_N = 4'b0000;
assign 	SRAM_CE1_N = 0;
assign 	SRAM_CE2 = 1;
assign 	SRAM_CE3_N = 0;
assign 	SRAM_CLK = CLK;
assign 	SRAM_GW_N = 1;

reg		[18:0]	STORE_ADDRESS;	//SRAM pointer for incoming data
reg				ADDRESS_VALID;	//Address valid flag

wire	[19:0]	TRANS_ADDRESS;	//Calculated SRAM pointer for outgoing data
wire			TRANS_READY_N;	//Ready signal for address calculation
wire			ADDRESS_RD;		//Signal to begin the generation of the read address
wire			READ_READY;
 

//-----------------------------------------------------------------------------------------------------//
//	Parameters

// These define the display attributes
parameter	DISPLAY_WIDTH = 800;
parameter	DISPLAY_HEIGHT = 480;
parameter	INPUT_WIDTH = 800;
parameter	INPUT_HEIGHT = 480;

// These initialise the SRAM read and write locations
// Necessary to account for the latency in streaming data through the system
// Also clears the last address in the memory which is used when the display pixel is out of range
//parameter	STORE_ADD_INIT = 19'h7ffff;
parameter	STORE_ADD_INIT = INPUT_WIDTH*INPUT_HEIGHT-1;
//parameter STORE_ADD_INIT = 0;

// These define the values of the STATE variable
parameter	DATA_IN_HOLD = 4'h9;
parameter	DATA_OUT_WAIT = 4'hd;
parameter	DATA_OUT_LATCH = 4'hf;
parameter	INIT = 4'h0, IDLE_SETUP = 4'h1;


reg [29:0] edgeDetectSum; //sum of maskX + sum of maskY convolution

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

	/*maskEdgeX[0] = 1;
	maskEdgeX[1] = 2;
	maskEdgeX[2] =	1;
	maskEdgeX[3] = 2;
	maskEdgeX[4] =	4;
	maskEdgeX[5] = 2;
	maskEdgeX[6] = 1;
	maskEdgeX[7] = 2;
	maskEdgeX[8] = 1;
	              
	maskEdgeY[0] = 1;
	maskEdgeY[1] = 1;
	maskEdgeY[2] =	1;
	maskEdgeY[3] = 1;
	maskEdgeY[4] =	1;
	maskEdgeY[5] =	1; 
	maskEdgeY[6] = 1;
	maskEdgeY[7] = 1;
	maskEdgeY[8] = 1;	*/	
end               


//-----------------------------------------------------------------------------------------------------//
//	Pixel Transformation and Address Calculation
PIXEL_MAP PT1(
		.CLK(CLK),
		.RESET_N(RESET_N),
		.iREAD(ADDRESS_RD),
		.iSW(iSW[17:0]),
		.oADDRESS(TRANS_ADDRESS),
		.oREADY_N(TRANS_READY_N)
		);
		
//-----------------------------------------------------------------------------------------------------//
//	FIFOS
		
reg[29:0] P1,P2,P3,P4,P5,P6,P7,P8,P9;

reg[29:0] P1Red,P2Red,P3Red,P4Red,P5Red,P6Red,P7Red,P8Red,P9Red;
reg[29:0] P1Blue,P2Blue,P3Blue,P4Blue,P5Blue,P6Blue,P7Blue,P8Blue,P9Blue;
reg[29:0] P1Green,P2Green,P3Green,P4Green,P5Green,P6Green,P7Green,P8Green,P9Green;

reg[29:0] P1Red_s;
reg[29:0] P1Blue_s;
reg[29:0] P1Green_s;

wire [29:0] EFIFO1_output; 
wire [29:0] EFIFO2_output;
wire [29:0] EFIFO1_input; 
wire [29:0] EFIFO2_input;		
		
wire [29:0] fifoRed1_output; 
wire [29:0] fifoRed2_output;

wire [29:0] fifoGreen1_output; 
wire [29:0] fifoGreen2_output;

wire [29:0] fifoBlue1_output; 
wire [29:0] fifoBlue2_output;		
		
wire [29:0] CCD_Input;		
		
CCD_FIFO	CCD_FIFO_inst (
		.aclr (~RESET_N),
		.data (CCD_Input),//edgeDetectSum),
		.rdclk (CLK),
		.rdreq (CCD_FIFO_RD),
		.wrclk (CCD_FIFO_WRCLK),
		.wrreq (CCD_FIFO_WE),
		.q (CCD_FIFO_OUT),
		.rdusedw (CCD_FIFO_USED),
		.wrfull (CCD_FIFO_FULL)
	);
	
	

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

	
/*screen_fifo fifoRed1(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P7Red),//P3),
	.shiftout(fifoRed1_output),
	.taps());
	
screen_fifo fifoRed2(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P4Red),//P6),
	.shiftout(fifoRed2_output),
	.taps());
	

screen_fifo fifoGreen1(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P7Green),//P3),
	.shiftout(fifoGreen1_output),
	.taps());
	
screen_fifo fifoGreen2(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P4Green),//P6),
	.shiftout(fifoGreen2_output),
	.taps());
	
screen_fifo fifoBlue1(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P7Blue),//P3),
	.shiftout(fifoBlue1_output),
	.taps());
	
screen_fifo fifoBlue2(
	.clock(CCD_FIFO_WRCLK),
	.shiftin(P4Blue),//P6),
	.shiftout(fifoBlue2_output),
	.taps());
	
	
	//This is for edge detection

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
	
	P1Red <= P2Red;
	P1Green <= P2Green;	
	P1Blue <= P2Blue;		
end

always@(posedge CCD_FIFO_WRCLK)
begin
	P1Red_s <= P1Red;
	P1Green_s <= P1Green;
	P1Blue_s <= P1Blue;
end	*/
	
always@(posedge CCD_FIFO_WRCLK)
begin
/*	P9 <= CCD_FIFO_IN;
	P8 <= P9;
	P7 <= P8;
	//EFIFO1_input <= P7;
	P6 <= EFIFO1_output;
	P4 <= P5;
	//EFIFO2_input <= P4;
	P3 <= EFIFO2_output;
	P2 <= P3;
	P1 <= P2;*/
	/*RGBSum <= (CCD_FIFO_IN[9:0] + CCD_FIFO_IN[19:10] + CCD_FIFO_IN[29:20])/3;
	P1[9:0]   <= RGBSum;
	P1[19:10] <= RGBSum;
	P1[29:20] <= RGBSum;
	P1 = CCD_FIFO_IN;
	P2 = P1;
	P3 = P2;
	P4 = EFIFO1_output;
	P5 = P4;
	P6 = P5;
	P7 = EFIFO2_output;
	P8 = P7;
	P9 = P8;*/
	
	RGBSum = (CCD_FIFO_IN[9:0] + CCD_FIFO_IN[19:10] + CCD_FIFO_IN[29:20])/3;
	P9[9:0]   <= RGBSum;
	P9[19:10] <= RGBSum;
	P9[29:20] <= RGBSum;
	
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
	
	
	
	
	/*SumTopRowX = $signed($signed(maskEdgeX[0])*P1 + $signed(maskEdgeX[2])*P3);
	SumMidRowX = $signed($signed(maskEdgeX[3])*P4 + $signed(maskEdgeX[5])*P6);
	SumBotRowX = $signed($signed(maskEdgeX[6])*P7 + $signed(maskEdgeX[8])*P9);
	
	SumTopRowY = $signed($signed(maskEdgeY[0])*P1 + $signed(maskEdgeY[1])*P2 + $signed(maskEdgeY[2])*P3);
	SumMidRowY = 0;
	SumBotRowY = $signed($signed(maskEdgeY[6])*P7 + $signed(maskEdgeY[7])*P8 + $signed(maskEdgeY[8])*P9);*/

	SumTopRowX <= maskEdgeX[0]*P9 + maskEdgeX[1]*P8 + maskEdgeX[2]*P7;
	SumMidRowX <= maskEdgeX[3]*P6 + maskEdgeX[4]*P5 + maskEdgeX[5]*P4;
	SumBotRowX <= maskEdgeX[6]*P3 + maskEdgeX[7]*P2 + maskEdgeX[8]*P1;
	
	SumTopRowY <= maskEdgeY[0]*P9 + maskEdgeY[1]*P8 + maskEdgeY[2]*P7;
	SumMidRowY <= maskEdgeY[3]*P6 + maskEdgeY[4]*P5 + maskEdgeY[5]*P4;
	SumBotRowY <= maskEdgeY[6]*P3 + maskEdgeY[7]*P2 + maskEdgeY[8]*P1;
	
	SumX <= SumTopRowX + SumMidRowX + SumBotRowX;
	
	SumY <= SumTopRowY + SumMidRowY + SumBotRowY;
	
	edgeDetectSum = (($signed(SumX) < 0 ? -$signed(SumX) : SumX) + ($signed(SumY) < 0 ? -$signed(SumY) : SumY));	
	
end

/*always@(posedge CLK)
begin
	edgeDetectSum[9:0]   <= (P1Blue + P2Blue + P3Blue + P4Blue + P5Blue + P6Blue + P7Blue + P8Blue + P9Blue)/9;
	edgeDetectSum[19:10] <= (P1Green + P2Green + P3Green + P4Green + P5Green + P6Green + P7Green + P8Green + P9Green)/9;
	edgeDetectSum[29:20] <= (P1Red + P2Red + P3Red + P4Red + P5Red + P6Red + P7Red + P8Red + P9Red)/9;
end*/

assign CCD_Input = iSW[17] == 1 ? edgeDetectSum : P1;

	

assign CCD_FIFO_EMPTY = (CCD_FIFO_USED[9:2] == 8'h00);	//Stop reading when FIFO contains less than 4 words
assign DISP_FIFO_FULL = (DISP_FIFO_USED[9:2] == 8'hff); //Stop writing when FIFO contains less than 4 spaces
	
DISP_FIFO	DISP_FIFO_inst (
		.aclr (~RESET_N),
		.data (DISP_FIFO_IN),
		.rdclk (DISP_FIFO_RDCLK),
		.rdreq (DISP_FIFO_RD),
		.wrclk (CLK),
		.wrreq (DISP_FIFO_WE),
		.q (DISP_FIFO_OUT),
		.rdempty (DISP_FIFO_EMPTY),
		.wrusedw (DISP_FIFO_USED)
	);	
		
//-----------------------------------------------------------------------------------------------------//
//	Datapath assignments
//Input to display FIFO comes from memory data bus
assign 	DISP_FIFO_IN = {DISP_RED,DISP_GREEN,DISP_BLUE};
//Multiplexers to blank display at invalid addresses
assign	DISP_RED = (ADDRESS_VALID ? ioSRAM_DATA[29:22] : 8'h01);
assign	DISP_GREEN = (ADDRESS_VALID ? ioSRAM_DATA[19:12] : 8'h01);
assign	DISP_BLUE = (ADDRESS_VALID ? ioSRAM_DATA[9:2] : 8'h01);

//Set SRAM data bus to high-impedance when SRAM output is enabled
assign	ioSRAM_DATA = (SRAM_OE_N ? SRAM_DATA : 32'hzzzz);
assign	SRAM_DATA = {2'h0,CCD_FIFO_OUT};
//Test Patterns
//assign	SRAM_DATA = {STORE_ADDRESS[18],STORE_ADDRESS[18],8'h00,STORE_ADDRESS[7],STORE_ADDRESS[7],8'h00,STORE_ADDRESS[3],STORE_ADDRESS[3],8'h00};//{STORE_ADDRESS[17:2],STORE_ADDRESS[17:2]};
/*assign	SRAM_DATA = {(STORE_ADDRESS[4:0] == 5'h00),(STORE_ADDRESS[4:0] == 5'h00),8'h00,
					(STORE_ADDRESS[18:5] > 14'h2ede),(STORE_ADDRESS[18:5] > 14'h2ede),8'h00,
					(STORE_ADDRESS[18:5] == 14'h0000),(STORE_ADDRESS[18:5] == 14'h0000),8'h00};*/


//-----------------------------------------------------------------------------------------------------//
//	State machine and registered outputs
//	Controls STATE and Read Address Latch
always@(posedge CLK or negedge RESET_N)
begin
	if(RESET_N==0)
	begin
		STATE <= INIT;
		ADDRESS_VALID <= 0;
	end
	else
	begin
		case(STATE)
		
		DATA_IN_HOLD: begin			//Hold second write to memory, FIFO is read at the end of this state
			if (READ_READY)			//Check FIFO status to decide next action
			begin
				STATE <= IDLE_SETUP;
			end
			else if (~CCD_FIFO_EMPTY)
				STATE <= DATA_IN_HOLD;//SET;
			else
				STATE <= IDLE_SETUP;
									//Increment store address
			if (STORE_ADDRESS == INPUT_WIDTH*INPUT_HEIGHT-1)
				STORE_ADDRESS <= 0;					//Wrap to buffer size
			else
				STORE_ADDRESS <= STORE_ADDRESS+19'h1;
		end
		
		DATA_OUT_WAIT:
			STATE <= DATA_OUT_LATCH;
			
		DATA_OUT_LATCH: begin
			if	(READ_READY)
			begin
				STATE <= DATA_OUT_WAIT;
				ADDRESS_VALID <= TRANS_ADDRESS[19];
			end
			else if (~CCD_FIFO_EMPTY)
				STATE <= DATA_IN_HOLD;
			else
				STATE <= IDLE_SETUP;
		end	
				 				
		IDLE_SETUP: begin						//Idle state when CCD FIFO is empty and display FIFO is full
			if	(READ_READY)
			begin
				STATE <= DATA_OUT_WAIT;
				ADDRESS_VALID <= TRANS_ADDRESS[19];
			end
			else if (~CCD_FIFO_EMPTY)
				STATE <= DATA_IN_HOLD;
			else
				STATE <= IDLE_SETUP;
		end
		
		INIT: begin						//Initial State, used to initialise store address
			STATE <= IDLE_SETUP;	
			STORE_ADDRESS <= STORE_ADD_INIT;		//Initialise Store Address
		end
		
		default: begin					//Illegal states behave like INIT
			STATE <= IDLE_SETUP;	
		end
		
		endcase
	end
end

//-----------------------------------------------------------------------------------------------------//
//	State machine combinatorial outputs

//Signal to indicate when read is possible
assign	READ_READY = (!DISP_FIFO_FULL && !TRANS_READY_N);

//Signals to read and write FIFOs		
assign CCD_FIFO_RD = (STATE == DATA_IN_HOLD);
assign DISP_FIFO_WE = (STATE == DATA_OUT_LATCH);

//Read next address translation after the previous one has been latched
assign ADDRESS_RD = (((STATE == IDLE_SETUP) && READ_READY) || ((STATE == DATA_OUT_LATCH) && READ_READY));

//Combinatorial output for SRAM Address
always@(STATE,CCD_FIFO_OUT,STORE_ADDRESS,TRANS_ADDRESS)
begin
	case(STATE)
	DATA_IN_HOLD: begin
	SRAM_ADDRESS <= {STORE_ADDRESS};
	end
	
	DATA_OUT_WAIT: begin
	SRAM_ADDRESS <= {TRANS_ADDRESS[18:0]};
	end
	
	DATA_OUT_LATCH: begin
	SRAM_ADDRESS <= {TRANS_ADDRESS[18:0]};
	end
	
	IDLE_SETUP: begin
	SRAM_ADDRESS <= {TRANS_ADDRESS[18:0]};
	end
	
	default: begin								//IDLE, INIT and illegal states
	SRAM_ADDRESS <= {STORE_ADDRESS};		//This has no effect except to simplify logic
	end
	
	endcase
end

//SRAM Control Signals
assign SRAM_WE_N = ~(STATE == DATA_IN_HOLD);
assign SRAM_OE_N = ~(STATE == DATA_OUT_LATCH);
assign SRAM_ADSC_N = ~(STATE == DATA_IN_HOLD);
assign SRAM_ADSP_N = ~(((STATE == IDLE_SETUP) && READ_READY) || ((STATE == DATA_OUT_LATCH) && READ_READY));


endmodule
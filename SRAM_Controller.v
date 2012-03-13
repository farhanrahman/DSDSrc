

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

wire [29:0] EFIFO1_output; 
wire [29:0] EFIFO2_output;
wire [29:0] EFIFO1_input; 
wire [29:0] EFIFO2_input;		
		
CCD_FIFO	CCD_FIFO_inst (
		.aclr (~RESET_N),
		.data (P9),
		.rdclk (CLK),
		.rdreq (CCD_FIFO_RD),
		.wrclk (CCD_FIFO_WRCLK),
		.wrreq (CCD_FIFO_WE),
		.q (CCD_FIFO_OUT),
		.rdusedw (CCD_FIFO_USED),
		.wrfull (CCD_FIFO_FULL)
	);
	
	


	
screen_fifo EFIFO1(
	.clock(CLK),
	.shiftin(P3),
	.shiftout(EFIFO1_output),
	.taps());
	
screen_fifo EFIFO2(
	.clock(CLK),
	.shiftin(P6),
	.shiftout(EFIFO2_output),
	.taps());
	
always@(posedge CLK)
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
	
	P1 = CCD_FIFO_IN;
	P2 = P1;
	P3 = P2;
	P4 = EFIFO1_output;
	P5 = P4;
	P6 = P5;
	P7 = EFIFO2_output;
	P8 = P7;
	P9 = P8;
	
end	
	
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
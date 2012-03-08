

//-----------------------------------------------------------------------------------------------------//
//	Pixel mapping and address calculation

module	PIXEL_MAP(
		CLK,
		RESET_N,
		iREAD,
		iSW,
		oADDRESS,
		oREADY_N);

		
input			CLK;			//Clock
input			RESET_N;		//Asynchronous reset
input			iREAD;			//Signal to output next address from FIFO
input	[17:0]	iSW;			//Switch input to control mapping functions

output	[19:0]	oADDRESS;		//Address output from FIFO
output			oREADY_N;		//Signal indicates when data is ready in the FIFO

wire	[19:0]	oADDRESS;		//Memory address output
wire	[18:0]	PIXEL_ADDRESS;	//Result of address calculation, goes into FIFO
reg		[15:0]	OUTPUT_ROW;		//Display row for address calculation
reg		[15:0]	OUTPUT_COLUMN;	//Display column for address calculation

wire			ADDRESS_VALID;	//Signal to indicate output address is valid
wire			FIFO_WRITE;		//Signal to enable load into the FIFO
wire			EN_PIX_COUNT;	//Signal to increment of the row and column counter

parameter	DISPLAY_WIDTH = 15'd800;	//Defines the number of columns in the picture
parameter	DISPLAY_HEIGHT = 15'd480;	//Defines the number of rows in the picture

parameter	OUTPUT_ROW_INIT = 15'd0;	//Initialises the row counter to synchronise with display
parameter	OUTPUT_COL_INIT = 15'd1;	//Initialises the column counter to synchronise with display

wire cordic
wire rotate
wire blur =
wire edge_detect

assign cordic <=  = iSW[14];
assign rotate <= iSW[15];
assign blur <=   iSW[16];
assign edge_detect <= iSW[17];


//-----------------------------------------------------------------------------------------------------//
//	A FIFO is used to buffer the calculated memory addresses
//	This simplifies synchronisation between the address calculation and the memory controller

PIXEL_MAP_FIFO	u0 (
				.clock (CLK),
				.data ({ADDRESS_VALID,PIXEL_ADDRESS}),
				.rdreq (iREAD),
				.wrreq (FIFO_WRITE),
				.empty (oREADY_N),
				.full (FIFO_FULL),
				.q (oADDRESS)
				);

//-----------------------------------------------------------------------------------------------------//
//	Pixel row and column counter

always@(posedge CLK or negedge RESET_N)
begin
	if(RESET_N==0)
	begin
		OUTPUT_COLUMN <= OUTPUT_COL_INIT;			//Initialise pixel index. 
		OUTPUT_ROW <= OUTPUT_ROW_INIT;				//Initialisation values synchronise row and column counters to the display
	end
	else
		if	(EN_PIX_COUNT)							//The row and column are incremented when counter enable is asserted
		begin
			if (OUTPUT_COLUMN == DISPLAY_WIDTH-15'b1)		//Check for the end of a row
			begin
				OUTPUT_COLUMN <= 0;						//Wrap to display width
				if (OUTPUT_ROW == DISPLAY_HEIGHT-15'b1)		//Check for last row of screen
					OUTPUT_ROW <= 0;					//Wrap to display height
				else
					OUTPUT_ROW <= OUTPUT_ROW+15'b1;			//Increment row when column wraps
			end
			else
				OUTPUT_COLUMN <= OUTPUT_COLUMN+15'b1;
		end
end

//	Frame sync signal
assign	FRAME_SYNC = (EN_PIX_COUNT && (OUTPUT_ROW == DISPLAY_HEIGHT-15'b1) && (OUTPUT_COLUMN == DISPLAY_WIDTH-15'b1));

//-----------------------------------------------------------------------------------------------------//
//	Address calculation
													//Calculate address with vertical flip
assign 	PIXEL_ADDRESS = ((DISPLAY_HEIGHT-19'h1-OUTPUT_ROW)*DISPLAY_WIDTH+OUTPUT_COLUMN);
assign	ADDRESS_VALID = 1'b1;						//Address is always valid

//-----------------------------------------------------------------------------------------------------//
//	Counter and FIFO control

assign	FIFO_WRITE = !FIFO_FULL;					//Address is written whenever there is room in the FIFO
assign	EN_PIX_COUNT = FIFO_WRITE;					//Pixel counter is enabled whenever and address is written to the FIFO

endmodule

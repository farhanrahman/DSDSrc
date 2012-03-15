

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

reg 	[15:0]	x;
reg 	[15:0]	y;

reg 	[15:0]	x_s;
reg 	[15:0]	y_s;

parameter	DISPLAY_WIDTH = 15'd800;	//Defines the number of columns in the picture
parameter	DISPLAY_HEIGHT = 15'd480;	//Defines the number of rows in the picture

parameter	DISPLAY_CENTER_X = 15'd400;	
parameter	DISPLAY_CENTER_Y = 15'd240;

parameter	OUTPUT_ROW_INIT = 15'd0;	//Initialises the row counter to synchronise with display
parameter	OUTPUT_COL_INIT = 15'd1;	//Initialises the column counter to synchronise with display

//reg[7:0] SIN_THETA = 8'b00011100;
//reg[7:0] COS_THETA = 8'b11111111;

//reg[7:0] SIN_THETA = 8'b00000001;
//reg[7:0] COS_THETA = 8'b00000000;

reg signed [7:0] SIN_THETA = 8'h00;
reg signed [7:0] COS_THETA = 8'hFF;

reg [22:0] counter = 0;
reg Rotate;

wire [6:0] THETA;
reg	 [6:0] THETA_INCR;

wire signed [7:0] SIN;
wire signed [7:0] COS;

wire signed [15:0] SIN_CORDIC;
wire signed [15:0] COS_CORDIC;

assign THETA = iSW[13:8];


wire CORDIC_DONE;

//reg[15:0] x_temp;
//reg[15:0] y_temp;


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
				
//Sine lookup table

sin_lut sine_lookup_table(
	.address(THETA_INCR),
	.clock(CLK),
	.data(8'h00),
	.wren(1'b0),
	.q(SIN));

//Cos lookup table
cos_lut cos_lookup_table(
	.address(THETA_INCR),
	.clock(CLK),
	.data(8'h00),
	.wren(1'b0),
	.q(COS));

CORDIC cordic(
	CLK, 
	COS_CORDIC, 
	SIN_CORDIC, 
	THETA_INCR, 
	RESET_N,
	CORDIC_DONE);

//-----------------------------------------------------------------------------------------------------//
//	Pixel row and column counter

always@(posedge CLK or negedge RESET_N)
begin
	if(RESET_N==0)
	begin
		OUTPUT_COLUMN <= OUTPUT_COL_INIT;			//Initialise pixel index. 
		OUTPUT_ROW <= OUTPUT_ROW_INIT;				//Initialisation values synchronise row and column counters to the display
		//OUTPUT_COLUMN = (((OUTPUT_COL_INIT - DISPLAY_CENTER_X)*COS_THETA - (OUTPUT_ROW_INIT - DISPLAY_CENTER_Y)*SIN_THETA) >> 8) + DISPLAY_CENTER_X;
		//OUTPUT_ROW 	  = (((OUTPUT_COL_INIT - DISPLAY_CENTER_X)*SIN_THETA + (OUTPUT_ROW_INIT - DISPLAY_CENTER_Y)*COS_THETA) >> 8) + DISPLAY_CENTER_Y;	
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

always@(OUTPUT_COLUMN or OUTPUT_ROW)// or DISPLAY_CENTER_X or DISPLAY_CENTER_Y or SIN_THETA or COS_THETA)
begin
	if (iSW[14]) 		// CORDIC method
	begin
		 x 	= $signed((
		 
		    ($signed(OUTPUT_COLUMN) - $signed(DISPLAY_CENTER_X) + 32'sh0)*COS_CORDIC
		  - ($signed(OUTPUT_ROW) 	- $signed(DISPLAY_CENTER_Y) + 32'sh0)*SIN_CORDIC) >>> 8)
		  + DISPLAY_CENTER_X;
		   
		 y 	= $signed((
		 
			($signed(OUTPUT_COLUMN) - $signed(DISPLAY_CENTER_X) + 32'sh0)*SIN_CORDIC 
		+ 	($signed(OUTPUT_ROW) 	- $signed(DISPLAY_CENTER_Y) + 32'sh0)*COS_CORDIC) >>> 8) 
		+ 	DISPLAY_CENTER_Y;
	end
	else				// LUT method
	begin
		x 	= $signed((
		 
		    ($signed(OUTPUT_COLUMN) - $signed(DISPLAY_CENTER_X) + 32'sh0)*COS
		  - ($signed(OUTPUT_ROW) 	- $signed(DISPLAY_CENTER_Y) + 32'sh0)*SIN) / 9'sd128)
		  + DISPLAY_CENTER_X;
		   
		 y 	= $signed((
		 
			($signed(OUTPUT_COLUMN) - $signed(DISPLAY_CENTER_X) + 32'sh0)*SIN 
		+ 	($signed(OUTPUT_ROW) 	- $signed(DISPLAY_CENTER_Y) + 32'sh0)*COS) / 9'sd128) 
		+ 	DISPLAY_CENTER_Y;
	end
end

always@(posedge CLK)
begin
	counter = counter + 1;
	Rotate = 0;
	if(counter == 5000000)
	begin
		counter = 0;
		Rotate = 1;
	end
	
	if (iSW[15])
		begin
			if (Rotate == 1)

			begin
				THETA_INCR <= THETA + THETA_INCR;
			end		
		end
	else
		begin
			THETA_INCR <= THETA;
		end		
				 
		if (THETA_INCR >= 71)
		begin
			THETA_INCR <= THETA_INCR - 71;
		 end	
end

always@(posedge CLK or negedge RESET_N)
begin
	if(RESET_N == 0)
	begin
		x_s = 0;
		y_s = 0;
	end
	else
	begin
		x_s = x;
		y_s = y;
	end
end

//	Frame sync signal
assign	FRAME_SYNC = (EN_PIX_COUNT && (y_s == DISPLAY_HEIGHT-15'b1) && (x_s == DISPLAY_WIDTH-15'b1));

//-----------------------------------------------------------------------------------------------------//
//	Address calculation
													//Calculate address with vertical flip
assign 	PIXEL_ADDRESS = ((DISPLAY_HEIGHT-19'h1-y_s)*DISPLAY_WIDTH+x_s);
assign	ADDRESS_VALID = ~(x_s >= DISPLAY_WIDTH || y_s >= DISPLAY_HEIGHT);//1'b1;						//Address is always valid

//-----------------------------------------------------------------------------------------------------//
//	Counter and FIFO control

assign	FIFO_WRITE = !FIFO_FULL;					//Address is written whenever there is room in the FIFO
assign	EN_PIX_COUNT = FIFO_WRITE;					//Pixel counter is enabled whenever and address is written to the FIFO

endmodule

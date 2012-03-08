module I2C_CCD_Config (	//	Host Side
						iCLK,
						iRST_N,
						iExposure,
						oStatus,
						//	I2C Side
						I2C_SCLK,
						I2C_SDAT	);
//	Host Side
input			iCLK;
input			iRST_N;
input	[3:0]	iExposure;
output	[8:0]	oStatus;
//	I2C Side
output		I2C_SCLK;
inout		I2C_SDAT;
//	Internal Registers/Wires
reg	[15:0]	mI2C_CLK_DIV;
reg	[23:0]	mI2C_DATA;
reg			mI2C_CTRL_CLK;
reg			mI2C_GO;
wire		mI2C_END;
wire		mI2C_ACK;
reg	[15:0]	LUT_DATA;
reg	[5:0]	LUT_INDEX;
reg	[3:0]	mSetup_ST;
reg [15:0]	EXPOSURE;

//	Clock Setting
parameter	CLK_Freq	=	50000000;	//	50	MHz
parameter	I2C_Freq	=	20000;		//	20	KHz
//	LUT Data Number
parameter	LUT_SIZE	=	17;

/////////////////////	I2C Control Clock	////////////////////////
always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		mI2C_CTRL_CLK	<=	0;
		mI2C_CLK_DIV	<=	0;
	end
	else
	begin
		if( mI2C_CLK_DIV	< (CLK_Freq/I2C_Freq) )
		mI2C_CLK_DIV	<=	mI2C_CLK_DIV+1;
		else
		begin
			mI2C_CLK_DIV	<=	0;
			mI2C_CTRL_CLK	<=	~mI2C_CTRL_CLK;
		end
	end
end
////////////////////////////////////////////////////////////////////
I2C_Controller 	u0	(	.CLOCK(mI2C_CTRL_CLK),		//	Controller Work Clock
						.I2C_SCLK(I2C_SCLK),		//	I2C CLOCK
 	 	 	 	 	 	.I2C_SDAT(I2C_SDAT),		//	I2C DATA
						.I2C_DATA(mI2C_DATA),		//	DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
						.GO(mI2C_GO),      			//	GO transfor
						.END(mI2C_END),				//	END transfor 
						.ACK(mI2C_ACK),				//	ACK
						.RESET(iRST_N)	);
////////////////////////////////////////////////////////////////////
//////////////////////	Config Control	////////////////////////////
always@(posedge mI2C_CTRL_CLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		LUT_INDEX	<=	0;
		mSetup_ST	<=	0;
		mI2C_GO		<=	0;
	end
	else
	begin
		if(LUT_INDEX<LUT_SIZE)
		begin
			case(mSetup_ST)
			0:	begin
					mI2C_DATA	<=	{8'hBA,LUT_DATA};
					mI2C_GO		<=	1;
					mSetup_ST	<=	1;
				end
			1:	begin						
					if(mI2C_END)
					begin	
						mI2C_GO		<=	0;
						if(!mI2C_ACK)
						mSetup_ST	<=	2;
						else
						mSetup_ST	<=	0;
					end
				end
			2:	begin
					LUT_INDEX	<=	LUT_INDEX+1;
					mSetup_ST	<=	0;
				end
			endcase
		end
	end
end


assign oStatus = {mI2C_ACK,mSetup_ST[1:0],LUT_INDEX};

////////////////////////////////////////////////////////////////////
/////////////////////	Config Data LUT	  //////////////////////////
always@(iExposure)
begin
	case(iExposure)
	0	:	EXPOSURE	<=	64;
	1	:	EXPOSURE	<=	90;
	2	:	EXPOSURE	<=	128;
	3	:	EXPOSURE	<=	180;
	4	:	EXPOSURE	<=	256;
	5	:	EXPOSURE	<=	362;
	6	:	EXPOSURE	<=	512;
	7	:	EXPOSURE	<=	724;
	8	:	EXPOSURE	<=	1024;
	9	:	EXPOSURE	<=	1448;
	10	:	EXPOSURE	<=	2048;
	11	:	EXPOSURE	<=	2896;
	12	:	EXPOSURE	<=	4096;
	13	:	EXPOSURE	<=	5792;
	14	:	EXPOSURE	<=	8192;
	15	:	EXPOSURE	<=	11158;
	default:EXPOSURE	<= 	0;
	endcase
end

	
always
begin
	case(LUT_INDEX)
	0	:	LUT_DATA	<=	16'h0000;
	1	:	LUT_DATA	<=	16'h2000;
	2	:	LUT_DATA	<=	16'hF102;	//	Mirror Row and Columns
	3	:	LUT_DATA	<=	{8'h09,EXPOSURE[15:8]};//	Exposure
	4	:	LUT_DATA	<=	{8'hF1,EXPOSURE[7:0]};
	5	:	LUT_DATA	<=	16'h2B00;	//	Green 1 Gain
	6	:	LUT_DATA	<=	16'hF1B0;
	7	:	LUT_DATA	<=	16'h2C00;	//	Blue Gain
	8	:	LUT_DATA	<=	16'hF1CF;
	9	:	LUT_DATA	<=	16'h2D00;	//	Red Gain
	10	:	LUT_DATA	<=	16'hF1CF;
	11	:	LUT_DATA	<=	16'h2E00;	//	Green 2 Gain
	12	:	LUT_DATA	<=	16'hF1B0;
	13	:	LUT_DATA	<=	16'h0500;	//	H_Blanking
	14	:	LUT_DATA	<=	16'hF188;
	15	:	LUT_DATA	<=	16'h0600;	//	V_Blanking
	16	:	LUT_DATA	<=	16'hF119;
	default:LUT_DATA	<=	16'h0000;
	endcase
end
////////////////////////////////////////////////////////////////////
endmodule
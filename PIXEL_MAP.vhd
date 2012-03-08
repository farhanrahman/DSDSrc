
-----------------------------------------------------------------------------------------------------
--	Pixel Map and Address calculation

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY PIXEL_MAP IS
	PORT
	(
		CLK, RESET_N, iREAD	: IN	STD_LOGIC;
		iSW					: IN	STD_LOGIC_VECTOR(17 DOWNTO 0);
		oREADY_N			: OUT	STD_LOGIC;
		oADDRESS			: OUT	STD_LOGIC_VECTOR(19 DOWNTO 0)
	);
END PIXEL_MAP;

ARCHITECTURE RTL OF PIXEL_MAP IS

	SIGNAL PIXEL_ADDRESS 	:	STD_LOGIC_VECTOR(18 DOWNTO 0);		--Input to FIFO
	SIGNAL PIXEL_ADDRESS_RESULT 	:	UNSIGNED(23 DOWNTO 0);		--Calculated Address
	SIGNAL ADDRESS_VALID	:	STD_LOGIC;
	SIGNAL FIFO_WRITE		:	STD_LOGIC;							--FIFO Write Enable
	SIGNAL FIFO_FULL		:	STD_LOGIC;
	SIGNAL EN_PIX_COUNT		:	STD_LOGIC;							--Pixel Count Enable
	SIGNAL FRAME_SYNC		:	STD_LOGIC;							--Frame Start Synchronisation
	
	SIGNAL	ROW_COUNT		: 	UNSIGNED(11 DOWNTO 0);				--Row Counter, Y coordinate of current pixel
	SIGNAL	COL_COUNT		: 	UNSIGNED(11 DOWNTO 0);				--Column Counter, X coordinate of current pixel
	
	CONSTANT DISPLAY_HEIGHT :	UNSIGNED(11 DOWNTO 0) := X"1e0";
	CONSTANT DISPLAY_WIDTH 	:	UNSIGNED(11 DOWNTO 0) := X"320";
	CONSTANT ROW_INIT 		:	UNSIGNED(11 DOWNTO 0) := X"000";
	CONSTANT COLUMN_INIT	:	UNSIGNED(11 DOWNTO 0) := X"001";
		
component PIXEL_MAP_FIFO
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (19 DOWNTO 0);
		rdreq		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		empty		: OUT STD_LOGIC ;
		full		: OUT STD_LOGIC ;
		q			: OUT STD_LOGIC_VECTOR (19 DOWNTO 0)
	);
end component;

BEGIN

-----------------------------------------------------------------------------------------------------
--	FIFO Instantiation

	U0 : PIXEL_MAP_FIFO
		PORT MAP
		(
			aclr	=>	NOT RESET_N, 
			clock	=>	CLK,
			data	=>	ADDRESS_VALID & PIXEL_ADDRESS,
			rdreq	=>	iREAD,
			wrreq	=>	FIFO_WRITE,
			empty	=>	oREADY_N,
			full	=>	FIFO_FULL,
			q		=>	oADDRESS
		);
		
-----------------------------------------------------------------------------------------------------
--	Row and Column Counter

	PROCESS (CLK,RESET_N)
	BEGIN
		IF RESET_N = '0' THEN
			ROW_COUNT <= ROW_INIT;
			COL_COUNT <= COLUMN_INIT;
		
		ELSIF (clk'EVENT AND clk = '1') THEN
			IF EN_PIX_COUNT = '1' THEN
				IF COL_COUNT = DISPLAY_WIDTH - 1 THEN
					COL_COUNT <= X"000";
					IF ROW_COUNT = DISPLAY_HEIGHT - 1 THEN
						ROW_COUNT <= X"000";
					ELSE
						ROW_COUNT <= ROW_COUNT + 1;
					END IF;
				ELSE
					COL_COUNT <= COL_COUNT + 1;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
-----------------------------------------------------------------------------------------------------
--	Frame Sync detection

	PROCESS (EN_PIX_COUNT, ROW_COUNT, COL_COUNT)
	BEGIN
		IF ((ROW_COUNT = (DISPLAY_HEIGHT-1)) AND (COL_COUNT = (DISPLAY_WIDTH-1))) THEN
			FRAME_SYNC <= EN_PIX_COUNT;
		ELSE
			FRAME_SYNC <= '0';
		END IF;
	END PROCESS;

-----------------------------------------------------------------------------------------------------
--	Address calculation
												--Calculate address with vertical flip
	PIXEL_ADDRESS_RESULT <= (DISPLAY_HEIGHT-1-ROW_COUNT)*DISPLAY_WIDTH+COL_COUNT;
	PIXEL_ADDRESS <= STD_LOGIC_VECTOR(PIXEL_ADDRESS_RESULT(18 downto 0));
	ADDRESS_VALID <= '1';						--Address is always valid

-----------------------------------------------------------------------------------------------------
--	Counter and FIFO control

	FIFO_WRITE <= NOT FIFO_FULL;				--Address is written whenever there is room in the FIFO
	EN_PIX_COUNT <= FIFO_WRITE;					--Pixel counter is enabled whenever and address is written to the FIFO

END RTL;


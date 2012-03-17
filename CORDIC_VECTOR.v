module CORDIC_VECTOR (CLK, TAN, ROOT, X_IN, Y_IN, FUNC, reset);

input CLK;
input [6:0] X_IN;
input [6:0] Y_IN;
input reset;
input FUNC;
reg signed [1:0]mu;

output signed [15:0]TAN;
output signed [15:0]ROOT;

reg signed [17:0] x;
reg signed [17:0] y;
reg signed [19:0] z;
reg signed [15:0] dx;
reg signed [15:0] dy;

reg [19:0] dz[12:0];

reg [19:0] ei_store;
reg state;
reg XOR_STORE;

reg [5:0]i;
reg signed [15:0]TAN_REG;
reg signed [15:0]ROOT_REG;

parameter Z_SHIFT = 12;
//assign done_out = done;

//reg reset;

assign TAN = TAN_REG;
assign ROOT = ROOT_REG;
//assign RESET_REG = reset;

initial begin
  // MU = 1 
dz[0]  = 184320; // arctan(2^0) << 12
dz[1]  = 108810; // arctan(2^-1) << 12
dz[2]  = 57492;
dz[3]  = 29184;
dz[4]  = 14649;
dz[5]  = 7331;
dz[6]  = 3667;
dz[7]  = 1833;
dz[8]  = 917;
dz[9]  = 458;
dz[10] = 229;
dz[11] = 115;
dz[12] = 57;
end

always@(posedge CLK)//or posedge reset)
begin
		//if (reset) begin
		//	state = 0;
		//end
	case(state)
		0: begin
			case(FUNC)
				0: begin		//TAN
					x <= 1;
					z <= 0;
					y <= Y_IN << 12;
				end
				1: begin 	//ROOT
					x <= X_IN;
					y <= Y_IN;
					z <= 0;
				end
			endcase
			mu = 1;
			state = 1;
			i <= 0;		
		end
		1: begin
			//if (done == 0) begin
				dy = x >>> i;
				dx = y >>> i;
				XOR_STORE=  x[17]^y[17];
				if (XOR_STORE  == 1) begin
					x <= x - dx;
					y <= y + dy;
					z <= z - dz[i];
				end 
				else begin
					x <= x + dx;
					y <= y - dy;
					z <= z + dz[i];
				end
				if (i == 12) begin
					case(FUNC)
					0: begin		//TAN
						TAN_REG <= z;
					end
					1: begin 	//ROOT
						ROOT_REG <= x*421;  // multiplied by << 8
					end
					endcase
					state <= 0;
				end
				else begin
					i <= i + 1;
				end
		end
	endcase
end	
endmodule


module CORDIC(CLK, cos_z, sin_z, z0, reset, done_out);

input CLK;
input [6:0] z0;
input reset;

output signed [15:0]cos_z;
output signed [15:0]sin_z;

output done_out;

reg signed [15:0] x;
reg signed [15:0] y;
reg signed [15:0] z;
reg signed [15:0] dx;
reg signed [15:0] dy;
reg [16:0] e[12:0];

reg state;
reg done;

reg [5:0]i;
reg signed [15:0]COS_Z_REG;
reg signed [15:0]SIN_Z_REG;


assign done_out = done;

//reg reset;

assign cos_z = COS_Z_REG;
assign sin_z = SIN_Z_REG;
//assign RESET_REG = reset;
initial begin

e[0]  = 11520; 	// arctan(2^0) << 8
e[1]  = 6801; 	// arctan(2^-1) << 8
e[2]  = 3593;	// arctan(2^-2) << 8
e[3]  = 1824;	// arctan(2^-3) << 8
e[4]  = 916;	// arctan(2^-4) << 8
e[5]  = 458;	// arctan(2^-5) << 8
e[6]  = 229;	// arctan(2^-6) << 8
e[7]  = 115;	// arctan(2^-7) << 8
e[8]  = 57;		// arctan(2^-8) << 8
e[9]  = 29;		// arctan(2^-9) << 8
e[10] = 14;		// arctan(2^-10) << 8
e[11] = 7;		// arctan(2^-11) << 8
e[12] = 4;		// arctan(2^-12) << 8

end

always@(posedge CLK )//or posedge reset)
begin
		//if (reset) begin
		//	state = 0;
		//end
	case(state)
		0: begin
			if((z0 >= 17) && (z0 <= 35))
				z = ((35 - z0)*5 <<<  8);
			else if((z0 > 35) && (z0 <= 53))
				z = ((z0 - 35)*5 <<<  8);
			else if((z0 > 53) && (z0 < 71))
				z = ((71 - z0)*5 <<<  8);
			else if(z0 == 71)
				z = ((71 - z0)*5 <<<  8);
			else
				z = ((z0)*5 <<<  8);  // shifted to match e
			x = 155; // 0.6073 *2^n Shift needs to match shift out of cos and sign - 14
			y = 0;
			i <= 0;
			done = 0;
			state = 1;	
		end
		1: begin
			//if (done == 0) begin
				dy = y >>> i;
				dx = x >>> i;
				if (z >= 0) begin
					x = x - dy;
					y = y + dx;
					z = z - e[i];
				end
				else begin
					x = x + dy;
					y = y - dx;
					z = z + e[i];
				end
				if (i == 12) begin
					if((z0 >=0) && (z0 < 17)) //0 <= theta < 90
					begin
						COS_Z_REG <= x;
						SIN_Z_REG <= y;
					end
					else if((z0 >= 17) && (z0 < 35)) //90 <= theta < 180
					begin
						COS_Z_REG <= $signed(x) > 0 ? $signed(0 - $signed(x)) : x;//-1*(x);
						SIN_Z_REG <= y;					
					end
					else if((z0 >= 35) && (z0 < 53)) //180 <= theta < 270
					begin					
						COS_Z_REG <= $signed(x) > 0 ? $signed(0 - $signed(x)) : x;//-1*(x);
						SIN_Z_REG <= $signed(y) > 0 ? $signed(0 - $signed(y)) : y;//-1*(y);					
					end
					else if((z0 >= 53) && (z0 < 71)) //270 <= theta < 360
					begin				
						COS_Z_REG <= x;
						SIN_Z_REG <= $signed(y) > 0 ? $signed(0 - $signed(y)) : y;//-1*(y);				
					end
					else
					begin //theta = 360
						COS_Z_REG <= x;
						SIN_Z_REG <= y;				
					end
					//COS_Z_REG = x;
					//SIN_Z_REG = y;					
					done <= 1;
					state <= 0;
				end
				else begin
					i <= i + 1;
				end
			//end
			
			done <= 0;
		end
	endcase
end	
endmodule


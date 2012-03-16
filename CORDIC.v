module CORDIC(CLK, cos_z, sin_z, z0, mu, reset);

input CLK;
input [6:0] z0;
input reset;
input signed [1:0]mu;

output signed [15:0]cos_z;
output signed [15:0]sin_z;

//output done_out;

reg signed [15:0] x;
reg signed [15:0] y;
reg signed [19:0] z;
reg signed [15:0] dx;
reg signed [15:0] dy;

reg [19:0] dz[12:0];
reg [19:0] ez[12:0];
reg [19:0] fz[12:0];

reg [19:0] ei_store;
reg state;
reg done;

reg [5:0]i;
reg signed [15:0]COS_Z_REG;
reg signed [15:0]SIN_Z_REG;

parameter Z_SHIFT = 12;
//assign done_out = done;

//reg reset;

assign cos_z = COS_Z_REG;
assign sin_z = SIN_Z_REG;
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
// MU = 0 - values shifted by 12
ez[0]  = 4096; // 2^-i << 12
ez[1]  = 2048; 
ez[2]  = 1024;
ez[3]  = 512;
ez[4]  = 256;
ez[5]  = 128;
ez[6]  = 64;
ez[7]  = 32;
ez[8]  = 16;
ez[9]  = 8;
ez[10] = 4;
ez[11] = 2;
ez[12] = 1;

// MU = -1

fz[0]  = 500000; // 2^-i << 12
fz[1]  = 128913;
fz[2]  = 59941;
fz[3]  = 29490;
fz[4]  = 14687;
fz[5]  = 7336;
fz[6]  = 3667;
fz[7]  = 1834;
fz[8]  = 917;
fz[9]  = 458;
fz[10] = 229;
fz[11] = 115;
fz[12] = 57;
end

always@(posedge CLK )//or posedge reset)
begin
		//if (reset) begin
		//	state = 0;
		//end
	case(state)
		0: begin
			if((z0 > 17) && (z0 <= 35))
				z = ((35 - z0)*5 <<<  Z_SHIFT);
			else if((z0 > 35) && (z0 <= 53))
				z = ((z0 - 35)*5 <<<  Z_SHIFT);
			else if((z0 > 53) && (z0 < 71))
				z = ((71 - z0)*5 <<<  Z_SHIFT);
			else if(z0 == 71)
				z = ((71 - z0)*5 <<<  Z_SHIFT);
			else
				z = ((z0)*5 <<<  Z_SHIFT);  // shifted to match dz
			x <= 155; // 0.6073 *2^n Shift needs to match shift out of cos and sign - 14
			y <= 0;
			i <= 0;
//			done = 0;
			state = 1;	
		end
		1: begin
			//if (done == 0) begin
				if (mu == 1) begin
					ei_store = dz[i];
				end
				else if (mu == 0)begin
					ei_store = ez[i];
				end
				else begin
					ei_store = fz[i];
				end
				dy = x >>> i;
				dx = y >>> i;
				if (z >= 0) begin
					x <= x - mu*dx;
					y <= y + dy;
					z <= z - ei_store;
				end
				else begin
					x <= x + mu*dx;
					y <= y - dy;
					z <= z + ei_store;
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
//					done <= 1;
					state <= 0;
				end
				else begin
					i <= i + 1;
				end
			//end
			
//			done <= 0;
		end
	endcase
end	
endmodule


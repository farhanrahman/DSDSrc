module CORDIC(CLK, cos_z, sin_z, z0);

input CLK;
input z0;

output signed cos_z;
output signed sin_z;

reg signed [15:0] x;
reg signed [15:0] y;
reg signed [15:0] z;
reg signed [15:0] dx;
reg signed [15:0] dy;
reg signed [15:0] dz[12:0];

reg done;
reg i;
reg signed COS_Z_REG;
reg signed SIN_Z_REG;

assign cos_z = COS_Z_REG;
assign sin_z = SIN_Z_REG;
initial begin
z = z0 <<  8;  // shifted to match dz
x = 39780; // 0.6073 *2^n Shift needs to match shift out of cos and sign
y = 0;
i = 0;
done <= 0;
dz[0]  <= 11520; // arctan(2^0) >> 8
dz[1]  <= 6801; // arctan(2^-1) >> 8
dz[2]  <= 3593;
dz[3]  <= 1824;
dz[4]  <= 916;
dz[5]  <= 458;
dz[6]  <= 229;
dz[7]  <= 115;
dz[8]  <= 57;
dz[9]  <= 29;
dz[10] <= 14;
dz[11] <= 7;
dz[12] <= 4;

end

always@(posedge CLK)
begin
	if (done == 0) begin
		dy = y >>> i;
		dx = x >>> i;
		if (z >= 0) begin
			x <= x - dx;
			y <= y + dy;
			z <= z - dz[i];
		end
		else begin
			x = x + dx;
			y = y - dy;
			z = z + dz[i];
		end
		if (i == 12) begin
			COS_Z_REG <= x >>> 16;
			SIN_Z_REG <= y >>> 16;
			done <= 1;
		end
		else begin
			i = i + 1;
		end
	end
end	
endmodule


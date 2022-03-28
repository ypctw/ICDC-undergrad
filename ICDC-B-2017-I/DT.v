module DT(
	input 			clk, 
	input			reset,
	output	reg		done ,
	output	reg		sti_rd ,
	output	wire 	[9:0]	sti_addr ,
	input			[15:0]	sti_di,
	output	reg		res_wr ,
	output	reg		res_rd ,
	output	wire 	[13:0]	res_addr ,
	output	reg 	[7:0]	res_do,
	input		[7:0]	res_di
	);

localparam W = -1;
localparam NW = -129;
localparam N = -128;
localparam NE = -127;
localparam E = 1;
localparam SW = 127;
localparam S = 128;
localparam SE = 129;

reg [3:0] cur_state, next_state;

reg [2:0] rom_x;
reg [6:0] rom_y;
reg [6:0] ram_x;
reg [6:0] ram_y;
reg [13:0] pivot;
reg [3:0] count;
reg en;
assign res_addr = {ram_y, ram_x};
assign sti_addr = {rom_y, rom_x};

always @(*) begin
	next_state = cur_state;
	case (cur_state)
		0: begin
			if (ram_x == 127 && ram_y == 127) next_state = 2;
			else if (count == 15) next_state = 13; 
		end
		13: next_state = 0;
		1: next_state = 2;
		2: begin
			if (pivot == 16255) next_state = 7;
			else next_state = (res_di == 0) ? 1 : 3;
		end
		3: next_state = 4;
		4: next_state = 5;
		5: next_state = 6; 
		6: next_state = (pivot == 16255) ? 7 : 1;
		7: next_state = 8;
		8: next_state = (res_di == 0) ? 7 : 9;
		9: next_state = 10;
		10: next_state = 11;
		11: next_state = 12;
		12: next_state = 7; 
	endcase
end

always @(posedge clk or negedge reset) begin
	if(!reset) 
	begin
		done <= 0;
		sti_rd <= 1;
		res_wr <= 0;
		res_rd <= 0;
		res_do <= 0;
		rom_x <= 0;
		rom_y <= 1;
		ram_x <= 0;
		ram_y <= 1;
		count <= 0;
		pivot <= 129;
		en <= 0;
	end
	else 
	begin
		case(cur_state)
			0: begin // read one line
				res_do <= sti_di[15 - count];
				count <= count + 1;
				if (ram_x == 127 && ram_y == 127) begin
					res_wr <= 0;
					res_rd <= 1;
					{ram_y, ram_x} <= pivot;
				end
				else begin
					res_wr <= 1;
					{ram_y, ram_x} <= (en) ? {ram_y, ram_x} + 1 : {ram_y, ram_x};
					{rom_y, rom_x} <= (count == 15) ? {rom_y, rom_x} + 1 : {rom_y, rom_x};
				end
				en <= 1;
			end
			13: begin
				res_wr <= 0;
			end
			1: begin
				res_wr <= 0;
				res_rd <= 1;
				{ram_y, ram_x} <= pivot; // 2(res_di) == Center
			end
			2:begin
				if (pivot == 16255)  pivot <= 16254;
				else if(res_di == 0) pivot <= pivot + 1;
				else {ram_y, ram_x} <= pivot + W;
			end
			3:begin
				res_do <= res_di;
				{ram_y, ram_x} <= pivot + NW;
			end
			4:begin
				if (res_di < res_do) res_do <= res_di;
				{ram_y, ram_x} <= pivot + N;
			end
			5:begin
				if (res_di < res_do) res_do <= res_di;
				{ram_y, ram_x} <= pivot + NE;
			end
			6:begin
				res_wr <= 1;
				if (res_di < res_do) res_do <= res_di + 1;
				else res_do <= res_do + 1;
				{ram_y, ram_x} <= pivot;
				pivot <= (pivot == 16255) ? 16254: pivot + 1;
			end
			7: begin
				res_wr <= 0;
				res_rd <= 1;
				{ram_y, ram_x} <= pivot;
			end
			8: begin
				res_do <= res_di;
				if (pivot == 129) done <= 1;
				else if(res_di == 0) pivot <= pivot - 1;
				else {ram_y, ram_x} <= pivot + E;  // 2(res_di) == Center
			end
			9: begin
			  	if (res_di + 1 < res_do) res_do <= res_di + 1;
				{ram_y, ram_x} <= pivot + SE;
			end
			10: begin
				if (res_di + 1 < res_do) res_do <= res_di + 1;
				{ram_y, ram_x} <= pivot + S;
			end
			11: begin
				if (res_di + 1 < res_do) res_do <= res_di + 1;
				{ram_y, ram_x} <= pivot + SW;
			end
			12:begin
				res_wr <= 1;
				if (res_di + 1 < res_do) res_do <= res_di + 1;
				else res_do <= res_do;
				{ram_y, ram_x} <= pivot;
				if(pivot == 129) done <= 1;
				pivot <= pivot - 1;
			end
			default: begin
				res_wr <= 0;
			end





		endcase
	end

end

always @(posedge clk or negedge reset) begin
	if (!reset) cur_state <= 0;
	else cur_state <= next_state;
end

endmodule

`timescale 1ns/10ps
`define LAT         "./lat.dat"
`define LON         "./lon.dat"
`define ANS_D	    "./D_Pattern.dat"
`define ANS_a	    "./a_Pattern.dat"
`define	cycle_time   200.0
`define DEL          1.0
`define sdf_file "./GPSDC_syn.sdf" // Your sdf file name


module test;
reg          clk;
reg          DEN;
reg          reset_n;

reg	[23:0] lon_mem[0:120];
reg	[23:0] lat_mem[0:120];
reg [39:0] ans_D_mem[0:120];
reg [63:0] ans_a_mem[0:120];
reg [23:0] lon_temp;
reg [23:0] lat_temp;

integer		Pcnt;
integer		check_cnt;
integer		cycle_cnt;
integer D_err,a_err;
integer over;



initial	$readmemh (`LON, lon_mem);
initial	$readmemh (`LAT, lat_mem);
initial	$readmemh (`ANS_D, ans_D_mem);
initial	$readmemh (`ANS_a, ans_a_mem);

initial begin
   clk           = 1'b0;
   DEN           = 1'b0;   
   reset_n           = 1'b0;
   D_err	 		 =0;
   a_err =0;
   check_cnt	 =0;
   over	=1'b0;
end


always #(`cycle_time/2) clk = ~clk; 
wire [6:0]COS_ADDR;
wire [95:0]COS_DATA;
wire [127:0]ASIN_DATA;
wire [5:0]ASIN_ADDR;
wire Valid;
wire [39:0]D;
wire [63:0]a;
cos_rom lat_cos_rom_u1(.addr(COS_ADDR),.data(COS_DATA));
asin_rom asin_rom_u1(.addr(ASIN_ADDR),.data(ASIN_DATA));

GPSDC GPSDC_u1(.clk(clk),.reset_n(reset_n),.DEN(DEN),.LON_IN(lon_temp),.LAT_IN(lat_temp),.COS_ADDR(COS_ADDR),.COS_DATA(COS_DATA),.ASIN_ADDR(ASIN_ADDR),.ASIN_DATA(ASIN_DATA),.Valid(Valid),.a(a),.D(D));

`ifdef SDF
	initial $sdf_annotate(`sdf_file, GPSDC_u1);
`endif
initial begin  
//reset cycle 
#1;  reset_n = 0;
#(`cycle_time*3); #1; reset_n = 1;
$display(" ----------------------------------------------------------------------");
$display("TEST START !!!");
$display(" ----------------------------------------------------------------------");
#(`cycle_time*0.25);
//start send frame data
    #(`cycle_time);
	@(posedge clk)
	#1
	DEN=1;  
	Pcnt=0;
	lon_temp = lon_mem[Pcnt];
	lat_temp = lat_mem[Pcnt];
	@(posedge clk)
	#1
	DEN=0;
	lon_temp = 24'hx;
	lat_temp = 24'hx;
	
    #(`cycle_time*256);
	@(posedge clk)
	#1
	DEN=1;  
	Pcnt=Pcnt+1;
	lon_temp = lon_mem[Pcnt];
	lat_temp = lat_mem[Pcnt];
	@(posedge clk)#1
	DEN=0;
	lon_temp = 24'hx;
	lat_temp = 24'hx;
	
	while(Pcnt <119)begin
    	@(posedge clk)
	#1
		if(Valid==1'b1)begin
			@(posedge clk)
			#1
			DEN=1;
			Pcnt=Pcnt+1;			
			lon_temp = lon_mem[Pcnt];
			lat_temp = lat_mem[Pcnt];
		@(posedge clk)
		#1
		DEN=0;
		lon_temp = 24'hx;
		lat_temp = 24'hx;
		end
	
	end
end


always@(posedge clk)begin
	if(Valid===1'b1 && over==0)begin

		if(a !== ans_a_mem[check_cnt])begin
		$display("a ERROR at %d:output %h !=expect %h ",check_cnt, a, ans_a_mem[check_cnt]);
		a_err = a_err +1 ;
		end
		else if ( a === 64'dx)begin
		$display("a ERROR at %d:output %h !=expect %h ",check_cnt, a, ans_a_mem[check_cnt]);
		a_err = a_err +1 ;
		end

		if(D !== ans_D_mem[check_cnt])begin
		$display("D ERROR at %d:output %h !=expect %h ",check_cnt, D, ans_D_mem[check_cnt]);
		D_err = D_err+1 ;
		end
		else if ( D === 40'dx)begin
		$display("D ERROR at %d:output %h !=expect %h ",check_cnt, D, ans_D_mem[check_cnt]);
		D_err = D_err+1 ;
		end
		check_cnt=check_cnt+1;
		if(check_cnt===119)begin
		over =1'b1;
		end
	end

	if (D_err === 0 &&  over===1'b1 && a_err===0 )  begin
	$display("All data have been generated successfully!\n");
	$display(" ----------------------------PASS--------------------------------------");
	#10 $finish;
	end
	else if( over===1'b1 ) begin 
	$display("There are %d D errors!\n", D_err);
	$display("There are %d a errors!\n", a_err);
	$display(" ----------------------------------------------------------------------");
	#10 $finish;
        end

end

//==============================================================================================================
//================================= WF D U M P ====================================================================

`ifdef FSDB
	initial begin
		$fsdbDumpfile("GPSDC.fsdb");
		$fsdbDumpMDA(GPSDC_u1);
		$fsdbDumpvars("+all");
	end
`endif

`ifdef VCD
	initial begin
		$dumpfile("GPSDC.vcd");
		$dumpvars;
	end
`endif


endmodule





module asin_rom(addr,data);
input [5:0]addr;

output reg [127:0]data;

always @(addr)begin
case (addr)
6'd0 : data={64'h000000000000,64'h000000000000} ; // asin(0.000000e+00)=0.000000e+00 
6'd1 : data={64'h000000855305,64'h0b8beee546d2} ; // asin(4.736630e-13)=6.882318e-07 
6'd2 : data={64'h0000010aa60a,64'h105452200523} ; // asin(9.473261e-13)=9.733068e-07 
6'd3 : data={64'h0000018ff90f,64'h13ffd39301e1} ; // asin(1.420989e-12)=1.192052e-06 
6'd4 : data={64'h000002154c14,64'h1717ddca8daa} ; // asin(1.894652e-12)=1.376464e-06 
6'd5 : data={64'h0000029a9f19,64'h19d1aae3f45a} ; // asin(2.368315e-12)=1.538933e-06 
6'd6 : data={64'h0000031ff21e,64'h1c48872c47e9} ; // asin(2.841978e-12)=1.685817e-06 
6'd7 : data={64'h000003a54523,64'h1e8caa029aba} ; // asin(3.315641e-12)=1.820890e-06 
6'd8 : data={64'h0000042a9828,64'h20a8a4400a58} ; // asin(3.789304e-12)=1.946614e-06 
6'd9 : data={64'h000004afeb2d,64'h22a3ccafd48e} ; // asin(4.262967e-12)=2.064695e-06 
6'd10 : data={64'h000005353e32,64'h24837b423515} ; // asin(4.736630e-12)=2.176380e-06 
6'd11 : data={64'h000005ba9137,64'h264bb8a60553} ; // asin(5.210294e-12)=2.282607e-06 
6'd12 : data={64'h0000063fe43c,64'h27ffa72603e1} ; // asin(5.683957e-12)=2.384105e-06 
6'd13 : data={64'h000006c53741,64'h29a1c4c77c84} ; // asin(6.157620e-12)=2.481455e-06 
6'd14 : data={64'h0000074a8a46,64'h2b3416d8716a} ; // asin(6.631283e-12)=2.575128e-06 
6'd15 : data={64'h000007cfdd4b,64'h2cb847ae3330} ; // asin(7.104946e-12)=2.665510e-06 
6'd16 : data={64'h000008553050,64'h2e2fbb951b85} ; // asin(7.578609e-12)=2.752927e-06 
6'd17 : data={64'h000008da8355,64'h2f9b9fef7dbf} ; // asin(8.052272e-12)=2.837653e-06 
6'd18 : data={64'h0000095fd65a,64'h30fcf6600faf} ; // asin(8.525935e-12)=2.919920e-06 
6'd19 : data={64'h000009e5295f,64'h32549d31d43b} ; // asin(8.999598e-12)=2.999933e-06 
6'd20 : data={64'h00000a6a7c64,64'h33a355c7e8f8} ; // asin(9.473261e-12)=3.077866e-06 
6'd21 : data={64'h00000aefcf69,64'h34e9c99e7388} ; // asin(9.946924e-12)=3.153874e-06 
6'd22 : data={64'h00000b75226e,64'h36288e3bd664} ; // asin(1.042059e-11)=3.228093e-06 
6'd23 : data={64'h00000bfa7573,64'h376028557863} ; // asin(1.089425e-11)=3.300644e-06 
6'd24 : data={64'h00000c7fc878,64'h38910e58902b} ; // asin(1.136791e-11)=3.371634e-06 
6'd25 : data={64'h00000d051b7d,64'h39bbaa7a6293} ; // asin(1.184158e-11)=3.441159e-06 
6'd26 : data={64'h00000d8a6e82,64'h3ae05c6a3fde} ; // asin(1.231524e-11)=3.509308e-06 
6'd27 : data={64'h00000e0fc187,64'h3bff7ab90620} ; // asin(1.278890e-11)=3.576157e-06 
6'd28 : data={64'h00000e95148c,64'h3d19540535e4} ; // asin(1.326257e-11)=3.641781e-06 
6'd29 : data={64'h00000f1a6791,64'h3e2e2ff72e68} ; // asin(1.373623e-11)=3.706242e-06 
6'd30 : data={64'h00000f9fba96,64'h3f3e501692f3} ; // asin(1.420989e-11)=3.769601e-06 
6'd31 : data={64'h000010250d9b,64'h4049f07feae5} ; // asin(1.468355e-11)=3.831913e-06 
6'd32 : data={64'h000010aa60a0,64'h415148801538} ; // asin(1.515722e-11)=3.893227e-06 
6'd33 : data={64'h0000112fb3a5,64'h42548b1a0737} ; // asin(1.563088e-11)=3.953591e-06 
6'd34 : data={64'h000011b506aa,64'h4353e77a6e42} ; // asin(1.610454e-11)=4.013047e-06 
6'd35 : data={64'h0000123a59af,64'h444f895c1de2} ; // asin(1.657821e-11)=4.071634e-06 
6'd36 : data={64'h000012bfacb4,64'h4547995fa9c0} ; // asin(1.705187e-11)=4.129391e-06 
6'd37 : data={64'h00001344ffb9,64'h463c3d581e21} ; // asin(1.752553e-11)=4.186351e-06 
6'd38 : data={64'h000013ca52be,64'h472d988e7283} ; // asin(1.799920e-11)=4.242546e-06 
6'd39 : data={64'h0000144fa5c3,64'h481bcbfd0bc3} ; // asin(1.847286e-11)=4.298006e-06 
6'd40 : data={64'h000014d4f8c8,64'h4906f6846ae9} ; // asin(1.894652e-11)=4.352760e-06 
6'd41 : data={64'h0000155a4bcd,64'h49ef3519f766} ; // asin(1.942018e-11)=4.406834e-06 
6'd42 : data={64'h000015df9ed2,64'h4ad4a2f1ae0e} ; // asin(1.989385e-11)=4.460252e-06 
6'd43 : data={64'h00001664f1d7,64'h4bb759a35f0e} ; // asin(2.036751e-11)=4.513038e-06 
6'd44 : data={64'h000016ea44dc,64'h4c97714c0b82} ; // asin(2.084117e-11)=4.565213e-06 
6'd45 : data={64'h0000176f97e1,64'h4d7500abde1d} ; // asin(2.131484e-11)=4.616799e-06 
6'd46 : data={64'h000017f4eae6,64'h4e501d412880} ; // asin(2.178850e-11)=4.667815e-06 
6'd47 : data={64'h0000187a3deb,64'h4f28db60c015} ; // asin(2.226216e-11)=4.718280e-06 
6'd48 : data={64'h000018ff90f0,64'h4fff4e4c08bc} ; // asin(2.273583e-11)=4.768210e-06 
6'd49 : data={64'h00001984e3f5,64'h50d38844f110} ; // asin(2.320949e-11)=4.817623e-06 
6'd50 : data={64'h00001a0a36fa,64'h51a59aa01b06} ; // asin(2.368315e-11)=4.866534e-06 
6'd51 : data={64'h00001a8f89ff,64'h527595d5642a} ; // asin(2.415682e-11)=4.914958e-06 
6'd52 : data={64'h00001b14dd04,64'h5343898efa23} ; // asin(2.463048e-11)=4.962910e-06 
6'd53 : data={64'h00001b9a3009,64'h540f84b722a2} ; // asin(2.510414e-11)=5.010403e-06 
6'd54 : data={64'h00001c1f830e,64'h54d99584d91d} ; // asin(2.557780e-11)=5.057450e-06 
6'd55 : data={64'h00001ca4d613,64'h55a1c9876096} ; // asin(2.605147e-11)=5.104064e-06 
6'd56 : data={64'h00001d2a2918,64'h56682db0e40f} ; // asin(2.652513e-11)=5.150255e-06 
6'd57 : data={64'h00001daf7c1d,64'h572cce603d57} ; // asin(2.699879e-11)=5.196036e-06 
6'd58 : data={64'h00001e34cf22,64'h57efb769f70e} ; // asin(2.747246e-11)=5.241417e-06 
6'd59 : data={64'h00001eba2227,64'h58b0f4209c7c} ; // asin(2.794612e-11)=5.286409e-06 
6'd60 : data={64'h00001f3f752c,64'h59708f5c67be} ; // asin(2.841978e-11)=5.331021e-06 
6'd61 : data={64'h00001fc4c831,64'h5a2e93825d1c} ; // asin(2.889345e-11)=5.375262e-06 
6'd62 : data={64'h0000204a1b36,64'h5aeb0a8ae0a4} ; // asin(2.936711e-11)=5.419143e-06 
6'd63 : data={64'h000020cf6e3b,64'h5ba5fe07d1ed} ; // asin(2.984077e-11)=5.462671e-06 
 


endcase
end
endmodule

module cos_rom(addr,data);
input [6:0]addr;

output reg [95:0]data;

always @(addr)begin
case (addr)
7'd0 : data={48'h18C7AE147A,48'hF03CE5C7} ;//0,cos(2.478000e+001)=9.384292e-001 
7'd1 : data={48'h18C7B47304,48'hF03F1902} ;//1,cos(2.478010e+001)=9.384628e-001 
7'd2 : data={48'h18C7BAD18D,48'hF0414C17} ;//2,cos(2.478019e+001)=9.384964e-001 
7'd3 : data={48'h18C7C13016,48'hF0437F05} ;//3,cos(2.478029e+001)=9.385299e-001 
7'd4 : data={48'h18C7C78E9F,48'hF045B1CE} ;//4,cos(2.478039e+001)=9.385635e-001 
7'd5 : data={48'h18C7CDED28,48'hF047E470} ;//5,cos(2.478049e+001)=9.385970e-001 
7'd6 : data={48'h18C7D44BB1,48'hF04A16EC} ;//6,cos(2.478058e+001)=9.386305e-001 
7'd7 : data={48'h18C7DAAA3A,48'hF04C4943} ;//7,cos(2.478068e+001)=9.386640e-001 
7'd8 : data={48'h18C7E108C3,48'hF04E7B73} ;//8,cos(2.478078e+001)=9.386975e-001 
7'd9 : data={48'h18C7E7674D,48'hF050AD7D} ;//9,cos(2.478087e+001)=9.387310e-001 
7'd10 : data={48'h18C7EDC5D6,48'hF052DF61} ;//10,cos(2.478097e+001)=9.387645e-001 
7'd11 : data={48'h18C7F4245F,48'hF055111F} ;//11,cos(2.478107e+001)=9.387980e-001 
7'd12 : data={48'h18C7FA82E8,48'hF05742B7} ;//12,cos(2.478117e+001)=9.388315e-001 
7'd13 : data={48'h18C800E171,48'hF0597429} ;//13,cos(2.478126e+001)=9.388650e-001 
7'd14 : data={48'h18C8073FFA,48'hF05BA574} ;//14,cos(2.478136e+001)=9.388984e-001 
7'd15 : data={48'h18C80D9E83,48'hF05DD69A} ;//15,cos(2.478146e+001)=9.389319e-001 
7'd16 : data={48'h18C813FD0D,48'hF0600799} ;//16,cos(2.478155e+001)=9.389653e-001 
7'd17 : data={48'h18C81A5B96,48'hF0623873} ;//17,cos(2.478165e+001)=9.389987e-001 
7'd18 : data={48'h18C820BA1F,48'hF0646926} ;//18,cos(2.478175e+001)=9.390321e-001 
7'd19 : data={48'h18C82718A8,48'hF06699B3} ;//19,cos(2.478185e+001)=9.390656e-001 
7'd20 : data={48'h18C82D7731,48'hF068CA1A} ;//20,cos(2.478194e+001)=9.390990e-001 
7'd21 : data={48'h18C833D5BA,48'hF06AFA5B} ;//21,cos(2.478204e+001)=9.391324e-001 
7'd22 : data={48'h18C83A3443,48'hF06D2A76} ;//22,cos(2.478214e+001)=9.391657e-001 
7'd23 : data={48'h18C84092CC,48'hF06F5A6B} ;//23,cos(2.478224e+001)=9.391991e-001 
7'd24 : data={48'h18C846F156,48'hF0718A3A} ;//24,cos(2.478233e+001)=9.392325e-001 
7'd25 : data={48'h18C84D4FDF,48'hF073B9E3} ;//25,cos(2.478243e+001)=9.392658e-001 
7'd26 : data={48'h18C853AE68,48'hF075E965} ;//26,cos(2.478253e+001)=9.392992e-001 
7'd27 : data={48'h18C85A0CF1,48'hF07818C1} ;//27,cos(2.478262e+001)=9.393325e-001 
7'd28 : data={48'h18C8606B7A,48'hF07A47F8} ;//28,cos(2.478272e+001)=9.393659e-001 
7'd29 : data={48'h18C866CA03,48'hF07C7708} ;//29,cos(2.478282e+001)=9.393992e-001 
7'd30 : data={48'h18C86D288C,48'hF07EA5F2} ;//30,cos(2.478292e+001)=9.394325e-001 
7'd31 : data={48'h18C8738716,48'hF080D4B6} ;//31,cos(2.478301e+001)=9.394658e-001 
7'd32 : data={48'h18C879E59F,48'hF0830354} ;//32,cos(2.478311e+001)=9.394991e-001 
7'd33 : data={48'h18C8804428,48'hF08531CC} ;//33,cos(2.478321e+001)=9.395324e-001 
7'd34 : data={48'h18C886A2B1,48'hF087601D} ;//34,cos(2.478330e+001)=9.395657e-001 
7'd35 : data={48'h18C88D013A,48'hF0898E49} ;//35,cos(2.478340e+001)=9.395989e-001 
7'd36 : data={48'h18C8935FC3,48'hF08BBC4E} ;//36,cos(2.478350e+001)=9.396322e-001 
7'd37 : data={48'h18C899BE4C,48'hF08DEA2E} ;//37,cos(2.478360e+001)=9.396654e-001 
7'd38 : data={48'h18C8A01CD5,48'hF09017E7} ;//38,cos(2.478369e+001)=9.396987e-001 
7'd39 : data={48'h18C8A67B5F,48'hF092457A} ;//39,cos(2.478379e+001)=9.397319e-001 
7'd40 : data={48'h18C8ACD9E8,48'hF09472E7} ;//40,cos(2.478389e+001)=9.397651e-001 
7'd41 : data={48'h18C8B33871,48'hF096A02D} ;//41,cos(2.478398e+001)=9.397984e-001 
7'd42 : data={48'h18C8B996FA,48'hF098CD4E} ;//42,cos(2.478408e+001)=9.398316e-001 
7'd43 : data={48'h18C8BFF583,48'hF09AFA49} ;//43,cos(2.478418e+001)=9.398648e-001 
7'd44 : data={48'h18C8C6540C,48'hF09D271D} ;//44,cos(2.478428e+001)=9.398980e-001 
7'd45 : data={48'h18C8CCB295,48'hF09F53CB} ;//45,cos(2.478437e+001)=9.399311e-001 
7'd46 : data={48'h18C8D3111F,48'hF0A18054} ;//46,cos(2.478447e+001)=9.399643e-001 
7'd47 : data={48'h18C8D96FA8,48'hF0A3ACB6} ;//47,cos(2.478457e+001)=9.399975e-001 
7'd48 : data={48'h18C8DFCE31,48'hF0A5D8F1} ;//48,cos(2.478466e+001)=9.400306e-001 
7'd49 : data={48'h18C8E62CBA,48'hF0A80507} ;//49,cos(2.478476e+001)=9.400638e-001 
7'd50 : data={48'h18C8EC8B43,48'hF0AA30F7} ;//50,cos(2.478486e+001)=9.400969e-001 
7'd51 : data={48'h18C8F2E9CC,48'hF0AC5CC0} ;//51,cos(2.478496e+001)=9.401300e-001 
7'd52 : data={48'h18C8F94855,48'hF0AE8864} ;//52,cos(2.478505e+001)=9.401632e-001 
7'd53 : data={48'h18C8FFA6DE,48'hF0B0B3E1} ;//53,cos(2.478515e+001)=9.401963e-001 
7'd54 : data={48'h18C9060568,48'hF0B2DF38} ;//54,cos(2.478525e+001)=9.402294e-001 
7'd55 : data={48'h18C90C63F1,48'hF0B50A69} ;//55,cos(2.478535e+001)=9.402625e-001 
7'd56 : data={48'h18C912C27A,48'hF0B73574} ;//56,cos(2.478544e+001)=9.402955e-001 
7'd57 : data={48'h18C9192103,48'hF0B96058} ;//57,cos(2.478554e+001)=9.403286e-001 
7'd58 : data={48'h18C91F7F8C,48'hF0BB8B17} ;//58,cos(2.478564e+001)=9.403617e-001 
7'd59 : data={48'h18C925DE15,48'hF0BDB5AF} ;//59,cos(2.478573e+001)=9.403947e-001 
7'd60 : data={48'h18C92C3C9E,48'hF0BFE021} ;//60,cos(2.478583e+001)=9.404278e-001 
7'd61 : data={48'h18C9329B28,48'hF0C20A6D} ;//61,cos(2.478593e+001)=9.404608e-001 
7'd62 : data={48'h18C938F9B1,48'hF0C43493} ;//62,cos(2.478603e+001)=9.404939e-001 
7'd63 : data={48'h18C93F583A,48'hF0C65E93} ;//63,cos(2.478612e+001)=9.405269e-001 
7'd64 : data={48'h18C945B6C3,48'hF0C8886C} ;//64,cos(2.478622e+001)=9.405599e-001 
7'd65 : data={48'h18C94C154C,48'hF0CAB220} ;//65,cos(2.478632e+001)=9.405929e-001 
7'd66 : data={48'h18C95273D5,48'hF0CCDBAD} ;//66,cos(2.478641e+001)=9.406259e-001 
7'd67 : data={48'h18C958D25E,48'hF0CF0514} ;//67,cos(2.478651e+001)=9.406589e-001 
7'd68 : data={48'h18C95F30E7,48'hF0D12E55} ;//68,cos(2.478661e+001)=9.406918e-001 
7'd69 : data={48'h18C9658F71,48'hF0D35770} ;//69,cos(2.478671e+001)=9.407248e-001 
7'd70 : data={48'h18C96BEDFA,48'hF0D58065} ;//70,cos(2.478680e+001)=9.407578e-001 
7'd71 : data={48'h18C9724C83,48'hF0D7A933} ;//71,cos(2.478690e+001)=9.407907e-001 
7'd72 : data={48'h18C978AB0C,48'hF0D9D1DB} ;//72,cos(2.478700e+001)=9.408237e-001 
7'd73 : data={48'h18C97F0995,48'hF0DBFA5D} ;//73,cos(2.478709e+001)=9.408566e-001 
7'd74 : data={48'h18C985681E,48'hF0DE22B9} ;//74,cos(2.478719e+001)=9.408895e-001 
7'd75 : data={48'h18C98BC6A7,48'hF0E04AEF} ;//75,cos(2.478729e+001)=9.409224e-001 
7'd76 : data={48'h18C9922531,48'hF0E272FF} ;//76,cos(2.478739e+001)=9.409553e-001 
7'd77 : data={48'h18C99883BA,48'hF0E49AE8} ;//77,cos(2.478748e+001)=9.409882e-001 
7'd78 : data={48'h18C99EE243,48'hF0E6C2AB} ;//78,cos(2.478758e+001)=9.410211e-001 
7'd79 : data={48'h18C9A540CC,48'hF0E8EA49} ;//79,cos(2.478768e+001)=9.410540e-001 
7'd80 : data={48'h18C9AB9F55,48'hF0EB11BF} ;//80,cos(2.478777e+001)=9.410869e-001 
7'd81 : data={48'h18C9B1FDDE,48'hF0ED3910} ;//81,cos(2.478787e+001)=9.411197e-001 
7'd82 : data={48'h18C9B85C67,48'hF0EF603B} ;//82,cos(2.478797e+001)=9.411526e-001 
7'd83 : data={48'h18C9BEBAF1,48'hF0F1873F} ;//83,cos(2.478807e+001)=9.411854e-001 
7'd84 : data={48'h18C9C5197A,48'hF0F3AE1D} ;//84,cos(2.478816e+001)=9.412183e-001 
7'd85 : data={48'h18C9CB7803,48'hF0F5D4D5} ;//85,cos(2.478826e+001)=9.412511e-001 
7'd86 : data={48'h18C9D1D68C,48'hF0F7FB67} ;//86,cos(2.478836e+001)=9.412839e-001 
7'd87 : data={48'h18C9D83515,48'hF0FA21D3} ;//87,cos(2.478846e+001)=9.413167e-001 
7'd88 : data={48'h18C9DE939E,48'hF0FC4818} ;//88,cos(2.478855e+001)=9.413495e-001 
7'd89 : data={48'h18C9E4F227,48'hF0FE6E38} ;//89,cos(2.478865e+001)=9.413823e-001 
7'd90 : data={48'h18C9EB50B0,48'hF1009431} ;//90,cos(2.478875e+001)=9.414151e-001 
7'd91 : data={48'h18C9F1AF3A,48'hF102BA03} ;//91,cos(2.478884e+001)=9.414479e-001 
7'd92 : data={48'h18C9F80DC3,48'hF104DFB0} ;//92,cos(2.478894e+001)=9.414806e-001 
7'd93 : data={48'h18C9FE6C4C,48'hF1070537} ;//93,cos(2.478904e+001)=9.415134e-001 
7'd94 : data={48'h18CA04CAD5,48'hF1092A97} ;//94,cos(2.478914e+001)=9.415461e-001 
7'd95 : data={48'h18CA0B295E,48'hF10B4FD1} ;//95,cos(2.478923e+001)=9.415789e-001 
7'd96 : data={48'h18CA1187E7,48'hF10D74E5} ;//96,cos(2.478933e+001)=9.416116e-001 
7'd97 : data={48'h18CA17E670,48'hF10F99D3} ;//97,cos(2.478943e+001)=9.416443e-001 
7'd98 : data={48'h18CA1E44FA,48'hF111BE9A} ;//98,cos(2.478952e+001)=9.416770e-001 
7'd99 : data={48'h18CA24A383,48'hF113E33B} ;//99,cos(2.478962e+001)=9.417097e-001 
7'd100 : data={48'h18CA2B020C,48'hF11607B7} ;//100,cos(2.478972e+001)=9.417424e-001 
7'd101 : data={48'h18CA316095,48'hF1182C0B} ;//101,cos(2.478982e+001)=9.417751e-001 
7'd102 : data={48'h18CA37BF1E,48'hF11A503A} ;//102,cos(2.478991e+001)=9.418078e-001 
7'd103 : data={48'h18CA3E1DA7,48'hF11C7443} ;//103,cos(2.479001e+001)=9.418404e-001 
7'd104 : data={48'h18CA447C30,48'hF11E9825} ;//104,cos(2.479011e+001)=9.418731e-001 
7'd105 : data={48'h18CA4ADAB9,48'hF120BBE1} ;//105,cos(2.479020e+001)=9.419057e-001 
7'd106 : data={48'h18CA513943,48'hF122DF77} ;//106,cos(2.479030e+001)=9.419384e-001 
7'd107 : data={48'h18CA5797CC,48'hF12502E6} ;//107,cos(2.479040e+001)=9.419710e-001 
7'd108 : data={48'h18CA5DF655,48'hF1272630} ;//108,cos(2.479050e+001)=9.420036e-001 
7'd109 : data={48'h18CA6454DE,48'hF1294953} ;//109,cos(2.479059e+001)=9.420362e-001 
7'd110 : data={48'h18CA6AB367,48'hF12B6C50} ;//110,cos(2.479069e+001)=9.420688e-001 
7'd111 : data={48'h18CA7111F0,48'hF12D8F27} ;//111,cos(2.479079e+001)=9.421014e-001 
7'd112 : data={48'h18CA777079,48'hF12FB1D7} ;//112,cos(2.479088e+001)=9.421340e-001 
7'd113 : data={48'h18CA7DCF03,48'hF131D462} ;//113,cos(2.479098e+001)=9.421666e-001 
7'd114 : data={48'h18CA842D8C,48'hF133F6C6} ;//114,cos(2.479108e+001)=9.421992e-001 
7'd115 : data={48'h18CA8A8C15,48'hF1361904} ;//115,cos(2.479118e+001)=9.422317e-001 
7'd116 : data={48'h18CA90EA9E,48'hF1383B1C} ;//116,cos(2.479127e+001)=9.422643e-001 
7'd117 : data={48'h18CA974927,48'hF13A5D0D} ;//117,cos(2.479137e+001)=9.422968e-001 
7'd118 : data={48'h18CA9DA7B0,48'hF13C7ED8} ;//118,cos(2.479147e+001)=9.423293e-001 
7'd119 : data={48'h18CAA40639,48'hF13EA07D} ;//119,cos(2.479157e+001)=9.423619e-001 
7'd120 : data={48'h18CAAA64C2,48'hF140C1FC} ;//120,cos(2.479166e+001)=9.423944e-001 
7'd121 : data={48'h18CAB0C34C,48'hF142E354} ;//121,cos(2.479176e+001)=9.424269e-001 
7'd122 : data={48'h18CAB721D5,48'hF1450487} ;//122,cos(2.479186e+001)=9.424594e-001 
7'd123 : data={48'h18CABD805E,48'hF1472593} ;//123,cos(2.479195e+001)=9.424919e-001 
7'd124 : data={48'h18CAC3DEE7,48'hF1494679} ;//124,cos(2.479205e+001)=9.425243e-001 
7'd125 : data={48'h18CACA3D70,48'hF14B6738} ;//125,cos(2.479215e+001)=9.425568e-001 
7'd126 : data={48'h18CAD09BF9,48'hF14D87D2} ;//126,cos(2.479225e+001)=9.425893e-001 
7'd127 : data={48'h18CAD6FA82,48'hF14FA845} ;//127,cos(2.479234e+001)=9.426217e-001 



endcase
end
endmodule


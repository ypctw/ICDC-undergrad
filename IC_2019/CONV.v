
`timescale 1ns/10ps

module  CONV(clk,reset,busy,ready,iaddr,idata,cwr,caddr_wr,cdata_wr,crd,caddr_rd,cdata_rd,csel);
input clk;
input reset;
input ready;
input [19:0] idata;
input [19:0] cdata_rd;

output reg  busy;
output reg [11:0]iaddr;
output reg crd;
output reg [19:0]caddr_rd;
output reg cwr;
output reg [19:0]cdata_wr;
output reg [11:0]caddr_wr;
output reg [2:0] csel;

wire [35:0] conv_ans;
reg [19:0] conv_2_mul;
reg [19:0] kernel;
reg [19:0] bias;
reg [5:0] STATE;
reg [11:0] pivot;
reg [9:0] layer2;
reg [35:0] conv_temp;
initial
begin
    busy <= 0;
    iaddr <= 0;
    crd <= 0;
    caddr_rd <= 0;
    cdata_wr <= 0;
    cwr <= 0;
    csel <= 0;
    bias <= 20'h01310;
    layer2 <= 0;
end
assign conv_ans = ({16'd0,kernel} * {16'd0,conv_2_mul});
always@(posedge clk)
begin
    if(reset)
    begin
        STATE <= 1;
        cwr <= 0;
        iaddr <= 0;
        csel <= 0;
    end
    else
    begin
        case(STATE)
            1:
            begin
                if(ready)
                begin
                    busy <= 1;
                    // STATE <= 1;
                    iaddr <= -65;
                    pivot <= 0;
                    conv_temp <= 0;
                end
                else if(busy == 1)
                    STATE <= 2;
                else
                    STATE <= 1;
            end
            2: // (0,0)
            begin
                // Padding
                if (pivot[11:6] == 0 || pivot[5:0] == 0)
                    conv_2_mul <= 0; // (0,0~63) (0~63,0)
                else
                    conv_2_mul <= idata;
                kernel <= 20'h0A89E;
                conv_temp <= 0;
                STATE <= 3; // (0,1)
                iaddr <= iaddr + 1;
            end
            3: //(0,1)
            begin
                if (pivot[11:6] == 0 )
                    conv_2_mul <= 0; // (0)
                else
                    conv_2_mul <= idata;
                kernel <=  20'h092D5;
                iaddr <= iaddr + 1;// (0,2)
                conv_temp <= conv_temp + conv_ans;
                STATE <= 4;
            end
            4: //(0,2)
            begin
                if (pivot[11:6] == 0 || pivot[5:0] == 63)
                    conv_2_mul <= 0;
                else
                    conv_2_mul <= idata;
                kernel <=  20'h06D43;
                iaddr <= iaddr + 62;// (1,0)
                conv_temp <= conv_temp + conv_ans;
                STATE <= 5;
            end
            5: //(1,0)
            begin
                if (pivot[5:0] == 0)
                    conv_2_mul <= 0;
                else
                    conv_2_mul <= idata;
                kernel <=  20'h01004;
                iaddr <= iaddr + 1;// (1,1)
                conv_temp <= conv_temp + conv_ans;
                STATE <= 6;
            end
            6: //(1,1)
            begin
                conv_2_mul <= idata;
                kernel <=  ~(20'hF8F71) + 1;
                iaddr <= iaddr + 1; // (1,2)
                conv_temp <= conv_temp + conv_ans;
                STATE <= 7;
            end
            7: //(1,2)
            begin
                if (pivot[5:0] == 63)
                    conv_2_mul <= 0;
                else
                    conv_2_mul <= idata;
                kernel <=  ~(20'hF6E54) + 1;
                iaddr <= iaddr + 62;// (2,0)
                conv_temp <= conv_temp + (~conv_ans + 1'b1) ;
                STATE <= 8;
            end
            8: // (2,0)
            begin
                if (pivot[11:6] == 63 || pivot[5:0] == 0)
                    conv_2_mul <= 0;
                else
                    conv_2_mul <= idata;
                iaddr <= iaddr + 1;
                kernel <= ~(20'hFA6D7) + 1;
                conv_temp <= conv_temp + (~conv_ans + 1'b1) ;
                STATE <= 9;
            end
            9: // (2,1)
            begin
                if (pivot[11:6] == 63 )
                    conv_2_mul <= 0;
                else
                    conv_2_mul <= idata;
                iaddr <= iaddr + 1;
                kernel <= ~(20'hFC834) + 1;
                conv_temp <= conv_temp + (~conv_ans + 1'b1) ;
                STATE <= 10;
            end
            10: // (2,2)
            begin
                if (pivot[11:6] == 63 || pivot[5:0] == 63)
                    conv_2_mul <= 0;
                else
                    conv_2_mul <= idata;
                iaddr <= iaddr + 1;
                kernel <= ~(20'hFAC19) + 1;
                conv_temp <= conv_temp + (~conv_ans + 1'b1) ;
                STATE <= 11;
            end
            11:
            begin
                conv_temp <= conv_temp + (~conv_ans + 1'b1) + {20'h01310,16'b0};
                STATE <= 12;
            end
            12:
            begin
                cwr <= 1;
                caddr_wr <= pivot;
                if (conv_temp[35] == 1)
                    cdata_wr <= 0;
                else
                    cdata_wr <= conv_temp[35:16] + conv_temp[15]; // riounding
                csel<= 3'b001;
                STATE <= 13;
            end
            13:
            begin
                csel<= 3'b000;
                cwr <= 0;
                caddr_wr <= 'hx;
                cdata_wr <= 'hx;
                STATE <= 2;
                pivot <= pivot + 1;
                iaddr <= pivot - 64;
                if(pivot == 4095)
                    STATE <= 14;
                else
                    STATE <= 2;
            end
            14:
            begin
                csel <= 3'b001;
                crd <= 1;
                cwr <= 0;
                caddr_wr <= 'hx;
                cdata_wr <= 'hx;
                caddr_rd <= {layer2[9:5], 1'b0, layer2[4:0], 1'b0 };
                STATE <= 15;
            end
            15: // (0,0)
            begin
                caddr_rd <= {layer2[9:5], 1'b0, layer2[4:0], 1'b1 };
                conv_temp <= cdata_rd;
                STATE <= 16;
            end
            16: // (1,0)
            begin
                caddr_rd <= {layer2[9:5] , 1'b1, layer2[4:0], 1'b0 };
                conv_temp <= conv_temp < cdata_rd ? cdata_rd : conv_temp;
                STATE <= 17;
            end
            17: // (0,1)
            begin
                caddr_rd <= {layer2[9:5], 1'b1, layer2[4:0], 1'b1 };
                conv_temp <= conv_temp < cdata_rd ? cdata_rd : conv_temp;
                STATE <= 18;
            end
            18:
            begin
                crd <= 0;
                csel <= 3'b011;
                cwr <= 1;
                caddr_wr <= layer2;
                cdata_wr <= conv_temp < cdata_rd ? cdata_rd : conv_temp;
                if (layer2 == 1023)
                    STATE <= 19;
                else
                    STATE <= 14;
                layer2 <= layer2 + 1;
            end
            19:
            begin
                csel <= 3'b000;
                cwr <= 0;
                caddr_wr <= 'hx;
                cdata_wr <= 'hx;
                busy <= 0;
            end
            default:
            begin
                STATE <= 0;
            end
        endcase
    end
end
endmodule

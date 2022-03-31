module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output valid;
output is_inside;

reg valid;
reg is_inside;
reg [4:0]CASE;
reg [9:0] X_A[6:0];
reg [9:0] Y_A[6:0];
reg [22:0] Out[3:0];
reg [2:0] COUNT;
reg [10:0]X_1;
reg [10:0]Y_1;
reg [10:0]X_2;
reg [10:0]Y_2;
reg MINUS[3:0];
reg [11:0] A;
reg [11:0] B;
reg [2:0] A_OUT;
reg [2:0] B_OUT;
reg temp;
reg BI;
reg[3:0] CO;
always @(posedge clk) begin
    if(reset) begin
        CASE <= 1;
        COUNT <= 0;
        valid <= 0;
    end
    else begin
        case(CASE)
        5'd1:begin
            COUNT <= COUNT + 1;
            X_A[COUNT] <= X;
            Y_A[COUNT] <= Y;
            if(COUNT == 6) begin
                CASE <= 2;
                COUNT <= 0; 
                temp <= 0;
                A_OUT <= 2;
                B_OUT <= 3;
                CO <= 0;
            end
        end
        5'd2:begin
            CASE <= 3;
            X_1 <= ({1'b0,X_A[A_OUT]} - {1'b0,X_A[1]});
            Y_2 <= ({1'b0,Y_A[B_OUT]} - {1'b0,Y_A[1]});
            X_2 <= ({1'b0,X_A[B_OUT]} - {1'b0,X_A[1]});
            Y_1 <= ({1'b0,Y_A[A_OUT]} - {1'b0,Y_A[1]});
        end
        5'd3: begin 
            if(X_1[10] == 1) begin
                X_1 <= ~X_1[10:0] + 1;
                MINUS[0] <= 0;
            end
            else begin MINUS[0] <= 1;end

            if(Y_2[10] == 1) begin
                Y_2 <= ~Y_2[10:0] + 1;
                MINUS[1] <= 0;
            end
            else begin MINUS[1] <= 1;end

            if(X_2[10] == 1) begin
                X_2 <= ~X_2[10:0] + 1;
                MINUS[2] <= 0;
            end
            else begin MINUS[2] <= 1;end

            if(Y_1[10] == 1) begin
                Y_1 <= ~Y_1[10:0] + 1;
                MINUS[3] <= 0;
            end
            else begin MINUS[3] <= 1;end
               
            CASE <= 4;//外積
        end
        5'd4:begin
            A <=  {7'b0,(X_1>>4)} * {7'b0,(Y_2>>4)}>>2;
            CASE <= 20;
        end
        5'd5: begin
            if(MINUS[0]+MINUS[1] == 1) begin
                A <= ~A[11:0] + 1'b1;
            end
            if (MINUS[2]+MINUS[3] == 1)begin
                B <= ~B[11:0] + 1'b1;
            end
            CASE <= 6;
        end
        5'd6: begin
            BI <= (A-B)>>11;
            if(temp == 1)begin
                CASE <= 18;
            end
            else begin
                CASE <= CO + 7;
                COUNT <= COUNT + 1;
            end
        end
        5'd7: begin//0-2 0-2
            if(BI == 0) begin
                X_A[2] <= X_A[3];
                X_A[3] <= X_A[2];
                Y_A[2] <= Y_A[3];
                Y_A[3] <= Y_A[2];
            end 
            CO <= 1;
            A_OUT <= 2;
            B_OUT <= 4;
            CASE <= 2;
        end
        5'd8: begin //
            if(BI == 0) begin
                X_A[2] <= X_A[4];
                X_A[4] <= X_A[2];
                Y_A[2] <= Y_A[4];
                Y_A[4] <= Y_A[2];
            end 
            CO <= 2;
            A_OUT <= 2;
            B_OUT <= 5;
            CASE <= 2;
        end
        5'd9: begin 
            if(BI == 0) begin
                X_A[2] <= X_A[5];
                X_A[5] <= X_A[2];
                Y_A[2] <= Y_A[5];
                Y_A[5] <= Y_A[2];
            end 
            CO <= 3;
            A_OUT <= 2;
            B_OUT <= 6;
            CASE <= 2;
        end
        5'd10:begin 
            if(BI == 0) begin
                X_A[2] <= X_A[6];
                X_A[6] <= X_A[2];
                Y_A[2] <= Y_A[6];
                Y_A[6] <= Y_A[2];
            end 
            CO <= 4;
            A_OUT <= 3;
            B_OUT <= 4;
            CASE <= 2;
        end
        5'd11:begin 
            if(BI == 0) begin
                X_A[3] <= X_A[4];
                X_A[4] <= X_A[3];
                Y_A[3] <= Y_A[4];
                Y_A[4] <= Y_A[3];
            end 
            CO <= 5;
            A_OUT <= 3;
            B_OUT <= 5;
            CASE <= 2;
        end
        5'd12:begin 
            if(BI == 0) begin
                X_A[3] <= X_A[5];
                X_A[5] <= X_A[3];
                Y_A[3] <= Y_A[5];
                Y_A[5] <= Y_A[3];
            end 
            CO <= 6;
            A_OUT <= 3;
            B_OUT <= 6;
            CASE <= 2;
        end
        5'd13:begin 
            if(BI == 0) begin
                X_A[3] <= X_A[6];
                X_A[6] <= X_A[3];
                Y_A[3] <= Y_A[6];
                Y_A[6] <= Y_A[3];
            end 
            CO <= 7;
            A_OUT <= 4;
            B_OUT <= 5;
            CASE <= 2;
        end
        5'd14:begin 
            if(BI == 0) begin
                X_A[4] <= X_A[5];
                X_A[5] <= X_A[4];
                Y_A[4] <= Y_A[5];
                Y_A[5] <= Y_A[4];
            end 
            CO <= 8;
            A_OUT <= 4;
            B_OUT <= 6;
            CASE <= 2;
        end
        5'd15:begin 
            if(BI == 0) begin
                X_A[4] <= X_A[6];
                X_A[6] <= X_A[4];
                Y_A[4] <= Y_A[6];
                Y_A[6] <= Y_A[4];
            end 
            CO <= 9;
            A_OUT <= 5;
            B_OUT <= 6;
            CASE <= 2;
        end
        5'd16:begin 
            if(BI == 0) begin
                X_A[5] <= X_A[6];
                X_A[6] <= X_A[5];
                Y_A[5] <= Y_A[6];
                Y_A[6] <= Y_A[5];
            end 
            CASE <= 17;
            COUNT<= 0;
            A_OUT <= 'hx;
            B_OUT <= 'hx;
            temp <= 1;
        end
        5'd17: begin
            COUNT <= COUNT + 1;
            if(COUNT == 5) begin
                X_1 <= ({1'b0,X_A[6]} - {1'b0,X_A[0]});
                Y_2 <= ({1'b0,Y_A[1]} - {1'b0,Y_A[6]});
                X_2 <= ({1'b0,X_A[1]} - {1'b0,X_A[6]});
                Y_1 <= ({1'b0,Y_A[6]} - {1'b0,Y_A[0]});
            end
            else begin
                X_1 <= ({1'b0,X_A[COUNT + 1]} - {1'b0,X_A[0]});
                Y_2 <= ({1'b0,Y_A[COUNT + 2]} - {1'b0,Y_A[COUNT + 1]});
                X_2 <= ({1'b0,X_A[COUNT + 2]} - {1'b0,X_A[COUNT + 1]});
                Y_1 <= ({1'b0,Y_A[COUNT + 1]} - {1'b0,Y_A[0]});
            end
            CASE <= 3;
            temp <= 1;
        end
        5'd18: begin
            if(COUNT == 5) begin
                if(BI == 1) begin
                    valid <= 1;
                    is_inside <= 1;
                end
                else begin
                    valid <= 1;
                    is_inside <= 0;
                end
                CASE <= 19;
            end
            else if(BI == 0)begin
                valid <= 1;
                is_inside <= 0;
                CASE <= 19;
            end
            else begin
                CASE <= 17;
            end
        end
        5'd19: begin
            valid <= 0;
            CASE <= 1;
            is_inside <= 'hx;
            COUNT <=0;
        end
        5'd20:begin
            CASE <= 5;
            B <= {7'b0,(Y_1>>4)} * {7'b0,(X_2>>4)}>>2;
        end
        endcase
    end
end
endmodule
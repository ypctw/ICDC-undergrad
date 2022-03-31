module JAM (
input CLK,
input RST,
output reg [2:0] W,
output reg [2:0] J,
input [6:0] Cost,
output reg [3:0] MatchCount,
output reg [9:0] MinCost,
output reg Valid);

reg [2:0] cur_state, next_state;
reg [2:0] fact[7:0];
reg [2:0] pivot, right, tail;
reg [9:0] MinCost_buf;
reg [2:0] swapNum,swapNum_index;
reg en_o;
wire en;

assign en = (fact[0] == 7 && fact[1] == 6 && fact[2] == 5 && fact[3] == 4 & fact[4] == 3 && fact[5] == 2 && fact[6] == 1 && fact[7] == 0) ? 1 : 0;

always @(*) begin
    next_state = cur_state;
    case (cur_state)
        0: if (W == 7) next_state = 2;
        // 1: next_state = (en) ? 6 : 2;
        2: begin
            if (en) next_state = 6;
            else if (fact[pivot] > fact[pivot - 1]) next_state = 3;
        end
        3: if (right == 7) next_state = 4;
        4: next_state = 5;
        5: begin
            // if (en) next_state = 6;
            if (tail <= right) next_state = 0;
        end
        default: next_state = next_state;
    endcase
end

always @(posedge CLK or posedge RST) begin
    if (RST)
    begin
        Valid <= 0;
        MatchCount <= 4'd0;
        MinCost <= 10'b1111111111;
        MinCost_buf <= 10'd0;
        W <= 3'd0;
        J <= 3'd0;
        fact[0] <= 0;
        fact[1] <= 1;
        fact[2] <= 2;
        fact[3] <= 3;
        fact[4] <= 4;
        fact[5] <= 5;
        fact[6] <= 6;
        fact[7] <= 7;
        pivot <= 3'd7;
        right <= 3'd0;
        swapNum <= 7;
        en_o <= 0;
    end
    else
    begin
        case (cur_state)
            0: begin
                MinCost_buf <= MinCost_buf + Cost;
                W <= W + 1; // W would be reset to 0
                J <= fact[W + 1];
            end 
            // 1: begin // compare
            //     if (MinCost_buf < MinCost) begin
            //         MinCost <= MinCost_buf; 
            //         MatchCount <= 1;
            //     end
            //     else if(MinCost_buf ==  MinCost) begin
            //         MatchCount <= MatchCount + 1;
            //     end
            //     else begin
            //         MinCost <= MinCost;
            //     end
            //     MinCost_buf <= 10'd0;
                
            // end
            2: begin
                /*  find pivot */
                if (fact[pivot] > fact[pivot - 1]) begin
                    pivot <= pivot - 1;
                    swapNum_index <= pivot;
                end
                else begin
                    pivot <= pivot - 1;
                end
                right <= pivot;
                
                if (!en_o) begin
                    en_o <= 1;
                    if (MinCost_buf < MinCost) begin
                        MinCost <= MinCost_buf; 
                        MatchCount <= 1;
                    end
                    else if(MinCost_buf ==  MinCost) begin
                        MatchCount <= MatchCount + 1;
                    end
                    else begin
                        MinCost <= MinCost;
                    end
                end
                else begin
                end
            end
            3: begin
                /* find min swap number */
                right <= right + 1;
                if (fact[right] > fact[pivot]) begin
                    if (fact[right] < swapNum) begin
                        swapNum <= fact[right];
                        swapNum_index <= right;
                    end
                    else begin
                        swapNum <= swapNum;
                    end
                end
                else begin
                    
                end
            end
            4: begin // swap 
                fact[pivot] <= fact[swapNum_index];
                fact[swapNum_index] <= fact[pivot];
                right <= pivot + 1;
                tail <= 7;
            end
            5: begin
                // if (MinCost_buf < MinCost) begin
                //     MinCost <= MinCost_buf; 
                //     MatchCount <= 1;
                // end
                // else if(MinCost_buf ==  MinCost) begin
                //     MatchCount <= MatchCount + 1;
                // end
                // else begin
                //     MinCost <= MinCost;
                // end

                MinCost_buf <= 10'd0;
                if (right < tail) begin
                    fact[right] <= fact[tail];
                    fact[tail] <= fact[right];
                    right <= right + 1;
                    tail <= tail - 1;
                end
                else begin 
                    right <= 'hx;
                    W <= 0;
                    pivot <= 3'd7;
                    J <= fact[0];
                    swapNum <= 7;
                    en_o <= 0;
                end     
            end
            default: begin
                Valid <= 1;
            end
        endcase
    end
end

always @(posedge CLK or posedge RST) begin
    if (RST) cur_state <= 0;
    else cur_state <= next_state;
end

endmodule



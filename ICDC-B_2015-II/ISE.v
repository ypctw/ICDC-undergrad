`timescale 1ns/10ps
module ISE( clk, reset, image_in_index, pixel_in, busy, out_valid, color_index, image_out_index);
input               clk;
input               reset;
input       [4:0]   image_in_index;
input       [23:0]  pixel_in;
output reg          busy;
output reg          out_valid;
output reg  [1:0]   color_index;
output reg  [4:0]   image_out_index;

localparam R = 2'b00;
localparam G = 2'b01;
localparam B = 2'b10;

reg [4:0] cur_state, nxt_state;

reg [14:0] cnt  [0:2];
reg [21:0] sum  [0:2];
reg [10:0] means [0:31];
reg [5:0]  index [0:31];
reg [1:0]  color [0:31];
reg [4:0] i, j;
reg [10:0] div;
reg [1:0] cur_color;
reg [4:0] cur_image_index;
reg [13:0] pixel_count;

always @(posedge clk or posedge reset) begin
    if (reset) cur_state <= 0;
    else cur_state <= nxt_state;
end

always @(*) begin
    nxt_state = cur_state;
    case (cur_state)
        0: if (pixel_count == 14'd16383) nxt_state = 1;
        1: begin
            if (i == cur_image_index) nxt_state = 2;
            else if (cur_color > color[i]) ;
            else if (div > means[i] && cur_color >= color[i]) ;
            else nxt_state = 2;
        end
        2: if (j == 5'd0 || i == j) nxt_state = 3;
        3: nxt_state = (cur_image_index == 5'd31) ? 4 : 0; 
        default: begin end
    endcase
end

always @(posedge clk or posedge reset) 
begin
   if (reset)
   begin
       busy <= 0;
       out_valid <= 0;
       cnt[R] <= 14'd0;
       cnt[G] <= 14'd0;
       cnt[B] <= 14'd0;
       sum[R] <= 22'd0;
       sum[G] <= 22'd0;
       sum[B] <= 22'd0;
       i <= 5'd0;
       pixel_count <= 14'd0;
   end 
   else
   begin
       case (cur_state)
            0: begin
                cur_image_index <= image_in_index;
                pixel_count <= pixel_count + 14'd1;
                busy <= (pixel_count == 14'd16383) ? 1 : 0;
                // compare rgb cnt
                if (pixel_in[23:16] >= pixel_in[15:8] && pixel_in[23:16] >= pixel_in[7:0]) begin // red
                    cnt[R] <= cnt[R] + 14'd1;
                    sum[R] <= sum[R] + pixel_in[23:16];
                end
                else if (pixel_in[15:8] >= pixel_in[7:0] && pixel_in[15:8] > pixel_in[23:16]) begin // green
                    cnt[G] <= cnt[G] + 14'd1;
                    sum[G] <= sum[G] + pixel_in[15:8];
                end
                else begin
                    cnt[B] <= cnt[B] + 14'd1;
                    sum[B] <= sum[B] + pixel_in[7:0];
                end
                // assign rgb sum
            end
            1: begin // find
                j <= cur_image_index;
                if (i == cur_image_index) begin
                    // next state
                end
                else if (cur_color > color[i]) begin
                    i <= i + 5'd1; 
                end
                else if (div > means[i] && cur_color >= color[i]) begin
                    i <= i + 5'd1;
                end
                else begin
                    // next state
                end
            end
            2: begin // insert
                if (j == 5'd0 || i == j) begin
                    color[j] <= cur_color;
                    index[j] <= cur_image_index;
                    means[j] <= div;
                end
                else begin
                    color[j] <= color[j - 1];
                    index[j] <= index[j - 1];
                    means[j] <= means[j - 1];
                    j <= j - 5'd1;
                end
            end
            3: begin
                busy <= (cur_image_index == 5'd31) ? 1 : 0;
                cnt[R] <= 0;
                cnt[G] <= 0;
                cnt[B] <= 0;
                sum[R] <= 0;
                sum[G] <= 0;
                sum[B] <= 0;
                i <= 0;
            end
            default: begin
                out_valid <= 1;
                color_index <= color[i];
                image_out_index <= index[i];
                i <= i + 5'd1;
            end
       endcase    
   end
end

always @(*) begin
    div = {sum[cur_color], 3'd0} / cnt[cur_color];
end

always @(*) begin
    if (cnt[R] > cnt[G] && cnt[R] > cnt[B]) cur_color = R;
    else if (cnt[G] > cnt[R] && cnt[G] > cnt[B]) cur_color = G;
    else cur_color = B;
end
endmodule
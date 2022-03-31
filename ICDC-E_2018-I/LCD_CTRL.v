module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;
input [3:0] cmd;
input cmd_valid;
input [7:0] IROM_Q;
output reg IROM_rd;
output reg [5:0] IROM_A;
output reg IRAM_valid;
output reg [7:0] IRAM_D;
output wire [5:0] IRAM_A;
output reg busy;
output reg done;

reg [3:0] cur_state,next_state;
reg [7:0] image [0:63];
reg [2:0] image_X;
reg [2:0] image_Y;

assign 


always @(posedge reset or posedge clk) begin
    if(reset) begin
        IROM_rd <= 1;
        IROM_A <= 0;
        IRAM_A <= 0;
        IRAM_D <= 0;
        busy <= 1;
        done <= 0;
        FSM <= 0;
        {image_Y,image_X} <= 0;
    end
    else if(IROM_rd)begin 
        if(IROM_A == 63) begin
            busy <= 0;
            IROM_rd <= 0;
        end
        else 
            busy <= 1;
        image[IROM_A] <= IROM_Q;
        IROM_A <= IROM_A + 1;
    end
    else if(cmd_valid && !busy) begin
        busy <= 1;
        FSM <= cmd;
        {image_Y,image_X} <= 0;
    end
    else begin
        case (FSM)
            0:begin

                {image_Y,image_X} <= {image_Y,image_X} + 1;
            end
            1:
            2: 
            default: 
        endcase
    end
end


endmodule




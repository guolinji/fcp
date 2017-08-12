`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:12:21 08/12/2017
// Design Name: 
// Module Name:    fcp logical layer
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module fcp_logical_layer (
    clk,
    rst_n,
    //
    rx_data,
    rx_data_en,
);

input     clk;
input     rst_n;

reg         [3:0] cur_st;
reg         [3:0] nxt_st;

// RD: 8'b0     SBRRD       REGADDR     CRC
// WT: SBRWR    EGADDR      DATA        CRC
assign wr_en    = rx_data[31:24]==SBRWR;
assign rd_en    = rx_data[31:24]==8'b0 && rx_data[23:16]==SBRRD;
assign wr_data  = wr_en ? rx_data[15:8] : 8'b0;
assign addr     = wr_en ? rx_data[23:16] : rx_data[15:8];
assign crc_data = rx_data[7:0];

//========================================================================================
//========================================================================================
//              Main State
//========================================================================================
//========================================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cur_st <= SLV_IDLE;
    end else begin
        cur_st <= nxt_st;
    end
end

always @(*) begin
    nxt_st = cur_st;

    case(cur_st)
    SLV_IDLE: begin
        if (ping_from_master) begin
            nxt_st = SLV_WAIT_BUS;
        end
    end
    SLV_WAIT_BUS: begin
        if (reset_from_master) begin
            nxt_st = SLV_IDLE;
        end else if (bus_ready & require_respond) begin
            nxt_st = SLV_SEND_RESPOND;
        end else if (bus_ready) begin
            nxt_st = SLV_SEND_PING;
        end
    end
    SLV_SEND_PING: begin
        if (slave_ping_send & respond_done) begin
            nxt_st = SLV_IDLE;
        end else if (slave_ping_send & require_respond) begin
            nxt_st = SLV_WAIT_BUS;
        end else if (slave_ping_send & !require_respond) begin
            nxt_st = SLV_RECEIVER_DATA;
        end
    end
    SLV_SEND_RESPOND: begin
        if (respond_done) begin
            nxt_st = SLV_SEND_PING;
        end
    end
    SLV_RECEIVER_DATA: begin
        if (reset_from_master) begin
            nxt_st = SLV_IDLE;
        end else if (command_received & data_corrupted) begin
            nxt_st = SLV_IDLE;
        end else if (command_received) begin
            nxt_st = SLV_WAIT_BUS;
        end
    end
    default;
    endcase
end

endmodule

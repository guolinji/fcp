`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:12:21 08/12/2017
// Design Name: 
// Module Name:    rx ctrl
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

module fcp_rx_ctrl (
    clk,
    rst_n,
    //
    data,
    rx_own_bus,
);

input     clk;
input     rst_n;

//========================================================================================
//              Main State
//========================================================================================

assign rx_invalid   = !rx_own_bus;      //master does not own the bus

// UI = 20 clock cycle
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dur_cnt <= 'b0;
    end else if (rx_invalid) begin      //count when receiver data
        dur_cnt <= 'b0;
    end else if (data_pos_edge) begin   //re-start the count at the beginning of a pulse
        dur_cnt <= 'b1;
    end else if (data) begin
        dur_cnt <= dur_cnt + 1;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        data_r <= 1'b0;
    end else if (rx_invalid) begin
        data_r <= 1'b0;
    end else begin
        data_r <= data;
    end
end

assign data_pos_edge        = rx_invalid ? 1'b0 : data&(!data_r);
assign data_neg_edge        = rx_invalid ? 1'b0 : (!data)&data_r;

assign quarter_pulse        = data_neg_edge ? (dur_cnt<6) : 1'b0;                       // 1/4 UI Pulse
assign ping_from_master     = data_neg_edge ? (dur_cnt>=288 && dur_cnt<=352) : 1'b0;
assign reset_from_master    = data_neg_edge ? (dur_cnt>=1800) : 1'b0;

// register is high from 1/4 pulse to the nxt posedge
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        quarter_pulse_previous <= 1'b0;
    end else if (quarter_pulse) begin
        quarter_pulse_previous <= 1'b1;
    end else if (data_pos_edge) begin
        quarter_pulse_previous <= 1'b0;
    end
end

// Low quarter pulse cnt
// begins when a quarter_pulse is dectected
// stops when the next posedge is dectected
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        low_quarter_pulse_dur_cnt <= 'b0;
    end else if (quarter_pulse) begin                                   // start count when a high 1/4 pulse is detected
        low_quarter_pulse_dur_cnt <= 'b1;
    end else if (quarter_pulse_previous) begin
        low_quarter_pulse_dur_cnt <= low_quarter_pulse_dur_cnt + 1;
    end
end

assign low_quarter_pulse    = data_pos_edge ? (low_quarter_pulse_dur_cnt<6) : 1'b0;

// Clock sync cnt
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        clk_sync_cnt <= 'b0;
    end else if (ping_from_master) begin     // 16 UI master ping
        clk_sync_cnt <= dur_cnt>>4;
    end else if (parity_en) begin               // 1/4 UI Sync
        clk_sync_cnt <= dur_cnt<<2;
    end
end

// Count for 1 UI, sample at 1/2 UI
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        cnt_for_sample <= 'b0;
    end else if (cnt_for_sample==clk_sync_cnt) begin
        cnt_for_sample <= 'b0;
    end else if (quarter_pulse | low_quarter_pulse) begin
        cnt_for_sample <= 'b0;
    end else if (rx_st) begin
        cnt_for_sample <= cnt_for_sample + 1;
    end
end

assign sample_en    = (cnt_for_sample==(clk_sync_cnt>>1)) ? 1'b1 : 1'b0;

// sampled data [8:1] data, [0:0] parity
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        sample_data <= 'b0;
    end else if (sample_en) begin
        sample_data <= {sample_data[7:0], data};
    end
end

// bit numbers have been sampled
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        sample_num <= 'b0;
    end else if (quarter_pulse) begin
        sample_num <= 'b0;
    end else if (sample_en) begin
        sample_num <= sample_num + 1;
    end
end

assign parity_en            = quarter_pulse & (sample_num == 9);
assign parity_value         = ^sample_data; // 1:pass  0:fail

// parity fail register
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        parity_pass <= 1'b1;
    end else if (rx_start) begin
        parity_pass <= 1'b1;
    end else if (parity_en) begin
        if (!parity_pass) begin              // if previous parity check fail, it remains
            parity_pass <= 1'b0;
        end else if (!parity_value) begin    // parity check fail
            parity_pass <= 1'b0;
        end
    end
end

// 32 bit register to store the received data
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        rx_data <= 'b0;
    end else if (rx_start) begin
        rx_data <= 'b0;
    end else if (parity_en & parity_value) begin
        rx_data <= {rx_data[23:0], sample_data[8:1]};
    end
end

// Rx FSM
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_st <= 1'b0;
    end else if (quarter_pulse) begin
        rx_st <= 1'b1;
    end else if (ping_from_master) begin
        rx_st <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_st_r <= 1'b0;
    end else begin
        rx_st_r <= rx_st;
    end
end

assign rx_start     = rx_st & (!rx_st_r);
assign rx_end       = (!rx_st) & rx_st_r;
assign crc_pass     = 1'b1;
assign rx_data_en   = rx_end & parity_pass & crc_pass;

endmodule

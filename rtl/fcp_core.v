`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:12:21 08/12/2017
// Design Name: 
// Module Name:    fcp core
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

module fcp_core (
    clk,
    rstn,
    // I
    // O
    UP_VOLT,
    DN_VOLT,
    // IO
    data
);

//================================
// IO ports
//================================
input       clk;
input       rstn;
output      UP_VOLT;
output      DN_VOLT;

inout       data;
//================================
// Signals
//================================
wire            ping_from_master;
wire            reset_from_master;
wire            crc_error;
wire            par_error;
wire [23:0]     rx_data;
wire            rx_data_valid;
wire            tx_done;
wire            pl_tx_en;
wire            pl_tx_type;
wire [15:0]     pl_tx_data;
wire            UP_VOLT;
wire            DN_VOLT;

fcp_logical_layer U_FCP_LOGICAL_LAYER (
         .clk                   (clk)
        ,.rstn                  (rstn)
        // I
        ,.ping_from_master      (ping_from_master)
        ,.reset_from_master     (reset_from_master)
        ,.crc_error             (crc_error)
        ,.par_error             (par_error)
        ,.rx_data               (rx_data)
        ,.rx_data_valid         (rx_data_valid)
        ,.tx_done               (tx_done)
        // O
        ,.pl_tx_en              (pl_tx_en)
        ,.pl_tx_type            (pl_tx_type)
        ,.pl_tx_data            (pl_tx_data)
        ,.UP_VOLT               (UP_VOLT)
        ,.DN_VOLT               (DN_VOLT)
        );

fcp_physical_layer U_FCP_PYSICAL_LAYER (
         .clk                   (clk)
        ,.rstn                  (rstn)
        // I
        ,.pl_tx_en              (pl_tx_en)
        ,.pl_tx_type            (pl_tx_type)
        ,.pl_tx_data            (pl_tx_data)
        // O
        ,.ping_from_master      (ping_from_master)
        ,.reset_from_master     (reset_from_master)
        ,.crc_error             (crc_error)
        ,.par_error             (par_error)
        ,.rx_data               (rx_data)
        ,.rx_data_valid         (rx_data_valid)
        ,.tx_done               (tx_done)
        // IO
        ,.data                  (data)
        );

endmodule


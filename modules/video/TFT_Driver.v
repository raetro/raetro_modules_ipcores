//##############################################################################
// Project       : Awesome FPGA
// Purpose       : TFT Driver Module
// Author        : Verdvana
// Creation Date : 20190412
//##############################################################################
//
// Copyright (c) 2019 Verdvana
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
//##############################################################################
module tft_driver(
	input clk,             // 33.3M
	input rst_n,
	input [23:0] data_in,  // Data to be displayed

	output [10:0] hcount,  // X coordinate
	output [10:0] vcount,  // Y coordinate
	output tft_request,    // Data request signal

	output tft_clk,        // Drive clock
	output tft_de,         // Enable
	output tft_blank_n,
	output tft_hsync,
	output tft_vsync,
	output [23:0] tft_rgb, // TFT data output
	output tft_pwm
);

	// 800*480 Timing parameters
	parameter H_SYNC=11'd2;     // Line synchronization
	parameter H_BACK=11'd44;    // Line display trailing edge
	parameter H_DISP=11'd800;   // Line valid data
	parameter H_FRON=11'd210;   // Line display leading edge
	parameter H_TOTAL=11'd1056; // Line scan cycle

	parameter V_SYNC=11'd2;     // Field sync
	parameter V_BACK=11'd22;    // Field display trailing edge
	parameter V_DISP=11'd480;   // Field valid data
	parameter V_FRONT=11'd22;   // Field display front
	parameter V_TOTAL=11'd524;  // Field scan period

	// Required display area
	parameter X_START=12'd24;
	parameter X_ZOOM=12'd752;
	parameter Y_START=12'd0;
	parameter Y_ZOOM=12'd480;

	assign tft_clk = clk;
	assign tft_pwm = rst_n;

	// TFT Drive part
	reg [10:0] hcount_r; // TFT line scan counter
	reg [10:0] vcount_r; // TFT field scan counter
	// Line scan
	always @(posedge clk or negedge rst_n)
		begin
			if (!rst_n)
				hcount_r <= 11'd0;
			else if (hcount_r == H_TOTAL)
				hcount_r <= 11'd0;
			else
				hcount_r <= hcount_r+11'd1;
		end

	// Field scan
	always @(posedge clk or negedge rst_n)
		begin
			if (!rst_n)
				vcount_r <= 11'd0;
			else if (hcount_r == H_TOTAL)
				begin
					if (vcount_r == V_TOTAL)
						vcount_r <= 11'd0;
					else
						vcount_r <= vcount_r+11'd1;
				end
			else
				vcount_r <= vcount_r;
		end

	// Data, same frequency signal output
	assign tft_de = ((hcount_r >= (H_SYNC+H_BACK)) && (hcount_r < (H_SYNC+H_BACK+H_DISP))) &&
		            ((vcount_r >= (V_SYNC+V_BACK)) && (vcount_r < (V_SYNC+V_BACK+V_DISP))) ? 1'b1:1'b0;

	assign tft_hsync = (hcount_r > H_SYNC-1);
	assign tft_vsync = (vcount_r > V_SYNC-1);
	assign tft_rgb = (tft_request) ? data_in:24'h0000;
	assign tft_blank_n = tft_de;

	assign tft_request = ((hcount_r >= (H_SYNC+H_BACK+X_START)) && (hcount_r < (H_SYNC+H_BACK+X_START+X_ZOOM))) &&
		                 ((vcount_r >= (V_SYNC+V_BACK+Y_START)) && (vcount_r < (V_SYNC+V_BACK+Y_START+Y_ZOOM)));

	assign hcount = tft_request ? (hcount_r-H_SYNC-H_BACK-X_START):11'd0;
	assign vcount = tft_request ? (vcount_r-V_SYNC-V_BACK-Y_START):11'd0;

endmodule

// megafunction wizard: %Shift register (RAM-based)%VBB%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altshift_taps 

// ============================================================
// File Name: fifo_disp.v
// Megafunction Name(s):
// 			altshift_taps
//
// Simulation Library Files(s):
// 			altera_mf
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 8.0 Build 215 05/29/2008 SJ Full Version
// ************************************************************

//Copyright (C) 1991-2008 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions 
//and other software and tools, and its AMPP partner logic 
//functions, and any output files from any of the foregoing 
//(including device programming or simulation files), and any 
//associated documentation or information are expressly subject 
//to the terms and conditions of the Altera Program License 
//Subscription Agreement, Altera MegaCore Function License 
//Agreement, or other applicable license agreement, including, 
//without limitation, that your use is for the sole purpose of 
//programming logic devices manufactured by Altera and sold by 
//Altera or its authorized distributors.  Please refer to the 
//applicable agreement for further details.

module fifo_disp (
	clock,
	shiftin,
	shiftout,
	taps);

	input	  clock;
	input	[23:0]  shiftin;
	output	[23:0]  shiftout;
	output	[23:0]  taps;

endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: ACLR NUMERIC "0"
// Retrieval info: PRIVATE: CLKEN NUMERIC "0"
// Retrieval info: PRIVATE: GROUP_TAPS NUMERIC "0"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone II"
// Retrieval info: PRIVATE: NUMBER_OF_TAPS NUMERIC "1"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "1"
// Retrieval info: PRIVATE: TAP_DISTANCE NUMERIC "1597"
// Retrieval info: PRIVATE: WIDTH NUMERIC "24"
// Retrieval info: CONSTANT: LPM_HINT STRING "RAM_BLOCK_TYPE=M512"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altshift_taps"
// Retrieval info: CONSTANT: NUMBER_OF_TAPS NUMERIC "1"
// Retrieval info: CONSTANT: TAP_DISTANCE NUMERIC "1597"
// Retrieval info: CONSTANT: WIDTH NUMERIC "24"
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: USED_PORT: shiftin 0 0 24 0 INPUT NODEFVAL shiftin[23..0]
// Retrieval info: USED_PORT: shiftout 0 0 24 0 OUTPUT NODEFVAL shiftout[23..0]
// Retrieval info: USED_PORT: taps 0 0 24 0 OUTPUT NODEFVAL taps[23..0]
// Retrieval info: CONNECT: @shiftin 0 0 24 0 shiftin 0 0 24 0
// Retrieval info: CONNECT: shiftout 0 0 24 0 @shiftout 0 0 24 0
// Retrieval info: CONNECT: taps 0 0 24 0 @taps 0 0 24 0
// Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL fifo_disp.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL fifo_disp.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL fifo_disp.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL fifo_disp.bsf FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL fifo_disp_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL fifo_disp_bb.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL fifo_disp_waveforms.html TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL fifo_disp_wave*.jpg FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL fifo_disp_syn.v TRUE
// Retrieval info: LIB_FILE: altera_mf
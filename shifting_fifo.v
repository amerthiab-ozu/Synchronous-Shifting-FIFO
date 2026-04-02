/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Özyeğin University | Electrical and Electronics Eng. Dept.
// EE568 Hardware Design Patterns | Prof. H. Fatih Uğurdağ
// Teaching Assistant: Amer Dyab (amer.thiab@ozu.edu.tr)

// Project: Classic Synthesizable Shifting FIFO

// File Name  : shifting_fifo.v
// Language   : Verilog-2001
// Description: Reformatted Version of Provided syncFIFO_shifting.v Reference

// Modifications Since Draft:
//
// 1. Each Input Has its always@<input> block
// 2. Each Input Block Displays Time Difference between Posedge of Clock and Drive Input

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module shifting_fifo #(

    parameter               N  = 32,        // Number of Entries (Buffer Length)
    parameter               BW = 8          // Bandwidth (Data Width in Bits)

)(

    input                   clk,            // Clock
    input                   rst,            // Sync Reset (Active-High)

    input                   pop,            // Pop Request      *In Reference: ren
    input                   push,           // Push Request     *In Reference: wen

    input       [BW-1:0]    data_in,        // Input Data       *In Reference: din

    output reg  [BW-1:0]    data_out,       // Output Data      *In Reference: dout
    
    output reg              full,           // Full Flag        
    output reg              empty           // Empty Flag       

);

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Local Parameters --------------------------------------------------------------------------------------------

    localparam              WPW = $clog2(N);            // Write Pointer Width

    // Regs --------------------------------------------------------------------------------------------------------

    reg                     empty_nxt, full_nxt;        // Status Nexts

    reg [WPW-1:0]           wptr, wptr_nxt;             // Write Pointer
    reg [WPW-1:0]           wptr_shifted;               // Write Pointer After Pop Shift

    reg                     equal;                      // Helper Flag (As in Reference)

    reg [BW-1:0]            mem [0:N-1];               // FIFO Memory

    integer                 ii;                         // Loop Index for Shifting

    time                    last_clk_posedge_time;      // Last Clock Posedge Time

// Input Monitoring //////////////////////////////////////////////////////////////////////////////////////////////////

    always @(posedge clk) begin
        last_clk_posedge_time = $time;
    end

    always @(rst) begin
        $display("\n[FIFO INPUT MONITOR] =================================================================================");
        $display("[FIFO INPUT MONITOR] Time: %0t ns | Input Change: rst     = %0b | Delta from clk posedge: %0t ns",
                 $time, rst, $time - last_clk_posedge_time);
        $display("[FIFO INPUT MONITOR] =================================================================================\n");
    end

    always @(pop) begin
        $display("\n[FIFO INPUT MONITOR] =================================================================================");
        $display("[FIFO INPUT MONITOR] Time: %0t ns | Input Change: pop     = %0b | Delta from clk posedge: %0t ns",
                 $time, pop, $time - last_clk_posedge_time);
        $display("[FIFO INPUT MONITOR] =================================================================================\n");
    end

    always @(push) begin
        $display("\n[FIFO INPUT MONITOR] =================================================================================");
        $display("[FIFO INPUT MONITOR] Time: %0t ns | Input Change: push    = %0b | Delta from clk posedge: %0t ns",
                 $time, push, $time - last_clk_posedge_time);
        $display("[FIFO INPUT MONITOR] =================================================================================\n");
    end

    always @(data_in) begin
        $display("\n[FIFO INPUT MONITOR] =================================================================================");
        $display("[FIFO INPUT MONITOR] Time: %0t ns | Input Change: data_in = 0x%0h | Delta from clk posedge: %0t ns",
                 $time, data_in, $time - last_clk_posedge_time);
        $display("[FIFO INPUT MONITOR] =================================================================================\n");
    end

// Sequential Logic /////////////////////////////////////////////////////////////////////////////////////////////////

    always @(posedge clk) begin
        
        // Shifting Logic ------------------------------------------------------------------------------------------
        
        empty <= #1 empty_nxt;
        full  <= #1 full_nxt;
        wptr  <= #1 wptr_nxt;
        
        // Pop and Push Operations ---------------------------------------------------------------------------------
        
        if (pop)
            for (ii = 0; ii < N-1; ii = ii + 1)         // Shift Memory Contents Toward Front (mem[0])
                mem[ii] <= #1 mem[ii+1];

        if (push)
            mem[wptr_shifted] <= #1 data_in;            // Push Input to Data to WPTR Location

    end

// Combinational Logic //////////////////////////////////////////////////////////////////////////////////////////////

    always @* begin

        data_out = mem[0];                              // Data Out is Always the Front Entry

        wptr_shifted = wptr - pop;                      // Pointer Moving
        wptr_nxt     = wptr_shifted + push;
        
        equal        = (wptr_nxt == 0);                 // WPTR is at Front

        empty_nxt = empty;
        full_nxt  = full;
        
        // Reset State ---------------------------------------------------------------------------------------------
        
        if (rst) begin
            empty_nxt = 1;
            full_nxt  = 0;
            wptr_nxt  = 0;
        end
        
        // Operational State ---------------------------------------------------------------------------------------
        
        else begin
        
            if (push) begin                             // Full Update
                empty_nxt = 0;
                if (equal) full_nxt = 1;
            end

            else if (pop) begin                         // Empty Update
                full_nxt = 0;
                if (equal) empty_nxt = 1;
            end
        end

    end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Özyeğin University | Electrical and Electronics Eng. Dept.
// EE568 Hardware Design Patterns | Prof. H. Fatih Uğurdağ
// Teaching Assistant: Amer Dyab (amer.thiab@ozu.edu.tr)

// Project: Classic Synthesizable Shifting FIFO

// File Name  : tb_shifting_fifo.v
// Language   : Verilog-2001
// Description: Basic Testbench for shifting_fifo.v or shifting_fifo_altx.v

// Test Sections:

// 1) Full Fill  : Detect/Check Empty First, Then Fill FIFO Completely
// 2) Full Drain : Detect/Check Full First, Then Drain FIFO Completely
// 3) Simultaneous Push/Pop While Full (5 Cycles)

// Modifications Since Draft:
//
// 1. All FIFO Drive Signals Now Use Non-blocking Assignments and Two-unit Delay

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_shifting_fifo;

// Global Parameters ////////////////////////////////////////////////////////////////////////////////////////////////

    parameter N  = 8;                           // FIFO Depth (Cells)
    parameter BW = 8;                           // Word Width (Bits)

    parameter CLK_PERIOD_NS      = 10;          // Clock Period in Nanoseconds
    parameter POST_CLK_SETTLE_NS = 2;           // Settling Time in Nanoseconds

// S-FIFO DUT I/O Signals and Instance ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    reg             clk;
    reg             rst;
    reg             push;
    reg             pop;
    reg  [BW-1:0]   data_in;

    wire            empty;
    wire            full;
    wire [BW-1:0]   data_out;
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // CHANGE WHICH FIFO MODULE YOU WANT TO TEST HERE ///////////////////////////////////////////////////////////////
    
    shifting_fifo #(                
    
        .N          (N              ),          .BW         (BW             )
        
    ) dut (
    
        .clk        (clk            ),          .rst        (rst            ),
        
        .push       (push           ),          .pop        (pop            ),
        .data_in    (data_in        ),
        
        .empty      (empty          ),          .full       (full           ),
        .data_out   (data_out       )
        
    );
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Clock Generator ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    initial clk = 1'b0;
    always #(CLK_PERIOD_NS/2) clk = ~clk;

// Testbench Operational Variables //////////////////////////////////////////////////////////////////////////////////

    integer         i, j;                       // Loop Variables
    
    // Numbers of Checks, Passes, and Fails (Whole Test and Per Each Section)
    
    integer         checks,         pass,           fail;             
    integer         fill_checks,    fill_pass,      fill_fail;
    integer         drain_checks,   drain_pass,     drain_fail;
    integer         sim_checks,     sim_pass,       sim_fail;

    reg [BW-1:0]    expected;                       // Expected Result
    
    reg [BW-1:0]    ref_q [0:N-1];                  // Reference Queue for Section 3 (Sim. P/P)
    integer         ref_count;

    integer         t_ns;                           // Formatted Time Helper

// Formatting Helpers (Verilog-2001) ////////////////////////////////////////////////////////////////////////////////

    // Prints Decimal with Comma Separators (e.g., 317,000) --------------------------------------------------------
    
    task print_dec_commas;
    
        input integer   value;
        integer         millions;
        integer         thousands;
        integer         units;
    
        begin
        
            if (value < 1000) begin
                $write("%0d", value);
            end
            
            else if (value < 1000000) begin
                thousands = value / 1000;
                units     = value % 1000;
                $write("%0d,%03d", thousands, units);
            end
            
            else begin
                millions  = value / 1000000;
                thousands = (value % 1000000) / 1000;
                units     = value % 1000;
                $write("%0d,%03d,%03d", millions, thousands, units);
            end
        end
    
    endtask

    // Fixed-Format Line Prefix: [CHK] [TIME] [TYPE] --------------------------------------------------------------
    
    task print_prefix;
    
        input [7:0] level_char;                     // "i", "e", "!"
    
        begin
            t_ns = $time;                               // timescale is 1ns/1ps
            $write("[%-4d] | [t=", checks);
            print_dec_commas(t_ns);
            $write(" ns] | (%0s) | ", level_char);
        end
    
    endtask

// Utility Helpers //////////////////////////////////////////////////////////////////////////////////////////////////

    task log_banner;
    
        begin
            $display("");
            $display("================================================================================================");
            $display("FIFO TESTBENCH STARTED (Simplified Directed Tests)");
            $display("N = %0d | BW = %0d | Clock = %0d ns | Sample = Posedge + %0d ns", N, BW, CLK_PERIOD_NS, POST_CLK_SETTLE_NS);
            $display("Tests: [1] Full Fill  [2] Full Drain  [3] 5x Simultaneous Push/Pop While Full");
            $display("================================================================================================");
            $display("");
        end
        
    endtask

    task log_section;
        input [8*80-1:0] title;
            
        begin
            $display("------------------------------------------------------------------------------------------------");
            $display("%0s", title);
            $display("------------------------------------------------------------------------------------------------");
        end
        
    endtask

    task log_info;
    
        input [8*160-1:0] msg;
        
        begin
            print_prefix("i");
            $display("%0s", msg);
        end
        
    endtask

    task log_exec;
    
        input [8*160-1:0] msg;
            
        begin
            print_prefix("e");
            $display("%0s", msg);
        end
        
    endtask

    task log_error;
    
        input [8*160-1:0] msg;
        
        begin
        
            print_prefix("!");
            
            $display("%0s", msg);
            $display("    >>> Failure Detail");
            $display("        DUT Flags   : Empty=%0b | Full=%0b", empty, full);
            $display("        DUT DataOut : 0x%0h", data_out);
            $display("        TB Control  : Rst=%0b | Push=%0b | Pop=%0b | DataIn=0x%0h", rst, push, pop, data_in);
            
        end
        
    endtask
    
    task add_check;
    
        input integer section_id;           // 1=Fill, 2=Drain, 3=Sim
        input ok;
        input [8*160-1:0] pass_msg;
        input [8*160-1:0] fail_msg;
        
        begin
        
            checks = checks + 1;
    
            if (section_id == 1) fill_checks  = fill_checks  + 1;
            if (section_id == 2) drain_checks = drain_checks + 1;
            if (section_id == 3) sim_checks   = sim_checks   + 1;
    
            if (ok) begin
                pass = pass + 1;
    
                if (section_id == 1) fill_pass  = fill_pass  + 1;
                if (section_id == 2) drain_pass = drain_pass + 1;
                if (section_id == 3) sim_pass   = sim_pass   + 1;
    
                log_info(pass_msg);
            end
            
            else begin
                fail = fail + 1;
    
                if (section_id == 1) fill_fail  = fill_fail  + 1;
                if (section_id == 2) drain_fail = drain_fail + 1;
                if (section_id == 3) sim_fail   = sim_fail   + 1;
    
                log_error(fail_msg);
            end
            
        end
        
    endtask

    task section_summary;
    
        input [8*64-1:0] name;
        input integer c;
        input integer p;
        input integer f;
        
        begin
            $display("------------------------------------------------------------------------------------------------");
            $display("%0s Summary | Checks = %0d | Pass = %0d | Fail = %0d", name, c, p, f);
            $display("------------------------------------------------------------------------------------------------");
            $display("");
        end
        
    endtask
    
// FIFO Driving Helpers //////////////////////////////////////////////////////////////////////////////////////////////
    
    task wait_sample;           // Settlement Delay -----------------------------------------------------------------
    
        begin
            @(posedge clk);             // Wait for the Next Posedge
            #(POST_CLK_SETTLE_NS);      // Wait a Predefined Delay (Set to 2ns)
        end
        
    endtask

    task do_push;               // Push ------------------------------------------------------------------------------
    
        input [BW-1:0] din;
        
        begin
        
            push        <=  1'b1;
            pop         <=  1'b0;
            data_in     <=  din;
            
            wait_sample;
            
            push        <=  1'b0;
            pop         <=  1'b0;
            data_in     <=  {BW{1'b0}};
        end
    
    endtask

    task do_pop;                // Pop -------------------------------------------------------------------------------
    
        begin
        
            push        <=  1'b0;
            pop         <=  1'b1;
            
            wait_sample;
            
            push        <=  1'b0;
            pop         <=  1'b0;
        end
    
    endtask

    task do_sim_push_pop;       // Push || Pop -----------------------------------------------------------------------
    
        input [BW-1:0] din;
        
        begin
        
            push        <=  1'b1;
            pop         <=  1'b1;
            data_in     <=  din;
            
            wait_sample;
            
            push        <=  1'b0;
            pop         <=  1'b0;
            data_in     <=  {BW{1'b0}};
        end
        
    endtask

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Main Test Sequence
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    initial begin
        
        // Initial State -------------------------------------------------------------------------------------------
        
        rst             <= 1'b1;
        push            <= 1'b0;
        pop             <= 1'b0;
        
        data_in         <= {BW{1'b0}};
        
        wait_sample;
        
        checks          = 0;    pass        = 0;           fail = 0;
        fill_checks     = 0;    fill_pass   = 0;      fill_fail = 0;
        drain_checks    = 0;    drain_pass  = 0;     drain_fail = 0;
        sim_checks      = 0;    sim_pass    = 0;       sim_fail = 0;

        ref_count = 0;
        expected  = {BW{1'b0}};

        // Initiate Reset ------------------------------------------------------------------------------------------
        
        @(posedge clk);
        @(posedge clk);
        
        rst             <= 1'b0;
        
        wait_sample;

        log_banner;

// 1) Full Fill /////////////////////////////////////////////////////////////////////////////////////////////////////

        log_section ("1) Full Fill");

        add_check (1, (empty === 1'b1),
        "FIFO Is Empty After Reset (Good Start).", "FIFO Is Not Empty After Reset.");
        
        add_check (1, (full === 1'b0),
        "FIFO Is Not Full After Reset.", "FIFO Is Unexpectedly Full After Reset.");

        for (i = 0; i < N; i = i + 1) begin
        
            add_check (1, (full === 1'b0),
            "FIFO Has Room Before Push.", "FIFO Reports Full Too Early During Fill.");

            print_prefix("e");
            $display("Push Value = 0x%0h", i[BW-1:0]);

            do_push(i[BW-1:0]);

            if (i == 0) begin
            
                add_check (1, (empty === 1'b0),
                "FIFO Left Empty State After First Push.", "FIFO Still Reports Empty After First Push.");
            end
        end

        add_check (1, (full === 1'b1),
        "FIFO Is Full After Complete Fill.", "FIFO Did Not Assert Full After Complete Fill.");

        add_check (1, (empty === 1'b0), "FIFO Is Not Empty When Full.", "FIFO Reports Empty While Full.");

        section_summary ("Fill", fill_checks, fill_pass, fill_fail);

// 2) Full Drain ////////////////////////////////////////////////////////////////////////////////////////////////////

        log_section ("2) Full Drain");

        add_check (2, (full === 1'b1),
        "FIFO Is Full at Start of Drain (As Expected).", "FIFO Is Not Full at Start of Drain (Fill May Have Failed).");

        for (i = 0; i < N; i = i + 1) begin
        
            add_check (2, (empty === 1'b0),
            "FIFO Has Data Before Pop.", "FIFO Reports Empty Too Early During Drain.");

            expected = i[BW-1:0];
            
            add_check (2, (data_out === expected),
            "Drain Data Matches Expected FIFO Order.",
             "Drain Data Mismatch (Incorrect FIFO Order or Value).");

            if (data_out !== expected) begin
                $display("    >>> Expected = 0x%0h | Actual = 0x%0h | Drain Index = %0d",
                expected, data_out, i);
            end

            print_prefix("e");
            
            $display("Pop Value  = 0x%0h", data_out);

            do_pop;
        end

        add_check (2, (empty === 1'b1),
        "FIFO Is Empty After Complete Drain.", "FIFO Did Not Assert Empty After Complete Drain.");

        add_check (2, (full === 1'b0), "FIFO Is Not Full After Drain.", "FIFO Still Asserts Full After Drain.");

        section_summary ("Drain", drain_checks, drain_pass, drain_fail);

// 3) 5x Simultaneous Push/Pop While Full ///////////////////////////////////////////////////////////////////////////

        log_section("3) 5x Simultaneous Push/Pop While Full");

        log_exec("Preparing FIFO: Refill With Known Pattern 0xA0..0xA7.");

        for (i = 0; i < N; i = i + 1) begin
            do_push(8'hA0 + i[BW-1:0]);
            ref_q[i] = 8'hA0 + i[BW-1:0];
        end
        
        ref_count = N;

        add_check (3, (full === 1'b1),
        "FIFO Is Full Before Simultaneous Push/Pop Test.",
        "FIFO Is Not Full Before Simultaneous Push/Pop Test.");

        add_check (3, (empty === 1'b0),
        "FIFO Is Not Empty Before Simultaneous Push/Pop Test.",
        "FIFO Reports Empty Before Simultaneous Push/Pop Test.");

        for (i = 0; i < 5; i = i + 1) begin
        
            expected = ref_q[0];

            add_check (3, (data_out === expected),
            "Front Item Is Correct Before Simultaneous Push/Pop.",
            "Front Item Mismatch Before Simultaneous Push/Pop.");

            if (data_out !== expected) begin
                $display("    >>> Expected Front = 0x%0h | Actual Front = 0x%0h | Sim Cycle = %0d",
                expected, data_out, i);
            end

            print_prefix("e");
            $display("Sim Push+Pop While Full | Pop = 0x%0h | Push = 0x%0h", ref_q[0], (8'hE0 + i[BW-1:0]));

            do_sim_push_pop(8'hE0 + i[BW-1:0]);

            // Update Reference Queue
            
            for (j = 0; j < N-1; j = j + 1) ref_q[j] = ref_q[j+1];
                
            ref_q[N-1] = 8'hE0 + i[BW-1:0];

            add_check (3, (full === 1'b1),
            "FIFO Remains Full After Simultaneous Push/Pop While Full.",
            "FIFO Full Flag Is Wrong After Simultaneous Push/Pop While Full.");

            add_check (3, (empty === 1'b0),
            "FIFO Remains Not Empty After Simultaneous Push/Pop While Full.",
            "FIFO Empty Flag Is Wrong After Simultaneous Push/Pop While Full.");

            add_check (3, (data_out === ref_q[0]),
            "Front Advanced Correctly After Simultaneous Push/Pop.",
            "Front Did Not Advance Correctly After Simultaneous Push/Pop.");
        end

        section_summary("Simultaneous Push/Pop", sim_checks, sim_pass, sim_fail);

// Final Summary ////////////////////////////////////////////////////////////////////////////////////////////////////

        $display("================================================================================================");
        
        $display("Testbench Finished | Checks = %0d | Pass = %0d | Fail = %0d", checks, pass, fail);
        
        if (fail == 0)  $display("Final Result: Pass");
        else            $display("Final Result: Fail");
            
        $display("================================================================================================");

        $finish;
    end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
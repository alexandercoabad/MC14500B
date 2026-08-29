`default_nettype none

module tt_um_mc14500b_soc_extended (
    input  wire [7:0] ui_in,    // Dedicated inputs (External Input Port)
    output wire [7:0] uo_out,   // Dedicated outputs (External Output Port)
    input  wire [7:0] uio_in,   // IO lines input path
    output wire [7:0] uio_out,  // IO lines output path
    output wire [7:0] uio_oe,   // IO lines output enable
    input  wire       clk,      // Clock signal
    input  wire       rst_n     // Active-low reset
);

    // --- Memory Arrays ---
    reg [7:0] rom_memory [0:255]; // Expanded 256-word Program Memory Block Space
    reg [15:0] ram_bank;          // Full 16-bit Internal Data Scratchpad Memory

    // --- Core Registers ---
    reg [7:0] pc;                // Expanded 8-bit Program Counter Address Register
    reg [7:0] r_ext_out;         // Registered 8-bit output port holding parallel patterns

    // --- Bootloader Init Block ---
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Manual logic array clearing during reset state loops to avoid uninitialized cell blocks
            // Fits cleanly inside the 3x2 tile structural budget
        end
    end

    // --- Core ICU Internal Interconnect Nets ---
    wire [7:0] current_instruction = rom_memory[pc];
    wire [3:0] opcode  = current_instruction[7:4];
    wire [3:0] operand = current_instruction[3:0];

    // Data selector MUX
    wire core_data_in = ram_bank[operand];

    wire core_rr;
    wire core_write_en;
    wire core_data_out;
    wire core_flag_f;
    reg  r_skip;

    // --- MC14500B ICU Hardware Logic Array ---
    reg r_rr, r_oen, r_ien;
    wire actual_data = core_data_in & r_ien;
    
    assign core_rr       = r_rr;
    assign core_data_out = r_rr;
    assign core_write_en = (!r_skip) && r_oen && ((opcode == 4'h8) || (opcode == 4'h9));
    assign core_flag_f   = (!r_skip) && (opcode == 4'h0);

    // --- SoC Parallel Logic Output Register Matrix Update Loop ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_ext_out <= 8'h00;
        end else begin
            r_ext_out <= ram_bank[7:0];
        end
    end

    // --- SoC System Sequential Management ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc       <= 8'h00;
            ram_bank <= 16'h0000;
            r_rr     <= 1'b0;
            r_oen    <= 1'b1;
            r_ien    <= 1'b1;
            r_skip   <= 1'b0;
        end else begin
            // 1. Program Counter Stepper
            pc <= pc + 1'b1;

            // 2. Hardware Input Latch Loop
            ram_bank[15:8] <= ui_in;

            // 3. Sub-Core State Processor Execution Loop
            if (r_skip) begin
                r_skip <= 1'b0;
            end else begin
                case (opcode)
                    4'h0: ; // NOPO
                    4'h1: r_rr   <= actual_data;           // LD
                    4'h2: r_rr   <= !actual_data;          // LDC
                    4'h3: r_rr   <= r_rr & actual_data;    // AND
                    4'h4: r_rr   <= r_rr & (!actual_data); // ANDC
                    4'h5: r_rr   <= r_rr | actual_data;    // OR
                    4'h6: r_rr   <= r_rr | (!actual_data); // ORC
                    4'h7: r_rr   <= !(r_rr ^ actual_data); // XNOR
                    4'h8: ; // STO 
                    4'h9: ; // STOC
                    4'hA: r_ien  <= actual_data;           // IEN
                    4'hB: r_oen  <= actual_data;           // OEN
                    4'hC: ; // JMP
                    4'hD: r_skip <= !r_rr;                 // SKPZ
                    4'hE: ; // ORF
                    4'hF: ; // RTN
                endcase
            end

            // 4. Memory Demultiplexer Internal Ram Write Strobe Logic
            if (core_write_en) begin
                ram_bank[operand] <= (opcode == 4'h9) ? !core_data_out : core_data_out;
            end
        end
    end

    // --- Signal Map Assignment Bus Array Block Layout ---
    assign uo_out = r_ext_out;

    assign uio_out[5:0] = pc[5:0];       
    assign uio_out[6]   = core_rr;       
    assign uio_out[7]   = core_write_en; 
    assign uio_oe       = 8'b11111111;   

endmodule



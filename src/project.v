`default_nettype none

module tt_um_mc14500b_soc_extended (
    input  wire [7:0] ui_in,    // Dedicated inputs (External Parallel Input Port)
    output wire [7:0] uo_out,   // Dedicated outputs (External Parallel Output Port)
    input  wire [7:0] uio_in,   // IO lines input path
    output wire [7:0] uio_out,  // IO lines output path
    output wire [7:0] uio_oe,   // IO lines output enable
    input  wire       ena,      // Tiny Tapeout project select enable (ADD THIS LINE)
    input  wire       clk,      // Clock signal
    input  wire       rst_n     // Active-low reset
);

    // --- SoC Architecture Memory Allocations & Map ---
    // (Everything else inside this file remains exactly the same)
    reg [7:0] rom_memory [0:255]; 
    reg [15:0] ram_bank;          
    reg [7:0] pc;                
    reg [7:0] r_ext_out;         

    initial begin
        rom_memory[0] = 8'h18; 
        rom_memory[1] = 8'h59; 
        rom_memory[2] = 8'h80; 
        rom_memory[3] = 8'h10; 
        rom_memory[4] = 8'hD0; 
        rom_memory[5] = 8'h20; 
        rom_memory[6] = 8'h81; 
        rom_memory[7] = 8'h00; 
        
        for (integer i = 8; i < 256; i = i + 1) begin
            rom_memory[i] = 8'h00; 
        end
    end

    wire [7:0] current_instruction = rom_memory[pc];
    wire [3:0] opcode  = current_instruction[7:4];
    wire [3:0] operand = current_instruction[3:0];

    wire core_data_in = ram_bank[operand];
    wire core_rr;
    wire core_write_en;
    wire core_data_out;
    wire core_flag_f;
    reg  r_skip;

    reg r_rr, r_oen, r_ien;
    wire actual_data = core_data_in & r_ien;
    
    assign core_rr       = r_rr;
    assign core_data_out = r_rr;
    assign core_write_en = (!r_skip) && r_oen && ((opcode == 4'h8) || (opcode == 4'h9));
    assign core_flag_f   = (!r_skip) && (opcode == 4'h0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_ext_out <= 8'h00;
        end else begin
            r_ext_out <= ram_bank[7:0];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc       <= 8'h00;
            ram_bank <= 16'h0000;
            r_rr     <= 1'b0;
            r_oen    <= 1'b1;
            r_ien    <= 1'b1;
            r_skip   <= 1'b0;
        end else begin
            // You can optionally gate your circuit using (ena) here, 
            // but for a classic MCU, running continuously is fine.
            pc <= pc + 1'b1;
            ram_bank[15:8] <= ui_in;

            if (r_skip) begin
                r_skip <= 1'b0;
            end else begin
                case (opcode)
                    4'h0: ; 
                    4'h1: r_rr   <= actual_data;           
                    4'h2: r_rr   <= !actual_data;          
                    4'h3: r_rr   <= r_rr & actual_data;    
                    4'h4: r_rr   <= r_rr & (!actual_data); 
                    4'h5: r_rr   <= r_rr | actual_data;    
                    4'h6: r_rr   <= r_rr | (!actual_data); 
                    4'h7: r_rr   <= !(r_rr ^ actual_data); 
                    4'h8: ; 
                    4'h9: ; 
                    4'hA: r_ien  <= actual_data;           
                    4'hB: r_oen  <= actual_data;           
                    4'hC: ; 
                    4'hD: r_skip <= !r_rr;                 
                    4'hE: ; 
                    4'hF: ; 
                endcase
            end

            if (core_write_en) begin
                ram_bank[operand] <= (opcode == 4'h9) ? !core_data_out : core_data_out;
            end
        end
    end

    assign uo_out = r_ext_out;
    assign uio_out[5:0] = pc[5:0];       
    assign uio_out[6]   = core_rr;       
    assign uio_out[7]   = core_write_en; 
    assign uio_oe       = 8'b11111111;   

endmodule

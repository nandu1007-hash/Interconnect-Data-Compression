`timescale 1ns/1ps

module bdi_dbi_encoder (
    input  logic         clk,
    input  logic         rst_n,
    input  logic [255:0] data_in,
    input  logic         valid_in,
    output logic [255:0] bus_out,
    output logic         dbi_flag,
    output logic         bdi_flag,
    output logic         valid_out
);

    // BDI Intermediate Signals
    logic [31:0]  base_val;
    logic [31:0]  diffs [7:0];
    logic         is_compressible;
    logic [255:0] bdi_data;

    // DBI Intermediate Signals
    logic [8:0]   ones_count;
    logic         do_dbi;
    logic [255:0] final_bus_data;

    always_comb begin
        // ==========================================
        // STAGE 1: BDI COMPRESSION
        // ==========================================
        base_val = data_in[31:0];
        is_compressible = 1'b1;
        bdi_data[31:0] = base_val; // First word is always the base
        
        for (int i = 1; i < 8; i++) begin
            diffs[i] = data_in[i*32 +: 32] - base_val;
            
            // Check if delta fits in 7-bit signed (-64 to 63)
            // This targets your exact Expression Coverage logic
            if ((diffs[i][31:7] != 25'h0000000) && (diffs[i][31:7] != 25'h1FFFFFF)) begin
                is_compressible = 1'b0;
            end
        end

        // Pack the data based on compressibility
        if (is_compressible) begin
            for (int i = 1; i < 8; i++) begin
                // Only send the 7-bit delta, mask the rest to 0 to save power
                bdi_data[i*32 +: 32] = {25'b0, diffs[i][6:0]}; 
            end
        end else begin
            bdi_data = data_in; // Uncompressible, send raw data
        end

        // ==========================================
        // STAGE 2: DBI INVERSION
        // ==========================================
        ones_count = 0;
        for (int i = 0; i < 256; i++) begin
            ones_count += bdi_data[i];
        end
        
        do_dbi = (ones_count > 128);
        final_bus_data = do_dbi ? ~bdi_data : bdi_data;
    end

    // ==========================================
    // FLOPPED OUTPUTS
    // ==========================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_out   <= 256'h0;
            dbi_flag  <= 1'b0;
            bdi_flag  <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            bus_out   <= valid_in ? final_bus_data : 256'h0;
            dbi_flag  <= valid_in ? do_dbi         : 1'b0;
            bdi_flag  <= valid_in ? is_compressible: 1'b0;
            valid_out <= valid_in;
        end
    end

endmodule

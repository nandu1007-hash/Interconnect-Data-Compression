`timescale 1ns/1ps

module bdi_dbi_decoder (
    input  logic         clk,
    input  logic         rst_n,
    input  logic [255:0] bus_in,
    input  logic         dbi_flag,
    input  logic         bdi_flag,
    input  logic         valid_in,
    output logic [255:0] data_out,
    output logic         valid_out
);

    logic [255:0] undbi_data;
    logic [255:0] unbdi_data;

    always_comb begin
        // ==========================================
        // STAGE 1: REVERSE DBI
        // ==========================================
        undbi_data = dbi_flag ? ~bus_in : bus_in;

        // ==========================================
        // STAGE 2: REVERSE BDI
        // ==========================================
        unbdi_data[31:0] = undbi_data[31:0]; // Base is always word 0
        
        for (int i = 1; i < 8; i++) begin
            if (bdi_flag) begin
                // Reconstruct: Base + Sign-Extended 7-bit Delta
                unbdi_data[i*32 +: 32] = undbi_data[31:0] + {{25{undbi_data[i*32+6]}}, undbi_data[i*32 +: 7]};
            end else begin
                // Raw data
                unbdi_data[i*32 +: 32] = undbi_data[i*32 +: 32];
            end
        end
    end

    // ==========================================
    // FLOPPED OUTPUTS
    // ==========================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 256'h0;
            valid_out <= 1'b0;
        end else begin
            data_out  <= valid_in ? unbdi_data : 256'h0;
            valid_out <= valid_in;
        end
    end

endmodule

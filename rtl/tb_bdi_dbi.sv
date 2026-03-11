`timescale 1ns/1ps

module tb_bdi_dbi();

    logic         clk;
    logic         rst_n;
    logic [255:0] tb_data_in;
    logic         tb_valid_in;
    logic [255:0] highway_bus;
    logic         highway_dbi_flag;
    logic         highway_bdi_flag;
    logic         highway_valid;
    logic [255:0] tb_data_out;
    logic         tb_valid_out;

    logic [255:0] expected_queue [$];
    logic [255:0] expected_data;

    initial clk = 0;
    always #0.5 clk = ~clk;

    // Explicit port mapping to fix the dot-star (*W,CUVDSO) warnings
    bdi_dbi_encoder U_ENCODER (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (tb_data_in),
        .valid_in   (tb_valid_in),
        .bus_out    (highway_bus),
        .dbi_flag   (highway_dbi_flag),
        .bdi_flag   (highway_bdi_flag),
        .valid_out  (highway_valid)
    );

    bdi_dbi_decoder U_DECODER (
        .clk        (clk),
        .rst_n      (rst_n),
        .bus_in     (highway_bus),
        .dbi_flag   (highway_dbi_flag),
        .bdi_flag   (highway_bdi_flag),
        .valid_in   (highway_valid),
        .data_out   (tb_data_out),
        .valid_out  (tb_valid_out)
    );

    task send_packet(input [255:0] data, input string packet_type, input bit verbose = 1);
        @(posedge clk);
        tb_data_in  <= data;
        tb_valid_in <= 1'b1;
        expected_queue.push_back(data);
        if (verbose) $display("[%0t] SENT: %s", $time, packet_type);
    endtask

    initial begin
        expected_data = 256'h0;
        rst_n       = 0;
        tb_data_in  = 256'h0;
        tb_valid_in = 0;
        #5; rst_n = 1; #5;

        $display("=========================================================");
        // Changed 100% to 100 PERCENT to fix the *E,ILLFMT error
        $display("   STARTING 100 PERCENT COVERAGE DIRECTED TESTS          ");
        $display("=========================================================");

        // 1. BDI Small Positive (Upper 25-bits = 0)
        send_packet({32'h101C, 32'h1018, 32'h1014, 32'h1010, 32'h100C, 32'h1008, 32'h1004, 32'h1000}, "BDI Small Positive");

        // 2. BDI Small Negative (Upper 25-bits = 1) -> FIXES EXPRESSION COVERAGE
        send_packet({32'h0FE4, 32'h0FE8, 32'h0FEC, 32'h0FF0, 32'h0FF4, 32'h0FF8, 32'h0FFC, 32'h1000}, "BDI Small Negative");

        // 3. All Zeros (Extreme BDI)
        send_packet({8{32'h00000000}}, "All Zeros");

        // 4. Uncompressible Random Noise
        send_packet({32'hDEADBEEF, 32'h8BADF00D, 32'hCAFEBABE, 32'h12345678, 32'h9ABCDEF0, 32'h11223344, 32'h55667788, 32'h99AABBCC}, "Random Uncompressible Noise");

        // 5. DBI Boundary Condition: Exactly 128 ones (Should NOT invert)
        send_packet({ {4{32'hFFFFFFFF}}, {4{32'h00000000}} }, "DBI Boundary: Exactly 128 Ones");

        // 6. DBI Boundary Condition: Exactly 129 ones (SHOULD invert)
        send_packet({ {4{32'hFFFFFFFF}}, 32'h00000001, {3{32'h00000000}} }, "DBI Boundary: Exactly 129 Ones");

        $display("=========================================================");
        $display("   STARTING RANDOMIZED TOGGLE COVERAGE STRESS TEST       ");
        $display("=========================================================");

        for (int i = 0; i < 5000; i++) begin
            send_packet({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom}, "Random", 0);
        end

        @(posedge clk);
        tb_valid_in <= 1'b0;
        #50;
        
        if (expected_queue.size() == 0) $display(">>> VERIFICATION COMPLETE. ZERO FAILURES. <<<");
        else $display("ERROR: Pipeline did not flush.");
        $finish;
    end

    always @(posedge clk) begin
        if (tb_valid_out) begin
            expected_data = expected_queue.pop_front();
            if (tb_data_out !== expected_data) begin
                $error("[%0t] FATAL ERROR: Data corruption!", $time);
                $finish;
            end
        end
    end
endmodule

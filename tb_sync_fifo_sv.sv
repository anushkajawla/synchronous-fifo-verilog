`timescale 1ns/1ps

module tb_sync_fifo_sv;

    localparam DATA_WIDTH = 8;
    localparam DEPTH = 4;

    reg clk, rst, wr_en, rd_en;
    reg [DATA_WIDTH-1:0] din;

    wire [DATA_WIDTH-1:0] dout;
    wire full, empty;

    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty)
    );

    // Reference model: fixed-size circular queue
    reg [DATA_WIDTH-1:0] model_mem [0:DEPTH-1];
    integer model_head = 0;
    integer model_tail = 0;
    integer model_count = 0;

    integer errors = 0;
    integer read_checks = 0;
    integer cycles = 0;

    // Lightweight functional coverage counters
    integer occupancy_hits [0:DEPTH];
    integer blocked_write_hits = 0;
    integer blocked_read_hits = 0;
    integer simultaneous_request_hits = 0;
    integer wr_wrap_hits = 0;
    integer rd_wrap_hits = 0;
    integer i;

    reg accepted_write;
    reg accepted_read;
    reg [DATA_WIDTH-1:0] expected_data;

    always #5 clk = ~clk;

    // Procedural safety checks.
    // Capture the FIFO's pre-clock state, then check after DUT updates settle.
    reg [1:0] pre_wr_ptr;
    reg [1:0] pre_rd_ptr;
    reg pre_full;
    reg pre_empty;
    reg pre_rst;
    reg pre_wr_en;
    reg pre_rd_en;
    integer pre_count;
    integer assertion_checks = 0;

    always @(posedge clk) begin
        // Capture state before the DUT's nonblocking assignments take effect.
        pre_rst    = rst;
        pre_full   = full;
        pre_empty  = empty;
        pre_wr_ptr = dut.wr_ptr;
        pre_rd_ptr = dut.rd_ptr;
        pre_count  = dut.count;
        pre_wr_en  = wr_en;
        pre_rd_en  = rd_en;

        // Allow the DUT's nonblocking assignments to settle.
        #1;

        if (pre_rst) begin
            // Reset is active; skip normal-operation assertions.
        end
        else begin
            assertion_checks = assertion_checks + 1;

            if (full && empty) begin
                $display("ASSERTION FAILED: full and empty both high");
                errors = errors + 1;
            end

            if (dut.count > DEPTH) begin
                $display("ASSERTION FAILED: occupancy exceeds DEPTH");
                errors = errors + 1;
            end

            if (pre_wr_en && pre_full &&
                dut.wr_ptr !== pre_wr_ptr) begin
                $display("ASSERTION FAILED: write pointer advanced on blocked write");
                errors = errors + 1;
            end

            if (pre_rd_en && pre_empty &&
                dut.rd_ptr !== pre_rd_ptr) begin
                $display("ASSERTION FAILED: read pointer advanced on blocked read");
                errors = errors + 1;
            end
        end
    end

    // Scoreboard: independently tracks accepted FIFO operations
    always @(posedge clk) begin
        cycles = cycles + 1;

        if (rst) begin
            model_head = 0;
            model_tail = 0;
            model_count = 0;
        end
        else begin
            accepted_write = wr_en && !full;
            accepted_read  = rd_en && !empty;

            if (wr_en && full)
                blocked_write_hits = blocked_write_hits + 1;

            if (rd_en && empty)
                blocked_read_hits = blocked_read_hits + 1;

            if (wr_en && rd_en)
                simultaneous_request_hits =
                    simultaneous_request_hits + 1;

            if (accepted_read && model_head == DEPTH-1)
                rd_wrap_hits = rd_wrap_hits + 1;

            if (accepted_write && model_tail == DEPTH-1)
                wr_wrap_hits = wr_wrap_hits + 1;

            // Save the oldest item before processing a write.
            if (accepted_read) begin
                expected_data = model_mem[model_head];
                model_head = (model_head + 1) % DEPTH;
                model_count = model_count - 1;
            end

            if (accepted_write) begin
                model_mem[model_tail] = din;
                model_tail = (model_tail + 1) % DEPTH;
                model_count = model_count + 1;
            end
        end

        // Allow the DUT's nonblocking assignments to settle.
        #1;

        occupancy_hits[model_count] = occupancy_hits[model_count] + 1;

        if (full !== (model_count == DEPTH)) begin
            $display("ERROR cycle %0d: full=%b, expected=%b",
                     cycles, full, (model_count == DEPTH));
            errors = errors + 1;
        end

        if (empty !== (model_count == 0)) begin
            $display("ERROR cycle %0d: empty=%b, expected=%b",
                     cycles, empty, (model_count == 0));
            errors = errors + 1;
        end

        if (!rst && accepted_read) begin
            read_checks = read_checks + 1;

            if (dout !== expected_data) begin
                $display(
                    "ERROR cycle %0d: expected dout=%0d, got dout=%0d",
                    cycles, expected_data, dout
                );
                errors = errors + 1;
            end
        end
    end

    initial begin
        $dumpfile("fifo_sv.vcd");
        $dumpvars(0, tb_sync_fifo_sv);

        for (i = 0; i <= DEPTH; i = i + 1)
            occupancy_hits[i] = 0;

        clk = 0;
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        din = 0;

        // Reset the FIFO.
        repeat (2) @(negedge clk);
        rst = 0;

        // Directed test: fill the FIFO.
        @(negedge clk);
        wr_en = 1;
        din = 10;

        @(negedge clk);
        din = 20;

        @(negedge clk);
        din = 30;

        @(negedge clk);
        din = 40;

        // Attempt a write while full.
        @(negedge clk);
        din = 50;

        // Read all four items and check ordering.
        rd_en = 1;
        wr_en = 0;

        repeat (4) @(negedge clk);

        // Attempt a read while empty.
        @(negedge clk);
        rd_en = 1;
        wr_en = 0;

        // Randomized stimulus: reproducible seed.
        // Run 500 cycles with random read/write requests and data.
        @(negedge clk);
        rd_en = 0;
        wr_en = 0;
        din = 0;

        // Seed the simulator's random generator.
        // The test remains reproducible for the same simulator.
        repeat (500) begin
            @(negedge clk);
            wr_en = $urandom_range(0, 1);
            rd_en = $urandom_range(0, 1);
            din = $urandom_range(0, 255);
        end

        // Stop writing and drain all remaining entries.
        @(negedge clk);
        wr_en = 0;
        rd_en = 1;

        while (!empty)
            @(negedge clk);

        // Leave controls inactive and finish cleanly.
        wr_en = 0;
        rd_en = 0;
        @(negedge clk);

        if (errors == 0) begin
            $display("----------------------------------");
            $display("PASS: All scoreboard checks passed");
            $display("Clock cycles: %0d", cycles);
            $display("Read data checks: %0d", read_checks);
            $display("Assertion checks: %0d", assertion_checks);
            $display("Errors: %0d", errors);
            $display("Functional coverage counters:");
            for (i = 0; i <= DEPTH; i = i + 1)
                $display("  Occupancy %0d: %0d hits",
                         i, occupancy_hits[i]);
            $display("  Blocked writes: %0d", blocked_write_hits);
            $display("  Blocked reads: %0d", blocked_read_hits);
            $display("  Simultaneous requests: %0d",
                     simultaneous_request_hits);
            $display("  Write pointer wraps: %0d", wr_wrap_hits);
            $display("  Read pointer wraps: %0d", rd_wrap_hits);
            $display("----------------------------------");
        end
        else begin
            $display("----------------------------------");
            $display("FAIL: Scoreboard detected %0d errors", errors);
            $display("Clock cycles: %0d", cycles);
            $display("Read data checks: %0d", read_checks);
            $display("----------------------------------");
            $fatal(1, "FIFO verification failed");
        end

        $finish;
    end

endmodule


`timescale 1ns/1ps

module tb_sync_fifo;

    reg clk, rst, wr_en, rd_en;
    reg [7:0] din;

    wire [7:0] dout;
    wire full, empty;

    sync_fifo uut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty)
    );

    // 10 ns clock period
    always #5 clk = ~clk;

   
       
initial begin
    $dumpfile("fifo.vcd");
    $dumpvars(0, tb_sync_fifo);

    clk = 0;
    rst = 1;
    wr_en = 0;
    rd_en = 0;
    din = 0;

    #12;
    rst = 0;

    // Write four values
    @(negedge clk);
    wr_en = 1;
    din = 10;

    @(negedge clk);
    din = 20;

    @(negedge clk);
    din = 30;

    @(negedge clk);
    din = 40;

    @(negedge clk);
    wr_en = 0;
    #1;
    $display("After 4 writes: full=%b, empty=%b", full, empty);

    // Attempt a fifth write
    wr_en = 1;
    din = 50;
    @(negedge clk);
    wr_en = 0;
    #1;
    $display("After extra write: full=%b, empty=%b", full, empty);

    // Read four values
    rd_en = 1;
    repeat (4) begin
        @(negedge clk);
        $display("Read: dout=%0d", dout);
    end

    rd_en = 0;
    #1;
    $display("After 4 reads: full=%b, empty=%b", full, empty);

    // Attempt a read while empty
    rd_en = 1;
    @(negedge clk);
    rd_en = 0;
    #1;
    $display("After empty read: full=%b, empty=%b", full, empty);

    $finish;
end


endmodule

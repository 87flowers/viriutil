pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // skip program name
    _ = args.skip();
    const src_path = args.next() orelse @panic("no src file specified");
    const dest_path = args.next() orelse @panic("no dest file specified");
    if (args.next() != null) @panic("too many arguments");

    var src_file = try std.fs.cwd().openFile(src_path, .{ .mode = .read_only });
    defer src_file.close();

    var dest_file = try std.fs.cwd().createFile(dest_path, .{ .exclusive = true });
    defer dest_file.close();

    const reader = src_file.reader();
    const writer = dest_file.writer();

    while (true) {
        var board = reader.readStruct(PackedBoard) catch |err| switch (err) {
            std.fs.File.Reader.NoEofError.EndOfStream => return,
            else => return err,
        };
        if (board.stm == 1) board.eval = invertEval(board.eval);
        try writer.writeStruct(board);

        var stm = ~board.stm;

        while (true) {
            var move = try reader.readStruct(MoveData);
            if (stm == 1) move.score = invertEval(move.score);
            stm = ~stm;
            try writer.writeStruct(move);
            if (move.move == 0 and move.score == 0) break;
        }
    }
}

fn invertEval(x: i16) i16 {
    if (x == 0x8000) return -0x7FFF;
    return -x;
}

const PackedBoard = packed struct {
    occupancy: u64,
    pieces: u128,
    ep_square: u7,
    stm: u1,
    halfmove_clock: u8,
    fullmove_number: u16,
    eval: i16,
    wdl: u8,
    extra: u8,
};

const MoveData = packed struct {
    move: u16,
    score: i16,
};

const std = @import("std");

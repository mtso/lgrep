//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

pub fn main() !void {
    // {
    //     const haystack = "hello world, my name is SUSHI and others";
    //     const needle = "SUSHIS";
    //     const li = std.mem.lastIndexOf(u8, haystack, needle);
    //     std.debug.print("index={?}\n", .{li});
    //     if (true) {
    //         return;
    //     }
    // }

    const needle = "SUSHI";

    const allocator = std.heap.page_allocator;
    var stdin = std.io.getStdIn().reader();
    var stdout = std.io.getStdOut().writer();

    var line_buffer = std.ArrayList(u8).init(allocator);
    defer line_buffer.deinit();

    // var line_cache = std.ArrayList([]u8).init(allocator);
    // defer line_cache.deinit();

    var line: i32 = 0;
    while (true) {
        line_buffer.clearRetainingCapacity();
        const read_result = try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 4096 * 16);
        if (read_result == null) break;
        // defer allocator.free(read_result.?);

        line_cache.insert(read_result.?);

        if (read_result == null) {
            continue;
        }

        const found = std.mem.lastIndexOf(u8, read_result.?, needle);

        if (found == null) {
            continue;
        }

        try stdout.print("{d} ", .{line});
        line += 1;
        try stdout.writeAll(read_result.?);
        try stdout.writeAll("\n");
    }

    // for (line_cache.items) |l| {
    //     try stdout.writeAll(l);
    //     try stdout.writeAll("\n");
    //     allocator.free(l);
    // }
}

const std = @import("std");

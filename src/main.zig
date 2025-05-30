//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

fn match(haystack: [][]u8, needle: []const u8) bool {
    for (haystack) |line| {
        if (std.mem.indexOf(u8, line, needle) != null) {
            return true;
        }
    }
    return false;
}

fn closing(start: []const u8, end: []const u8) bool {
    if (start.len == 0 or end.len == 0) {
        return false;
    }
    const opening = start[start.len - 1];
    return switch (end[0]) {
        '}' => opening == '{',
        ']' => opening == '[',
        ')' => opening == '(',
        else => false,
    };
}

pub fn main() !void {
    const needle = "SUSHI";

    const allocator = std.heap.page_allocator;
    var stdin = std.io.getStdIn().reader();
    var stdout = std.io.getStdOut().writer();

    var line_buffer = std.ArrayList(u8).init(allocator);
    defer line_buffer.deinit();

    var line_cache = std.ArrayList([]u8).init(allocator);
    defer line_cache.deinit();

    var line: usize = 0;

    var check_index: usize = 0;

    while (true) {
        // std.debug.print("input: {?}\n", .{line});
        line += 1;
        line_buffer.clearRetainingCapacity();
        const read_result = try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 4096 * 16);
        if (read_result == null) break;

        if (read_result.?.len > 0) {
            if (line_cache.items.len == 0) {
                try line_cache.append(read_result.?);
            } else if (read_result.?[0] == ' ') {
                try line_cache.append(read_result.?);
            } else {
                const check_line = line_cache.items[check_index];
                if (closing(check_line, read_result.?)) {
                    try line_cache.append(read_result.?);
                    check_index = line_cache.items.len - 1;
                } else {
                    // assume not the same, reset

                    if (match(line_cache.items, needle)) {
                        for (line_cache.items) |l| {
                            try stdout.writeAll(l);
                            try stdout.writeAll("\n");
                            allocator.free(l);
                        }
                    } else {
                        for (line_cache.items) |l| {
                            allocator.free(l);
                        }
                    }
                    line_cache.clearRetainingCapacity();
                    check_index = 0;
                    try line_cache.append(read_result.?);
                }
            }
        } else {
            // empty line, skip
            allocator.free(read_result.?);
        }
    }

    if (match(line_cache.items, needle)) {
        for (line_cache.items) |l| {
            try stdout.writeAll(l);
            try stdout.writeAll("\n");
            allocator.free(l);
        }
    } else {
        for (line_cache.items) |l| {
            allocator.free(l);
        }
    }
    line_cache.clearRetainingCapacity();
    check_index = 0;
}

const std = @import("std");

const std = @import("std");

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

fn startsMultiline(line: []const u8) bool {
    // start of error stacktraces
    if (std.mem.indexOf(u8, line, "Error") != null) {
        return true;
    }
    if (std.mem.indexOf(u8, line, "Exception") != null) {
        return true;
    }
    // start of serialized objects
    return switch (line[line.len - 1]) {
        '{', '[', '(' => true,
        else => false,
    };
}

pub fn main() !u8 {
    const allocator = std.heap.page_allocator;
    var stdin = std.io.getStdIn().reader();
    var stdout = std.io.getStdOut().writer();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const needle = if (args.len >= 2) args[1] else {
        try std.io.getStdErr().writeAll("usage: lgrep [pattern]\n");
        return 1;
    };

    var line_cache = std.ArrayList([]u8).init(allocator);
    defer line_cache.deinit();

    var line: usize = 0;

    var check_index: usize = 0;

    while (true) {
        // std.debug.print("input: {?}\n", .{line});
        line += 1;
        const read_result = try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 4096 * 16);
        if (read_result == null) break;

        if (read_result.?.len > 0) {
            if (line_cache.items.len == 0) {
                if (startsMultiline(read_result.?)) {
                    // start of multiline log
                    try line_cache.append(read_result.?);
                } else {
                    // single line log
                    if (std.mem.indexOf(u8, read_result.?, needle) != null) {
                        try stdout.writeAll(read_result.?);
                        try stdout.writeAll("\n");
                        allocator.free(read_result.?);
                    }
                }
            } else if (read_result.?[0] == ' ') {
                if (line_cache.items.len > 0) {
                    // continues multiline log
                    try line_cache.append(read_result.?);
                } else if (startsMultiline(read_result.?)) {
                    // no existing multiline log, but begins a multiline log
                    try line_cache.append(read_result.?);
                } else {
                    // no existing multiline log
                    // single line log
                    if (std.mem.indexOf(u8, read_result.?, needle) != null) {
                        try stdout.writeAll(read_result.?);
                        try stdout.writeAll("\n");
                        allocator.free(read_result.?);
                    }
                }
            } else {
                const check_line = line_cache.items[check_index];
                if (closing(check_line, read_result.?)) {
                    try line_cache.append(read_result.?);
                    check_index = line_cache.items.len - 1;
                } else {
                    // assume the line is a part of a new log, reset
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
                    if (startsMultiline(read_result.?)) {
                        try line_cache.append(read_result.?);
                    } else {
                        // single line log
                        if (std.mem.indexOf(u8, read_result.?, needle) != null) {
                            try stdout.writeAll(read_result.?);
                            try stdout.writeAll("\n");
                            allocator.free(read_result.?);
                        }
                    }
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

    return 0;
}

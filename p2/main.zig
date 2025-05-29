const std = @import("std");
const utils = @import("referenceHav.zig");
const ReferenceHaversine = utils.refenenceHaversineDistance;

const PointPair = utils.PointPair;

const stdout = std.io.getStdOut().writer();

pub fn assert(condition: bool, comptime fmt: []const u8, args: anytype) void {
    if (!condition) {
        std.debug.panic(fmt, args);
    }
}
pub fn main() !void {
    // Allocator for memory management
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("output.json", .{});
    defer file.close();

    const average_file = try std.fs.cwd().openFile("average", .{});
    defer average_file.close();

    const content = try average_file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    const precalc_average = try std.fmt.parseFloat(f64, std.mem.trim(u8, content, &std.ascii.whitespace));

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);
    _ = try file.readAll(buffer);

    // Parse as an array of PointPair
    const parsed = try std.json.parseFromSlice(
        []PointPair, // Changed from PointPair to []PointPair
        allocator,
        buffer,
        .{},
    );
    defer parsed.deinit();

    try stdout.print("Pair count: {d}\n", .{parsed.value.len});

    var sum: f64 = 0;
    for (parsed.value, 0..) |pair, i| {
        // try stdout.print("Pair {d}: x0={d}, y0={d}, x1={d}, y1={d}\n", .{ i, pair.x0, pair.y0, pair.x1, pair.y1 });
        _ = i;
        const val = ReferenceHaversine(pair);
        sum += val;
        // try stdout.print("val {d}\n", .{val});
    }
    const average: f64 = sum / @as(f64, @floatFromInt(parsed.value.len));
    try stdout.print("average : {d} \n", .{average});
    try stdout.print("expected : {d} \n", .{precalc_average});

    std.debug.assert(average == precalc_average);
}

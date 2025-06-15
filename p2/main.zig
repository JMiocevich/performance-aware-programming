const std = @import("std");
const utils = @import("referenceHav.zig");
const ReferenceHaversine = utils.refenenceHaversineDistance;
const timer = @import("profiler.zig");

const PointPair = utils.PointPair;

const stdout = std.io.getStdOut().writer();

pub fn assert(condition: bool, comptime fmt: []const u8, args: anytype) void {
    if (!condition) {
        std.debug.panic(fmt, args);
    }
}
pub fn main() !void {
    const p_start = timer.rtdsc();
    // Allocator for memory management
    const p_setup = timer.rtdsc();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const p_readfile = timer.rtdsc();
    const file = try std.fs.cwd().openFile("output.json", .{});
    defer file.close();

    const average_file = try std.fs.cwd().openFile("average", .{});
    defer average_file.close();

    const content = try average_file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    const precalc_average = try std.fmt.parseFloat(f64, std.mem.trim(u8, content, &std.ascii.whitespace));

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    _ = try file.readAll(buffer);

    const p_parsejson = timer.rtdsc();
    // Parse as an array of PointPair
    const parsed = try std.json.parseFromSlice(
        []PointPair, // Changed from PointPair to []PointPair
        allocator,
        buffer,
        .{},
    );
    defer parsed.deinit();

    try stdout.print("Pair count: {d}\n", .{parsed.value.len});

    const p_calculate = timer.rtdsc();
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

    const p_deallocate = timer.rtdsc();
    allocator.free(buffer);
    const p_end = timer.rtdsc();
    // Calculate and print percentages
    const total_time = @as(f64, @floatFromInt(p_end - p_start));

    try stdout.print("Setup: {d:.2}%\n", .{(@as(f64, @floatFromInt(p_setup - p_start)) / total_time) * 100.0});
    try stdout.print("Read file: {d:.2}%\n", .{(@as(f64, @floatFromInt(p_readfile - p_setup)) / total_time) * 100.0});
    try stdout.print("Parse JSON: {d:.2}%\n", .{(@as(f64, @floatFromInt(p_parsejson - p_readfile)) / total_time) * 100.0});
    try stdout.print("Calculate: {d:.2}%\n", .{(@as(f64, @floatFromInt(p_calculate - p_parsejson)) / total_time) * 100.0});
    try stdout.print("Deallocate: {d:.2}%\n", .{(@as(f64, @floatFromInt(p_deallocate - p_calculate)) / total_time) * 100.0});
    try stdout.print("Cleanup: {d:.2}%\n", .{(@as(f64, @floatFromInt(p_end - p_deallocate)) / total_time) * 100.0});
    try stdout.print("Total time: {d} cycles\n", .{p_end - p_start});
}

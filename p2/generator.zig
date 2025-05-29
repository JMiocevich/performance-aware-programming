const std = @import("std");
const math = std.math;

const PointPair = struct {
    x0: f64,
    y0: f64,
    x1: f64,
    y1: f64,
};

const Data = struct {
    pairs: []PointPair,
};

const Config = struct {
    seed: u64 = undefined,
    method: []const u8 = "uniform",
    count: u64 = undefined,
    generate: ?[]const u8 = null,
    verify: ?[]const u8 = null,
    profile: bool = false,
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var config = Config{
        .count = 100, // Default count if not specified
    };

    // Get random seed if not specified
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--seed") or std.mem.eql(u8, arg, "-s")) {
            i += 1;
            if (i >= args.len) return error.MissingSeedValue;
            config.seed = try std.fmt.parseInt(u64, args[i], 10);
        } else if (std.mem.eql(u8, arg, "--method") or std.mem.eql(u8, arg, "-m")) {
            i += 1;
            if (i >= args.len) return error.MissingMethodValue;
            config.method = args[i];
        } else if (std.mem.eql(u8, arg, "--count") or std.mem.eql(u8, arg, "-c")) {
            i += 1;
            if (i >= args.len) return error.MissingCountValue;
            config.count = try std.fmt.parseInt(u64, args[i], 10);
        } else if (std.mem.eql(u8, arg, "--generate") or std.mem.eql(u8, arg, "-g")) {
            i += 1;
            if (i >= args.len) return error.MissingGenerateValue;
            config.generate = args[i];
        } else if (std.mem.eql(u8, arg, "--verify") or std.mem.eql(u8, arg, "-v")) {
            i += 1;
            if (i >= args.len) return error.MissingVerifyValue;
            config.verify = args[i];
        } else if (std.mem.eql(u8, arg, "--profile") or std.mem.eql(u8, arg, "-p")) {
            config.profile = true;
        } else {
            std.debug.print("Unknown argument: {s}\n", .{arg});
            return error.UnknownArgument;
        }
    }

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = config.seed;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    const rand = prng.random();
    const sum = try generateAndPrintPairs(allocator, config.count, rand);
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Method: {s}\n", .{"method"});
    try stdout.print("Random seed: {d}\n", .{config.seed});
    try stdout.print("Pair count: {d}\n", .{config.count});
    try stdout.print("Expected average: {d:.16}\n", .{sum});
}

fn generateAndPrintPairs(allocator: std.mem.Allocator, number: usize, rand: std.Random) anyerror!f64 {
    var pairs = std.ArrayList(PointPair).init(allocator);
    var distances = std.ArrayList(f64).init(allocator);
    defer pairs.deinit();
    defer distances.deinit();
    var totalDistance: f64 = 0.0;
    for (0..number) |_| {
        const x0 = rand.float(f64);
        const y0 = rand.float(f64);
        const x1 = rand.float(f64);
        const y1 = rand.float(f64);

        const pair = PointPair{
            .x0 = x0,
            .y0 = y0,
            .x1 = x1,
            .y1 = y1,
        };

        const distance = haversineDistance(pair);
        totalDistance += distance;
        try pairs.append(pair);
        try distances.append(distance);
    }

    var string = std.ArrayList(u8).init(allocator);
    defer string.deinit();
    try std.json.stringify(pairs.items, .{}, string.writer());

    const filepath = "output.json";
    // Create or open the file for writing
    const file = try std.fs.cwd().createFile(
        filepath,
        .{ .read = true, .truncate = true },
    );
    defer file.close();

    try file.writeAll(string.items);

    const file2 = try std.fs.cwd().createFile(
        "average",
        .{ .read = true, .truncate = true },
    );
    defer file2.close();

    // for (distances.items) |distance| {
    //     var buf: [64]u8 = undefined;
    //     const str = try std.fmt.bufPrint(&buf, "{d}\n", .{distance});
    //     try file2.writeAll(str);
    // }

    totalDistance = totalDistance / @as(f64, @floatFromInt(number));
    var total_buf: [64]u8 = undefined;
    const total_str = try std.fmt.bufPrint(&total_buf, "{d}\n", .{totalDistance});
    try file2.writeAll(total_str);
    return totalDistance;
}

fn haversineDistance(pair: PointPair) f64 {
    // Convert degrees to radians
    const lat1 = pair.y0 * math.pi / 180.0;
    const lon1 = pair.x0 * math.pi / 180.0;
    const lat2 = pair.y1 * math.pi / 180.0;
    const lon2 = pair.x1 * math.pi / 180.0;
    const EARTH_RADIUS: f64 = 6371.0;
    // Differences in coordinates
    const dLat = lat2 - lat1;
    const dLon = lon2 - lon1;

    // Haversine formula
    const a = math.sin(dLat / 2.0) * math.sin(dLat / 2.0) +
        math.cos(lat1) * math.cos(lat2) *
            math.sin(dLon / 2.0) * math.sin(dLon / 2.0);

    // In Zig, atan2 takes only y and x parameters
    const c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    const distance = EARTH_RADIUS * c;

    return distance;
}

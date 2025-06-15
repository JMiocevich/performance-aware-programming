const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    const msToWait = 10;
    const wait_ns = @as(i128, msToWait) * 1_000_000; // 1 ms = 1 000 000 ns

    const startOs = std.time.nanoTimestamp();
    const startTicks = rtdsc();

    while (std.time.nanoTimestamp() - startOs < wait_ns) {}

    const endOs = std.time.nanoTimestamp();
    const endTicks = rtdsc();

    const cpuElapsed = @as(i128, endTicks - startTicks);
    const osElapsed = @as(i128, endOs - startOs);
    const cpu_freq = @divTrunc(cpuElapsed * get_arm_timer_frequency(), osElapsed);

    std.debug.print("OS Timer: {d} -> {d} = {d} elapsed\n", .{ startOs, endOs, osElapsed });
    std.debug.print("OS Seconds: {d:.4}\n", .{@as(f64, @floatFromInt(osElapsed)) / @as(f64, @floatFromInt(get_arm_timer_frequency()))});

    std.debug.print("CPU Timer: {d} -> {d} = {d} elapsed\n", .{ startTicks, endTicks, cpuElapsed });
    std.debug.print("CPU Freq: {d:.4} (guessed)\n", .{cpu_freq});
}

pub fn rtdsc() u64 {
    return asm volatile ("mrs x0, cntpct_el0"
        : [x0] "={x0}" (-> u64),
        :
        : "x0"
    );
}

pub fn get_arm_timer_frequency() u64 {
    // Reads the CNTFRQ_EL0 register, which holds the frequency
    // of the system counter in Hz.
    return asm volatile ("mrs x0, cntfrq_el0"
        : [x0] "={x0}" (-> u64),
        :
        : "x0"
    );
}

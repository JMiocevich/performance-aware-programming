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
    const cpuFreqHz = @divTrunc(cpuElapsed * get_arm_timer_frequency(), osElapsed);

    std.debug.print("OS elapsed     : {d} ns\n", .{osElapsed});
    std.debug.print("CPU elapsed    : {d} timer-ticks\n", .{cpuElapsed});
    std.debug.print("CPU frequency estimate  : {d} Hz\n", .{cpuFreqHz});
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
// pub fn calibrate_frequency(ms: u64, time_fn: *const fn () u64) f64 {
//     const freq: u64 = query_performance_frequency();
//     const ticks_to_run = ms * (freq / 1000);
//
//     const cpu_start = time_fn();
//     const start = query_performance_counter();
//
//     while (query_performance_counter() -% start < ticks_to_run) {}
//
//     const end = query_performance_counter();
//     const cpu_end = time_fn();
//
//     const cpu_elapsed = cpu_end -% cpu_start;
//     const os_elpased = end -% start;
//
//     const cpu_freq = freq * cpu_elapsed / os_elpased;
//     return @floatFromInt(cpu_freq);
// }

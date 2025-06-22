const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    const msToWait = 10;
    const wait_ns = @as(i128, msToWait) * 1_000_000; // 1 ms = 1 000 000 ns

    const startOs = std.time.nanoTimestamp();
    const startTicks = readTimerCounter();

    while (std.time.nanoTimestamp() - startOs < wait_ns) {}

    const endOs = std.time.nanoTimestamp();
    const endTicks = readTimerCounter();

    const cpuElapsed = @as(i128, endTicks - startTicks);
    const osElapsed = @as(i128, endOs - startOs);

    switch (builtin.cpu.arch) {
        .aarch64 => {
            const cpuFreqHz = @divTrunc(cpuElapsed * getTimerFrequency(), osElapsed);
            std.debug.print("OS elapsed     : {d} ns\n", .{osElapsed});
            std.debug.print("CPU elapsed    : {d} timer-ticks\n", .{cpuElapsed});
            std.debug.print("CPU frequency estimate  : {d} Hz\n", .{cpuFreqHz});
        },
        .x86_64 => {
            // For x86, we estimate TSC frequency directly from the timing
            const tscFreqHz = @divTrunc(cpuElapsed * 1_000_000_000, osElapsed);
            std.debug.print("OS elapsed     : {d} ns\n", .{osElapsed});
            std.debug.print("TSC elapsed    : {d} cycles\n", .{cpuElapsed});
            std.debug.print("TSC frequency estimate   : {d} Hz\n", .{tscFreqHz});
        },
        else => {
            std.debug.print("Architecture not supported\n");
            return;
        },
    }
}

pub fn readTimerCounter() u64 {
    return switch (builtin.cpu.arch) {
        .aarch64 => asm volatile ("mrs x0, cntpct_el0"
            : [x0] "={x0}" (-> u64),
            :
            : "x0"
        ),
        .x86_64 => {
            var low: u32 = undefined;
            var high: u32 = undefined;
            asm volatile ("rdtsc"
                : [low] "={eax}" (low),
                  [high] "={edx}" (high),
                :
                : "eax", "edx"
            );
            return (@as(u64, high) << 32) | low;
        },
        else => @compileError("Architecture not supported"),
    };
}

pub fn getTimerFrequency() u64 {
    return switch (builtin.cpu.arch) {
        .aarch64 => asm volatile ("mrs x0, cntfrq_el0"
            : [x0] "={x0}" (-> u64),
            :
            : "x0"
        ),
        .x86_64 => @compileError("x86_64 TSC frequency not available via register"),
        else => @compileError("Architecture not supported"),
    };
}

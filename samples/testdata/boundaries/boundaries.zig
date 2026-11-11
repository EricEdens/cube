const std = @import("std");
const stg = @import("stg");

pub fn main() void {
    const sizes = [_]u64{ 0, 1, 63, 64, 65, 511, 512, 513, 4095, 4096, 4097, 4160, 8191, 8192, 8193 };
    const root = stg.stg("boundaries", stg.RW, true);
    var name: [32]u8 = undefined;
    var pat: [64]u8 = undefined;

    for (sizes) |n| {
        const nm = std.fmt.bufPrint(&name, "{d}", .{n}) catch unreachable;
        stg.mk(root, nm, std.fmt.bufPrint(&pat, "{s}@0\n", .{nm}) catch unreachable, n);
    }
    root.release();
    stg.dump("boundaries");
}

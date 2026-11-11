const std = @import("std");
const stg = @import("stg");

fn rr(s: []const *stg.IStream, pat: []const [32]u8, sizes: []const u64, n: usize, chunk: u64) void {
    var off: u64 = 0;
    var more = true;

    while (more) : (off += chunk) {
        more = false;
        for (0..n) |i| {
            if (off >= sizes[i])
                continue;
            const len = @min(sizes[i] - off, chunk);
            stg.put(s[i], std.mem.sliceTo(&pat[i], 0), off, len);
            more = true;
        }
    }
}

pub fn main() void {
    const big = [_]u64{ 8 << 20, 16 << 20, 40 << 20 };
    var small: [12]u64 = undefined;
    const root = stg.stg("interleaved", stg.RW, true);
    var bs: [3]*stg.IStream = undefined;
    var ms: [12]*stg.IStream = undefined;
    var bp: [3][32]u8 = @splat(@splat(0));
    var mp: [12][32]u8 = @splat(@splat(0));
    var name: [32]u8 = undefined;

    for (0..3) |i| {
        const nm = std.fmt.bufPrint(&name, "b{d}", .{big[i] >> 20}) catch unreachable;
        _ = std.fmt.bufPrint(&bp[i], "{s}@0\n", .{nm}) catch unreachable;
        bs[i] = stg.str(root, nm, stg.RW, true);
    }
    for (0..12) |i| {
        const nm = std.fmt.bufPrint(&name, "m{d:0>2}", .{i}) catch unreachable;
        _ = std.fmt.bufPrint(&mp[i], "{s}@0\n", .{nm}) catch unreachable;
        small[i] = 64 + i * 333;
        ms[i] = stg.str(root, nm, stg.RW, true);
    }
    rr(&ms, &mp, &small, 12, 64);
    rr(&bs, &bp, &big, 3, 4096);
    for (0..3) |i|
        bs[i].release();
    for (0..12) |i|
        ms[i].release();
    root.release();
    stg.dump("interleaved");
}

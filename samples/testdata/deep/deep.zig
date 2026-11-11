const std = @import("std");
const stg = @import("stg");

pub fn main() void {
    const longs = [_][]const u8{
        "0123456789012345678901234567890", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcde",
        "a b c d e f g h i j k l m n o p", "_______________________________",
    };
    const root = stg.stg("deep", stg.RW, true);
    var chain: [41]*stg.IStorage = undefined;
    var name: [32]u8 = undefined;
    var pat: [512]u8 = undefined;
    var path: [512]u8 = undefined;
    var len: usize = 0;
    var n: usize = 0;

    var p = root;
    for (0..32) |i| {
        stg.mk(p, "xx", std.fmt.bufPrint(&pat, "{s}xx@0\n", .{path[0..len]}) catch unreachable, 100 + i * 61);
        const nm = std.fmt.bufPrint(&name, "level {d:0>2}", .{i}) catch unreachable;
        stg.mk(p, nm, std.fmt.bufPrint(&pat, "{s}{s}@0\n", .{ path[0..len], nm }) catch unreachable, i * 4096 / 31);
        p = stg.dir(p, "x", stg.RW, true);
        chain[n] = p;
        n += 1;
        len += (std.fmt.bufPrint(path[len..], "x/", .{}) catch unreachable).len;
    }
    stg.mk(p, "x", "bottom@0\n", 5000);
    p = root;
    len = 0;
    for (0..8) |i| {
        p = stg.dir(p, longs[i % 4], stg.RW, true);
        chain[n] = p;
        n += 1;
        len += (std.fmt.bufPrint(path[len..], "{s}/", .{longs[i % 4]}) catch unreachable).len;
        const pt = std.fmt.bufPrint(&pat, "{s}x@0\n", .{path[0..len]}) catch unreachable;
        stg.mk(p, "x", pt[0..@min(pt.len, 255)], 200 + i * 1000);
    }
    while (n != 0) {
        n -= 1;
        chain[n].release();
    }
    root.release();
    stg.dump("deep");
}

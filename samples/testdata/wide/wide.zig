const std = @import("std");
const stg = @import("stg");

const cs = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ #$%&'()+,-.;=@[]^_`{}~";

pub fn main() void {
    const named = [_][]const u8{
        "a",
        "B",
        "c",
        "[",
        "_",
        "`",
        "{",
        "~",
        "@",
        "ab",
        "AC",
        "aD",
        "Z_",
        "z`",
        "\x05SummaryInformation",
        "\x05DocumentSummaryInformation",
        "\x01CompObj",
        "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz",
        "Zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzy",
    };
    const k = cs.len;
    const root = stg.stg("wide", stg.RW, true);
    var name: [32]u8 = undefined;
    var pat: [64]u8 = undefined;

    for (named, 0..) |nm, i|
        stg.mk(root, nm, std.fmt.bufPrint(&pat, "{s}@0\n", .{nm}) catch unreachable, i * 97 % 300);
    for (0..1000) |i| {
        const len = 3 + i * 7 % 29;
        name[0] = cs[i / k];
        name[1] = cs[i % k];
        for (2..len) |j| {
            name[j] = cs[(i + j * 13) % k];
            if (name[j] >= 'A' and name[j] <= 'Z' and (i >> @intCast(j) & 1) != 0)
                name[j] += 'a' - 'A';
        }
        const p = std.fmt.bufPrint(&pat, "{s}@0\n", .{name[0..len]}) catch unreachable;
        stg.mk(root, name[0..len], p, if (i % 100 != 0) i * 37 % 300 else 5000 + i);
    }
    root.release();
    stg.dump("wide");
}

const std = @import("std");
const stg = @import("stg");

fn size(s: *stg.IStream) u64 {
    var st: stg.STATSTG = undefined;

    stg.CK(s.stat(&st, stg.STATFLAG_NONAME), @src());
    return st.cbSize;
}

pub fn main() void {
    var root = stg.stg("reopen-cycles", stg.RW, true);
    var s: *stg.IStream = undefined;
    var pat: [64]u8 = undefined;
    var buf: [4096]u8 = undefined;
    var n: stg.ULONG = undefined;

    s = stg.str(root, "mid", stg.RW, true);
    stg.put(s, "mid@0\n", 0, 65536);
    s.release();
    stg.mk(root, "sparse", "sparse@0\n", 100);
    root.release();

    for (0..20) |i| {
        root = stg.stg("reopen-cycles", stg.RO, false);
        if (i != 0) {
            s = stg.str(root, "log", stg.RO, false);
            while (s.read(&buf, &n) == stg.S_OK and n != 0) {}
            s.release();
        }
        root.release();

        root = stg.stg("reopen-cycles", stg.RW, false);
        s = stg.str(root, "log", stg.RW, i == 0);
        stg.put(s, "log@0\n", size(s), 3000);
        s.release();

        s = stg.str(root, "small", stg.RW, i == 0);
        stg.put(s, "small@0\n", size(s), 100);
        s.release();

        s = stg.str(root, "mid", stg.RW, false);
        const p = std.fmt.bufPrint(&pat, "mid@{d}\n", .{i + 1}) catch unreachable;
        stg.put(s, p, i * 3001, 1000);
        s.release();

        if (i == 10) {
            s = stg.str(root, "sparse", stg.RW, false);
            stg.put(s, "sparse@1\n", 20000, 100);
            s.release();
        }
        root.release();
    }
    stg.dump("reopen-cycles");
}

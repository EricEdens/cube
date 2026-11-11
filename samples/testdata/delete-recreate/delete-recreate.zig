const std = @import("std");
const stg = @import("stg");

pub fn main() void {
    const sizes = [_]u64{ 10, 100, 5000, 70000, 0, 3000, 4096, 200000, 64, 9000 };
    var root = stg.stg("delete-recreate", stg.RW, true);
    var p: *stg.IStorage = undefined;
    var name: [32]u8 = undefined;
    var pat: [64]u8 = undefined;

    for (sizes, 0..) |n, i| {
        const nm = std.fmt.bufPrint(&name, "{c}", .{'a' + @as(u8, @intCast(i))}) catch unreachable;
        stg.mk(root, nm, std.fmt.bufPrint(&pat, "{s}@0\n", .{nm}) catch unreachable, n);
    }
    p = stg.dir(root, "dir", stg.RW, true);
    stg.mk(p, "one", "dir/one@0\n", 300);
    stg.mk(p, "two", "dir/two@0\n", 30000);
    p.release();
    stg.mk(root, "flip", "flip@0\n", 6000);
    root.release();

    root = stg.stg("delete-recreate", stg.RW, false);
    stg.rm(root, "b");
    stg.rm(root, "d");
    stg.rm(root, "f");
    stg.rm(root, "h");
    stg.rm(root, "dir");
    stg.rm(root, "flip");
    root.release();

    root = stg.stg("delete-recreate", stg.RW, false);
    stg.mk(root, "b", "b@1\n", 50000);
    stg.mk(root, "d", "d@1\n", 1000);
    stg.mk(root, "f", "f@1\n", 0);
    stg.mk(root, "dir", "dir@1\n", 12345);
    p = stg.dir(root, "flip", stg.RW, true);
    stg.mk(p, "inside", "flip/inside@1\n", 777);
    p.release();
    for (0..50) |i| {
        const pt = std.fmt.bufPrint(&pat, "churn@{d}\n", .{i}) catch unreachable;
        stg.mk(root, "churn", pt, if (i & 1 != 0) 100 + i else 5000 + i * 100);
        if (i != 49)
            stg.rm(root, "churn");
    }
    stg.rm(root, "a");
    stg.mk(root, "a", "a@1\n", 10);
    root.release();
    stg.dump("delete-recreate");
}

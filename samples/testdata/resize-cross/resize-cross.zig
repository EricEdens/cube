const stg = @import("stg");

pub fn main() void {
    var root = stg.stg("resize-cross", stg.RW, true);
    var s: *stg.IStream = undefined;

    stg.mk(root, "grow-set", "grow-set@0\n", 1000);
    stg.mk(root, "grow-write", "grow-write@0\n", 4000);
    stg.mk(root, "shrink", "shrink@0\n", 1 << 20);
    stg.mk(root, "to-4096", "to-4096@0\n", 10000);
    stg.mk(root, "to-4095", "to-4095@0\n", 10000);
    stg.mk(root, "bounce", "bounce@0\n", 100);
    stg.mk(root, "neighbor", "neighbor@0\n", 2000);
    root.release();

    root = stg.stg("resize-cross", stg.RW, false);
    s = stg.str(root, "grow-set", stg.RW, false);
    stg.resize(s, 20000);
    stg.put(s, "grow-set@1\n", 1000, 500);
    s.release();
    s = stg.str(root, "grow-write", stg.RW, false);
    stg.put(s, "grow-write@0\n", 4000, 200);
    s.release();
    s = stg.str(root, "shrink", stg.RW, false);
    stg.resize(s, 100);
    s.release();
    s = stg.str(root, "to-4096", stg.RW, false);
    stg.resize(s, 4096);
    s.release();
    s = stg.str(root, "to-4095", stg.RW, false);
    stg.resize(s, 4095);
    s.release();
    root.release();

    root = stg.stg("resize-cross", stg.RW, false);
    s = stg.str(root, "bounce", stg.RW, false);
    stg.put(s, "bounce@0\n", 100, 9900);
    stg.resize(s, 50);
    stg.put(s, "bounce@1\n", 50, 4046);
    stg.resize(s, 8192);
    s.release();
    s = stg.str(root, "to-4095", stg.RW, false);
    stg.resize(s, 4096);
    stg.put(s, "to-4095@1\n", 4095, 1);
    s.release();
    s = stg.str(root, "shrink", stg.RW, false);
    stg.resize(s, 0);
    stg.put(s, "shrink@1\n", 0, 4097);
    s.release();
    root.release();
    stg.dump("resize-cross");
}

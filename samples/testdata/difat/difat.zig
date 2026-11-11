const stg = @import("stg");

pub fn main() void {
    const root = stg.stg("difat", stg.RW, true);

    stg.mk(root, "tiny", "tiny@0\n", 10);
    stg.mk(root, "big", "big@0\n", 24 << 20);
    stg.mk(root, "after", "after@0\n", 3000);
    root.release();
    stg.dump("difat");
}

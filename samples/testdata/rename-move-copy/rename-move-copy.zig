const stg = @import("stg");

pub fn main() void {
    const root = stg.stg("rename-move-copy", stg.RW, true);
    var src: *stg.IStorage = undefined;
    var dst: *stg.IStorage = undefined;
    var p: *stg.IStorage = undefined;

    src = stg.dir(root, "src", stg.RW, true);
    stg.mk(src, "s1", "src/s1@0\n", 100);
    stg.mk(src, "s2", "src/s2@0\n", 5000);
    stg.mk(src, "s3", "src/s3@0\n", 300);
    stg.mk(src, "s4", "src/s4@0\n", 7000);
    stg.mk(src, "s5", "src/s5@0\n", 50);
    p = stg.dir(src, "inner", stg.RW, true);
    stg.mk(p, "i1", "src/inner/i1@0\n", 200);
    stg.mk(p, "i2", "src/inner/i2@0\n", 9000);
    p.release();

    stg.CK(src.renameElement(stg.w("s1"), stg.w("renamed")), @src());
    stg.CK(src.renameElement(stg.w("s2"), stg.w("tmp")), @src());
    stg.CK(src.renameElement(stg.w("tmp"), stg.w("S2")), @src());
    dst = stg.dir(root, "dst", stg.RW, true);
    stg.CK(src.moveElementTo(stg.w("s3"), dst, stg.w("s3moved"), stg.STGMOVE_MOVE), @src());
    stg.CK(src.moveElementTo(stg.w("s4"), dst, stg.w("s4copy"), stg.STGMOVE_COPY), @src());
    stg.CK(src.moveElementTo(stg.w("inner"), dst, stg.w("inner"), stg.STGMOVE_COPY), @src());
    p = stg.dir(root, "copy", stg.RW, true);
    stg.CK(src.copyTo(p), @src());
    p.release();
    dst.release();
    src.release();

    stg.rm(root, "src");
    stg.CK(root.renameElement(stg.w("copy"), stg.w("src")), @src());
    stg.CK(root.renameElement(stg.w("dst"), stg.w("tmp")), @src());
    stg.CK(root.renameElement(stg.w("tmp"), stg.w("DST")), @src());
    src = stg.dir(root, "src", stg.RW, false);
    stg.CK(src.renameElement(stg.w("renamed"), stg.w("s1")), @src());
    stg.rm(src, "s5");
    stg.mk(src, "s5", "src/s5@1\n", 6000);
    src.release();
    root.release();
    stg.dump("rename-move-copy");
}

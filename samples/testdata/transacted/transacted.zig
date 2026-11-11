const stg = @import("stg");

const TX = stg.RW | stg.STGM_TRANSACTED;

pub fn main() void {
    var root = stg.stg("transacted", TX, true);
    var p: *stg.IStorage = undefined;
    var s: *stg.IStream = undefined;

    stg.mk(root, "kept", "kept@0\n", 10000);
    stg.CK(root.commit(stg.STGC_DEFAULT), @src());
    stg.mk(root, "reverted", "reverted@0\n", 5000);
    s = stg.str(root, "kept", stg.RW, false);
    stg.put(s, "kept@1\n", 10000, 5000);
    s.release();
    stg.CK(root.revert(), @src());

    p = stg.dir(root, "sub", TX, true);
    stg.mk(p, "a", "sub/a@0\n", 300);
    stg.CK(p.commit(stg.STGC_DEFAULT), @src());
    stg.mk(p, "b", "sub/b@0\n", 6000);
    p.release();
    p = stg.dir(root, "sub2", TX, true);
    stg.mk(p, "c", "sub2/c@0\n", 40000);
    stg.CK(p.commit(stg.STGC_DEFAULT), @src());
    p.release();
    stg.CK(root.commit(stg.STGC_DEFAULT), @src());

    p = stg.dir(root, "sub", TX, false);
    stg.mk(p, "d", "sub/d@0\n", 700);
    stg.CK(p.commit(stg.STGC_DEFAULT), @src());
    p.release();
    stg.CK(root.revert(), @src());
    root.release();

    root = stg.stg("transacted", TX, false);
    stg.rm(root, "kept");
    stg.mk(root, "kept", "kept@2\n", 20000);
    p = stg.dir(root, "sub2", stg.RW, false);
    stg.rm(p, "c");
    stg.mk(p, "c", "sub2/c@1\n", 50);
    p.release();
    stg.CK(root.commit(stg.STGC_DEFAULT), @src());
    stg.mk(root, "ghost", "ghost@0\n", 9000);
    root.release();
    stg.dump("transacted");
}

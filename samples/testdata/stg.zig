const std = @import("std");

pub const HRESULT = i32;
pub const DWORD = u32;
pub const ULONG = u32;
pub const WCHAR = u16;
pub const FILETIME = extern struct { lo: DWORD, hi: DWORD };
pub const GUID = std.os.windows.GUID;

pub const S_OK: HRESULT = 0;
pub const E_FAIL: HRESULT = @bitCast(@as(u32, 0x80004005));
pub const E_INVALIDARG: HRESULT = @bitCast(@as(u32, 0x80070057));
pub const E_UNEXPECTED: HRESULT = @bitCast(@as(u32, 0x8000ffff));
pub const STG_E_WRITEFAULT: HRESULT = @bitCast(@as(u32, 0x8003001d));

pub const STGM_READ: DWORD = 0x0;
pub const STGM_WRITE: DWORD = 0x1;
pub const STGM_READWRITE: DWORD = 0x2;
pub const STGM_SHARE_EXCLUSIVE: DWORD = 0x10;
pub const STGM_CREATE: DWORD = 0x1000;
pub const STGM_TRANSACTED: DWORD = 0x10000;
pub const STGC_DEFAULT: DWORD = 0;
pub const STGMOVE_MOVE: DWORD = 0;
pub const STGMOVE_COPY: DWORD = 1;
pub const STGTY_STORAGE: DWORD = 1;
pub const STGTY_STREAM: DWORD = 2;
pub const STATFLAG_DEFAULT: DWORD = 0;
pub const STATFLAG_NONAME: DWORD = 1;
pub const STREAM_SEEK_SET: DWORD = 0;

pub const RW = STGM_READWRITE | STGM_SHARE_EXCLUSIVE;
pub const RO = STGM_READ | STGM_SHARE_EXCLUSIVE;

pub const STATSTG = extern struct {
    pwcsName: ?[*:0]WCHAR,
    type: DWORD,
    cbSize: u64,
    mtime: FILETIME,
    ctime: FILETIME,
    atime: FILETIME,
    grfMode: DWORD,
    grfLocksSupported: DWORD,
    clsid: GUID,
    grfStateBits: DWORD,
    reserved: DWORD,
};

const Name = [*:0]const WCHAR;
const Fn = *const anyopaque;

pub const IStream = extern struct {
    vt: *const extern struct {
        QueryInterface: Fn,
        AddRef: Fn,
        Release: *const fn (*IStream) callconv(.winapi) ULONG,
        Read: *const fn (*IStream, *anyopaque, ULONG, ?*ULONG) callconv(.winapi) HRESULT,
        Write: *const fn (*IStream, *const anyopaque, ULONG, ?*ULONG) callconv(.winapi) HRESULT,
        Seek: *const fn (*IStream, i64, DWORD, ?*u64) callconv(.winapi) HRESULT,
        SetSize: *const fn (*IStream, u64) callconv(.winapi) HRESULT,
        CopyTo: Fn,
        Commit: Fn,
        Revert: Fn,
        LockRegion: Fn,
        UnlockRegion: Fn,
        Stat: *const fn (*IStream, *STATSTG, DWORD) callconv(.winapi) HRESULT,
        Clone: Fn,
    },

    pub fn release(s: *IStream) void {
        _ = s.vt.Release(s);
    }
    pub fn read(s: *IStream, b: []u8, n: *ULONG) HRESULT {
        return s.vt.Read(s, b.ptr, @intCast(b.len), n);
    }
    pub fn write(s: *IStream, b: []const u8, n: *ULONG) HRESULT {
        return s.vt.Write(s, b.ptr, @intCast(b.len), n);
    }
    pub fn seek(s: *IStream, off: i64, origin: DWORD) HRESULT {
        return s.vt.Seek(s, off, origin, null);
    }
    pub fn setSize(s: *IStream, n: u64) HRESULT {
        return s.vt.SetSize(s, n);
    }
    pub fn stat(s: *IStream, st: *STATSTG, flag: DWORD) HRESULT {
        return s.vt.Stat(s, st, flag);
    }
};

pub const IEnumSTATSTG = extern struct {
    vt: *const extern struct {
        QueryInterface: Fn,
        AddRef: Fn,
        Release: *const fn (*IEnumSTATSTG) callconv(.winapi) ULONG,
        Next: *const fn (*IEnumSTATSTG, ULONG, *STATSTG, ?*ULONG) callconv(.winapi) HRESULT,
        Skip: Fn,
        Reset: Fn,
        Clone: Fn,
    },

    pub fn release(e: *IEnumSTATSTG) void {
        _ = e.vt.Release(e);
    }
    pub fn next(e: *IEnumSTATSTG, st: *STATSTG) HRESULT {
        return e.vt.Next(e, 1, st, null);
    }
};

pub const IStorage = extern struct {
    vt: *const extern struct {
        QueryInterface: Fn,
        AddRef: Fn,
        Release: *const fn (*IStorage) callconv(.winapi) ULONG,
        CreateStream: *const fn (*IStorage, Name, DWORD, DWORD, DWORD, **IStream) callconv(.winapi) HRESULT,
        OpenStream: *const fn (*IStorage, Name, ?*anyopaque, DWORD, DWORD, **IStream) callconv(.winapi) HRESULT,
        CreateStorage: *const fn (*IStorage, Name, DWORD, DWORD, DWORD, **IStorage) callconv(.winapi) HRESULT,
        OpenStorage: *const fn (*IStorage, Name, ?*IStorage, DWORD, ?*anyopaque, DWORD, **IStorage) callconv(.winapi) HRESULT,
        CopyTo: *const fn (*IStorage, DWORD, ?*const GUID, ?*anyopaque, *IStorage) callconv(.winapi) HRESULT,
        MoveElementTo: *const fn (*IStorage, Name, *IStorage, Name, DWORD) callconv(.winapi) HRESULT,
        Commit: *const fn (*IStorage, DWORD) callconv(.winapi) HRESULT,
        Revert: *const fn (*IStorage) callconv(.winapi) HRESULT,
        EnumElements: *const fn (*IStorage, DWORD, ?*anyopaque, DWORD, **IEnumSTATSTG) callconv(.winapi) HRESULT,
        DestroyElement: *const fn (*IStorage, Name) callconv(.winapi) HRESULT,
        RenameElement: *const fn (*IStorage, Name, Name) callconv(.winapi) HRESULT,
        SetElementTimes: Fn,
        SetClass: Fn,
        SetStateBits: Fn,
        Stat: *const fn (*IStorage, *STATSTG, DWORD) callconv(.winapi) HRESULT,
    },

    pub fn release(p: *IStorage) void {
        _ = p.vt.Release(p);
    }
    pub fn copyTo(p: *IStorage, dst: *IStorage) HRESULT {
        return p.vt.CopyTo(p, 0, null, null, dst);
    }
    pub fn moveElementTo(p: *IStorage, name: Name, dst: *IStorage, new: Name, flags: DWORD) HRESULT {
        return p.vt.MoveElementTo(p, name, dst, new, flags);
    }
    pub fn commit(p: *IStorage, flags: DWORD) HRESULT {
        return p.vt.Commit(p, flags);
    }
    pub fn revert(p: *IStorage) HRESULT {
        return p.vt.Revert(p);
    }
    pub fn renameElement(p: *IStorage, old: Name, new: Name) HRESULT {
        return p.vt.RenameElement(p, old, new);
    }
};

extern "ole32" fn StgCreateDocfile(?Name, DWORD, DWORD, **IStorage) callconv(.winapi) HRESULT;
extern "ole32" fn StgOpenStorage(?Name, ?*IStorage, DWORD, ?*anyopaque, DWORD, **IStorage) callconv(.winapi) HRESULT;
extern "ole32" fn CoTaskMemFree(?*anyopaque) callconv(.winapi) void;

const io = std.Io.Threaded.global_single_threaded.io();

pub fn die(hr: HRESULT, s: []const u8, line: u32) noreturn {
    std.debug.print("{d}: {s}: 0x{x:0>8}\n", .{ line, s, @as(u32, @bitCast(hr)) });
    std.process.exit(1);
}

pub fn ck(hr: HRESULT, s: []const u8, line: u32) void {
    if (hr < 0) die(hr, s, line);
}

pub fn CK(hr: HRESULT, src: std.builtin.SourceLocation) void {
    ck(hr, src.fn_name, src.line);
}

var wbuf: [4][32:0]WCHAR = undefined;
var wn: u2 = 0;

pub fn w(s: []const u8) Name {
    const p = &wbuf[wn];
    wn +%= 1;
    if (s.len > 31) die(E_INVALIDARG, s, @src().line);
    for (s, 0..) |c, i| p[i] = c;
    p[s.len] = 0;
    return p;
}

pub fn stg(file: []const u8, mode: DWORD, create: bool) *IStorage {
    var path: [260:0]WCHAR = undefined;
    var p: *IStorage = undefined;

    for (file, 0..) |c, i| path[i] = c;
    for (".cfb", file.len..) |c, i| path[i] = c;
    path[file.len + 4] = 0;
    if (create)
        CK(StgCreateDocfile(&path, mode | STGM_CREATE, 0, &p), @src())
    else
        CK(StgOpenStorage(&path, null, mode, null, 0, &p), @src());
    return p;
}

pub fn dir(parent: *IStorage, name: []const u8, mode: DWORD, create: bool) *IStorage {
    var p: *IStorage = undefined;

    if (create)
        CK(parent.vt.CreateStorage(parent, w(name), mode, 0, 0, &p), @src())
    else
        CK(parent.vt.OpenStorage(parent, w(name), null, mode, null, 0, &p), @src());
    return p;
}

pub fn str(parent: *IStorage, name: []const u8, mode: DWORD, create: bool) *IStream {
    var p: *IStream = undefined;

    if (create)
        CK(parent.vt.CreateStream(parent, w(name), mode, 0, 0, &p), @src())
    else
        CK(parent.vt.OpenStream(parent, w(name), null, mode, 0, &p), @src());
    return p;
}

pub fn rm(parent: *IStorage, name: []const u8) void {
    CK(parent.vt.DestroyElement(parent, w(name)), @src());
}

var buf: [1 << 16]u8 = undefined;

pub fn put(s: *IStream, pat: []const u8, off: u64, n: u64) void {
    var o = off;
    var left = n;
    var done: ULONG = undefined;

    CK(s.seek(@intCast(o), STREAM_SEEK_SET), @src());
    while (left != 0) {
        const chunk: usize = @intCast(@min(left, buf.len));
        for (buf[0..chunk], 0..) |*b, i| b.* = pat[@intCast((o + i) % pat.len)];
        CK(s.write(buf[0..chunk], &done), @src());
        if (done != chunk) die(STG_E_WRITEFAULT, pat, @src().line);
        o += chunk;
        left -= chunk;
    }
}

pub fn resize(s: *IStream, n: u64) void {
    CK(s.setSize(n), @src());
}

pub fn mk(parent: *IStorage, name: []const u8, pat: []const u8, n: u64) void {
    const s = str(parent, name, RW, true);
    put(s, pat, 0, n);
    s.release();
}

fn hash(s: *IStream, size: *u64) u64 {
    var h: std.hash.XxHash3 = .init(0);
    var n: ULONG = undefined;

    size.* = 0;
    while (true) {
        CK(s.read(&buf, &n), @src());
        if (n == 0) break;
        h.update(buf[0..n]);
        size.* += n;
    }
    return h.final();
}

fn walk(p: *IStorage, path: *[4096]u8, len: usize, out: *std.Io.Writer) !void {
    var e: *IEnumSTATSTG = undefined;
    var st: STATSTG = undefined;

    CK(p.vt.EnumElements(p, 0, null, 0, &e), @src());
    defer e.release();
    while (e.next(&st) == S_OK) {
        defer CoTaskMemFree(st.pwcsName);
        const name = std.mem.span(st.pwcsName.?);
        var n = len;
        if (n != 0) {
            path[n] = '/';
            n += 1;
        }
        for (name) |c| {
            if (c > 0x7f) die(E_UNEXPECTED, "non-ascii name", @src().line);
            path[n] = @intCast(c);
            n += 1;
        }
        if (st.type == STGTY_STORAGE) {
            var sub: *IStorage = undefined;
            CK(p.vt.OpenStorage(p, name.ptr, null, RO, null, 0, &sub), @src());
            defer sub.release();
            try walk(sub, path, n, out);
        } else if (st.type == STGTY_STREAM) {
            var s: *IStream = undefined;
            var size: u64 = undefined;
            CK(p.vt.OpenStream(p, name.ptr, null, RO, 0, &s), @src());
            const dig = hash(s, &size);
            s.release();
            if (size != st.cbSize) die(E_UNEXPECTED, path[0..n], @src().line);
            try out.writeAll("    .{ .path = \"");
            for (path[0..n]) |c| switch (c) {
                '"', '\\' => try out.print("\\{c}", .{c}),
                0...0x1f, 0x7f => try out.print("\\x{x:0>2}", .{c}),
                else => try out.writeByte(c),
            };
            try out.print("\", .size = {d}, .xxh3 = 0x{x:0>16} }},\n", .{ size, dig });
        }
    }
}

pub fn dump(file: []const u8) void {
    var name: [260]u8 = undefined;
    var path: [4096]u8 = undefined;
    var obuf: [4096]u8 = undefined;
    const root = stg(file, RO, false);
    defer root.release();

    const fname = std.fmt.bufPrint(&name, "{s}.zon", .{file}) catch unreachable;
    const f = std.Io.Dir.cwd().createFile(io, fname, .{}) catch die(E_FAIL, fname, @src().line);
    defer f.close(io);
    var fw = f.writer(io, &obuf);
    const out = &fw.interface;
    out.writeAll(".{\n") catch die(E_FAIL, fname, @src().line);
    walk(root, &path, 0, out) catch die(E_FAIL, fname, @src().line);
    out.writeAll("}\n") catch die(E_FAIL, fname, @src().line);
    out.flush() catch die(E_FAIL, fname, @src().line);
}

const std = @import("std");

pub fn readAlloc(io: std.Io, gpa: std.mem.Allocator, fname: []const u8) ![]align(8) const u8 {
    const f = try std.Io.Dir.cwd().openFile(io, fname, .{});
    defer f.close(io);
    const size = (try f.stat(io)).size;

    var reader = f.reader(io, &.{});
    const ret: []align(8) u8 = try gpa.alignedAlloc(u8, .@"8", size);
    errdefer gpa.free(ret);

    try reader.interface.readSliceAll(ret);
    return ret;
}

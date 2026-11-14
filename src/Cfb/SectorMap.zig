const std = @import("std");
const SectorMap = @This();
const Sid = @import("../Cfb.zig").Sid;

pub const Sector = *align(4) const [512]u8;

pub const SectorNumber = enum(u32) {
    maxregsect = 0xfffffffa,
    difsect = 0xfffffffc,
    fatsect = 0xfffffffd,
    endofchain = 0xfffffffe,
    freesect = 0xffffffff,
    _,

    pub fn isRegular(self: SectorNumber) bool {
        return self.toInt() <= @backingInt(SectorNumber.maxregsect);
    }

    pub fn fromInt(n: u32) SectorNumber {
        return @fromBackingInt(@intCast(n));
    }

    pub fn toInt(self: SectorNumber) u32 {
        return @backingInt(self);
    }
};

image: []align(4) const u8,
owners: []Sid,

const major_shift: u32 = 0x1e;

pub fn init(gpa: std.mem.Allocator, image: []align(4) const u8) !SectorMap {
    if (image.len < 512) return error.ImageTooShort;
    if (std.mem.readInt(u16, image[major_shift..][0..2], .little) != 9)
        return error.UnsupportedShift;
    const owners = try gpa.alloc(Sid, image.len / 512 - 1);
    @memset(owners, .nostream);
    return .{ .image = image, .owners = owners };
}

pub fn deinit(self: *SectorMap, gpa: std.mem.Allocator) void {
    gpa.free(self.owners);
    self.* = undefined;
}

pub fn sector(self: *const SectorMap, sid: Sid, n: SectorNumber) !?Sector {
    if (!n.isRegular() or n.toInt() >= self.owners.len) return null;
    const owner = &self.owners[n.toInt()];
    if (owner.* == .nostream) owner.* = sid;
    if (owner.* != sid) return error.StreamsCross;
    return @alignCast(self.image[(@as(usize, n.toInt()) + 1) * 512 ..][0..512]);
}

pub fn headerU32(self: *const SectorMap, slot: u32) u32 {
    return std.mem.readInt(u32, self.image[slot * 4 ..][0..4], .little);
}

pub fn readu32(self: *const SectorMap, sid: Sid, n: SectorNumber, slot: u32) !?u32 {
    const s = try self.sector(sid, n) orelse return null;
    return std.mem.readInt(u32, s[slot * 4 ..][0..4], .little);
}

// -- TESTS --

const testing = std.testing;
const files = @import("../files.zig");

test "sector spec-example" {
    const bytes = try files.readAlloc(
        testing.io,
        testing.allocator,
        "src/Cfb/testdata/spec-sample.cfb",
    );
    defer testing.allocator.free(bytes);

    var self: SectorMap = try .init(testing.allocator, @alignCast(bytes));
    defer self.deinit(testing.allocator);
    try testing.expectEqual(bytes.ptr + 512, @as([*]const u8, (try self.sector(.fatsect, .fromInt(0))).?));
    try testing.expectEqual(bytes.ptr + 2560, @as([*]const u8, (try self.sector(.root, .fromInt(4))).?));
    try testing.expectEqual(null, try self.sector(.root, .fromInt(5)));
    try testing.expectEqual(null, try self.sector(.root, .endofchain));
    try testing.expectEqual(null, try self.sector(.root, .freesect));
    try testing.expectError(error.StreamsCross, self.sector(.root, .fromInt(0)));
    try testing.expectError(error.StreamsCross, self.sector(.fatsect, .fromInt(4)));
    _ = try self.sector(.fatsect, .fromInt(0));
}

test "init" {
    var buf: [512]u8 align(4) = @splat(0);
    try testing.expectError(error.ImageTooShort, SectorMap.init(testing.allocator, buf[0..511]));
    try testing.expectError(error.UnsupportedShift, SectorMap.init(testing.allocator, &buf));
    buf[major_shift] = 9;
    var self: SectorMap = try .init(testing.allocator, &buf);
    defer self.deinit(testing.allocator);
    try testing.expectEqual(null, self.sector(.root, .fromInt(0)));
}

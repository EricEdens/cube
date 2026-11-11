const std = @import("std");
const Difat = @This();

image: []align(4) const u8,

const shift: u32 = 0x1e;
const first: u32 = 0x44;
const count: u32 = 0x48;
const array: u32 = 0x4c;

const endstrm: u32 = 0xfffffffe;
const freesct: u32 = 0xffffffff;

pub fn init(image: []align(4) const u8) !Difat {
    if (image.len < 512) return error.ImageTooShort;
    if (std.mem.readInt(u16, image[shift..][0..2], .little) != 9)
        return error.UnsupportedShift;
    return .{ .image = image };
}

pub fn startSectorNumber(difat: *const Difat) u32 {
    return std.mem.readInt(u32, difat.image[first..][0..4], .little);
}

pub fn numDifatSectors(difat: *const Difat) u32 {
    return std.mem.readInt(u32, difat.image[count..][0..4], .little);
}

pub fn iterator(difat: *const Difat) Iterator {
    return .{
        .difat = difat,
        .curr = std.mem.bytesAsSlice(u32, difat.image[array..][0..(109 * 4)]),
        .next_sect_number = difat.startSectorNumber(),
    };
}

pub const Iterator = struct {
    difat: *const Difat,
    curr: []const u32,
    next_sect_number: u32,

    pub fn next(iter: *Iterator) ?u32 {
        if (iter.curr.len == 0) {
            const total_sectors = @divCeil(iter.difat.image.len, 512);
            if (iter.next_sect_number + 1 > total_sectors) return null;

            const sector_bytes: []align(4) const u8 = @alignCast(
                iter.difat.image[((iter.next_sect_number + 1) * 512)..][0..512],
            );
            const sector = std.mem.bytesAsSlice(u32, sector_bytes);
            iter.curr = sector[0..127];
            iter.next_sect_number = sector[127];
        }
        if (iter.curr.len > 0) {
            defer iter.curr = iter.curr[1..];
            return iter.curr[0];
        }

        return null;
    }
};

// -- TESTS --

const testing = std.testing;
const files = @import("../files.zig");

// Test file from MS-CFB#3.1.
test "spec-example" {
    const bytes = try files.readAlloc(
        testing.io,
        testing.allocator,
        "src/Cfb/testdata/spec-sample.cfb",
    );
    defer testing.allocator.free(bytes);
    try testing.expectEqual(3072, bytes.len);

    const difat: Difat = try .init(@alignCast(bytes));
    try testing.expectEqual(0xfffffffe, difat.startSectorNumber());
    try testing.expectEqual(0, difat.numDifatSectors());

    var iter = difat.iterator();
    try testing.expectEqual(0, iter.next());
    for (0..108) |_| try testing.expectEqual(0xffffffff, iter.next());
    try testing.expectEqual(null, iter.next());
}

// A 25M v3 file, that spills the difat across 3 sectors in the body.
test "three-difat-sectors" {
    const bytes = try files.readAlloc(
        testing.io,
        testing.allocator,
        "src/Cfb/testdata/difat.cfb",
    );
    defer testing.allocator.free(bytes);
    const difat: Difat = try .init(@alignCast(bytes));
    try testing.expectEqual(3, difat.numDifatSectors());

    // This makes three checks, all to avoid hardcoding the difat:
    //   1. There are 388 entries, terminated by 0xffffffff.
    //   2. The sum of the entries is the same as we get from oledump.
    //   3. Spot check values near the sector boundaries.

    var iter = difat.iterator();
    var total: u64 = 0;
    var actual: std.ArrayList(u32) = .empty;
    defer actual.deinit(testing.allocator);
    for (0..388) |idx| {
        if (iter.next()) |el| {
            total += el;
            try actual.append(testing.allocator, el);
        } else {
            std.testing.failPrint("null found at index {d}", .{idx});
            return error.TestFailed;
        }
    }
    try testing.expectEqual(0xffffffff, iter.next().?);
    try testing.expectEqual(0x924114, total);

    try std.testing.expectEqual(0, actual.items[0]);
    try std.testing.expectEqual(0x35ef, actual.items[108]);
    try std.testing.expectEqual(0x3670, actual.items[109]);
    try std.testing.expectEqual(0x36f2, actual.items[110]);
    try std.testing.expectEqual(0x7672, actual.items[237]);
    try std.testing.expectEqual(0x76f3, actual.items[238]);
    try std.testing.expectEqual(0x7774, actual.items[239]);
}

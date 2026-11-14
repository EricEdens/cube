const std = @import("std");
const Cfb = @import("../Cfb.zig");
const SectorNumber = Cfb.SectorNumber;
const Fat = @This();

image: []align(4) const u8,

const major_shift: u32 = 0x1e;
const first_difat: u32 = 0x11;
const num_difat: u32 = 0x12;
const difat_array0: u32 = 0x13;

pub fn init(image: []align(4) const u8) !Fat {
    if (image.len < 512) return error.ImageTooShort;
    if (std.mem.readInt(u16, image[major_shift..][0..2], .little) != 9)
        return error.UnsupportedShift;
    return .{ .image = image };
}

/// The first DIFAT sector number, declared in the header.
pub fn startSectorNumber(self: *const Fat) SectorNumber {
    return .fromInt(self.readu32(0, first_difat).?);
}

/// The number of difat sectors, declared in the header.
pub fn numDifatSectors(self: *const Fat) u32 {
    return self.readu32(0, num_difat).?;
}

/// Reads DIFAT[n]
pub fn difat(self: *const Fat, n: u32) ?SectorNumber {
    if (n < 109) return .fromInt(self.readu32(0, difat_array0 + n).?);
    var sect = self.startSectorNumber();
    var idx = n - 109;
    while (sect.isRegular()) : (idx -= 127) {
        const file_sect = sect.toInt() + 1;
        if (idx < 127) return .fromInt(self.readu32(file_sect, idx) orelse break);
        sect = .fromInt(self.readu32(file_sect, 127) orelse break);
    }
    return null;
}

/// Reads FAT[n]
pub fn fat(self: *const Fat, n: u32) ?SectorNumber {
    const sect = self.difat(n / 128) orelse return null;
    if (!sect.isRegular()) return null;
    return .fromInt(self.readu32(sect.toInt() + 1, n % 128) orelse return null);
}

fn readu32(self: *const Fat, sect: u32, idx: u32) ?u32 {
    const pos: u64 = (sect * 128 + idx) * 4;
    return if (pos + 4 <= self.image.len)
        std.mem.readInt(u32, self.image[pos..][0..4], .little)
    else
        null;
}

// -- TESTS --

const testing = std.testing;
const files = @import("../files.zig");

// Test file from MS-CFB#3.1.
test "difat spec-example" {
    const bytes = try files.readAlloc(
        testing.io,
        testing.allocator,
        "src/Cfb/testdata/spec-sample.cfb",
    );
    defer testing.allocator.free(bytes);
    try testing.expectEqual(3072, bytes.len);

    const self: Fat = try .init(@alignCast(bytes));
    try testing.expectEqual(SectorNumber.endofchain, self.startSectorNumber());
    try testing.expectEqual(0, self.numDifatSectors());

    try testing.expectEqual(0, self.difat(0).?.toInt());
    for (1..109) |n| try testing.expectEqual(SectorNumber.freesect, self.difat(@intCast(n)));
    try testing.expectEqual(null, self.difat(109));
}

// A 25M v3 file, that spills the self across 3 sectors in the body.
test "difat three-self-sectors" {
    const bytes = try files.readAlloc(
        testing.io,
        testing.allocator,
        "src/Cfb/testdata/difat.cfb",
    );
    defer testing.allocator.free(bytes);
    const self: Fat = try .init(@alignCast(bytes));
    try testing.expectEqual(3, self.numDifatSectors());

    // This makes three checks, all to avoid hardcoding the self:
    //   1. There are 388 entries, terminated by 0xffffffff.
    //   2. The sum of the entries is the same as we get from oledump.
    //   3. Spot check values near the sector boundaries.

    var total: u64 = 0;
    var actual: std.ArrayList(SectorNumber) = .empty;
    defer actual.deinit(testing.allocator);
    for (0..388) |idx| {
        if (self.difat(@intCast(idx))) |el| {
            total += el.toInt();
            try actual.append(testing.allocator, el);
        } else {
            std.testing.failPrint("null found at index {d}", .{idx});
            return error.TestFailed;
        }
    }
    try testing.expectEqual(SectorNumber.freesect, self.difat(388).?);
    try testing.expectEqual(0x924114, total);

    try std.testing.expectEqual(0, actual.items[0].toInt());
    try std.testing.expectEqual(0x35ef, actual.items[108].toInt());
    try std.testing.expectEqual(0x3670, actual.items[109].toInt());
    try std.testing.expectEqual(0x36f2, actual.items[110].toInt());
    try std.testing.expectEqual(0x7672, actual.items[237].toInt());
    try std.testing.expectEqual(0x76f3, actual.items[238].toInt());
    try std.testing.expectEqual(0x7774, actual.items[239].toInt());
}

test "fat spec-example" {
    const bytes = try files.readAlloc(
        testing.io,
        testing.allocator,
        "src/Cfb/testdata/spec-sample.cfb",
    );
    defer testing.allocator.free(bytes);

    const self: Fat = try .init(@alignCast(bytes));
    try testing.expectEqual(SectorNumber.fatsect, self.fat(0));
    try testing.expectEqual(SectorNumber.endofchain, self.fat(1));
    try testing.expectEqual(SectorNumber.endofchain, self.fat(2));
    try testing.expectEqual(4, self.fat(3).?.toInt());
    try testing.expectEqual(SectorNumber.endofchain, self.fat(4));
    for (5..128) |n| try testing.expectEqual(SectorNumber.freesect, self.fat(@intCast(n)));
    try testing.expectEqual(null, self.fat(128));
}

test "fat three-self-sectors" {
    const bytes = try files.readAlloc(
        testing.io,
        testing.allocator,
        "src/Cfb/testdata/difat.cfb",
    );
    defer testing.allocator.free(bytes);
    const self: Fat = try .init(@alignCast(bytes));

    var nfat: u32 = 0;
    var ndif: u32 = 0;
    for (0..388 * 128) |n| switch (self.fat(@intCast(n)).?) {
        .fatsect => nfat += 1,
        .difsect => ndif += 1,
        else => {},
    };
    try testing.expectEqual(388, nfat);
    try testing.expectEqual(3, ndif);
    try testing.expectEqual(null, self.fat(388 * 128));

    for (0..388) |n| try testing.expectEqual(SectorNumber.fatsect, self.fat(self.difat(@intCast(n)).?.toInt()));
    try testing.expectEqual(SectorNumber.difsect, self.fat(0x3671));
    try testing.expectEqual(SectorNumber.endofchain, self.fat(1));
}

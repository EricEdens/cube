const std = @import("std");
const Cfb = @This();
const Difat = @import("Cfb/Difat.zig");

const testing = std.testing;

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

pub const Sid = enum(u32) {
    maxregsid = 0xfffffffa,
    nostream = 0xffffffff,
    _,

    pub fn isRegular(self: Sid) bool {
        return self.toInt() <= @backingInt(Sid.maxregsid);
    }

    pub fn fromInt(n: u32) Sid {
        return @fromBackingInt(@intCast(n));
    }

    pub fn toInt(self: Sid) u32 {
        return @backingInt(self);
    }
};

test {
    _ = Difat;
}

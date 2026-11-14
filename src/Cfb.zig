const std = @import("std");
const Cfb = @This();
const Fat = @import("Cfb/Fat.zig");
const SectorMap = @import("Cfb/SectorMap.zig");

const testing = std.testing;

pub const Sid = enum(u32) {
    root = 0, // minstream
    maxregsid = 0xfffffffa,
    minifat = 0xfffffffb,
    difsect = 0xfffffffc,
    fatsect = 0xfffffffd,
    directory = 0xfffffffe,
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
    _ = Fat;
    _ = SectorMap;
}

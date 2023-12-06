const std = @import("std");
const Shared = @import("../Shared.zig").Shared;
const raylib = @import("raylib");
const RndGen = std.rand.DefaultPrng;

pub const AsteroidsViewModel = Shared.View.ViewModel.Create(
    struct {},
    .{},
);

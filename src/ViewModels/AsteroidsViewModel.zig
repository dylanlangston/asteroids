const std = @import("std");
const Shared = @import("../Shared.zig").Shared;
const raylib = @import("raylib");

pub const AsteroidsViewModel = Shared.View.ViewModel.Create(
    struct {},
    .{},
);

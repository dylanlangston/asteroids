const std = @import("std");
const Shared = @import("../Shared.zig").Shared;
const raylib = @import("raylib");
const RndGen = std.rand.DefaultPrng;

pub const DylanSplashScreenViewModel = Shared.View.ViewModel.Create(
    struct {
        var lastRandom: raylib.Color = Shared.Color.Green.Dark;
        pub inline fn GetRandomColor(seed: f32) raylib.Color {
            var rnd = RndGen.init(@as(u64, @intFromFloat(seed)));
            const random = rnd.random().intRangeAtMost(u8, 0, 4);
            switch (random) {
                0 => {
                    return Shared.Color.Red.Dark;
                },
                1 => {
                    return Shared.Color.Yellow.Dark;
                },
                2 => {
                    return Shared.Color.Green.Dark;
                },
                3 => {
                    return Shared.Color.Blue.Dark;
                },
                else => {
                    return Shared.Color.Purple.Dark;
                },
            }
        }
    },
    .{},
);

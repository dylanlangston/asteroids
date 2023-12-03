const std = @import("std");
const ViewModel = @import("./ViewModel.zig").ViewModel;
const Shared = @import("../Shared.zig").Shared;
const States = @import("../Views/RaylibSplashScreenView.zig").States;
const Logger = @import("../Logger.zig").Logger;
const raylib = @import("raylib");
const Colors = @import("../Colors.zig").Colors;
const RndGen = std.rand.DefaultPrng;

pub const DylanSplashScreenViewModel = ViewModel.Create(
    struct {
        var lastRandom: raylib.Color = Colors.Green.Dark;
        pub inline fn GetRandomColor(seed: f32) raylib.Color {
            var rnd = RndGen.init(@as(u64, @intFromFloat(seed)));
            const random = rnd.random().intRangeAtMost(u8, 0, 4);
            switch (random) {
                0 => {
                    return Colors.Red.Dark;
                },
                1 => {
                    return Colors.Yellow.Dark;
                },
                2 => {
                    return Colors.Green.Dark;
                },
                3 => {
                    return Colors.Blue.Dark;
                },
                else => {
                    return Colors.Purple.Dark;
                },
            }
        }
    },
    .{},
);

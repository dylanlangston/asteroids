const std = @import("std");
const ViewModel = @import("./ViewModel.zig").ViewModel;
const Shared = @import("../Shared.zig").Shared;
const States = @import("../Views/RaylibSplashScreenView.zig").States;
const Logger = @import("../Logger.zig").Logger;
const raylib = @import("raylib");
const Colors = @import("../Colors.zig").Colors;
const Views = @import("../ViewLocator.zig").Views;
const RndGen = std.rand.DefaultPrng;

pub const GameplayIntroViewModel = ViewModel.Create(
    struct {
        pub var BackgroundTexture: ?raylib.Texture = null;

        pub inline fn GameIntro() void {
            raylib.endDrawing();
            const img = raylib.loadImageFromScreen();
            defer img.unload();
            BackgroundTexture = img.toTexture();
            raylib.setTextureFilter(
                BackgroundTexture.?,
                @intFromEnum(raylib.TextureFilter.texture_filter_trilinear),
            );
        }
    },
    .{
        .BypassDeinit = true,
    },
);

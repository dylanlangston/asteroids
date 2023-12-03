const std = @import("std");
const ViewModel = @import("./ViewModel.zig").ViewModel;
const Shared = @import("../Shared.zig").Shared;
const States = @import("../Views/RaylibSplashScreenView.zig").States;
const Logger = @import("../Logger.zig").Logger;
const raylib = @import("raylib");
const Colors = @import("../Colors.zig").Colors;
const Views = @import("../ViewLocator.zig").Views;
const RndGen = std.rand.DefaultPrng;

pub const PauseOptions = enum {
    Continue,
    Quit,
};

pub const PausedViewModel = ViewModel.Create(
    struct {
        pub var selection = PauseOptions.Continue;

        pub var View: Views = undefined;
        pub var BackgroundTexture: ?raylib.Texture = null;

        pub inline fn PauseView(v: Views) void {
            raylib.endDrawing();
            const img = raylib.loadImageFromScreen();
            defer img.unload();
            BackgroundTexture = img.toTexture();
            raylib.setTextureFilter(
                BackgroundTexture.?,
                @intFromEnum(raylib.TextureFilter.texture_filter_trilinear),
            );
            View = v;
            selection = PauseOptions.Continue;
        }
    },
    .{
        .BypassDeinit = true,
    },
);

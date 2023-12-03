const std = @import("std");
const Shared = @import("../Shared.zig").Shared;
const raylib = @import("raylib");

pub const GameplayIntroViewModel = Shared.View.ViewModel.Create(
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

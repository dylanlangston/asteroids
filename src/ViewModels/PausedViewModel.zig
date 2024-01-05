const std = @import("std");
const Shared = @import("../Shared.zig").Shared;
const raylib = @import("raylib");

pub const PauseOptions = enum {
    Continue,
    Quit,
};

pub const PausedViewModel = Shared.View.ViewModel.Create(
    struct {
        pub var selection = PauseOptions.Continue;

        pub var View: Shared.View.Views = undefined;
        pub var BackgroundTexture: ?raylib.Texture = null;

        pub var frameCount: f32 = 0;

        pub inline fn PauseView(v: Shared.View.Views) void {
            frameCount = 0;

            Shared.Music.Stop(.BackgroundMusic);
            for (std.enums.values(Shared.Sound.Sounds)) |sound| {
                Shared.Sound.Pause(sound);
            }

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
        .DeInit = deinit,
    },
);

fn deinit() void {
    for (std.enums.values(Shared.Sound.Sounds)) |sound| {
        Shared.Sound.Resume(sound);
    }
}

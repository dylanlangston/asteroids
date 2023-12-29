const std = @import("std");
const Shared = @import("../Shared.zig").Shared;
const raylib = @import("raylib");

pub const GameOverViewModel = Shared.View.ViewModel.Create(
    struct {
        pub var BackgroundTexture: ?raylib.Texture = null;
        pub var startTime: i64 = 0;
        pub var score: u64 = 0;
        pub var highScore: u64 = 0;

        pub inline fn GameOver(Score: u64, HighScore: u64) void {
            score = Score;
            highScore = HighScore;
            raylib.endDrawing();
            const img = raylib.loadImageFromScreen();
            defer img.unload();
            BackgroundTexture = img.toTexture();
            raylib.setTextureFilter(
                BackgroundTexture.?,
                @intFromEnum(raylib.TextureFilter.texture_filter_trilinear),
            );
            startTime = Shared.Time.getTimestamp();
        }
    },
    .{},
);

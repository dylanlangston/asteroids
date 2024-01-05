const std = @import("std");
const Shared = @import("../Shared.zig").Shared;
const raylib = @import("raylib");

pub const GameOverViewModel = Shared.View.ViewModel.Create(
    struct {
        pub var BackgroundTexture: ?raylib.Texture = null;
        pub var startTime: i64 = 0;
        pub var score: u64 = 0;
        pub var highScore: u64 = 0;

        pub var frameCount: f32 = 0;

        pub inline fn GameOver(Score: u64, HighScore: u64) void {
            frameCount = 0.75;

            score = Score;
            highScore = HighScore;

            Shared.Music.Stop(.BackgroundMusic);
            for (std.enums.values(Shared.Sound.Sounds)) |sound| {
                Shared.Sound.Stop(sound);
            }

            Shared.Sound.Play(.Gameover);

            if (score > highScore) {
                Shared.Settings.UpdateSettings(.{
                    .HighScore = score,
                });
                Shared.Settings.SaveNow();
            }

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

const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("../Shared.zig").Shared;

pub const Starscape = struct {
    const STAR_COUNT = 500;
    const MIN_STAR_SIZE: f32 = 0.1;
    const MAX_STAR_SIZE: f32 = 2.0;

    starTexture: raylib.Texture,

    pub fn init(screenSize: raylib.Vector2) Starscape {
        @setEvalBranchQuota(5000);

        var stars: [STAR_COUNT]raylib.Vector3 = undefined;
        inline for (0..STAR_COUNT) |i| {
            stars[i] = raylib.Vector3.init(
                Shared.Random.Get().float(f32) * screenSize.x,
                Shared.Random.Get().float(f32) * screenSize.y,
                (Shared.Random.Get().float(f32) * (MAX_STAR_SIZE - MIN_STAR_SIZE)) + MIN_STAR_SIZE,
            );
        }
        var renderTexture = raylib.loadRenderTexture(@intFromFloat(screenSize.x), @intFromFloat(screenSize.y));
        {
            raylib.beginTextureMode(renderTexture);
            raylib.clearBackground(Shared.Color.Transparent);
            inline for (stars) |star| {
                raylib.drawCircleGradient(
                    @intFromFloat(star.x),
                    @intFromFloat(star.y),
                    star.z,
                    Shared.Color.Blue.Base,
                    Shared.Color.Yellow.Base,
                );
            }
            defer raylib.endTextureMode();
        }

        return Starscape{
            .starTexture = renderTexture.texture,
        };
    }

    pub fn deinit(self: @This()) void {
        self.starTexture.unload();
    }

    pub fn Draw(self: @This(), screenWidth: f32, screenHeight: f32) void {
        raylib.drawTexturePro(
            self.starTexture,
            raylib.Rectangle.init(
                0,
                0,
                @floatFromInt(self.starTexture.width),
                @floatFromInt(self.starTexture.height),
            ),
            raylib.Rectangle.init(
                0,
                0,
                screenWidth,
                screenHeight,
            ),
            raylib.Vector2.init(0, 0),
            0,
            Shared.Color.Tone.Base,
        );
    }
};

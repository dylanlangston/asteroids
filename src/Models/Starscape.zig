const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("../Shared.zig").Shared;

pub const Starscape = struct {
    const STAR_COUNT = 500;
    const MIN_STAR_SIZE: f32 = 0.25;
    const MAX_STAR_SIZE: f32 = 2.0;

    starTexture: raylib.Texture,

    pub inline fn init(screenSize: raylib.Vector2) Starscape {
        var stars: [STAR_COUNT]raylib.Vector3 = undefined;
        for (0..STAR_COUNT) |i| {
            stars[i] = raylib.Vector3.init(
                Shared.Random.Get().float(f32) * screenSize.x,
                Shared.Random.Get().float(f32) * screenSize.y,
                (Shared.Random.Get().float(f32) * (MAX_STAR_SIZE - MIN_STAR_SIZE)) + MIN_STAR_SIZE,
            );
        }
        var renderTexture = raylib.loadRenderTexture(@intFromFloat(screenSize.x), @intFromFloat(screenSize.y));
        {
            raylib.beginTextureMode(renderTexture);
            defer raylib.endTextureMode();
            raylib.clearBackground(Shared.Color.Transparent);
            for (stars) |star| {
                raylib.drawCircleGradient(
                    @intFromFloat(star.x),
                    @intFromFloat(star.y),
                    star.z,
                    Shared.Color.Blue.Base,
                    Shared.Color.Yellow.Base,
                );
            }
        }

        return Starscape{
            .starTexture = renderTexture.texture,
        };
    }

    pub inline fn deinit(self: @This()) void {
        self.starTexture.unload();
    }

    pub inline fn Draw(
        self: @This(),
        screenWidth: f32,
        screenHeight: f32,
        position: raylib.Vector2,
    ) void {
        const textWidthF: f32 = @floatFromInt(self.starTexture.width);
        const textHeightF: f32 = @floatFromInt(self.starTexture.height);
        raylib.drawTexturePro(
            self.starTexture,
            raylib.Rectangle.init(
                0,
                0,
                textWidthF,
                textHeightF,
            ),
            raylib.Rectangle.init(
                -(screenWidth * 0.2),
                -(screenHeight * 0.2),
                screenWidth + (screenWidth * 0.4),
                screenHeight + (screenHeight * 0.4),
            ),
            raylib.Vector2.init(
                0,
                0,
            ),
            0,
            Shared.Color.Tone.Base,
        );

        // raylib.drawTexturePro(
        //     self.starTexture,
        //     raylib.Rectangle.init(
        //         0,
        //         0,
        //         textWidthF,
        //         textHeightF,
        //     ),
        //     raylib.Rectangle.init(
        //         position.x - (textWidthF / 2),
        //         position.y - (textHeightF / 2),
        //         textWidthF,
        //         textHeightF,
        //     ),
        //     raylib.Vector2.init(
        //         0,
        //         0,
        //     ),
        //     0,
        //     Shared.Color.Tone.Base,
        // );

        raylib.drawTexturePro(
            self.starTexture,
            raylib.Rectangle.init(
                0,
                0,
                textWidthF,
                textHeightF,
            ),
            raylib.Rectangle.init(
                position.x - (textWidthF / 2),
                position.y - (textHeightF / 2),
                textWidthF + (screenWidth * 0.5),
                textHeightF + (screenHeight * 0.5),
            ),
            raylib.Vector2.init(
                (position.x / textWidthF) * (textWidthF * 0.5),
                (position.y / textHeightF) * (textHeightF * 0.5),
            ),
            0,
            Shared.Color.Red.Light,
        );

        raylib.drawTexturePro(
            self.starTexture,
            raylib.Rectangle.init(
                0,
                0,
                -textWidthF,
                -textHeightF,
            ),
            raylib.Rectangle.init(
                position.x - (textWidthF / 2),
                position.y - (textHeightF / 2),
                textWidthF + (screenWidth * 0.25),
                textHeightF + (screenHeight * 0.25),
            ),
            raylib.Vector2.init(
                (position.x / textWidthF) * (textWidthF * 0.25),
                (position.y / textHeightF) * (textHeightF * 0.25),
            ),
            0,
            Shared.Color.Tone.Base,
        );

        // const paralaxAngles = [_]f32{ 0.2, 0.05 };
        // var c: u8 = 0;
        // inline for (paralaxAngles) |angle| {
        //     c += 1;
        //     raylib.drawTexturePro(
        //         self.starTexture,
        //         raylib.Rectangle.init(
        //             0,
        //             0,
        //             -textWidthF,
        //             if (c < 2) textHeightF else -textHeightF,
        //         ),
        //         raylib.Rectangle.init(
        //             -(screenWidth * 0.2),
        //             -(screenHeight * 0.2),
        //             screenWidth + (screenWidth * 0.4) + (screenWidth * angle),
        //             screenHeight + (screenHeight * 0.4) + (screenHeight * angle),
        //         ),
        //         raylib.Vector2.init(
        //             if (c < 2) (position.x / screenWidth) * (screenWidth * angle) else (position.x / screenWidth) * (screenWidth * -angle),
        //             if (c < 2) (position.y / screenHeight) * (screenHeight * angle) else (position.y / screenHeight) * (screenHeight * -angle),
        //         ),
        //         0,
        //         if (c < 2) Shared.Color.Blue.Light else Shared.Color.Red.Light,
        //     );
        // }
    }
};

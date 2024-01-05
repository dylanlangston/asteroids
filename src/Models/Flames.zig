const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("../Shared.zig").Shared;

pub const Flames = struct {
    var frame: f32 = 0;

    pub inline fn Draw(
        position: raylib.Rectangle,
        rotation: f32,
    ) void {
        if (frame == std.math.floatMax(f32)) {
            frame = 0;
        }
        frame += raylib.getFrameTime();

        const fireTexture = Shared.Texture.Get(.Fire);

        const waveShader = Shared.Shader.Get(.Wave);
        const waveShaderLoc = raylib.getShaderLocation(waveShader, "seconds");
        raylib.setShaderValue(waveShader, waveShaderLoc, &frame, @intFromEnum(raylib.ShaderUniformDataType.shader_uniform_float));
        waveShader.activate();
        defer waveShader.deactivate();

        raylib.drawTexturePro(
            fireTexture,
            raylib.Rectangle.init(
                0,
                0,
                @as(f32, @floatFromInt(fireTexture.width)),
                @as(f32, @floatFromInt(fireTexture.height)),
            ),
            position,
            raylib.Vector2.init(position.width / 2, position.height),
            rotation,
            Shared.Color.White.alpha(0.75),
        );
    }
};

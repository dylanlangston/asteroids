const raylib = @import("raylib");
const Shared = @import("../Shared.zig").Shared;

pub const Shoot = struct {
    position: raylib.Vector2,
    speed: raylib.Vector2,
    radius: f32,
    rotation: f32,
    lifeSpawn: f32,
    active: bool,
    color: raylib.Color,

    const ANIMATION_SPEED_MOD = 30;

    pub inline fn init(color: raylib.Color) Shoot {
        return Shoot{
            .position = raylib.Vector2.init(
                0,
                0,
            ),
            .speed = raylib.Vector2.init(
                0,
                0,
            ),
            .radius = 2,
            .rotation = 0,
            .active = false,
            .lifeSpawn = 0,
            .color = color,
        };
    }

    pub inline fn Update(self: *@This(), screenSize: raylib.Vector2) void {
        if (self.active) {
            self.lifeSpawn += raylib.getFrameTime() * ANIMATION_SPEED_MOD;

            // Movement
            self.position.x += self.speed.x;
            self.position.y -= self.speed.y;

            // Collision logic: shoot vs walls
            if (self.position.x > screenSize.x + self.radius) {
                self.active = false;
                self.lifeSpawn = 0;
            } else if (self.position.x < 0 - self.radius) {
                self.active = false;
                self.lifeSpawn = 0;
            }
            if (self.position.y > screenSize.y + self.radius) {
                self.active = false;
                self.lifeSpawn = 0;
            } else if (self.position.y < 0 - self.radius) {
                self.active = false;
                self.lifeSpawn = 0;
            }

            // Life of shoot
            if (self.lifeSpawn >= 60) {
                self.position.x = 0;
                self.position.y = 0;
                self.speed.x = 0;
                self.speed.y = 0;
                self.lifeSpawn = 0;
                self.active = false;
            }
        }
    }

    pub inline fn Draw(self: @This()) void {
        if (self.active) {
            const shootTexture = Shared.Texture.Get(.Shoot);
            const shootWidthF = @as(f32, @floatFromInt(shootTexture.width));
            const shootHeightF = @as(f32, @floatFromInt(shootTexture.height));
            const shootAspectRatio = shootHeightF / shootWidthF;

            const waveShader = Shared.Shader.Get(.Wave);
            const waveShaderLoc = raylib.getShaderLocation(waveShader, "seconds");
            raylib.setShaderValue(waveShader, waveShaderLoc, &Shared.Random.Get().float(f32), @intFromEnum(raylib.ShaderUniformDataType.shader_uniform_float));
            waveShader.activate();
            defer waveShader.deactivate();

            const width = self.radius * 2;

            raylib.drawTexturePro(
                shootTexture,
                raylib.Rectangle.init(0, 0, shootWidthF, shootHeightF),
                raylib.Rectangle.init(self.position.x, self.position.y, width, width * shootAspectRatio),
                raylib.Vector2.init(self.radius, 0),
                self.rotation,
                self.color.alpha((Shared.Random.Get().float(f32) * 0.2) + 0.55),
            );
            raylib.drawCircleV(
                self.position,
                self.radius,
                self.color.alpha((Shared.Random.Get().float(f32) * 0.2) + 0.55),
            );
        }
    }
};

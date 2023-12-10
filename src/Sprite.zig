const std = @import("std");
const raylib = @import("raylib");
const Textures = @import("./AssetManager.zig").AssetManager.Textures;
const Shared = @import("./Shared.zig").Shared;

pub const Sprite = struct {
    Frames: i32,
    Texture: Textures,

    pub inline fn init(frames: i32, texture: Textures) Sprite {
        return Sprite{
            .Frames = frames,
            .Texture = texture,
        };
    }

    pub inline fn getSpriteFrame(self: @This(), currentFrame: i32) Frame {
        const texture = Shared.Texture.Get(self.Texture);
        const frameSize: f32 = @as(f32, @floatFromInt(texture.height)) / 5;
        const nPatchInfo = raylib.NPatchInfo{
            .source = raylib.Rectangle.init(
                0,
                @as(f32, @floatFromInt(currentFrame)) * frameSize,
                @floatFromInt(texture.width),
                frameSize,
            ),
            .top = 0,
            .bottom = 0,
            .left = 0,
            .right = 0,
            .layout = @intFromEnum(raylib.NPatchType.npatch_nine_patch),
        };
        return Frame{
            .Texture = texture,
            .NPatchInfo = nPatchInfo,
        };
    }

    pub const Frame = struct {
        Texture: raylib.Texture,
        NPatchInfo: raylib.NPatchInfo,
    };
};

const std = @import("std");
const raylib = @import("raylib");
const raymath = @import("raylib-math");
const raygui = @import("raygui");
const Shared = @import("../Shared.zig").Shared;
const AsteroidsViewModel = @import("../ViewModels/AsteroidsViewModel.zig").AsteroidsViewModel;

// Original Sauce 😋: https://github.com/raysan5/raylib-games/blob/master/classics/src/asteroids.c
// TODO: This code still needs ot be split into a ViewModel and updated to scale based on the current screenSize.

const vm: type = AsteroidsViewModel.GetVM();

fn DrawFunction() Shared.View.Views {
    raylib.clearBackground(Shared.Color.Blue.Dark);

    vm.starScape.Draw(
        vm.screenSize.x,
        vm.screenSize.y,
        vm.player.position,
    );

    if (vm.player.position.x < 500 or vm.player.position.y < 500 or vm.player.position.x > vm.screenSize.x - 500 or vm.player.position.y > vm.screenSize.y - 500) {
        {
            const wave = Shared.Shader.Get(.Wave);
            wave.activate();
            defer wave.deactivate();

            const waveShaderLoc = raylib.getShaderLocation(wave, "seconds");
            raylib.setShaderValue(wave, waveShaderLoc, &Shared.Random.Get().float(f32), @intFromEnum(raylib.ShaderUniformDataType.shader_uniform_float));

            raylib.drawRectangleLinesEx(
                raylib.Rectangle.init(-5, -5, vm.screenSize.x + 10, vm.screenSize.y + 10),
                5,
                Shared.Color.Red.Dark.alpha((Shared.Random.Get().float(f32) * 0.2) + 0.2),
            );
        }
        raylib.drawRectangleLinesEx(
            raylib.Rectangle.init(-5, -5, vm.screenSize.x + 10, vm.screenSize.y + 10),
            2,
            Shared.Color.Red.Light.alpha((Shared.Random.Get().float(f32) * 0.2) + 0.2),
        );
    }

    // Flash shield if player hurt
    if (vm.player.status != .default) {
        raylib.drawCircleGradient(
            @intFromFloat(vm.player.position.x),
            @intFromFloat(vm.player.position.y),
            vm.player.collider.z * 1.75,
            Shared.Color.Transparent,
            Shared.Color.Yellow.Base.alpha((Shared.Random.Get().float(f32) * 0.2) + 0.2),
        );
    }

    // Draw spaceship
    vm.player.Draw(vm.shipHeight, vm.PLAYER_BASE_SIZE);

    inline for (0..vm.MAX_ALIENS) |i| {
        vm.aliens[i].Draw();
    }

    // Draw meteors
    for (0..vm.MAX_SMALL_METEORS) |i| {
        vm.smallMeteors[i].Draw(vm.player.position);

        if (i < vm.MAX_MEDIUM_METEORS) {
            vm.mediumMeteors[i].Draw(vm.player.position);
        }

        if (i < vm.MAX_BIG_METEORS) {
            vm.bigMeteors[i].Draw(vm.player.position);
        }
    }

    // Draw shoot
    inline for (0..vm.PLAYER_MAX_SHOOTS) |i| {
        if (vm.shoot[i].active) vm.shoot[i].Draw();
    }

    // Draw alien shoot
    inline for (0..vm.ALIENS_MAX_SHOOTS) |i| {
        if (vm.alien_shoot[i].active) vm.alien_shoot[i].Draw();
    }

    return .AsteroidsView;
}

fn DrawWithCamera() Shared.View.Views {
    Shared.Music.Play(.BackgroundMusic);

    vm.Update();

    const screenWidth: f32 = @floatFromInt(raylib.getScreenWidth());
    const screenHeight: f32 = @floatFromInt(raylib.getScreenHeight());
    const screenSize = raylib.Vector2.init(screenWidth, screenHeight);

    const shakeAmount = screenWidth / 350;
    const target = if (vm.player.status == .collide) raylib.Vector2.init(
        vm.player.position.x - (if (Shared.Random.Get().boolean()) shakeAmount else -shakeAmount),
        vm.player.position.y - (if (Shared.Random.Get().boolean()) shakeAmount else -shakeAmount),
    ) else vm.player.position;
    const camera = Shared.Camera.initScaledTargetCamera(
        vm.screenSize,
        screenSize,
        3.5,
        target,
    );
    const result = camera.Draw(Shared.View.Views, &DrawFunction);

    //Flash screen if player hurt
    // if (vm.player.status != .default) {
    //     raylib.drawRectangleV(raylib.Vector2.init(0, 0), screenSize, Shared.Color.Red.Base.alpha(0.1));
    // }

    // Draw Health Bar
    const onePixelScaled: f32 = 0.0025 * screenWidth;
    const healthBarWidth = onePixelScaled * 100;
    raylib.drawRectangleRounded(
        raylib.Rectangle.init(
            5 * onePixelScaled,
            5 * onePixelScaled,
            healthBarWidth + (4 * onePixelScaled),
            10 * onePixelScaled,
        ),
        5 * onePixelScaled,
        5,
        Shared.Color.Red.Dark.alpha(0.5),
    );
    if (vm.shieldLevel > 0) {
        raylib.drawRectangleRounded(
            raylib.Rectangle.init(
                5 * onePixelScaled,
                5 * onePixelScaled,
                (@as(
                    f32,
                    @floatFromInt(vm.shieldLevel),
                ) / @as(
                    f32,
                    @floatFromInt(vm.MAX_SHIELD),
                ) * healthBarWidth) + (4 * onePixelScaled),
                10 * onePixelScaled,
            ),
            5 * onePixelScaled,
            5,
            Shared.Color.Red.Light.alpha(0.5),
        );
    }
    raylib.drawRectangleRoundedLines(
        raylib.Rectangle.init(
            5 * onePixelScaled,
            5 * onePixelScaled,
            healthBarWidth + (4 * onePixelScaled),
            10 * onePixelScaled,
        ),
        5 * onePixelScaled,
        5,
        onePixelScaled,
        Shared.Color.Red.Dark,
    );

    const locale = Shared.Locale.GetLocale();

    const font = Shared.Font.Get(.HyperspaceBold);
    var scoreBuffer: [64]u8 = undefined;
    Shared.Helpers.DrawTextWithFontRightAligned(
        std.fmt.bufPrintZ(&scoreBuffer, "{s}{}", .{ locale.?.Score, vm.score }) catch locale.?.ScoreNotFound,
        Shared.Color.Yellow.Light,
        font,
        onePixelScaled * 15,
        screenWidth - (5 * onePixelScaled),
        5,
    );

    if (Shared.Input.Start_Pressed()) {
        return Shared.View.Pause(.AsteroidsView);
    }

    if (vm.shieldLevel == 0) {
        return Shared.View.GameOver(vm.score, Shared.Settings.GetSettings().HighScore);
    }

    return result;
}

pub const AsteroidsView = Shared.View.View{
    .Key = .AsteroidsView,
    .DrawRoutine = &DrawWithCamera,
    .VM = &AsteroidsViewModel,
};

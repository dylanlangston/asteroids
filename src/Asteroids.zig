const builtin = @import("builtin");
const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("Shared.zig").Shared;

usingnamespace if (builtin.target.os.tag == .wasi) struct {
    // We need this to fix an issue with wizer https://github.com/WebAssembly/WASI/issues/471
    extern fn __wasm_call_ctors() void;
    export fn wizer_initialize() void {
        Shared.init() catch {
            @panic("Error durring init");
        };

        // // Pre-init window
        raylib.setExitKey(.key_null);
        raylib.setTargetFPS(60);
    }
} else struct {};

pub inline fn main() void {
    // On WASM we pre-init using Wizer instead
    if (builtin.target.os.tag != .wasi) {
        Shared.init() catch {
            @panic("Error durring init");
        };
    }
    Shared.Random.init();
    defer Shared.deinit();

    const settings = Shared.Settings.GetSettings();

    // Set logging level
    if (settings.Debug) {
        raylib.setTraceLogLevel(raylib.TraceLogLevel.log_all);
    } else {
        raylib.setTraceLogLevel(raylib.TraceLogLevel.log_info);
    }

    // Create window
    Shared.Log.Info("Creating Window");
    raylib.initWindow(settings.CurrentResolution.Width, settings.CurrentResolution.Height, "Asteroid Arena");
    defer raylib.closeWindow();
    raylib.initAudioDevice();
    defer raylib.closeAudioDevice();
    if (builtin.target.os.tag != .wasi) {
        raylib.setExitKey(.key_null);
        raylib.setTargetFPS(settings.TargetFPS);
    }

    // Default View on startup is the Splash Screen
    var current_view: Shared.View.Views = Shared.View.Views.RaylibSplashScreenView;
    defer DeinitViews();

    // Load locale
    Shared.Log.Info("Load Locale");
    var locale: ?Shared.Locale.Locale = null;
    locale = Shared.Locale.GetLocale();

    // fallback if locale is not set
    if (locale == null) {
        // For now just set the locale to english since that's the only locale
        Shared.Settings.UpdateSettings(.{
            .UserLocale = Shared.Locale.Locales.english,
        });

        // Refresh locale
        locale = Shared.Locale.RefreshLocale();
    }

    raylib.setWindowTitle(locale.?.Title);

    // Get the current view
    var view = Shared.View.ViewLocator.Build(current_view);
    view.init();

    var scanlinePosition: f32 = -10;

    Shared.Log.Info("Begin Game Loop");
    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        defer raylib.endDrawing();

        // Draw the current view
        const new_view = view.DrawRoutine();
        defer current_view = new_view;

        // Draw scan lines
        const screenHeight: f32 = @floatFromInt(raylib.getScreenHeight());
        const screenTick = screenHeight / 240;
        scanlinePosition += raylib.getFrameTime() * 5;
        if (scanlinePosition > 0) scanlinePosition -= 10;
        //raylib.drawLine(0, @intFromFloat(screenTick * (scanlinePosition + 10)), raylib.getScreenWidth(), @intFromFloat(screenTick * (scanlinePosition + 10)), Shared.Color.Red.Base);
        Shared.Shader.DrawTexture(.ScanLine, .ScanLines, raylib.Rectangle.init(
            0,
            screenTick * scanlinePosition,
            @as(f32, @floatFromInt(raylib.getScreenWidth())),
            screenHeight + (screenTick * 20),
        ));

        if (Shared.Settings.GetSettings().Debug) {
            raylib.drawFPS(10, 10);
        }

        if (new_view != current_view) {
            // get the next view
            const next_view = Shared.View.ViewLocator.Build(new_view);

            // deinit old view
            const should_deinit = !next_view.shouldBypassDeinit();
            if (should_deinit) view.deinit();

            // Update the View
            view = next_view;

            // Init new View
            view.init();

            Shared.Log.Debug_Formatted("New View: {}", .{new_view});
        }

        // Quit main loop
        if (new_view == Shared.View.Views.Unknown) break;
    }
}

inline fn DeinitViews() void {
    for (std.enums.values(Shared.View.Views)) |v| {
        const view = Shared.View.ViewLocator.Build(v);
        view.deinit();
    }
}

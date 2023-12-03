const builtin = @import("builtin");
const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("Shared.zig").Shared;

pub inline fn main() void {
    // Cleanup code
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
    raylib.setConfigFlags(
        @enumFromInt( //@intFromEnum(raylib.ConfigFlags.flag_window_always_run) +
            @intFromEnum(raylib.ConfigFlags.flag_msaa_4x_hint) +
            @intFromEnum(raylib.ConfigFlags.flag_window_resizable)),
    );
    raylib.initWindow(settings.CurrentResolution.Width, settings.CurrentResolution.Height, "Astroids Game!");
    defer raylib.closeWindow();
    raylib.initAudioDevice();
    defer raylib.closeAudioDevice();
    raylib.setExitKey(.key_null);
    raylib.setTargetFPS(settings.TargetFPS);

    // Default View on startup is the Splash Screen
    var current_view: Shared.View.Views = Shared.View.Views.Raylib_Splash_Screen;

    // If DebugView is configure use that instead
    if (settings.Debug and settings.DebugView != null) {
        current_view = @enumFromInt(settings.DebugView.?);
    }
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

    Shared.Log.Info("Begin Game Loop");
    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        defer raylib.endDrawing();

        // Draw the current view
        const new_view = view.DrawRoutine();
        defer current_view = new_view;

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
        if (new_view == Shared.View.Views.Quit) break;
    }
}

inline fn DeinitViews() void {
    for (std.enums.values(Shared.View.Views)) |v| {
        const view = Shared.View.ViewLocator.Build(v);
        view.deinit();
    }
}

const std = @import("std");
const BaseViewModel = @import("./ViewModels/ViewModel.zig").ViewModel;
const BaseView = @import("./Views/View.zig").View;
const Shared = @import("./Shared.zig").Shared;
const view_assets = @import("Views_enums").Views_enums;

pub const ViewLocator = struct {
    inline fn LoadViews() []BaseView {
        comptime {
            @setEvalBranchQuota(1500);

            var allPossibleViews: [std.enums.values(Views).len]BaseView = undefined;
            inline for (view_assets, 0..) |file, i| {
                // Check if the file is a view
                const folder = std.fs.path.dirname(file);
                if (folder != null and std.mem.eql(u8, "View", folder.?)) {
                    const importedFile = @cImport(file);
                    inline for (std.meta.fields(@TypeOf(importedFile))) |f| {
                        if (f.type == @TypeOf(BaseView)) {
                            const view = @field(importedFile, f.name);
                            var buf: [1024]u8 = undefined;
                            _ = buf;
                            if (@hasField(@TypeOf(view), "Key")) {
                                allPossibleViews[i] = view;
                            }
                        }
                    }
                }
            }
            return &allPossibleViews;
        }
    }
    const AllViews = LoadViews();
    // const AllViews = [_]BaseView{
    //     @import("./Views/RaylibSplashScreenView.zig").RaylibSplashScreenView,
    //     @import("./Views/DylanSplashScreenView.zig").DylanSplashScreenView,
    //     @import("./Views/PausedView.zig").PausedView,
    //     @import("./Views/AsteroidsView.zig").AsteroidsView,
    //     @import("./Views/MenuView.zig").MenuView,
    //     @import("./Views/SettingsView.zig").SettingsView,
    //     @import("./Views/GameOverView.zig").GameOverView,
    // };

    inline fn GetView(view: Views) BaseView {
        inline for (AllViews) |v| {
            if (@intFromEnum(v.Key) == @intFromEnum(view)) {
                return v;
            }
        }

        return BaseView{
            .Key = .Quit,
            .DrawRoutine = DrawQuit,
        };
    }

    fn DrawQuit() Views {
        return Views.Quit;
    }

    pub inline fn Build(view: Views) BaseView {
        const BuiltView = GetView(view);
        return BuiltView;
    }

    pub inline fn Destroy(view: Views) void {
        const BuiltView = GetView(view);
        BuiltView.deinit();
    }
};

pub const Views = enum {
    Raylib_Splash_Screen,
    Dylan_Splash_Screen,
    Menu,
    Asteroids,
    Paused,
    Settings,
    Game_Over,
    Quit,
};

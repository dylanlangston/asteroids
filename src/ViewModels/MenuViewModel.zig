const std = @import("std");
const Shared = @import("../Shared.zig").Shared;
const Logger = @import("../Logger.zig").Logger;
const raylib = @import("raylib");
const Starscape = @import("../Models/Starscape.zig").Starscape;
const AsteroidsViewModel = @import("../ViewModels/AsteroidsViewModel.zig").AsteroidsViewModel;
const Meteor = @import("../Models/Meteor.zig").Meteor;
const Alien = @import("../Models/Alien.zig").Alien;
const Player = @import("../Models/Player.zig").Player;
const Shoot = @import("../Models/Shoot.zig").Shoot;

pub const Selection = enum {
    Start,
    Quit,
    None,
};

const AsteroidsVM = AsteroidsViewModel.GetVM();

pub const MenuViewModel = Shared.View.ViewModel.Create(
    struct {
        pub var selection = Selection.Start;
        pub var Rectangles: [std.enums.directEnumArrayLen(Selection, 0)]raylib.Rectangle = undefined;

        pub var frameCount: f32 = 0;

        var starScape: Starscape = undefined;
        pub var meteors: [30]Meteor = undefined;
        pub var aliens: [10]Alien = undefined;
        pub const player = Player.init(AsteroidsVM.screenSize, AsteroidsVM.shipHeight, 0);
        var shoots: [0]Shoot = undefined;

        pub inline fn init() void {
            frameCount = 0;

            starScape = Starscape.init(AsteroidsVM.screenSize);
            AsteroidsVM.starScape = starScape;

            inline for (0..meteors.len) |i| {
                meteors[i] = Meteor.init(Shared.Random.Get().float(f32) * 40 + 10);
                meteors[i].RandomizePositionAndSpeed(player, AsteroidsVM.screenSize, false);
                meteors[i].active = true;
            }
            inline for (0..aliens.len) |i| {
                aliens[i] = Alien.init();
                aliens[i].RandomizePosition(player, AsteroidsVM.screenSize, false);
                aliens[i].active = true;
            }
        }

        pub inline fn Update() void {
            inline for (0..meteors.len) |i| {
                // Check Large
                switch (meteors[i].Update(player, &shoots, &aliens, &shoots, AsteroidsVM.screenSize, AsteroidsVM.shipHeight, AsteroidsVM.PLAYER_BASE_SIZE)) {
                    else => {},
                }
            }

            inline for (0..aliens.len) |i| {
                switch (aliens[i].Update(player, &shoots, &shoots, AsteroidsVM.screenSize)) {
                    else => {},
                }
            }
        }

        pub inline fn GetSelectionText(select: Selection) [:0]const u8 {
            const locale = Shared.Locale.GetLocale().?;

            switch (select) {
                Selection.Start => {
                    return locale.Menu_StartGame;
                },
                Selection.Quit => {
                    return locale.Menu_Quit;
                },
                else => {
                    return locale.Missing_Text;
                },
            }
        }
    },
    .{
        .Init = init,
    },
);

fn init() void {
    MenuViewModel.GetVM().init();
    Shared.Music.SetVolume(.TitleScreenMusic, 0.75);
}

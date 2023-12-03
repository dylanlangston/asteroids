const raylib = @import("raylib");

pub const Colors = struct {
    pub const Transparent = raylib.Color.blank;

    pub const Tone = Color{
        .Base = raylib.Color.ray_white,
        .Dark = raylib.Color.black,
        .Light = raylib.Color.white,
    };

    pub const Gray = Color{
        .Base = raylib.Color.gray,
        .Dark = raylib.Color.dark_gray,
        .Light = raylib.Color.light_gray,
    };

    pub const Red = Color{
        .Base = raylib.Color.red,
        .Dark = raylib.Color.maroon,
        .Light = raylib.Color.pink,
    };

    pub const Yellow = Color{
        .Base = raylib.Color.gold,
        .Dark = raylib.Color.orange,
        .Light = raylib.Color.yellow,
    };

    pub const Green = Color{
        .Base = raylib.Color.lime,
        .Dark = raylib.Color.dark_green,
        .Light = raylib.Color.green,
    };

    pub const Blue = Color{
        .Base = raylib.Color.blue,
        .Dark = raylib.Color.dark_blue,
        .Light = raylib.Color.sky_blue,
    };

    pub const Purple = Color{
        .Base = raylib.Color.violet,
        .Dark = raylib.Color.dark_purple,
        .Light = raylib.Color.purple,
    };

    pub const Brown = Color{
        .Base = raylib.Color.brown,
        .Dark = raylib.Color.dark_brown,
        .Light = raylib.Color.beige,
    };
};

pub const Color = struct {
    Base: raylib.Color,
    Dark: raylib.Color,
    Light: raylib.Color,
};

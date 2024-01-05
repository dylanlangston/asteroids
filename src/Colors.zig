const raylib = @import("raylib");

pub const DefaultColors = struct {
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

pub const AKC12 = struct {
    pub const Transparent = raylib.Color.blank;
    pub const White = raylib.Color.white;
    pub const Black = raylib.Color.black;

    pub const Red = Color{
        .Base = raylib.Color.init(194, 75, 110, 255),
        .Dark = raylib.Color.init(167, 49, 105, 255),
        .Light = raylib.Color.init(217, 98, 107, 255),
    };
    pub const Yellow = Color{
        .Base = raylib.Color.init(255, 194, 122, 255),
        .Dark = raylib.Color.init(236, 154, 109, 255),
        .Light = raylib.Color.init(255, 235, 153, 255),
    };
    pub const Green = Color{
        .Base = raylib.Color.init(106, 175, 157, 255),
        .Dark = raylib.Color.init(53, 93, 104, 255),
        .Light = raylib.Color.init(148, 197, 172, 255),
    };
    pub const Blue = Color{
        .Base = raylib.Color.init(32, 20, 51, 255),
        .Dark = raylib.Color.init(32, 17, 39, 255),
        .Light = raylib.Color.init(27, 30, 52, 255),
    };
};

pub const Color = struct {
    Base: raylib.Color,
    Dark: raylib.Color,
    Light: raylib.Color,
};

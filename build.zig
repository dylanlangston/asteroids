const std = @import("std");
const builtin = @import("builtin");
const rl = @import("src/Build_raylib.zig");
const raygui = @import("src/raygui/build.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    var raylib = rl.getModule(b, "src/raylib-zig");
    var raylib_math = rl.math.getModule(b, "src/raylib-zig");

    //web exports are completely separate
    if (target.getOsTag() == .emscripten) {
        const cwd_path = b.build_root.path.?;
        const emscripten_absolute_path = b.pathJoin(&[_][]const u8{
            cwd_path,
            ".",
            "src",
            "emscripten",
            "upstream",
            "emscripten",
        });

        // Set the sysroot folder for emscripten
        b.sysroot = emscripten_absolute_path;

        setupEmscripten(b);

        const exe_lib = rl.compileForEmscripten(
            b,
            "Asteroids",
            "src/Asteroids.zig",
            target,
            optimize,
        );
        try addAssets(
            b,
            exe_lib,
        );

        exe_lib.addModule("raylib", raylib);
        exe_lib.addModule("raylib-math", raylib_math);
        raygui.addTo(b, exe_lib, target, optimize);
        const raylib_artifact = rl.getArtifact(b, target, optimize);

        // Override raylib's default config.h with our custom one
        const raylib_artifact_src_folder = raylib_artifact.step.owner.build_root.path.?;
        const copy_raylib_config_header = b.addSystemCommand(&[_][]const u8{
            "cp",
            b.pathJoin(&[_][]const u8{
                cwd_path,
                "src",
                "Includes",
                "raylib_config.h",
            }),
            b.pathJoin(&[_][]const u8{
                raylib_artifact_src_folder,
                "src",
                "config.h",
            }),
        });
        raylib_artifact.step.dependOn(&copy_raylib_config_header.step);

        // Note that raylib itself is not actually added to the exe_lib output file, so it also needs to be linked with emscripten.
        exe_lib.linkLibrary(raylib_artifact);
        const link_step = try rl.linkWithEmscripten(
            b,
            &[_]*std.Build.Step.Compile{ exe_lib, raylib_artifact },
        );
        b.getInstallStep().dependOn(&link_step.step);
        const run_step = try rl.emscriptenRunStep(b);
        run_step.step.dependOn(&link_step.step);
        const run_option = b.step("run", "Run Asteroids");
        run_option.dependOn(&run_step.step);

        try copyWASMRunStep(b, &link_step.step, cwd_path);

        return;
    }

    const exe = b.addExecutable(.{
        .name = "Asteroids",
        .root_source_file = .{ .path = "src/Asteroids.zig" },
        .optimize = optimize,
        .target = target,
    });
    try addAssets(
        b,
        exe,
    );

    rl.link(b, exe, target, optimize);
    exe.addModule("raylib", raylib);
    exe.addModule("raylib-math", raylib_math);
    raygui.addTo(b, exe, target, optimize);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run Asteroids");
    run_step.dependOn(&run_cmd.step);

    // // Add locales
    // b.installDirectory(.{
    //     .source_dir = .{ .path = "./src/Locales" },
    //     .install_dir = .bin,
    //     .install_subdir = "Locales",
    // });

    b.installArtifact(exe);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/Tests.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

pub fn setupEmscripten(b: *std.build) void {
    std.debug.print("Install Emscripten\n", .{});
    _ = b.exec(&[_][]const u8{
        b.pathJoin(&[_][]const u8{ ".", "src", "emscripten", "emsdk" }),
        "install",
        "latest",
    });

    std.debug.print("Activate Emscripten\n", .{});
    _ = b.exec(&[_][]const u8{
        b.pathJoin(&[_][]const u8{ ".", "src", "emscripten", "emsdk" }),
        "activate",
        "latest",
    });
}

inline fn addAssets(
    b: *std.Build,
    c: *std.build.Step.Compile,
) !void {
    // Views
    try embedFiles(
        "Views",
        "Views",
        &[_][]const u8{
            ".zig",
        },
        b,
        c,
    );

    // Music
    try embedFiles(
        "Music",
        "music_assets",
        &[_][]const u8{
            ".ogg",
        },
        b,
        c,
    );

    // Music
    try embedFiles(
        "Sounds",
        "sound_assets",
        &[_][]const u8{
            ".ogg",
        },
        b,
        c,
    );

    // Fonts
    try embedFiles(
        "Fonts",
        "font_assets",
        &[_][]const u8{
            ".ttf",
        },
        b,
        c,
    );

    // Textures
    try embedFiles(
        "Textures",
        "texture_assets",
        &[_][]const u8{
            ".png",
        },
        b,
        c,
    );
}

inline fn importFiles(
    comptime path: [:0]const u8,
    comptime module_name: [:0]const u8,
    comptime allowed_exts: []const []const u8,
    b: *std.Build,
    c: *std.build.Step.Compile,
) !void {
    const files_step = b.addWriteFiles();

    var deps = std.ArrayList(std.build.ModuleDependency).init(b.allocator);
    var enumNames = std.ArrayList([]const u8).init(b.allocator);
    var sources = std.ArrayList([]const u8).init(b.allocator);
    {
        const cwd = std.fs.cwd();
        var dir = try cwd.openIterableDir(b.pathJoin(&[_][]const u8{
            "src", path,
        }), .{
            .access_sub_paths = true,
        });
        var walker = try dir.walk(b.allocator);
        defer walker.deinit();
        while (try walker.next()) |entry| {
            const ext = std.fs.path.extension(entry.basename);
            const include_file = for (allowed_exts) |e| {
                if (std.mem.eql(u8, ext, e))
                    break true;
            } else false;
            if (include_file) {
                const file_mod = b.createModule(.{ .source_file = .{
                    .path = b.dupe(try std.fmt.allocPrint(b.allocator, ".{s}{s}", .{
                        std.fs.path.sep_str,
                        b.pathJoin(&[_][]const u8{ "src", path, entry.path }),
                    })),
                } });
                const extension = std.fs.path.extension(entry.basename);
                var name = b.dupe(entry.basename[0 .. entry.basename.len - extension.len]);
                std.mem.replaceScalar(
                    u8,
                    name,
                    ' ',
                    '_',
                );
                try enumNames.append(name);
                try deps.append(std.build.ModuleDependency{
                    .name = name,
                    .module = file_mod,
                });

                c.addModule(name, file_mod);
                try sources.append(name);
            }
        }
    }

    const file_name = module_name ++ ".zig";
    const format =
        \\pub const {s} = struct {{
        \\  pub const enums = enum {{ {s}, Unknown }};
        \\  pub const imports = [_][]const type {{ @import("{s}"), }};
        \\}};
    ;

    const string = try std.fmt.allocPrint(b.allocator, format, .{
        module_name,
        try std.mem.join(b.allocator, ", ", enumNames.items),
        try std.mem.join(b.allocator, "\"), @import(\"", sources.items),
    });

    const file = files_step.add(file_name, string);

    const module = b.addModule(module_name, .{
        .source_file = file,
        .dependencies = deps.items,
    });
    c.step.dependOn(&files_step.step);
    c.addModule(module_name, module);
}

inline fn embedFiles(
    comptime path: [:0]const u8,
    comptime module_name: [:0]const u8,
    comptime allowed_exts: []const []const u8,
    b: *std.Build,
    c: *std.build.Step.Compile,
) !void {
    var enumNames = std.ArrayList([]const u8).init(b.allocator);
    var sources = std.ArrayList([]const u8).init(b.allocator);
    {
        var dir = try std.fs.cwd().openIterableDir(b.pathJoin(&[_][]const u8{
            "src", path,
        }), .{
            .access_sub_paths = true,
        });
        var walker = try dir.walk(b.allocator);
        defer walker.deinit();
        while (try walker.next()) |entry| {
            const ext = std.fs.path.extension(entry.basename);
            const include_file = for (allowed_exts) |e| {
                if (std.mem.eql(u8, ext, e))
                    break true;
            } else false;
            if (include_file) {
                try sources.append(b.dupe(try std.fmt.allocPrint(b.allocator, ".{s}{s}", .{
                    std.fs.path.sep_str,
                    b.pathJoin(&[_][]const u8{ path, entry.path }),
                })));
                const extension = std.fs.path.extension(entry.basename);
                var name = b.dupe(entry.basename[0 .. entry.basename.len - extension.len]);
                std.mem.replaceScalar(
                    u8,
                    name,
                    ' ',
                    '_',
                );
                try enumNames.append(name);
            }
        }
    }

    const file_name = module_name ++ ".zig";
    const format =
        \\pub const {s} = struct {{
        \\  pub const enums = enum {{ Unknown, {s} }};
        \\  pub const files = [_][]const u8 {{ "{s}" }};
        \\}};
    ;

    const string = try std.fmt.allocPrint(b.allocator, format, .{
        module_name,
        try std.mem.join(b.allocator, ", ", enumNames.items),
        try std.mem.join(b.allocator, "\", \"", sources.items),
    });

    const files_step = b.addWriteFiles();
    const file = files_step.add(file_name, string);

    const module = b.addModule(module_name, .{
        .source_file = file.dupe(b),
    });
    c.step.dependOn(&files_step.step);
    c.addModule(module_name, module);
}

pub fn copyWASMRunStep(b: *std.Build, dependsOn: *std.Build.Step, cwd_path: []const u8) !void {
    const indexjs_step = b.addSystemCommand(&[_][]const u8{
        "cp",
        b.pathJoin(&[_][]const u8{
            cwd_path,
            "zig-out",
            "htmlout",
            "asteroids.js",
        }),
        b.pathJoin(&[_][]const u8{
            cwd_path,
            "src",
            "asteroids-website",
            "src",
            "import",
            "emscripten.js",
        }),
    });
    const indexwasm_step = b.addSystemCommand(&[_][]const u8{
        "cp",
        b.pathJoin(&[_][]const u8{
            cwd_path,
            "zig-out",
            "htmlout",
            "asteroids.wasm",
        }),
        b.pathJoin(&[_][]const u8{
            cwd_path,
            "src",
            "asteroids-website",
            "src",
            "import",
            "asteroids.wasm",
        }),
    });
    indexjs_step.step.dependOn(dependsOn);
    indexwasm_step.step.dependOn(dependsOn);

    b.getInstallStep().dependOn(&indexjs_step.step);
    b.getInstallStep().dependOn(&indexwasm_step.step);
}

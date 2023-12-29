const std = @import("std");
const raylib = @import("raylib");
const Shared = @import("./Shared.zig").Shared;

pub const Crypto = struct {
    const key = [_]u8{
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
    };

    const AES = std.crypto.core.aes.Aes256;

    pub inline fn GetIV() [16]u8 {
        var buf: [16]u8 = undefined;
        Shared.Random.Get().bytes(buf[0..]);
        return buf;
    }

    pub inline fn Encrypt(
        iv: [16]u8,
        value: []const u8,
        out: []u8,
    ) void {
        var _iv: [16]u8 = iv;
        std.mem.copy(u8, out[0..16], _iv[0..]);

        var ctx = AES.initEnc(key[0..].*);

        var i: usize = 0;
        while (i < value.len) : (i += 16) {
            var block: [16]u8 = undefined;
            std.mem.copy(u8, block[0..], value[i .. i + 16]);

            // block[i] xor iv
            var j: usize = 0;
            while (j < 16) : (j += 1) {
                block[j] ^= _iv[j];
            }

            var block2: [16]u8 = undefined;
            ctx.encrypt(&block2, &block);
            std.mem.copy(u8, out[i + 16 .. i + 32], block2[0..]);
            std.mem.copy(u8, _iv[0..], block2[0..]);
        }
    }

    pub inline fn Decrypt(
        value: []const u8,
        out: []u8,
    ) void {
        var iv: [16]u8 = value[0..16].*;
        var ctx = AES.initDec(key[0..].*);

        var i: usize = 16;
        while (i < value.len) : (i += 16) {
            var block: [16]u8 = undefined;
            std.mem.copy(u8, block[0..], value[i .. i + 16]);
            var block2: [16]u8 = undefined;

            ctx.decrypt(&block2, &block);

            // block[i] xor iv
            var j: usize = 0;
            while (j < 16) : (j += 1) {
                block2[j] ^= iv[j];
            }

            std.mem.copy(u8, out[i - 16 .. i], block2[0..]);
            std.mem.copy(u8, iv[0..], block[0..]);
        }
    }
};

test "round trip" {
    Shared.Random.init();

    const iv = Crypto.GetIV();
    var encryptedOut: [32]u8 = undefined;
    const in = "abcdefghjklmnopq";
    var decryptedOut: [32]u8 = undefined;

    Crypto.Encrypt(iv, in[0..], encryptedOut[0..]);

    try std.testing.expectEqualSlices(u8, iv[0..], encryptedOut[0..16]);

    Crypto.Decrypt(encryptedOut[0..], decryptedOut[0..]);

    try std.testing.expectEqualSlices(u8, in, decryptedOut[0..in.len]);
}

test "crypto number" {
    Shared.Random.init();

    const iv = Crypto.GetIV();
    var encryptedOut: [48]u8 = undefined;
    var decryptedOut: [32]u8 = undefined;
    const in = 10;

    _ = try std.fmt.bufPrint(&decryptedOut, "{d}", .{in});
    Crypto.Encrypt(iv, decryptedOut[0..], encryptedOut[0..]);

    try std.testing.expectEqualSlices(u8, iv[0..], encryptedOut[0..16]);

    for (0..5) |_| {
        Shared.Random.init();
        Crypto.Decrypt(encryptedOut[0..], decryptedOut[0..]);

        var trimValue: [1]u8 = undefined;
        var out = try std.fmt.parseInt(u64, std.mem.trimRight(u8, &decryptedOut, &trimValue), 10);
        try std.testing.expect(in == out);
    }
}

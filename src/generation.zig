const std = @import("std");
const math = @import("zlm.zig");
const Chunk = @import("chunk.zig");
const TextureAtlas = @import("texture_atlas.zig").TextureAtlas;
const c = @import("c.zig");

fn hashVec2(vec: math.Vec2) u64 {
    var seed: u64 = 2;
    seed ^= @floatToInt(u64, @fabs(vec.x)) + 0x9e3779b9 + (seed << 6) + (seed >> 2);
    seed ^= @floatToInt(u64, @fabs(vec.y)) + 0x9e3779b9 + (seed << 6) + (seed >> 2);
    return seed;
}

pub const Generator = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    seed: u32,
    atlas: *TextureAtlas,

    pub fn create(allocator: std.mem.Allocator, seed: u32, atlas: *TextureAtlas) Self {
        return Self {
            .allocator = allocator,
            .seed = seed,
            .atlas = atlas,
        };
    }

    pub fn destroy(_: *Self) void {

    }

    pub fn generateChunk(self: *Self, offset: math.Vec2) !*Chunk.Chunk {
        c.srand(self.seed + @truncate(u32, hashVec2(offset)));

        var data: []u8 = try self.allocator.alloc(u8, Chunk.CHUNK_VOLUME);

        var x: usize = 0;
        while(x < Chunk.CHUNK_SIZE) : (x += 1) {
            var y: usize = 0;
            while(y < Chunk.CHUNK_SIZE) : (y += 1) {
                var value = c.noise2((offset.x * Chunk.CHUNK_SIZE + @intToFloat(f32, x)) / @intToFloat(f32, Chunk.CHUNK_SIZE), (offset.y * Chunk.CHUNK_SIZE + @intToFloat(f32, y)) / @intToFloat(f32, Chunk.CHUNK_SIZE));

                var z: usize = 0;
                while(z < Chunk.CHUNK_HEIGHT) : (z += 1) {
                    var index: usize = (x * Chunk.CHUNK_HEIGHT) + (y * Chunk.CHUNK_HEIGHT * Chunk.CHUNK_SIZE) + z;

                    if(z < 80 + @floatToInt(i32, @round(value * 10))) {
                        data[index] = 1;
                    } else {
                        data[index] = 0;
                    }
                }
            }
        }

        var chunk: *Chunk.Chunk = try self.allocator.create(Chunk.Chunk);
        chunk.* = try Chunk.Chunk.create(self.allocator, data, self.atlas, offset);
        return chunk;
    }
};

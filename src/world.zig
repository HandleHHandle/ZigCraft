const std = @import("std");
const TextureAtlas = @import("texture_atlas.zig").TextureAtlas;
const Player = @import("player.zig").Player;
const Chunk = @import("chunk.zig");
const Generator = @import("generation.zig").Generator;
const math = @import("zlm.zig");

pub const World = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    chunk_size: u8,
    generator: Generator,
    chunks: []Chunk.Chunk,

    pub fn create(allocator: std.mem.Allocator, atlas: *TextureAtlas, chunk_size: u8, seed: u32) !Self {
        var generator = Generator.create(allocator, seed, atlas);

        var length: u32 = @intCast(u32, chunk_size) * @intCast(u32, chunk_size);
        var chunks: []Chunk.Chunk = try allocator.alloc(Chunk.Chunk, length);

        var x: usize = 0;
        while(x < chunk_size) : (x += 1) {
            var y: usize = 0;
            while(y < chunk_size) : (y += 1) {
                var offset = math.vec2(
                    @intToFloat(f32, @intCast(i32, x) - Chunk.CHUNK_SIZE / 2),
                    @intToFloat(f32, @intCast(i32, y) - Chunk.CHUNK_SIZE / 2)
                );

                var index: usize = y * @intCast(usize, chunk_size) + x;
                chunks[index] = try generator.generateChunk(offset);
            }
        }

        return Self {
            .allocator = allocator,
            .chunk_size = chunk_size,
            .generator = generator,
            .chunks = chunks,
        };
    }

    pub fn destroy(self: *World) void {
        var x: usize = 0;
        while(x < self.chunk_size) : (x += 1) {
            var y: usize = 0;
            while(y < self.chunk_size) : (y += 1) {
                var offset = y * self.chunk_size + x;
                self.chunks[offset].destroy();
            }
        }

        self.generator.destroy();

        self.allocator.free(self.chunks);
    }

    pub fn update(_: *Self) void {

    }

    pub fn render(self: *Self) void {
        var x: usize = 0;
        while(x < self.chunk_size) : (x += 1) {
            var y: usize = 0;
            while(y < self.chunk_size) : (y += 1) {
                var offset = y * self.chunk_size + x;
                self.chunks[offset].render();
            }
        }
    }
};

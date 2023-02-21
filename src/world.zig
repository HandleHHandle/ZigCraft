const std = @import("std");
const Chunk = @import("chunk.zig").Chunk;

pub const World = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    chunk_size: u8,
    chunks: []Chunk,

    pub fn create(allocator: std.mem.Allocator, chunk_size: u8) !Self {
        var chunks: []Chunk = try allocator.alloc(Chunk, @intCast(u32, chunk_size) * @intCast(u32, chunk_size));

        return Self {
            .allocator = allocator,
            .chunk_size = chunk_size,
            .chunks = chunks,
        };
    }

    pub fn destroy(world: *World) void {
        world.allocator.free(world.chunks);
    }
};

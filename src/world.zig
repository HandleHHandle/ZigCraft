const std = @import("std");
const TextureAtlas = @import("texture_atlas.zig").TextureAtlas;
const Player = @import("player.zig").Player;
const Chunk = @import("chunk.zig");
const Generator = @import("generation.zig").Generator;
const math = @import("zlm.zig");

pub const CHUNK_LOAD_MAX = 1;

pub const World = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    player: *Player,

    world_size: u8,
    chunk_origin: math.Vec2,
    generator: Generator,
    chunks: []?*Chunk.Chunk,
    chunks_loaded: u16,

    pub fn create(allocator: std.mem.Allocator, player: *Player, atlas: *TextureAtlas, world_size: u8, seed: u32) !Self {
        var generator = Generator.create(allocator, seed, atlas);

        var chunk_origin = Chunk.getChunkPosFromPos(player.position);
        var length: u32 = @intCast(u32, world_size) * @intCast(u32, world_size);
        var chunks: []?*Chunk.Chunk = try allocator.alloc(?*Chunk.Chunk, length);

        var x: usize = 0;
        while(x < world_size) : (x += 1) {
            var y: usize = 0;
            while(y < world_size) : (y += 1) {
                var offset = math.vec2(
                    @intToFloat(f32, @intCast(i32, x) - world_size / 2) + chunk_origin.x,
                    @intToFloat(f32, @intCast(i32, y) - world_size / 2) + chunk_origin.y
                );

                var index: usize = x * @intCast(usize, world_size) + y;
                chunks[index] = try generator.generateChunk(offset);
            }
        }

        return Self {
            .allocator = allocator,
            .player = player,
            .world_size = world_size,
            .chunk_origin = chunk_origin,
            .generator = generator,
            .chunks = chunks,
            .chunks_loaded = 0,
        };
    }

    pub fn destroy(self: *World) void {
        var x: usize = 0;
        while(x < self.world_size) : (x += 1) {
            var y: usize = 0;
            while(y < self.world_size) : (y += 1) {
                var index = y * self.world_size + x;
                if(self.chunks[index] == null) continue;
                self.chunks[index].?.destroy();
                self.allocator.destroy(self.chunks[index].?);
            }
        }

        self.generator.destroy();

        self.allocator.free(self.chunks);
    }

    pub fn update(self: *Self, delta_time: f32) !void {
        self.chunks_loaded = 0;

        self.player.update(delta_time);

        var player_chunk = Chunk.getChunkPosFromPos(self.player.position);
        if(!player_chunk.eql(self.chunk_origin)) {
            self.chunk_origin = player_chunk;

            var length: u32 = @intCast(u32, self.world_size) * @intCast(u32, self.world_size);
            var old_chunks = try self.allocator.alloc(?*Chunk.Chunk, length);
            defer self.allocator.free(old_chunks);
            std.mem.copy(?*Chunk.Chunk, old_chunks,self.chunks);
            std.mem.set(?*Chunk.Chunk, self.chunks, null);

            var index: usize = 0;
            while(index < length) : (index += 1) {
                var chunk = old_chunks[index];
                if(chunk == null) continue;

                if(self.chunkInBounds(chunk.?.offset)) {
                    var offset = chunk.?.offset.sub(self.chunk_origin);
                    offset.x += @intToFloat(f32, self.world_size / 2);
                    offset.y += @intToFloat(f32, self.world_size / 2);
                    var i = @floatToInt(usize, offset.x) * self.world_size + @floatToInt(usize, offset.y);
                    self.chunks[i] = chunk;
                } else {
                    chunk.?.destroy();
                    self.allocator.destroy(chunk.?);
                    old_chunks[index] = null;
                }
            }
        }

        // Load empty chunks
        var x: usize = 0;
        while(x < self.world_size) : (x += 1) {
            var y: usize = 0;
            while(y < self.world_size) : (y += 1) {
                var index: usize = x * @intCast(usize, self.world_size) + y;
                if(self.chunks[index] == null and self.chunks_loaded < CHUNK_LOAD_MAX) {
                    var offset = math.vec2(
                        @intToFloat(f32, @intCast(i32, x) - self.world_size / 2) + self.chunk_origin.x,
                        @intToFloat(f32, @intCast(i32, y) - self.world_size / 2) + self.chunk_origin.y
                    );

                    self.chunks[index] = try self.generator.generateChunk(offset);
                    self.chunks_loaded += 1;
                }
            }
        }
    }

    pub fn render(self: *Self) void {
        var x: usize = 0;
        while(x < self.world_size) : (x += 1) {
            var y: usize = 0;
            while(y < self.world_size) : (y += 1) {
                var index = x * self.world_size + y;
                if(self.chunks[index] == null) continue;
                self.chunks[index].?.render();
            }
        }
    }

    pub fn chunkInBounds(self: *Self, chunk_pos: math.Vec2) bool {
        var min_x = self.chunk_origin.x - @intToFloat(f32, self.world_size / 2);
        var max_x = self.chunk_origin.x + @intToFloat(f32, self.world_size / 2);
        var min_y = self.chunk_origin.y - @intToFloat(f32, self.world_size / 2);
        var max_y = self.chunk_origin.y + @intToFloat(f32, self.world_size / 2);

        return (chunk_pos.x >= min_x
            and chunk_pos.x < max_x
            and chunk_pos.y >= min_y
            and chunk_pos.y < max_y
        );
    }
};

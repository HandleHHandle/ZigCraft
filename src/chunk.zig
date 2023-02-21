const std = @import("std");
const math = @import("zlm.zig");
const TextureAtlas = @import("texture_atlas.zig").TextureAtlas;

const c = @import("c.zig");

pub const CHUNK_SIZE = 16;
pub const CHUNK_HEIGHT = 256;
pub const CHUNK_VOLUME = CHUNK_SIZE * CHUNK_SIZE * CHUNK_HEIGHT;

pub const Mesh = struct {
    const Self = @This();

    vao: c.GLuint,
    vbo: c.GLuint,
    ebo: c.GLuint,
    index_count: i32,

    pub fn create(vertices: []f32, indices: []u32) Self {
        var vao: c.GLuint = undefined;
        var vbo: c.GLuint = undefined;
        var ebo: c.GLuint = undefined;


        c.glGenVertexArrays(1, &vao);
        c.glGenBuffers(1, &vbo);
        c.glGenBuffers(1, &ebo);
        c.glBindVertexArray(vao);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(u32, @sizeOf(f32) * vertices.len), @ptrCast(*const anyopaque, vertices.ptr), c.GL_STATIC_DRAW);

        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @intCast(u32, @sizeOf(u32) * indices.len), @ptrCast(*const anyopaque, indices.ptr), c.GL_STATIC_DRAW);

        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 5 * @sizeOf(f32), null);
        c.glEnableVertexAttribArray(0);

        c.glVertexAttribPointer(1, 2, c.GL_FLOAT, c.GL_FALSE, 5 *  @sizeOf(f32), @intToPtr(*const anyopaque, 3 * @sizeOf(f32)));
        c.glEnableVertexAttribArray(1);

        c.glBindVertexArray(0);

        return Self {
            .vao = vao,
            .vbo = vbo,
            .ebo = ebo,
            .index_count = @intCast(i32, indices.len),
        };
    }

    pub fn destroy(mesh: *Mesh) void {
        c.glDeleteBuffers(1, &mesh.ebo);
        c.glDeleteBuffers(1, &mesh.vbo);
        c.glDeleteVertexArrays(1, &mesh.vao);
    }

    pub fn update(_: *Mesh) void {
    
    }

    pub fn render(mesh: *Mesh) void {
        c.glBindVertexArray(mesh.vao);
        c.glDrawElements(c.GL_TRIANGLES, mesh.index_count, c.GL_UNSIGNED_INT, null);
    }
};

pub const Chunk = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    data: []u8,
    mesh: Mesh,
    offset: math.Vec2,

    pub fn create(allocator: std.mem.Allocator, data: []u8, atlas: *TextureAtlas, offset: math.Vec2) !Self {
        var vertices = try std.ArrayList(f32).initCapacity(allocator, 24 * CHUNK_SIZE * CHUNK_SIZE * CHUNK_HEIGHT);
        var indices = try std.ArrayList(u32).initCapacity(allocator, 36 * CHUNK_SIZE * CHUNK_SIZE * CHUNK_HEIGHT);
        var index_offset: u32 = 0;

        var x: usize = 0;
        while(x < CHUNK_SIZE) : (x += 1) {
            var y: usize = 0;
            while(y < CHUNK_SIZE) : (y += 1) {
                var z: usize = 0;
                while(z < CHUNK_HEIGHT) : (z += 1) {
                    var index: usize = (x * CHUNK_HEIGHT) + (y * CHUNK_HEIGHT * CHUNK_SIZE) + z;
                    if(data[index] != 0) {
                        var left = if(x > 0) data[index - CHUNK_HEIGHT] else 0;
                        var right = if(x < CHUNK_SIZE-1) data[index + CHUNK_HEIGHT] else 0;
                        var backward = if(y > 0) data[index - CHUNK_HEIGHT * CHUNK_SIZE] else 0;
                        var forward = if(y < CHUNK_SIZE-1) data[index + CHUNK_HEIGHT * CHUNK_SIZE] else 0;
                        var bottom = if(z > 0) data[index - 1] else 0;
                        var top = if(z < CHUNK_HEIGHT-1) data[index + 1] else 0;

                        var offsets = atlas.getFaceOffsets();
                        var front_coords = atlas.getFaceCoords(1,0);
                        var back_coords = atlas.getFaceCoords(1,0);
                        var left_coords = atlas.getFaceCoords(1,0);
                        var right_coords = atlas.getFaceCoords(1,0);
                        var top_coords = atlas.getFaceCoords(0,0);
                        var bottom_coords = atlas.getFaceCoords(2,0);

                        var ox = @intToFloat(f32, x) + offset.x * CHUNK_SIZE;
                        var oy = @intToFloat(f32, y) + offset.y * CHUNK_SIZE;
                        var oz = @intToFloat(f32, z);

                        if(left == 0) {
                            var tex_bl = left_coords;
                            var tex_tl = tex_bl.add(math.vec2(0, offsets.y));
                            var tex_br = tex_bl.add(math.vec2(offsets.x, 0));
                            var tex_tr = tex_bl.add(offsets);

                            try vertices.appendSlice(&[_]f32 {
                                0.0 + ox,0.0 + oz,1.0 + oy, tex_bl.x,tex_bl.y,
                                0.0 + ox,0.0 + oz,0.0 + oy, tex_br.x,tex_br.y,
                                0.0 + ox,1.0 + oz,0.0 + oy, tex_tr.x,tex_tr.y,
                                0.0 + ox,1.0 + oz,1.0 + oy, tex_tl.x,tex_tl.y
                            });

                            try indices.appendSlice(&[_]u32 {
                                index_offset,index_offset+1,index_offset+2,
                                index_offset,index_offset+2,index_offset+3
                            });

                            index_offset += 4;
                        }
                        if(right == 0) {
                            var tex_bl = right_coords;
                            var tex_tl = tex_bl.add(math.vec2(0, offsets.y));
                            var tex_br = tex_bl.add(math.vec2(offsets.x, 0));
                            var tex_tr = tex_bl.add(offsets);

                            try vertices.appendSlice(&[_]f32 {
                                1.0 + ox,0.0 + oz,0.0 + oy, tex_bl.x,tex_bl.y,
                                1.0 + ox,0.0 + oz,1.0 + oy, tex_br.x,tex_br.y,
                                1.0 + ox,1.0 + oz,1.0 + oy, tex_tr.x,tex_tr.y,
                                1.0 + ox,1.0 + oz,0.0 + oy, tex_tl.x,tex_tl.y
                            });

                            try indices.appendSlice(&[_]u32 {
                                index_offset,index_offset+1,index_offset+2,
                                index_offset,index_offset+2,index_offset+3
                            });

                            index_offset += 4;
                        }
                        if(backward == 0) {
                            var tex_bl = front_coords;
                            var tex_tl = tex_bl.add(math.vec2(0, offsets.y));
                            var tex_br = tex_bl.add(math.vec2(offsets.x, 0));
                            var tex_tr = tex_bl.add(offsets);

                            try vertices.appendSlice(&[_]f32 {
                                0.0 + ox,0.0 + oz,0.0 + oy, tex_bl.x,tex_bl.y,
                                1.0 + ox,0.0 + oz,0.0 + oy, tex_br.x,tex_br.y,
                                1.0 + ox,1.0 + oz,0.0 + oy, tex_tr.x,tex_tr.y,
                                0.0 + ox,1.0 + oz,0.0 + oy, tex_tl.x,tex_tl.y
                            });

                            try indices.appendSlice(&[_]u32 {
                                index_offset,index_offset+1,index_offset+2,
                                index_offset,index_offset+2,index_offset+3
                            });

                            index_offset += 4;
                        }
                        if(forward == 0) {
                            var tex_bl = back_coords;
                            var tex_tl = tex_bl.add(math.vec2(0, offsets.y));
                            var tex_br = tex_bl.add(math.vec2(offsets.x, 0));
                            var tex_tr = tex_bl.add(offsets);

                            try vertices.appendSlice(&[_]f32 {
                                1.0 + ox,0.0 + oz,1.0 + oy, tex_bl.x,tex_bl.y,
                                0.0 + ox,0.0 + oz,1.0 + oy, tex_br.x,tex_br.y,
                                0.0 + ox,1.0 + oz,1.0 + oy, tex_tr.x,tex_tr.y,
                                1.0 + ox,1.0 + oz,1.0 + oy, tex_tl.x,tex_tl.y
                            });

                            try indices.appendSlice(&[_]u32 {
                                index_offset,index_offset+1,index_offset+2,
                                index_offset,index_offset+2,index_offset+3
                            });

                            index_offset += 4;
                        }
                        if(bottom == 0) {
                            var tex_bl = bottom_coords;
                            var tex_tl = tex_bl.add(math.vec2(0, offsets.y));
                            var tex_br = tex_bl.add(math.vec2(offsets.x, 0));
                            var tex_tr = tex_bl.add(offsets);

                            try vertices.appendSlice(&[_]f32 {
                                0.0 + ox,0.0 + oz,1.0 + oy, tex_bl.x,tex_bl.y,
                                1.0 + ox,0.0 + oz,1.0 + oy, tex_br.x,tex_br.y,
                                1.0 + ox,0.0 + oz,0.0 + oy, tex_tr.x,tex_tr.y,
                                0.0 + ox,0.0 + oz,0.0 + oy, tex_tl.x,tex_tl.y
                            });

                            try indices.appendSlice(&[_]u32 {
                                index_offset,index_offset+1,index_offset+2,
                                index_offset,index_offset+2,index_offset+3
                            });

                            index_offset += 4;
                        }
                        if(top == 0) {
                            var tex_bl = top_coords;
                            var tex_tl = tex_bl.add(math.vec2(0, offsets.y));
                            var tex_br = tex_bl.add(math.vec2(offsets.x, 0));
                            var tex_tr = tex_bl.add(offsets);

                            try vertices.appendSlice(&[_]f32 {
                                0.0 + ox,1.0 + oz,0.0 + oy, tex_bl.x,tex_bl.y,
                                1.0 + ox,1.0 + oz,0.0 + oy, tex_br.x,tex_br.y,
                                1.0 + ox,1.0 + oz,1.0 + oy, tex_tr.x,tex_tr.y,
                                0.0 + ox,1.0 + oz,1.0 + oy, tex_tl.x,tex_tl.y
                            });

                            try indices.appendSlice(&[_]u32 {
                                index_offset,index_offset+1,index_offset+2,
                                index_offset,index_offset+2,index_offset+3
                            });

                            index_offset += 4;
                        }
                    }
                }
            }
        }

        var mesh = Mesh.create(vertices.items,indices.items);

        vertices.deinit();
        indices.deinit();

        return Self {
            .allocator = allocator,
            .data = data,
            .mesh = mesh,
            .offset = offset,
        };
    }

    pub fn destroy(self: *Chunk) void {
        self.allocator.free(self.data);
        self.mesh.destroy();
    }

    pub fn render(chunk: *Chunk) void {
        chunk.mesh.render();
    }
};

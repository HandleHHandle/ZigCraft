const std = @import("std");
const math = @import("zlm.zig");
const TextureAtlas = @import("texture_atlas.zig").TextureAtlas;

const c = @import("c.zig");

const CHUNK_SIZE = 16;
const CHUNK_HEIGHT = 256;
const CHUNK_VOLUME = CHUNK_SIZE * CHUNK_SIZE * CHUNK_HEIGHT;

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
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(u32, @sizeOf(f32) * vertices.len), @ptrCast(*const anyopaque, &vertices[0]), c.GL_STATIC_DRAW);

        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @intCast(u32, @sizeOf(u32) * indices.len), @ptrCast(*const anyopaque, &indices[0]), c.GL_STATIC_DRAW);

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

    data: [16][16][256]u8,
    mesh: Mesh,
    offset: math.Vec3,

    pub fn create(allocator: std.mem.Allocator, atlas: *TextureAtlas, offset: math.Vec3,) !Self {
        var data: [16][16][256]u8 = undefined;

        var x: usize = 0;
        while(x < CHUNK_SIZE) : (x += 1) {
            var y: usize = 0;
            while(y < CHUNK_SIZE) : (y += 1) {
                var z: usize = 0;
                while(z < CHUNK_HEIGHT) : (z += 1) {
                    if(z < 70) {
                        data[x][y][z] = 1;
                    } else {
                        data[x][y][z] = 0;
                    }
                }
            }
        }

        var vertices = std.ArrayList(f32).init(allocator);
        var indices = std.ArrayList(u32).init(allocator);
        var index_offset: u32 = 0;

        x = 0;
        while(x < CHUNK_SIZE) : (x += 1) {
            var y: usize = 0;
            while(y < CHUNK_SIZE) : (y += 1) {
                var z: usize = 0;
                while(z < CHUNK_HEIGHT) : (z += 1) {
                    if(data[x][y][z] == 1) {
                        var ox = @intToFloat(f32, x) + offset.x;
                        var oy = @intToFloat(f32, y) + offset.z;
                        var oz = @intToFloat(f32, z) + offset.y;

                        var offsets = atlas.getFaceOffsets();
                        var front_coords = atlas.getFaceCoords(1,0);
                        var back_coords = atlas.getFaceCoords(1,0);
                        var left_coords = atlas.getFaceCoords(1,0);
                        var right_coords = atlas.getFaceCoords(1,0);
                        var top_coords = atlas.getFaceCoords(0,0);
                        var bottom_coords = atlas.getFaceCoords(2,0);

                        // Front
                        if(y == 0 or data[x][y-1][z] == 0) {
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

                        // Back
                        if(y == CHUNK_SIZE-1 or data[x][y+1][z] == 0) {
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

                        // Left
                        if(x == 0 or data[x-1][y][z] == 0) {
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

                        // Right
                        if(x == CHUNK_SIZE-1 or data[x+1][y][z] == 0) {
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

                        // Top
                        if(z == CHUNK_HEIGHT-1 or data[x][y][z+1] == 0) {
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

                        // Bottom
                        if(z == 0 or data[x][y][z-1] == 0) {
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
                    }
                }
            }
        }

        var mesh = Mesh.create(vertices.items,indices.items);

        vertices.deinit();
        indices.deinit();

        return Self {
            .data = data,
            .mesh = mesh,
            .offset = offset,
        };
    }

    pub fn destroy(chunk: *Chunk) void {
        chunk.mesh.destroy();
    }

    pub fn render(chunk: *Chunk) void {
        chunk.mesh.render();
    }
};

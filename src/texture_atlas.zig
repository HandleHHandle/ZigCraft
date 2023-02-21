const c = @import("c.zig");
const math = @import("zlm.zig");

pub const TextureAtlas = struct {
    const Self = @This();

    width: i32,
    height: i32,
    block_size: u8,
    texture_id: c.GLuint,

    pub fn create(path: [*]const u8, block_size: u8) !Self {
        var width: i32 = 0;
        var height: i32 = 0;
        var channels: i32 = 0;
        c.stbi_set_flip_vertically_on_load(1);
        var data = c.stbi_load(path, &width,&height,&channels, 4);
        if(data == null) {
            return error.FailedToLoadTexture;
        }
        defer c.stbi_image_free(data);

        if(@mod(width, block_size) != 0 or @mod(width, block_size) != 0) {
            return error.TexAtlasDimensionsIncorrect;
        }

        var texture_id: c.GLuint = 0;
        c.glGenTextures(1, &texture_id);
        c.glBindTexture(c.GL_TEXTURE_2D, texture_id);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);

        c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA, width, height, 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, data);

        return Self {
            .width = width,
            .height = height,
            .block_size = block_size,
            .texture_id = texture_id,
        };
    }

    pub fn destroy(self: *Self) void {
        c.glDeleteTextures(1, &self.texture_id);
    }

    pub fn use(self: *Self) void {
        c.glBindTexture(c.GL_TEXTURE_2D, self.texture_id);
    }

    // Offsets from top left corner
    pub fn getFaceCoords(self: *Self, x: u8,y: u8) math.Vec2 {
        var fx: f32 = @intToFloat(f32, x);
        var fy: f32 = @intToFloat(f32, y);
        var fwidth: f32 = @intToFloat(f32, self.width);
        var fheight: f32 = @intToFloat(f32, self.height);
        var fsize: f32 = @intToFloat(f32, self.block_size);

        return math.vec2(fx * fsize / fwidth, fheight - ((fy + 1.0) * fsize / fheight));
    }

    pub fn getFaceOffsets(self: *Self) math.Vec2 {
        var fwidth: f32 = @intToFloat(f32, self.width);
        var fheight: f32 = @intToFloat(f32, self.height);
        var fsize: f32 = @intToFloat(f32, self.block_size);

        return math.vec2(fsize / fwidth,fsize / fheight);
    }
};

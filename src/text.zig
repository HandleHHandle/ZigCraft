const c = @import("c.zig");
const Shader = @import("shader.zig").Shader;
const math = @import("zlm.zig");
const std = @import("std");

pub const TextRenderer = struct {
    const Self = @This();

    size: i32,
    font: *c.TTF_Font,
    shader: Shader,
    tex: c.GLuint,
    vao: c.GLuint,
    vbo: c.GLuint,
    ebo: c.GLuint,

    pub fn create(path: [*]const u8, size: i32) !Self {
        var font: *c.TTF_Font = c.TTF_OpenFont(path, size) orelse {
            return error.FailedToOpenFont;
        };

        var shader = Shader.create(@embedFile("./text.vs"),@embedFile("./text.fs"));
        shader.use();
        shader.setMat4("projection", math.Mat4.createOrthogonal(-2.25,2.25,-4,4, -1000.0,1000.0));

        var tex: c.GLuint = 0;
        c.glGenTextures(1, &tex);
        c.glBindTexture(c.GL_TEXTURE_2D, tex);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);

        var vertices = [_]f32 {
            0.0,-1.0,0.5, 0.0,1.0,
            1.0,-1.0,0.5, 1.0,1.0,
            1.0,0.0,0.5, 1.0,0.0,
            0.0,0.0,0.5, 0.0,0.0
        };
        var indices = [_]u8 {
            0,1,2,
            0,2,3
        };

        var vao: c.GLuint = undefined;
        var vbo: c.GLuint = undefined;
        var ebo: c.GLuint = undefined;

        c.glGenVertexArrays(1, &vao);
        c.glGenBuffers(1, &vbo);
        c.glGenBuffers(1, &ebo);
        c.glBindVertexArray(vao);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(u32, @sizeOf(f32) * vertices.len), @ptrCast(*const anyopaque, &vertices), c.GL_STATIC_DRAW);

        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @intCast(u32, @sizeOf(u8) * indices.len), @ptrCast(*const anyopaque, &indices), c.GL_STATIC_DRAW);

        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 5 * @sizeOf(f32), null);
        c.glEnableVertexAttribArray(0);

        c.glVertexAttribPointer(1, 2, c.GL_FLOAT, c.GL_FALSE, 5 *  @sizeOf(f32), @intToPtr(*const anyopaque, 3 * @sizeOf(f32)));
        c.glEnableVertexAttribArray(1);

        c.glBindVertexArray(0);

        return Self {
            .size = size,
            .font = font,
            .shader = shader,
            .tex = tex,
            .vao = vao,
            .vbo = vbo,
            .ebo = ebo,
        };
    }

    pub fn destroy(self: *Self) void {
        c.glDeleteBuffers(1, &self.ebo);
        c.glDeleteBuffers(1, &self.vbo);
        c.glDeleteBuffers(1, &self.vao);
        c.glDeleteTextures(1, &self.tex);
        self.shader.destroy();
        c.TTF_CloseFont(self.font);
    }

    pub fn renderSlice(self: *Self, allocator: std.mem.Allocator, text: []const u8, position: math.Vec2) !void {
        const cstring = try std.cstr.addNullByte(allocator, text);
        try self.render(cstring.ptr,position);
        allocator.free(cstring);
    }

    pub fn render(self: *Self, text: [*]const u8, position: math.Vec2) !void {
        var color: c.SDL_Color = undefined;
        color.r = 255;
        color.g = 255;
        color.b = 255;
        color.a = 255;

        var surface = c.TTF_RenderText_Blended(self.font, text, color);
        if(surface == null) {
            return error.FailedToRenderFont;
        }
        defer c.SDL_FreeSurface(surface);

        c.glBindTexture(c.GL_TEXTURE_2D, self.tex);

        var colors = surface.*.format.*.BytesPerPixel;
        var format: c.GLuint = 0;
        if(colors == 4) {
            if(surface.*.format.*.Rmask == 0x000000ff) {
                format = c.GL_RGBA;
            } else {
                format = c.GL_BGRA;
            }
        } else {
            if(surface.*.format.*.Rmask == 0x000000ff) {
                format = c.GL_RGB;
            } else {
                format = c.GL_BGR;
            }
        }

        c.glPixelStorei(c.GL_UNPACK_ROW_LENGTH, @divTrunc(surface.*.pitch, surface.*.format.*.BytesPerPixel));
        c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA, surface.*.w,surface.*.h, 0, format, c.GL_UNSIGNED_BYTE, surface.*.pixels);
        c.glPixelStorei(c.GL_UNPACK_ROW_LENGTH, 0);

        self.shader.use();

        var size = @intToFloat(f32, self.size) / 10.0;
        var ratio = @intToFloat(f32, surface.*.w) / @intToFloat(f32, surface.*.h);
        var translation = math.Mat4.createTranslation(math.vec3(position.x,position.y,0.0));
        var scale = math.Mat4.createScale(ratio / 2.0 / size, 1.0 / size,1);
        var model = math.Mat4.batchMul(&[_]math.Mat4 {scale,translation});
        self.shader.setMat4("model", model);

        c.glBindVertexArray(self.vao);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_BYTE, null);
    }
};

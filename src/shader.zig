const std = @import("std");
const c = @import("c.zig");
const math = @import("zlm.zig");

pub const Shader = struct {
    const Self = @This();

    program: c.GLuint,

    pub fn create(vsource: [*]const u8,fsource: [*]const u8) Self {
        var vertexShader = c.glCreateShader(c.GL_VERTEX_SHADER);
        c.glShaderSource(vertexShader, 1, &@ptrCast([*]const u8, vsource), null);
        c.glCompileShader(vertexShader);
        var success: i32 = 0;
        var infoLog: [512]u8 = undefined;
        c.glGetShaderiv(vertexShader, c.GL_COMPILE_STATUS, &success);
        if (success == 0) {
            std.debug.print("Called", .{});
            c.glGetShaderInfoLog(vertexShader, 512, null, &infoLog);
            std.debug.print("{any}", .{infoLog});
        }

        var fragmentShader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
        c.glShaderSource(fragmentShader, 1, &@ptrCast([*]const u8, fsource), null);
        c.glCompileShader(fragmentShader);
        c.glGetShaderiv(vertexShader, c.GL_COMPILE_STATUS, &success);
        if (success == 0) {
            std.debug.print("Called", .{});
            c.glGetShaderInfoLog(vertexShader, 512, null, &infoLog);
            std.debug.print("{any}", .{infoLog});
        }

        var program = c.glCreateProgram();
        c.glAttachShader(program, vertexShader);
        c.glAttachShader(program, fragmentShader);
        c.glLinkProgram(program);
        c.glGetProgramiv(program, c.GL_LINK_STATUS, &success);
        if (success == 0) {
            std.debug.print("Called", .{});
            c.glGetProgramInfoLog(program, 512, null, &infoLog);
            std.debug.print("{s}", .{infoLog});
        }

        c.glDeleteShader(vertexShader);
        c.glDeleteShader(fragmentShader);

        return Self {
            .program = program,
        };
    }

    pub fn destroy(self: *Self) void {
        c.glDeleteProgram(self.program);
    }

    pub fn use(self: *Self) void {
        c.glUseProgram(self.program);
    }

    pub fn setVec2(self: *Self, uniform: [*]const u8, vec: math.Vec2) void {
        c.glUniform2fv(c.glGetUniformLocation(self.program, uniform), 1, &vec.fields[0][0]);
    }

    pub fn setVec3(self: *Self, uniform: [*]const u8, vec: math.Vec3) void {
        c.glUniform3fv(c.glGetUniformLocation(self.program, uniform), 1, &vec.fields[0][0]);
    }

    pub fn setMat4(self: *Self, uniform: [*]const u8, mat: math.Mat4) void {
        c.glUniformMatrix4fv(c.glGetUniformLocation(self.program, uniform), 1, c.GL_FALSE, &mat.fields[0][0]);
    }
};

const std = @import("std");
const Display = @import("display.zig").Display;
const TextureAtlas = @import("texture_atlas.zig").TextureAtlas;
const Player = @import("player.zig").Player;
const Chunk = @import("chunk.zig").Chunk;
const World = @import("world.zig").World;
const math = @import("zlm.zig");

const c = @import("c.zig");

const vertexSource =
    \\#version 330 core
    \\layout(location = 0) in vec3 vertex;
    \\layout(location = 1) in vec2 texcoord;
    \\out vec2 uv;
    \\uniform mat4 mvp;
    \\void main() {
    \\  uv = texcoord;
    \\  gl_Position = mvp * vec4(vertex, 1.0);
    \\}
;

const fragmentSource =
    \\#version 330 core
    \\in vec2 uv;
    \\out vec4 outColor;
    \\uniform sampler2D text;
    \\void main() {
    \\  outColor = texture(text, uv);
    \\}
;

pub fn main() !void {
    var display = try Display.init("ZigCraft", 1280,720);
    defer display.shutdown();

    // Shader stuff
    var vertexShader = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertexShader, 1, &@ptrCast([*]const u8, vertexSource), null);
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
    c.glShaderSource(fragmentShader, 1, &@ptrCast([*]const u8, fragmentSource), null);
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

    // Texture stuff
    var atlas = try TextureAtlas.create("resources/images/texture_atlas.png", 8);
    defer atlas.destroy();

    // Math stuff
    var translation = math.Mat4.createTranslation(math.vec3(0,0,1));
    var scale = math.Mat4.createScale(1,1,1);
    var rotation = math.Mat4.createAngleAxis(math.vec3(0,0,1), math.toRadians(0.0));
    var model = math.Mat4.batchMul(&[_]math.Mat4 {translation,scale,rotation});

    var projection = math.Mat4.createPerspective(math.toRadians(90.0), 16.0 / 9.0, 0.01,1000.0);

    // World stuff
    var player = Player.init(&display);
    player.position = math.vec3(0,80,-16);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if(leaked) {
            @panic("MEMORY LEAK");
        }
    }

    var world = try World.create(allocator, &atlas, 16, 22);
    defer world.destroy();

    //c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);

    var now = c.SDL_GetPerformanceCounter();
    var last = now;
    var delta_time: f32 = 0.0;
    while(display.running) {
        last = now;
        now = c.SDL_GetPerformanceCounter();
        delta_time = @floatCast(f32, @intToFloat(f64, (now - last) * 1000) / @intToFloat(f64, c.SDL_GetPerformanceFrequency()) * 0.001);

        display.input();

        player.update(delta_time);

        if(display.keyPressed(c.SDLK_ESCAPE) and display.cursorCaptured()) {
            display.releaseCursor();
        }
        if(display.mousePressed(c.SDL_BUTTON_LEFT) and !display.cursorCaptured()) {
            display.captureCursor();
        }

        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        c.glUseProgram(program);

        var view = player.getViewMatrix();
        var mvp = math.Mat4.batchMul(&[_]math.Mat4 {model, view, projection});

        c.glUniformMatrix4fv(c.glGetUniformLocation(program, "mvp"), 1, c.GL_FALSE, &mvp.fields[0][0]);

        atlas.use();
        world.render();

        display.swap();
    }
}

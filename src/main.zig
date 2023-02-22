const std = @import("std");
const Display = @import("display.zig").Display;
const Shader = @import("shader.zig").Shader;
const TextureAtlas = @import("texture_atlas.zig").TextureAtlas;
const Player = @import("player.zig").Player;
const Chunk = @import("chunk.zig");
const World = @import("world.zig").World;
const math = @import("zlm.zig");

const TextRenderer = @import("text.zig").TextRenderer;

const c = @import("c.zig");

const vs_default =
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

const fs_default =
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
    display.setVsync(false);
    display.clearColor(126,192,238,255);

    var shader = Shader.create(vs_default,fs_default);
    defer shader.destroy();

    // Texture stuff
    var atlas = try TextureAtlas.create("resources/images/texture_atlas.png", 8);
    defer atlas.destroy();

    // Math stuff
    var projection = math.Mat4.createPerspective(math.toRadians(90.0), 16.0 / 9.0, 0.01,1000.0);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if(leaked) {
            @panic("MEMORY LEAK");
        }
    }

    // World stuff
    var player = Player.init(&display);
    player.position = math.vec3(70,80,-70);

    var world = try World.create(allocator, &player,&atlas, 16, 1344);
    defer world.destroy();

    var text_renderer = try TextRenderer.create("resources/fonts/modern_dos.ttf", 48);
    defer text_renderer.destroy();

    var polygon_mode: bool = false;
    var now = c.SDL_GetPerformanceCounter();
    var last = now;
    var delta_time: f32 = 0.0;
    while(display.running) {
        last = now;
        now = c.SDL_GetPerformanceCounter();
        delta_time = @floatCast(f32, @intToFloat(f64, (now - last) * 1000) / @intToFloat(f64, c.SDL_GetPerformanceFrequency()) * 0.001);

        display.input();
        
        if(display.keyPressed(c.SDLK_f)) {
            display.setFullscreen(!display.fullscreen);
        }
        if(display.keyPressed(c.SDLK_x)) {
            polygon_mode = !polygon_mode;
            c.glPolygonMode(c.GL_FRONT_AND_BACK, if(polygon_mode) c.GL_LINE else c.GL_FILL);
        }
        if(display.keyPressed(c.SDLK_ESCAPE) and display.cursorCaptured()) {
            display.releaseCursor();
        }
        if(display.mousePressed(c.SDL_BUTTON_LEFT) and !display.cursorCaptured()) {
            display.captureCursor();
        }

        try world.update(delta_time);

        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        shader.use();

        var view = player.getViewMatrix();
        var mvp = math.Mat4.batchMul(&[_]math.Mat4 {view, projection});

        shader.setMat4("mvp", mvp);

        atlas.use();
        world.render();

        const position = try std.fmt.allocPrint(allocator, "Position: {d:.2},{d:.2},{d:.2}", .{player.position.x,player.position.y,player.position.z});
        defer allocator.free(position);
        const fps = try std.fmt.allocPrint(allocator, "FPS: {d:.2}", .{1.0 / delta_time});
        defer allocator.free(fps);
        const chunk_pos = Chunk.getChunkPosFromPos(player.position);
        const cp = try std.fmt.allocPrint(allocator, "Chunk: {d},{d}", .{chunk_pos.x,chunk_pos.y});
        defer allocator.free(cp);
        try text_renderer.renderSlice(allocator, position, math.vec2(-2.25,3.9));
        try text_renderer.renderSlice(allocator, fps, math.vec2(-2.25, -3.5));
        try text_renderer.renderSlice(allocator, cp, math.vec2(-2.25, 3.5));

        display.swap();
    }
}

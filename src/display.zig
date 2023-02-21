const c = @import("c.zig");

const std = @import("std");
const math = @import("zlm.zig");

pub const Display = struct {
    const Self = @This();

    window: *c.SDL_Window,
    context: c.SDL_GLContext,
    running: bool,
    keys: [1024]bool,
    previous_keys: [1024]bool,
    mouse_buttons: [5]bool,
    previous_mouse_buttons: [5]bool,
    mouse_delta: math.Vec2,
    mouse_captured: bool,

    pub fn init(title: [*]const u8, width: c_int,height: c_int) !Self {
        if(c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        var window = c.SDL_CreateWindow(
            title,
            c.SDL_WINDOWPOS_UNDEFINED,c.SDL_WINDOWPOS_UNDEFINED,
            width,height,
            c.SDL_WINDOW_OPENGL
        ) orelse {
            c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
            return error.SDLWindowCreationFailed;
        };

        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_DOUBLEBUFFER, 1);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_DEPTH_SIZE, 24);
        _ = c.SDL_GL_SetSwapInterval(0);

        var context = c.SDL_GL_CreateContext(window);
        if(context == null) {
            c.SDL_Log("Failed to create OpenGL context: %s", c.SDL_GetError());
            return error.SDLGLContextCreationFailed;
        }

        if(c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, &c.SDL_GL_GetProcAddress)) == 0) {
            c.SDL_Log("Failed to initialize GLAD");
        }

        c.glViewport(0,0, 1280,720);
        c.glEnable(c.GL_DEPTH_TEST);
        c.glEnable(c.GL_BLEND);
        c.glEnable(c.GL_CULL_FACE);
        c.glCullFace(c.GL_BACK);
        c.glClearColor(1, 0, 0, 1);

        var keys: [1024]bool = undefined;
        var previous_keys: [1024]bool = undefined;
        var buttons: [5]bool = undefined;
        var previous_buttons: [5]bool = undefined;

        return Self {
            .window = window,
            .context = context,
            .running = true,
            .keys = keys,
            .previous_keys = previous_keys,
            .mouse_buttons = buttons,
            .previous_mouse_buttons = previous_buttons,
            .mouse_delta = math.vec2(0,0),
            .mouse_captured = false,
        };
    }

    pub fn shutdown(display: *Display) void {
        c.SDL_GL_DeleteContext(display.context);
        c.SDL_DestroyWindow(display.window);
        c.SDL_Quit();
    }

    pub fn input(display: *Display) void {
        @memcpy(@ptrCast([*]u8, &display.previous_keys), @ptrCast([*]u8, &display.keys), 1024);
        @memcpy(@ptrCast([*]u8, &display.previous_mouse_buttons), @ptrCast([*]u8, &display.mouse_buttons), 5);

        display.mouse_delta.x = 0.0;
        display.mouse_delta.y = 0.0;

        var event: c.SDL_Event = undefined;
        while(c.SDL_PollEvent(&event) != 0) {
            switch(event.@"type") {
                c.SDL_QUIT => {
                    display.running = false;
                },

                c.SDL_KEYDOWN => {
                    display.keys[@intCast(usize, event.@"key".@"keysym".@"sym")] = true;
                },
                c.SDL_KEYUP => {
                    display.keys[@intCast(usize, event.@"key".@"keysym".@"sym")] = false;
                },

                c.SDL_MOUSEMOTION => {
                    display.mouse_delta.x = @intToFloat(f32, event.@"motion".@"xrel");
                    display.mouse_delta.y = @intToFloat(f32, event.@"motion".@"yrel");
                },
                c.SDL_MOUSEBUTTONDOWN => {
                    display.mouse_buttons[@intCast(usize, event.@"button".@"button")] = true;
                },
                c.SDL_MOUSEBUTTONUP => {
                    display.mouse_buttons[@intCast(usize, event.@"button".@"button")] = false;
                },

                else => {},
            }
        }
    }

    pub fn captureCursor(display: *Display) void {
        _ = c.SDL_SetRelativeMouseMode(c.SDL_TRUE);
        display.mouse_captured = true;
    }

    pub fn releaseCursor(display: *Display) void {
        _ = c.SDL_SetRelativeMouseMode(c.SDL_FALSE);
        display.mouse_captured = false;
    }

    pub fn cursorCaptured(display: *Display) bool {
        return display.mouse_captured;
    }

    pub fn keyPressed(display: *Display, keycode: c.SDL_KeyCode) bool {
        return display.keys[keycode] and !display.previous_keys[keycode];
    }

    pub fn keyReleased(display: *Display, keycode: c.SDL_KeyCode) bool {
        return !display.keys[keycode] and display.previous_keys[keycode];
    }

    pub fn keyDown(display: *Display, keycode: c.SDL_KeyCode) bool {
        return display.keys[keycode];
    }

    pub fn keyUp(display: *Display, keycode: c.SDL_KeyCode) bool {
        return !display.keys[keycode];
    }

    pub fn getMouseDelta(display: *Display) math.Vec2 {
        return display.mouse_delta;
    }

    pub fn mousePressed(display: *Display, button: u8) bool {
        return display.mouse_buttons[button] and !display.previous_mouse_buttons[button];
    }

    pub fn mouseReleased(display: *Display, button: u8) bool {
        return !display.mouse_buttons[button] and display.previous_mouse_buttons[button];
    }

    pub fn mouseDown(display: *Display, button: u8) bool {
        return display.mouse_buttons[button];
    }

    pub fn mouseUp(display: *Display, button: u8) bool {
        return !display.mouse_buttons[button];
    }

    pub fn swap(display: *Display) void {
        c.SDL_GL_SwapWindow(display.window);
    }
};

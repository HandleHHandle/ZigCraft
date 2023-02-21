const c = @import("c.zig");

const math = @import("zlm.zig");
const std = @import("std");
const Display = @import("display.zig").Display;

pub const Player = struct {
    const Self = @This();

    display: *Display,
    position: math.Vec3,
    cam_rotation: math.Vec2,
    cam_forward: math.Vec3,
    cam_right: math.Vec3,
    up: math.Vec3,

    pub fn init(display: *Display) Self {
        return Self {
            .display = display,
            .position = math.vec3(0,0,0),
            .cam_rotation = math.vec2(0,0),
            .cam_forward = math.vec3(0,0,1),
            .cam_right = math.vec3(1,0,0),
            .up = math.vec3(0,1,0),
        };
    }

    pub fn update(player: *Player, delta_time: f32) void {
        var display = player.display;

        if(display.cursorCaptured()) {
            var delta = display.getMouseDelta();
            delta = delta.scale(50.0 * delta_time);
            player.cam_rotation.x -= delta.y;
            player.cam_rotation.x = std.math.clamp(player.cam_rotation.x, -89.0,89.0);
            player.cam_rotation.y -= delta.x;

            var rot = math.vec3(0,0,0);
            rot.x = @cos(math.toRadians(player.cam_rotation.y)) * @cos(math.toRadians(player.cam_rotation.x));
            rot.y = @sin(math.toRadians(player.cam_rotation.x));
            rot.z = @sin(math.toRadians(player.cam_rotation.y)) * @cos(math.toRadians(player.cam_rotation.x));
            player.cam_forward = rot.normalize();
            player.cam_right = player.up.cross(player.cam_forward);
        }

        var mdir = math.vec3(0,0,0);

        // Forward
        if(display.keyDown(c.SDLK_w)) {
            mdir.z += 1;
        }
        // Backward
        if(display.keyDown(c.SDLK_s)) {
            mdir.z -= 1;
        }
        // Left
        if(display.keyDown(c.SDLK_a)) {
            mdir.x -= 1;
        }
        // Right
        if(display.keyDown(c.SDLK_d)) {
            mdir.x += 1;
        }
        // Down
        if(display.keyDown(c.SDLK_q)) {
            mdir.y -= 1;
        }
        // Up
        if(display.keyDown(c.SDLK_e)) {
            mdir.y += 1;
        }

        mdir = mdir.scale(5.0 * delta_time);

        player.position = player.position
            .add(player.cam_right.scale(mdir.x))
            .add(player.up.scale(mdir.y))
            .add(player.cam_forward.scale(mdir.z));
    }

    pub fn getViewMatrix(player: *Player) math.Mat4 {
        return math.Mat4.createLookAt(player.position, player.position.add(player.cam_forward), player.up);
    }
};

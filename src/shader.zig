const std = @import("std");

pub const Shader = struct {
    id: c_uint,

    pub fn init(vertex_path: []const u8, fragment_path: []const u8) !Shader {
        _ = fragment_path;
        _ = vertex_path;
    }

    pub fn use(self: Shader) void {
        _ = self;
    }

    pub fn setBool(self: Shader, name: [:0]const u8, value: bool) void {
        _ = value;
        _ = name;
        _ = self;
    }

    pub fn setInt(self: Shader, name: [:0]const u8, value: u32) void {
        _ = value;
        _ = name;
        _ = self;
    }

    pub fn setFloat(self: Shader, name: [:0]const u8, value: f32) void {
        _ = value;
        _ = name;
        _ = self;
    }
};

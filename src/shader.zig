const std = @import("std");
const gl = @import("opengl/gl41.zig");
const Shader = @This();

// program id
id: c_uint,

pub fn create(arena: std.mem.Allocator, vertex_path: []const u8, fragment_path: []const u8) Shader {

    //get vert/frag src from filePath
    //TODO properly handle erros probably
    const vs_file = std.fs.cwd().openFile(vertex_path, .{}) catch unreachable;
    const vs_code = vs_file.readToEndAllocOptions(arena, (10 * 1024), null, @alignOf(u8), 0) catch unreachable;
    const fs_file = std.fs.cwd().openFile(fragment_path, .{}) catch unreachable;
    const fs_code = fs_file.readToEndAllocOptions(arena, (10 * 1024), null, @alignOf(u8), 0) catch unreachable;

    //build and compile the shader program

    //varaibles for compilation error logging
    var success: c_int = undefined;
    var infoLog: [512]u8 = undefined;

    // //compile vertex shader
    var vertex_shader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertex_shader, 1, &vs_code.ptr, null);
    gl.compileShader(vertex_shader);
    //check vertex shader compilation errors
    gl.getShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(vertex_shader, 512, null, &infoLog);
        std.log.err("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}\n", .{infoLog});
    }
    //compile fragment shader
    var fragment_shader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragment_shader, 1, &fs_code.ptr, null);
    gl.compileShader(fragment_shader);
    //check fragment shader compilation errors
    gl.getShaderiv(fragment_shader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(fragment_shader, 512, null, &infoLog);
        std.log.err("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}\n", .{infoLog});
    }
    //create shader program
    const shader_program = gl.createProgram();
    //attach shaders to shader program
    gl.attachShader(shader_program, vertex_shader);
    gl.attachShader(shader_program, fragment_shader);
    //link the shaders
    gl.linkProgram(shader_program);
    //check for shader link errors
    gl.getProgramiv(shader_program, gl.LINK_STATUS, &success);
    if (success == 0) {
        gl.getProgramInfoLog(shader_program, 512, null, &infoLog);
        std.log.err("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}\n", .{infoLog});
    }
    //delete shaders once they are linked to the program
    defer gl.deleteShader(vertex_shader);
    defer gl.deleteShader(fragment_shader);
    return Shader{ .id = shader_program };
}

pub fn use(self: Shader) void {
    gl.useProgram(self.id);
}

pub fn setBool(self: Shader, name: [:0]const u8, value: bool) void {
    gl.uniform1i(gl.getUniformLocation(self.id, name), @intFromBool(value));
}

pub fn setInt(self: Shader, name: [:0]const u8, value: u32) void {
    gl.uniform1i(gl.getUniformLocation(self.id, name), @intCast(value));
}

pub fn setFloat(self: Shader, name: [:0]const u8, value: f32) void {
    gl.uniform1i(gl.getUniformLocation(self.id, name), @floatCast(value));
}

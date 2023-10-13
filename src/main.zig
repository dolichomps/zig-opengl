const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const SCR_WIDTH: u32 = 800;
const SCR_HEIGHT: u32 = 600;

const vertex_shader_source: [:0]const u8 =
    \\#version 410 core
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec3 aColor;
    \\
    \\out vec3 ourColor;
    \\
    \\void main()
    \\{
    \\  gl_Position = vec4(aPos, 1.0);
    \\  ourColor = aColor;
    \\}
;
const fragment_shader_source: [:0]const u8 =
    \\#version 410 core
    \\out vec4 FragColor;
    \\in vec3 ourColor;
    \\
    \\void main()
    \\{
    \\  FragColor = vec4(ourColor, 1.0);
    \\}
;

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    //initialize glfw
    if (!glfw.init(.{})) {
        std.log.err("filed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }

    //create a glfw window
    const window = glfw.Window.create(SCR_WIDTH, SCR_HEIGHT, "Learn opengl", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 4,
        .context_version_minor = 0,
    }) orelse {
        std.log.err("failde to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    //terminate glfw, clearing all allocations
    //(remeber it's defered so it runs after exiting main())
    defer glfw.terminate();
    glfw.makeContextCurrent(window);

    //load all opengl function pointers
    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    //build and compile the shader program
    //compile vertex shader
    var vertex_shader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertex_shader, 1, &vertex_shader_source.ptr, null);
    gl.compileShader(vertex_shader);
    //check vertex shader compilation errors
    var success: c_int = undefined;
    var infoLog: [512]u8 = undefined;
    gl.getShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(vertex_shader, 512, null, &infoLog);
        std.log.err("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}\n", .{infoLog});
    }
    //compile fragment shader
    var fragment_shader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragment_shader, 1, &fragment_shader_source.ptr, null);
    gl.compileShader(fragment_shader);
    //check fragment shader compilation errors
    gl.getShaderiv(fragment_shader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(fragment_shader, 512, null, &infoLog);
        std.log.err("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}\n", .{infoLog});
    }
    //create shader program
    var shader_program = gl.createProgram();
    defer gl.deleteProgram(shader_program);
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
    gl.deleteShader(vertex_shader);
    gl.deleteShader(fragment_shader);

    //setup vertex data and buffers and configure vertex attribs
    const verts = [_]f32{
        //positions      //colors
        -0.5, -0.5, 0.0, 1.0, 1.0, 0.0, //bottom left
        0.5, -0.5, 0.0, 0.0, 1.0, 1.0, //top
        0.0, 0.5, 0.0, 1.0, 0.0, 1.0, //bottom right
    };
    const indices = [_]u32{
        0, 1, 2, //first triangle
    };

    //create a vertex buffer object and a vertex array object
    var VBO: c_uint = undefined;
    var VAO: c_uint = undefined;
    var EBO: c_uint = undefined;
    gl.genVertexArrays(1, &VAO);
    defer gl.deleteVertexArrays(1, &VAO);
    gl.genBuffers(1, &VBO);
    defer gl.deleteBuffers(1, &VBO);
    gl.genBuffers(1, &EBO);
    defer gl.deleteBuffers(1, &EBO);

    //bind vertex array object first,
    gl.bindVertexArray(VAO);
    //then bind and set vertex buffers
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.bufferData(gl.ARRAY_BUFFER, verts.len * @sizeOf(f32), &verts, gl.STATIC_DRAW);
    //bind element buffer object
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(u32), &indices, gl.STATIC_DRAW);
    //then configure vertex attributes, the last param sets the offset
    //position attribute
    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);
    //color attribute
    gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    gl.enableVertexAttribArray(1);

    //we can safely unbind because 'gl.vertexAttribPointer' registered
    //VBO as the vertex attributes bound vertex buffer object
    gl.bindBuffer(gl.ARRAY_BUFFER, 0);

    //uncomment to draw in wireframe mode
    //gl.polygonMode(gl.FRONT_AND_BACK, gl.LINE);

    //render loop
    while (!window.shouldClose()) {
        //input
        try processInput(window);

        //render
        gl.clearColor(0.961, 0.512, 0.957, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        //acvtivate the shader
        gl.useProgram(shader_program);

        //update uniform color
        var time_value = glfw.getTime();
        var blue_value = (@sin(time_value) / 2.0) + 0.5;
        var vertex_color_location = gl.getUniformLocation(shader_program, "ourColor");
        gl.uniform4f(vertex_color_location, 0.0, 0.0, @floatCast(blue_value), 1.0);

        //render the triangle
        gl.bindVertexArray(VAO);
        gl.drawElements(gl.TRIANGLES, 3, gl.UNSIGNED_INT, null);

        window.swapBuffers();
        glfw.pollEvents();
    }
}

fn processInput(window: glfw.Window) !void {
    if (window.getKey(glfw.Key.escape) == glfw.Action.press) {
        window.setShouldClose(true);
    }
}

//default glfw error handling callback so we can log errors from glfw
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

//get the version of opengl supported by the platform
fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

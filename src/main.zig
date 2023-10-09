const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const SCR_WIDTH: u32 = 800;
const SCR_HEIGHT: u32 = 600;

const vertexShaderSource: [:0]const u8 =
    \\#version 410 core
    \\layout (location = 0) in vec3 aPos;
    \\void main()
    \\{
    \\  gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
;
const fragmentShaderSource: [:0]const u8 =
    \\#version 410 core
    \\out vec4 FragColor;
    \\void main()
    \\{
    \\  FragColor = vec4(0.337f, 0.796f, 0.988f, 1.0f);
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
    var vertexShader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertexShader, 1, &vertexShaderSource.ptr, null);
    gl.compileShader(vertexShader);
    //check vertex shader compilation errors
    var success: c_int = undefined;
    var infoLog: [512]u8 = undefined;
    gl.getShaderiv(vertexShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(vertexShader, 512, null, &infoLog);
        std.log.err("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}\n", .{infoLog});
    }
    //compile fragment shader
    var fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragmentShader, 1, &fragmentShaderSource.ptr, null);
    gl.compileShader(fragmentShader);
    //check fragment shader compilation errors
    gl.getShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(fragmentShader, 512, null, &infoLog);
        std.log.err("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}\n", .{infoLog});
    }
    //create shader program
    var shaderProgram = gl.createProgram();
    defer gl.deleteProgram(shaderProgram);
    //attach shaders to shader program
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    //link the shaders
    gl.linkProgram(shaderProgram);
    //check for shader link errors
    gl.getProgramiv(shaderProgram, gl.LINK_STATUS, &success);
    if (success == 0) {
        gl.getProgramInfoLog(shaderProgram, 512, null, &infoLog);
        std.log.err("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}\n", .{infoLog});
    }
    //delete shaders once they are linked to the program
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);

    //setup vertex data and buffers and configure vertex attribs
    const verts = [_]f32{
        0.5, 0.5, 0.0, //top right
        0.5, -0.5, 0.0, //bottom right
        -0.5, -0.5, 0.0, //bottom left
        -0.5, 0.5, 0.0, //top left
    };
    const indices = [_]u32{
        0, 1, 3, //first triangle
        1, 2, 3, //second triangle
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
    //then configure vertex attributes
    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

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

        //draw the triangle
        //all shaders will use this shader progam from here on out
        gl.useProgram(shaderProgram);
        gl.bindVertexArray(VAO);
        gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, null);

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

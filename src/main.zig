const std = @import("std");
const glfw = @import("mach-glfw");
const shader = @import("libs").shader;
const gl = @import("libs").gl;

const SCR_WIDTH: u32 = 800;
const SCR_HEIGHT: u32 = 600;

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    //initialize glfw
    if (!glfw.init(.{})) {
        std.log.err("filed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    //terminate glfw, clearing all allocations
    //(remeber it's defered so it runs after exiting main())
    defer glfw.terminate();

    //create a glfw window
    const window = glfw.Window.create(SCR_WIDTH, SCR_HEIGHT, "Learn opengl", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 4,
        .context_version_minor = 0,
    }) orelse {
        std.log.err("failde to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    glfw.makeContextCurrent(window);

    //load all opengl function pointers
    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    // create allocator for reading from files
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var shader_program = shader.create(arena_allocator, "shaders/shader.vs", "shaders/shader.fs");

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
        shader_program.use();

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

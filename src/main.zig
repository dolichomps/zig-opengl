const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("opengl/gl41.zig");
const shader = @import("Shader.zig");
const zstbi = @import("zstbi");

const SCR_WIDTH: u32 = 800;
const SCR_HEIGHT: u32 = 600;

var mix_amount: f32 = 0.0;
var offset_amountx: f32 = 0.0;
var offset_amountY: f32 = 0.0;

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    //initialize glfw
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    //terminate glfw, clearing all allocations
    //(remember it's defered so it runs after exiting main())
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

    // get a shader from the shader class
    var shader_program = shader.create(
        arena_allocator,
        "src/shaders/shader.vert",
        "src/shaders/shader.frag",
    );

    //load an image
    zstbi.init(allocator);
    defer zstbi.deinit();
    var img1 = try zstbi.Image.loadFromFile("src/assets/container.png", 0);
    zstbi.setFlipVerticallyOnLoad(true);
    var img2 = try zstbi.Image.loadFromFile("src/assets/awesomeface.png", 0);

    //load a texture
    // create texture id
    var texture1: c_uint = undefined;
    gl.genTextures(1, &texture1);
    //activate texture unit before binding
    gl.activeTexture(gl.TEXTURE0);
    // bind the texture
    gl.bindTexture(gl.TEXTURE_2D, texture1);
    //set the wrapping/filtering options on the bound texture object
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    // generate the texture with the loaded image data
    //TODO should handle what happens if a texture doesn't load
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, @intCast(img1.width), @intCast(img1.height), 0, gl.RGBA, gl.UNSIGNED_BYTE, @ptrCast(img1.data));
    gl.generateMipmap(gl.TEXTURE_2D);
    // free the memory after generating the texture
    img1.deinit();

    //load a texture
    // create texture id
    var texture2: c_uint = undefined;
    gl.genTextures(1, &texture2);
    //activate texture unit before binding
    gl.activeTexture(gl.TEXTURE1);
    // bind the texture
    gl.bindTexture(gl.TEXTURE_2D, texture2);
    //set the wrapping/filtering options on the bound texture object
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @intCast(img2.width), @intCast(img2.height), 0, gl.RGBA, gl.UNSIGNED_BYTE, @ptrCast(img2.data));
    gl.generateMipmap(gl.TEXTURE_2D);
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    img2.deinit();

    //setup vertex data and buffers and configure vertex attribs
    const verts = [_]f32{
        //positions    //colors       //texture coords
        0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, //top right
        0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, //bottom right
        -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, //bottom left
        -0.5, 0.5, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, // top left
    };
    const indices = [_]u32{
        0, 1, 2, //first triangle
        3, 0, 2,
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
    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);
    //color attribute
    gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    gl.enableVertexAttribArray(1);
    //texture coord attribute
    gl.vertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), @ptrFromInt(6 * @sizeOf(f32)));
    gl.enableVertexAttribArray(2);

    //we can safely unbind because 'gl.vertexAttribPointer' registered
    //VBO as the vertex attributes bound vertex buffer object
    gl.bindBuffer(gl.ARRAY_BUFFER, 0);

    //uncomment to draw in wireframe mode
    //gl.polygonMode(gl.FRONT_AND_BACK, gl.LINE);

    //activate the shader
    shader_program.use();
    shader_program.setInt("texture1", 0);
    shader_program.setInt("texture2", 1);

    //render loop
    while (!window.shouldClose()) {
        //input
        try processInput(window);

        //render
        gl.clearColor(0.961, 0.512, 0.957, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // const time = glfw.getTime();
        // const offset_x = @sin(time * 2) / 2;
        // const offset_y = @sin(time * 1) / 2;
        shader_program.setFloat("xOffset", @floatCast(offset_amountx));
        shader_program.setFloat("yOffset", @floatCast(offset_amountY));
        shader_program.setFloat("mixAmount", mix_amount);
        //render the triangle
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, texture1);
        gl.activeTexture(gl.TEXTURE1);
        gl.bindTexture(gl.TEXTURE_2D, texture2);
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
    if (window.getKey(glfw.Key.up) == glfw.Action.press) {
        offset_amountY += 0.0001;
    }
    if (window.getKey(glfw.Key.down) == glfw.Action.press) {
        offset_amountY -= 0.0001;
    }
    if (window.getKey(glfw.Key.left) == glfw.Action.press) {
        offset_amountx -= 0.0001;
    }
    if (window.getKey(glfw.Key.right) == glfw.Action.press) {
        offset_amountx += 0.0001;
    }
    if (window.getKey(glfw.Key.q) == glfw.Action.press) {
        mix_amount += 0.0001;
        if (mix_amount > 1) mix_amount = 1;
    }
    if (window.getKey(glfw.Key.w) == glfw.Action.press) {
        mix_amount -= 0.0001;
        if (mix_amount < 0) mix_amount = 0;
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

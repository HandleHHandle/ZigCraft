pub usingnamespace @cImport({
    @cInclude("glad/glad.h");
    @cInclude("SDL2/SDL.h");
    @cDefine("STB_IMAGE_IMPLEMENTATION", "");
    @cDefine("STBI_ONLY_PNG", "");
    @cInclude("misc/stb_image.h");
    @cInclude("stdlib.h");
    @cInclude("noise1234.h");
});

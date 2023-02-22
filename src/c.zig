pub usingnamespace @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("glad/glad.h");
    @cInclude("noise1234.h");
    @cInclude("SDL.h");
    @cInclude("SDL_ttf.h");
    @cDefine("STB_IMAGE_IMPLEMENTATION", "");
    @cDefine("STBI_ONLY_PNG", "");
    @cInclude("misc/stb_image.h");
});

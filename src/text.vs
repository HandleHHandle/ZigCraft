#version 330 core
layout(location = 0) in vec3 vertex;
layout(location = 1) in vec2 texcoord;

out vec2 uv;

uniform mat4 projection;
uniform mat4 model;

void main() {
  uv = texcoord;
  gl_Position = projection * model * vec4(vertex, 1.0);
}

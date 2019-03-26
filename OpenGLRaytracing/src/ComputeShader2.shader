#version 430

layout(local_size_x = 1) in;
layout(rgba32f, binding = 0) uniform image2D imgOutput;

uniform int map[100];
uniform float lookDir;
uniform vec3 pos;

void main() {
	vec4 pixel = vec4(0, 0, 0, 1.0);
	ivec2 dims = imageSize(imgOutput);
	ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);
	int maxDistance = 50;

	float x = float(pixelCoords.x * 2 - dims.x) / dims.x;

	vec3 origin = vec3(5, 0, 5);
	float angle = x * 0.698f + lookDir;
	vec3 rayDir = vec3(sin(angle), 0, cos(angle));
	float distance = 0;
	while (distance < maxDistance) {
		distance += 0.01f;
		vec3 newPos = pos + rayDir * distance;
		int index = int(newPos.x) + int(newPos.z) * 10;
		if (index < 0 || index > 99) break;
		if (map[index] != 0) {
			float color = 1 / distance;
			pixel = vec4(color, color, color, 1);
			break;
		}
	}

	int hHeight = dims.y / 2;
	int height = int((maxDistance - distance * 1.5f) * (float(hHeight) / maxDistance));
	for (int i = 0; i < hHeight; ++i) {
		if (i > height) {
			pixel = vec4(0, 0, 0, 1);
		}
		pixelCoords.y = hHeight + i;
		imageStore(imgOutput, pixelCoords, pixel);
		pixelCoords.y = hHeight - i;
		imageStore(imgOutput, pixelCoords, pixel);
	}
}
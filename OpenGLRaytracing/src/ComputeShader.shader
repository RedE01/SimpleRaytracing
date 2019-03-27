#version 430

layout(local_size_x = 1) in;
layout(rgba32f, binding = 0) uniform image2D imgOutput;

uniform int map[100];
uniform vec3 lightPos[1];
uniform float lookDir;
uniform vec3 pos;

struct hitInfo {
	float distance;
	vec3 hitPoint;
	bool hit;
};

hitInfo castRay(vec3 origin, vec3 rayDir, float maxDistance, float increment) {
	hitInfo hitInf;
	float distance;
	while (distance < maxDistance) {
		distance += increment;
		vec3 newPos = origin + rayDir * distance;
		int index = int(newPos.x) + int(newPos.z) * 10;
		if (index < 0 || index > 99) break;
		if (map[index] != 0) {
			hitInf.distance = distance;
			hitInf.hitPoint = newPos;
			hitInf.hit = true;
			return hitInf;
		}
	}

	return hitInf;
}

void main() {
	vec4 pixel = vec4(0, 0, 0, 1.0);
	ivec2 dims = imageSize(imgOutput);
	ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);
	int maxDistance = 50;

	float x = float(pixelCoords.x * 2 - dims.x) / dims.x;

	float angle = x * 0.698f + lookDir;
	vec3 rayDir = vec3(sin(angle), 0, cos(angle));
	hitInfo info = castRay(pos, rayDir, 50, 0.005f);

	if (info.distance > 0) {
		float lightDistance = distance(info.hitPoint, lightPos[0]);
		float color = 1 / lightDistance;
		pixel = vec4(color, color, color, 1);
	}

	int hHeight = dims.y / 2;
	int height = hHeight - int(float(hHeight) - (float(dims.y) / info.distance));
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
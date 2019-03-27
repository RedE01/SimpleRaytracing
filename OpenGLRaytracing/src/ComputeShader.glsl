#version 430

layout(local_size_x = 1) in;
layout(rgba32f, binding = 0) uniform image2D imgOutput;

uniform int map[100];
uniform vec3 lightPos[1];
uniform float lookDir;
uniform vec3 pos;

struct hitInfo {
	float dist;
	vec3 hitPoint;
	bool hit;
};

hitInfo castRay(vec3 origin, vec3 rayDir, float maxDistance, float increment) {
	hitInfo hitInf;
	hitInf.hit = false;
	float dist = 0;
	while (dist < maxDistance) {
		dist += increment;
		vec3 newPos = origin + rayDir * dist;
		int index = int(newPos.x) + int(newPos.z) * 10;
		if (index < 0 || index > 99) break;
		if (map[index] != 0) {
			hitInf.dist = dist;
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

	float x = float(pixelCoords.x * 2 - dims.x) / dims.x;

	float angle = x * -0.698f + lookDir;
	vec3 rayDir = vec3(sin(angle), 0, cos(angle));
	hitInfo info = castRay(pos, rayDir, 50, 0.01f);
	float lightDistance = 0, color;

	if (info.hit) {
		lightDistance = distance(info.hitPoint, lightPos[0]);
		vec3 rayDir2 = normalize(lightPos[0] - info.hitPoint);
		hitInfo info2 = castRay(info.hitPoint + rayDir2 * 0.02f, rayDir2, lightDistance, 0.01f);
		color = 1 / lightDistance;
		pixel = vec4(color, color, color, 1);
		if (info2.hit) pixel *= 0.5f;
	}

	int hHeight = dims.y / 2;
	int height = hHeight - int(float(hHeight) - (float(dims.y) / info.dist));
	for (int i = 0; i < hHeight; ++i) {
		if (i > height) {
			float floorColor = (0.5 - lightDistance * 0.04f) * color;
			pixel = vec4(floorColor, floorColor, floorColor, 1);
		}
		pixelCoords.y = hHeight - i;
		imageStore(imgOutput, pixelCoords, pixel);
		if (i > height) {
			pixel *= 0.5f;
		}
		pixelCoords.y = hHeight + i;
		imageStore(imgOutput, pixelCoords, pixel);
	}
}
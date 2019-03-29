#version 430

#define MAP_WIDTH 10

layout(local_size_x = 1) in;
layout(rgba32f, binding = 0) uniform image2D imgOutput;

uniform int map[MAP_WIDTH * MAP_WIDTH];
uniform int mapWidth;
uniform float maxRayLength;
uniform vec3 lightPos[1];
uniform float lookDir;
uniform vec3 pos;
uniform int reflections;

struct hitInfo {
	float dist;
	vec3 hitPoint;
	bool hit;
	int wallType;
};

int getSign(float f) {
	return int(f > 0) - int(f < 0);
}

hitInfo castRay(vec3 origin, vec3 rayDir, float maxDistance) {
	hitInfo hitInf;
	hitInf.hit = false;
	float dist = 0;
	vec3 target = vec3((getSign(rayDir.x) * 1.00001f + 1) / 2.0f, 0, (getSign(rayDir.z) * 1.00001f + 1) / 2.0f );
	while (dist < maxDistance) {
		vec3 delta = origin - ivec3(origin);
		vec3 len = vec3((target.x - delta.x) / rayDir.x, 0, (target.z - delta.z) / rayDir.z);
		float smallestLen = len.x < len.z ? len.x : len.z;
		dist += smallestLen;
		origin = origin + rayDir * smallestLen;
		int index = int(origin.x) + int(origin.z) * mapWidth;
		if(index < 0 || index > 143) break;
		if(map[index] != 0) {
			hitInf.dist = dist;
			hitInf.hitPoint = origin;
			hitInf.hit = true;
			hitInf.wallType = map[index];
			break;
		}
	}
	return hitInf;
}

float calculateColor(hitInfo info) {
	float color = 0;
	if (info.hit) {
		float lightDistance = distance(info.hitPoint, lightPos[0]);
		vec3 rayDir2 = normalize(lightPos[0] - info.hitPoint);
		hitInfo info2 = castRay(info.hitPoint + rayDir2 * 0.04f, rayDir2, lightDistance);
		color = 1 / lightDistance;
		if (info2.hit) color *= 0.75f;
	}
	return color;
}

vec3 calculateRefDir(vec3 rayDir, hitInfo lastHitInfo) {
	vec3 refDir = rayDir;

	vec3 normal = (lastHitInfo.hitPoint - ivec3(lastHitInfo.hitPoint)) - vec3(0.5, 0, 0.5);
	if(abs(normal.x) > abs(normal.z)) refDir.x *= -1;
	else refDir.z *= -1;

	return refDir;
}

void main() {
	ivec2 dims = imageSize(imgOutput);
	ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);

	float x = float(pixelCoords.x * 2 - dims.x) / dims.x;

	float angle = x * -0.698f + lookDir;
	vec3 rayDir = vec3(sin(angle), 0, cos(angle));

	hitInfo info = castRay(pos, rayDir, maxRayLength);
	float color = calculateColor(info); 
	
	if(info.wallType == 2) {
		vec3 refDir = rayDir;
		hitInfo refInfo = info;
		float color2;
		int counter = 0;

		while(refInfo.wallType == 2 && counter < reflections) {
			refDir = calculateRefDir(refDir, refInfo);
			refInfo = castRay(refInfo.hitPoint, refDir, maxRayLength);
			color2 = calculateColor(refInfo);

			color = color * 0.7 + color2 * 0.3f;
			info.dist += refInfo.dist;
			counter++;
		}
	}

	vec4 pixel = vec4(color, color, color, 1);
	
	int hHeight = dims.y / 2;
	int height = hHeight - int(float(hHeight) - (float(dims.y) / info.dist));
	for (int i = 0; i < hHeight; ++i) {
		if (i > height) {
			float floorColor = color * 0.4f;
			pixel = vec4(floorColor, floorColor, floorColor, 1);
		}
		pixelCoords.y = hHeight - i;
		imageStore(imgOutput, pixelCoords, pixel);
		if (i > height) {
			pixel *= 0.3;
		}
		pixelCoords.y = hHeight + i;
		imageStore(imgOutput, pixelCoords, pixel);
	}
}
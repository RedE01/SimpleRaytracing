#version 430
layout(local_size_x = 1, local_size_y = 1) in;
layout(rgba32f, binding = 0) uniform image2D img_output;

uniform vec3 spherePos;
uniform vec3 lightPos;

void main() {
	vec4 pixel = vec4(0.0, 0.0, 0.0, 1.0);
	ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);
	
	float max_x = 5.0;
	float max_y = 5.0;
	ivec2 dims = imageSize(img_output); // fetch image dimensions
	float x = (float(pixel_coords.x * 2 - dims.x) / dims.x);
	float y = (float(pixel_coords.y * 2 - dims.y) / dims.y);
	vec3 ray_o = vec3(x * max_x, y * max_y, 0.0);
	vec3 ray_d = normalize(vec3(sin(x), 0, cos(x)) + vec3(0, sin(y), cos(y)));
	
	for (int i = 0; i < 2; ++i) {
		vec3 sphere_c = spherePos + vec3(3.0, 0.0, 0.0) * i;
		float sphere_r = 1.0;

		vec3 omc = ray_o - sphere_c;
		float b = dot(ray_d, omc);
		float c = dot(omc, omc) - sphere_r * sphere_r;
		float bsqmc = b * b - c;

		if (bsqmc >= 0.0) {
			float t = sqrt(bsqmc) - b;
			vec3 hitPoint = ray_o + ray_d * t;
			vec3 normal = normalize(hitPoint - sphere_c);
			float angle = dot(normal, lightPos) / 32.0;
			pixel = vec4(angle, angle, angle, 1.0);
		}
	}
	imageStore(img_output, pixel_coords, pixel);
}
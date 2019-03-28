#include <iostream>
#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <fstream>

double mXpos = -1, mYpos = -1, mDeltaX = 0, mDeltaY = 0;

static void cursor_position_callback(GLFWwindow* window, double xpos, double ypos) {
	if (mXpos != -1) {
		mDeltaX = xpos - mXpos;
		mDeltaY = ypos - mYpos;
	}
	mXpos = xpos;
	mYpos = ypos;
}

void move(float& x, float& z, float angle, float speed, int* map) {
	float movementZ = std::cos(angle) * speed;
	float movementX = std::sin(angle) * speed;

	if (!map[(int)(x + movementX) + (int)(z) * 10]) {
		x += movementX;
	}

	if (!map[(int)(x) + (int)(z + movementZ) * 10]) {
		z += movementZ;
	}
}

int main(void) {
	GLFWwindow* window;

	if (!glfwInit())
		return -1;

	window = glfwCreateWindow(1280, 720, "Raytracing", NULL, NULL);
	if (!window) {
		glfwTerminate();
		return -1;
	}

	glfwMakeContextCurrent(window);
	if (GLEW_OK != glewInit())
		std::cout << "FAILED GLEW INIT" << std::endl;

	glfwSetCursorPosCallback(window, cursor_position_callback);
	glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
	glfwSwapInterval(1);

	int texW = 1280, texH = 720;
	GLuint textureID;
	glGenTextures(1, &textureID);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, textureID);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, texW, texH, 0, GL_RGBA, GL_FLOAT, NULL);
	glBindImageTexture(0, textureID, 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RGBA32F);

	std::ifstream stream("src/ComputeShader.glsl");
	std::string computeShaderSourceString((std::istreambuf_iterator<char>(stream)), std::istreambuf_iterator<char>());
	const char* computeShaderSource = computeShaderSourceString.c_str();

	GLuint rayShader = glCreateShader(GL_COMPUTE_SHADER);
	glShaderSource(rayShader, 1, &computeShaderSource, NULL);
	glCompileShader(rayShader);

	GLint params;
	glGetShaderiv(rayShader, GL_COMPILE_STATUS, &params);
	std::cout << "shaderiv: " << params << std::endl;

	GLuint rayProgram = glCreateProgram();
	glAttachShader(rayProgram, rayShader);
	glLinkProgram(rayProgram);
	glUseProgram(rayProgram);

	glDeleteShader(rayShader);

	GLint lookDirUniformLocation = glGetUniformLocation(rayProgram, "lookDir");
	GLint posUniformLocation = glGetUniformLocation(rayProgram, "pos");
	GLint lightPosUniformLocation = glGetUniformLocation(rayProgram, "lightPos");
	glUniform1i(glGetUniformLocation(rayProgram, "reflections"), 10);
	glUniform1f(glGetUniformLocation(rayProgram, "rayDelta"), 0.01f);

	float lightPos[3] = { 5.5f, 0, 5.5f };
	glUniform3fv(lightPosUniformLocation, 1, lightPos);

	int map[100] = {
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 0, 0, 0, 0, 1, 0, 0, 0, 1,
		1, 0, 0, 1, 0, 0, 0, 0, 0, 1,
		1, 0, 0, 0, 1, 2, 1, 0, 0, 1,
		1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
		1, 0, 0, 1, 0, 0, 0, 1, 0, 1,
		1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
		1, 1, 0, 2, 0, 0, 0, 1, 0, 1,
		1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
		1, 1, 1, 1, 1, 2, 1, 1, 1, 1
	}; // 1 is wall, 2 is mirror

	GLint mapUniformLocation = glGetUniformLocation(rayProgram, "map");
	glUniform1iv(mapUniformLocation, 100, map);
	
	const char* vertShaderSource = {
		"#version 330 core\n"
		"layout(location = 0) in vec3 aPos;\n"
		"layout(location = 1) in vec2 aTex;\n"
		"out vec2 texCoord;\n"
		"void main() {\n"
		"	gl_Position = vec4(aPos, 1.0f);\n"
		"	texCoord = aTex;\n"
		"}"
	};

	const char* fragShaderSource = {
		"#version 330 core\n"
		"out vec4 FragColor;\n"
		"in vec2 texCoord;\n"
		"uniform sampler2D ourTexture;\n"
		"void main() {\n"
			"FragColor = texture(ourTexture, texCoord);\n"
		"}"
	};
		
	GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(vertexShader, 1, &vertShaderSource, NULL);

	GLuint fragShader = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(fragShader, 1, &fragShaderSource, NULL);

	glCompileShader(vertexShader);
	glCompileShader(fragShader);

	GLuint program = glCreateProgram();

	glAttachShader(program, vertexShader);
	glAttachShader(program, fragShader);

	glLinkProgram(program);
	glUseProgram(program);

	glDeleteShader(vertexShader);
	glDeleteShader(fragShader);

	float vertexData[] {
		-1.0f, -1.0f, 0.0f, 0.0f, 0.0f,
		 1.0f, -1.0f, 0.0f, 1.0f, 0.0f,
		 1.0f,  1.0f, 0.0f, 1.0f, 1.0f,
		-1.0f,  1.0f, 0.0f, 0.0f, 1.0f
	};

	GLuint vertexBuffer;
	glGenBuffers(1, &vertexBuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);

	unsigned int indexData[] {
		0, 1, 2,
		2, 3, 0
	};

	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 5, (void*)0);
	glEnableVertexAttribArray(1);
	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 5, (void*)(3 * sizeof(float)));

	GLuint indexBuffer;
	glGenBuffers(1, &indexBuffer);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(unsigned int) * 6, indexData, GL_STATIC_DRAW);

	double previousFrame = 0, timer = 0;
	int frames = 0;
	float lookDir = 0, pX = 5, pZ = 5;

	while (!glfwWindowShouldClose(window)) {
		double currentFrame = glfwGetTime();
		double deltaTime = (currentFrame - previousFrame);
		previousFrame = currentFrame;

		++frames;
		timer += deltaTime;
		if (timer > 1) {
			std::cout << "fps: " << frames << std::endl;
			frames = 0;
			timer -= 1;
		}

		if (glfwGetKey(window, GLFW_KEY_ESCAPE)) glfwSetWindowShouldClose(window, true);
		if (glfwGetKey(window, GLFW_KEY_W)) move(pX, pZ, lookDir, deltaTime * 2, map);
		if (glfwGetKey(window, GLFW_KEY_S)) move(pX, pZ, lookDir, deltaTime * -2, map);
		if (glfwGetKey(window, GLFW_KEY_A)) move(pX, pZ, lookDir + 90, deltaTime * 2, map);
		if (glfwGetKey(window, GLFW_KEY_D)) move(pX, pZ, lookDir - 90, deltaTime * 2, map);
		lookDir -= mDeltaX * 0.001;

		glUseProgram(rayProgram);
		glUniform1f(lookDirUniformLocation, lookDir);
		glUniform3f(posUniformLocation, pX, 0, pZ);
		glDispatchCompute((GLuint)texW, 1, 1);

		glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);

		/* Render here */
		glClear(GL_COLOR_BUFFER_BIT);
		glUseProgram(program);
		glBindTexture(GL_TEXTURE_2D, textureID);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

		mDeltaX = mDeltaY = 0;
		glfwSwapBuffers(window);
		glfwPollEvents();
	}

	glfwTerminate();
	return 0;
}
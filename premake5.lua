workspace "OpenGLRaytracing"
	architecture "x86_64"
	configurations { "Debug", "Release" }

project "OpenGLRaytracing"
	location "OpenGLRaytracing"
	kind "ConsoleApp"
	language "C++"
	targetdir "bin/%{cfg.buildcfg}"
	objdir "bin-int/%{cfg.buildcfg}"
	systemversion "latest"
	defines "GLEW_STATIC"

	files {
		"OpenGLRaytracing/src/**.h",
		"OpenGLRaytracing/src/**.cpp",
		"OpenGLRaytracing/src/**.c"
	}

	includedirs {
		"OpenGLRaytracing/vendor/GLEW/include",
		"OpenGLRaytracing/vendor/GLFW/include",
		"OpenGLRaytracing/vendor/stb"
	}

	libdirs {
		"OpenGLRaytracing/vendor/GLEW/lib/Release/x64",
		"OpenGLRaytracing/vendor/GLFW/lib"
	}

	links {
		"glfw3.lib",
		"glew32s.lib",
		"opengl32.lib"
	}

	filter "configurations:Debug"
		defines { "DEBUG" }
		symbols "On"
		runtime "Debug"
	filter "configurations:Release"
		optimize "On"
		runtime "Release"
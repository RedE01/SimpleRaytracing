workspace "OpenGLRaytracing"
	architecture "x64"
	configurations { "Debug", "Release" }

project "OpenGLRaytracing"
	location "OpenGLRaytracing"
	kind "ConsoleApp"
	language "C++"
	targetdir "bin/%{cfg.buildcfg}"
	objdir "bin-int/%{cfg.buildcfg}"
	systemversion "latest"

	files {
		"src/**.h",
		"src/**.cpp",
		"src/**.c"
	}

	includedirs {
		"OpenGLRaytracing/vendor/GLEW/include",
		"%{prj.name}/vendor/GLFW/include"
	}

	libdirs {
		"OpenGLRaytracing/vendor/GLEW/lib/Release/x64",
		"%{prj.name}/vendor/GLFW/lib"
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
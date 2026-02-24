allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix for plugins (e.g. isar_flutter_libs) that don't set namespace (required by AGP 8+)
subprojects {
    afterEvaluate {
        // Use the BaseExtension to cover both Library and App extensions safely
        val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (android != null && android.namespace == null) {
            // Falls back to the project group if no namespace is defined
            android.namespace = project.group.toString()
        }
    }
}

// Custom build directory configuration (often used in Lovable/Cursor projects)
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Set subproject build directories relative to the new root build directory
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Ensure the app module is evaluated first for dependency resolution
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
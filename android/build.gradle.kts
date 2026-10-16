allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        val androidExtension = extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
        if (androidExtension != null && androidExtension.namespace == null) {
            androidExtension.namespace = project.group.toString().takeIf { it.isNotEmpty() } ?: "dev.flutter.plugins.${project.name}"
        }
    }
}

gradle.projectsEvaluated {
    rootProject.subprojects {
        tasks.matching { it.name.contains("verifyReleaseResources", ignoreCase = true) }.configureEach {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

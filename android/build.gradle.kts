allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Plugins live in the pub cache (C:), while this project is on E:. Redirecting their
    // build dir across drives breaks AGP/Kotlin relative-path resolution
    // ("this and base files have different roots"), so only redirect same-drive projects.
    if (project.projectDir.toPath().root == rootProject.projectDir.toPath().root) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

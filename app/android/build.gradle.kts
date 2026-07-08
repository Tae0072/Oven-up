allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// 일부 플러그인(portone_flutter 등)이 낮은 compileSdk(34)로 잡혀 있어
// 최신 라이브러리(app_links 등)와 충돌한다 → 라이브러리 모듈의 compileSdk를 36으로 통일.
fun fixLibraryCompileSdk(p: Project) {
    val androidExt = p.extensions.findByName("android")
    if (androidExt is com.android.build.gradle.LibraryExtension) {
        val current = androidExt.compileSdk
        if (current == null || current < 36) {
            androidExt.compileSdk = 36
        }
    }
}

subprojects {
    if (state.executed) {
        fixLibraryCompileSdk(this)
    } else {
        afterEvaluate { fixLibraryCompileSdk(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

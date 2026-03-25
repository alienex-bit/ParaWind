// Redirect build outputs so Flutter tool finds APKs at build/app/...
rootProject.layout.buildDirectory.set(rootDir.resolve("../build"))

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    layout.buildDirectory.set(rootDir.resolve("../build/${project.name}"))
}

subprojects {
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

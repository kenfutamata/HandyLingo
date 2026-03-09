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

// --- UPDATED FIX FOR NAMESPACE ERROR (Supports early evaluation) ---
subprojects {
    val applyNamespaceFix = {
        if (project.hasProperty("android")) {
            try {
                val android = project.extensions.getByName("android")
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)

                if (getNamespace.invoke(android) == null) {
                    val sanitizedName = project.name.replace("-", "_").replace(".", "_")
                    setNamespace.invoke(android, "com.handylingo.fix.$sanitizedName")
                    println("Applied namespace fix to: ${project.name}")
                }
            } catch (e: Exception) {
                // Ignore if method is missing or extension isn't found
            }
        }
    }

    // If the project is already evaluated (due to evaluationDependsOn), run it now.
    // Otherwise, schedule it for after evaluation.
    if (project.state.executed) {
        applyNamespaceFix()
    } else {
        project.afterEvaluate { applyNamespaceFix() }
    }
}
// --- END OF FIX ---

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
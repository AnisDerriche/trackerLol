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
    afterEvaluate {
        // Ensure the SDK location is correctly set
        val localProperties = rootProject.file("local.properties")
        if (localProperties.exists()) {
            val properties = java.util.Properties()
            localProperties.inputStream().use { properties.load(it) }
            val sdkDir = properties.getProperty("sdk.dir")
            if (sdkDir.isNullOrEmpty()) {
                throw GradleException("SDK location not found. Define a valid SDK location in local.properties.")
            }
        } else {
            throw GradleException("local.properties file not found. Please create one and define the sdk.dir path.")
        }
    }
project.evaluationDependsOn(":app")
    }


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

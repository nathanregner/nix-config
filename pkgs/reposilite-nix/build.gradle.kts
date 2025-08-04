import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar

plugins {
    // Apply the org.jetbrains.kotlin.jvm Plugin to add support for Kotlin.
    alias(libs.plugins.kotlin.jvm)

    // Apply the java-library plugin for API and implementation separation.
    `java-library`

    id("com.gradleup.shadow") version "8.3.5"
}

repositories {
    // Use Maven Central for resolving dependencies.
    mavenCentral()
    maven {
        url = uri("https://maven.reposilite.com/releases/")
    }
}

dependencies {
    // This dependency is exported to consumers, that is to say found on their compile classpath.
    api(libs.commons.math3)

    // This dependency is used internally, and not exposed to consumers on their own compile classpath.
    implementation(libs.guava)

    compileOnly(libs.reposiliteBackend)

    // FIXME
    implementation(libs.reposiliteBackend)
}

testing {
    suites {
        // Configure the built-in test suite
        val test by getting(JvmTestSuite::class) {
            // Use Kotlin Test test framework
            useKotlinTest("2.1.20")
        }
    }
}

// Apply a specific Java toolchain to ease working on different environments.
java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

tasks.withType<ShadowJar> {
    archiveFileName.set("example-plugin.jar")
    // destinationDirectory.set(file("$rootDir/reposilite-backend/src/test/workspace/plugins"))
    mergeServiceFiles()
}

gradle.settingsEvaluated(Action {
    throw RuntimeException( "NO" )
    settings.dependencyResolutionManagement {
        repositoriesMode = RepositoriesMode.PREFER_SETTINGS

        repositories {
            repositories.forEach {
                if (it is MavenArtifactRepository) {
                    it.url = uri("https://maven.nregner.net/whatever/")
                }
            }
        }
    }
})

import com.github.benmanes.gradle.versions.updates.DependencyUpdatesTask

initscript {
  repositories {
    gradlePluginPortal()
  }
  dependencies {
    classpath("com.github.ben-manes:gradle-versions-plugin:+")
  }
}

val STABLE_VERSION = "^[0-9,.v-]+(-r)?$".toRegex()

fun isStable(version: String): Boolean {
  val stableKeyword = listOf("RELEASE", "FINAL", "GA").any { version.uppercase().contains(it) }
  val stableVersion = STABLE_VERSION.matches(version)
  return stableKeyword || stableVersion
}

allprojects {
  apply<com.github.benmanes.gradle.versions.VersionsPlugin>()

  tasks.named<DependencyUpdatesTask>("dependencyUpdates").configure {
    rejectVersionIf {
      isStable(currentVersion) && !isStable(candidate.version)
    }
  }
}

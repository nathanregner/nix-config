import com.github.benmanes.gradle.versions.updates.DependencyUpdatesTask

initscript {
  repositories {
    gradlePluginPortal()
  }
  dependencies {
    classpath("com.github.ben-manes:gradle-versions-plugin:+")
  }
}

allprojects {
  apply<com.github.benmanes.gradle.versions.VersionsPlugin>()

  tasks.named<DependencyUpdatesTask>("dependencyUpdates").configure {
    // configure the task, for example wrt. resolution strategies
  }
}

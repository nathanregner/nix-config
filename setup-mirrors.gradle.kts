import groovy.json.JsonSlurper
import org.apache.groovy.json.internal.LazyMap
import org.gradle.api.artifacts.ArtifactRepositoryContainer.DEFAULT_MAVEN_CENTRAL_REPO_NAME

@Suppress("UnstableApiUsage")
gradle.settingsEvaluated {
//    apply(from = "../gradlew")
//    providers.fileContents(Provider<File> { file("/home/nregner/test.json") })
    val home = providers.environmentVariable("HOME").get()
    println(home)
    val mirrors = layout.rootDirectory.file("$home/mirrors.json").asFile
    val jsonObject = JsonSlurper().parseText(mirrors.readText()) as LazyMap
    println(jsonObject["repositories"])

    val toDeclare2 = settings.pluginManagement.repositories.mapNotNull {
        println(it.name)
        if (it is MavenArtifactRepository) {
            it
        } else {
            null
        }
    }
    settings.pluginManagement {
        repositories {
            clear()

        }
    }
    settings.dependencyResolutionManagement {
        repositoriesMode = RepositoriesMode.PREFER_SETTINGS

        repositories {
            // Clear existing repositories if you want to enforce your mirrors

            val toDeclare = repositories.mapNotNull {
                println(it.name)
                if (it is MavenArtifactRepository) {
                    it
//                    it.url = uri("1")
                } else {
                    null
                }
            }

            clear()

            (toDeclare + toDeclare2).forEach {
                maven {
//                    name = it.name
                    url = it.url
                    isAllowInsecureProtocol = true
                }
            }

//            maven {
//                name = DEFAULT_MAVEN_CENTRAL_REPO_NAME
//                url = uri("https://maven.nregner.net/repo1.maven.org")
//                isAllowInsecureProtocol = true
//            }

            // Add other repositories as needed, e.g., for plugins
            // maven {
            //     name "GradlePluginPortalMirror"
            //     url "https://your.internal.mirror/repository/gradle-plugins/"
            // }
        }
    }
}

//gradle.addProjectEvaluationListener(object : ProjectEvaluationListener {
//    override fun beforeEvaluate(project: Project) {
//        TODO("Not yet implemented")
//    }
//
//    override fun afterEvaluate(project: Project, state: ProjectState) {
//        TODO("Not yet implemented")
//    }
//})



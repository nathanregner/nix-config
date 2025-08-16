package net.nregner.reposilite.plugin.nix

import com.fasterxml.jackson.module.kotlin.readValue
import com.reposilite.ReposiliteObjectMapper
import com.reposilite.configuration.shared.SharedConfigurationFacade
import com.reposilite.maven.application.MavenSettings
import com.reposilite.maven.application.MirroredRepositorySettings
import com.reposilite.maven.application.RepositorySettings
import com.reposilite.plugin.api.Facade
import com.reposilite.plugin.api.Plugin
import com.reposilite.plugin.api.ReposilitePlugin
import com.reposilite.plugin.facade
import java.io.File
import kotlin.time.Duration.Companion.minutes

@Plugin(name = "nix", dependencies = ["maven"])
class NixPlugin(
    private val proxiedRepositories: String = System.getenv("REPOSILITE_PROXIED_REPOSITORIES") ?: throw IllegalStateException("Must specify REPOSILITE_PROXIED_REPOSITORIES")
) : ReposilitePlugin() {

    override fun initialize(): Facade? {
        val facade = facade<SharedConfigurationFacade>()
        ReposiliteObjectMapper.DEFAULT_OBJECT_MAPPER.writeValueAsString(facade)

        val proxied = ReposiliteObjectMapper.DEFAULT_OBJECT_MAPPER.readValue<List<MirroredRepositorySettings>>(
            File(proxiedRepositories).readText()
        )

        val mavenSettings = facade.getDomainSettings<MavenSettings>()
        mavenSettings.update({ old ->
            val repository = RepositorySettings(
                id = "proxied",
                metadataMaxAge = 15.minutes.inWholeSeconds,
                proxied = proxied
            )

            old.copy(
                repositories = old.repositories.associateByTo(mutableMapOf()) { it.id }
                    .also { repositories -> repositories[repository.id] = repository }
                    .values
                    .toList()
            )
        })

        return null
    }
}

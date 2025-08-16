package net.nregner.reposilite.plugin.nix

import com.reposilite.configuration.application.ConfigurationComponents
import com.reposilite.configuration.shared.SharedConfigurationFacade
import com.reposilite.configuration.shared.SharedSettingsProvider
import com.reposilite.configuration.shared.application.SharedConfigurationComponents
import com.reposilite.journalist.backend.AggregatedLogger
import com.reposilite.journalist.backend.PrintStreamLogger
import com.reposilite.maven.application.MavenSettings
import com.reposilite.plugin.Extensions
import com.reposilite.plugin.api.ReposilitePlugin.ReposilitePluginAccessor
import com.reposilite.status.FailureFacade
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import panda.std.reactive.mutableReference
import java.io.File
import java.nio.file.Path

class NixPluginTest {

    private val nixPlugin = NixPlugin()

    @TempDir
    lateinit var workingDirectory: File

    private val logger = PrintStreamLogger(System.out, System.err)
    private val extensions = Extensions(AggregatedLogger(logger, PrintStreamLogger(System.out, System.err)))
    private lateinit var sharedConfigurationFacade: SharedConfigurationFacade

    @BeforeEach
    fun prepare() {
        sharedConfigurationFacade = SharedConfigurationComponents(
            journalist = logger,
            workingDirectory = workingDirectory.toPath(),
            extensions = Extensions(logger),
            sharedConfigurationPath = Path.of("shared.json"),
            failureFacade = FailureFacade(logger),
            configurationFacade = ConfigurationComponents().configurationFacade()
        ).sharedConfigurationFacade(
            sharedSettingsProvider = SharedSettingsProvider(
                mapOf(
                    MavenSettings::class.java to mutableReference(
                        MavenSettings()
                    )
                )
            ),
        )

        extensions.registerFacade(sharedConfigurationFacade)
        ReposilitePluginAccessor.injectExtension(nixPlugin, extensions)
    }

    @Test
    fun name() {
        assertDoesNotThrow {
            val facade = nixPlugin.initialize()
            println(facade)
        }
    }
}


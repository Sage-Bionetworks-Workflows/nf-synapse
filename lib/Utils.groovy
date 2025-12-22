// groovy_utils.groovy

import java.nio.file.Paths

class Utils {
    static public def clean_uri(outdir) {
        // Use URI parsing to clean up redundant slashes while preserving all URI components
        def uri = new URI(outdir)

        // First ensure we have the required URI components
        if (!uri.scheme) {
            throw new Exception("There must be a scheme in the URI (e.g., s3://)")
        }

        // Combine authority and path based on URI structure
        def fullPath
        if (uri.authority) {
            fullPath = uri.authority + (uri.path ?: '')
        } else {
            fullPath = uri.path ?: ''
        }

        // Remove leading, trailing, and duplicate slashes from fullPath before returning
        def normalizedPath = fullPath.replaceAll('^/+', '').replaceAll('/+', '/').replaceAll('/+$', '')

        return "${uri.scheme}://${normalizedPath}"
    }

    static public def get_publish_dir(params, file_id) {
        def strategy_map = [
            "id_folders": { "${params.outdir_clean}/${file_id}" },
            "flat": { "${params.outdir_clean}" }
            // Add more strategies as needed: "another_strategy": { "path_for_another_strategy" }
        ]

        def strategy = strategy_map.getOrDefault(params.save_strategy, {
            def message = "Invalid save strategy: ${params.save_strategy}"
            throw new Exception(message)
        })

        return strategy.call()
    }
}

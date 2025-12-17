// groovy_utils.groovy

import java.nio.file.Paths

class Utils {
    static public def clean_uri(outdir) {
        // Use URI parsing to clean up redundant slashes while preserving all URI components
        def uri = new URI(outdir)

        // Clean up the path by removing duplicate slashes and trailing slash
        def cleanPath = (uri.path ?: '').replaceAll('/+', '/').replaceAll('/$', '')

        // Build clean URI based on whether it has authority (bucket name) or not
        if (uri.authority) {
            // Example: s3://bucket/path (bucket is authority, path is path)
            return "${uri.scheme}://${uri.authority}${cleanPath.startsWith('/') ? cleanPath : '/' + cleanPath}"
        } else {
            // Example: s3:///bucket/path (bucket is part of path, no authority)
            return "${uri.scheme}://${cleanPath.replaceAll('^/', '')}"
        }
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

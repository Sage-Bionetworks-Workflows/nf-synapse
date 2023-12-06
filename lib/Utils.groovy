// groovy_utils.groovy

class Utils {
    static public def get_publish_dir(params, file_id) {
        def strategy_map = [
            "default": { "${params.outdir_clean}/${file_id}/" },
            "simple": { "${params.outdir_clean}/" }
            // Add more strategies as needed: "another_strategy": { "path_for_another_strategy" }
        ]

        def strategy = strategy_map.getOrDefault(params.save_strategy, {
            def message = "Invalid save strategy: ${params.save_strategy}"
            throw new Exception(message)
        })

        return strategy.call()
    }
}

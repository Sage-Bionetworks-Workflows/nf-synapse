nextflow.enable.dsl = 2

// entry validation
valid_entry_points = ['synstage', 'synindex']
if (!params.entry) {
    error "Entry point must be specified using --entry. Select one of: ${valid_entry_points.join(', ')}"
}
if (!valid_entry_points.contains(params.entry)) {
    error "Invalid entry point: '${params.entry}'. Valid options are: ${valid_entry_points.join(', ')}"
}

// SYNSTAGE - Stage files from Synapse to Nextflow Tower S3 Bucket
include { SYNSTAGE } from './workflows/synstage.nf'

// SYNINDEX - Index files into Synapse from Nextflow Tower S3 Bucket
include { SYNINDEX } from './workflows/synindex.nf'

workflow {
    if (params.entry == 'synstage') {
        SYNSTAGE ()
    } else if (params.entry == 'synindex') {
        SYNINDEX ()
    } else {
        error "Invalid entry point: '${params.entry}'. Valid options are: '${valid_entry_points.join(', ')}'"
    }
}

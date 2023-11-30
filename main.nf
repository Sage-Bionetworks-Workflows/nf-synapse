nextflow.enable.dsl = 2

// Synstage - Stage files from Synapse to AWS S3
include { SYNSTAGE } from './subworkflows/synstage.nf'

workflow NF_SYNSTAGE {
    SYNSTAGE ()
}

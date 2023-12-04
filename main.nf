nextflow.enable.dsl = 2

// Synstage - Stage files from Synapse to Nextflow Tower S3 Bucket
include { SYNSTAGE } from './subworkflows/synstage.nf'

workflow NF_SYNSTAGE {
    SYNSTAGE ()
}

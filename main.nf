nextflow.enable.dsl = 2

// NF_SYNSTAGE - Stage files from Synapse to Nextflow Tower S3 Bucket
include { SYNSTAGE } from './workflows/synstage.nf'

workflow NF_SYNSTAGE {
    SYNSTAGE ()
}

// NF_SYNINDEX - Index files into Synapse from Nextflow Tower S3 Bucket
include { SYNINDEX } from './workflows/synindex.nf'

workflow NF_SYNINDEX {
    SYNINDEX ()
}

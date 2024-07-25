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

process SAY_HELLO {

    output: 
        stdout
    
    """
    echo 'Hello World!'
    """
}

process SAY_HELLO_2 {

    output: 
        stdout
    
    """
    echo 'Hello World 2!'
    """
}

workflow NF_HELLO_WORLD {
    SAY_HELLO()
    SAY_HELLO_2()
}

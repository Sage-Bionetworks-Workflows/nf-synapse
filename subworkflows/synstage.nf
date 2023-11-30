#!/usr/bin/env nextflow

// Ensure DSL2
nextflow.enable.dsl = 2

/*
========================================================================================
    SETUP PARAMS
========================================================================================
*/

input_file = file(params.input, checkIfExists: true)
workdir = "${workDir.parent}/${workDir.name}"
params.outdir = "${workDir.scheme}://${workdir}/synstage/"
outdir = params.outdir.replaceAll('/$', '')
/*
========================================================================================
    IMPORT MODULES
========================================================================================
*/

include { SYNAPSE_GET } from '../modules/synapse_get.nf'
include { SEVENBRIDGES_GET } from '../modules/sevenbridges_get.nf'
include { UPDATE_INPUT } from '../modules/update_input.nf'

workflow SYNSTAGE {
    // Parse Synapse URIs from input file
    synapse_uris = (input_file.text =~ 'syn://(syn[0-9]+)').findAll()    
    // Parse SBG URIs from input file
    sbg_uris = (input_file.text =~ 'sbg://([^,]+)').findAll()

    // Warning about input file lacking URIs
    if (synapse_uris.size() == 0 && sbg_uris.size() == 0) {
    message = "The input file (${params.input}) does not contain any Synapse " +
                "URIs (e.g., syn://syn98765432) or SevenBridges URIs " +
                "(e.g., sbg://63b717559fd1ad5d228550a0). Is this expected?"
    log.warn(message)
    }

    // Synapse channel
    ch_synapse_ids = Channel.fromList(synapse_uris).unique() // channel: [ syn://syn98765432, syn98765432 ]
    // SBG channel
    ch_sbg_ids = Channel.fromList(sbg_uris).unique() // channel: [ sbg://63b717559fd1ad5d228550a0, 63b717559fd1ad5d228550a0]

    params.name = workflow.runName
    run_name = params.name

    SYNAPSE_GET(ch_synapse_ids, outdir)
    //SEVENBRIDGES_GET(ch_sbg_ids, outdir)

    // Mix channels
    //ch_all_files = merge(SYNAPSE_GET.output, SEVENBRIDGES_GET.output)
    ch_all_files = SYNAPSE_GET.output
    // Convert Mixed URIs and staged locations into sed expressions
    ch_stage_sed = ch_all_files
    .map { uri, id, file -> /-e 's|\b${uri}\b|${outdir}\/${id}\/${file.name}|g'/ }
    .reduce { a, b -> "${a} ${b}" }
    ch_stage_sed.view()

    // Update input file with staged locations
    UPDATE_INPUT(input_file, ch_stage_sed, SYNAPSE_GET.output)

}






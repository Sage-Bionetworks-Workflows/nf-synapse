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
params.outdir_clean = params.outdir.replaceAll('/$', '')
params.input_parent_dir = input_file.parent
// Parse Synapse URIs from input file
params.synapse_uris = (input_file.text =~ 'syn://(syn[0-9]+)').findAll()    
// Parse SBG URIs from input file
params.sbg_uris = (input_file.text =~ 'sbg://([a-zA-Z0-9]+)').findAll()

/*
========================================================================================
    IMPORT MODULES
========================================================================================
*/

include { SYNAPSE_GET } from '../modules/synapse_get.nf'
include { SEVENBRIDGES_GET } from '../modules/sevenbridges_get.nf'
include { UPDATE_INPUT } from '../modules/update_input.nf'

workflow SYNSTAGE {

    // Warning if input file lacks URIs
    if (params.synapse_uris.size() == 0 && params.sbg_uris.size() == 0) {
        message = "The input file (${params.input}) does not contain any Synapse " +
                    "URIs (e.g., syn://syn98765432) or SevenBridges URIs " +
                    "(e.g., sbg://63b717559fd1ad5d228550a0). Is this expected?"
        log.warn(message)
    }

    // Synapse channel
    ch_synapse_ids = Channel.fromList(params.synapse_uris).unique() // channel: [ syn://syn98765432, syn98765432 ]

    // SBG channel
    ch_sbg_ids = Channel.fromList(params.sbg_uris).unique() // channel: [ sbg://63b717559fd1ad5d228550a0, 63b717559fd1ad5d228550a0]

    // Stage files
    SYNAPSE_GET(ch_synapse_ids)
    SEVENBRIDGES_GET(ch_sbg_ids)

    // Mix channels
    ch_all_files = SEVENBRIDGES_GET.output.mix(SYNAPSE_GET.output)

    // Convert Mixed URIs and staged locations into sed expressions
    ch_stage_sed = ch_all_files
    .map { uri, id, file -> /-e 's|\b${uri}\b|${params.outdir_clean}\/${id}\/${file.name}|g'/ }
    .reduce { a, b -> "${a} ${b}" }

    // Get Workflow Run Name for Publishing
    params.name = workflow.runName
    run_name = params.name

    // Update input file with staged locations
    UPDATE_INPUT(input_file, ch_stage_sed, run_name)
}

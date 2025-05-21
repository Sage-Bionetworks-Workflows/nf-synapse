# Contributing New Workflows

In order to contribute to `nf-synapse`, you will first need to either create a feature branch on the main repository (if you are a Sage Bionetworks employee) or fork the repository. Once you have a branch or fork, you can create a new workflow by following the steps below.

## Create New Modules

Before you create any new modules, be sure to look at those that already exist in the `modules/` directory. You may find that you can reuse or modify an existing module rather than creating a new one.

Based on the purpose of your workflow, you may need to create one or more modules. In this repository, a module is a [Nextflow process](https://nextflow.io/docs/latest/process.html) that performs a single task. For example, a module may be responsible for downloading a file from Synapse like in the `SYNAPSE_GET` module and emitting it's downloaded path. Create any modules necessary for your workflow and store them as individual `.nf` files with names that are lowercase representations of the name of the process you are creating.

## Create New Workflow

Once you have created all of the modules necessary for your workflow, you can create the workflow itself. Create a new workflow by adding a `.nf` file in the `workflows/` directory. This file should contain a single [Nextflow workflow](https://nextflow.io/docs/latest/workflow.html) that combines the modules you created in the previous step with any needed extra logic in between processes. Be sure to give your workflow and its file a unique name that describes the goal it is trying to achieve.

## Add New Workflow to `main.nf`

After your workflow is complete, you will need to add it to the `main.nf` file. Follow the examples already present to provide access to your workflow given a `params.entry` value:
1. Write a comment that describes the purpose of your workflow.
1. Add the `include` statement to import your workflow to `main.nf`.
1. Add your workflow to `main.nf`.

Example:
```nextflow
// Synstage - Stage files from Synapse to Nextflow Tower S3 Bucket
include { WORKFLOW_NAME } from './workflows/workflow_name.nf'

workflow {
    ...
    else if (params.entry == 'workflow_name') {
        WORKFLOW_NAME ()
    }
    ...
}
```

## Test Your Workflow Locally

Once your workflow is added to `main.nf` with a unique name, it is now accessible to be run with the `params.entry` parameter. If it is possible to do so, test the workflow on your local machine using the [Nextflow CLI](https://nextflow.io/docs/latest/cli.html#run). It will be much easier to debug any problems you encounter locally before running on Seqera Platform.
Example:
```
nextflow run main.nf -profile docker --entry <WORKFLOW_NAME>
```

## Test Your Workflow in Nextflow Tower

Using the [Tower CLI](https://help.tower.nf/latest/cli/), or the [Seqera Platform UI](https://help.tower.nf/latest/launch/launchpad/) run your workflow and ensure that it completes successfully and with the intended results. Be sure to provide the name of your branch as the `revision`(and the URL to your fork, if applicable) to the Tower run.

## Test Other Potentially Affected Workflows

After you have tested your workflow, be sure to test any other workflows that depend on the modules you have modified. This will help ensure that the changes you made do not have any unintended side effects.

## Update The README

Before submitting your pull request, update the `README.md` file to include a description of your workflow. Follow the example set by the `SYNSTAGE` and `SYNINDEX` sections and include all relavent information including a mermaid diagram describing the flow of data through the workflow.

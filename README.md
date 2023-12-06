# nf-synapse

A centralized repository of Nextflow workflows that interact with [Synapse](https://www.synapse.org/).

## Purpose

The purpose of this repository is to provide a collection of Nextflow workflows that interact with Synapse by leveraging the [Synapse Python Client](https://github.com/Sage-Bionetworks/synapsePythonClient). These workflows are intended to be used in a [Nextflow Tower](https://help.tower.nf/latest/) environment primarily, but they can also be executed using the [Nextflow CLI](https://nextflow.io/docs/latest/cli.html#run) on your local machine.

## Structure

This repository is organized as follows:
1. Individual process definitions, or modules, are stored in the `modules/` directory.
1. Modules are then combined into workflows, stored in the `workflows/` directory. These workflows are intended to capture the entire process of an interaction with Synapse.
1. Workflows are then represented in the `main.nf` script, which provides an entrypoint for running each workflow.

## Usage

Only one workflow can be used per `nf-synapse` run. The configuration for a workflow run will need to include which workflow you intend to use (indicated by specifying `entry`), along with all of the parameters required for that workflow.

In the example below, we provide the `entry` parameter `NF_SYNSTAGE` to indicate that we want to run the `NF_SYNSTAGE` workflow. We also provide the `input` parameter, which is required for `NF_SYNSTAGE`.

```
nextflow run main.nf -profile docker -entry NF_SYNSTAGE --input path/to/input.csv
```

## Authentication

For Nextflow Tower runs, you can configure your secrets using the [Tower CLI](https://help.tower.nf/23.2/cli/cli/) or the [Tower Web UI](https://help.tower.nf/23.2/). If you are running the workflow locally, you can configure your secrets within the [Nextflow CLI](https://nextflow.io/docs/latest/secrets.html).

### Synapse

All included workflows require a `SYNAPSE_AUTH_TOKEN` secret. You can generate a Synapse personal access token using [this dashboard](https://www.synapse.org/#!PersonalAccessTokens:). 

### Profiles

Current `profiles` included in this repository are:
1. `docker`: Indicates that you want to run the workflow using Docker for running process containers.
2. `conda`: Indicates that you want to use a `conda` environment for running process containers.

# Included Workflows

## `NF_SYNSTAGE`: Stage Synapse Files To AWS S3

### Purpose

The purpose of this workflow is to automate the process of staging Synapse and SevenBridges files to an accessible location (_e.g._ an S3 bucket). In turn, these staged files can be used as input for a general-purpose (_e.g._ nf-core) workflow that doesn't contain platform-specific steps for downloading data. This workflow is intended to be run first in preparation for other data processing workflows.

### Overview

`NF_SYNSTAGE` achieves its purpose by performing the following steps:

1. Extract all Synapse and SevenBridges URIs (_e.g._ `syn://syn28521174` or `sbg://63b717559fd1ad5d228550a0`) from a given text file.
1. Download the corresponding files from both platforms in parallel.
1. Replace the URIs in the text file with their staged locations.
1. Output the updated text file so it can serve as input for another workflow.

### Quickstart

The examples below demonstrate how you would stage Synapse files in an S3 bucket called `example-bucket`, but they can be adapted for other storage backends.

1. Prepare your input file containing the Synapse URIs. For example, the following CSV file follows the format required for running the [`nf-core/rnaseq`](https://nf-co.re/rnaseq/latest/usage) workflow.

    **Example:** Uploaded to `s3://example-bucket/input.csv`

    ```text
    sample,fastq_1,fastq_2,strandedness
    foobar,syn://syn28521174,syn://syn28521175,unstranded
    ```

1. Launch workflow using the [Nextflow CLI](https://nextflow.io/docs/latest/cli.html#run), the [Tower CLI](https://help.tower.nf/latest/cli/), or the [Tower web UI](https://help.tower.nf/latest/launch/launchpad/).

    **Example:** Launched using the Nextflow CLI

    ```console
    nextflow run main.nf -profile docker -entry NF_SYNSTAGE --input path/to/input.csv
    ```

1. Retrieve the output file, which by default is stored in a `synstage/` subfolder within the parent directory of the input file. The Synapse and/or Seven Bridges URIs have been replaced with their staged locations. This file can now be used as the input for other workflows.

    **Example:** Downloaded from `s3://example-bucket/synstage/input.csv`

    ```text
    sample,fastq_1,fastq_2,strandedness
    foobar,s3://example-scratch/synstage/syn28521174/foobar.R1.fastq.gz,s3://example-scratch/synstage/syn28521175/foobar.R2.fastq.gz,unstranded
    ```

### Special Considerations for Staging Seven Bridges Files

If you are staging Seven Bridges files, there are a few differences that you will want to incorporate in your Nextflow run. 

1. You will need to configure `SB_AUTH_TOKEN` and `SB_API_ENDPOINT` secrets.
  - You can generate an authenication token and retrieve your API endpoint by logging in to the Seven Bridges portal you intend to stage files from, such as [Seven Bridges CGC](https://cgc-accounts.sbgenomics.com/auth/login). From there, click on the "Developer" dropdown and then click "Authentication Token". A full list of Seven Bridges API endpoints can be found [here](https://sevenbridges-python.readthedocs.io/en/latest/quickstart/#authentication-and-configuration)
1. When adding your URIs to your input file, SevenBridges file URIs should have the prefix `sbg://`. 
1. There are two ways to get the ID of a file in SevenBridges:
   - The first way involves logging into a SevenBridges portal, such as [SevenBridges CGC](https://cgc-accounts.sbgenomics.com/auth/login), navigating to the file and copying the ID from the URL. For example, your URL might look like this: "https://cgc.sbgenomics.com/u/user_name/project/63b717559fd1ad5d228550a0/". From this url, you would copy the "63b717559fd1ad5d228550a0" piece and combine it with the `sbg://` prefix to have the complete URI `sbg://63b717559fd1ad5d228550a0`.
   - The second way involves using the [SBG CLI](https://docs.sevenbridges.com/docs/files-and-metadata). To get the ID numbers that you need, run the `sb files list` command and specify the project that you are downloading files from. A list of all files in the project will be returned, and you will combine the ID number with the prefix for each file that you want to stage.

Note: `NF_SYNSTAGE` can handle either or both types of URIs in a single input file.

### Parameters

Check out the [Quickstart](#quickstart) section for example parameter values.

- **`input`**: (Required) A text file containing Synapse URIs (_e.g._ `syn://syn28521174`). The text file can have any format (_e.g._ a single column of Synapse URIs, a CSV/TSV sample sheet for an nf-core workflow).

- **`outdir`**: (Optional) An output location where the Synapse files will be staged. Currently, this location must be an S3 prefix for Nextflow Tower runs. If not provided, this will default to the parent directory of the input file.

- **`save_strategy`**: (Optional) A string indicating where to stage the files within the `outdir`. Options include:
    - `default`: Files will be staged in child folders named after the Synapse or Seven Bridges ID of the file. This is the default behavior.
    - `simple`: Files will be staged in top level of the `outdir`.

### Known Limitations

- The only way for the workflow to download Synapse files is by listing Synapse URIs in a file. You cannot provide a list of Synapse IDs or URIs to a parameter.
- The workflow doesn't check if newer versions exist for the files associated with the Synapse URIs. If you need to force-download a newer version, you should manually delete the staged version.

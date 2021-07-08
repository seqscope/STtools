
# SeqScope Tools Introduction
STtools is an package that processing spatial transciriptomics data from various ST platform such as Seq-Scope and VISIUM. This pipleine includes data preprocessing, alignment, collapsing barcodes into 
gridded datasets and clustering based on classic Seurat methods. 

## Required operation system and sofware tools
Linux operatin system is necessary.
You need to install the following software tools before using this package .
* STARSolo>=2.7.5c
* seqtk
* R 
* Python >=3.0 (specify libraries)
* perl
* pigz

## Installation

## Input and Output Data Format
Please refer to [the link](https://github.com/jyxi7676/STtools/blob/main/doc/fileformats.md) for an illustration of required input data format and output data format for each step.

## Example Data
* SeqScope exmaple data for each step can be found at https://drive.google.com/file/d/1e0u57Yu_fVKFvs-UA7WYfj-vgm8Nd2y4/view?usp=sharing, please download the zip files. For each step, the example input data is stored in the corresponding subdirectories. 

* VISIUM digital expresstion data and spatial coordinates are available at https://drive.google.com/drive/folders/130ENNRBEi7kCOXDnGZlHUnuf4CD3_JEI?usp=sharing

## Overall Workflow

This image below shows the overall workflow for STtools. 

<p align="center">
    <img src="STtools_workflow.png" width="1550" height="700" />
</p>

There are 6 steps, each step takes input from either outputs from previous steps or the raw exapmle data. Please see a brief explanation about each step as follows:

* Step 1 takes fastq.gz files as input and output spatial coordinates .txt files and whitelist used for STARsolo alignemnt in the current working directory.
* Step 2 takes in fastq.gz file with barcode info and spatial coordinates file to generate a barcode/HDMI density plot which can be compared with HE images for an estimation of tissue boundary
* Step 3 takes whitelist.txt, transcriptomic fastq.gz files and reference genome as input and runs STARsolo alignment; this step outputs digital expression matrix
* Step 4 takes DGE from Step 3 and output Seurat object with collapsed DGE of simple square grids
* Step 5 takes DGE from Step 3 and output Seurat object with collapsed DGE of square grids from sliding window strategy
* Step 6 takes in RDS file from Step 4 and Step 5 as input and performs dimension reduction, clustering and conducts refernece mapping with simple square grids as query
* Step 7 takes DGE(Velocyto) from Step 3 and generate subcellular plots showing pattern of spliced/unspliced reads




## Getting Started
STtools commands are ran in the working directory and output files/plot will be stored in the working directory. The package have flexible options for the user to run either **from the step 1** or run for **consecutive steps** or for **one specific step**. Several examples from various scerios will be given for illustratrion. 
* [Automatic running all steps](./doc/readme1.md)
* [Running consecutive steps](./doc/readme2.md)
* [Running specific step](./doc/readme3.md)

## External links
Here are some useful external links:
* To instal seqtk: https://github.com/lh3/seqtk
* To install STAR: https://github.com/alexdobin/STAR
* To generate gene index for STARsolo alignment: https://hbctraining.github.io/Intro-to-rnaseq-hpc-O2/lessons/03_alignment.html
* Multimodal reference mapping: https://satijalab.org/seurat/articles/multimodal_reference_mapping.html
* Incoporate transgenes to alignment: add script for this?

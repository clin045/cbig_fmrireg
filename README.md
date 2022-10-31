# Snakemake workflow for the CBIG_preproc_native2mni step
This was written specifically for the NCG (neurocardiac guided TMS) trial. This workflow is meant to be equivalent to this CBIG configuration line:
```
CBIG_preproc_native2mni -down FSL_MNI_2mm -sm 6 -sm_mask ${CBIG_CODE_DIR}/data/templates/volume/FS_nonlinear_volumetric_space_4.5/SubcortCerebellumWhiteMask.GCA.t0.5_resampled.nii.gz -final_mask ${FSL_DIR}/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz
```
Please note that some of these options have been hardcoded into the workflow. Furthermore, the `CBIG_preproc_native2mni.csh` script from the official CBIG repo has been modified by Alex Cohen and Stephan Palm to perform smoothing with two different masks. The modified script this workflow is based on is included in this repo as `CBIG_preproc_native2mni_stephan.csh`.

## First time installation
First, clone this repository.

Install snakemake to a new environment:
```
mamba create -c conda-forge -c bioconda -n ncg snakemake
```
Install erisone snakemake profile



snakemake -np data/sub-3010_bld001_merged_sm6_finalmasked.nii.gz \
    data/sub-3010_bld002_merged_sm6_finalmasked.nii.gz \
    data/sub-3010_bld003_merged_sm6_finalmasked.nii.gz \
    data/sub-3010_bld004_merged_sm6_finalmasked.nii.gz \
    --keep-going --wait-for-files



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
```
mkdir ~/.config/snakemake/ && cp -r erisone ~/.config/snakemake/
```
## Processing a subject
This workflow expects a folder called ./data containing your preprocessed (unregistered) BOLD runs as well as the registration files. I.e., for each bold run, you should have these two files ready:
```
sub-3010_bld004_rest_skip4_stc_mc_reg.dat
sub-3010_bld004_rest_skip4_stc_mc_bp_0.0001_0.08.nii.gz
```
The easiest way to do this would be to symlink these files to your ./data directory.
```
ln -s /data/mfdc/R01_Official/CBIG/R01_CBIG_preprocessed/CBIG_fMRI_preprocess_preproc_CBIG_BWH/sub-3010/bold/*/sub-3010_bld*_rest_skip4_stc_mc_bp_0.0001_0.08.nii.gz .
ln -s /data/mfdc/R01_Official/CBIG/R01_CBIG_preprocessed/CBIG_fMRI_preprocess_preproc_CBIG_BWH/sub-3010/bold/*/sub-3010_bld*_rest_skip4_stc_mc_reg.dat.
```
Next, activate the conda environment and prep the environment variables:
```
conda activate ncg
source prep_env.sh
```
The final output of the workflow looks like
```
data/sub-3010_bld001_merged_sm6_finalmasked.nii.gz
```
Thus, for subject 3010 with 4 bold runs, use this command:
```
snakemake -np data/sub-3010_bld001_merged_sm6_finalmasked.nii.gz \
    data/sub-3010_bld002_merged_sm6_finalmasked.nii.gz \
    data/sub-3010_bld003_merged_sm6_finalmasked.nii.gz \
    data/sub-3010_bld004_merged_sm6_finalmasked.nii.gz \
    --keep-going --wait-for-files
```
If the workflow has never been run before, you should see that it registers 6 steps. This is because most of the rules are performed per-frame, and snakemake does not yet know how many frames there will be. Once the frame splitting step is performed, the DAG will be re-evaluated. 

If everything looks good, switch the `-np` dry run flag to `--profile erisone` to go!

```
# You can do this as-is on an interactive job

snakemake --profile erisone data/sub-3010_bld001_merged_sm6_finalmasked.nii.gz \
    data/sub-3010_bld002_merged_sm6_finalmasked.nii.gz \
    data/sub-3010_bld003_merged_sm6_finalmasked.nii.gz \
    data/sub-3010_bld004_merged_sm6_finalmasked.nii.gz \
    --keep-going --wait-for-files

# Or you should be able to submit it as a cluster job too. 
# Snakemake doesn't need high resources, but the cluster job needs to live as long as 
# the processing pipeline is running (8+ hours)

bsub -q normal snakemake --profile erisone data/sub-3010_bld001_merged_sm6_finalmasked.nii.gz \
    data/sub-3010_bld002_merged_sm6_finalmasked.nii.gz \
    data/sub-3010_bld003_merged_sm6_finalmasked.nii.gz \
    data/sub-3010_bld004_merged_sm6_finalmasked.nii.gz \
    --keep-going --wait-for-files
```

## Notes
- Everything is submitted via the `rerunnable` queue on erisone, which yields the best performance. However, these are liable to be interrupted, causing task failures. The `--keep-going` flag lets snakemake continue execution on independent jobs even after failure, however, you should rerun the pipeline after it appears to be complete just to ensure that all tasks have run. Alternatively, you could wrap it in an `until` loop: `until snakemake -np data/sub-3010_bld003_merged_sm6_finalmasked.nii.gz --keep-going; do echo "trying again"; done`
- Everything in the data/*frames/ directories should be temporary. I don't have it delete automatically in case the workflow needs to be rerun, but you should remove them to save space if the outputs are all good.
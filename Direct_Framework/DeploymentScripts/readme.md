# Deployment Scripts

Deployment scripts are used in DIRECT to allow for extended actions during deployments.

Certain scripts and certain actions need to run at different times during the deployment process.

The deployment scripts are broken down into 4 different folders to allow for this.

The scripts can either be run outside of the Dacpac process, by the CD pipeline, or inside the Dacpac process, by the Dacpac process itself.

The main script currently in use is the PostDeployment script, which populated the lookup tables with required base data.

Deployment scripts folders:

* 1-PreDacpacDeployment
* 2-PreDeployment
* 3-PostDeployment
* 4-PostDacpacDeployment

## 1-PreDacpacDeployment

This folder contains scripts that are run before the Dacpac process starts.

These scripts need to be configured to be run by the CD pipeline.

## 2-PreDeployment

This folder contains scripts that are run by the Dacpac process at the start of processing the Dacpac.

## 3-PostDeployment

This folder contains scripts that are run by the Dacpac process at the end of processing the Dacpac.

## 4-PostDacpacDeployment

This folder contains scripts that are run after the Dacpac process has completed.

These scripts need to be configured be to run by the CD pipeline.

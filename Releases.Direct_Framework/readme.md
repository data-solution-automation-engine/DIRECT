# Direct Framework Releases

A collection of current and older releases, which includes the database dacpacs and scripts.

These are organised in version directories, one for each historical release

The directory also holds the `next` and `current` releases.

The next directory holds the output from the current build of the Direct Framework solution. These files are used by the test harness to test the latest built changes and updates.

The current directory holds the currently released code version, which is what is upgraded from if one deploys the next release.

The upgrade testing tests the upgrade from the current to the next version to identify any issues with a straight upgrade. Any renamed columns or structural changes would need to be migrated before the state-based compare and deploy the dacpac uses would work.

Once a new release is added, the current contents goes to the folder for that version, the next output from the build engine becomes the current and future work goes into the next directory.

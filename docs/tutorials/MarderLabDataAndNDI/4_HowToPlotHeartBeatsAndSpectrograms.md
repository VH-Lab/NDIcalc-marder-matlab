# Tutorial 1 Marder Lab data and NDI

## 1.4 Plotting Heart Beats and Spectrograms for PPG data

### 1.4.1 Open an example session

Let's open an example session. Let's use our 994_13 example from before.

#### Code block 1.4.1:

```matlab
myDataPath = '/Users/vanhoosr/data/grace';
mySessionPath = fullfile(myDataPath,'994_13');
S = ndi.session.dir(mySessionPath);
```

Now let's list all of the subjects

#### Code block 1.4.2:

```matlab
sT = ndi.fun.docTable.subject(S)
```

For me, this returns:

#### Code block 1.4.3 (output only, don't type in)

```matlab
sT = 

  4x2 table

          SubjectDocumentIdentifier                SubjectLocalIdentifier       
    _____________________________________    ___________________________________

    {'412693a357d10010_c0c02febe68548fc'}    {'gdy_0013@marderlab.brandeis.edu'}
    {'412693a357d10565_c0d01f184e858a0a'}    {'gdy_0014@marderlab.brandeis.edu'}
    {'412693a357d10ace_c0cfda142fb3d8ae'}    {'gdy_0015@marderlab.brandeis.edu'}
    {'412693a357d10f57_40b3eae7d7d2dc09'}    {'gdy_0016@marderlab.brandeis.edu'}

```

### 1.4.2 Plot a summary of a whole PPG session

We can plot a summary of the whole session with the following code:

#### Code block 1.4.4:

```matlab
mlt.plot.HeartBeatsFromDocs(S)
mlt.plot.SpectrogramsFromDocs(S)
```

### 1.4.3 Get the heart beat data for a subject and sensor location

Use the `mlt.doc.*` functions. You can see the documentation for the heart beat fields by typing `help mlt.beats.beatdocs2struct`.

#### Code block 1.4.5

```matlab
[heartBeatDocs,HeartBeatData] = mlt.doc.getHeartBeats(S,'gdy_0013@marderlab.brandeis.edu','heart');

HeartBeatData{1}, % display the first structure

figure;
plot([HeartBeatData{1}.onset],[HeartBeatData{1}.instant_freq],'k-');
xlabel('Time (UTC)');
ylabel('Instantaneous frequency')
```

### 1.4.4 Get the spectrogram data for a subject and sensor location

#### Code block 1.4.5

```matlab
[SpectrogramDocs,SpectrogramData] = mlt.doc.getSpectograms(S,'gdy_0013@marderlab.brandeis.edu','heart');

SpectrogramData{1}, % display the first structure
mlt.plot.Spectrogram(SpectrogramData{1}.spec,SpectrogramData{1}.f,SpectrogramData{1}.ts);
```

### 1.4.5 Get the heart and spectrogram data all together!

```matlab
mySubjectData = mlt.doc.getHeartBeatAndSpectrogram(S,'gdy_0013@marderlab.brandeis.edu','heart');
mlt.plot.Traces(S,mySubjectData,1)
```

### 1.4.6 Notes:

The functions that read from local files where we initially stored the heart beat and spectrogram information are not recommended anymore. We will eventually remove them. These were quick and dirty treatments to get started looking at the data:

- `mlt.plot.HeartBeatsFromFiles` - Not recommended
- `mlt.plot.SpectrogramsFromFiles` - Not recommended
- `SpectrogramsBeatsOverlayFromFiles` - Not recommended

### 1.4.7 A comprehensive subject trace view

A single function, `mlt.plot.subjectTrace`, provides a comprehensive multi-panel plot that is ideal for detailed inspection of a recording. It combines the spectrogram, raw data trace, normalized data trace, and beat metrics into a single, time-linked figure.

#### Viewing a subject trace

You can generate a detailed trace for any subject and record type. For example, to view the 'heart' record for subject 'gdy_0014@marderlab.brandeis.edu', you can use the following command. The `showBeats` option is useful for visually correlating the detected beat onsets and offsets with the raw and normalized data traces.

```matlab
[ax,data]=mlt.plot.subjectTrace(S,'gdy_0014@marderlab.brandeis.edu','heart','showBeats',true)
```

This will produce a 6-panel plot that includes the spectrogram, the raw data, a z-scored normalized version of the raw data, and plots of the instantaneous beat frequency, amplitude, and duty cycle.

#### Interactive beat marking and curation

The `mlt.plot.subjectTrace` function also includes a powerful interactive mode for curating the beat data. This is essential for correcting errors in the automated beat detection process.

To activate the interactive mode, set the `markBeats` option to `true`:

```matlab
[ax,data]=mlt.plot.subjectTrace(S,'gdy_0014@marderlab.brandeis.edu','heart','showBeats',true,'markBeats',true)
```

When this mode is active, three buttons will appear below the normalized data plot:

*   **Bad**: Click this button to mark detected beats that are incorrect. A dialog will appear instructing you to click on the normalized data plot near the beats you want to remove. Each click will mark the nearest detected beat with a large gray 'X'. Press `Enter` when you are finished.
*   **Missing**: Click this button to add beats that the automated detection missed. A dialog will appear instructing you to click on the normalized data plot where a beat should have occurred. Each click will add a new "missing" beat, marked with a large green '+'. Press `Enter` when you are finished.
*   **Save**: Click this button to save your work. A file dialog will appear, allowing you to save the curated beat list to a `.mat` file. The saved file will contain a table with all beats and a 'Status' column indicating whether each beat was 'detected', 'marked bad', or 'marked missing'.
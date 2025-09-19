# Tutorial 1 Marder Lab data and NDI

## 1.3 Plotting Heart Beats and Spectrograms for PPG data

### 1.3.1 Open an example session

Let's open an example session. Let's use our 994_13 example from before.

#### Code block 1.3.1:

```matlab
myDataPath = '/Users/vanhoosr/data/grace';
mySessionPath = fullfile(myDataPath,'994_13');
S = ndi.session.dir(mySessionPath);
```

Now let's list all of the subjects

#### Code block 1.3.2:

```matlab
sT = ndi.fun.docTable.subject(S)
```

For me, this returns:

#### Code block 1.3.3 (output only, don't type in)

```matlab
sT =

  4×2 table

          SubjectDocumentIdentifier                SubjectLocalIdentifier       
    _____________________________________    ___________________________________

    {'412693a357d10010_c0c02febe68548fc'}    {'gdy_0013@marderlab.brandeis.edu'}
    {'412693a357d10565_c0d01f184e858a0a'}    {'gdy_0014@marderlab.brandeis.edu'}
    {'412693a357d10ace_c0cfda142fb3d8ae'}    {'gdy_0015@marderlab.brandeis.edu'}
    {'412693a357d10f57_40b3eae7d7d2dc09'}    {'gdy_0016@marderlab.brandeis.edu'}

```

### 1.3.2 Plot a summary of a whole PPG session

We can plot a summary of the whole session with the following code:

#### Code block 1.3.3:

```matlab
mlt.plot.HeartBeatsFromDocs(S)
mlt.plot.SpectrogramsFromDocs(S)
```




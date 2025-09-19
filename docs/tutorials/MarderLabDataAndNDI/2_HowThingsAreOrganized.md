# Tutorial 1 Marder Lab data and NDI

## 1.2 How we have been organizing things

### Where are the sessions?

For the time being, we have been storing the PPG sessions in zipped folders on a shared Google Drive.

Soon (overdue) this can all be in the cloud so it will get much easier.


### Opening a session

Let's use 994_13 as an example. Find the 994_13.zip file on the shared drive, download it, and put it on your disk where you'd like.


#### Code block 1.2.1:

```matlab
myDataPath = '/Users/vanhoosr/data/grace';
mySessionPath = fullfile(myDataPath,'994_13');
S = ndi.session.dir(mySessionPath);
```

Now you can list the subjects and look at the probes and epochs as in the [generic tutorial](1_ReadingGenericDataWithNDI.md).

### Importing new data into a session

The NDI team has been doing this for the moment. We will document this so we can hand it off.



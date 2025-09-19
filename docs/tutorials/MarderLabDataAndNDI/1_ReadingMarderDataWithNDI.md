#Tutorial 1 Marder Lab data and NDI

## 1.1 Reading Marder lab data with NDI

### About NDI

The Neuroscience Data Interface is a data interface that sits between data and analysis code. NDI presents scientific data so it is in the form of a database that can be accessed through an Application Programming Interface (API) and database queries.

See our documentation for:

1. [A short introduction to NDI](https://vh-lab.github.io/NDI-matlab/NDI-matlab/tutorials/ndimodel/1_intro/)
2. [Key concepts and vocabulary](https://vh-lab.github.io/NDI-matlab/NDI-matlab/tutorials/ndimodel/2_ndimodel_vocabulary/)

### Sessions and datasets

In NDI, data is organized into sessions and datasets. A dataset is comprised of a set of sessions. 

To open an existing session, one simply uses:

#### Code block 1.1:

```[matlab]
S = ndi.session.dir(path/to/your/session);
```

### Listing subjects in a session

We have a handy helper function to list all of the subjects in a session in a table, along with some information about the global treatments of those subjects:

#### Code block 1.2:
```[matlab]
sT = ndi.fun.docTable.subject(S)
```

### Seeing probes and elements

Text


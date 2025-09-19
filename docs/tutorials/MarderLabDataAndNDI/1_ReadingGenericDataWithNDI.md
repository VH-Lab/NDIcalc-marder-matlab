# Tutorial 1 Marder Lab data and NDI

## 1.1 Reading Generic lab data with NDI

### About NDI

The Neuroscience Data Interface is a data interface that sits between data and analysis code. NDI presents scientific data so it is in the form of a database that can be accessed through an Application Programming Interface (API) and database queries.

See our documentation for:

1. [A short introduction to NDI](https://vh-lab.github.io/NDI-matlab/NDI-matlab/tutorials/ndimodel/1_intro/)
2. [Key concepts and vocabulary](https://vh-lab.github.io/NDI-matlab/NDI-matlab/tutorials/ndimodel/2_ndimodel_vocabulary/)

### Sessions and datasets

In NDI, data is organized into sessions and datasets. A dataset is comprised of a set of sessions. 

To open an existing session, one simply uses:

#### Code block 1.1.1:

```matlab
S = ndi.session.dir(path/to/your/session);
```

### Listing subjects in a session

We have a handy helper function to list all of the subjects in a session in a table, along with some information about the global treatments of those subjects:

#### Code block 1.1.2:

```matlab
sT = ndi.fun.docTable.subject(S)
```

### Seeing probes and elements

Probes are anything that measures or stimulates a subject, and a session typically has many probe instances. To see the probes for your experiment, you can use

#### Code block 1.1.3:

```matlab
p = S.getprobes()
```

Elements are related to probes but they can also contain derived data. All probes are elements, some elements are probes. We can look at all the elements in our session like this:

#### Code block 1.1.4:

```matlab
e = S.elements()
```

You can examine the elements, which will be in a cell array, as follows:

#### Code block 1.1.5

```matlab

for i=1:numel(e)
    e{i} % display the element's information
end
```

### Listing the epochs of elements or probes

We can get the data for a probe or an element using the epochtable function.

#### Code block 1.1.6

```matlab
elementNumber = 10; % choose an element
et = e{elementNumber}.epochtable;

for i=1:numel(et),
    et(i) % display the epoch table entry
end
```

### Reading timeseries data from an element during an epoch

We can read the timeseries data from an element a few different ways. We can ask for the data in the local time coordinates of the data acquisition device very easily:


#### Code block 1.1.7
```matlab
epochNumber = 1;
[d,t] = e{elementNumber}.readtimeseries(epochNumber,-inf,inf); % read all times available
figure;
plot(t,d);
xlabel('Time(s)');
ylabel('Signal');
```


# Systems Programming 

*Target Case Study Project - Systems Programming*
<br>

## Case Study Overview

```
In our production environment, we don’t allow developers to SSH into servers without VP approval. Therefore, it is critical that our team provide tools to allow developers to debug problems using our monitoring tools.

For example, when we get an alert that a disk is getting full, you would want to know what files are using up all of the space.

Write a program in a language of your choice which will take a mount point as an argument and return a list of all the files on the mountpoint and their disk usage in bytes in json format.

Eg
    Command: getdiskusage.py /tmp  #<- "mountpoint"
    Output: {
        "files":
        [
            {"/tmp/foo", 1000},
            {"/tmp/bar", 1000000},
            {"/tmp/buzzz", 42},
        ],
    }
```

## Documentation
- [Mount Points](https://www.ibm.com/docs/en/aix/7.1?topic=mounting-mount-points)

## Requirements
- [PowerShell 5.1](https://www.microsoft.com/en-us/download/details.aspx?id=54616) or [higher](https://github.com/PowerShell/PowerShell/releases/tag/v7.2.5)

## Assumptions
- The mountpoint is a valid directory on the filesystem.
- The user running the program has permission to read the directory.
    - The user running the program has permission to read the files in the directory.
- The user running the program has permission to read the disk usage of the files in the directory.

## Exceptions
 - The mountpoint is not a directory.
    - Error will be thrown with a message indicating the mountpoint is not a directory.
 - The user running the program does not have permission to read the directory or the files within that directory.
    - Error will be thrown with a message indicating the user does not have permission to read the directory or the files within that directory.
- The user running the program does not have permission to read the disk usage of the files within that directory.
    - Error will be thrown with a message indicating the user does not have permission to read the disk usage of the files within that directory.

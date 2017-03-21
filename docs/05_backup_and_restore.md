## Backup and restore using an external provider

A process for backing up all the transactions occurred in a given node exists
and can be invoked via a *rake* task. Likewise, a restoring process can also be
used to download the transactions and apply them sequentially to a fresh node.

Both processes use the concept of a **provider**, which is just an abstraction
useful to represent the role of any service that can store and retrieve the
transactions using a well-defined file format.

For now, the only implemented provider is
[Internet Archive](https://archive.org/), but the system is flexible enough to
accommodate new providers as long as they adhere to a common interface.

### Transactions format
The exported transactions are represented internally using a JSON format that
follows this structure:

```json
{
  "status": "created",
  "date": "2016-06-02T08:37:53.768Z",
  "envelope": {
                // ... Envelope attributes ...
              }
}
```

As we can see it\'s basically a JSON object containing a couple of fields that
identify the type of transaction and when it happened, and the serialized
envelope attributes.

### Dump file format
In order to efficiently store the transactions in a dump file and allow an easy
retrieval in the future, we encode the transaction\'s JSON representation using
Base 64. This allows us to store them in a regular text file, each transaction
taking a single line.

After that, the dump file is compressed using Gzip. The resulting file is the
one that is finally uploaded to the backup provider.

So, to recap, the dump files are just gzipped text files that contain Base 64
encoded representations - separated by line breaks - of the transactions using
the format described above.

### Backup
The backup process is currently only able to create transaction dump files on a
daily basis. This means that you can create a dump file that contains the
transactions spanning a single day.

The rake task to backup the transactions can be executed as follows:

```
bin/rake dumps:backup[2016-06-09]
```

The date argument represents the day we want to backup in ISO 8601 format
(`YYYY-MM-DD`), and is optional (if omitted the default is the previous day).

Once the task has completed, a new dump file named `dump-2016-06-09.txt.gz` will
be created in the `tmp/dumps` folder and automatically uploaded to archive.org.

Keep in mind that, if the dump had been previously created, the task will return
an error, as the system does not allow rewriting dump files once they have been
uploaded.

We suggest creating a scheduled task, cron job or equivalent facility in
order to execute the backup task daily. For example, a cron job could simply
execute `bin/rake dumps:backup` every day at 1AM and it would take care of
dumping and uploading the transactions that were recorded the day before.

### Restore
The restore process is very similar to the backup process. It also accepts a
date as a task argument - default is previous day as well - but in this case it
represents the date we want to start restoring from. So if we execute something
like:

```
bin/rake dumps:restore[2016-06-01]
```

it will try to download and restore all dump files from June 1, 2016 to the
present day.

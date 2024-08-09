A small script which accepts *one* argument, being a ZFS dataset, lists all snapshots and their cumulative size, and interactively offers to destroy them.

Works great for home use, with some safeguards built in, but not production-ready. For example, my pool name is hardcoded on line 16.

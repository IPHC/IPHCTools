IPHCTools
=========

Misc tools for grid management, disk monitoring, DPM harvesting, ...

Octopus
-------

A tool for monitoring large sets of Crab 2.x tasks
- Automatically create multicrab.cfg files
- Produce summary tables of number of jobs submitted/running/aborted/done/cleared
- Automatically resubmit crashed jobs

UIDisksMonitoring
-----------------

A tool to check disk usage on the UI, generating a HTML/Javascript page

DPMharvester
------------

A tool to copy bunches of NTuples to the UIs
- Ignore duplicated NTuples (take the most recent one)
- Doesn't transfer already existing file (easier to relaunch if proxy expired)

# coverage-merger
store and send merged test coverage to coveralls 

Allows to merge reports for multiple projects.

##System dependencies: `nodejs unzip inotify-tools`
##Installation: `npm install` or `yarn`
##Usage:
Provide proper `.conf` file, similar to `lisk.conf`.
- REPO_URL: url to repository (used for git clone)
- REPO_NAME: url repository name
- REPORT_CREATION_DIR: path, where the report was created 
- REPO_TOKEN= coveralls token for repository

Run watch for reports for specific project:
`bash watch_coverages.sh example-repo.conf [false]`
where the second argument is the option to reset all previously stored data.

data is for each project is stored in separate directory. Every project directory has:
- coverages: coverages are stored
- logs: where the logs are kept
- chunks: unpacked coverages taken for merged report
- merged-report: output coverage

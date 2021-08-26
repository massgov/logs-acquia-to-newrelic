Fetch logs from Acquia Logstream, massage, and POST to New Relic Logs.

#### Usage

./index.php mass:logstream --logtypes=varnish-request

- Other logtypes can be fetched but their records are not parsed correctly as they dont get delivered in JSON but rather in unparsed log lines.
- Redirect stdOut if you dont want to see log lines in the console.

#### Required Environment variables
- AC_API2_KEY
- AC_API2_SECRET
- AC_API_ENVIRONMENT_UUID (see Prod entry in self.site.yml)
- NR_LICENSE_KEY

## Docker image
See [Docker Hub](https://hub.docker.com/repository/docker/massgov/logs-acquia-to-newrelic) for a containerized version of this command.

To manually build and push a new version of the container to Docker Hub:
1. From the latest main branch, run `docker build -t massgov/logs-acquia-to-newrelic:latest`.
2. Run `docker push massgov/logs-acquia-to-newrelic:latest`.

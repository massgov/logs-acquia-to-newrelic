# Logs Acquia to New Relic

## Table of Contents
- [Overview](#overview)
- [Project Contacts](#project-contacts)
- [Knowledge History](#knowledge-history)


## Overview
Fetch logs from Acquia Log stream, massage, and POST to New Relic Logs.


## Project Contacts

| Name     | Role  | Email                                                               |
|----------|-------|---------------------------------------------------------------------|
| SSR-Team | Infra | [EOTSS-DL-DigitalSSR@mass.gov](mailto:EOTSS-DL-DigitalSSR@mass.gov) |
|          |       |                                                                     |


## Knowledge History
This section is to be used to describe history of knowledge around the project in a `change log` fashion

Can be used described here, or moved to a new file. If moved, add reference to `docs.manifest` so that can be uploaded to doc site for better.


#### Usage

./index.php mass:logstream --logtypes=varnish-request --logtypes=drupal-watchdog

- Other logtypes can be fetched but their records are not parsed correctly as they don't get delivered in JSON but rather in unparsed log lines.
- Redirect stdOut if you don't want to see log lines in the console.

#### Required Environment variables
- AC_API2_KEY
- AC_API2_SECRET
- AC_API_ENVIRONMENT_UUID (see Prod entry in self.site.yml)
- NR_LICENSE_KEY
- LOG_TYPES (e.g. `varnish-request,drupal-watchdog`)

#### Docker image
See [Docker Hub](https://hub.docker.com/repository/docker/massgov/logs-acquia-to-newrelic) for a containerized version of this command.

This Docker image is used in the [Digital Services Elk Stack](https://github.com/massgov/mds-elk) to stream logs to New Relic.

To manually build and push a new version of the container to Docker Hub:
1. From the latest main branch, run `docker build --platform linux/amd64 -t massgov/logs-acquia-to-newrelic:latest .`.
2. Run `docker push massgov/logs-acquia-to-newrelic:latest`.

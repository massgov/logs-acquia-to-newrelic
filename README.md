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

#!/usr/bin/env php
<?php

require './vendor/autoload.php';

use Massgov\LogsAcquiaToNewrelic\MassLogstreamCommand;
use Symfony\Component\Console\Application;

$application = new Application('MassLogstream', 0.1);
$application->add(new MassLogstreamCommand());
$application->run();
exit;


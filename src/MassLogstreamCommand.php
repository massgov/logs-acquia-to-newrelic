<?php

namespace Massgov\LogsAcquiaToNewrelic;

use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputOption;
use AcquiaCloudApi\Connector\Client;
use AcquiaCloudApi\Connector\Connector;
use AcquiaCloudApi\Endpoints\Logs;

class MassLogstreamCommand extends Command
{

    protected static $defaultName = 'mass:logstream';

    /**
     * @inheritdoc
     */
    protected function configure()
    {
        $this
            ->setDescription('Streams logs from Acquia Cloud to New Relic Logs')
            ->addOption(
                'logtypes',
                't',
                InputOption::VALUE_REQUIRED | InputOption::VALUE_IS_ARRAY,
                'Log types to stream',
                [
                    'bal-request',
                    'varnish-request',
                    'apache-request',
                    'apache-error',
                    'php-error',
                    'drupal-watchdog',
                    'drupal-request',
                    'mysql-slow'
                ]
            )
            ->addOption(
                'servers',
                's',
                InputOption::VALUE_REQUIRED | InputOption::VALUE_IS_ARRAY,
                'Servers to stream logs from e.g. web-1234.'
            )
            ->addOption(
                'colourise',
                'c',
                InputOption::VALUE_NONE,
                'Colorise the output based on HTTP status code.'
            );
    }

    /**
     * @inheritdoc
     */
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $config = [
            'key' => getenv('AC_API2_KEY'),
            'secret' => getenv('AC_API2_SECRET'),
        ];

        $connector = new Connector($config);
        $client = Client::factory($connector);

        $client->addOption('headers', [
            'User-Agent' => sprintf(
                "%s/%s (https://github.com/typhonius/acquia-logstream)",
                $this->getApplication()->getName(),
                $this->getApplication()->getVersion()
            )
        ]);

        $logs = new Logs($client);

        $stream = $logs->stream(getenv('AC_API_ENVIRONMENT_UUID'));

        $logstream = new MassLogStreamManager($input, $output);
        $logstream->setParams($stream->logstream->params);

        $logstream->setLogTypeFilter($input->getOption('logtypes'));
        $logstream->setLogServerFilter($input->getOption('servers'));
        $logstream->setColourise($input->getOption('colourise'));
        $logstream->stream();
        return 0;
    }
}

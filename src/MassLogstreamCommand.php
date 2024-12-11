<?php

namespace Massgov\LogsAcquiaToNewrelic;

use AcquiaLogstream\LogstreamManager;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Input\InputOption;
use AcquiaCloudApi\Connector\Client;
use AcquiaCloudApi\Connector\Connector;
use AcquiaCloudApi\Endpoints\Logs;

/**
 * Uses our own MassLogStreamManager instead of the typhonius one.
 */
class MassLogstreamCommand extends Command
{

    protected static $defaultName = 'mass:logstream';

    protected function configure()
    {
        $this
            ->setDescription('Streams logs directly from the Acquia Cloud')
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

        // @todo Remove after successful deployment. This is intended to prevent breakage for current environments.
        if ($logtypes = getenv('LOG_TYPES')) {
          $logtypes = explode(',', $logtypes);
        }
        else {
          $logtypes = [
            'varnish-request',
            'drupal-watchdog',
          ];
        }

        $logstream->setLogTypeFilter($logtypes);

        $logstream->setLogServerFilter($input->getOption('servers'));
        $logstream->setColourise($input->getOption('colourise'));
        $logstream->stream();
        return 0;
    }
}

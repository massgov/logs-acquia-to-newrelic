<?php


namespace Massgov\LogsAcquiaToNewrelic;


use Monolog\Handler\BufferHandler;
use Monolog\Logger;
use NewRelic\Monolog\Enricher\{Handler, Processor};
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class MassLogStreamManager extends \AcquiaLogstream\LogstreamManager
{
    protected Logger $log;

    public function __construct(InputInterface $input, OutputInterface $output)
    {
        parent::__construct($input, $output);
        $log = new Logger('log');
        $log->pushProcessor(new Processor);
        $handler = new Handler;
        $handler->setLicenseKey(getenv('NR_LICENSE_KEY'));
        $records_until_http_send = 50;
        $log->pushHandler(new BufferHandler($handler, $records_until_http_send, Logger::DEBUG, true, true));
        $this->log = $log;
    }

    /**
     * Customized to buffer each message to Monolog (and on to New Relic from there).
     */
    protected function processMessage($msg)
    {
        $message = json_decode($msg);
        if ($message->cmd === 'line') {
            $json = $this->enrichJson($message->text);
            $verb = $message->http_status >= 400 ? 'error' : 'info';
            $this->log->$verb($json);
        }
        return parent::processMessage($msg);
    }

    protected function enrichJson($json)
    {
        $record = json_decode($json);
        $time = $record->time;
        unset($record->time);
        $record->timestamp = strtotime(str_replace(['[', ']'], '', $time));
        $record->logtype = 'varnish.request';
        return json_encode($record);
    }
}
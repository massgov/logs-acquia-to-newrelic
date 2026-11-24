<?php


namespace Massgov\LogsAcquiaToNewrelic;


use Monolog\Handler\BufferHandler;
use Monolog\Logger;
use NewRelic\Monolog\Enricher\{Handler, Processor};
use Ratchet\Client\Connector as WebSocketConnector;
use Ratchet\Client\WebSocket;
use Ratchet\RFC6455\Messaging\MessageInterface;
use React\EventLoop\Factory as EventLoop;
use React\Socket\Connector as SocketConnector;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class MassLogStreamManager extends \AcquiaLogstream\LogstreamManager
{
    protected Logger $log;
    private string $streamUrl;

    public function __construct(InputInterface $input, OutputInterface $output, string $streamUrl)
    {
        parent::__construct($input, $output);
        $this->streamUrl = $streamUrl;
        $log = new Logger('log');
        $log->pushProcessor(new Processor);
        $handler = new Handler;
        $handler->setLicenseKey(getenv('NR_LICENSE_KEY'));
        $records_until_http_send = getenv('NUM_BUFFER') ?: 50;
        $log->pushHandler(new BufferHandler($handler, $records_until_http_send, Logger::DEBUG, true, true));
        $this->log = $log;
    }

    /**
     * Uses the API-provided URL instead of the parent class's fixed endpoint.
     */
    public function stream()
    {
        $loop = EventLoop::create();
        $socketConnector = new SocketConnector($loop, [
            'dns' => $this->getDns(),
            'timeout' => $this->getTimeout(),
        ]);
        $connector = new WebSocketConnector($loop, $socketConnector);

        $connector($this->streamUrl)->then(
            function (WebSocket $conn) {
                $conn->on('message', function (MessageInterface $msg) use ($conn) {
                    if ($send = $this->processMessage($msg)) {
                        $conn->send($send);
                    }
                });

                $conn->on('close', function ($code = null, $reason = null) {
                    echo "Connection closed ({$code} - {$reason})\n";
                });

                $conn->send(json_encode($this->getAuthArray()));
            },
            function (\Exception $e) use ($loop) {
                echo "Could not connect: {$e->getMessage()}\n";
                $loop->stop();
            }
        );

        $loop->run();
    }

    /**
     * Customized to buffer each message to Monolog (and on to New Relic from there).
     */
    protected function processMessage($msg)
    {
        $message = json_decode($msg);
        if ($message->cmd === 'line') {
            if ($message->log_type == 'varnish-request') {
              $json = $this->processVarnish($message->text);
              $verb = $message->http_status >= 400 ? 'error' : 'info';
              $this->log->$verb($json);
            }
            elseif ($message->log_type == 'drupal-watchdog') {
              $this->processWatchdog($message->text);
            }
        }
        return parent::processMessage($msg);
    }

    protected function processVarnish($json)
    {
        $record = json_decode($json);
        $time = $record->time;
        unset($record->time);
        $record->timestamp = strtotime(str_replace(['[', ']'], '', $time));
        $record->logtype = 'varnish.request';
        return json_encode($record);
    }

  protected function processWatchdog($line)
  {
    $start_pos = strpos($line, '{');
    $end_pos = strlen($line) - strrpos($line, '}') - 1;

    if ($start_pos === false) {
      return;
    }

    $json = substr($line, $start_pos, strlen($line) - $start_pos - $end_pos);
    $record = json_decode($json, JSON_OBJECT_AS_ARRAY);
    unset($record['datetime'], $record['extra']['user'], $record['extra']['base_url']);
    $record['logtype'] = 'drupal.watchdog';
    $this->log->addRecord($this->log->toMonologLevel($record['level_name']), json_encode($record), $record['context']);
  }
}

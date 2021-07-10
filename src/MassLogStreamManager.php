<?php


namespace Massgov\LogsAcquiaToNewrelic;


use Monolog\Handler\BufferHandler;
use Monolog\Logger;
use NewRelic\Monolog\Enricher\{Handler, Processor};
use Ratchet\Client\Connector as Ratchet;
use Ratchet\Client\WebSocket;
use Ratchet\RFC6455\Messaging\MessageInterface;
use React\EventLoop\Factory as EventLoop;
use React\Socket\Connector as React;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class MassLogStreamManager extends \AcquiaLogstream\LogstreamManager
{
    private Logger $log;

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
    public function stream()
    {
        $loop = EventLoop::create();
        $reactConnector = new React($loop, [
            'dns' => $this->dns,
            'timeout' => $this->timeout
        ]);

        $connector = new Ratchet($loop, $reactConnector);

        $connector(self::LOGSTREAM_URI)
            ->then(function (WebSocket $conn) {
                $conn->on('message', function (MessageInterface $msg) use ($conn) {
                    $message = json_decode($msg);

                    switch ($message->cmd) {
                        case 'available':
                            if (empty($this->logTypes) || in_array($message->type, $this->logTypes)) {
                                if (empty($this->servers) || in_array($message->server, $this->servers)) {
                                    $enable = [
                                        'cmd' => 'enable',
                                        'type' => $message->type,
                                        'server' => $message->server
                                    ];

                                    $conn->send(json_encode($enable));
                                }
                            }
                            break;
                        case 'connected':
                        case 'success':
                            if ($this->output->isDebug()) {
                                $this->output->writeln($msg);
                            }
                            break;
                        case 'line':
                            // MASS CUSTOMIZATIONS
                            $json = $this->enrichJson($message->text);
                            $verb = $message->http_status >= 400 ? 'error' : 'info';
                            $this->log->$verb($json);
                            echo "\n$message->text\n";
                            // END CUSTOMIZATION
                            break;
                        case 'error':
                            $this->output->writeln("<fg=red>${msg}</>");
                            break;
                        default:
                            break;
                    }
                });

                $conn->on('close', function ($code = null, $reason = null) {
                    echo "Connection closed ({$code} - {$reason})\n";
                });

                $conn->send(json_encode($this->getAuthArray()));
            }, function (\Exception $e) use ($loop) {
                echo "Could not connect: {$e->getMessage()}\n";
                $loop->stop();
            });

        $loop->run();
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
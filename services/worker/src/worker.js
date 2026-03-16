require("dotenv").config();

const http = require("node:http");
const { Kafka } = require("kafkajs");

const logger = require("./logger");
const {
  register,
  jobsProcessedTotal,
  jobsFailedTotal,
  jobProcessingDurationSeconds,
  kafkaConsumerConnected
} = require("./metrics");

const KAFKA_CLIENT_ID = process.env.KAFKA_CLIENT_ID;
const KAFKA_BROKERS = process.env.KAFKA_BROKERS.split(",");
const KAFKA_TOPIC = process.env.KAFKA_TOPIC;
const KAFKA_GROUP_ID = process.env.KAFKA_GROUP_ID;
const OBSERVABILITY_PORT = Number(process.env.OBSERVABILITY_PORT || 3001);

const kafka = new Kafka({
  clientId: KAFKA_CLIENT_ID,
  brokers: KAFKA_BROKERS,
  retry: {
    initialRetryTime: 1000,
    retries: 8,
    maxRetryTime: 30000,
    multiplier: 2
  }
});

const consumer = kafka.consumer({
  groupId: KAFKA_GROUP_ID,
  retry: {
    initialRetryTime: 1000,
    retries: 8,
    maxRetryTime: 30000,
    multiplier: 2
  }
});

const consumerState = {
  connected: false,
  subscribed: false,
  running: false,
  crashed: false
};

function syncConsumerGauge() {
  kafkaConsumerConnected.set(consumerState.connected ? 1 : 0);
}

syncConsumerGauge();

function isConsumerReady() {
  return consumerState.connected
    && consumerState.subscribed
    && consumerState.running
    && !consumerState.crashed;
}

function createObservabilityServer() {
  const server = http.createServer(async (req, res) => {
    if (req.url === "/metrics") {
      res.writeHead(200, { "Content-Type": register.contentType });
      res.end(await register.metrics());
      return;
    }

    if (req.url === "/health") {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({
        status: "ok",
        service: "worker"
      }));
      return;
    }

    if (req.url === "/ready") {
      const statusCode = isConsumerReady() ? 200 : 503;

      res.writeHead(statusCode, { "Content-Type": "application/json" });
      res.end(JSON.stringify({
        status: isConsumerReady() ? "ready" : "not-ready",
        service: "worker",
        consumer: {
          connected: consumerState.connected,
          subscribed: consumerState.subscribed,
          running: consumerState.running,
          crashed: consumerState.crashed
        }
      }));
      return;
    }

    res.writeHead(404, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "not found" }));
  });

  server.listen(OBSERVABILITY_PORT, () => {
    logger.info({ port: OBSERVABILITY_PORT }, "Worker observability endpoint running");
  });

  return server;
}

function processText(text) {
  const words = text.toLowerCase().split(/\s+/);
  const frequency = {};

  for (const word of words) {
    frequency[word] = (frequency[word] || 0) + 1;
  }

  return frequency;
}

consumer.on(consumer.events.CONNECT, () => {
  consumerState.connected = true;
  consumerState.crashed = false;
  syncConsumerGauge();
});

consumer.on(consumer.events.DISCONNECT, () => {
  consumerState.connected = false;
  consumerState.running = false;
  syncConsumerGauge();
});

consumer.on(consumer.events.STOP, () => {
  consumerState.running = false;
});

consumer.on(consumer.events.CRASH, ({ payload }) => {
  consumerState.connected = false;
  consumerState.running = false;
  consumerState.crashed = true;
  syncConsumerGauge();
  logger.error({ err: payload.error }, "Kafka consumer crashed");
});

async function startWithRetry(retries = 0, maxRetries = 10) {
  try {
    await consumer.connect();
    logger.debug("Worker connected to Kafka");

    await consumer.subscribe({
      topic: KAFKA_TOPIC,
      fromBeginning: true
    });

    consumerState.subscribed = true;
    logger.info("Successfully subscribed to topic");

    consumerState.running = true;
    await consumer.run({
      eachMessage: async ({ message }) => {
        const endTimer = jobProcessingDurationSeconds.startTimer();

        try {
          const payload = JSON.parse(message.value.toString());

          logger.info({ payload }, "Received message:");

          const result = processText(payload.text);

          jobsProcessedTotal.inc();
          logger.info({ result }, "Processing result:");
        } catch (err) {
          jobsFailedTotal.inc();
          logger.error({ err }, "Failed to process Kafka message");
          throw err;
        } finally {
          endTimer();
        }
      }
    });
  } catch (err) {
    consumerState.connected = false;
    consumerState.running = false;
    syncConsumerGauge();

    if (retries < maxRetries) {
      const delay = Math.min(1000 * Math.pow(2, retries), 30000);
      logger.warn({ err, retries, nextRetryIn: delay }, "Failed to start consumer, retrying...");
      await new Promise(resolve => setTimeout(resolve, delay));
      return startWithRetry(retries + 1, maxRetries);
    }
    logger.error({ err }, "Failed to start consumer after max retries");
    throw err;
  }
}

const observabilityServer = createObservabilityServer();

async function shutdown(signal) {
  logger.info({ signal }, "Shutting down worker");

  consumerState.running = false;
  syncConsumerGauge();

  try {
    await consumer.disconnect();
  } catch (err) {
    logger.warn({ err }, "Failed to disconnect consumer cleanly");
  }

  observabilityServer.close(() => {
    process.exit(0);
  });
}

process.on("SIGINT", () => {
  shutdown("SIGINT").catch((err) => {
    logger.error({ err }, "Failed to shutdown worker");
    process.exit(1);
  });
});

process.on("SIGTERM", () => {
  shutdown("SIGTERM").catch((err) => {
    logger.error({ err }, "Failed to shutdown worker");
    process.exit(1);
  });
});

startWithRetry().catch((err) => {
  logger.error({ err }, "Worker failed to start");
  observabilityServer.close(() => process.exit(1));
});

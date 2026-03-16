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
const CONSUME_FROM_BEGINNING = process.env.KAFKA_CONSUME_FROM_BEGINNING === "true";

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
  crashed: false,
  shuttingDown: false
};

function syncConsumerGauge() {
  kafkaConsumerConnected.set(consumerState.connected ? 1 : 0);
}

syncConsumerGauge();

function isConsumerReady() {
  return consumerState.connected
    && consumerState.subscribed
    && consumerState.running
    && !consumerState.crashed
    && !consumerState.shuttingDown;
}

function setConsumerState(updates) {
  Object.assign(consumerState, updates);
  syncConsumerGauge();
}

function buildMessageContext({ topic, partition, message, payload }) {
  return {
    topic,
    partition,
    offset: message.offset,
    payloadId: payload?.id ?? null
  };
}

function logInfrastructureError(err, message, extra = {}) {
  logger.error({
    err,
    errorType: "infrastructure",
    topic: KAFKA_TOPIC,
    groupId: KAFKA_GROUP_ID,
    ...extra
  }, message);
}

function logProcessingError(err, context = {}) {
  logger.error({
    err,
    errorType: "processing",
    ...context
  }, "Failed to process Kafka message");
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
          crashed: consumerState.crashed,
          shuttingDown: consumerState.shuttingDown
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
  setConsumerState({
    connected: true,
    crashed: false
  });
  logger.info({
    topic: KAFKA_TOPIC,
    groupId: KAFKA_GROUP_ID
  }, "Kafka consumer connected");
});

consumer.on(consumer.events.DISCONNECT, () => {
  setConsumerState({
    connected: false,
    running: false
  });
  logger.info({
    topic: KAFKA_TOPIC,
    groupId: KAFKA_GROUP_ID,
    shuttingDown: consumerState.shuttingDown
  }, "Kafka consumer disconnected");
});

consumer.on(consumer.events.STOP, () => {
  setConsumerState({ running: false });
  logger.info({
    topic: KAFKA_TOPIC,
    groupId: KAFKA_GROUP_ID
  }, "Kafka consumer stopped");
});

consumer.on(consumer.events.CRASH, ({ payload }) => {
  setConsumerState({
    connected: false,
    running: false,
    crashed: true
  });
  logInfrastructureError(payload.error, "Kafka consumer crashed");
});

async function startWithRetry(retries = 0, maxRetries = 10) {
  try {
    await consumer.connect();

    await consumer.subscribe({
      topic: KAFKA_TOPIC,
      fromBeginning: CONSUME_FROM_BEGINNING
    });

    setConsumerState({ subscribed: true });
    logger.info({
      topic: KAFKA_TOPIC,
      groupId: KAFKA_GROUP_ID,
      fromBeginning: CONSUME_FROM_BEGINNING,
      mode: CONSUME_FROM_BEGINNING ? "demo" : "continuous"
    }, "Kafka consumer subscribed");

    await consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        const endTimer = jobProcessingDurationSeconds.startTimer();

        try {
          const payload = JSON.parse(message.value.toString());
          const context = buildMessageContext({ topic, partition, message, payload });

          setConsumerState({ running: true });
          logger.info({
            ...context,
            groupId: KAFKA_GROUP_ID
          }, "Received Kafka message");

          const result = processText(payload.text);

          jobsProcessedTotal.inc();
          logger.info({
            ...context,
            result,
            groupId: KAFKA_GROUP_ID
          }, "Processed Kafka message");
        } catch (err) {
          jobsFailedTotal.inc();
          logProcessingError(err, {
            topic,
            partition,
            offset: message.offset,
            groupId: KAFKA_GROUP_ID
          });
          throw err;
        } finally {
          endTimer();
        }
      }
    });

    setConsumerState({ running: true });
    logger.info({
      topic: KAFKA_TOPIC,
      groupId: KAFKA_GROUP_ID
    }, "Kafka consumer is ready to consume");
  } catch (err) {
    setConsumerState({
      connected: false,
      running: false
    });

    if (retries < maxRetries) {
      const delay = Math.min(1000 * Math.pow(2, retries), 30000);
      logger.warn({
        err,
        errorType: "infrastructure",
        topic: KAFKA_TOPIC,
        groupId: KAFKA_GROUP_ID,
        retries,
        nextRetryIn: delay
      }, "Failed to start consumer, retrying");
      await new Promise(resolve => setTimeout(resolve, delay));
      return startWithRetry(retries + 1, maxRetries);
    }
    logInfrastructureError(err, "Failed to start consumer after max retries");
    throw err;
  }
}

const observabilityServer = createObservabilityServer();

async function shutdown(signal) {
  if (consumerState.shuttingDown) {
    logger.info({ signal }, "Shutdown already in progress");
    return;
  }

  setConsumerState({
    running: false,
    shuttingDown: true
  });
  logger.info({
    signal,
    topic: KAFKA_TOPIC,
    groupId: KAFKA_GROUP_ID
  }, "Starting graceful shutdown");

  try {
    logger.info({
      topic: KAFKA_TOPIC,
      groupId: KAFKA_GROUP_ID
    }, "Disconnecting Kafka consumer");
    await consumer.disconnect();
    logger.info({
      topic: KAFKA_TOPIC,
      groupId: KAFKA_GROUP_ID
    }, "Kafka consumer disconnected cleanly");
  } catch (err) {
    logger.warn({
      err,
      errorType: "infrastructure",
      topic: KAFKA_TOPIC,
      groupId: KAFKA_GROUP_ID
    }, "Failed to disconnect consumer cleanly");
  }

  observabilityServer.close(() => {
    logger.info({ signal }, "Worker shutdown completed");
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

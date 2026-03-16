require("dotenv").config({ quiet: true });

const express = require("express");
const { Kafka, Partitioners } = require("kafkajs");

const app = express();
app.use(express.json());

const register = require("./metrics");
const logger = require("./logger");

const PORT = process.env.PORT || 3000;
const KAFKA_CLIENT_ID = process.env.KAFKA_CLIENT_ID;
const KAFKA_BROKERS = process.env.KAFKA_BROKERS.split(",");
const KAFKA_TOPIC = process.env.KAFKA_TOPIC;

const kafka = new Kafka({
  clientId: KAFKA_CLIENT_ID,
  brokers: KAFKA_BROKERS
});

const producer = kafka.producer({
  createPartitioner: Partitioners.LegacyPartitioner
});

let kafkaReady = false;

async function startKafka() {
  await producer.connect();
  kafkaReady = true;
  logger.info({ brokers: KAFKA_BROKERS, topic: KAFKA_TOPIC }, "Kafka producer connected");
}

app.post("/job", async (req, res) => {
  const { text } = req.body;

  if (!text) {
    return res.status(400).json({ error: "text is required" });
  }

  const message = {
    text,
    timestamp: new Date().toISOString()
  };

  try {
    await producer.send({
      topic: KAFKA_TOPIC,
      messages: [{ value: JSON.stringify(message) }]
    });
  } catch (error) {
    logger.error({ err: error, topic: KAFKA_TOPIC }, "Failed to publish message to Kafka");
    return res.status(503).json({ error: "failed to queue message" });
  }

  res.json({
    status: "queued",
    message
  });
});

app.get("/", (_, res) => {
  res.send("API Service running");
});

app.get("/metrics", async (_, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

app.get("/health", (_, res) => {
  res.status(200).json({
    status: "ok",
    service: "api"
  });
});

app.get("/ready", (_, res) => {
  if (!kafkaReady) {
    return res.status(503).json({
      status: "not-ready",
      service: "api"
    });
  }

  return res.status(200).json({
    status: "ready",
    service: "api"
  });
});

async function bootstrap() {
  try {
    await startKafka();

    app.listen(PORT, () => {
      logger.info(`API running on port ${PORT}`);
      logger.info("API service is ready to accept jobs");
    });
  } catch (error) {
    logger.error({ err: error }, "Failed to initialize API service");
    process.exit(1);
  }
}

bootstrap();

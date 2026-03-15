require("dotenv").config();

const { Kafka } = require("kafkajs");

const logger = require("./logger");

const KAFKA_CLIENT_ID = process.env.KAFKA_CLIENT_ID;
const KAFKA_BROKERS = process.env.KAFKA_BROKERS.split(",");
const KAFKA_TOPIC = process.env.KAFKA_TOPIC;
const KAFKA_GROUP_ID = process.env.KAFKA_GROUP_ID;

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

function processText(text) {
  const words = text.toLowerCase().split(/\s+/);
  const frequency = {};

  for (const word of words) {
    frequency[word] = (frequency[word] || 0) + 1;
  }

  return frequency;
}

async function startWithRetry(retries = 0, maxRetries = 10) {
  try {
    await consumer.connect();
    logger.debug("Worker connected to Kafka");

    await consumer.subscribe({
      topic: KAFKA_TOPIC,
      fromBeginning: true
    });

    logger.info("Successfully subscribed to topic");

    await consumer.run({
      eachMessage: async ({ message }) => {
        const payload = JSON.parse(message.value.toString());

        logger.info({ payload }, "Received message:");

        const result = processText(payload.text);

        logger.info({ result }, "Processing result:");
      }
    });
  } catch (err) {
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

startWithRetry().catch((err) => logger.error(err));

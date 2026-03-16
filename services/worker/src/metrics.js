const client = require("prom-client");

const register = new client.Registry();

client.collectDefaultMetrics({ register });

const jobsProcessedTotal = new client.Counter({
  name: "jobs_processados_total",
  help: "Total number of jobs processed successfully by the worker",
  registers: [register]
});

const jobsFailedTotal = new client.Counter({
  name: "jobs_falhos_total",
  help: "Total number of jobs that failed during processing",
  registers: [register]
});

const jobProcessingDurationSeconds = new client.Histogram({
  name: "job_processing_duration_seconds",
  help: "Time spent processing jobs in seconds",
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10],
  registers: [register]
});

const kafkaConsumerConnected = new client.Gauge({
  name: "kafka_consumer_connected",
  help: "Kafka consumer connectivity state. 1 means connected, 0 means disconnected",
  registers: [register]
});

module.exports = {
  register,
  jobsProcessedTotal,
  jobsFailedTotal,
  jobProcessingDurationSeconds,
  kafkaConsumerConnected
};

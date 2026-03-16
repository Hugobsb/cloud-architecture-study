const pino = require("pino");

const transport = process.env.NODE_ENV === "development"
  ? { target: "pino-pretty" }
  : undefined;

const logger = pino({
  level: process.env.LOG_LEVEL || "info",
  transport
});

module.exports = logger;

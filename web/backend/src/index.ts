import "dotenv/config";
import express from "express";
import cors from "cors";
import { authRouter } from "./routes/auth.js";
import { devicesRouter } from "./routes/devices.js";
import { adminRouter } from "./routes/admin.js";
import { otaRouter } from "./routes/ota.js";

const app = express();
const PORT = Number(process.env.PORT) || 4000;

app.use(cors({ origin: true, credentials: true }));
app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({ status: "ok", service: "health-monitor-api" });
});

app.use("/api/auth", authRouter);
app.use("/api/devices", devicesRouter);
app.use("/api/admin", adminRouter);
app.use("/api/ota", otaRouter);

app.listen(PORT, () => {
  console.log(`API chạy tại http://localhost:${PORT}`);
});

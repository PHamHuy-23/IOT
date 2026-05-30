import { Router } from "express";
import path from "path";
import fs from "fs";
import crypto from "crypto";
import multer from "multer";
import { z } from "zod";
import { prisma } from "../lib/prisma.js";
import { authMiddleware, adminOnly } from "../lib/auth.js";

export const otaRouter = Router();

const uploadDir = path.resolve("uploads/firmware");
fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    const safe = file.originalname.replace(/[^a-zA-Z0-9._-]/g, "_");
    cb(null, `${Date.now()}-${safe}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 4 * 1024 * 1024 } });

otaRouter.post(
  "/firmware",
  authMiddleware,
  adminOnly,
  upload.single("file"),
  async (req, res) => {
    const schema = z.object({
      version: z.string().min(1),
      description: z.string().optional(),
      minHwRev: z.string().optional(),
    });
    const parsed = schema.safeParse(req.body);
    if (!parsed.success || !req.file) {
      res.status(400).json({ error: "Cần file firmware và version" });
      return;
    }

    const buffer = fs.readFileSync(req.file.path);
    const checksum = crypto.createHash("sha256").update(buffer).digest("hex");

    const firmware = await prisma.firmware.create({
      data: {
        version: parsed.data.version,
        description: parsed.data.description,
        fileName: req.file.originalname,
        filePath: req.file.path,
        checksum,
        minHwRev: parsed.data.minHwRev ?? "1.0",
      },
    });
    res.status(201).json(firmware);
  }
);

otaRouter.get("/firmware", authMiddleware, adminOnly, async (_req, res) => {
  const list = await prisma.firmware.findMany({ orderBy: { createdAt: "desc" } });
  res.json(list);
});

otaRouter.get("/firmware/:id/download", async (req, res) => {
  const fw = await prisma.firmware.findUnique({ where: { id: req.params.id } });
  if (!fw || !fs.existsSync(fw.filePath)) {
    res.status(404).json({ error: "Firmware not found" });
    return;
  }
  res.download(fw.filePath, fw.fileName);
});

otaRouter.post("/campaigns", authMiddleware, adminOnly, async (req, res) => {
  const schema = z.object({
    name: z.string().min(1),
    firmwareId: z.string(),
    targetModel: z.string().optional(),
    targetErrorCode: z.string().optional(),
    rolloutPercent: z.number().int().min(1).max(100).default(100),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const campaign = await prisma.otaCampaign.create({
    data: parsed.data,
    include: { firmware: true },
  });
  res.status(201).json(campaign);
});

otaRouter.post(
  "/campaigns/:id/start",
  authMiddleware,
  adminOnly,
  async (req, res) => {
    const campaign = await prisma.otaCampaign.update({
      where: { id: req.params.id },
      data: { status: "RUNNING", startedAt: new Date() },
      include: { firmware: true },
    });

    const where: Record<string, unknown> = {};
    if (campaign.targetModel) where.model = campaign.targetModel;

    let devices = await prisma.device.findMany({ where });

    if (campaign.targetErrorCode) {
      const withError = await prisma.deviceError.findMany({
        where: { errorCode: campaign.targetErrorCode, resolved: false },
        select: { deviceId: true },
        distinct: ["deviceId"],
      });
      const ids = new Set(withError.map((e) => e.deviceId));
      devices = devices.filter((d) => ids.has(d.id));
    }

    const limit = Math.ceil(
      (devices.length * campaign.rolloutPercent) / 100
    );
    const targets = devices.slice(0, limit);

    await prisma.otaLog.createMany({
      data: targets.map((d) => ({
        campaignId: campaign.id,
        deviceId: d.id,
        status: "pending",
      })),
      skipDuplicates: true,
    });

    res.json({ campaign, targetedDevices: targets.length });
  }
);

otaRouter.get("/campaigns", authMiddleware, adminOnly, async (_req, res) => {
  const campaigns = await prisma.otaCampaign.findMany({
    include: {
      firmware: true,
      _count: { select: { logs: true } },
    },
    orderBy: { createdAt: "desc" },
  });
  res.json(campaigns);
});

otaRouter.get(
  "/campaigns/:id/logs",
  authMiddleware,
  adminOnly,
  async (req, res) => {
    const logs = await prisma.otaLog.findMany({
      where: { campaignId: req.params.id },
      include: {
        device: { select: { deviceCode: true, firmwareVersion: true } },
      },
      orderBy: { updatedAt: "desc" },
    });
    res.json(logs);
  }
);

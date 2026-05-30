import { Router } from "express";
import { z } from "zod";
import { DeviceStatus } from "@prisma/client";
import { prisma } from "../lib/prisma.js";
import { authMiddleware } from "../lib/auth.js";

export const devicesRouter = Router();

/** App mobile gọi khi user kích hoạt vòng tay qua BLE */
devicesRouter.post("/activate", authMiddleware, async (req, res) => {
  const schema = z.object({
    deviceCode: z.string().min(4).max(64),
    model: z.string().optional(),
    firmwareVersion: z.string().optional(),
    activationToken: z.string().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const { userId } = (req as typeof req & { user: { userId: string } }).user;
  const { deviceCode, model, firmwareVersion } = parsed.data;

  let device = await prisma.device.findUnique({ where: { deviceCode } });

  if (!device) {
    device = await prisma.device.create({
      data: {
        deviceCode,
        model: model ?? "ESP32-C3-BAND",
        firmwareVersion: firmwareVersion ?? "1.0.0",
        status: DeviceStatus.ACTIVE,
        ownerId: userId,
        lastSeenAt: new Date(),
      },
    });
  } else {
    device = await prisma.device.update({
      where: { id: device.id },
      data: {
        status: DeviceStatus.ACTIVE,
        ownerId: userId,
        lastSeenAt: new Date(),
        ...(firmwareVersion ? { firmwareVersion } : {}),
      },
    });
  }

  await prisma.deviceClaim.create({
    data: {
      deviceId: device.id,
      userId,
      source: "mobile_ble",
    },
  });

  const owner = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, name: true, email: true, phone: true },
  });

  res.json({
    success: true,
    device: {
      id: device.id,
      deviceCode: device.deviceCode,
      model: device.model,
      firmwareVersion: device.firmwareVersion,
      status: device.status,
    },
    user: owner,
  });
});

/** ESP32 / app gửi heartbeat + telemetry */
devicesRouter.post("/:deviceCode/heartbeat", async (req, res) => {
  const schema = z.object({
    firmwareVersion: z.string().optional(),
    heartRate: z.number().int().optional(),
    spo2: z.number().int().optional(),
    steps: z.number().int().optional(),
    battery: z.number().int().min(0).max(100).optional(),
    errorCodes: z.array(z.string()).optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const device = await prisma.device.findUnique({
    where: { deviceCode: req.params.deviceCode },
  });
  if (!device) {
    res.status(404).json({ error: "Thiết bị chưa đăng ký" });
    return;
  }

  const hasErrors = (parsed.data.errorCodes?.length ?? 0) > 0;

  await prisma.device.update({
    where: { id: device.id },
    data: {
      lastSeenAt: new Date(),
      status: hasErrors ? DeviceStatus.ERROR : DeviceStatus.ACTIVE,
      ...(parsed.data.firmwareVersion
        ? { firmwareVersion: parsed.data.firmwareVersion }
        : {}),
    },
  });

  if (
    parsed.data.heartRate ||
    parsed.data.spo2 ||
    parsed.data.steps ||
    parsed.data.battery
  ) {
    await prisma.telemetry.create({
      data: {
        deviceId: device.id,
        heartRate: parsed.data.heartRate,
        spo2: parsed.data.spo2,
        steps: parsed.data.steps,
        battery: parsed.data.battery,
      },
    });
  }

  if (parsed.data.errorCodes?.length) {
    for (const code of parsed.data.errorCodes) {
      await prisma.deviceError.create({
        data: { deviceId: device.id, errorCode: code },
      });
    }
  }

  res.json({ ok: true });
});

/** Thiết bị kiểm tra OTA */
devicesRouter.get("/:deviceCode/firmware/check", async (req, res) => {
  const device = await prisma.device.findUnique({
    where: { deviceCode: req.params.deviceCode },
  });
  if (!device) {
    res.status(404).json({ error: "Device not found" });
    return;
  }

  const runningCampaign = await prisma.otaCampaign.findFirst({
    where: { status: "RUNNING" },
    include: { firmware: true },
    orderBy: { startedAt: "desc" },
  });

  if (!runningCampaign) {
    res.json({ updateAvailable: false, currentVersion: device.firmwareVersion });
    return;
  }

  const needsUpdate =
    runningCampaign.firmware.version !== device.firmwareVersion;

  const baseUrl = `${req.protocol}://${req.get("host")}`;

  res.json({
    updateAvailable: needsUpdate,
    currentVersion: device.firmwareVersion,
    targetVersion: runningCampaign.firmware.version,
    downloadUrl: needsUpdate
      ? `${baseUrl}/api/ota/firmware/${runningCampaign.firmware.id}/download`
      : null,
    checksum: needsUpdate ? runningCampaign.firmware.checksum : null,
    campaignId: runningCampaign.id,
  });
});

devicesRouter.post("/:deviceCode/ota/report", async (req, res) => {
  const schema = z.object({
    campaignId: z.string(),
    status: z.enum(["downloading", "success", "failed"]),
    message: z.string().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const device = await prisma.device.findUnique({
    where: { deviceCode: req.params.deviceCode },
  });
  if (!device) {
    res.status(404).json({ error: "Device not found" });
    return;
  }

  await prisma.otaLog.upsert({
    where: {
      campaignId_deviceId: {
        campaignId: parsed.data.campaignId,
        deviceId: device.id,
      },
    },
    create: {
      campaignId: parsed.data.campaignId,
      deviceId: device.id,
      status: parsed.data.status,
      message: parsed.data.message,
    },
    update: {
      status: parsed.data.status,
      message: parsed.data.message,
    },
  });

  if (parsed.data.status === "success") {
    const campaign = await prisma.otaCampaign.findUnique({
      where: { id: parsed.data.campaignId },
      include: { firmware: true },
    });
    if (campaign) {
      await prisma.device.update({
        where: { id: device.id },
        data: { firmwareVersion: campaign.firmware.version },
      });
    }
  }

  res.json({ ok: true });
});

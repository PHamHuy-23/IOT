import { Router } from "express";
import { z } from "zod";
import { DeviceStatus, Role } from "@prisma/client";
import { prisma } from "../lib/prisma.js";
import { authMiddleware, adminOnly } from "../lib/auth.js";

export const adminRouter = Router();
adminRouter.use(authMiddleware, adminOnly);

adminRouter.get("/stats", async (_req, res) => {
  const [
    totalDevices,
    activeDevices,
    totalUsers,
    activeUsers,
    errorDevices,
    unresolvedErrors,
  ] = await Promise.all([
    prisma.device.count(),
    prisma.device.count({
      where: { status: { in: [DeviceStatus.ACTIVE, DeviceStatus.ERROR] } },
    }),
    prisma.user.count({ where: { role: Role.USER } }),
    prisma.user.count({
      where: {
        role: Role.USER,
        devices: { some: { status: DeviceStatus.ACTIVE } },
      },
    }),
    prisma.device.count({ where: { status: DeviceStatus.ERROR } }),
    prisma.deviceError.count({ where: { resolved: false } }),
  ]);

  res.json({
    totalDevices,
    activeDevices,
    unclaimedDevices: totalDevices - activeDevices,
    totalUsers,
    activeUsers,
    errorDevices,
    unresolvedErrors,
  });
});

adminRouter.get("/devices", async (req, res) => {
  const status = req.query.status as DeviceStatus | undefined;
  const devices = await prisma.device.findMany({
    where: status ? { status } : undefined,
    include: {
      owner: { select: { id: true, name: true, email: true, phone: true } },
      errors: {
        where: { resolved: false },
        orderBy: { reportedAt: "desc" },
        take: 5,
      },
    },
    orderBy: { updatedAt: "desc" },
  });
  res.json(devices);
});

adminRouter.get("/devices/:id", async (req, res) => {
  const device = await prisma.device.findUnique({
    where: { id: req.params.id },
    include: {
      owner: true,
      claims: {
        include: { user: { select: { id: true, name: true, email: true } } },
        orderBy: { claimedAt: "desc" },
      },
      telemetry: { orderBy: { recordedAt: "desc" }, take: 50 },
      errors: { orderBy: { reportedAt: "desc" }, take: 20 },
    },
  });
  if (!device) {
    res.status(404).json({ error: "Không tìm thấy thiết bị" });
    return;
  }
  res.json(device);
});

adminRouter.get("/users", async (_req, res) => {
  const users = await prisma.user.findMany({
    where: { role: Role.USER },
    include: {
      devices: {
        select: {
          id: true,
          deviceCode: true,
          status: true,
          firmwareVersion: true,
          lastSeenAt: true,
        },
      },
      _count: { select: { devices: true } },
    },
    orderBy: { createdAt: "desc" },
  });
  res.json(users);
});

adminRouter.post("/devices/register", async (req, res) => {
  const schema = z.object({
    deviceCode: z.string().min(4),
    model: z.string().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const device = await prisma.device.upsert({
    where: { deviceCode: parsed.data.deviceCode },
    create: {
      deviceCode: parsed.data.deviceCode,
      model: parsed.data.model ?? "ESP32-C3-BAND",
      status: DeviceStatus.UNCLAIMED,
    },
    update: { model: parsed.data.model },
  });
  res.status(201).json(device);
});

adminRouter.patch("/errors/:id/resolve", async (req, res) => {
  const err = await prisma.deviceError.update({
    where: { id: req.params.id },
    data: { resolved: true },
  });
  res.json(err);
});

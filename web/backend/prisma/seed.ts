import "dotenv/config";
import { PrismaClient, Role, DeviceStatus } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  const adminEmail = process.env.ADMIN_EMAIL ?? "admin@health.local";
  const adminPassword = process.env.ADMIN_PASSWORD ?? "admin123";

  await prisma.user.upsert({
    where: { email: adminEmail },
    create: {
      email: adminEmail,
      name: "Administrator",
      password: await bcrypt.hash(adminPassword, 10),
      role: Role.ADMIN,
    },
    update: {},
  });

  const user1 = await prisma.user.upsert({
    where: { email: "nguyen.van.a@example.com" },
    create: {
      email: "nguyen.van.a@example.com",
      name: "Nguyễn Văn A",
      phone: "0901234567",
      password: await bcrypt.hash("user123", 10),
      role: Role.USER,
    },
    update: {},
  });

  const user2 = await prisma.user.upsert({
    where: { email: "tran.thi.b@example.com" },
    create: {
      email: "tran.thi.b@example.com",
      name: "Trần Thị B",
      phone: "0912345678",
      password: await bcrypt.hash("user123", 10),
      role: Role.USER,
    },
    update: {},
  });

  const devices = [
    { deviceCode: "C3-A1B2C3D4E5F6", ownerId: user1.id, status: DeviceStatus.ACTIVE },
    { deviceCode: "C3-F6E5D4C3B2A1", ownerId: user2.id, status: DeviceStatus.ACTIVE },
    { deviceCode: "C3-112233445566", ownerId: null, status: DeviceStatus.UNCLAIMED },
    { deviceCode: "C3-ERROR-DEVICE01", ownerId: user1.id, status: DeviceStatus.ERROR },
  ];

  for (const d of devices) {
    const device = await prisma.device.upsert({
      where: { deviceCode: d.deviceCode },
      create: {
        deviceCode: d.deviceCode,
        model: "ESP32-C3-BAND",
        firmwareVersion: "1.0.0",
        status: d.status,
        ownerId: d.ownerId,
        lastSeenAt: d.ownerId ? new Date() : null,
      },
      update: { status: d.status, ownerId: d.ownerId },
    });

    if (d.ownerId) {
      const existing = await prisma.deviceClaim.findFirst({
        where: { deviceId: device.id, userId: d.ownerId },
      });
      if (!existing) {
        await prisma.deviceClaim.create({
          data: { deviceId: device.id, userId: d.ownerId, source: "seed" },
        });
      }
    }
  }

  const errorDevice = await prisma.device.findUnique({
    where: { deviceCode: "C3-ERROR-DEVICE01" },
  });
  if (errorDevice) {
    await prisma.deviceError.create({
      data: {
        deviceId: errorDevice.id,
        errorCode: "E_SENSOR_HR",
        message: "Cảm biến nhịp tim không phản hồi",
      },
    });
  }

  console.log("Seed xong. Admin:", adminEmail, "/", adminPassword);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

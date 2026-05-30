import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma.js";
import {
  comparePassword,
  hashPassword,
  signToken,
  authMiddleware,
} from "../lib/auth.js";

export const authRouter = Router();

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(4),
});

authRouter.post("/login", async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const user = await prisma.user.findUnique({
    where: { email: parsed.data.email },
  });
  if (!user || !(await comparePassword(parsed.data.password, user.password))) {
    res.status(401).json({ error: "Email hoặc mật khẩu không đúng" });
    return;
  }

  const token = signToken({ userId: user.id, role: user.role });
  res.json({
    token,
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
    },
  });
});

authRouter.get("/me", authMiddleware, async (req, res) => {
  const { userId } = (req as typeof req & { user: { userId: string } }).user;
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, email: true, name: true, role: true },
  });
  if (!user) {
    res.status(404).json({ error: "User not found" });
    return;
  }
  res.json(user);
});

authRouter.post("/register-user", async (req, res) => {
  const schema = z.object({
    email: z.string().email(),
    password: z.string().min(6),
    name: z.string().min(1),
    phone: z.string().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  const exists = await prisma.user.findUnique({
    where: { email: parsed.data.email },
  });
  if (exists) {
    res.status(409).json({ error: "Email đã tồn tại" });
    return;
  }

  const user = await prisma.user.create({
    data: {
      ...parsed.data,
      password: await hashPassword(parsed.data.password),
      role: "USER",
    },
    select: { id: true, email: true, name: true, role: true },
  });
  res.status(201).json(user);
});

const API = "/api";

function headers(): HeadersInit {
  const token = localStorage.getItem("token");
  return {
    "Content-Type": "application/json",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
}

export async function api<T>(
  path: string,
  options?: RequestInit
): Promise<T> {
  const res = await fetch(`${API}${path}`, {
    ...options,
    headers: { ...headers(), ...options?.headers },
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error(err.error ?? "Request failed");
  }
  return res.json();
}

export type Stats = {
  totalDevices: number;
  activeDevices: number;
  unclaimedDevices: number;
  totalUsers: number;
  activeUsers: number;
  errorDevices: number;
  unresolvedErrors: number;
};

export type Device = {
  id: string;
  deviceCode: string;
  model: string;
  firmwareVersion: string;
  status: string;
  lastSeenAt: string | null;
  owner: { id: string; name: string; email: string; phone: string | null } | null;
  errors: { id: string; errorCode: string; message: string | null }[];
};

export type UserRow = {
  id: string;
  name: string;
  email: string;
  phone: string | null;
  devices: { deviceCode: string; status: string }[];
  _count: { devices: number };
};

export type Firmware = {
  id: string;
  version: string;
  description: string | null;
  checksum: string;
  createdAt: string;
};

export type Campaign = {
  id: string;
  name: string;
  status: string;
  rolloutPercent: number;
  firmware: { version: string };
  _count: { logs: number };
};

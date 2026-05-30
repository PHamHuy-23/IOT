import { FormEvent, useEffect, useState } from "react";
import { api, type Campaign, type Firmware } from "../lib/api";

export default function OtaPage() {
  const [firmwares, setFirmwares] = useState<Firmware[]>([]);
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [version, setVersion] = useState("");
  const [desc, setDesc] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [campaignName, setCampaignName] = useState("");
  const [selectedFw, setSelectedFw] = useState("");
  const [targetError, setTargetError] = useState("");
  const [msg, setMsg] = useState("");

  function load() {
    api<Firmware[]>("/ota/firmware").then(setFirmwares).catch(console.error);
    api<Campaign[]>("/ota/campaigns").then(setCampaigns).catch(console.error);
  }

  useEffect(() => {
    load();
  }, []);

  async function uploadFirmware(e: FormEvent) {
    e.preventDefault();
    if (!file) return;
    setMsg("");
    const fd = new FormData();
    fd.append("file", file);
    fd.append("version", version);
    fd.append("description", desc);
    const token = localStorage.getItem("token");
    const res = await fetch("/api/ota/firmware", {
      method: "POST",
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: fd,
    });
    if (!res.ok) {
      setMsg("Upload thất bại");
      return;
    }
    setMsg("Đã upload firmware");
    setVersion("");
    setDesc("");
    setFile(null);
    load();
  }

  async function createCampaign(e: FormEvent) {
    e.preventDefault();
    await api("/ota/campaigns", {
      method: "POST",
      body: JSON.stringify({
        name: campaignName,
        firmwareId: selectedFw,
        targetErrorCode: targetError || undefined,
      }),
    });
    setCampaignName("");
    setTargetError("");
    load();
  }

  async function startCampaign(id: string) {
    const result = await api<{ targetedDevices: number }>(
      `/ota/campaigns/${id}/start`,
      { method: "POST" }
    );
    setMsg(`Campaign chạy — ${result.targetedDevices} thiết bị nhận OTA`);
    load();
  }

  return (
    <div>
      <h2 className="text-2xl font-semibold mb-1">OTA / Firmware</h2>
      <p className="text-slate-400 text-sm mb-6">
        Upload bản vá và triển khai cập nhật từ xa hàng loạt
      </p>
      {msg && <p className="text-emerald-400 text-sm mb-4">{msg}</p>}

      <div className="grid lg:grid-cols-2 gap-8">
        <form
          onSubmit={uploadFirmware}
          className="bg-slate-900 border border-slate-800 rounded-xl p-5 space-y-3"
        >
          <h3 className="font-medium">Upload firmware (.bin)</h3>
          <input
            type="text"
            placeholder="Version (vd: 1.0.1)"
            value={version}
            onChange={(e) => setVersion(e.target.value)}
            className="w-full px-3 py-2 rounded-lg bg-slate-950 border border-slate-700"
            required
          />
          <input
            type="text"
            placeholder="Mô tả"
            value={desc}
            onChange={(e) => setDesc(e.target.value)}
            className="w-full px-3 py-2 rounded-lg bg-slate-950 border border-slate-700"
          />
          <input
            type="file"
            accept=".bin"
            onChange={(e) => setFile(e.target.files?.[0] ?? null)}
            className="text-sm text-slate-400"
            required
          />
          <button
            type="submit"
            className="px-4 py-2 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-sm"
          >
            Upload
          </button>
        </form>

        <form
          onSubmit={createCampaign}
          className="bg-slate-900 border border-slate-800 rounded-xl p-5 space-y-3"
        >
          <h3 className="font-medium">Tạo chiến dịch OTA</h3>
          <input
            type="text"
            placeholder="Tên campaign"
            value={campaignName}
            onChange={(e) => setCampaignName(e.target.value)}
            className="w-full px-3 py-2 rounded-lg bg-slate-950 border border-slate-700"
            required
          />
          <select
            value={selectedFw}
            onChange={(e) => setSelectedFw(e.target.value)}
            className="w-full px-3 py-2 rounded-lg bg-slate-950 border border-slate-700"
            required
          >
            <option value="">Chọn firmware</option>
            {firmwares.map((f) => (
              <option key={f.id} value={f.id}>
                v{f.version}
              </option>
            ))}
          </select>
          <input
            type="text"
            placeholder="Lọc theo mã lỗi (tùy chọn, vd: E_SENSOR_HR)"
            value={targetError}
            onChange={(e) => setTargetError(e.target.value)}
            className="w-full px-3 py-2 rounded-lg bg-slate-950 border border-slate-700"
          />
          <button
            type="submit"
            className="px-4 py-2 rounded-lg bg-slate-700 hover:bg-slate-600 text-sm"
          >
            Tạo campaign
          </button>
        </form>
      </div>

      <h3 className="font-medium mt-8 mb-3">Campaigns</h3>
      <div className="space-y-2">
        {campaigns.map((c) => (
          <div
            key={c.id}
            className="flex items-center justify-between bg-slate-900 border border-slate-800 rounded-lg px-4 py-3 text-sm"
          >
            <div>
              <p className="font-medium">{c.name}</p>
              <p className="text-slate-500 text-xs">
                FW v{c.firmware.version} · {c.status} · {c._count.logs}{" "}
                thiết bị
              </p>
            </div>
            {c.status === "DRAFT" && (
              <button
                type="button"
                onClick={() => startCampaign(c.id)}
                className="text-emerald-400 hover:underline text-xs"
              >
                Bắt đầu rollout
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

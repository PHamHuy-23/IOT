import { FormEvent, useEffect, useState } from "react";
import { api, type Device } from "../lib/api";

const statusColor: Record<string, string> = {
  ACTIVE: "text-emerald-400",
  UNCLAIMED: "text-slate-400",
  OFFLINE: "text-slate-500",
  ERROR: "text-red-400",
};

export default function DevicesPage() {
  const [devices, setDevices] = useState<Device[]>([]);
  const [newCode, setNewCode] = useState("");
  const [msg, setMsg] = useState("");

  function load() {
    api<Device[]>("/admin/devices").then(setDevices).catch(console.error);
  }

  useEffect(() => {
    load();
  }, []);

  async function register(e: FormEvent) {
    e.preventDefault();
    setMsg("");
    try {
      await api("/admin/devices/register", {
        method: "POST",
        body: JSON.stringify({ deviceCode: newCode }),
      });
      setNewCode("");
      setMsg("Đã đăng ký mã thiết bị");
      load();
    } catch (err) {
      setMsg(err instanceof Error ? err.message : "Lỗi");
    }
  }

  async function resolveError(id: string) {
    await api(`/admin/errors/${id}/resolve`, { method: "PATCH" });
    load();
  }

  return (
    <div>
      <h2 className="text-2xl font-semibold mb-1">Vòng tay</h2>
      <p className="text-slate-400 text-sm mb-6">
        Mã thiết bị và người dùng sau khi kích hoạt qua app
      </p>

      <form
        onSubmit={register}
        className="flex gap-2 mb-6 flex-wrap items-end"
      >
        <div>
          <label className="text-xs text-slate-400 block mb-1">
            Đăng ký mã trước (tùy chọn)
          </label>
          <input
            value={newCode}
            onChange={(e) => setNewCode(e.target.value)}
            placeholder="C3-XXXXXXXX"
            className="px-3 py-2 rounded-lg bg-slate-950 border border-slate-700 w-56"
          />
        </div>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-slate-700 hover:bg-slate-600 text-sm"
        >
          Thêm
        </button>
        {msg && <span className="text-sm text-emerald-400">{msg}</span>}
      </form>

      <div className="overflow-x-auto rounded-xl border border-slate-800">
        <table className="w-full text-sm">
          <thead className="bg-slate-900 text-slate-400">
            <tr>
              <th className="text-left p-3">Mã thiết bị</th>
              <th className="text-left p-3">Người dùng</th>
              <th className="text-left p-3">Firmware</th>
              <th className="text-left p-3">Trạng thái</th>
              <th className="text-left p-3">Lỗi</th>
            </tr>
          </thead>
          <tbody>
            {devices.map((d) => (
              <tr key={d.id} className="border-t border-slate-800">
                <td className="p-3 font-mono text-emerald-300/90">
                  {d.deviceCode}
                </td>
                <td className="p-3">
                  {d.owner ? (
                    <div>
                      <p>{d.owner.name}</p>
                      <p className="text-xs text-slate-500">{d.owner.email}</p>
                    </div>
                  ) : (
                    <span className="text-slate-500">—</span>
                  )}
                </td>
                <td className="p-3">{d.firmwareVersion}</td>
                <td className={`p-3 ${statusColor[d.status] ?? ""}`}>
                  {d.status}
                </td>
                <td className="p-3">
                  {d.errors.length === 0 ? (
                    <span className="text-slate-600">—</span>
                  ) : (
                    <ul className="space-y-1">
                      {d.errors.map((e) => (
                        <li key={e.id} className="flex items-center gap-2">
                          <span className="text-red-400 font-mono text-xs">
                            {e.errorCode}
                          </span>
                          <button
                            type="button"
                            onClick={() => resolveError(e.id)}
                            className="text-xs text-emerald-500 hover:underline"
                          >
                            Đã xử lý
                          </button>
                        </li>
                      ))}
                    </ul>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

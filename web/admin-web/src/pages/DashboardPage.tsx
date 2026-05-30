import { useEffect, useState } from "react";
import { api, type Stats } from "../lib/api";

function StatCard({
  label,
  value,
  sub,
  accent,
}: {
  label: string;
  value: number;
  sub?: string;
  accent?: string;
}) {
  return (
    <div className="bg-slate-900 border border-slate-800 rounded-xl p-5">
      <p className="text-slate-400 text-sm">{label}</p>
      <p className={`text-3xl font-bold mt-1 ${accent ?? "text-white"}`}>
        {value}
      </p>
      {sub && <p className="text-xs text-slate-500 mt-2">{sub}</p>}
    </div>
  );
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    api<Stats>("/admin/stats")
      .then(setStats)
      .catch((e) => setError(e.message));
  }, []);

  return (
    <div>
      <h2 className="text-2xl font-semibold mb-1">Dashboard</h2>
      <p className="text-slate-400 text-sm mb-8">
        Tổng quan vòng tay và người dùng trong hệ thống
      </p>
      {error && <p className="text-red-400 mb-4">{error}</p>}
      {stats && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            label="Tổng vòng tay"
            value={stats.totalDevices}
            sub={`${stats.unclaimedDevices} chưa kích hoạt`}
          />
          <StatCard
            label="Vòng tay đang hoạt động"
            value={stats.activeDevices}
            accent="text-emerald-400"
          />
          <StatCard
            label="Tổng người dùng"
            value={stats.totalUsers}
            sub={`${stats.activeUsers} đang dùng thiết bị`}
          />
          <StatCard
            label="Thiết bị lỗi / cảnh báo"
            value={stats.errorDevices}
            sub={`${stats.unresolvedErrors} mã lỗi chưa xử lý`}
            accent="text-amber-400"
          />
        </div>
      )}
      <div className="mt-8 p-5 bg-slate-900/50 border border-slate-800 rounded-xl text-sm text-slate-400">
        <p className="font-medium text-slate-300 mb-2">Luồng kích hoạt</p>
        <ol className="list-decimal list-inside space-y-1">
          <li>ESP32-C3 phát BLE với mã thiết bị (deviceCode)</li>
          <li>App điện thoại kết nối BLE và gọi API kích hoạt</li>
          <li>Admin web hiển thị thiết bị + người dùng ngay sau khi claim</li>
          <li>Thiết bị báo lỗi → Admin upload firmware → OTA hàng loạt</li>
        </ol>
      </div>
    </div>
  );
}

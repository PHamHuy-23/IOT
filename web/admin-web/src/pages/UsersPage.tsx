import { useEffect, useState } from "react";
import { api, type UserRow } from "../lib/api";

export default function UsersPage() {
  const [users, setUsers] = useState<UserRow[]>([]);

  useEffect(() => {
    api<UserRow[]>("/admin/users").then(setUsers).catch(console.error);
  }, []);

  return (
    <div>
      <h2 className="text-2xl font-semibold mb-1">Người dùng</h2>
      <p className="text-slate-400 text-sm mb-6">
        Danh sách người dùng và vòng tay đã liên kết
      </p>
      <div className="grid gap-4">
        {users.map((u) => (
          <div
            key={u.id}
            className="bg-slate-900 border border-slate-800 rounded-xl p-4"
          >
            <div className="flex justify-between items-start">
              <div>
                <p className="font-medium">{u.name}</p>
                <p className="text-sm text-slate-400">{u.email}</p>
                {u.phone && (
                  <p className="text-xs text-slate-500 mt-1">{u.phone}</p>
                )}
              </div>
              <span className="text-sm bg-slate-800 px-2 py-1 rounded">
                {u._count.devices} vòng tay
              </span>
            </div>
            {u.devices.length > 0 && (
              <ul className="mt-3 flex flex-wrap gap-2">
                {u.devices.map((d) => (
                  <li
                    key={d.deviceCode}
                    className="text-xs font-mono bg-slate-950 px-2 py-1 rounded border border-slate-700"
                  >
                    {d.deviceCode}{" "}
                    <span className="text-slate-500">({d.status})</span>
                  </li>
                ))}
              </ul>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

import { NavLink, Outlet } from "react-router-dom";
import { useAuth } from "../lib/auth";

const nav = [
  { to: "/", label: "Dashboard", end: true },
  { to: "/devices", label: "Vòng tay" },
  { to: "/users", label: "Người dùng" },
  { to: "/ota", label: "OTA / Firmware" },
];

export default function Layout() {
  const { user, logout } = useAuth();

  return (
    <div className="min-h-screen flex">
      <aside className="w-56 border-r border-slate-800 bg-slate-900/50 p-4 flex flex-col">
        <div className="mb-8">
          <p className="text-xs uppercase tracking-wider text-emerald-400 font-medium">
            Health Monitor
          </p>
          <h1 className="text-lg font-semibold">Admin</h1>
        </div>
        <nav className="flex flex-col gap-1 flex-1">
          {nav.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                `px-3 py-2 rounded-lg text-sm transition-colors ${
                  isActive
                    ? "bg-emerald-600/20 text-emerald-300"
                    : "text-slate-400 hover:text-slate-200 hover:bg-slate-800"
                }`
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="pt-4 border-t border-slate-800 text-sm">
          <p className="text-slate-300 truncate">{user?.name}</p>
          <p className="text-slate-500 text-xs truncate">{user?.email}</p>
          <button
            type="button"
            onClick={logout}
            className="mt-2 text-xs text-red-400 hover:text-red-300"
          >
            Đăng xuất
          </button>
        </div>
      </aside>
      <main className="flex-1 p-8 overflow-auto">
        <Outlet />
      </main>
    </div>
  );
}

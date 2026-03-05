import React, { useEffect, useState } from 'react';
import { Outlet, NavLink, useNavigate, Navigate } from 'react-router-dom';
import { LayoutDashboard, Globe, Smartphone, Key, LogOut } from 'lucide-react';
import axios from 'axios';

const AdminLayout = () => {
  const navigate = useNavigate();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkAuth = async () => {
      const token = localStorage.getItem('adminToken');
      // If no token, redirect to login
      if (!token) {
        setLoading(false);
        setIsAuthenticated(false);
        return;
      }

      try {
        // Verify token with backend
        await axios.get('/api/admin/check-auth', {
          params: { token }
        });
        setIsAuthenticated(true);
      } catch (err) {
        // If verification fails, clear token
        console.error("Auth check failed:", err);
        localStorage.removeItem('adminToken');
        setIsAuthenticated(false);
      } finally {
        setLoading(false);
      }
    };

    checkAuth();
  }, [navigate]); // Add navigate to dependency array

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <div className="text-teal-400 flex flex-col items-center gap-4">
          <div className="w-8 h-8 border-2 border-teal-500/30 border-t-teal-500 rounded-full animate-spin"></div>
          <span className="text-sm font-medium">Verifying access...</span>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/admin/login" replace />;
  }

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    // Force reload to clear any state
    window.location.href = '/admin/login';
  };

  const navLinkClass = ({ isActive }) =>
    `flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
      isActive 
        ? 'bg-teal-500/10 text-teal-400 border border-teal-500/20 shadow-lg shadow-teal-900/20' 
        : 'text-slate-400 hover:text-white hover:bg-slate-800/50'
    }`;

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 flex font-sans">
      {/* Sidebar */}
      <aside className="w-64 bg-slate-800/50 border-r border-slate-700/50 flex flex-col fixed h-full">
        <div className="p-6 border-b border-slate-700/50">
          <h1 className="text-xl font-bold text-white tracking-tight">DeskCare <span className="text-teal-400">Admin</span></h1>
        </div>

        <nav className="flex-1 p-4 space-y-2">
          <NavLink to="/admin/dashboard" className={navLinkClass}>
            <LayoutDashboard size={20} />
            <span>概览</span>
          </NavLink>
          <NavLink to="/admin/website-stats" className={navLinkClass}>
            <Globe size={20} />
            <span>官网数据</span>
          </NavLink>
          <NavLink to="/admin/app-stats" className={navLinkClass}>
            <Smartphone size={20} />
            <span>软件日活</span>
          </NavLink>
          <NavLink to="/admin/codes" className={navLinkClass}>
            <Key size={20} />
            <span>下载码管理</span>
          </NavLink>
        </nav>

        <div className="p-4 border-t border-slate-700/50">
          <button 
            onClick={handleLogout}
            className="flex items-center gap-3 px-4 py-3 rounded-lg text-rose-400 hover:bg-rose-500/10 hover:text-rose-300 w-full transition-colors"
          >
            <LogOut size={20} />
            <span>退出登录</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 ml-64 p-8 bg-slate-900">
        <Outlet />
      </main>
    </div>
  );
};

export default AdminLayout;

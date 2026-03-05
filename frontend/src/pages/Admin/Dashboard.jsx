import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { Download, Users, Eye, Activity, Key, Globe, Smartphone } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

const AdminDashboard = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      const token = localStorage.getItem('adminToken');
      try {
        const response = await axios.get('/api/admin/stats/overview', {
          params: { token }
        });
        setStats(response.data);
      } catch (err) {
        console.error('Failed to fetch stats:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, []);

  if (loading) return <div>Loading...</div>;

  return (
    <div>
      <h1 className="text-3xl font-bold text-white mb-8">数据概览</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
        <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700/50 shadow-lg">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-slate-400 font-medium text-sm uppercase tracking-wider">今日日活 (DAU)</h3>
            <div className="bg-rose-500/10 p-2 rounded-lg text-rose-400">
              <Activity size={20} />
            </div>
          </div>
          <div className="text-3xl font-bold text-white">{stats?.today_dau || 0}</div>
          <div className="text-slate-500 text-sm mt-2">实时在线用户</div>
        </div>

        <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700/50 shadow-lg">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-slate-400 font-medium text-sm uppercase tracking-wider">今日浏览 (PV)</h3>
            <div className="bg-blue-500/10 p-2 rounded-lg text-blue-400">
              <Eye size={20} />
            </div>
          </div>
          <div className="text-3xl font-bold text-white">{stats?.today_pv || 0}</div>
          <div className="text-slate-500 text-sm mt-2">官网总浏览量: {stats?.total_pv}</div>
        </div>

        <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700/50 shadow-lg">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-slate-400 font-medium text-sm uppercase tracking-wider">今日访客 (UV)</h3>
            <div className="bg-teal-500/10 p-2 rounded-lg text-teal-400">
              <Users size={20} />
            </div>
          </div>
          <div className="text-3xl font-bold text-white">{stats?.today_uv || 0}</div>
          <div className="text-slate-500 text-sm mt-2">独立IP访问数</div>
        </div>

        <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700/50 shadow-lg">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-slate-400 font-medium text-sm uppercase tracking-wider">总下载量</h3>
            <div className="bg-amber-500/10 p-2 rounded-lg text-amber-400">
              <Download size={20} />
            </div>
          </div>
          <div className="text-3xl font-bold text-white">{stats?.total_downloads || 0}</div>
          <div className="text-slate-500 text-sm mt-2">累计成功下载</div>
        </div>
      </div>

      <div className="bg-slate-800 p-8 rounded-2xl border border-slate-700/50 shadow-lg">
        <h2 className="text-xl font-bold text-white mb-6">快速入口</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
           <a href="/admin/codes" className="block p-6 bg-slate-700/50 rounded-xl hover:bg-slate-700 transition-colors border border-slate-600/50">
             <div className="text-teal-400 mb-2"><Key size={24} /></div>
             <div className="font-bold text-white mb-1">管理下载码</div>
             <div className="text-slate-400 text-sm">生成新的下载码或查看使用情况</div>
           </a>
           <a href="/admin/website-stats" className="block p-6 bg-slate-700/50 rounded-xl hover:bg-slate-700 transition-colors border border-slate-600/50">
             <div className="text-blue-400 mb-2"><Globe size={24} /></div>
             <div className="font-bold text-white mb-1">官网流量分析</div>
             <div className="text-slate-400 text-sm">查看详细的访问来源与地理分布</div>
           </a>
           <a href="/admin/app-stats" className="block p-6 bg-slate-700/50 rounded-xl hover:bg-slate-700 transition-colors border border-slate-600/50">
             <div className="text-rose-400 mb-2"><Smartphone size={24} /></div>
             <div className="font-bold text-white mb-1">软件活跃分析</div>
             <div className="text-slate-400 text-sm">查看用户留存与活跃趋势</div>
           </a>
        </div>
      </div>
    </div>
  );
};

export default AdminDashboard;

import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Smartphone, Activity, Clock } from 'lucide-react';

const AdminAppStats = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      const token = localStorage.getItem('adminToken');
      try {
        const response = await axios.get('/api/admin/stats/app', {
          params: { token }
        });
        setData(response.data);
      } catch (err) {
        console.error('Failed to fetch stats:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) return <div className="text-white p-8">Loading...</div>;

  return (
    <div>
      <h1 className="text-3xl font-bold text-white mb-8">软件日活数据 (DAU)</h1>

      <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700/50 mb-8 shadow-lg">
        <h2 className="text-lg font-bold text-white mb-6 flex items-center gap-2">
          <Activity className="text-rose-400" size={20} />
          活跃趋势 (近30天)
        </h2>
        <div className="h-[350px]">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data?.trend}>
              <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
              <XAxis dataKey="date" stroke="#94a3b8" />
              <YAxis stroke="#94a3b8" />
              <Tooltip 
                contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '0.5rem' }}
                labelStyle={{ color: '#e2e8f0' }}
              />
              <Line type="monotone" dataKey="active_users" stroke="#f43f5e" strokeWidth={3} activeDot={{ r: 8 }} name="日活跃用户数 (DAU)" />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="bg-slate-800 rounded-2xl border border-slate-700/50 overflow-hidden shadow-lg">
        <div className="p-6 border-b border-slate-700/50">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <Clock className="text-slate-400" size={20} />
            最近活跃记录 (Last 100)
          </h2>
        </div>
        <div className="overflow-x-auto max-h-[600px]">
          <table className="w-full text-left">
            <thead className="bg-slate-900/50 text-slate-400 text-sm uppercase sticky top-0 backdrop-blur-sm z-10">
              <tr>
                <th className="px-6 py-4 font-medium">最近活跃时间</th>
                <th className="px-6 py-4 font-medium">机器码 (UID)</th>
                <th className="px-6 py-4 font-medium">版本</th>
                <th className="px-6 py-4 font-medium">IP / 城市</th>
                <th className="px-6 py-4 font-medium">今日启动</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50 text-sm">
              {data?.logs.map((log) => (
                <tr key={log.id} className="hover:bg-slate-700/30 transition-colors">
                  <td className="px-6 py-4 text-slate-400 whitespace-nowrap">
                    <div className="text-white font-medium">{new Date(log.last_seen).toLocaleDateString()}</div>
                    <div className="text-xs text-slate-500">{new Date(log.last_seen).toLocaleTimeString()}</div>
                  </td>
                  <td className="px-6 py-4 font-mono text-xs text-slate-500 truncate max-w-[150px]" title={log.uid}>
                    {log.uid}
                  </td>
                  <td className="px-6 py-4">
                    <span className="bg-teal-500/10 text-teal-400 px-2 py-1 rounded text-xs border border-teal-500/20">v{log.version}</span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-white font-mono">{log.ip_address}</div>
                    <div className="text-slate-500 text-xs">{log.city || 'Unknown'}</div>
                  </td>
                  <td className="px-6 py-4 text-white font-bold">
                    {log.launch_count} 次
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default AdminAppStats;

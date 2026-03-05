import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, Legend } from 'recharts';
import { Globe, MapPin, Monitor } from 'lucide-react';

const AdminWebsiteStats = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [filterDate, setFilterDate] = useState('');

  const fetchData = async (date) => {
    const token = localStorage.getItem('adminToken');
    try {
      const response = await axios.get('/api/admin/stats/website', {
        params: { 
          token,
          date: date || undefined,
          limit: date ? 1000 : 100 // Show more logs if date is selected
        }
      });
      setData(response.data);
    } catch (err) {
      console.error('Failed to fetch stats:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData(filterDate);
  }, [filterDate]);

  if (loading) return <div className="text-white p-8">Loading...</div>;

  const handleDotClick = (e) => {
      if (e && e.activePayload && e.activePayload[0]) {
          const date = e.activePayload[0].payload.date;
          setFilterDate(date);
      }
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-white mb-8">官网访问数据</h1>

      {/* Row 1: Trend Chart (Full Width) */}
      <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700/50 shadow-lg mb-6">
        <h2 className="text-lg font-bold text-white mb-6 flex items-center gap-2">
          <Globe className="text-blue-400" size={20} />
          访问趋势 (近3个月)
          <span className="text-xs text-slate-400 ml-2 font-normal">点击节点可筛选下方日志</span>
        </h2>
        <div className="h-[300px]">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data?.trend} onClick={handleDotClick}>
              <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
              <XAxis dataKey="date" stroke="#94a3b8" />
              <YAxis stroke="#94a3b8" />
              <Tooltip 
                contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '0.5rem' }}
                labelStyle={{ color: '#e2e8f0' }}
              />
              <Legend />
              <Line type="monotone" dataKey="pv" stroke="#3b82f6" strokeWidth={2} activeDot={{ r: 8, cursor: 'pointer' }} name="浏览量 (PV)" />
              <Line type="monotone" dataKey="uv" stroke="#14b8a6" strokeWidth={2} name="访客数 (UV)" />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Row 2: Geo Distribution (Full Width) */}
      <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700/50 shadow-lg mb-6">
        <h2 className="text-lg font-bold text-white mb-6 flex items-center gap-2">
          <MapPin className="text-rose-400" size={20} />
          地域分布 (Top 10)
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {data?.geo.map((item, index) => (
              <div key={index} className="flex items-center justify-between bg-slate-700/30 p-3 rounded-lg">
                <span className="text-slate-300 font-medium">{item.city || 'Unknown'}</span>
                <div className="flex items-center gap-3 flex-1 ml-4 justify-end">
                  <div className="w-full max-w-[150px] h-2 bg-slate-700 rounded-full overflow-hidden">
                    <div 
                      className="h-full bg-rose-500 rounded-full" 
                      style={{ width: `${(item.count / data.geo[0].count) * 100}%` }}
                    ></div>
                  </div>
                  <span className="text-white font-mono text-sm w-8 text-right">{item.count}</span>
                </div>
              </div>
            ))}
        </div>
      </div>

      {/* Row 3: Logs Table */}
      <div className="bg-slate-800 rounded-2xl border border-slate-700/50 overflow-hidden shadow-lg">
        <div className="p-6 border-b border-slate-700/50 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <Monitor className="text-slate-400" size={20} />
            访问日志
            {filterDate && <span className="text-teal-400 text-sm">({filterDate})</span>}
          </h2>
          <div className="flex items-center gap-2">
            {filterDate && (
                <button 
                    onClick={() => setFilterDate('')}
                    className="text-slate-400 hover:text-white text-sm underline mr-2"
                >
                    清除筛选
                </button>
            )}
            <input 
                type="date" 
                value={filterDate}
                onChange={(e) => setFilterDate(e.target.value)}
                className="bg-slate-900 border border-slate-700 rounded-lg px-3 py-1.5 text-white text-sm focus:outline-none focus:border-teal-500"
            />
          </div>
        </div>
        <div className="overflow-x-auto max-h-[600px]">
          <table className="w-full text-left">
            <thead className="bg-slate-900/50 text-slate-400 text-sm uppercase sticky top-0 backdrop-blur-sm z-10">
              <tr>
                <th className="px-6 py-4 font-medium">时间</th>
                <th className="px-6 py-4 font-medium">IP / 地理位置</th>
                <th className="px-6 py-4 font-medium">时长</th>
                <th className="px-6 py-4 font-medium">下载</th>
                <th className="px-6 py-4 font-medium">来源</th>
                <th className="px-6 py-4 font-medium">设备</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50 text-sm">
              {data?.logs.length === 0 ? (
                <tr><td colSpan="6" className="text-center py-8 text-slate-400">暂无日志</td></tr>
              ) : (
                data?.logs.map((log) => (
                  <tr key={log.id} className="hover:bg-slate-700/30 transition-colors">
                    <td className="px-6 py-4 text-slate-400 whitespace-nowrap">
                      {new Date(log.visited_at).toLocaleString()}
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-white font-mono">{log.ip_address}</div>
                      <div className="text-xs text-slate-500">{log.city}</div>
                    </td>
                    <td className="px-6 py-4 text-slate-300">
                        {log.duration_seconds > 0 ? (
                            <span>{Math.floor(log.duration_seconds / 60)}m {log.duration_seconds % 60}s</span>
                        ) : (
                            <span className="text-slate-600">-</span>
                        )}
                    </td>
                    <td className="px-6 py-4">
                        {log.is_download_click ? (
                            <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-teal-500/10 text-teal-400 border border-teal-500/20">
                                是
                            </span>
                        ) : (
                            <span className="text-slate-600">-</span>
                        )}
                    </td>
                    <td className="px-6 py-4 text-slate-400 max-w-[200px] truncate" title={log.referrer}>
                      {log.referrer || '-'}
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-slate-300">{log.os} / {log.browser}</div>
                      <div className="text-xs text-slate-500">{log.device_type}</div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default AdminWebsiteStats;

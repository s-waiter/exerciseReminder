import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import { Smartphone, Activity, Clock, MapPin, Calendar as CalendarIcon, FilterX } from 'lucide-react';

const AdminAppStats = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [logLoading, setLogLoading] = useState(false);
  const [filterDate, setFilterDate] = useState('');

  const fetchData = async (date) => {
    const token = localStorage.getItem('adminToken');
    setLogLoading(!!date);
    if (!data) setLoading(true);

    try {
      const response = await axios.get('/api/admin/stats/app', {
        params: { 
          token,
          date: date || undefined,
          limit: date ? 1000 : 100
        }
      });
      setData(response.data);
    } catch (err) {
      console.error('Failed to fetch stats:', err);
    } finally {
      setLoading(false);
      setLogLoading(false);
    }
  };

  useEffect(() => {
    fetchData(filterDate);
  }, [filterDate]);

  if (loading && !data) return <div className="text-white p-8 flex justify-center">Loading...</div>;

  const handleDotClick = (e) => {
      if (e && e.activeLabel) {
          setFilterDate(e.activeLabel);
          return;
      }
      if (e && e.activePayload && e.activePayload[0]) {
          const date = e.activePayload[0].payload.date;
          setFilterDate(date);
      }
  };

  const clearFilter = () => setFilterDate('');

  return (
    <div>
      <h1 className="text-3xl font-bold text-white mb-8">软件日活数据 (DAU)</h1>

      {/* Row 1: Trend Chart */}
      <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700/50 mb-6 shadow-lg">
        <h2 className="text-lg font-bold text-white mb-6 flex items-center gap-2">
          <Activity className="text-rose-400" size={20} />
          活跃趋势 (近3个月)
          <span className="text-xs text-slate-400 ml-2 font-normal bg-slate-700/50 px-2 py-1 rounded-md border border-slate-600">
            提示: 点击图表任意位置可筛选下方日志
          </span>
        </h2>
        <div className="h-[300px]">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data?.trend} onClick={handleDotClick} className="cursor-pointer">
              <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
              <XAxis dataKey="date" stroke="#94a3b8" />
              <YAxis stroke="#94a3b8" />
              <Tooltip 
                contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '0.5rem' }}
                labelStyle={{ color: '#e2e8f0' }}
                cursor={{ stroke: '#f43f5e', strokeWidth: 1 }}
              />
              <Legend />
              <Line 
                type="monotone" 
                dataKey="active_users" 
                stroke="#f43f5e" 
                strokeWidth={2} 
                activeDot={{ r: 6, strokeWidth: 2, stroke: '#fff' }} 
                dot={{ r: 3, strokeWidth: 1, fill: '#f43f5e' }}
                name="日活跃用户数 (DAU)" 
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Row 2: Geo Distribution */}
      <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700/50 shadow-lg mb-6">
        <h2 className="text-lg font-bold text-white mb-6 flex items-center gap-2">
          <MapPin className="text-blue-400" size={20} />
          用户分布 (Top 10)
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {data?.geo?.map((item, index) => (
              <div key={index} className="flex items-center justify-between bg-slate-700/30 p-3 rounded-lg border border-slate-700/30">
                <span className="text-slate-300 font-medium">{item.city || 'Unknown'}</span>
                <div className="flex items-center gap-3 flex-1 ml-4 justify-end">
                  <div className="w-full max-w-[150px] h-2 bg-slate-700 rounded-full overflow-hidden">
                    <div 
                      className="h-full bg-blue-500 rounded-full transition-all duration-500" 
                      style={{ width: `${(item.count / (data.geo[0]?.count || 1)) * 100}%` }}
                    ></div>
                  </div>
                  <span className="text-white font-mono text-sm w-8 text-right">{item.count}</span>
                </div>
              </div>
            ))}
            {(!data?.geo || data.geo.length === 0) && (
                <div className="col-span-2 text-center text-slate-500 py-4">暂无分布数据</div>
            )}
        </div>
      </div>

      {/* Row 3: Logs Table */}
      <div className="bg-slate-800 rounded-2xl border border-slate-700/50 overflow-hidden shadow-lg min-h-[400px]">
        <div className="p-6 border-b border-slate-700/50 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h2 className="text-lg font-bold text-white flex items-center gap-2">
              <Clock className="text-slate-400" size={20} />
              {filterDate ? `活跃记录 (${filterDate})` : '最新活跃记录 (Last 100)'}
            </h2>
            <p className="text-slate-400 text-sm mt-1">
              {filterDate 
                ? `显示 ${filterDate} 的所有活跃用户` 
                : '显示最近 100 条活跃记录，可点击上方图表或右侧日期筛选特定日期'}
            </p>
          </div>

          <div className="flex items-center gap-3 bg-slate-900/50 p-1.5 rounded-lg border border-slate-700/50">
            <div className="relative flex items-center">
              <CalendarIcon size={16} className="text-slate-400 absolute left-3 pointer-events-none" />
              <input 
                  type="date" 
                  value={filterDate}
                  onChange={(e) => setFilterDate(e.target.value)}
                  className="bg-transparent border-none text-white text-sm focus:ring-0 pl-9 pr-2 py-1.5 cursor-pointer"
                  style={{ colorScheme: 'dark' }} 
              />
            </div>
            
            {filterDate && (
                <button 
                    onClick={clearFilter}
                    className="flex items-center gap-1 text-slate-400 hover:text-white hover:bg-slate-700 px-3 py-1.5 rounded-md transition-colors text-sm"
                    title="清除筛选"
                >
                    <FilterX size={14} />
                    清除
                </button>
            )}
          </div>
        </div>

        <div className="overflow-x-auto max-h-[600px] relative">
          {logLoading && (
            <div className="absolute inset-0 bg-slate-800/80 backdrop-blur-sm z-20 flex items-center justify-center">
              <div className="text-teal-400 flex items-center gap-2">
                <svg className="animate-spin h-5 w-5 text-teal-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                加载记录中...
              </div>
            </div>
          )}

          <table className="w-full text-left border-collapse">
            <thead className="bg-slate-900/80 text-slate-400 text-sm uppercase sticky top-0 backdrop-blur-md z-10 shadow-sm">
              <tr>
                <th className="px-6 py-4 font-medium tracking-wider">最近活跃时间</th>
                <th className="px-6 py-4 font-medium tracking-wider">机器码 (UID)</th>
                <th className="px-6 py-4 font-medium tracking-wider">版本</th>
                <th className="px-6 py-4 font-medium tracking-wider">IP / 城市</th>
                <th className="px-6 py-4 font-medium tracking-wider">今日启动</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50 text-sm">
              {data?.logs?.length === 0 ? (
                <tr>
                  <td colSpan="5" className="text-center py-16">
                    <div className="flex flex-col items-center gap-3 text-slate-500">
                      <FilterX size={32} strokeWidth={1.5} />
                      <p>
                        {filterDate ? `${filterDate} 无活跃记录` : '暂无记录'}
                      </p>
                    </div>
                  </td>
                </tr>
              ) : (
                data?.logs?.map((log) => (
                  <tr key={log.id} className="hover:bg-slate-700/30 transition-colors group">
                    <td className="px-6 py-4 text-slate-400 whitespace-nowrap font-mono text-xs">
                      {new Date(log.last_seen).toLocaleTimeString()} 
                      <span className="text-slate-600 ml-2">{new Date(log.last_seen).toLocaleDateString()}</span>
                    </td>
                    <td className="px-6 py-4">
                        <div className="font-mono text-xs text-slate-500 truncate max-w-[150px] group-hover:text-slate-300 transition-colors" title={log.uid}>
                            {log.uid}
                        </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-teal-500/10 text-teal-400 border border-teal-500/20 font-mono">
                        v{log.version}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-white font-mono text-sm group-hover:text-blue-400 transition-colors">{log.ip_address}</div>
                      <div className="text-xs text-slate-500 mt-0.5">{log.city || 'Unknown'}</div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-white font-bold font-mono">{log.launch_count}</span>
                      <span className="text-slate-600 text-xs ml-1">次</span>
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

export default AdminAppStats;

import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { Plus, Trash2, Copy, Check } from 'lucide-react';

const AdminCodes = () => {
  const [codes, setCodes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [newCode, setNewCode] = useState('');
  const [newType, setNewType] = useState('one_time');
  const [newDays, setNewDays] = useState(7);
  const [requireCode, setRequireCode] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [copied, setCopied] = useState(null);

  const token = localStorage.getItem('adminToken');

  const fetchCodes = async () => {
    try {
      const response = await axios.get('/api/admin/codes', { params: { token } });
      setCodes(response.data);
    } catch (err) {
      console.error('Failed to fetch codes:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchConfig = async () => {
    try {
      const response = await axios.get('/api/admin/config/download', { params: { token } });
      setRequireCode(response.data.require_download_code);
    } catch (err) {
      console.error('Failed to fetch config:', err);
    }
  };

  useEffect(() => {
    fetchCodes();
    fetchConfig();
  }, []);

  const handleToggleRequire = async () => {
    try {
      const newValue = !requireCode;
      await axios.post('/api/admin/config/download', 
        { require_download_code: newValue }, 
        { params: { token } }
      );
      setRequireCode(newValue);
    } catch (err) {
      alert('更新设置失败');
    }
  };

  const handleGenerate = async (e) => {
    e.preventDefault();
    if (!newCode.trim()) return;

    setGenerating(true);
    try {
      const payload = { key: newCode, type: newType };
      if (newType === 'time_limited') {
        payload.days = parseInt(newDays);
      }
      
      await axios.post('/api/admin/codes', payload, { params: { token } });
      setNewCode('');
      setNewType('one_time');
      setNewDays(7);
      fetchCodes();
    } catch (err) {
      alert(err.response?.data?.detail || '生成失败');
    } finally {
      setGenerating(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('确定要删除这个下载码吗？')) return;
    
    try {
      await axios.delete(`/api/admin/codes/${id}`, { params: { token } });
      fetchCodes();
    } catch (err) {
      alert('删除失败');
    }
  };

  const handleCopy = (text) => {
    navigator.clipboard.writeText(text);
    setCopied(text);
    setTimeout(() => setCopied(null), 2000);
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-white mb-8">下载码管理</h1>

      {/* Global Config Switch */}
      <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700/50 mb-8 shadow-lg flex items-center justify-between">
        <div>
          <h2 className="text-lg font-bold text-white mb-1">启用下载码验证</h2>
          <p className="text-slate-400 text-sm">关闭后，用户无需输入下载码即可直接下载客户端。</p>
        </div>
        <button 
          onClick={handleToggleRequire}
          className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-teal-500 focus:ring-offset-2 focus:ring-offset-slate-900 ${
            requireCode ? 'bg-teal-600' : 'bg-slate-600'
          }`}
        >
          <span
            className={`${
              requireCode ? 'translate-x-6' : 'translate-x-1'
            } inline-block h-4 w-4 transform rounded-full bg-white transition-transform`}
          />
        </button>
      </div>

      <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700/50 mb-8 shadow-lg">
        <h2 className="text-lg font-bold text-white mb-4">生成新下载码</h2>
        <form onSubmit={handleGenerate} className="flex flex-col gap-4">
          <div className="flex gap-4">
            <input
              type="text"
              value={newCode}
              onChange={(e) => setNewCode(e.target.value)}
              placeholder="输入自定义代码 (例如: VIP2026)"
              className="flex-1 bg-slate-900 border border-slate-700 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-teal-500"
            />
            <button
              type="submit"
              disabled={generating || !newCode.trim()}
              className="bg-teal-600 hover:bg-teal-500 text-white font-bold py-2 px-6 rounded-lg transition-colors flex items-center gap-2 disabled:opacity-50 whitespace-nowrap"
            >
              {generating ? '生成中...' : <><Plus size={18} /> 生成</>}
            </button>
          </div>
          
          <div className="flex flex-wrap gap-6 text-sm text-slate-300 items-center">
            <label className="flex items-center gap-2 cursor-pointer hover:text-white transition-colors">
              <input 
                type="radio" 
                name="type" 
                value="one_time" 
                checked={newType === 'one_time'}
                onChange={(e) => setNewType(e.target.value)}
                className="text-teal-500 focus:ring-teal-500 bg-slate-900 border-slate-700"
              />
              一次性
            </label>
            <label className="flex items-center gap-2 cursor-pointer hover:text-white transition-colors">
              <input 
                type="radio" 
                name="type" 
                value="permanent" 
                checked={newType === 'permanent'}
                onChange={(e) => setNewType(e.target.value)}
                className="text-teal-500 focus:ring-teal-500 bg-slate-900 border-slate-700"
              />
              永久
            </label>
            <label className="flex items-center gap-2 cursor-pointer hover:text-white transition-colors">
              <input 
                type="radio" 
                name="type" 
                value="time_limited" 
                checked={newType === 'time_limited'}
                onChange={(e) => setNewType(e.target.value)}
                className="text-teal-500 focus:ring-teal-500 bg-slate-900 border-slate-700"
              />
              限时有效
            </label>
            
            {newType === 'time_limited' && (
              <div className="flex items-center gap-2 animate-fadeIn">
                <input 
                  type="number" 
                  min="1" 
                  max="3650"
                  value={newDays}
                  onChange={(e) => setNewDays(e.target.value)}
                  className="w-20 bg-slate-900 border border-slate-700 rounded px-2 py-1 text-white focus:outline-none focus:border-teal-500 text-center"
                />
                <span>天</span>
              </div>
            )}
          </div>
        </form>
      </div>

      <div className="bg-slate-800 rounded-2xl border border-slate-700/50 overflow-hidden shadow-lg">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-slate-900/50 text-slate-400 text-sm uppercase">
              <tr>
                <th className="px-6 py-4 font-medium">下载码</th>
                <th className="px-6 py-4 font-medium">类型</th>
                <th className="px-6 py-4 font-medium">状态</th>
                <th className="px-6 py-4 font-medium">使用次数</th>
                <th className="px-6 py-4 font-medium">过期时间</th>
                <th className="px-6 py-4 font-medium">操作</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50">
              {loading ? (
                <tr><td colSpan="7" className="text-center py-8 text-slate-400">加载中...</td></tr>
              ) : codes.length === 0 ? (
                <tr><td colSpan="7" className="text-center py-8 text-slate-400">暂无下载码</td></tr>
              ) : (
                codes.map((code) => {
                  const isExpired = code.expires_at && new Date() > new Date(code.expires_at);
                  const isUsedUp = code.type === 'one_time' && code.is_used;
                  const isValid = !isExpired && !isUsedUp;
                  
                  return (
                  <tr key={code.id} className="hover:bg-slate-700/30 transition-colors">
                    <td className="px-6 py-4 font-mono text-teal-400 font-bold flex items-center gap-2">
                      {code.key}
                      <button 
                        onClick={() => handleCopy(code.key)}
                        className="text-slate-500 hover:text-white transition-colors"
                        title="复制"
                      >
                        {copied === code.key ? <Check size={14} className="text-green-500" /> : <Copy size={14} />}
                      </button>
                    </td>
                    <td className="px-6 py-4 text-slate-300">
                      {code.type === 'permanent' && <span className="text-purple-400">永久</span>}
                      {code.type === 'one_time' && <span className="text-blue-400">一次性</span>}
                      {code.type === 'time_limited' && <span className="text-amber-400">限时</span>}
                    </td>
                    <td className="px-6 py-4">
                      {!isValid ? (
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-700 text-slate-400">
                          {isExpired ? '已过期' : '已失效'}
                        </span>
                      ) : (
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-teal-500/10 text-teal-400 border border-teal-500/20">
                          可使用
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-slate-300">{code.usage_count || 0}</td>
                    <td className="px-6 py-4 text-slate-400 text-sm">
                      {code.expires_at ? new Date(code.expires_at).toLocaleDateString() : '-'}
                    </td>
                    <td className="px-6 py-4">
                      <button
                        onClick={() => handleDelete(code.id)}
                        className="text-slate-400 hover:text-red-400 transition-colors p-2 hover:bg-red-500/10 rounded-lg"
                      >
                        <Trash2 size={18} />
                      </button>
                    </td>
                  </tr>
                )})
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default AdminCodes;

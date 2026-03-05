import React from 'react';
import { Heart, Github, Mail, Twitter, Globe } from 'lucide-react';
import { useVersionInfo } from '../hooks/useVersionInfo';

const Footer = () => {
  const { version } = useVersionInfo();
  
  return (
    <footer className="bg-slate-950 border-t border-slate-900 pt-16 pb-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
          {/* Brand Column */}
          <div className="col-span-1 md:col-span-2">
            <div className="flex items-center gap-2 mb-4">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-tr from-teal-500 to-cyan-400 flex items-center justify-center shadow-lg shadow-teal-500/20">
                <span className="text-slate-900 font-bold text-lg">D</span>
              </div>
              <span className="text-2xl font-bold text-white tracking-tight">
                DeskCare
              </span>
              <span className="ml-2 px-2 py-0.5 rounded-full bg-slate-800 text-slate-400 text-xs font-mono border border-slate-700">
                {version || 'v1.0.0'}
              </span>
            </div>
            <p className="text-slate-400 text-sm leading-relaxed max-w-xs mb-6">
              为久坐者而生，愿你拥有健康的颈椎与明亮的双眼。
              <br />
              免费、纯净的桌面健康管家。
            </p>
            <div className="flex gap-4">
              <a href="https://github.com/trae-ai/DeskCare" target="_blank" rel="noopener noreferrer" className="w-10 h-10 rounded-full bg-slate-900 border border-slate-800 flex items-center justify-center text-slate-400 hover:text-white hover:border-teal-500/50 hover:bg-teal-500/10 transition-all duration-300">
                <Github size={20} />
              </a>
              <a href="#" className="w-10 h-10 rounded-full bg-slate-900 border border-slate-800 flex items-center justify-center text-slate-400 hover:text-white hover:border-blue-400/50 hover:bg-blue-400/10 transition-all duration-300">
                <Twitter size={20} />
              </a>
              <a href="mailto:support@deskcare.app" className="w-10 h-10 rounded-full bg-slate-900 border border-slate-800 flex items-center justify-center text-slate-400 hover:text-white hover:border-purple-500/50 hover:bg-purple-500/10 transition-all duration-300">
                <Mail size={20} />
              </a>
            </div>
          </div>

          {/* Links Column */}
          <div>
            <h4 className="text-white font-semibold mb-6">产品</h4>
            <ul className="space-y-4 text-sm text-slate-400">
              <li><a href="#features" className="hover:text-teal-400 transition-colors">功能特性</a></li>
              <li><a href="#download" className="hover:text-teal-400 transition-colors">下载客户端</a></li>
              <li><a href="https://github.com/trae-ai/DeskCare/releases" target="_blank" className="hover:text-teal-400 transition-colors">更新日志</a></li>
              <li><a href="#" className="hover:text-teal-400 transition-colors">路线图</a></li>
            </ul>
          </div>

          {/* Links Column */}
          <div>
            <h4 className="text-white font-semibold mb-6">支持</h4>
            <ul className="space-y-4 text-sm text-slate-400">
              <li><a href="#faq" className="hover:text-teal-400 transition-colors">常见问题</a></li>
              <li><a href="https://github.com/trae-ai/DeskCare/issues" target="_blank" className="hover:text-teal-400 transition-colors">反馈 Bug</a></li>
              <li><a href="#" className="hover:text-teal-400 transition-colors">隐私政策</a></li>
            </ul>
          </div>
        </div>

        <div className="pt-8 border-t border-slate-900 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <p className="text-sm text-slate-600 text-center md:text-left">
            &copy; {new Date().getFullYear()} DeskCare. All rights reserved.
          </p>
          <div className="flex items-center justify-center gap-1.5 text-sm text-slate-600">
             <span>Designed & Built with</span>
             <Heart size={14} className="text-red-500 fill-current animate-pulse" />
             <span>by Trae & Gemini</span>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;

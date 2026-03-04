import React from 'react';
import { Heart, Github } from 'lucide-react';
import { useVersionInfo } from '../hooks/useVersionInfo';

const Footer = () => {
  const { version } = useVersionInfo();
  return (
    <footer className="bg-slate-950 border-t border-slate-900">
      <div className="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col md:flex-row justify-between items-center">
          <div className="flex flex-col mb-4 md:mb-0">
             <div className="flex items-center">
               <span className="text-xl font-bold text-gray-200">DeskCare</span>
               {version && <span className="ml-2 px-2 py-0.5 rounded-full bg-teal-900/30 text-teal-400 text-xs font-mono">{version}</span>}
             </div>
             <p className="text-slate-500 text-sm mt-1">
                为久坐者而生，愿你拥有健康的颈椎与明亮的双眼。
             </p>
          </div>
          <div className="flex items-center space-x-6">
            <a href="https://github.com/trae-ai/DeskCare" target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 text-slate-400 hover:text-white transition-colors group">
               <Github size={18} />
               <span className="group-hover:underline decoration-teal-500 underline-offset-4">GitHub</span>
            </a>
            <a href="mailto:support@example.com" className="text-slate-400 hover:text-white transition-colors">联系支持</a>
          </div>
        </div>
        <div className="mt-8 border-t border-slate-900 pt-8 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <p className="text-sm text-slate-600 text-center md:text-left">
            &copy; 2026 DeskCare. All rights reserved.
          </p>
          <div className="flex items-center justify-center gap-1 text-sm text-slate-600">
             <span>Made with</span>
             <Heart size={14} className="text-red-500 fill-current animate-pulse" />
             <span>by Trae & Gemini</span>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;

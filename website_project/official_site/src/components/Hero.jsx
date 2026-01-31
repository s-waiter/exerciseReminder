import React from 'react';
import { motion } from 'framer-motion';
import { Download, ChevronRight, PlayCircle, AlertTriangle, Clock, Activity, Coffee } from 'lucide-react';
import ParticleBackground from './ParticleBackground';
import { useVersionInfo } from '../hooks/useVersionInfo';

const Hero = () => {
  const { version, downloadUrl, loading } = useVersionInfo();

  return (
    <div id="home" className="relative pt-32 pb-20 sm:pt-48 sm:pb-32 overflow-hidden min-h-[90vh] flex flex-col justify-center">
      {/* Dynamic Particle Background */}
      <ParticleBackground />
      
      {/* Ambient Glow */}
      <div className="absolute top-0 left-0 w-full h-full overflow-hidden -z-20">
        <div className="absolute top-[-20%] right-[-10%] w-[800px] h-[800px] bg-teal-900/20 rounded-full blur-[120px] opacity-40 animate-pulse" />
        <div className="absolute bottom-[-20%] left-[-10%] w-[600px] h-[600px] bg-blue-900/20 rounded-full blur-[100px] opacity-40 animate-pulse" style={{ animationDelay: '3s' }} />
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center relative z-10">
        {version && (
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 1 }}
          className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-teal-500/10 border border-teal-500/20 text-teal-300 text-sm mb-8 backdrop-blur-sm"
        >
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-teal-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-teal-500"></span>
          </span>
          {version} 正式版现已发布
        </motion.div>
        )}

        <motion.h1 
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: "easeOut" }}
          className="text-5xl tracking-tight font-extrabold text-white sm:text-6xl md:text-7xl mb-6"
        >
          <span className="block mb-2">智能提醒</span>
          <span className="bg-gradient-to-r from-teal-200 via-teal-400 to-cyan-400 bg-clip-text text-transparent">
            健康办公
          </span>
        </motion.h1>
        
        <motion.p 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="mt-6 max-w-2xl mx-auto text-xl text-slate-300 sm:max-w-3xl leading-relaxed"
        >
          专为久坐人群打造的健康管家。
          <br className="hidden sm:block" />
          无论是程序员、设计师，还是行政文员、客服专员，DeskCare 都在默默守护您的颈椎与视力。
        </motion.p>
        
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.4 }}
          className="mt-10 flex flex-col sm:flex-row gap-4 justify-center items-center"
        >
          {loading ? (
             <button disabled className="group relative inline-flex items-center justify-center px-8 py-3.5 text-lg font-medium text-white/50 bg-teal-900/50 rounded-lg cursor-not-allowed">
                <div className="mr-2 h-5 w-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                加载版本信息...
             </button>
          ) : (
            <a href={downloadUrl || "#"} download={!!downloadUrl} className={`group relative inline-flex items-center justify-center px-8 py-3.5 text-lg font-medium text-white transition-all duration-200 bg-teal-600 rounded-lg hover:bg-teal-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-teal-600 focus:ring-offset-slate-900 overflow-hidden ${!downloadUrl ? 'opacity-50 cursor-not-allowed pointer-events-none' : ''}`}>
               <span className="absolute inset-0 w-full h-full -mt-10 transition-all duration-700 ease-out transform translate-x-full translate-y-full bg-gradient-to-br from-teal-400 to-cyan-300 group-hover:mb-32 group-hover:mr-0 group-hover:translate-x-0 group-hover:translate-y-0 opacity-30"></span>
               <Download className="mr-2 h-5 w-5" />
               免费下载 Windows 版
            </a>
          )}
          <a href="#features" className="inline-flex items-center justify-center px-8 py-3.5 text-lg font-medium text-slate-300 transition-all duration-200 bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 hover:text-white backdrop-blur-sm">
            探索功能 <ChevronRight className="ml-1 h-5 w-5" />
          </a>
        </motion.div>

        {/* SmartScreen Warning Hint */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.5 }}
          className="mt-8 max-w-lg mx-auto bg-amber-500/10 border border-amber-500/20 rounded-lg p-4 backdrop-blur-sm text-left"
        >
          <div className="flex gap-3">
            <AlertTriangle className="h-5 w-5 text-amber-400 flex-shrink-0 mt-0.5" />
            <div className="text-sm text-amber-100/90">
              <p className="font-medium text-amber-200 mb-1">安装提示</p>
              <p className="leading-relaxed">
                如果 Windows 提示 <span className="text-white font-semibold">"已保护你的电脑"</span>，
                请点击 <span className="text-white font-semibold">更多信息</span> &rarr; <span className="text-white font-semibold">仍要运行</span> 即可。
              </p>
              <p className="mt-2 text-xs opacity-60 text-amber-200/70">
                * 这是由于软件暂未购买商业数字签名证书所致，程序安全无毒，请放心使用。
              </p>
            </div>
          </div>
        </motion.div>

        {/* Floating Abstract UI Representation - Updated to look like real software */}
        <motion.div 
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 1.2, delay: 0.6 }}
          className="mt-20 relative mx-auto max-w-4xl"
        >
           {/* Main Interface Mockup */}
           <div className="relative rounded-xl bg-slate-900 border border-slate-700 p-1 shadow-2xl backdrop-blur-xl ring-1 ring-white/10 max-w-2xl mx-auto">
             {/* Window Header */}
             <div className="h-8 bg-slate-800 rounded-t-lg flex items-center px-4 justify-between border-b border-slate-700">
                <div className="flex gap-2">
                   <div className="w-3 h-3 rounded-full bg-red-500/80"></div>
                   <div className="w-3 h-3 rounded-full bg-amber-500/80"></div>
                   <div className="w-3 h-3 rounded-full bg-green-500/80"></div>
                </div>
                <div className="text-xs text-slate-400 font-medium">DeskCare</div>
                <div className="w-10"></div>
             </div>
             
             {/* Window Content - 1:1 Pixel Perfect Recreation of Fig 1 */}
          <div className="p-6 flex flex-col items-center justify-between bg-[#131722] rounded-b-lg min-h-[480px] relative overflow-hidden">
             
             {/* Background Particles/Stars (Subtle) */}
             <div className="absolute inset-0 z-0">
                <div className="absolute top-10 left-10 w-1 h-1 bg-blue-400/30 rounded-full animate-pulse"></div>
                <div className="absolute top-20 right-20 w-1.5 h-1.5 bg-cyan-400/20 rounded-full animate-pulse delay-700"></div>
                <div className="absolute bottom-32 left-1/2 w-1 h-1 bg-white/10 rounded-full"></div>
                {/* Gradient Orb Background */}
                <div className="absolute -top-20 -left-20 w-64 h-64 bg-blue-600/10 rounded-full blur-3xl"></div>
             </div>

             {/* Header Title (Inside Window) */}
             <div className="z-10 w-full text-center text-slate-400 text-sm mb-4 tracking-wide">久坐提醒助手</div>

             {/* Circular Timer - Fig 1 Style */}
             <div className="relative z-10 w-56 h-56 mb-6 flex items-center justify-center">
                {/* Outer Glow */}
                <div className="absolute inset-0 bg-cyan-500/10 rounded-full blur-xl"></div>
                
                {/* SVG Ring */}
                <svg className="w-full h-full transform -rotate-90">
                   {/* Track */}
                   <circle cx="112" cy="112" r="100" className="text-slate-800" strokeWidth="6" stroke="currentColor" fill="transparent" />
                   {/* Progress - Cyan Gradient Look */}
                   <circle cx="112" cy="112" r="100" className="text-cyan-400 drop-shadow-[0_0_10px_rgba(34,211,238,0.5)]" strokeWidth="6" stroke="currentColor" fill="transparent" strokeDasharray="628" strokeDashoffset="157" strokeLinecap="round" />
                </svg>
                
                {/* Timer Text Content */}
                <div className="absolute inset-0 flex flex-col items-center justify-center">
                   <div className="text-6xl font-sans font-light text-white tracking-wide mb-1">44:52</div>
                   <div className="text-cyan-400 text-lg font-medium mb-1">工作中</div>
                   <div className="text-slate-500 text-sm">预计 02:22 休息</div>
                </div>
             </div>

             {/* Middle Controls Row */}
             <div className="z-10 w-full max-w-[280px] flex gap-4 mb-8">
                {/* Interval Setting */}
                <div className="flex-1 bg-slate-800/50 rounded-xl p-3 flex flex-col items-center justify-center border border-white/5 backdrop-blur-sm">
                   <div className="text-white font-bold text-lg">45 min</div>
                   <div className="text-xs text-slate-500">• 间隔时长</div>
                </div>
                {/* Auto Start Toggle */}
                <div className="flex-1 bg-slate-800/50 rounded-xl p-3 flex flex-col items-center justify-center border border-white/5 backdrop-blur-sm">
                   <div className="w-10 h-5 bg-cyan-500 rounded-full relative mb-1">
                      <div className="absolute right-0.5 top-0.5 w-4 h-4 bg-white rounded-full shadow-sm"></div>
                   </div>
                   <div className="text-xs text-slate-500">开机自启</div>
                </div>
             </div>

             {/* Bottom Action Buttons */}
             <div className="z-10 w-full max-w-[320px] flex gap-4">
                <button className="flex-1 py-3 bg-[#3b82f6] hover:bg-blue-600 text-white rounded-full text-sm font-medium transition-colors shadow-lg shadow-blue-500/20">
                   立即休息
                </button>
                <button className="flex-1 py-3 bg-transparent border border-slate-600 text-slate-300 hover:text-white hover:border-slate-500 rounded-full text-sm font-medium transition-colors">
                   重置
                </button>
             </div>

          </div>
        </div>

           {/* Floating Mini Window Mockup */}
           <motion.div 
              animate={{ y: [0, -10, 0] }}
              transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
              className="absolute -right-4 -bottom-8 md:right-0 md:-bottom-4 w-48 bg-slate-800 rounded-lg border border-slate-600 shadow-xl p-3 hidden sm:block"
           >
              <div className="flex items-center gap-3">
                 <div className="w-10 h-10 rounded-full bg-teal-500/20 flex items-center justify-center border border-teal-500/30">
                    <Coffee className="w-5 h-5 text-teal-400" />
                 </div>
                 <div>
                    <div className="text-xs text-slate-400">该休息啦</div>
                    <div className="text-sm font-bold text-white">站起来走走</div>
                 </div>
              </div>
           </motion.div>
        </motion.div>
      </div>
    </div>
  );
};

export default Hero;

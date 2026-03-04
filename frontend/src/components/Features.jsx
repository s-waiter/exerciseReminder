import React from 'react';
import { motion } from 'framer-motion';
import { Clock, ShieldCheck, Minimize2, Coffee, Settings, Volume2, Moon } from 'lucide-react';

const Features = () => {
  return (
    <div id="features" className="py-24 bg-slate-900 relative overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-teal-400 font-semibold tracking-widest uppercase text-sm mb-3">Core Features</h2>
          <p className="text-3xl md:text-4xl font-bold text-white mb-4">
            简单易用，<br />
            守护您的<span className="text-transparent bg-clip-text bg-gradient-to-r from-teal-400 to-cyan-300">身心健康</span>
          </p>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            告别繁琐设置，开箱即用，让健康管理变得简单高效。
          </p>
        </div>

        {/* Bento Grid Layout */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          
          {/* Feature 1: Smart Timer (Large Card) */}
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="md:col-span-2 bg-slate-800/50 rounded-3xl p-8 border border-slate-700 hover:border-teal-500/30 transition-colors relative overflow-hidden group"
          >
            <div className="relative z-10">
              <div className="w-12 h-12 bg-teal-500/10 rounded-xl flex items-center justify-center mb-6">
                <Clock className="text-teal-400" size={24} />
              </div>
              <h3 className="text-2xl font-bold text-white mb-2">智能定时</h3>
              <p className="text-slate-400 max-w-md">
                科学的时间管理，默认45分钟工作+5分钟休息。支持自定义时长，到点自动提醒，防止过度劳累。
              </p>
            </div>
            {/* UI Mockup: Timer Slider */}
            <div className="absolute right-0 bottom-0 w-1/2 h-full opacity-30 group-hover:opacity-100 transition-opacity duration-500 hidden md:block">
               <div className="absolute inset-0 bg-gradient-to-l from-slate-800 to-transparent z-10"></div>
               <div className="absolute top-1/2 left-10 transform -translate-y-1/2 w-full">
                  <div className="flex items-center gap-4 mb-4">
                     <span className="text-white font-mono">45 min</span>
                     <div className="h-2 bg-slate-700 rounded-full flex-1">
                        <div className="h-full w-3/4 bg-teal-500 rounded-full shadow-[0_0_10px_rgba(20,184,166,0.5)]"></div>
                     </div>
                  </div>
                  <div className="flex items-center gap-4">
                     <span className="text-white font-mono">05 min</span>
                     <div className="h-2 bg-slate-700 rounded-full flex-1">
                        <div className="h-full w-1/4 bg-cyan-500 rounded-full shadow-[0_0_10px_rgba(6,182,212,0.5)]"></div>
                     </div>
                  </div>
               </div>
            </div>
          </motion.div>

          {/* Feature 2: Customizable (Tall Card) */}
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="bg-slate-800/50 rounded-3xl p-8 border border-slate-700 hover:border-teal-500/30 transition-colors flex flex-col justify-between"
          >
            <div>
              <div className="w-12 h-12 bg-purple-500/10 rounded-xl flex items-center justify-center mb-6">
                <Settings className="text-purple-400" size={24} />
              </div>
              <h3 className="text-xl font-bold text-white mb-2">个性化设置</h3>
              <p className="text-slate-400 text-sm leading-relaxed">
                支持深色模式、自定义提示语、灵活的休息时长。
                <br/>
                根据您的使用习惯，打造专属的健康助手。
              </p>
            </div>
            {/* UI Mockup: Settings Switches */}
            <div className="mt-8 flex flex-col gap-3">
               <div className="flex items-center justify-between bg-slate-900/50 p-3 rounded-lg border border-slate-700/50">
                  <div className="flex items-center gap-2 text-slate-300 text-xs">
                     <Moon size={14} /> <span>深色模式</span>
                  </div>
                  <div className="w-8 h-4 bg-teal-600 rounded-full relative">
                     <div className="absolute right-0.5 top-0.5 w-3 h-3 bg-white rounded-full"></div>
                  </div>
               </div>
               <div className="flex items-center justify-between bg-slate-900/50 p-3 rounded-lg border border-slate-700/50">
                  <div className="flex items-center gap-2 text-slate-300 text-xs">
                     <Settings size={14} /> <span>强制模式</span>
                  </div>
                  <div className="w-8 h-4 bg-teal-600 rounded-full relative">
                     <div className="absolute right-0.5 top-0.5 w-3 h-3 bg-white rounded-full"></div>
                  </div>
               </div>
            </div>
          </motion.div>

          {/* Feature 3: Minimalist Tray (Regular Card) */}
          <motion.div 
             initial={{ opacity: 0, y: 20 }}
             whileInView={{ opacity: 1, y: 0 }}
             viewport={{ once: true }}
             transition={{ delay: 0.2 }}
             className="bg-slate-800/50 rounded-3xl p-8 border border-slate-700 hover:border-teal-500/30 transition-colors"
          >
             <div className="w-12 h-12 bg-blue-500/10 rounded-xl flex items-center justify-center mb-6">
                <Minimize2 className="text-blue-400" size={24} />
             </div>
             <h3 className="text-xl font-bold text-white mb-2">极简不打扰</h3>
             <p className="text-slate-400 text-sm mb-6">
                平时隐藏在托盘或以迷你悬浮窗存在，极低内存占用，不干扰您的正常工作，只在需要时出现。
             </p>
             {/* UI Mockup: Tray Icon */}
             <div className="h-12 bg-slate-900 rounded-lg border border-slate-700 flex items-center justify-end px-4 gap-3">
                <div className="w-2 h-2 rounded-full bg-slate-600"></div>
                <div className="w-4 h-4 rounded bg-teal-500 animate-pulse"></div>
                <div className="text-[10px] text-white font-mono">10:45</div>
             </div>
          </motion.div>

          {/* Feature 4: Immersive Rest (Large Card) */}
          <motion.div 
             initial={{ opacity: 0, y: 20 }}
             whileInView={{ opacity: 1, y: 0 }}
             viewport={{ once: true }}
             transition={{ delay: 0.3 }}
             className="md:col-span-2 bg-gradient-to-br from-slate-800 to-slate-900 rounded-3xl p-8 border border-slate-700 hover:border-teal-500/30 transition-colors relative overflow-hidden group"
          >
             <div className="relative z-10 flex flex-col md:flex-row gap-8 items-center">
                <div className="flex-1">
                   <div className="w-12 h-12 bg-amber-500/10 rounded-xl flex items-center justify-center mb-6">
                      <ShieldCheck className="text-amber-400" size={24} />
                   </div>
                   <h3 className="text-2xl font-bold text-white mb-2">强制休息</h3>
                   <p className="text-slate-400">
                      支持全屏强制休息模式，暂时锁定屏幕，强迫您离开座椅活动筋骨，有效缓解视疲劳与颈椎压力。
                   </p>
                </div>
                
                {/* UI Mockup: Rest Screen */}
                <div className="w-full md:w-1/2 h-48 bg-black/40 rounded-xl border border-white/10 relative overflow-hidden flex items-center justify-center backdrop-blur-sm">
                   {/* Particles */}
                   <div className="absolute inset-0">
                      <div className="absolute top-10 left-10 w-2 h-2 bg-purple-400/50 rounded-full animate-ping"></div>
                      <div className="absolute bottom-10 right-20 w-3 h-3 bg-blue-400/30 rounded-full animate-pulse"></div>
                   </div>
                   <div className="text-center z-10">
                      <div className="text-2xl font-light text-white mb-2 tracking-[0.2em]">Rest Now</div>
                      <div className="text-xs text-white/50 uppercase tracking-widest">Take a deep breath</div>
                   </div>
                </div>
             </div>
          </motion.div>

        </div>
      </div>
    </div>
  );
};

export default Features;

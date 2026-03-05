import React, { useRef } from 'react';
import { motion, useScroll, useTransform } from 'framer-motion';
import { Download, ChevronRight, AlertTriangle, Clock, Activity } from 'lucide-react';
import ParticleBackground from './ParticleBackground';
import { useVersionInfo } from '../hooks/useVersionInfo';

const Hero = ({ trackDownload }) => {
  const { version, downloadUrl, loading } = useVersionInfo();
  const targetRef = useRef(null);
  const { scrollYProgress } = useScroll({
    target: targetRef,
    offset: ["start start", "end start"]
  });

  const opacity = useTransform(scrollYProgress, [0, 0.5], [1, 0]);
  const scale = useTransform(scrollYProgress, [0, 0.5], [1, 0.8]);
  const y = useTransform(scrollYProgress, [0, 0.5], [0, -50]);

  return (
    <div id="home" ref={targetRef} className="relative pt-32 pb-20 sm:pt-48 sm:pb-32 overflow-hidden min-h-screen flex flex-col justify-center">
      {/* Dynamic Particle Background */}
      <ParticleBackground />
      
      {/* Ambient Glow */}
      <div className="absolute top-0 left-0 w-full h-full overflow-hidden -z-20">
        <div className="absolute top-[-20%] right-[-10%] w-[800px] h-[800px] bg-teal-900/20 rounded-full blur-[120px] opacity-40 animate-pulse" />
        <div className="absolute bottom-[-20%] left-[-10%] w-[600px] h-[600px] bg-blue-900/20 rounded-full blur-[100px] opacity-40 animate-pulse" style={{ animationDelay: '3s' }} />
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 grid lg:grid-cols-2 gap-12 items-center">
        {/* Left Content */}
        <motion.div style={{ opacity, y }} className="text-center lg:text-left">
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
            className="text-5xl tracking-tight font-extrabold text-white sm:text-6xl mb-6"
          >
            <span className="block mb-2">不仅是久坐提醒</span>
            <span className="bg-gradient-to-r from-teal-200 via-teal-400 to-cyan-400 bg-clip-text text-transparent">
              更是您的全能管家
            </span>
          </motion.h1>
          
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="mt-6 text-xl text-slate-300 leading-relaxed"
          >
            集成了<strong>智能番茄钟</strong>、<strong>日程管理</strong>、<strong>健康数据分析</strong>与<strong>沉浸式午休</strong>模式。
            <br className="hidden sm:block" />
            DeskCare 致力于为久坐人群提供全方位的健康守护与效率提升。
          </motion.p>
          
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.4 }}
            className="mt-10 flex flex-col sm:flex-row gap-4 justify-center lg:justify-start items-center"
          >
            {loading ? (
               <button disabled className="group relative inline-flex items-center justify-center px-8 py-3.5 text-lg font-medium text-white/50 bg-teal-900/50 rounded-lg cursor-not-allowed">
                  <div className="mr-2 h-5 w-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                  加载版本信息...
               </button>
            ) : (
              <a href={downloadUrl || "#"} download={!!downloadUrl} onClick={() => trackDownload && trackDownload(version)} className={`group relative inline-flex items-center justify-center px-8 py-3.5 text-lg font-medium text-white transition-all duration-200 bg-teal-600 rounded-lg hover:bg-teal-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-teal-600 focus:ring-offset-slate-900 overflow-hidden shadow-lg shadow-teal-900/50 hover:shadow-teal-500/30 ${!downloadUrl ? 'opacity-50 cursor-not-allowed pointer-events-none' : ''}`}>
                 <span className="absolute inset-0 w-full h-full -mt-10 transition-all duration-700 ease-out transform translate-x-full translate-y-full bg-gradient-to-br from-teal-400 to-cyan-300 group-hover:mb-32 group-hover:mr-0 group-hover:translate-x-0 group-hover:translate-y-0 opacity-30"></span>
                 <Download className="mr-2 h-5 w-5 group-hover:animate-bounce" />
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
            className="mt-8 bg-amber-500/10 border border-amber-500/20 rounded-lg p-4 backdrop-blur-sm text-left max-w-lg mx-auto lg:mx-0"
          >
            <div className="flex gap-3">
              <AlertTriangle className="h-5 w-5 text-amber-400 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-amber-100/90">
                <p className="font-medium text-amber-200 mb-1">安装提示</p>
                <p className="leading-relaxed text-xs">
                  若 Windows 提示 <span className="text-white font-semibold">"已保护你的电脑"</span>，
                  请点击 <span className="text-white font-semibold">更多信息</span> &rarr; <span className="text-white font-semibold">仍要运行</span>。
                  (软件纯净无毒，暂未购买商业证书)
                </p>
              </div>
            </div>
          </motion.div>
        </motion.div>

        {/* Right Content - 3D Mockup */}
        <motion.div 
          style={{ scale }}
          initial={{ opacity: 0, x: 50, rotateY: -10 }}
          animate={{ opacity: 1, x: 0, rotateY: 0 }}
          transition={{ duration: 1, delay: 0.2 }}
          className="hidden lg:block relative perspective-1000"
        >
          <div className="relative z-10 transform transition-transform duration-500 hover:rotate-y-2 hover:rotate-x-2 preserve-3d">
            {/* Glow Effect */}
            <div className="absolute inset-0 bg-teal-500/20 blur-3xl rounded-full transform scale-90 translate-y-10"></div>
            
            {/* Main Window Mockup */}
            <div className="relative bg-slate-900 rounded-xl overflow-hidden shadow-2xl border border-slate-700/50">
               <div className="h-8 bg-slate-800 flex items-center px-4 gap-2 border-b border-slate-700">
                  <div className="w-3 h-3 rounded-full bg-red-500"></div>
                  <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
                  <div className="w-3 h-3 rounded-full bg-green-500"></div>
               </div>
               <img src="/images/screenshot-main.png" alt="DeskCare Main Interface" className="w-full h-auto object-cover opacity-90 hover:opacity-100 transition-opacity" />
               
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default Hero;

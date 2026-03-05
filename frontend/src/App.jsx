import React, { useEffect } from 'react';
import Navbar from './components/Navbar';
import Hero from './components/Hero';
import TargetAudience from './components/TargetAudience';
import Features from './components/Features';
import FAQ from './components/FAQ';
import Footer from './components/Footer';
import { Download, ShieldCheck, Github, Coffee, Monitor } from 'lucide-react';
import { useVersionInfo } from './hooks/useVersionInfo';
import { useAnalytics } from './hooks/useAnalytics';
import { motion } from 'framer-motion';

function App() {
  const { version, downloadUrl, loading } = useVersionInfo();
  const { trackDownload } = useAnalytics();

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 font-sans selection:bg-teal-500 selection:text-white">
      <Navbar />
      <main>
        <Hero trackDownload={trackDownload} />
        <TargetAudience />
        <Features />
        <FAQ />
        
        {/* Download Section */}
        <section id="download" className="py-24 bg-gradient-to-b from-slate-900 to-slate-800 relative overflow-hidden">
          {/* Background Glow */}
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-2xl h-full max-h-[500px] bg-teal-500/5 rounded-full blur-[100px] pointer-events-none"></div>

          <div className="max-w-4xl mx-auto px-4 text-center relative z-10">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="mb-12"
            >
              <h2 className="text-3xl md:text-4xl font-bold text-white mb-6">准备好开始更健康的工作方式了吗？</h2>
              <p className="text-slate-400 text-lg max-w-2xl mx-auto">
                DeskCare 永久免费，无广告，无捆绑。
                <br />
                立即下载，让每一次久坐都有人关心。
              </p>
            </motion.div>

            <motion.div 
              initial={{ opacity: 0, scale: 0.95 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              className="bg-slate-900/80 backdrop-blur-xl p-8 rounded-3xl border border-slate-700/50 shadow-2xl inline-block w-full max-w-lg relative overflow-hidden"
            >
               
               {/* Decorative background glow */}
               <div className="absolute top-0 right-0 -mr-20 -mt-20 w-48 h-48 bg-teal-500/10 rounded-full blur-3xl"></div>

               <div className="text-left mb-6 relative z-10">
                 <div className="flex items-center justify-between mb-2">
                   <h3 className="text-2xl font-bold text-white flex items-center gap-3">
                      <Monitor className="text-teal-400" />
                      Windows 版
                   </h3>
                   {version && <span className="bg-teal-500/10 text-teal-400 text-xs px-2 py-1 rounded-full border border-teal-500/20">{version}</span>}
                 </div>
                 <p className="text-slate-400 text-sm">适用于 Windows 10 / 11 (64-bit)</p>
               </div>
               
               {/* Main Download Button */}
               {loading ? (
                  <button disabled className="w-full bg-slate-800 text-slate-500 font-bold py-4 px-4 rounded-xl cursor-not-allowed flex items-center justify-center gap-2 border border-slate-700">
                    <div className="h-5 w-5 border-2 border-slate-500 border-t-transparent rounded-full animate-spin"></div>
                    <span>获取最新版本中...</span>
                  </button>
               ) : (
                 <a href={downloadUrl || "#"} download={!!downloadUrl} onClick={() => trackDownload(version)} className={`w-full bg-gradient-to-r from-teal-600 to-teal-500 hover:from-teal-500 hover:to-teal-400 text-white font-bold py-4 px-4 rounded-xl transition-all transform hover:scale-[1.02] active:scale-[0.98] flex items-center justify-center gap-2 shadow-lg shadow-teal-900/50 group ${!downloadUrl ? 'opacity-50 cursor-not-allowed pointer-events-none' : ''}`}>
                   <Download size={22} className="group-hover:animate-bounce" />
                   <span className="text-lg">立即下载完整版 (.zip)</span>
                 </a>
               )}
               
               <div className="mt-6 flex items-center justify-center gap-6 text-xs text-slate-500">
                 <span className="flex items-center gap-1.5">
                   <ShieldCheck size={14} className="text-teal-500" /> 无病毒
                 </span>
                 <span className="flex items-center gap-1.5">
                   <Coffee size={14} className="text-teal-500" /> 无广告
                 </span>
                 <span className="flex items-center gap-1.5">
                   <Github size={14} className="text-teal-500" /> 永久免费
                 </span>
               </div>

               {/* SmartScreen Warning Box */}
               <div className="mt-6 bg-slate-800/50 border border-slate-700 rounded-xl p-4 text-left">
                  <p className="text-slate-400 text-xs leading-relaxed">
                    <span className="text-amber-400 font-semibold">⚠️ 安装提示：</span> 
                    首次运行若遇 Windows 拦截，请点击 <span className="text-slate-200 border-b border-slate-600">更多信息</span> &rarr; <span className="text-slate-200 border-b border-slate-600">仍要运行</span>。
                  </p>
               </div>

            </motion.div>
          </div>
        </section>

      </main>
      <Footer />
    </div>
  );
}

export default App;

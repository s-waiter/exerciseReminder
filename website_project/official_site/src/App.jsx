import React from 'react';
import Navbar from './components/Navbar';
import Hero from './components/Hero';
import Features from './components/Features';
import FAQ from './components/FAQ';
import Footer from './components/Footer';
import { Download, ShieldAlert, Info } from 'lucide-react';
import { useVersionInfo } from './hooks/useVersionInfo';

function App() {
  const { version, downloadUrl } = useVersionInfo();

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 font-sans selection:bg-teal-500 selection:text-white">
      <Navbar />
      <main>
        <Hero />
        <Features />
        <FAQ />
        
        {/* Download Section */}
        <section id="download" className="py-20 bg-slate-800/50">
          <div className="max-w-4xl mx-auto px-4 text-center">
            <h2 className="text-3xl font-bold text-white mb-8">准备好开始更健康的工作方式了吗？</h2>
            <div className="bg-slate-900 p-8 rounded-2xl border border-slate-700 shadow-xl inline-block w-full max-w-md relative overflow-hidden">
               
               {/* Decorative background glow */}
               <div className="absolute top-0 right-0 -mr-16 -mt-16 w-32 h-32 bg-teal-500/10 rounded-full blur-2xl"></div>

               <div className="text-left mb-4 relative z-10">
                 <h3 className="text-xl font-bold text-white flex items-center gap-2">
                    <img src="/vite.svg" className="w-6 h-6" alt="Icon"/>
                    Windows 64-bit
                 </h3>
                 <p className="text-gray-400 text-sm mt-1">适用于 Windows 10/11</p>
               </div>
               
               <div className="border-t border-slate-800 my-5"></div>
               
               {/* Main Download Button */}
               <a href={downloadUrl} download className="w-full bg-teal-600 hover:bg-teal-700 text-white font-bold py-3.5 px-4 rounded-lg transition-all transform hover:scale-[1.02] active:scale-[0.98] flex items-center justify-center gap-2 shadow-lg shadow-teal-900/50 group">
                 <Download size={20} className="group-hover:animate-bounce" />
                 <span>下载完整版 (.zip)</span>
                 <span className="bg-teal-700/50 text-xs py-0.5 px-2 rounded ml-1 border border-teal-500/30">{version}</span>
               </a>
               
               <p className="text-xs text-gray-500 mt-4 text-center flex items-center justify-center gap-2">
                 <span>大小: ~30MB</span>
                 <span className="w-1 h-1 rounded-full bg-gray-600"></span>
                 <span>更新: 2026-01-31</span>
               </p>

               {/* SmartScreen Warning Box */}
               <div className="mt-6 bg-amber-500/10 border border-amber-500/20 rounded-lg p-4 text-left">
                  <div className="flex items-start gap-3">
                    <ShieldAlert className="w-5 h-5 text-amber-400 flex-shrink-0 mt-0.5" />
                    <div>
                      <h4 className="text-amber-400 text-sm font-bold mb-1">安装提示 (Windows SmartScreen)</h4>
                      <p className="text-gray-400 text-xs leading-relaxed">
                        由于软件尚未积累足够的微软信誉，首次运行时可能会弹出<span className="text-amber-300">"Windows 已保护你的电脑"</span>拦截提示。
                      </p>
                      <p className="text-gray-400 text-xs leading-relaxed mt-2">
                        解决方法：点击提示框中的 <span className="text-white font-medium border-b border-gray-500">更多信息</span>，然后选择 <span className="text-white font-medium border-b border-gray-500">仍要运行</span> 即可。本软件纯净无毒，请放心使用。
                      </p>
                    </div>
                  </div>
               </div>

            </div>
          </div>
        </section>

      </main>
      <Footer />
    </div>
  );
}

export default App;

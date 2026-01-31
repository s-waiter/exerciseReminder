import React, { useState, useEffect } from 'react';
import { Download, Menu, X } from 'lucide-react';

const Navbar = () => {
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <nav className={`fixed w-full z-50 transition-all duration-300 ${
      scrolled 
        ? 'bg-slate-900/80 backdrop-blur-xl border-b border-white/5 shadow-2xl py-3' 
        : 'bg-transparent py-5'
    }`}>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between">
          {/* Logo Area */}
          <div className="flex items-center gap-2 group cursor-pointer">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-tr from-teal-500 to-cyan-400 flex items-center justify-center shadow-lg shadow-teal-500/20 group-hover:shadow-teal-500/40 transition-all duration-300">
              <span className="text-slate-900 font-bold text-lg">D</span>
            </div>
            <span className="text-xl font-bold text-white tracking-tight group-hover:text-teal-50 transition-colors">
              DeskCare
            </span>
          </div>

          {/* Desktop Nav */}
          <div className="hidden md:flex items-center space-x-8">
            <a href="#" className="text-sm font-medium text-slate-300 hover:text-white transition-colors relative group">
              首页
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-teal-400 transition-all group-hover:w-full"></span>
            </a>
            <a href="#features" className="text-sm font-medium text-slate-300 hover:text-white transition-colors relative group">
              特性
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-teal-400 transition-all group-hover:w-full"></span>
            </a>
            <a href="#faq" className="text-sm font-medium text-slate-300 hover:text-white transition-colors relative group">
              常见问题
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-teal-400 transition-all group-hover:w-full"></span>
            </a>
            
            <a href="/downloads/DeskCare_v1.0.zip" download className="relative inline-flex items-center gap-2 px-5 py-2 rounded-full bg-teal-500/10 hover:bg-teal-500/20 text-teal-400 hover:text-teal-300 text-sm font-medium transition-all border border-teal-500/20 hover:border-teal-500/50 backdrop-blur-sm">
              <Download size={16} />
              <span>下载客户端</span>
            </a>
          </div>

          {/* Mobile Menu Button */}
          <div className="md:hidden">
            <button 
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="text-slate-300 hover:text-white transition-colors"
            >
              {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden absolute top-full left-0 w-full bg-slate-900/95 backdrop-blur-xl border-b border-white/5 py-4 px-4 flex flex-col space-y-4 shadow-2xl">
          <a href="#" onClick={() => setMobileMenuOpen(false)} className="text-slate-300 hover:text-white py-2 block">首页</a>
          <a href="#features" onClick={() => setMobileMenuOpen(false)} className="text-slate-300 hover:text-white py-2 block">特性</a>
          <a href="#faq" onClick={() => setMobileMenuOpen(false)} className="text-slate-300 hover:text-white py-2 block">常见问题</a>
          <a href="/downloads/DeskCare_v1.0.zip" download className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-teal-600 text-white justify-center">
            <Download size={16} />
            <span>下载客户端</span>
          </a>
        </div>
      )}
    </nav>
  );
};

export default Navbar;

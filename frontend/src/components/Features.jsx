import React from 'react';
import { motion } from 'framer-motion';
import { Clock, Calendar, Activity, Moon, CheckCircle, Zap, Shield } from 'lucide-react';

const FeatureBlock = ({ feature, index }) => {
  const isEven = index % 2 === 0;
  
  return (
    <div className={`flex flex-col ${isEven ? 'lg:flex-row' : 'lg:flex-row-reverse'} items-center gap-12 py-20`}>
      {/* Text Content */}
      <motion.div 
        initial={{ opacity: 0, x: isEven ? -50 : 50 }}
        whileInView={{ opacity: 1, x: 0 }}
        viewport={{ once: true, margin: "-100px" }}
        transition={{ duration: 0.6 }}
        className="flex-1 space-y-6 lg:px-8"
      >
        <div className={`inline-flex items-center justify-center p-3 rounded-xl ${feature.bgColor} ${feature.color} mb-2 shadow-lg`}>
          <feature.icon size={28} />
        </div>
        <h3 className="text-3xl font-bold text-white tracking-tight">{feature.title}</h3>
        <p className="text-lg text-slate-300 leading-relaxed">
          {feature.description}
        </p>
        <ul className="space-y-4 mt-6">
          {feature.points.map((point, i) => (
            <li key={i} className="flex items-start gap-3 text-slate-400 group">
              <div className="mt-1 w-5 h-5 rounded-full bg-teal-500/10 flex items-center justify-center flex-shrink-0 group-hover:bg-teal-500/20 transition-colors">
                 <CheckCircle className="w-3.5 h-3.5 text-teal-500" />
              </div>
              <span className="group-hover:text-slate-300 transition-colors">{point}</span>
            </li>
          ))}
        </ul>
      </motion.div>

      {/* Image Content */}
      <motion.div 
        initial={{ opacity: 0, scale: 0.9, rotateY: isEven ? -5 : 5 }}
        whileInView={{ opacity: 1, scale: 1, rotateY: 0 }}
        viewport={{ once: true, margin: "-100px" }}
        transition={{ duration: 0.8 }}
        className="flex-1 w-full perspective-1000"
      >
        <div className="relative group">
          {/* Back Glow */}
          <div className={`absolute -inset-4 bg-gradient-to-r ${feature.gradient} opacity-20 blur-3xl rounded-[2rem] transform group-hover:scale-105 transition-transform duration-700`}></div>
          
          {/* Main Card */}
          <div className="relative bg-slate-900 rounded-xl overflow-hidden shadow-2xl border border-slate-700/50 group-hover:border-slate-600 transition-all duration-500 transform group-hover:-translate-y-2 preserve-3d">
            {/* Window Controls */}
            <div className="h-9 bg-slate-800/50 backdrop-blur-sm flex items-center px-4 gap-2 border-b border-slate-700/50">
              <div className="w-3 h-3 rounded-full bg-[#ff5f56] border border-[#e0443e]"></div>
              <div className="w-3 h-3 rounded-full bg-[#ffbd2e] border border-[#dea123]"></div>
              <div className="w-3 h-3 rounded-full bg-[#27c93f] border border-[#1aab29]"></div>
            </div>
            
            {/* Image */}
            <div className="relative overflow-hidden bg-slate-900">
               <img 
                 src={feature.image} 
                 alt={feature.title} 
                 className="w-full h-auto object-cover opacity-90 group-hover:opacity-100 transition-opacity duration-500"
               />
               
               {/* Reflection/Sheen Effect */}
               <div className="absolute inset-0 bg-gradient-to-tr from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"></div>
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  );
};

const Features = () => {
  const features = [
    {
      title: "科学的久坐提醒机制",
      description: "不再是简单的倒计时。DeskCare 采用番茄工作法理念（默认 45+5），并支持强制全屏提醒，确保您真正停下来休息。",
      icon: Clock,
      image: "/images/screenshot-main.png",
      color: "text-teal-400",
      bgColor: "bg-teal-500/10",
      gradient: "from-teal-500 to-emerald-500",
      points: [
        "自定义工作/休息时长 (1-120分钟)",
        "支持“强制运动”模式，必须完成休息才可继续",
        "稍后提醒功能，灵活应对紧急工作",
        "常驻托盘，静默守护不打扰"
      ]
    },
    {
      title: "全能日程与提醒管理",
      description: "无论是每日例会、每周周报，还是重要的纪念日，DeskCare 都能帮您井井有条地管理。独有的“时间感知”让您对时间流逝更有概念。",
      icon: Calendar,
      image: "/images/screenshot-schedule.png",
      color: "text-blue-400",
      bgColor: "bg-blue-500/10",
      gradient: "from-blue-500 to-indigo-500",
      points: [
        "支持单次、每天、每周、每月、每年循环",
        "时间感知：显示“已过去”或“倒计时”天数",
        "工作/生活/健康/纪念 多维度分类",
        "桌面卡片提醒，重要事项不错过"
      ]
    },
    {
      title: "可视化时光足迹",
      description: "您的时间都去哪了？DeskCare 自动记录您的专注、运动、午休与暂停时长，通过直观的图表帮您复盘每一天。支持双击轨迹图记录日志，并可自动生成报表。",
      icon: Activity,
      image: "/images/screenshot-activity.png",
      color: "text-purple-400",
      bgColor: "bg-purple-500/10",
      gradient: "from-purple-500 to-pink-500",
      points: [
        "24小时时间轴分布图，一眼看清效率高峰",
        "双击轨迹图即可记录日志，自动生成每日报表",
        "专注/休息/午休/暂停 四态自动追踪",
        "支持查看过去 7 天的历史数据"
      ]
    },
    {
      title: "迷你模式与午休助眠",
      description: "不仅是工具，更是贴心的伙伴。迷你悬浮球让操作触手可及，午休模式为您营造沉浸式的休息环境。",
      icon: Moon,
      image: "/images/screenshot-mini.png",
      color: "text-amber-400",
      bgColor: "bg-amber-500/10",
      gradient: "from-amber-500 to-orange-500",
      points: [
        "极简悬浮球：双击切换模式，右键快捷菜单",
        "午休助眠：全屏黑色护眼，低亮时钟显示",
        "防误触设计：长按退出午休，防止意外中断",
        "支持整点报时特效，增添工作仪式感"
      ]
    }
  ];

  return (
    <div id="features" className="py-24 bg-slate-900 relative overflow-hidden">
      {/* Background Decorations */}
      <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-slate-700 to-transparent"></div>
      
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-24">
          <motion.span 
            initial={{ opacity: 0, y: 10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-teal-400 font-semibold tracking-widest uppercase text-sm mb-3 block"
          >
            Powerful Features
          </motion.span>
          <motion.h2 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-3xl md:text-5xl font-bold text-white mb-6"
          >
            从<span className="text-transparent bg-clip-text bg-gradient-to-r from-teal-400 to-cyan-300">久坐提醒</span>到
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-purple-400"> 全能助手</span>
          </motion.h2>
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="text-xl text-slate-400 max-w-2xl mx-auto"
          >
            每一个功能都经过精心打磨，只为让您在繁忙的工作中，依然保持健康与高效。
          </motion.p>
        </div>

        <div className="space-y-12">
          {features.map((feature, index) => (
            <FeatureBlock key={index} feature={feature} index={index} />
          ))}
        </div>
      </div>
    </div>
  );
};

export default Features;

import React from 'react';
import { motion } from 'framer-motion';
import { Code, PenTool, BookOpen, Coffee, Monitor, Briefcase } from 'lucide-react';

const AudienceCard = ({ icon: Icon, title, description, delay }) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    whileInView={{ opacity: 1, y: 0 }}
    viewport={{ once: true }}
    transition={{ delay, duration: 0.5 }}
    className="bg-slate-800/40 border border-slate-700/50 p-6 rounded-2xl hover:bg-slate-800/60 hover:border-teal-500/30 transition-all duration-300 group"
  >
    <div className="w-12 h-12 bg-slate-700/50 rounded-xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform duration-300">
      <Icon className="text-teal-400 w-6 h-6" />
    </div>
    <h3 className="text-lg font-bold text-white mb-2">{title}</h3>
    <p className="text-slate-400 text-sm leading-relaxed">{description}</p>
  </motion.div>
);

const TargetAudience = () => {
  const audiences = [
    {
      icon: Code,
      title: "程序员 & 开发者",
      description: "沉浸代码世界时常常忘记时间。番茄钟与强制休息模式，助您远离职业病，保持高效产出。"
    },
    {
      icon: PenTool,
      title: "设计师 & 创作者",
      description: "灵感来袭时容易久坐不动。定时起身活动，不仅保护颈椎，更能激发新的创意火花。"
    },
    {
      icon: BookOpen,
      title: "学生 & 考研党",
      description: "长时间伏案学习需要科学的节奏。用番茄工作法规划复习，劳逸结合，记忆效果更佳。"
    },
    {
      icon: Briefcase,
      title: "办公白领",
      description: "会议、报表、邮件处理... 繁忙工作中别忘了喝水。桌面提醒贴心守护您的职场健康。"
    }
  ];

  return (
    <section className="py-20 bg-slate-900 border-t border-slate-800 relative overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="text-center mb-12">
          <motion.h2 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-3xl font-bold text-white mb-4"
          >
            专为<span className="text-teal-400">久坐人群</span>设计
          </motion.h2>
          <p className="text-slate-400 max-w-2xl mx-auto">
            无论您的职业是什么，只要需要在电脑前长时间工作，DeskCare 都是您的健康好帮手。
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {audiences.map((item, index) => (
            <AudienceCard 
              key={index}
              {...item}
              delay={index * 0.1}
            />
          ))}
        </div>
      </div>
    </section>
  );
};

export default TargetAudience;

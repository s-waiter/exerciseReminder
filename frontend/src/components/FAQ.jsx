import React from 'react';
import { motion } from 'framer-motion';
import { HelpCircle, Shield, Minimize2, Moon, MessageSquare } from 'lucide-react';

const faqs = [
  {
    question: "安装时提示“Windows 已保护你的电脑”怎么办？",
    answer: "这是因为软件暂未购买昂贵的数字签名证书。请点击提示框中的“更多信息” -> “仍要运行”即可。DeskCare 纯净无毒，请放心使用。",
    icon: Shield
  },
  {
    question: "我点了右上角 ×，软件怎么“不见了”？",
    answer: "点击关闭按钮只会将窗口隐藏到系统托盘（屏幕右下角的小图标区域），DeskCare 仍在后台为您计时。单击托盘图标即可重新打开主界面。如需完全退出，请右键托盘图标选择“退出程序”。",
    icon: Minimize2
  },
  {
    question: "午休模式（全黑屏幕）怎么退出？",
    answer: "为了防止误触中断休息，午休模式设计了防误触机制。您只需要在屏幕上长按鼠标（左键或右键均可）2 秒钟，即可退出午休模式。",
    icon: Moon
  },
  {
    question: "“弹幕提醒”和“提醒卡片”有什么区别？",
    answer: "“弹幕提醒”是轻量级的文字飘过，适合不想被打断的场景；“提醒卡片”会常驻屏幕右上角，提供“我知道了”或“推迟”等操作按钮，适合需要确认的重要事项。",
    icon: MessageSquare
  }
];

const FAQ = () => {
  return (
    <div id="faq" className="py-24 bg-slate-900 border-t border-slate-800 relative overflow-hidden">
      {/* Background Glow */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full h-full max-w-7xl pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-teal-500/5 rounded-full blur-3xl"></div>
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-blue-500/5 rounded-full blur-3xl"></div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="text-center mb-16">
          <motion.span 
            initial={{ opacity: 0, y: 10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-teal-400 font-semibold tracking-widest uppercase text-sm mb-3 block"
          >
            FAQ
          </motion.span>
          <motion.h2 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-3xl md:text-4xl font-bold text-white mb-4"
          >
            常见问题解答
          </motion.h2>
          <p className="text-slate-400 max-w-2xl mx-auto">
            这里汇集了用户最关心的几个问题，希望能帮助您更好地使用 DeskCare。
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-6 max-w-5xl mx-auto">
          {faqs.map((faq, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.1 + 0.2 }}
              className="bg-slate-800/50 backdrop-blur-sm rounded-2xl p-6 border border-slate-700/50 hover:bg-slate-800 hover:border-teal-500/30 transition-all duration-300 group"
            >
              <div className="flex items-start gap-4">
                <div className="p-3 bg-teal-500/10 rounded-xl group-hover:bg-teal-500/20 transition-colors">
                  <faq.icon className="w-6 h-6 text-teal-400" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-white mb-2">{faq.question}</h3>
                  <p className="text-slate-400 leading-relaxed text-sm">
                    {faq.answer}
                  </p>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default FAQ;
